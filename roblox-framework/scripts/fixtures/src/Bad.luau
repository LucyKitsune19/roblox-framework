-- no strict line on line 1
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES
const Folder = ReplicatedStorage:WaitForChild("Things")

-- // SERVICES
const lowerName = 5

-- // WHATEVER
local Bad = {}

local function NoComment(Value)
	return Value
end

-- returns without saying so
local function Untyped(Count:number)
	if Count > 0 then
		return Count
	end
	return 0
end

-- iterates the old way
function Bad:Loop(List:{any})
	for i, Item in ipairs(List) do
		print(i, Item)
	end
	for _, Item in pairs(List) do
		print(Item)
	end
end

-- uses self
function Bad:UsesSelf()
	self:Loop({})
	print(self.Thing)
end

-- a reserved hook name used for something else
function Bad:OnHit(Target:Model)
	print(Target)
end

-- also reserved
function Bad:Start(Params:{any})
	print(Params)
end

-- makes its own remote
function Bad:MakeRemote() : RemoteEvent
	return Instance.new("RemoteEvent")
end

-- untyped varargs
function Bad:Many(...)
	print(...)
end

return Bad
