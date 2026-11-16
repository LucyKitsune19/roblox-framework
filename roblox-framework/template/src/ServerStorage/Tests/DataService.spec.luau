--!strict
-- DataService with a fake ProfileStore, fake replicas and fake players: loading, the setters' rules, replication,
-- play time, and what happens when a session ends or the player leaves

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const DataTemplate = require(ReplicatedStorage.SharedModules.DataTemplate)
const TestRunner = require(script.Parent.TestRunner)

-- // TYPES
type Check = TestRunner.Check

-- a stand-in for a ProfileStore or Replica signal
type FakeSignal = {
	Listeners:{(...any) -> ()},
	Connect:(self:FakeSignal, Listener:(...any) -> ()) -> {Disconnect:() -> ()},
	Fire:(self:FakeSignal, ...any) -> (),
}

type SetupOptions = {
	ClientReady:boolean?, -- false: the client has not said it is ready yet
	ReplicaReady:boolean?, -- false: the client has not asked for data yet
	LoadFails:boolean?, -- true: ProfileStore gives no profile
}

-- what a test gets back from Setup
type World = {
	Service:any,
	Player:any,
	Profile:any,
	Replicas:{any},
	Packages:any,
	Clock:{Now:number},
	InGame:{[any]:boolean},
	Kicked:{string},
}

-- // VARIABLES
const DATA_SERVICE = ServerScriptService.Services.DataService :: ModuleScript

-- a signal whose Fire calls every listener in order
local function NewSignal() : FakeSignal
	const Signal = { Listeners = {} } :: any

	-- adds a listener. returns its connection
	function Signal:Connect(Listener:(...any) -> ()) : {Disconnect:() -> ()}
		table.insert(Signal.Listeners, Listener)

		return {
			Disconnect = function()
				const Index = table.find(Signal.Listeners, Listener)

				if Index then
					table.remove(Signal.Listeners, Index)
				end
			end,
		}
	end

	-- calls every listener with the arguments
	function Signal:Fire(...:any)
		for _, Listener in table.clone(Signal.Listeners) do
			Listener(...)
		end
	end

	return Signal
end

