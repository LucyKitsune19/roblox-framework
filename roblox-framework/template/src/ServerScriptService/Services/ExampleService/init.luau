--!strict
-- template for the server half of a system: copy the folder, rename it (and its children), delete what you don't use.
-- it owns the system's server rules. Each kind of thing the system runs is a child module named after its id
-- (ExampleChild.luau), required the first time it is asked for, so a game with many kinds only loads the ones used.
-- clients ask through the ExampleRequest remote; other services call ExampleService:Run directly

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleConfig = require(ReplicatedStorage.SharedModules.ExampleConfig)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- // TYPES
-- the shape every child module must return. Run is required, the rest is optional
export type ServerChild = {
	-- does the child's work for Owner. false when it refuses
	Run:(self:ServerChild, Owner:Player) -> boolean,
	-- forgets anything it keeps for Owner (the player left)
	Forget:((self:ServerChild, Owner:Player) -> ())?,
}

export type ReplyKind = ExampleConfig.ReplyKind

-- how many requests a player sent in one whole second of the clock
type RequestRate = {
	Second:number,
	Count:number,
}

-- // VARIABLES
const REQUESTS_PER_SECOND = 5 -- requests one player may send each second, the rest are dropped

-- // MODULE
local ExampleService = {
	_Holder = script :: Instance, -- where the child modules are. a test puts its own folder here
	_Children = {} :: {[string]:ServerChild},
	_Failed = {} :: {[string]:boolean}, -- ids whose module failed to load: not tried again
	_Requests = {} :: {[Player]:RequestRate},
	_Connections = {} :: {RBXScriptConnection},
	-- what the service reaches for outside itself, so a test can swap them
	_Dependencies = {
		GetTime = os.clock,
	},
}

-- the child with that id, required on first use. nil when there is none, it failed to load, or it has no Run
local function GetChild(ChildId:string) : ServerChild?
	const Loaded = ExampleService._Children[ChildId]

	if Loaded then
		return Loaded
	end

	if ExampleService._Failed[ChildId] then
		return nil
	end

	const Module = ExampleService._Holder:FindFirstChild(ChildId)

	if not Module or not Module:IsA("ModuleScript") then
		return nil
	end

	const Success, Result = pcall(require, Module)

	if not Success or type(Result) ~= "table" or type(Result.Run) ~= "function" then
		ExampleService._Failed[ChildId] = true
		warn(`[ExampleService] the child "{ChildId}" failed to load: {if Success then "it has no Run function" else Result}`)

		return nil
	end

	const Child = Result :: ServerChild
	ExampleService._Children[ChildId] = Child

	return Child
end

-- true while Owner is under the request limit this second, and counts this request
local function TakeRequest(Owner:Player) : boolean
	const Second = math.floor(ExampleService._Dependencies.GetTime())
	local Rate = ExampleService._Requests[Owner]

	if not Rate or Rate.Second ~= Second then
		Rate = { Second = Second, Count = 0 }
		ExampleService._Requests[Owner] = Rate
	end

	Rate.Count += 1

	return Rate.Count <= REQUESTS_PER_SECOND
end

-- one request from a client. Everything it sent is checked before use: the types guarantee nothing over the network
local function HandleRequest(Owner:Player, ChildId:any)
	if not TakeRequest(Owner) then
		return
	end

	if not ExampleConfig:IsChildId(ChildId) then
		return
	end

	const Reply:ReplyKind = if ExampleService:Run(Owner, ChildId) then "Done" else "Refused"

	Network:FireClient("ExampleReply", Owner, ChildId, Reply)
end

-- // METHODS
-- runs the child with that id for Owner. false when there is no such child or it refused
function ExampleService:Run(Owner:Player, ChildId:string) : boolean
	const Child = GetChild(ChildId)

	if not Child then
		return false
	end

	return Child:Run(Owner)
end

-- loader hook: listens for requests
function ExampleService:Initialize()
	table.insert(ExampleService._Connections, Network:Listen("ExampleRequest", HandleRequest))
end

-- loader hook: forgets the player everywhere, children included
function ExampleService:OnPlayerRemoving(Player:Player)
	ExampleService._Requests[Player] = nil

	for _, Child in ExampleService._Children do
		if Child.Forget then
			Child:Forget(Player)
		end
	end
end

return ExampleService
