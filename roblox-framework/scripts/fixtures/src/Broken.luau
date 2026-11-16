--!strict
-- broken syntax the style rules alone would miss: a literal \t left by an edit, a missing end, an unclosed bracket

-- // MODULE
local Broken = {
\tLastClaimedAt = 0,
}

-- never closes its if
function Broken:Run(Value:number)
	if Value > 0 then
		print(Value
end

return Broken
