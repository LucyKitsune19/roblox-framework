--!strict
-- every RemoteEvent the game uses, named in one table both sides read, and the only code that creates or finds them.
-- ServerLoader creates them all before any service loads. On the client a remote is waited for the first time it is
-- used, so never call this at the top of a file: listen in Initialize.
-- if the project uses a packet library instead, this file is where its definitions go, and nothing else changes

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

-- // VARIABLES
const FOLDER_NAME = "Network" -- the folder under ReplicatedStorage that holds the remotes

-- every remote, by name. Add one here when a system needs it; never rename or remove one a live server still uses
const REMOTES = {
	ClientReady = true, -- client -> server: ClientLoader ran every controller's Start, the player may spawn
	ExampleRequest = true, -- client -> server: ExampleController asks ExampleService to run a child
	ExampleReply = true, -- server -> client: what came of it
}

-- // TYPES
-- below VARIABLES on purpose: the names are read from REMOTES, so the list is written once
-- check:ignore-file banners
export type RemoteName = keyof<typeof(REMOTES)>

-- // MODULE
local Network = {
	_Remotes = {} :: {[string]:RemoteEvent},
}

-- the remote with that name. Server: from the folder CreateRemotes made. Client: waits for it on first use
local function GetRemote(Name:RemoteName) : RemoteEvent
	const Cached = Network._Remotes[Name]

	if Cached then
		return Cached
	end

	const Folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	const Remote = Folder:WaitForChild(Name) :: RemoteEvent

	Network._Remotes[Name] = Remote

	return Remote
end

-- // METHODS
-- server only, called once by ServerLoader before the services load: makes the folder and every remote in it
function Network:CreateRemotes()
	assert(RunService:IsServer(), "[Network] CreateRemotes runs on the server only")

	if ReplicatedStorage:FindFirstChild(FOLDER_NAME) then
		return
	end

	const Folder = Instance.new("Folder")
	Folder.Name = FOLDER_NAME

	for Name in REMOTES do
		const Remote = Instance.new("RemoteEvent")
		Remote.Name = Name
		Remote.Parent = Folder

		Network._Remotes[Name] = Remote
	end

	-- parented last so a client never sees the folder half filled
	Folder.Parent = ReplicatedStorage
end

-- calls Callback each time the remote fires. On the server the first argument is the Player who sent it, and every
-- other argument is untrusted: check its type and its range before using it. Returns the connection, keep it
function Network:Listen(Name:RemoteName, Callback:(...any) -> ()) : RBXScriptConnection
	const Remote = GetRemote(Name)

	if RunService:IsServer() then
		return Remote.OnServerEvent:Connect(Callback)
	end

	return Remote.OnClientEvent:Connect(Callback)
end

-- client only: sends the arguments to the server
function Network:FireServer(Name:RemoteName, ...:any)
	GetRemote(Name):FireServer(...)
end

-- server only: sends the arguments to one player
function Network:FireClient(Name:RemoteName, Player:Player, ...:any)
	GetRemote(Name):FireClient(Player, ...)
end

-- server only: sends the arguments to every player
function Network:FireAllClients(Name:RemoteName, ...:any)
	GetRemote(Name):FireAllClients(...)
end

return Network
