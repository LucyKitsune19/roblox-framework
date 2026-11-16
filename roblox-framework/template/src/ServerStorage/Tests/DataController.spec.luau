--!strict
-- DataController with a fake ReplicaClient: waiting for the data, the getters, and every kind of watch

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const DataTemplate = require(ReplicatedStorage.SharedModules.DataTemplate)
const TestRunner = require(script.Parent.TestRunner)

-- // TYPES
type Check = TestRunner.Check

-- what a test gets back from Setup
type World = {
	Controller:any,
	Profile:any, -- the fake profile replica
	Session:any, -- the fake session replica
	Deliver:() -> (), -- sends both replicas to the controller, as the server does once data is requested
}

-- // VARIABLES
const DATA_CONTROLLER = ReplicatedStorage.Controllers.DataController :: ModuleScript
const USER_ID = 42

-- a client replica: Fire changes nothing by itself, the test changes Data then calls Fire like ReplicaClient does
local function NewReplica(Data:any, UserId:number) : any
	const Replica = { Data = Data, Tags = { UserId = UserId }, Listeners = {} } :: any

	-- adds a change listener. returns its connection
	function Replica:OnChange(Listener:(...any) -> ()) : any
		table.insert(Replica.Listeners, Listener)

		return {
			Disconnect = function()
				table.remove(Replica.Listeners, table.find(Replica.Listeners, Listener))
			end,
		}
	end

	-- tells every listener about one change
	function Replica:Fire(Action:string, Path:{any}, Param1:any, Param2:any)
		for _, Listener in table.clone(Replica.Listeners) do
			Listener(Action, Path, Param1, Param2)
		end
	end

	-- sets Value at Path and fires Set with the old value, like ReplicaClient
	function Replica:DoSet(Path:{any}, Value:any)
		const Parent = DataPath:Get(Replica.Data, table.move(Path, 1, #Path - 1, 1, {}))
		const Old = Parent[Path[#Path]]
		Parent[Path[#Path]] = Value
		Replica:Fire("Set", Path, Value, Old)
	end

	return Replica
end

-- a fresh DataController with a fake ReplicaClient. Data is only sent when the test calls Deliver
local function Setup(Check:Check) : World
	const Controller = Check:Fresh(DATA_CONTROLLER)
	const Profile = NewReplica(DataPath:DeepCopy(DataTemplate), USER_ID)
	const Session = NewReplica({ JoinedAt = 1, Streak = 0 }, USER_ID)
	const Listeners = {} :: {[string]:{(Replica:any) -> ()}}

	const Fake = {
		OnNew = function(Token:string, Listener:(Replica:any) -> ()) : any
			Listeners[Token] = Listeners[Token] or {}
			table.insert(Listeners[Token], Listener)

			return { Disconnect = function() end }
		end,
		RequestData = function() end,
	}

	Controller._Dependencies.LoadReplicaClient = function() : any
		return Fake
	end
	Controller._Dependencies.UserId = function() : number
		return USER_ID
	end
	Controller._Dependencies.IsRunning = function() : boolean
		return true
	end

	-- another player's replica first: the controller must ignore it
	local function Deliver()
		for _, Listener in Listeners.PlayerData or {} do
			Listener(NewReplica({ Coins = 999 }, USER_ID + 1))
			Listener(Profile)
		end

		for _, Listener in Listeners.PlayerSession or {} do
			Listener(Session)
		end
	end

	return { Controller = Controller, Profile = Profile, Session = Session, Deliver = Deliver }
end

-- // MODULE
return {
	-- Initialize waits for the data; WaitForData callers wake when it lands
	InitializeWaitsForData = function(Check:Check)
		const W = Setup(Check)
		local Finished = false
		local WaitResult = nil :: boolean?

		task.spawn(function()
			W.Controller:Initialize()
			Finished = true
		end)
		task.spawn(function()
			WaitResult = W.Controller:WaitForData()
		end)

		Check:True(not Finished, "Initialize still waiting")
		Check:True(not W.Controller:IsLoaded(), "not loaded")
		Check:Equal(W.Controller:GetValue({ "Coins" }), nil, "no value before data")

		W.Deliver()

		Check:True(Finished, "Initialize returned")
		Check:Equal(WaitResult, true, "waiter woke with true")
		Check:Equal(W.Controller:GetValue({ "Coins" }), 0, "own data, not the other player's")
		Check:Equal(W.Controller:GetSessionValue({ "JoinedAt" }), 1, "session value")
		Check:Equal(W.Controller:GetData(), W.Profile.Data, "GetData")
	end,

	-- a watch added before the data arrives starts when it does: Observe is called, Watch only remembers
	WatchesBeforeData = function(Check:Check)
		const W = Setup(Check)
		const Observed = {} :: {any}
		const Watched = {} :: {any}

		W.Controller:ObserveValue({ "Coins" }, function(Value:any)
			table.insert(Observed, Value)
		end)
		W.Controller:WatchValue({ "Coins" }, function(Value:any)
			table.insert(Watched, Value)
		end)

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()
		Check:Equal(Observed[1], 0, "observe called with the arrived value")
		Check:Equal(#Watched, 0, "watch not called on arrival")

		W.Profile:DoSet({ "Coins" }, 5)
		Check:Equal(Observed[2], 5, "observe on change")
		Check:Equal(Watched[1], 5, "watch on change")
	end,

	-- old values for plain values, nil for tables; a change inside a table reaches its watcher; unrelated paths do not
	ValueWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchValue({ "Settings", "MusicEnabled" }, function(Value:any, Old:any)
			table.insert(Log, `Music {Value} {Old}`)
		end)
		W.Controller:WatchValue({ "Settings" }, function(Value:any, Old:any)
			table.insert(Log, `Settings {type(Value)} {Old}`)
		end)

		W.Profile:DoSet({ "Settings", "MusicEnabled" }, false)
		W.Profile:DoSet({ "Coins" }, 3)
		-- SetValues on the parent with the same value: the child watch hears nothing new
		W.Profile:Fire("SetValues", { "Settings" }, { MusicEnabled = false })

		Check:Equal(table.concat(Log, ","), "Music false true,Settings table nil,Settings table nil", "log")
	end,

	-- array watches get the value and index, only for their own array
	ArrayWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchArrayInsert({ "Inventory" }, function(Value:any, Index:number)
			table.insert(Log, `+{Value}@{Index}`)
		end)
		W.Controller:WatchArrayRemove({ "Inventory" }, function(Value:any, Index:number)
			table.insert(Log, `-{Value}@{Index}`)
		end)

		W.Profile:Fire("TableInsert", { "Inventory" }, "Sword", 1)
		W.Profile:Fire("TableInsert", { "Other" }, "Nope", 1)
		W.Profile:Fire("TableRemove", { "Inventory" }, "Sword", 1)

		Check:Equal(table.concat(Log, ","), "+Sword@1,-Sword@1", "log")
	end,

	-- AnyChange hears everything until stopped; a stopped watch is never called again
	AnyChangeAndStop = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {string}

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		const Stop = W.Controller:WatchAnyChange(function(Action:string, Path:{any})
			table.insert(Log, `{Action} {table.concat(Path, ".")}`)
		end)

		W.Profile:DoSet({ "Coins" }, 1)
		W.Profile:Fire("TableInsert", { "Inventory" }, "A", 1)
		Stop()
		W.Profile:DoSet({ "Coins" }, 2)

		Check:Equal(table.concat(Log, ","), "Set Coins,TableInsert Inventory", "log")
	end,

	-- session watches follow the session replica only
	SessionWatches = function(Check:Check)
		const W = Setup(Check)
		const Log = {} :: {any}

		W.Controller:ObserveSessionValue({ "Streak" }, function(Value:any)
			table.insert(Log, Value)
		end)

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()
		W.Session:DoSet({ "Streak" }, 4)
		W.Profile:DoSet({ "Coins" }, 9)

		Check:Equal(table.concat(Log, ","), "0,4", "log")
	end,

	-- a watch whose callback errors stops no other watch
	ErroringWatcher = function(Check:Check)
		const W = Setup(Check)
		local Reached = false

		task.spawn(W.Controller.Initialize, W.Controller)
		W.Deliver()

		W.Controller:WatchValue({ "Coins" }, function()
			error("watcher failure, expected by the test")
		end)
		W.Controller:WatchValue({ "Coins" }, function()
			Reached = true
		end)

		W.Profile:DoSet({ "Coins" }, 1)
		Check:True(Reached, "second watcher still called")
	end,
} :: TestRunner.Spec
