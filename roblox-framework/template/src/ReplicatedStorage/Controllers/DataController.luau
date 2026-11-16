--!strict
-- the local player's data on the client: a read-only mirror of what DataService keeps, through two Replicas (saved
-- data and session data). Read with GetValue, react with the Watch / Observe methods. The client never writes:
-- ask a service through a remote and let DataService change the data.
-- it loads first and the loader waits for it (attributes LoadOrder = 1, DoesYield = true), so every other controller
-- can read data from its own Initialize. Watchers can be added before the data arrives: they start when it does

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

-- // CONTAINERS
const SharedModules = ReplicatedStorage.SharedModules

-- // MODULES
const DataConfig = require(SharedModules.DataConfig)
const DataPath = require(SharedModules.DataPath)
const DataTemplate = require(SharedModules.DataTemplate)

-- // TYPES
export type Path = DataPath.Path
export type DataSource = DataConfig.DataSource
export type ChangeAction = "Set" | "SetValues" | "TableInsert" | "TableRemove"

-- Value is the value now. OldValue is the one before for plain values, nil for tables (changed in place)
export type ValueWatcher = (Value:any, OldValue:any) -> ()
-- the value inserted or removed, and its index
export type ArrayWatcher = (Value:any, Index:number) -> ()
-- every change: Set (value, old value), SetValues (values), TableInsert (value, index), TableRemove (value, index)
export type ChangeWatcher = (Action:ChangeAction, Path:Path, Param1:any, Param2:any) -> ()

-- what a watch reacts to
export type WatchKind = "Value" | "ArrayInsert" | "ArrayRemove" | "AnyChange"

export type WatchParams = {
	Kind:WatchKind,
	Path:Path?, -- needed by every kind but AnyChange
	Callback:(...any) -> (),
	Source:DataSource?, -- "Profile" when nil
	Immediate:boolean?, -- Value only: also called once with the current value as soon as there is data
}

-- the parts of a client Replica this controller uses
type Connection = {
	Disconnect:(self:any) -> (),
}

type ClientReplica = {
	Data:any,
	Tags:{[any]:any},
	OnChange:(self:any, Listener:(Action:ChangeAction, Path:{any}, Param1:any, Param2:any) -> ()) -> Connection,
}

-- the parts of ReplicaClient this controller uses
type ReplicaClientModule = {
	OnNew:(Token:string, Listener:(Replica:ClientReplica) -> ()) -> Connection,
	RequestData:() -> (),
}

type Watch = {
	Kind:WatchKind,
	Path:Path,
	Callback:(...any) -> (),
	Immediate:boolean,
	Last:any, -- the last plain value a Value watch saw
}

-- one replica and everything watching it
type Source = {
	Replica:ClientReplica?,
	Watches:{Watch},
	Connection:Connection?,
}

-- // VARIABLES
const DATA_TIME_OUT = 30 -- seconds Initialize waits for the data before letting the other controllers start anyway

-- // CONTROLLER
local DataController = {
	_Sources = {
		Profile = { Replica = nil, Watches = {}, Connection = nil },
		Session = { Replica = nil, Watches = {}, Connection = nil },
	} :: {[DataSource]:Source},
	_Waiting = {} :: {thread},
	_Connections = {} :: {Connection},
	-- what the controller reaches for outside itself, so a test can swap it
	_Dependencies = {
		LoadReplicaClient = nil :: (() -> ReplicaClientModule)?, -- nil: the real one in SharedPackages
		UserId = function() : number
			return (Players.LocalPlayer :: Player).UserId
		end,
		IsRunning = function() : boolean
			return RunService:IsRunning()
		end,
	},
}

-- ReplicaClient, required here and not at the top: at require it starts looking for its remotes, which never
-- appear outside a running game
local function LoadReplicaClient() : ReplicaClientModule
	if DataController._Dependencies.LoadReplicaClient then
		return DataController._Dependencies.LoadReplicaClient()
	end

	return require(ReplicatedStorage.SharedPackages.ReplicaClient) :: any
