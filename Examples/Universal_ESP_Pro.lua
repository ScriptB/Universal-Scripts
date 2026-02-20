--[[
	Universal ESP Pro - Professional ESP System
	Designed from scratch using best practices from multiple ESP libraries
	
	Features:
	- Clean, modular architecture
	- Efficient rendering and memory management
	- Multiple ESP types (Box, Name, Health, Tracer, Arrow)
	- Proper error handling and cleanup
	- Performance optimized
	- Easy to extend and modify
]]

print("🚀 Loading Universal ESP Pro...")

-- ===================================
-- SERVICES AND VARIABLES
-- ===================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ===================================
-- CONFIGURATION
-- ===================================

local ESPConfig = {
	Enabled = true,
	TeamCheck = false,
	MaxDistance = 1000,
	
	-- ESP Features
	Box = {
		Enabled = true,
		Color = Color3.fromRGB(255, 0, 0),
		Thickness = 1,
		Transparency = 1
	},
	
	Name = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Size = 14,
		ShowDistance = true,
		ShowHealth = true
	},
	
	Health = {
		Enabled = true,
		Width = 4,
		Height = 40,
		Background = Color3.fromRGB(0, 0, 0),
		Healthy = Color3.fromRGB(0, 255, 0),
		Damaged = Color3.fromRGB(255, 0, 0)
	},
	
	Tracer = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 1
	},
	
	Arrow = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 0),
		Size = 15,
		Distance = 100
	}
}

-- ===================================
-- UTILITY FUNCTIONS
-- ===================================

local function isDrawingAvailable()
	local success, drawing = pcall(function()
		return Drawing
	end)
	return success and drawing
end

local function worldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function getDistance(part1, part2)
	return (part1.Position - part2.Position).Magnitude
end

local function getPlayerColor(player)
	if ESPConfig.TeamCheck and player.Team and LocalPlayer.Team then
		return player.TeamColor == LocalPlayer.TeamColor and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	end
	return ESPConfig.Box.Color
end

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- ===================================
-- ESP OBJECT MANAGEMENT
-- ===================================

local ESPObjects = {}
local Connections = {}

local function createDrawing(type, properties)
	local drawing = Drawing.new(type)
	for prop, value in pairs(properties) do
		drawing[prop] = value
	end
	return drawing
end

local function cleanupPlayerESP(player)
	if ESPObjects[player] then
		for _, espType in pairs(ESPObjects[player]) do
			if type(espType) == "table" then
				for _, obj in pairs(espType) do
					if obj and obj.Remove then
						obj:Remove()
					end
				end
			elseif espType and espType.Remove then
				espType:Remove()
			end
		end
		ESPObjects[player] = nil
	end
	
	if Connections[player] then
		for _, connection in pairs(Connections[player]) do
			if connection then
				connection:Disconnect()
			end
		end
		Connections[player] = nil
	end
end

-- ===================================
-- BOX ESP
-- ===================================

local function createBoxESP(player)
	if not ESPConfig.Box.Enabled then return {} end
	
	local box = {}
	
	-- Create 4 lines for box corners
	for i = 1, 4 do
		box[i] = createDrawing("Line", {
			Visible = false,
			Color = ESPConfig.Box.Color,
			Thickness = ESPConfig.Box.Thickness,
			Transparency = ESPConfig.Box.Transparency
		})
	end
	
	return box
end

local function updateBoxESP(player, box)
	if not box or not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
		for _, line in pairs(box) do
			line.Visible = false
		end
		return
	end
	
	local position, onScreen = worldToScreen(rootPart.Position)
	if not onScreen then
		for _, line in pairs(box) do
			line.Visible = false
		end
		return
	end
	
	-- Calculate box dimensions
	local size = Vector3.new(3, 4.5, 1) -- Approximate character size
	local cf = CFrame.new(rootPart.Position, Camera.CFrame.Position)
	
	-- Get corners
	local corners = {
		Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, 0)).Position)
	}
	
	-- Update corner lines (simplified corner box)
	local cornerLength = 10
	local color = getPlayerColor(player)
	
	-- Top-left
	box[1].From = Vector2.new(corners[1].X, corners[1].Y)
	box[1].To = Vector2.new(corners[1].X - cornerLength, corners[1].Y)
	box[1].Color = color
	
	box[2].From = Vector2.new(corners[1].X, corners[1].Y)
	box[2].To = Vector2.new(corners[1].X, corners[1].Y - cornerLength)
	box[2].Color = color
	
	-- Top-right
	box[3].From = Vector2.new(corners[2].X, corners[2].Y)
	box[3].To = Vector2.new(corners[2].X + cornerLength, corners[2].Y)
	box[3].Color = color
	
	box[4].From = Vector2.new(corners[2].X, corners[2].Y)
	box[4].To = Vector2.new(corners[2].X, corners[2].Y - cornerLength)
	box[4].Color = color
	
	-- Show box
	for _, line in pairs(box) do
		line.Visible = true
	end
