--!strict
-- every player's data on the server. Saved data (DataTemplate) is a ProfileStore profile, session data
-- (SessionTemplate) lives only while the player is here, and each is mirrored to its player through a Replica.
-- read with GetValue / GetSessionValue, write ONLY through the setters (SetValue, Increment, SetValues, InsertInArray,
-- RemoveFromArray): they change the table and tell the client in one step. Writing Profile.Data directly saves but
-- never reaches the client.
-- a player is "loaded" once their data is on their client and ClientLoader has started every controller. Other
-- services wait for that with WaitForLoaded or WatchPlayerLoaded

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const ServerScriptService = game:GetService("ServerScriptService")

-- // CONTAINERS
const SharedModules = ReplicatedStorage.SharedModules

-- // MODULES
const DataConfig = require(SharedModules.DataConfig)
const DataPath = require(SharedModules.DataPath)
const DataTemplate = require(SharedModules.DataTemplate)
const Network = require(SharedModules.Network)
const SessionTemplate = require(SharedModules.SessionTemplate)

-- // TYPES
export type Path = DataPath.Path
export type DataSource = DataConfig.DataSource
export type MathOperation = "=" | "+" | "-" | "*" | "/"

-- the parts of a ProfileStore signal this service uses
type Signal = {
	Connect:(self:any, Listener:(...any) -> ()) -> any,
}

-- the parts of a ProfileStore profile this service uses
export type Profile = {
	Data:any,
	Key:string,
	OnSave:Signal,
	OnSessionEnd:Signal,
	IsActive:(self:any) -> boolean,
	Reconcile:(self:any) -> (),
	EndSession:(self:any) -> (),
	AddUserId:(self:any, UserId:number) -> (),
}

-- the parts of a ProfileStore store this service uses
type Store = {
	StartSessionAsync:(self:any, Key:string, Params:{Cancel:(() -> boolean)?}?) -> Profile?,
}

-- the parts of a server Replica this service uses
export type Replica = {
	Data:any,
	Set:(self:any, Path:{any}, Value:any) -> (),
	SetValues:(self:any, Path:{any}, Values:{[string]:any}) -> (),
	TableInsert:(self:any, Path:{any}, Value:any, Index:number?) -> number,
	TableRemove:(self:any, Path:{any}, Index:number) -> any,
	Subscribe:(self:any, Player:Player) -> (),
	Destroy:(self:any) -> (),
}

-- the packages, loaded on first use so requiring this module in Edit (unit tests) starts nothing
type Packages = {
	Store:Store,
	NewReplica:(Params:{Token:any, Tags:{[string]:any}, Data:{[any]:any}}) -> Replica,
	ReadyPlayers:{[Player]:boolean}, -- players whose client asked ReplicaClient for data
	NewReadyPlayer:Signal,
	ProfileToken:any,
	SessionToken:any,
}

-- a player's session: data that is replicated but never saved
export type Session = {
	StartedAt:number, -- os.time() the player joined
	Data:SessionTemplate.Data,
	Replica:Replica?, -- nil until the client asked for data
}

-- where a write goes: the data table, and the replica that mirrors it once there is one
type Target = {
	Data:any,
	Replica:Replica?,
}

export type SetParams = {
	Player:Player,
	Path:Path,
	Value:any,
	MathOperation:MathOperation?, -- "=" when nil. any other needs a number at Path and a number Value
	MinValue:number?, -- a number result is raised to at least this
	MaxValue:number?, -- a number result is lowered to at most this
	Source:DataSource?, -- "Profile" when nil
}

export type SetValuesParams = {
	Player:Player,
	Path:Path, -- a dictionary in the data
	Values:{[string]:any},
	Source:DataSource?,
}

export type InsertParams = {
	Player:Player,
	Path:Path, -- an array in the data
	Value:any,
	Index:number?, -- the end when nil
	Source:DataSource?,
}

export type RemoveParams = {
	Player:Player,
	Path:Path, -- an array in the data
	Index:number?, -- which entry to remove. give this or Value
	Value:any, -- the first entry equal to this is removed, when Index is nil
	Source:DataSource?,
}

export type LoadedWatcher = (Player:Player) -> ()

-- // VARIABLES
const STORE_NAME = "PlayerData_v1" -- the DataStore. A new name starts every player from the template
const KEY_PREFIX = "Player_" -- a profile's key is this and the UserId
const KICK_LOAD_FAILED = "Your data could not be loaded. Please rejoin."
const KICK_SESSION_ENDED = "Your data was opened on another server. Please rejoin."
const KICK_DATA_RESET = "Your data has been reset. Please rejoin."

