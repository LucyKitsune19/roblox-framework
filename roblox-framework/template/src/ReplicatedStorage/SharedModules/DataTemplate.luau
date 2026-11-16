--!strict
-- the shape of a player's saved data and its starting values. DataService saves it with ProfileStore; DataController
-- reads the type. Add a key here and every profile gets it on its next load (Reconcile). Never rename or remove a key
-- a live profile still has: write a migration in DataService first.
-- only JSON-safe values: strings, numbers, booleans, and tables of those (no Instances, Vector3s or mixed tables)

-- // TYPES
export type TimeTrackers = {
	FirstJoined:number, -- os.time() of the first session, 0 until then
	LastJoined:number, -- os.time() the current or last session started
	TimePlayed:number, -- seconds played over every session
}

export type Data = {
	Coins:number,
	Inventory:{string},
	Settings:{
		MusicEnabled:boolean,
	},
	TimeTrackers:TimeTrackers,
}

-- // MODULE
-- the starting values. ProfileStore copies them: never write to this table
const DataTemplate:Data = {
	Coins = 0,
	Inventory = {},
	Settings = {
		MusicEnabled = true,
	},
	TimeTrackers = {
		FirstJoined = 0,
		LastJoined = 0,
		TimePlayed = 0,
	},
}

return DataTemplate
