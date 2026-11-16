--!strict
-- the shape of a player's session data: replicated to the player like saved data, but never saved. It starts fresh
-- each time the player joins (a round score, a streak, a party). DataService fills JoinedAt itself

-- // TYPES
export type Data = {
	JoinedAt:number, -- os.time() this session started
	Streak:number, -- example value: things done in a row this session
}

-- // MODULE
-- the starting values. DataService copies them: never write to this table
const SessionTemplate:Data = {
	JoinedAt = 0,
	Streak = 0,
}

return SessionTemplate