-- what each MathOperation does to the value already there (Old) with the value given (Given)
const MATH_OPERATIONS = {
	["+"] = function(Old:number, Given:number) : number
		return Old + Given
	end,
	["-"] = function(Old:number, Given:number) : number
		return Old - Given
	end,
	["*"] = function(Old:number, Given:number) : number
		return Old * Given
	end,
	["/"] = function(Old:number, Given:number) : number
		return Old / Given
	end,
}

-- // MODULE
local DataService = {
	_Packages = nil :: Packages?,
	_Profiles = {} :: {[Player]:Profile},
	_Replicas = {} :: {[Player]:Replica},
	_Sessions = {} :: {[Player]:Session},
	_CountedAt = {} :: {[Player]:number}, -- os.time() play time was last added to TimePlayed
	_ClientReady = {} :: {[Player]:boolean},
	_Loaded = {} :: {Player},
	_Waiting = {} :: {[Player]:{thread}},
	_Watchers = {} :: {LoadedWatcher},
	_Connections = {} :: {any}, -- RBXScriptConnections and the packages' own connection objects
	-- what the service reaches for outside itself, so a test can swap them
	_Dependencies = {
		GetTime = os.time,
		IsInGame = function(Player:Player) : boolean
			return Player:IsDescendantOf(Players)
		end,
		IsRunning = function() : boolean
			return RunService:IsRunning()
		end,
		LoadPackages = nil :: (() -> Packages)?, -- nil: the real ProfileStore and ReplicaServer
	},
}

-- the real packages: ProfileStore (ReplicatedStorage.SharedPackages) and ReplicaServer
-- (ServerScriptService.ServerPackages), required here and not at the top so nothing starts in Edit
local function LoadRealPackages() : Packages
	const ProfileStore = require(ReplicatedStorage.SharedPackages.ProfileStore) :: any
	const ReplicaServer = require(ServerScriptService.ServerPackages.ReplicaServer) :: any

	ProfileStore.OnError:Connect(function(Message:string, StoreName:string, Key:string)
		warn(`[DataService] ProfileStore error in {StoreName}/{Key}: {Message}`)
	end)

	return {
		Store = ProfileStore.New(STORE_NAME, DataTemplate),
		NewReplica = ReplicaServer.New,
		ReadyPlayers = ReplicaServer.ReadyPlayers,
		NewReadyPlayer = ReplicaServer.NewReadyPlayer,
		ProfileToken = ReplicaServer.Token(DataConfig.PROFILE_TOKEN),
		SessionToken = ReplicaServer.Token(DataConfig.SESSION_TOKEN),
	}
end

-- the packages, loaded the first time they are needed
local function GetPackages() : Packages
	if DataService._Packages then
		return DataService._Packages
	end

	const Loader = DataService._Dependencies.LoadPackages or LoadRealPackages
	const Packages = Loader()

	DataService._Packages = Packages

	return Packages
end

-- where a write for Player goes, nil when that data is not there (not loaded yet, or the player left)
local function GetTarget(Player:Player, Source:DataSource?) : Target?
	if Source == "Session" then
		const Session = DataService._Sessions[Player]

		return if Session then { Data = Session.Data, Replica = Session.Replica } else nil
	end

	const Profile = DataService._Profiles[Player]

	if not Profile or not Profile:IsActive() then
		return nil
	end

	return { Data = Profile.Data, Replica = DataService._Replicas[Player] }
end

