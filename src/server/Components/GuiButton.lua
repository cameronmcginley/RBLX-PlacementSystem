local PlayerManager = require(script.Parent.Parent.PlayerManager)
--local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
--local placeablesFolder = ReplicatedStorage.Placeables
local componentFolder = script.Parent
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local HttpService = game:GetService("HttpService")

local GuiButton = {}

GuiButton.__index = GuiButton

function GuiButton.new(tycoon, part)
	local self = setmetatable({}, GuiButton)
	self.Tycoon = tycoon
	self.Instance = part
	self.ButtonId = self.Instance:GetAttribute("Id")
	self.Cost = self.Instance:GetAttribute("Cost")
	self.bindableEvent = game.ServerStorage.ServerToButton
	
	return self
end

function GuiButton:Init()
	print("GuiButton init")

	local debounce = false
	local lastClick = 0

	local function onClick()
		-- Use debounce AND tick() to prevent autoclicking
		-- Autoclicking at 1ms gets 3-4 clicks past debounce, tick()
		-- can catch this though
		if not debounce then 
			debounce = true

			local thisClick = tick()
			print(thisClick)
			if thisClick - lastClick < 1 then
				warn("Autoclicking")
				lastClick = thisClick
				debounce = false
				return
			end
			lastClick = thisClick

			self:Press(self.Tycoon.Owner)
			debounce = false
			return
		end
	end

	self.clickDetect = self.Instance.MouseButton1Click:Connect(onClick)

	-- self.Subscription = self.Tycoon:SubscribeTopic("Placement", function(...)
	-- 	self:OnItemPlaced(...)	
	-- end)
end

function GuiButton:Press(player, debounce)
	local debounce = false
	if not debounce then
		debounce = true

		local money = PlayerManager.GetMoney(player)

		if player == self.Tycoon.Owner and money >= self.Cost then
			-- Lock button
			self:DisableButton()

			print(player.Name .. " purchased ButtonId: " .. self.ButtonId)
			PlayerManager.SetMoney(player, money - self.Cost)

			-- Generate uuid for the item
			local uuid = HttpService:GenerateGUID(false)

			local selectEvent = ReplicatedStorage:WaitForChild('Select') -- tell client to run module
			selectEvent:FireClient(self.Tycoon.Owner, self.Tycoon, self.ButtonId, uuid, self.Cost)
		end
	end

	-- Unlock button
	local unlockButton
	unlockButton = self.bindableEvent.Event:Connect(function()
		print("Button has heard the event")
		self:EnableButton()
		unlockButton:Disconnect()
	end)
end

function GuiButton:DisableButton()
	print("Disabling button")
	self.Instance.Visible = false
end

function GuiButton:EnableButton()
	print("Enabling button")
	self.Instance.Visible = true
end

return GuiButton
