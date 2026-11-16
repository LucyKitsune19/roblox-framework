--!strict
-- reading and comparing paths into nested data ({"Inventory", "Swords", 2}). DataService and DataController both walk
-- player data with these, so a path means the same thing on both sides. Pure functions, no state

-- // TYPES
export type Path = {string | number}

-- // MODULE
local DataPath = {}

-- // METHODS
-- the value at Path inside Data, nil as soon as a key is missing or something on the way is not a table.
-- an empty path is Data itself
function DataPath:Get(Data:any, Path:Path) : any
	local Current = Data

	for _, Key in Path do
		if type(Current) ~= "table" then
			return nil
		end

		Current = Current[Key]
	end

	return Current
end

-- true when one path is the start of the other, or they are equal: a change at one can change the value at the other
function DataPath:Overlaps(PathA:Path, PathB:Path) : boolean
	for Index = 1, math.min(#PathA, #PathB) do
		if PathA[Index] ~= PathB[Index] then
			return false
		end
	end

	return true
end

-- true when the two paths name the same place
function DataPath:Equals(PathA:Path, PathB:Path) : boolean
	if #PathA ~= #PathB then
		return false
	end

	return DataPath:Overlaps(PathA, PathB)
end

-- true for a path a caller may use: a non-empty array of strings and whole numbers
function DataPath:IsValid(Path:any) : boolean
	if type(Path) ~= "table" or #Path == 0 then
		return false
	end

	for _, Key in Path do
		if type(Key) == "number" then
			if Key % 1 ~= 0 then
				return false
			end
		elseif type(Key) ~= "string" then
			return false
		end
	end

	return true
end

-- the path as text ("Inventory.Swords.2"), for warnings
function DataPath:ToText(Path:Path) : string
	const Parts = {} :: {string}

	for _, Key in Path do
		table.insert(Parts, tostring(Key))
	end

	return table.concat(Parts, ".")
end

-- a full copy of Value: tables are copied all the way down, everything else is returned as is
function DataPath:DeepCopy<T>(Value:T) : T
	if type(Value) ~= "table" then
		return Value
	end

	const Copy = {}

	for Key, Inner in Value :: any do
		Copy[Key] = DataPath:DeepCopy(Inner)
	end

	return Copy :: any
end

return DataPath