end

-- ===================================
-- NAME ESP
-- ===================================

local function createNameESP(player)
	if not ESPConfig.Name.Enabled then return nil end
	
	return createDrawing("Text", {
		Visible = false,
		Color = ESPConfig.Name.Color,
		Size = ESPConfig.Name.Size,
		Center = true,
		Outline = true
	})
end

local function updateNameESP(player, nameText)
	if not nameText or not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
		nameText.Visible = false
		return
	end
	
	local position, onScreen = worldToScreen(head.Position + Vector3.new(0, 2, 0))
	if not onScreen then
		nameText.Visible = false
		return
	end
	
	-- Build name text
	local text = player.Name
	
	if ESPConfig.Name.ShowDistance then
		local distance = getDistance(rootPart, LocalPlayer.Character.HumanoidRootPart)
		text = text .. " [" .. math.floor(distance) .. "m]"
	end
	
	if ESPConfig.Name.ShowHealth then
		text = text .. " [" .. math.floor(humanoid.Health) .. "HP]"
	end
	
	nameText.Text = text
	nameText.Position = position
	nameText.Visible = true
end

-- ===================================
-- HEALTH BAR ESP
-- ===================================

local function createHealthESP(player)
	if not ESPConfig.Health.Enabled then return {} end
	
	return {
		background = createDrawing("Square", {
			Visible = false,
			Color = ESPConfig.Health.Background,
			Filled = true,
			Transparency = 1
		}),
		health = createDrawing("Square", {
			Visible = false,
			Color = ESPConfig.Health.Healthy,
			Filled = true,
			Transparency = 1
		})
	}
end

local function updateHealthESP(player, healthBar)
	if not healthBar or not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		healthBar.background.Visible = false
		healthBar.health.Visible = false
		return
	end
	
	local position, onScreen = worldToScreen(rootPart.Position)
	if not onScreen then
		healthBar.background.Visible = false
		healthBar.health.Visible = false
		return
	end
	
	-- Calculate health percentage
	local healthPercent = clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	
	-- Position health bar
	local barX = position.X - 30
	local barY = position.Y - 20
	
	-- Update background
	healthBar.background.Size = Vector2.new(ESPConfig.Health.Width, ESPConfig.Health.Height)
	healthBar.background.Position = Vector2.new(barX, barY)
	
	-- Update health bar
	healthBar.health.Size = Vector2.new(ESPConfig.Health.Width, ESPConfig.Health.Height * healthPercent)
	healthBar.health.Position = Vector2.new(barX, barY + ESPConfig.Health.Height * (1 - healthPercent))
	
	-- Update color based on health
	healthBar.health.Color = healthPercent < 0.3 and ESPConfig.Health.Damaged or ESPConfig.Health.Healthy
	
	healthBar.background.Visible = true
	healthBar.health.Visible = true
end

-- ===================================
-- TRACER ESP
-- ===================================

local function createTracerESP(player)
	if not ESPConfig.Tracer.Enabled then return nil end
	
	return createDrawing("Line", {
		Visible = false,
		Color = ESPConfig.Tracer.Color,
		Thickness = ESPConfig.Tracer.Thickness,
		Transparency = ESPConfig.Tracer.Transparency
	})
end

local function updateTracerESP(player, tracer)
	if not tracer or not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
		tracer.Visible = false
		return
	end
	
	local headPos, onScreen = worldToScreen(head.Position)
	if not onScreen then
		tracer.Visible = false
		return
	end
	
	-- Draw tracer from bottom of screen to head
	tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	tracer.To = Vector2.new(headPos.X, headPos.Y)
	tracer.Visible = true
end

-- ===================================
-- ARROW ESP (Off-screen indicator)
-- ===================================

local function createArrowESP(player)
	if not ESPConfig.Arrow.Enabled then return nil end
	
	return createDrawing("Triangle", {
		Visible = false,
		Color = ESPConfig.Arrow.Color,
		Filled = true,
		Thickness = 1,
		Transparency = 1
	})
end

