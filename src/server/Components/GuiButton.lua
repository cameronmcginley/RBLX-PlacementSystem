local PlayerManager = require(script.Parent.Parent.PlayerManager)
--local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
--local placeablesFolder = ReplicatedStorage.Placeables
local componentFolder = script.Parent
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent

local GuiButton = {}

GuiButton.__index = GuiButton

function GuiButton.new(tycoon, part)
	local self = setmetatable({}, GuiButton)
	self.Tycoon = tycoon
	self.Instance = part
	
	return self
end

function GuiButton:Init()
	print("GuiButton init")

	-- MB1Click doesn't auto pass player
	local player = self.Tycoon.Owner
	self.Instance.MouseButton1Click:Connect(function()
		self:Press(player)
	end)
end

function GuiButton:Press(player)
	local id = self.Instance:GetAttribute("Id")
	local cost = self.Instance:GetAttribute("Cost")

	print(player)
	local money = PlayerManager.GetMoney(player)

	if player == self.Tycoon.Owner and money >= cost then
		print(player.Name .. " purchased ButtonId: " .. id)
		PlayerManager.SetMoney(player, money - cost)

		-- publish button id to topic, all placeables listening will check if it
		-- matches their id
		--self.Tycoon:PublishTopic("GuiButton", id)	

		-- Get the placeable from the storage
		--local placeable = placeablesFolder:FindFirstChild(id)
		-- local compModule = require(componentFolder:FindFirstChild("Placeable"))
		-- local newComp = compModule.new(self, placeable, cost)
		-- newComp:Init()


		local selectEvent = ReplicatedStorage:WaitForChild('Select') -- tell client to run module
		print(id)
		selectEvent:FireClient(self.Tycoon.Owner, self.Tycoon, id, cost)
	end
end

return GuiButton