-- a replica that changes its Data like the real one and remembers every call. Added to Log
local function NewReplica(Params:any, Log:{any}) : any
	const Replica = { Data = Params.Data, Token = Params.Token, Calls = {}, Subscribed = {}, Destroyed = false } :: any

	-- the table holding the last key of Path
	local function Parent(Path:{any}) : any
		return DataPath:Get(Replica.Data, table.move(Path, 1, #Path - 1, 1, {}))
	end

	-- sets the value at Path
	function Replica:Set(Path:{any}, Value:any)
		table.insert(Replica.Calls, "Set")
		Parent(Path)[Path[#Path]] = Value
	end

	-- sets keys of the dictionary at Path
	function Replica:SetValues(Path:{any}, Values:{[string]:any})
		table.insert(Replica.Calls, "SetValues")
		const Target = DataPath:Get(Replica.Data, Path)

		for Key, Value in Values do
			Target[Key] = Value
		end
	end

	-- inserts into the array at Path. returns the index
	function Replica:TableInsert(Path:{any}, Value:any, Index:number?) : number
		table.insert(Replica.Calls, "TableInsert")
		const Array = DataPath:Get(Replica.Data, Path)
		const At = Index or #Array + 1
		table.insert(Array, At, Value)

		return At
	end

	-- removes from the array at Path. returns the removed value
	function Replica:TableRemove(Path:{any}, Index:number) : any
		table.insert(Replica.Calls, "TableRemove")

		return table.remove(DataPath:Get(Replica.Data, Path), Index)
	end

	-- remembers who it was sent to
	function Replica:Subscribe(Player:any)
		table.insert(Replica.Subscribed, Player)
	end

	-- marks it destroyed
	function Replica:Destroy()
		Replica.Destroyed = true
	end

	table.insert(Log, Replica)

	return Replica
end

-- a profile holding a copy of the template. EndSession fires OnSessionEnd like the real one
local function NewProfile() : any
	const Profile = {
		Data = DataPath:DeepCopy(DataTemplate),
		Key = "",
		Active = true,
		Ended = 0,
		OnSave = NewSignal(),
		OnSessionEnd = NewSignal(),
	} :: any

	-- true until the session ended
	function Profile:IsActive() : boolean
		return Profile.Active
	end

	-- nothing to fill in: the data is already the template
	function Profile:Reconcile() end

	-- not needed by the tests
	function Profile:AddUserId(_UserId:number) end

	-- ends the session and tells the listeners
	function Profile:EndSession()
		Profile.Active = false
		Profile.Ended += 1
		Profile.OnSessionEnd:Fire()
	end

	return Profile
end

-- a fresh DataService wired to fakes, initialized
local function Setup(Check:Check, Options:SetupOptions?) : World
	const Opts = Options or {}
	const Service = Check:Fresh(DATA_SERVICE)
	const Kicked = {} :: {string}
	const Player = {
		Name = "Tester",
		UserId = 42,
		Kick = function(_Self:any, Message:string)
			table.insert(Kicked, Message)
		end,
	} :: any
	const Profile = NewProfile()
	const Replicas = {} :: {any}
	const Clock = { Now = 1000 }
	const InGame = { [Player] = true } :: {[any]:boolean}

	const Packages = {
		Store = {
			StartSessionAsync = function(_Self:any, Key:string, _Params:any) : any
				Profile.Key = Key

				return if Opts.LoadFails then nil else Profile
			end,
		},
		NewReplica = function(Params:any) : any
			return NewReplica(Params, Replicas)
		end,
		ReadyPlayers = {} :: {[any]:boolean},
		NewReadyPlayer = NewSignal(),
		ProfileToken = "ProfileToken",
		SessionToken = "SessionToken",
	}

	if Opts.ReplicaReady ~= false then
		Packages.ReadyPlayers[Player] = true
	end

	Service._Dependencies.LoadPackages = function() : any
		return Packages
	end
	Service._Dependencies.GetTime = function() : number
		return Clock.Now
	end
	Service._Dependencies.IsInGame = function(Target:any) : boolean
		return InGame[Target] == true
	end
	Service._Dependencies.IsRunning = function() : boolean
		return false
	end

	Service:Initialize()

	if Opts.ClientReady ~= false then
		Service:_MarkClientReady(Player)
	end

	return {
		Service = Service,
		Player = Player,
		Profile = Profile,
		Replicas = Replicas,
		Packages = Packages,
		Clock = Clock,
		InGame = InGame,
		Kicked = Kicked,
	}
end

-- // MODULE
return {
	-- a ready client gets both replicas, subscribed, and is marked loaded
	LoadsAndReplicates = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)

		Check:Equal(W.Profile.Key, "Player_42", "profile key")
		Check:Equal(#W.Replicas, 2, "two replicas")
		Check:Equal(W.Replicas[1].Token, "ProfileToken", "first is the profile replica")
		Check:Equal(W.Replicas[1].Data, W.Profile.Data, "profile replica shares the profile's table")
		Check:Equal(W.Replicas[1].Subscribed[1], W.Player, "profile replica subscribed")
		Check:Equal(W.Replicas[2].Subscribed[1], W.Player, "session replica subscribed")
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded")
		Check:Equal(W.Profile.Data.TimeTrackers.FirstJoined, 1000, "first joined stamped")
		Check:Equal(W.Profile.Data.TimeTrackers.LastJoined, 1000, "last joined stamped")
		Check:Equal(W.Service:GetSessionValue(W.Player, { "JoinedAt" }), 1000, "session joined at")
	end,

	-- no replica until the client asked for data; both appear the moment it asks
	WaitsForReplicaReady = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 0, "no replica before the client asked")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "not loaded before the client asked")

		W.Packages.ReadyPlayers[W.Player] = true
		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated once it asked")
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded once it asked")

		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 2, "a second ready makes no new replicas")
	end,

	-- the client asking for data before the profile loaded: replicated when the profile arrives
	ReplicaReadyBeforeProfile = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })

		W.Packages.ReadyPlayers[W.Player] = true
		W.Packages.NewReadyPlayer:Fire(W.Player)
		Check:Equal(#W.Replicas, 0, "nothing to replicate yet")

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated when the profile loaded")
	end,

	-- not loaded until the client says it is ready, even with the data replicated
	WaitsForClientReady = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Replicas, 2, "replicated")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "not loaded before ClientReady")

		W.Service:_MarkClientReady(W.Player)
		Check:True(W.Service:IsPlayerLoaded(W.Player), "loaded after ClientReady")
	end,

	-- a failed load kicks a player still here, and leaves alone one who left
	LoadFailureKicks = function(Check:Check)
		const W = Setup(Check, { LoadFails = true })

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(#W.Kicked, 1, "kicked")
		Check:Equal(W.Service:GetData(W.Player), nil, "no data")

		const Gone = Setup(Check, { LoadFails = true })
		Gone.InGame[Gone.Player] = nil
		Gone.Service:OnPlayerAdded(Gone.Player)
		Check:Equal(#Gone.Kicked, 0, "not kicked after leaving")
	end,

	-- a player who left during the load gets their profile ended at once
	LeftDuringLoad = function(Check:Check)
		const W = Setup(Check)

		W.Packages.Store.StartSessionAsync = function(_Self:any, _Key:string, _Params:any) : any
			W.InGame[W.Player] = nil

			return W.Profile
		end

		W.Service:OnPlayerAdded(W.Player)
		Check:Equal(W.Profile.Ended, 1, "profile ended")
		Check:Equal(W.Service:GetProfile(W.Player), nil, "not kept")
		Check:Equal(#W.Replicas, 0, "not replicated")
	end,

	-- operations, bounds, a zero old value, and every refusal
	SetValueRules = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		Check:True(S:SetValue({ Player = P, Path = { "Coins" }, Value = 10, MathOperation = "+" }), "+ on 0")
		Check:Equal(S:GetValue(P, { "Coins" }), 10, "0 + 10")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 3, MathOperation = "*" })
		Check:Equal(S:GetValue(P, { "Coins" }), 30, "10 * 3")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 100, MathOperation = "-", MinValue = 0 })
		Check:Equal(S:GetValue(P, { "Coins" }), 0, "raised to MinValue")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 999, MaxValue = 50 })
		Check:Equal(S:GetValue(P, { "Coins" }), 50, "= lowered to MaxValue")
		Check:True(S:Increment(P, { "Coins" }, -20), "increment")
		Check:Equal(S:GetValue(P, { "Coins" }), 30, "50 - 20")
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 4, MathOperation = "/" })
		Check:Equal(S:GetValue(P, { "Coins" }), 7.5, "30 / 4")

		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 0, MathOperation = "/" }), "division by zero")
		Check:True(not S:SetValue({ Player = P, Path = { "Settings" }, Value = 1, MathOperation = "+" }), "+ on a table")
		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = "x", MathOperation = "+" }), "+ with a string")
		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 1, MathOperation = "^" :: any }), "unknown operation")
		Check:True(not S:SetValue({ Player = P, Path = { "Missing", "Key" }, Value = 1 }), "no parent")
		Check:True(not S:SetValue({ Player = P, Path = {}, Value = 1 }), "empty path")
		Check:Equal(S:GetValue(P, { "Coins" }), 7.5, "refusals changed nothing")
	end,

	-- every setter refuses for a player with no data
	NotLoadedRefuses = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		Check:True(not S:SetValue({ Player = P, Path = { "Coins" }, Value = 1 }), "SetValue")
		Check:True(not S:Increment(P, { "Coins" }, 1), "Increment")
		Check:True(not S:SetValues({ Player = P, Path = { "Settings" }, Values = {} }), "SetValues")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = 1 }), nil, "InsertInArray")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Index = 1 }), nil, "RemoveFromArray")
		Check:Equal(S:GetValue(P, { "Coins" }), nil, "GetValue")
		Check:True(not S:ResetData(P), "ResetData")
	end,

	-- writes go straight to the table before the replica exists, through it after
	WritesUseReplica = function(Check:Check)
		const W = Setup(Check, { ReplicaReady = false })
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		S:SetValue({ Player = P, Path = { "Coins" }, Value = 5 })
		Check:Equal(S:GetValue(P, { "Coins" }), 5, "written before replication")

		W.Packages.ReadyPlayers[P] = true
		W.Packages.NewReadyPlayer:Fire(P)
		Check:Equal(W.Replicas[1].Data.Coins, 5, "the replica starts with it")

		S:Increment(P, { "Coins" }, 1)
		Check:Equal(table.concat(W.Replicas[1].Calls, ","), "Set", "later writes go through the replica")
		Check:Equal(S:GetValue(P, { "Coins" }), 6, "and change the data")
	end,

	-- the array and dictionary setters, through the replica
	SettersReplicate = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		const Replica = W.Replicas[1]

		S:SetValue({ Player = P, Path = { "Settings", "MusicEnabled" }, Value = false })
		Check:True(S:SetValues({ Player = P, Path = { "Settings" }, Values = { MusicEnabled = true } }), "SetValues")
		Check:True(not S:SetValues({ Player = P, Path = { "Coins" }, Values = {} }), "SetValues on a number")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "Sword" }), 1, "insert at end")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "Bow", Index = 1 }), 1, "insert at index")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Inventory" }, Value = "X", Index = 5 }), nil, "index past the end")
		Check:Equal(S:InsertInArray({ Player = P, Path = { "Coins" }, Value = "X" }), nil, "not an array")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Value = "Sword" }), "Sword", "remove by value")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Value = "Nope" }), nil, "missing value")
		Check:Equal(S:RemoveFromArray({ Player = P, Path = { "Inventory" }, Index = 1 }), "Bow", "remove by index")
		Check:Equal(S:GetValue(P, { "Settings", "MusicEnabled" }), true, "dictionary written")
		Check:Equal(#S:GetValue(P, { "Inventory" }), 0, "array emptied")
		Check:Equal(table.concat(Replica.Calls, ","), "Set,SetValues,TableInsert,TableInsert,TableRemove,TableRemove", "replica calls")
	end,

	-- session writes go to the session replica and never touch saved data
	SessionSource = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		S:SetValue({ Player = P, Path = { "Streak" }, Value = 2, MathOperation = "+", Source = "Session" })
		Check:Equal(S:GetSessionValue(P, { "Streak" }), 2, "session value")
		Check:Equal(S:GetValue(P, { "Streak" }), nil, "not in saved data")
		Check:Equal(table.concat(W.Replicas[2].Calls, ","), "Set", "through the session replica")
		Check:Equal(#W.Replicas[1].Calls, 0, "profile replica untouched")
	end,

	-- each save adds the seconds since the last count, once
	CountsTimePlayed = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)
		W.Clock.Now = 1060
		W.Profile.OnSave:Fire()
		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 60, "first save")
		W.Clock.Now = 1090
		W.Profile.OnSave:Fire()
		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 90, "second save adds only 30")
	end,

	-- leaving counts the last stretch, destroys both replicas, ends the profile and releases waiters with false
	LeavingCleansUp = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })
		const S, P = W.Service, W.Player
		local WaitResult = nil :: boolean?

		S:OnPlayerAdded(P)
		task.spawn(function()
			WaitResult = S:WaitForLoaded(P)
		end)

		W.Clock.Now = 1010
		S:OnPlayerRemoving(P)

		Check:Equal(W.Profile.Data.TimeTrackers.TimePlayed, 10, "last stretch counted")
		Check:True(W.Replicas[1].Destroyed and W.Replicas[2].Destroyed, "replicas destroyed")
		Check:Equal(W.Profile.Ended, 1, "profile ended once")
		Check:Equal(#W.Kicked, 0, "leaving does not kick")
		Check:Equal(WaitResult, false, "waiter told the player left")
		Check:Equal(S:GetData(P), nil, "data forgotten")
		Check:Equal(S:GetSession(P), nil, "session forgotten")
	end,

	-- a session ended elsewhere (another server took it) kicks the player and forgets them
	SessionEndedElsewhere = function(Check:Check)
		const W = Setup(Check)

		W.Service:OnPlayerAdded(W.Player)
		W.Profile:EndSession()

		Check:Equal(#W.Kicked, 1, "kicked")
		Check:Equal(W.Service:GetProfile(W.Player), nil, "forgotten")
		Check:True(not W.Service:IsPlayerLoaded(W.Player), "no longer loaded")
		Check:True(W.Replicas[1].Destroyed, "replica destroyed")
	end,

	-- waiters wake with true, watchers hear new loads and players already loaded, and Stop works
	LoadedWatchers = function(Check:Check)
		const W = Setup(Check, { ClientReady = false })
		const S, P = W.Service, W.Player
		const Heard = {} :: {any}
		local WaitResult = nil :: boolean?

		S:OnPlayerAdded(P)
		task.spawn(function()
			WaitResult = S:WaitForLoaded(P)
		end)

		const Stop = S:WatchPlayerLoaded(function(Loaded:any)
			table.insert(Heard, Loaded)
		end)

		S:_MarkClientReady(P)
		S:_MarkClientReady(P)

		Check:Equal(WaitResult, true, "waiter woke with true")
		Check:Equal(#Heard, 1, "watcher heard the load once")
		Check:Equal(S:WaitForLoaded(P), true, "WaitForLoaded on a loaded player returns at once")
		Check:Equal(#S:GetLoadedPlayers(), 1, "listed")

		const Late = {} :: {any}
		S:WatchPlayerLoaded(function(Loaded:any)
			table.insert(Late, Loaded)
		end)
		Check:Equal(Late[1], P, "a late watcher hears players already loaded")

		Stop()
		Check:Equal(#S._Watchers, 1, "stopped watcher removed")
	end,

	-- reset puts the template back in the same table and kicks
	ResetData = function(Check:Check)
		const W = Setup(Check)
		const S, P = W.Service, W.Player

		S:OnPlayerAdded(P)
		const Before = W.Profile.Data
		S:Increment(P, { "Coins" }, 77)

		Check:True(S:ResetData(P), "reset")
		Check:Equal(W.Profile.Data, Before, "same table")
		Check:Equal(W.Profile.Data.Coins, 0, "coins back to template")
		Check:Equal(#W.Kicked, 1, "kicked")
	end,
} :: TestRunner.Spec
