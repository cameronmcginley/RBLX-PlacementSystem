local PlayerManager = require(script.Parent.Parent.PlayerManager)

local Button = {}

Button.__index = Button

function Button.new(tycoon, part)
	local self = setmetatable({}, Button)
	self.Tycoon = tycoon
	self.Instance = part
	
	return self
end

function Button:Init()
	print("Button init")
	self.Prompt = self:CreatePrompt()
	self.Prompt.Triggered:Connect(function(...)
		-- called when key held for duration, gives player as attr
		self:Press(...)
	end)
end

-- proximity prompt
-- default is 'e' key
function Button:CreatePrompt()
	local prompt = Instance.new("ProximityPrompt")
	
	prompt.HoldDuration = 0.5
	prompt.ActionText = self.Instance:GetAttribute("Display")
	prompt.ObjectText = "$" .. self.Instance:GetAttribute("Cost")
	prompt.Parent = self.Instance
	
	return prompt
end

function Button:Press(player)
	-- unlocks everything with matching Id and UnlockId
	local id = self.Instance:GetAttribute("Id")
	local cost = self.Instance:GetAttribute("Cost")
	local money = PlayerManager.GetMoney(player)
	
	if player == self.Tycoon.Owner and money >= cost then
		print(player.Name .. " purchased ButtonId: " .. id)
		PlayerManager.SetMoney(player, money - cost)
		-- publish button id to topic, all unlockables listening will check it it
		-- matches their id
		self.Tycoon:PublishTopic("Button", id)
		
		-- Despawn component handles this
		-- self.Instance:Destroy()		
	end
end

return Button
