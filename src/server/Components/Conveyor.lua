local Conveyor = {}
Conveyor.__index = Conveyor

function Conveyor.new(tycoon, instance)
	local self = setmetatable({}, Conveyor)
	self.Instance = instance
	self.Speed = instance:GetAttribute("Speed")
	
	return self
end

function Conveyor:Init()
	local belt = self.Instance.Belt
	
	-- Points toward front face, gives speed
	belt.AssemblyLinearVelocity = belt.CFrame.LookVector * self.Speed
end

return Conveyor
