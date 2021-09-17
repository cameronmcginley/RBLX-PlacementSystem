local Unlockable = {}

Unlockable.__index = Unlockable

-- instance is the object
function Unlockable.new(tycoon, instance)
	local self = setmetatable({}, Unlockable)
	self.Tycoon = tycoon
	self.Instance = instance
	
	return self
end

function Unlockable:Init()
	-- Hook to topic
	-- Could just pass id to function, but we don't really need to know info here
	-- so just pass everything (even though just id)
	self.Subscription = self.Tycoon:SubscribeTopic("Button", function(...)
		self:OnButtonPressed(...)	
	end)
end

function Unlockable:OnButtonPressed(id)
	-- compare id given
	if id == self.Instance:GetAttribute("UnlockId") then
		self.Tycoon:Unlock(self.Instance, id)
		
		-- once unlocked, no point for unlockable to be subscribed to button topic
		self.Subscription:Disconnect()
	end
end

return Unlockable
