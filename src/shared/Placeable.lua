local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService") -- for mouse input
local RunService = game:GetService('RunService') -- for RenderStepped / live input from the user 
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local placeablesFolder = ReplicatedStorage.Placeables

local Placeable = {}

Placeable.__index = Placeable

-- instance is the object
function Placeable.new(tycoon, id, cost)
	local self = setmetatable({}, Placeable)
	self.Tycoon = tycoon

	self.PlaceableID = id
	self.Instance = placeablesFolder:FindFirstChild(id)

	-- Cloned via client, CAN NOT PASS THIS TO SERVER
	-- Pass its id instead, then clone new one from serverstorage
	self.placeable = placeablesFolder:WaitForChild(self.Instance.Name):clone()

	-- Ignore list
	-- Everything inside template model + user
	 self.IgnoreList = self.Tycoon.Model:GetDescendants()
	table.insert(self.IgnoreList, self.placeable)
	table.remove(self.IgnoreList, table.find(self.IgnoreList, self.Tycoon.Model.Base))
	print(self.IgnoreList)

	return self
end

function Placeable:Init()
	--print("Placeable id " .. self.Instance.Name .. " initialized")
	--print(self.Instance)
	--print(self.Instance.Name)
	self:Place()
end

-- params: X(x position on the screen), Y(y position on the screen), IgnoreList(List of objects to ignore when making raycast)
-- returns: Instance(object that the player's mouse is on), Vector3(position that the player's mouse is on)
function Placeable:getMousePoint(X, Y)
	local camera = workspace.CurrentCamera

	-- Create a new set of Raycast Parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist -- have the mouse ignore objects
	raycastParams.FilterDescendantsInstances = self.IgnoreList -- have the mouse ignore the bed
	raycastParams.IgnoreWater = true

	local camray = camera:ScreenPointToRay(X, Y) -- get the position on the world relative to the mouse's screen position(x,y)

	-- Draw the ray in the world, pointing at wherever the mouse is
	local raycastResult = workspace:Raycast(camray.Origin, camray.Direction * 2048, raycastParams)

	-- If the draw failed, or the mouse is pointing at the sky, return nil
	if not raycastResult then return nil end

	-- Otherwise, return the part and position the mouse is over
	return raycastResult.Instance, raycastResult.Position
end

function Placeable:Place()
	--print("Placing " .. self.Instance.Name)

	local placeEvent = ReplicatedStorage:WaitForChild('Place') -- RemoteEvent to tell server to place object
	local hasPlaced = false

	local Placing
	local Stepped

	-- Place on click
	Placing = UIS.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			hasPlaced = self:PlacePosition(self.placeable, true, placeEvent, self.IgnoreList)

			-- Verify it was actually placed, above fires on invalid positions still
			if hasPlaced then
				-- Faster we disconnect placing the better, don't want duplicate placements
				Placing:Disconnect()
				Stepped:Disconnect()
			end
		end
	end)

	-- Move ghost with mouse
	-- RenderStepped will run every frame for the client (60ish times a second)
	Stepped = RunService.RenderStepped:Connect(function()
		self:PlacePosition(self.placeable, false, placeEvent, self.IgnoreList)
	end)
end

function Placeable:PlacePosition(placeable, toPlace, placeEvent)
	local mouseLocation = UIS:GetMouseLocation()
	local target, position = self:getMousePoint(mouseLocation.X, mouseLocation.Y, self.IgnoreList)

	if placeable.Parent ~= self.Tycoon.Model then
		placeable.Parent = self.Tycoon.Model
	end

	-- Move ghost to client target
	if target and target.Name == "Base" and position then
		-- Position sinks into ground by half of the primary parts height, add to y
		position = CFrame.new(position + Vector3.new(0,.1,0))
		placeable.PrimaryPart.CFrame = position
		
		if toPlace then
			-- Pass desired position and id of desired placeable
			placeEvent:FireServer(position, self.PlaceableID, self.Tycoon.Model)
			return true
		else
			return false
		end
	end
end

function Placeable:Kill()
	-- Destroy the cloned, ghost model
	
end



return Placeable
