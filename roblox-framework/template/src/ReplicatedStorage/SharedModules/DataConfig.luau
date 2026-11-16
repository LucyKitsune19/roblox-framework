--!strict
-- what DataService and DataController must agree on: the names the two replicas are created and found under

-- // TYPES
-- which data a call is about: the saved profile, or the session data that is never saved
export type DataSource = "Profile" | "Session"

-- // MODULE
const DataConfig = {
	PROFILE_TOKEN = "PlayerData", -- the replica holding a player's saved data
	SESSION_TOKEN = "PlayerSession", -- the replica holding a player's session data
}

return DataConfig