local function updateArrowESP(player, arrow)
	if not arrow or not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		arrow.Visible = false
		return
	end
	
	local _, onScreen = worldToScreen(rootPart.Position)
	
	-- Only show arrow when player is off-screen
	if not onScreen then
		-- Calculate direction to player
		local direction = (rootPart.Position - Camera.CFrame.Position).Unit
		local screenCenter = Camera.ViewportSize / 2
		
		-- Project direction to screen
		local angle = math.atan2(direction.Z, direction.X)
		local screenAngle = angle - math.pi/2
		
		-- Calculate arrow position on screen edge
		local distance = ESPConfig.Arrow.Distance
		local arrowX = screenCenter.X + math.cos(screenAngle) * distance
		local arrowY = screenCenter.Y + math.sin(screenAngle) * distance
		
		-- Create triangle points
		local size = ESPConfig.Arrow.Size
		local point1 = Vector2.new(arrowX, arrowY - size)
		local point2 = Vector2.new(arrowX - size/2, arrowY + size/2)
		local point3 = Vector2.new(arrowX + size/2, arrowY + size/2)
		
		arrow.PointA = point1
		arrow.PointB = point2
		arrow.PointC = point3
		arrow.Visible = true
	else
		arrow.Visible = false
	end
end

-- ===================================
-- MAIN ESP SYSTEM
-- ===================================

local function createPlayerESP(player)
	cleanupPlayerESP(player)
	
	ESPObjects[player] = {}
	Connections[player] = {}
	
	-- Create ESP objects
	ESPObjects[player].Box = createBoxESP(player)
	ESPObjects[player].Name = createNameESP(player)
	ESPObjects[player].Health = createHealthESP(player)
	ESPObjects[player].Tracer = createTracerESP(player)
	ESPObjects[player].Arrow = createArrowESP(player)
end

local function updatePlayerESP(player)
	if not ESPObjects[player] or not ESPConfig.Enabled then return end
	
	-- Update each ESP type
	updateBoxESP(player, ESPObjects[player].Box)
	updateNameESP(player, ESPObjects[player].Name)
	updateHealthESP(player, ESPObjects[player].Health)
	updateTracerESP(player, ESPObjects[player].Tracer)
	updateArrowESP(player, ESPObjects[player].Arrow)
end

-- ===================================
-- PLAYER MANAGEMENT
-- ===================================

local function onPlayerAdded(player)
	if player == LocalPlayer then return end
	
	-- Wait for character to load
	local characterAdded
	characterAdded = player.CharacterAdded:Connect(function()
		createPlayerESP(player)
	end)
	
	-- Create ESP if character already exists
	if player.Character then
		createPlayerESP(player)
	end
	
	-- Store connection
	Connections[player] = Connections[player] or {}
	table.insert(Connections[player], characterAdded)
end

local function onPlayerRemoving(player)
	cleanupPlayerESP(player)
end

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function initializeESP()
	-- Check if Drawing is available
	if not isDrawingAvailable() then
		warn("❌ Drawing service not available - ESP disabled")
		return
	end
	
	print("✅ Universal ESP Pro loaded successfully!")
	
	-- Setup existing players
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Main update loop
	RunService.RenderStepped:Connect(function()
		if not ESPConfig.Enabled then return end
		
		-- Update all players
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				updatePlayerESP(player)
			end
		end
	end)
end

-- ===================================
-- CONFIGURATION FUNCTIONS
-- ===================================

local function toggleESP(enabled)
	ESPConfig.Enabled = enabled
	print("ESP:", enabled and "ON" or "OFF")
end

local function toggleBoxESP(enabled)
	ESPConfig.Box.Enabled = enabled
	print("Box ESP:", enabled and "ON" or "OFF")
end

local function toggleNameESP(enabled)
	ESPConfig.Name.Enabled = enabled
	print("Name ESP:", enabled and "ON" or "OFF")
end

local function toggleHealthESP(enabled)
	ESPConfig.Health.Enabled = enabled
	print("Health ESP:", enabled and "ON" or "OFF")
end

local function toggleTracerESP(enabled)
	ESPConfig.Tracer.Enabled = enabled
	print("Tracer ESP:", enabled and "ON" or "OFF")
end

local function toggleArrowESP(enabled)
	ESPConfig.Arrow.Enabled = enabled
	print("Arrow ESP:", enabled and "ON" or "OFF")
end

-- ===================================
-- EXPORT API
-- ===================================

getgenv().UniversalESP = {
	toggleESP = toggleESP,
	toggleBoxESP = toggleBoxESP,
	toggleNameESP = toggleNameESP,
	toggleHealthESP = toggleHealthESP,
	toggleTracerESP = toggleTracerESP,
	toggleArrowESP = toggleArrowESP,
	Config = ESPConfig
}

-- Start the ESP system
initializeESP()

print("🎯 Universal ESP Pro functions exported to getgenv().UniversalESP")