end

-- calls Callback in its own thread, so a watcher that errors or yields stops nothing
local function Call(Callback:(...any) -> (), ...:any)
	task.spawn(Callback, ...)
end

-- a Value watch looks at the data now: calls it when the value changed since it last looked (always for a table),
-- or when Force is set. Remembers plain values for next time
local function CheckValue(Watch:Watch, Data:any, Force:boolean)
	const Value = DataPath:Get(Data, Watch.Path)
	const Old = Watch.Last

	if type(Value) == "table" then
		Watch.Last = nil
	elseif Value == Old and not Force then
		return
	else
		Watch.Last = Value
	end

	Call(Watch.Callback, Value, if type(Value) == "table" then nil else Old)
end

-- hands one change on to every watch of that source it concerns
local function Dispatch(Source:Source, Action:ChangeAction, ChangedPath:Path, Param1:any, Param2:any)
	const Replica = Source.Replica

	if not Replica then
		return
	end

	for _, Watch in table.clone(Source.Watches) do
		if Watch.Kind == "AnyChange" then
			Call(Watch.Callback, Action, ChangedPath, Param1, Param2)
		elseif Watch.Kind == "Value" then
			if DataPath:Overlaps(Watch.Path, ChangedPath) then
				CheckValue(Watch, Replica.Data, false)
			end
		elseif Watch.Kind == "ArrayInsert" then
			if Action == "TableInsert" and DataPath:Equals(Watch.Path, ChangedPath) then
				Call(Watch.Callback, Param1, Param2)
			end
		elseif Watch.Kind == "ArrayRemove" then
			if Action == "TableRemove" and DataPath:Equals(Watch.Path, ChangedPath) then
				Call(Watch.Callback, Param1, Param2)
			end
		end
	end
end

-- a Value watch starting on data that is here: called now when Immediate, else only remembers the value
local function StartValueWatch(Watch:Watch, Data:any)
	if Watch.Immediate then
		CheckValue(Watch, Data, true)
	else
		const Value = DataPath:Get(Data, Watch.Path)
		Watch.Last = if type(Value) == "table" then nil else Value
	end
end

-- wakes every thread waiting for the data with the answer
local function ResumeWaiting(Arrived:boolean)
	const Waiting = DataController._Waiting
	DataController._Waiting = {}

	for _, Thread in Waiting do
		task.spawn(Thread, Arrived)
	end
end

-- the local player's replica of that source has arrived: starts every watch already waiting on it
local function Attach(SourceName:DataSource, Replica:ClientReplica)
	const Source = DataController._Sources[SourceName]

	if Source.Connection then
		Source.Connection:Disconnect()
	end

	Source.Replica = Replica
	Source.Connection = Replica:OnChange(function(Action:ChangeAction, ChangedPath:{any}, Param1:any, Param2:any)
		Dispatch(Source, Action, ChangedPath :: Path, Param1, Param2)
	end)

	for _, Watch in Source.Watches do
		if Watch.Kind == "Value" then
			StartValueWatch(Watch, Replica.Data)
		end
	end

	if SourceName == "Profile" then
		ResumeWaiting(true)
	end
end

-- the data of that source, nil until it arrived
local function GetSourceData(SourceName:DataSource) : any
	const Replica = DataController._Sources[SourceName].Replica

	return if Replica then Replica.Data else nil
end

-- // METHODS
-- true once the saved data has arrived
function DataController:IsLoaded() : boolean
	return DataController._Sources.Profile.Replica ~= nil
end

-- waits until the saved data has arrived. true when it has, false when Initialize gave up waiting
function DataController:WaitForData() : boolean
	if DataController:IsLoaded() then
		return true
	end

	table.insert(DataController._Waiting, coroutine.running())

	return coroutine.yield()
end

-- the whole saved data, nil until it arrived. Read only
function DataController:GetData() : DataTemplate.Data?
	return GetSourceData("Profile")
