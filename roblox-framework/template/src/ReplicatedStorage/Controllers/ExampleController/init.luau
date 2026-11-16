--!strict
-- template for the client half of a system: copy the folder, rename it, delete what you don't use.
-- it sends the player's requests to ExampleService and tells whoever watches (its Ui child, other controllers) what
-- came back. Its interface lives in the Ui child, which the loader runs right after it

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleConfig = require(ReplicatedStorage.SharedModules.ExampleConfig)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- // TYPES
export type ReplyKind = ExampleConfig.ReplyKind

export type ReplyWatcher = (ChildId:string, Reply:ReplyKind) -> ()

-- // CONTROLLER
local ExampleController = {
	_Character = nil :: Model?,
	_Watchers = {} :: {ReplyWatcher},
	_Connections = {} :: {RBXScriptConnection},
}

-- tells every watcher about one reply. A watcher that errors stops no other
local function Announce(ChildId:string, Reply:ReplyKind)
	for _, Watcher in table.clone(ExampleController._Watchers) do
		task.spawn(Watcher, ChildId, Reply)
	end
end

-- one reply from the server, checked before use like anything off the network
local function HandleReply(ChildId:any, Reply:any)
	if not ExampleConfig:IsChildId(ChildId) or not ExampleConfig:IsReplyKind(Reply) then
		return
	end

	Announce(ChildId :: string, Reply :: ReplyKind)
end

-- // METHODS
-- asks the server to run the child with that id. false when there is no character to run it with
function ExampleController:Request(ChildId:string) : boolean
	if not ExampleController._Character then
		return false
	end

	Network:FireServer("ExampleRequest", ChildId)

	return true
end

-- calls Watcher with every reply from now on. Returns the function that stops it, keep it
function ExampleController:WatchReplies(Watcher:ReplyWatcher) : () -> ()
	table.insert(ExampleController._Watchers, Watcher)

	return function()
		const Index = table.find(ExampleController._Watchers, Watcher)

		if Index then
			table.remove(ExampleController._Watchers, Index)
		end
	end
end

-- loader hook: listens for replies. Here, not at the top of the file: Network waits for the remote on first use
function ExampleController:Initialize()
	table.insert(ExampleController._Connections, Network:Listen("ExampleReply", HandleReply))
end

-- loader hook: the player's body is ready
function ExampleController:OnCharacterAdded(Character:Model)
	ExampleController._Character = Character
end

-- loader hook: the player's body is going away
function ExampleController:OnCharacterRemoving(Character:Model)
	if ExampleController._Character == Character then
		ExampleController._Character = nil
	end
end

return ExampleController
