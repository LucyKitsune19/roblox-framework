--!strict
-- valid code that is easy to misread: if-expressions over several lines, generics, keywords inside strings and
-- comments, nested functions, typed varargs, a multi-line string. The checker must find nothing here

-- // SERVICES
const Players = game:GetService("Players")

-- // TYPES
export type Pair<A, B> = {
	First:A,
	Second:B,
}

-- // VARIABLES
const TEXT = [[
	function end if then local lowercase = pairs(x) self:Do()
]]
const LIMIT = 3 -- things at most

-- // MODULE
local Good = {
	_Count = 0,
}

-- the bigger number, as an if-expression on one line
local function Bigger(A:number, B:number) : number
	return if A > B then A else B
end

-- a label for Value over several lines, with a nested helper
local function Label(Value:number) : string
	-- the sign as text
	local function Sign(Number:number) : string
		return if Number < 0
			then "-"
			else "+"
	end

	const Text = if Value > LIMIT then `big {Sign(Value)}` else "end then if function"

	if Value == 0 then return "zero" end

	return Text
end

-- // METHODS
-- swaps a pair. a generic method with a typed table parameter
function Good:Swap<A, B>(Input:Pair<A, B>) : Pair<B, A>
	return { First = Input.Second, Second = Input.First }
end

-- counts its arguments
function Good:Count(...:any) : number
	Good._Count += select("#", ...)

	for _, Player in Players:GetPlayers() do
		print(Player.Name, Bigger(1, 2), Label(Good._Count), TEXT)
	end

	return Good._Count
end

-- loader hook
function Good:Initialize()
	task.spawn(function()
		task.wait(1)
	end)

	-- check:ignore no-pairs
	print(#TEXT, "pairs(", "self:Do(")
end

-- does nothing, returns nothing
function Good:Nothing()
	if Good._Count > 0 then
		return
	end
end

return Good
