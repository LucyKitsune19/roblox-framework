--!strict
-- DataPath: reading, comparing and checking paths

-- // SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const DataPath = require(ReplicatedStorage.SharedModules.DataPath)
const TestRunner = require(script.Parent.TestRunner)

type Check = TestRunner.Check

-- // MODULE
return {
	-- nested reads, missing keys, numbers as keys, a non-table on the way
	Get = function(Check:Check)
		const Data = { A = { B = { 10, 20 } }, Flat = 5 }

		Check:Equal(DataPath:Get(Data, { "A", "B", 2 }), 20, "nested index")
		Check:Equal(DataPath:Get(Data, { "A", "Missing", 1 }), nil, "missing key")
		Check:Equal(DataPath:Get(Data, { "Flat", "Deeper" }), nil, "through a number")
		Check:Equal(DataPath:Get(Data, {}), Data, "empty path is the data")
		Check:Equal(DataPath:Get(nil, { "A" }), nil, "nil data")
	end,

	-- prefixes overlap both ways, siblings do not
	Overlaps = function(Check:Check)
		Check:True(DataPath:Overlaps({ "A" }, { "A", "B" }), "parent and child")
		Check:True(DataPath:Overlaps({ "A", "B" }, { "A" }), "child and parent")
		Check:True(DataPath:Overlaps({ "A", "B" }, { "A", "B" }), "equal")
		Check:True(not DataPath:Overlaps({ "A", "B" }, { "A", "C" }), "siblings")
		Check:True(DataPath:Equals({ "A", 1 }, { "A", 1 }), "equals")
		Check:True(not DataPath:Equals({ "A" }, { "A", 1 }), "prefix is not equal")
	end,

	-- only non-empty arrays of strings and whole numbers
	IsValid = function(Check:Check)
		Check:True(DataPath:IsValid({ "A", 2 }), "strings and integers")
		Check:True(not DataPath:IsValid({}), "empty")
		Check:True(not DataPath:IsValid({ "A", 1.5 }), "fraction")
		Check:True(not DataPath:IsValid({ "A", true }), "boolean")
		Check:True(not DataPath:IsValid("A"), "not a table")
	end,

	-- a deep copy shares no table with the original
	DeepCopy = function(Check:Check)
		const Original = { A = { B = 1 } }
		const Copy = DataPath:DeepCopy(Original)

		Check:True(Copy ~= Original and Copy.A ~= Original.A, "new tables")
		Check:Equal(Copy.A.B, 1, "same values")
	end,
} :: TestRunner.Spec
