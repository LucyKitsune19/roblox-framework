--!strict
-- finds, requires, orders and calls the modules a loader script runs: every ModuleScript directly inside a folder,
-- each followed right away by its "Ui" child when it has one. Only ServerLoader and ClientLoader use it.
-- a module that fails to load, or whose hook errors, is warned about by name and stops no other module

-- // TYPES
-- the hooks a loader calls. These names are reserved: a module never uses them for anything else
export type HookName =
	"Initialize"
	| "Start"
	| "OnPlayerAdded"
	| "OnPlayerRemoving"
	| "OnCharacterAdded"
	| "OnCharacterRemoving"

export type LoadedModule = {
	Name:string,
	Content:any, -- the module's table, its shape is its own
	Instance:ModuleScript,
	LoadOrder:number?, -- the "LoadOrder" attribute: lower runs first, modules without one run after, by name
	DoesYield:boolean, -- the "DoesYield" attribute: its hooks run inline and the next module waits for them
}

-- // MODULE
local Loader = {}

-- the module's table, nil (with a warning naming it) when it errors or does not return a table
local function TryRequire(Module:ModuleScript, Name:string) : any
	const Success, Result = pcall(require, Module)

	if not Success then
		warn(`[Loader] "{Name}" failed to load: {Result}`)

		return nil
	end

	if type(Result) ~= "table" then
		warn(`[Loader] "{Name}" does not return a table, it is skipped`)

		return nil
	end

	return Result
end

-- a LoadedModule for Module, nil when it failed to load
local function Load(Module:ModuleScript, Name:string, LoadOrder:number?) : LoadedModule?
	const Content = TryRequire(Module, Name)

	if not Content then
		return nil
	end

	return {
		Name = Name,
		Content = Content,
		Instance = Module,
		LoadOrder = LoadOrder,
		DoesYield = Module:GetAttribute("DoesYield") == true,
	}
end

-- true when A runs before B: by LoadOrder, then by name so the order is the same every boot
local function RunsBefore(A:LoadedModule, B:LoadedModule) : boolean
	if A.LoadOrder ~= B.LoadOrder then
		return (A.LoadOrder :: number) < (B.LoadOrder :: number)
	end

	return A.Name < B.Name
end

-- // METHODS
-- every ModuleScript directly inside Holder, required and sorted, each followed by its "Ui" child.
-- children other than Ui are never loaded here: their parent module loads them
function Loader:Collect(Holder:Instance) : {LoadedModule}
	const WithOrder = {} :: {LoadedModule}
	const WithoutOrder = {} :: {LoadedModule}

	for _, Child in Holder:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		const LoadOrder = Child:GetAttribute("LoadOrder")
		const Loaded = Load(Child, Child.Name, if type(LoadOrder) == "number" then LoadOrder else nil)

		if not Loaded then
			continue
		end

		table.insert(if Loaded.LoadOrder then WithOrder else WithoutOrder, Loaded)
	end

	table.sort(WithOrder, RunsBefore)
	table.sort(WithoutOrder, RunsBefore)

	const Sorted = {} :: {LoadedModule}

	-- the Ui child requires its parent, so it is loaded after it and the parent never requires it
	for _, List in { WithOrder, WithoutOrder } do
		for _, Loaded in List do
			table.insert(Sorted, Loaded)

			const Ui = Loaded.Instance:FindFirstChild("Ui")

			if not Ui or not Ui:IsA("ModuleScript") then
				continue
			end

			const LoadedUi = Load(Ui, `{Loaded.Name}.Ui`, Loaded.LoadOrder)

			if LoadedUi then
				table.insert(Sorted, LoadedUi)
			end
		end
	end

	return Sorted
end

-- calls HookName on every module that has it, with the arguments given. A yielding module runs inline, the others
-- each in their own thread. An error is warned about with the module's name and stops no other module
function Loader:CallAll(Modules:{LoadedModule}, HookName:HookName, ...:any)
	const Arguments = table.pack(...)

	for _, Loaded in Modules do
		const Hook = Loaded.Content[HookName]

		if type(Hook) ~= "function" then
			continue
		end

		-- runs the hook under the module's memory category, warning with its name if it errors
		local function Invoke()
			debug.setmemorycategory(Loaded.Name)

			const Success, Problem = xpcall(Hook, debug.traceback, Loaded.Content, table.unpack(Arguments, 1, Arguments.n))

			if not Success then
				warn(`[Loader] {Loaded.Name}:{HookName} failed: {Problem}`)
			end
		end

		if Loaded.DoesYield then
			Invoke()
		else
			task.spawn(Invoke)
		end
	end
end

return Loader
