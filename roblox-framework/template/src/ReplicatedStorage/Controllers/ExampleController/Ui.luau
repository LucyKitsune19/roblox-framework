--!strict
-- ExampleController's interface. The loader runs it right after its parent with the same hooks, so the parent never
-- requires it. It clones its ScreenGui from ReplicatedStorage.UiTemplates.ExampleUi (a RunButton TextButton and a
-- Status TextLabel) and never builds instances in code

-- // SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const ExampleController = require(script.Parent)

-- // VARIABLES
const TEMPLATE_NAME = "ExampleUi"
const CHILD_ID = "ExampleChild" -- the child the button asks the server to run

-- // CONTROLLER
local ExampleUi = {
	_Gui = nil :: ScreenGui?,
	_Cleanups = {} :: {() -> ()},
}

-- the template ScreenGui, nil (with a warning) when it is missing
local function FindTemplate() : ScreenGui?
	const Templates = ReplicatedStorage:FindFirstChild("UiTemplates")
	const Template = if Templates then Templates:FindFirstChild(TEMPLATE_NAME) else nil

	if not Template or not Template:IsA("ScreenGui") then
		warn(`[ExampleController.Ui] no ScreenGui named "{TEMPLATE_NAME}" in ReplicatedStorage.UiTemplates`)

		return nil
	end

	return Template
end

-- // METHODS
-- loader hook: clones the interface into the player's gui and wires the button and the status line
function ExampleUi:Start()
	const Template = FindTemplate()

	if not Template then
		return
	end

	const Gui = Template:Clone()
	const FoundButton = Gui:FindFirstChild("RunButton", true)
	const FoundStatus = Gui:FindFirstChild("Status", true)

	if not FoundButton or not FoundButton:IsA("TextButton") or not FoundStatus or not FoundStatus:IsA("TextLabel") then
		warn(`[ExampleController.Ui] "{TEMPLATE_NAME}" needs a RunButton TextButton and a Status TextLabel`)
		Gui:Destroy()

		return
	end

	-- typed bindings, so the closures below keep the refined types
	const RunButton:TextButton = FoundButton
	const Status:TextLabel = FoundStatus

	const Clicked = RunButton.Activated:Connect(function()
		ExampleController:Request(CHILD_ID)
	end)

	table.insert(ExampleUi._Cleanups, function()
		Clicked:Disconnect()
	end)

	table.insert(ExampleUi._Cleanups, ExampleController:WatchReplies(function(ChildId:string, Reply:ExampleController.ReplyKind)
		Status.Text = `{ChildId}: {Reply}`
	end))

	Gui.ResetOnSpawn = false
	Gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	ExampleUi._Gui = Gui
end

return ExampleUi