end

-- the saved value at Path ({"Settings", "MusicEnabled"}), nil when it is not there or not arrived
function DataController:GetValue(Path:Path) : any
	return DataPath:Get(GetSourceData("Profile"), Path)
end

-- the session value at Path, nil when it is not there or not arrived
function DataController:GetSessionValue(Path:Path) : any
	return DataPath:Get(GetSourceData("Session"), Path)
end

-- starts a watch of any kind on either source (see WatchParams). Returns the function that stops it, keep it
function DataController:Watch(Params:WatchParams) : () -> ()
	const SourceName = Params.Source or "Profile"
	const Source = DataController._Sources[SourceName]

	assert(Params.Kind == "AnyChange" or Params.Path ~= nil, `[DataController] a {Params.Kind} watch needs a Path`)

	const NewWatch:Watch = {
		Kind = Params.Kind,
		Path = Params.Path or {},
		Callback = Params.Callback,
		Immediate = Params.Immediate == true,
		Last = nil,
	}

	table.insert(Source.Watches, NewWatch)

	if NewWatch.Kind == "Value" and Source.Replica then
		StartValueWatch(NewWatch, Source.Replica.Data)
	end

	return function()
		const Index = table.find(Source.Watches, NewWatch)

		if Index then
			table.remove(Source.Watches, Index)
		end
	end
end

-- calls Callback(Value, OldValue) now (or as soon as the data arrives) and every time the saved value at Path
-- changes, including changes inside it. Returns the function that stops it
function DataController:ObserveValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback, Immediate = true })
end

-- like ObserveValue, but only for changes from now on, not the current value
function DataController:WatchValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback })
end

-- like ObserveValue, for a session value
function DataController:ObserveSessionValue(Path:Path, Callback:ValueWatcher) : () -> ()
	return DataController:Watch({ Kind = "Value", Path = Path, Callback = Callback, Immediate = true, Source = "Session" })
end

-- calls Callback(Value, Index) each time a value is inserted into the saved array at Path
function DataController:WatchArrayInsert(Path:Path, Callback:ArrayWatcher) : () -> ()
	return DataController:Watch({ Kind = "ArrayInsert", Path = Path, Callback = Callback })
end

-- calls Callback(Value, Index) each time a value is removed from the saved array at Path
function DataController:WatchArrayRemove(Path:Path, Callback:ArrayWatcher) : () -> ()
	return DataController:Watch({ Kind = "ArrayRemove", Path = Path, Callback = Callback })
end

-- calls Callback(Action, Path, Param1, Param2) for every change to the saved data
function DataController:WatchAnyChange(Callback:ChangeWatcher) : () -> ()
	return DataController:Watch({ Kind = "AnyChange", Callback = Callback })
end

-- loader hook: asks for the data and waits for it (DoesYield: the other controllers start after), at most
-- DATA_TIME_OUT seconds. Skipped outside a running game
function DataController:Initialize()
	if not DataController._Dependencies.IsRunning() then
		return
	end

	const ReplicaClient = LoadReplicaClient()
	const UserId = DataController._Dependencies.UserId()

	-- only the local player's replicas: a game may replicate other players' data under the same token
	for SourceName, Token in { Profile = DataConfig.PROFILE_TOKEN, Session = DataConfig.SESSION_TOKEN } :: {[DataSource]:string} do
		table.insert(DataController._Connections, ReplicaClient.OnNew(Token, function(Replica:ClientReplica)
			if Replica.Tags.UserId == UserId then
				Attach(SourceName, Replica)
			end
		end))
	end

	ReplicaClient.RequestData()

	if DataController:IsLoaded() then
		return
	end

	task.delay(DATA_TIME_OUT, function()
		if not DataController:IsLoaded() then
			warn(`[DataController] no data after {DATA_TIME_OUT} seconds, the other controllers start without it`)
			ResumeWaiting(false)
		end
	end)

	DataController:WaitForData()
end

return DataController
