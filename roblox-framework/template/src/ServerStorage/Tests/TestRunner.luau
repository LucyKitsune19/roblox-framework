--!strict
-- runs the unit tests: every "<Name>.spec" ModuleScript in this folder returns a table of test functions, each given
-- a Check to assert with. Run from the command bar, in Edit:
--     require(game.ServerStorage.Tests.TestRunner:Clone()):Run()
-- (the clone gets past Studio's require cache, so an edited runner is never served stale)
-- a test gets fresh copies of the modules it tests through Check:Fresh, so no state leaks between tests or runs

-- // TYPES
export type Check = {
	Equal:(self:Check, Actual:any, Expected:any, Label:string?) -> (),
	True:(self:Check, Value:any, Label:string?) -> (),
	Fresh:(self:Check, Module:ModuleScript) -> any,
}

export type Spec = {[string]:(Check:Check) -> ()}

export type Result = {
	Run:number,
	Failed:{string},
}

-- // MODULE
local TestRunner = {}

-- a Check that adds every failed assertion to Failures under the test's name
local function NewCheck(TestName:string, Failures:{string}) : Check
	const Check = {}

	-- fails when Actual is not Expected (==)
	function Check:Equal(Actual:any, Expected:any, Label:string?)
		if Actual ~= Expected then
			table.insert(Failures, `{TestName}: {Label or "value"} was {tostring(Actual)}, expected {tostring(Expected)}`)
		end
	end

	-- fails when Value is false or nil
	function Check:True(Value:any, Label:string?)
		if not Value then
			table.insert(Failures, `{TestName}: {Label or "condition"} was {tostring(Value)}`)
		end
	end

	-- a fresh copy of Module, required: its state is new. Its requires of other modules are shared as usual
	function Check:Fresh(Module:ModuleScript) : any
		return require(Module:Clone()) :: any
	end

	return Check :: any
end

-- // METHODS
-- runs every spec in Folder (this folder when nil), prints a summary and every failure, and returns them
function TestRunner:Run(Folder:Instance?) : Result
	const Holder = Folder or script.Parent :: Instance
	const Result:Result = { Run = 0, Failed = {} }

	for _, Module in Holder:GetChildren() do
		if not Module:IsA("ModuleScript") or not string.match(Module.Name, "%.spec$") then
			continue
		end

		-- a clone, so an edited spec is not served from the require cache. Parented beside the original while it
		-- loads, because a spec requires script.Parent.TestRunner
		const Copy = Module:Clone()
		Copy.Name = `{Module.Name}.Running`
		Copy.Parent = Holder

		const Loaded, Spec = pcall(require, Copy)

		Copy:Destroy()

		if not Loaded or type(Spec) ~= "table" then
			table.insert(Result.Failed, `{Module.Name}: failed to load: {Spec}`)

			continue
		end

		for TestName, Test in Spec :: Spec do
			const FullName = `{Module.Name} > {TestName}`
			const Passed, Problem = xpcall(Test, debug.traceback, NewCheck(FullName, Result.Failed))

			Result.Run += 1

			if not Passed then
				table.insert(Result.Failed, `{FullName}: errored: {Problem}`)
			end
		end
	end

	print(`[TestRunner] {Result.Run} run, {#Result.Failed} failed`)

	for _, Failure in Result.Failed do
		warn(`[TestRunner] {Failure}`)
	end

	return Result
end

return TestRunner
