--!strict
-- the only client script. Waits for the game, requires every controller in ReplicatedStorage.Controllers (each
-- followed by its Ui child) and calls its hooks: Initialize, then Start, then the character hooks. Then it tells the
-- server the client is ready (DataService spawns the player when characters don't load on their own).
-- a new system is a ModuleScript in that folder, never a new LocalScript

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Player = Players.LocalPlayer :: Player
const CHARACTER_TIME_OUT = 10 -- seconds a new character gets to stream its parts in before the hooks run anyway
-- what a character needs before the controllers' OnCharacterAdded runs (parts can stream in after the model)
const CHARACTER_READY_NAMES = { "Humanoid", "HumanoidRootPart" }

-- waits until every CHARACTER_READY_NAMES child is in Character, or until Deadline (an os.clock time)
local function WaitForBody(Character:Model, Deadline:number)
	for _, Name in CHARACTER_READY_NAMES do
		const Remaining = Deadline - os.clock()

		if Remaining <= 0 then
			return
		end

		Character:WaitForChild(Name, Remaining)
	end
end

-- boots every controller and wires the character hooks
local function LoadClient()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- waited for, then required by path so the checker knows each module's type
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Loader")
	ReplicatedStorage:WaitForChild("Controllers")

	const Loader = require(ReplicatedStorage.SharedModules.Loader)
	const Network = require(ReplicatedStorage.SharedModules.Network)
	const Controllers = Loader:Collect(ReplicatedStorage.Controllers)

	-- each character gets OnCharacterAdded once (the event and the boot check below can both see it), and
	-- OnCharacterRemoving only if it got OnCharacterAdded
	local HandledCharacter = nil :: Model? -- dispatched or being waited on
	local DispatchedCharacter = nil :: Model?

	-- waits for the body, then dispatches it. Skipped if the character was replaced or removed meanwhile
	local function OnCharacterAdded(Character:Model)
		if HandledCharacter == Character then
			return
		end

		HandledCharacter = Character

		WaitForBody(Character, os.clock() + CHARACTER_TIME_OUT)

		if HandledCharacter ~= Character or Player.Character ~= Character then
			return
		end

		DispatchedCharacter = Character
		Loader:CallAll(Controllers, "OnCharacterAdded", Character)
	end

	-- connected before the hooks run, so a respawn during Initialize or Start is not missed
	Player.CharacterAdded:Connect(OnCharacterAdded)

	Player.CharacterRemoving:Connect(function(Character:Model)
		if HandledCharacter == Character then
			HandledCharacter = nil
		end

		if DispatchedCharacter ~= Character then
			return
		end

		DispatchedCharacter = nil
		Loader:CallAll(Controllers, "OnCharacterRemoving", Character)
	end)

	Loader:CallAll(Controllers, "Initialize")
	Loader:CallAll(Controllers, "Start")

	-- after the hooks above were called: a yielding controller (DataController) has finished, the others have begun
	Network:FireServer("ClientReady")

	-- a character that arrived before the CharacterAdded connection above
	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end
end

LoadClient()
