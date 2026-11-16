--!strict
-- the only server Script. Creates the remotes, requires every service in ServerScriptService.Services and calls its
-- hooks: Initialize, then Start, then the player and character hooks. A new system is a ModuleScript in that folder,
-- never a new Script

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const Loader = require(ReplicatedStorage.SharedModules.Loader)
const Network = require(ReplicatedStorage.SharedModules.Network)

-- boots every service and wires the player hooks
local function LoadServer()
	-- before any service loads, so a service can listen in Initialize and a client never waits on a missing remote
	Network:CreateRemotes()

	const Services = Loader:Collect(ServerScriptService.Services)

	Loader:CallAll(Services, "Initialize")
	Loader:CallAll(Services, "Start")

	-- connects before reading Player.Character so a spawn is never missed, and works when characters do not
	-- load on their own (CharacterAutoLoads off, a menu that spawns the player later)
	local function OnPlayerAdded(Player:Player)
		Loader:CallAll(Services, "OnPlayerAdded", Player)

		Player.CharacterAdded:Connect(function(Character:Model)
			Loader:CallAll(Services, "OnCharacterAdded", Player, Character)
		end)

		Player.CharacterRemoving:Connect(function(Character:Model)
			Loader:CallAll(Services, "OnCharacterRemoving", Player, Character)
		end)

		if Player.Character then
			Loader:CallAll(Services, "OnCharacterAdded", Player, Player.Character)
		end
	end

	Players.PlayerAdded:Connect(OnPlayerAdded)

	-- players who joined while the services were loading
	for _, Player in Players:GetPlayers() do
		task.spawn(OnPlayerAdded, Player)
	end

	Players.PlayerRemoving:Connect(function(Player:Player)
		Loader:CallAll(Services, "OnPlayerRemoving", Player)
	end)
end

LoadServer()
