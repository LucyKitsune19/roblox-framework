--!strict
-- what ExampleService and ExampleController must agree on: the reply names and the limits on a request.
-- shared modules hold data and pure helpers only, no state and no hooks

-- // TYPES
-- what the server tells the asking client
export type ReplyKind = "Done" | "Refused"

-- // VARIABLES
const MAX_ID_LENGTH = 32 -- characters: a child id longer than this is not one

-- // MODULE
local ExampleConfig = {
	MAX_ID_LENGTH = MAX_ID_LENGTH,
}

-- // METHODS
-- true for a child id a client may send: a string of 1 to MAX_ID_LENGTH characters
function ExampleConfig:IsChildId(Value:any) : boolean
	return type(Value) == "string" and #Value > 0 and #Value <= MAX_ID_LENGTH
end

-- true for one of the ReplyKind names
function ExampleConfig:IsReplyKind(Value:any) : boolean
	return Value == "Done" or Value == "Refused"
end

return ExampleConfig
