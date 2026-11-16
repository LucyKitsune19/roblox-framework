--!strict
-- one kind of thing ExampleService runs, server half. Its name is its id: ExampleService finds it by name and
-- requires it the first time it is asked for. It may require its parent (script.Parent) safely, because the parent
-- only requires it later, from inside a function

-- // VARIABLES
const COOLDOWN = 2 -- seconds between two runs for the same player

-- // MODULE
local ExampleChild = {
	_LastRun = {} :: {[Player]:number},
}

-- // METHODS
-- does the work for Owner. false while Owner is still on cooldown
function ExampleChild:Run(Owner:Player) : boolean
	const Now = os.clock()
	const LastRun = ExampleChild._LastRun[Owner]

	if LastRun and Now - LastRun < COOLDOWN then
		return false
	end

	ExampleChild._LastRun[Owner] = Now
	print(`[ExampleChild] ran for {Owner.Name}`)

	return true
end

-- forgets Owner's cooldown (the player left)
function ExampleChild:Forget(Owner:Player)
	ExampleChild._LastRun[Owner] = nil
end

return ExampleChild