-- the table holding the last key of Path, and that key. nil when Path is not valid or its parent is not a table
local function GetParent(Data:any, Path:Path) : ({[any]:any}?, (string | number)?)
	if not DataPath:IsValid(Path) then
		return nil, nil
	end

	const ParentPath = table.move(Path, 1, #Path - 1, 1, {})
	const Parent = DataPath:Get(Data, ParentPath)

	if type(Parent) ~= "table" then
		return nil, nil
	end

	return Parent, Path[#Path]
end

-- sets Value at Path, through the replica when there is one so the client hears it. false when Path has no parent
local function WriteAt(Target:Target, Path:Path, Value:any) : boolean
	const Parent, Key = GetParent(Target.Data, Path)

	if not Parent or Key == nil then
		return false
	end

	if Target.Replica then
		Target.Replica:Set(Path :: {any}, Value)
	else
		Parent[Key] = Value
	end

	return true
end

-- the array at Path, nil when there is none
local function GetArray(Target:Target, Path:Path) : {any}?
	if not DataPath:IsValid(Path) then
		return nil
	end

	const Array = DataPath:Get(Target.Data, Path)

	return if type(Array) == "table" then Array else nil
end

-- the value SetValue writes: the operation applied, then the bounds. false (and why) when it cannot be worked out
local function ComputeValue(Old:any, Params:SetParams) : (boolean, any)
	const Operation = Params.MathOperation or "="
	local Result = Params.Value

	if Operation ~= "=" then
		const Apply = MATH_OPERATIONS[Operation]

		if not Apply then
			return false, `unknown MathOperation "{Operation}"`
		end

		if type(Old) ~= "number" or type(Params.Value) ~= "number" then
			return false, `"{Operation}" needs a number at the path and a number Value`
		end

		if Operation == "/" and Params.Value == 0 then
			return false, "division by zero"
		end

		Result = Apply(Old, Params.Value)
	end

	if type(Result) == "number" then
		if Result ~= Result then
			return false, "the result is not a number (NaN)"
		end

		if Params.MinValue then
			Result = math.max(Result, Params.MinValue)
		end

		if Params.MaxValue then
			Result = math.min(Result, Params.MaxValue)
		end
	end

	return true, Result
end

-- adds the time since play time was last counted to TimePlayed
local function CountTimePlayed(Player:Player)
	const CountedAt = DataService._CountedAt[Player]
	const Target = GetTarget(Player, "Profile")

	if not CountedAt or not Target then
		return
	end

	const Now = DataService._Dependencies.GetTime()
	const Played = DataPath:Get(Target.Data, { "TimeTrackers", "TimePlayed" })

	DataService._CountedAt[Player] = Now

	if type(Played) == "number" then
		WriteAt(Target, { "TimeTrackers", "TimePlayed" }, Played + (Now - CountedAt))
	end
end

-- stamps the join times when the profile has just loaded
local function StartTimeTracking(Player:Player, Profile:Profile)
	const Now = DataService._Dependencies.GetTime()
	const TimeTrackers = Profile.Data.TimeTrackers

	if TimeTrackers.FirstJoined == 0 then
		TimeTrackers.FirstJoined = Now
	end

	TimeTrackers.LastJoined = Now
	DataService._CountedAt[Player] = Now
end

-- wakes every thread waiting on Player's load with the answer
local function ResumeWaiting(Player:Player, Loaded:boolean)
	const Waiting = DataService._Waiting[Player]

	if not Waiting then
		return
	end

	DataService._Waiting[Player] = nil

	for _, Thread in Waiting do
		task.spawn(Thread, Loaded)
	end
end

-- marks Player loaded once their data is on their client and the client is ready. Spawns the character when the
-- game does not spawn characters on its own (Players.CharacterAutoLoads off)
local function TryFinishLoading(Player:Player)
	if table.find(DataService._Loaded, Player) then
		return
	end

	if not DataService._Replicas[Player] or not DataService._ClientReady[Player] then
		return
	end

	table.insert(DataService._Loaded, Player)

	if not Players.CharacterAutoLoads then
		task.spawn(function()
			const Success, Problem = pcall(Player.LoadCharacterAsync, Player)

			if not Success then
				warn(`[DataService] could not spawn {Player.Name}: {Problem}`)
			end
		end)
	end

	ResumeWaiting(Player, true)

	for _, Watcher in table.clone(DataService._Watchers) do
		task.spawn(Watcher, Player)
	end
end

-- creates Player's two replicas once their profile is loaded and their client has asked for data
local function TryReplicate(Player:Player)
	if DataService._Replicas[Player] then
		return
	end

	const Profile = DataService._Profiles[Player]
	const Session = DataService._Sessions[Player]
	const Packages = GetPackages()

	if not Profile or not Session or not Packages.ReadyPlayers[Player] then
		return
	end

	const Tags = { UserId = Player.UserId }
	const ProfileReplica = Packages.NewReplica({ Token = Packages.ProfileToken, Tags = Tags, Data = Profile.Data })
	const SessionReplica = Packages.NewReplica({ Token = Packages.SessionToken, Tags = Tags, Data = Session.Data })

	ProfileReplica:Subscribe(Player)
	SessionReplica:Subscribe(Player)

	DataService._Replicas[Player] = ProfileReplica
	Session.Replica = SessionReplica

	TryFinishLoading(Player)
end

-- forgets everything about Player and destroys their replicas. Their profile is ended by the caller
local function Forget(Player:Player)
	const Replica = DataService._Replicas[Player]
	const Session = DataService._Sessions[Player]
	const LoadedIndex = table.find(DataService._Loaded, Player)

	if Replica then
		Replica:Destroy()
	end

	if Session and Session.Replica then
		Session.Replica:Destroy()
	end

	if LoadedIndex then
		table.remove(DataService._Loaded, LoadedIndex)
	end

	DataService._Profiles[Player] = nil
	DataService._Replicas[Player] = nil
	DataService._Sessions[Player] = nil
	DataService._CountedAt[Player] = nil
	DataService._ClientReady[Player] = nil

	ResumeWaiting(Player, false)
end

-- // METHODS
-- Player's profile, nil until it has loaded or once they left. For ProfileStore features the setters do not cover
function DataService:GetProfile(Player:Player) : Profile?
	return DataService._Profiles[Player]
end

-- Player's saved-data replica, nil until their client has asked for data
function DataService:GetReplica(Player:Player) : Replica?
	return DataService._Replicas[Player]
end

-- Player's session, nil before they joined or once they left
function DataService:GetSession(Player:Player) : Session?
	return DataService._Sessions[Player]
end

-- Player's whole saved data, nil until it has loaded. Read it, never write to it: use the setters
function DataService:GetData(Player:Player) : DataTemplate.Data?
	const Target = GetTarget(Player, "Profile")

	return if Target then Target.Data :: DataTemplate.Data else nil
end

-- the saved value at Path ({"Settings", "MusicEnabled"}), nil when it is not there or not loaded
function DataService:GetValue(Player:Player, Path:Path) : any
	const Target = GetTarget(Player, "Profile")

	return if Target then DataPath:Get(Target.Data, Path) else nil
end

-- the session value at Path, nil when it is not there
function DataService:GetSessionValue(Player:Player, Path:Path) : any
	const Target = GetTarget(Player, "Session")

	return if Target then DataPath:Get(Target.Data, Path) else nil
end

-- sets the value at Path, optionally through a MathOperation and between MinValue and MaxValue (see SetParams).
-- false when the data is not loaded, the path has no parent, or the operation cannot apply
function DataService:SetValue(Params:SetParams) : boolean
	const Target = GetTarget(Params.Player, Params.Source)

	if not Target then
		return false
	end

	const Success, Result = ComputeValue(DataPath:Get(Target.Data, Params.Path), Params)

	if not Success then
		warn(`[DataService] SetValue {DataPath:ToText(Params.Path)} for {Params.Player.Name}: {Result}`)

		return false
	end

	return WriteAt(Target, Params.Path, Result)
end

-- adds Amount to the number at Path in saved data (negative to take away). false when there is no number there
function DataService:Increment(Player:Player, Path:Path, Amount:number) : boolean
	return DataService:SetValue({ Player = Player, Path = Path, Value = Amount, MathOperation = "+" })
end

-- sets several keys of the dictionary at Path in one replication. false when there is no dictionary there
function DataService:SetValues(Params:SetValuesParams) : boolean
	const Target = GetTarget(Params.Player, Params.Source)
	const Dictionary = if Target and DataPath:IsValid(Params.Path) then DataPath:Get(Target.Data, Params.Path) else nil

	if not Target or type(Dictionary) ~= "table" then
		return false
	end

	if Target.Replica then
		Target.Replica:SetValues(Params.Path :: {any}, Params.Values)
	else
		for Key, Value in Params.Values do
			Dictionary[Key] = Value
		end
	end

	return true
end

-- inserts Value into the array at Path, at Index or at the end. The index it landed at, nil when there is no array
function DataService:InsertInArray(Params:InsertParams) : number?
	const Target = GetTarget(Params.Player, Params.Source)
	const Array = if Target then GetArray(Target, Params.Path) else nil

	if not Target or not Array then
		return nil
	end

	if Params.Index and (Params.Index < 1 or Params.Index > #Array + 1) then
		return nil
	end

	if Target.Replica then
		return Target.Replica:TableInsert(Params.Path :: {any}, Params.Value, Params.Index)
	end

	const Index = Params.Index or #Array + 1
	table.insert(Array, Index, Params.Value)

	return Index
end

-- removes one entry from the array at Path: the one at Index, or the first equal to Value. The removed value, nil
-- when there is no array or no such entry
function DataService:RemoveFromArray(Params:RemoveParams) : any
	const Target = GetTarget(Params.Player, Params.Source)
	const Array = if Target then GetArray(Target, Params.Path) else nil

	if not Target or not Array then
		return nil
	end

	const Index = Params.Index or table.find(Array, Params.Value)

	if not Index or Array[Index] == nil then
		return nil
	end

	if Target.Replica then
		return Target.Replica:TableRemove(Params.Path :: {any}, Index)
	end

	return table.remove(Array, Index)
end

-- puts Player's saved data back to the template and kicks them, so they rejoin with it. false when not loaded
function DataService:ResetData(Player:Player) : boolean
	const Profile = DataService._Profiles[Player]

	if not Profile or not Profile:IsActive() then
		return false
	end

	-- in place: the replica and the profile keep pointing at the same table, and the kick saves it
	table.clear(Profile.Data)

	for Key, Value in DataPath:DeepCopy(DataTemplate) :: any do
		Profile.Data[Key] = Value
	end

	Player:Kick(KICK_DATA_RESET)

	return true
end

-- true once Player's data is on their client and their client is ready
function DataService:IsPlayerLoaded(Player:Player) : boolean
	return table.find(DataService._Loaded, Player) ~= nil
end

-- a copy of the list of loaded players
function DataService:GetLoadedPlayers() : {Player}
	return table.clone(DataService._Loaded)
end

-- waits until Player is loaded. true when they are, false when they left first (or right away, if not in game)
function DataService:WaitForLoaded(Player:Player) : boolean
	if DataService:IsPlayerLoaded(Player) then
		return true
	end

	if not DataService._Dependencies.IsInGame(Player) then
		return false
	end

	const Waiting = DataService._Waiting[Player] or {}
	DataService._Waiting[Player] = Waiting
	table.insert(Waiting, coroutine.running())

	return coroutine.yield()
end

-- calls Watcher for every player who loads from now on, and right away for those already loaded.
-- returns the function that stops it, keep it
function DataService:WatchPlayerLoaded(Watcher:LoadedWatcher) : () -> ()
	table.insert(DataService._Watchers, Watcher)

	for _, Player in table.clone(DataService._Loaded) do
		task.spawn(Watcher, Player)
	end

	return function()
		const Index = table.find(DataService._Watchers, Watcher)

		if Index then
			table.remove(DataService._Watchers, Index)
		end
	end
end

-- the ClientReady remote: Player's client has started every controller. Counted once
function DataService:_MarkClientReady(Player:Player)
	if DataService._ClientReady[Player] then
		return
	end

	DataService._ClientReady[Player] = true
	TryFinishLoading(Player)
end

-- loader hook: listens for clients asking for their data and for ready clients. Outside a running game it does
-- nothing, unless a test gave it fake packages (then it skips only the remote)
function DataService:Initialize()
	const Running = DataService._Dependencies.IsRunning()

	if not Running and not DataService._Dependencies.LoadPackages then
		return
	end

	table.insert(DataService._Connections, GetPackages().NewReadyPlayer:Connect(TryReplicate))

	if not Running then
		return
	end

	table.insert(DataService._Connections, Network:Listen("ClientReady", function(Player:Player)
		DataService:_MarkClientReady(Player)
	end))
end

-- loader hook: starts the session, then loads the profile (this yields until ProfileStore answers)
function DataService:OnPlayerAdded(Player:Player)
	const Now = DataService._Dependencies.GetTime()
	const SessionData = DataPath:DeepCopy(SessionTemplate)
	SessionData.JoinedAt = Now

	DataService._Sessions[Player] = { StartedAt = Now, Data = SessionData, Replica = nil }

	const Profile = GetPackages().Store:StartSessionAsync(`{KEY_PREFIX}{Player.UserId}`, {
		-- stop retrying once the player is gone
		Cancel = function() : boolean
			return not DataService._Dependencies.IsInGame(Player)
		end,
	})

	if not Profile then
		if DataService._Dependencies.IsInGame(Player) then
			Player:Kick(KICK_LOAD_FAILED)
		end

		return
	end

	if not DataService._Dependencies.IsInGame(Player) then
		Profile:EndSession()

		return
	end

	Profile:AddUserId(Player.UserId) -- GDPR: ties the data to the user for erasure requests
	Profile:Reconcile() -- fills in keys added to DataTemplate since this profile last saved

	Profile.OnSave:Connect(function()
		CountTimePlayed(Player)
	end)

	-- another server took the profile, or it ended: the player can't keep playing without saving
	Profile.OnSessionEnd:Connect(function()
		if DataService._Profiles[Player] ~= Profile then
			return
		end

		Forget(Player)

		if DataService._Dependencies.IsInGame(Player) then
			Player:Kick(KICK_SESSION_ENDED)
		end
	end)

	DataService._Profiles[Player] = Profile
	StartTimeTracking(Player, Profile)
	TryReplicate(Player)
end

-- loader hook: counts the last play time, ends the profile (which saves it) and forgets the player
function DataService:OnPlayerRemoving(Player:Player)
	const Profile = DataService._Profiles[Player]

	CountTimePlayed(Player)
	Forget(Player)

	if Profile then
		Profile:EndSession()
	end
end

return DataService
