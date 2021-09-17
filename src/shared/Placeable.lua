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
	self.Instance = placeablesFolder:FindFirstChild(id)
	
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

	Placing = UIS.InputBegan:Connect(function(i)
		-- When the user clicks (left mouse button)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			hasPlaced = self:PlacePosition(self.placeable, true, placeEvent, self.IgnoreList)

			-- End placing after instance has been placed
			if hasPlaced then
				Placing:Disconnect()
				Stepped:Disconnect()
			end
		end
	end)

	-- RenderStepped will run every frame for the client (60ish times a second)
	Stepped = RunService.RenderStepped:Connect(function()
		self:PlacePosition(self.placeable, false, placeEvent, self.IgnoreList)
	end)
end

function Placeable:PlacePosition(placeable, toPlace, placeEvent)
	-- Get the mouse location using the User Input Service
	local mouseLocation = UIS:GetMouseLocation()
	-- Get the target object and position

	local target, position = self:getMousePoint(mouseLocation.X, mouseLocation.Y, self.IgnoreList)

	--print(self.Tycoon)
	--print(placeable)
	if placeable.Parent ~= self.Tycoon.Model then
		placeable.Parent = self.Tycoon.Model
	end

	-- If the target object and position BOTH exist
	if target and target.Name == "Base" and position then
		-- Set the bed there for the client
		placeable.PrimaryPart.CFrame = CFrame.new(position + Vector3.new(0,.1,0))
		
		if toPlace then
			placeEvent:FireServer(position, placeable, target)
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
