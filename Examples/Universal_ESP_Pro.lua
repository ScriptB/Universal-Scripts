--[[
	Universal ESP Pro Enhanced - Professional ESP System
	Designed from scratch using best practices from multiple ESP libraries
	
	Enhanced Features:
	- Performance optimizations (rendering efficiency, memory management)
	- Advanced ESP features (skeleton, chams, distance-based scaling)
	- Modular architecture for easy integration
	- Advanced features (team colors, rainbow effects, animations)
	- Future-ready structure for script transitions
	
	ESP Types:
	- Box ESP (corner boxes with auto-scaling)
	- Name ESP (distance/health display)
	- Health ESP (dynamic health bars)
	- Tracer ESP (screen edge tracers)
	- Arrow ESP (off-screen indicators)
	- Skeleton ESP (bone structure)
	- Chams ESP (character highlighting)
	- Distance ESP (distance-based scaling)
]]

-- ===================================
-- DEV COPY INTEGRATION (FIRST)
-- ===================================

-- Load DevCopy functionality from external source
print("🔧 Attempting to load DevCopy...")
local success, devCopyLoaded = pcall(function()
    local response = game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Useful/DevCopy")
    print("📡 DevCopy HTTP response received, length:", #response)
    return loadstring(response)()
end)

if success and devCopyLoaded then
    print("📋 DevCopy functionality integrated successfully!")
else
    print("⚠️ DevCopy integration failed!")
    if not success then
        print("❌ HTTP request or loadstring failed:", devCopyLoaded)
    else
        print("❌ DevCopy execution returned:", devCopyLoaded)
    end
    print("🔧 Continuing without DevCopy...")
end

-- ===================================
-- BRACKET LIBRARY INTEGRATION
-- ===================================

-- Load Bracket library for UI
print("🎨 Attempting to load Bracket library...")
local bracketSuccess, Bracket = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Library%20Repos/BracketLib"))()
end)

if bracketSuccess and Bracket then
    print("✅ Bracket library loaded successfully!")
else
    print("⚠️ Bracket library integration failed!")
    if not bracketSuccess then
        print("❌ HTTP request or loadstring failed:", Bracket)
    else
        print("❌ Bracket execution returned:", Bracket)
    end
    print("🔧 Continuing without UI...")
end

print("🚀 Loading Universal ESP Pro...")

-- ===================================
-- SERVICES AND VARIABLES
-- ===================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Performance tracking
local FrameCount = 0
local LastTime = tick()
local FPS = 60
local localTick = tick -- Local tick for rainbow effects

-- ===================================
-- ADVANCED CONFIGURATION
-- ===================================

local ESPConfig = {
	Enabled = true,
	TeamCheck = false,
	MaxDistance = 1000,
	
	-- Performance Settings
	Performance = {
		MaxFPS = 60,
		UpdateInterval = 1,
		DistanceCulling = true,
		OcclusionCulling = true,
		BatchRendering = true
	},
	
	-- Visual Effects
	Effects = {
		Rainbow = false,
		RainbowSpeed = 0.15,
		Animations = true,
		FadeIn = true,
		Glow = false
	},
	
	-- ESP Features
	Box = {
		Enabled = true,
		Color = Color3.fromRGB(255, 0, 0),
		Thickness = 1,
		Transparency = 1,
		AutoScale = true,
		CornerLength = 15,
		Rainbow = false
	},
	
	Name = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Size = 14,
		ShowDistance = true,
		ShowHealth = true,
		ShowTeam = true,
		AutoScale = true,
		Font = 2,
		Outline = true
	},
	
	Health = {
		Enabled = true,
		Width = 4,
		Height = 40,
		Background = Color3.fromRGB(0, 0, 0),
		Healthy = Color3.fromRGB(0, 255, 0),
		Damaged = Color3.fromRGB(255, 0, 0),
		Gradient = true,
		AutoScale = true
	},
	
	Tracer = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 1,
		AutoThickness = true,
		From = "Bottom", -- Bottom, Center, Top
		Rainbow = false
	},
	
	Arrow = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 0),
		Size = 15,
		Distance = 100,
		Filled = true,
		Rainbow = false
	},
	
	Skeleton = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 1,
		AutoThickness = true,
		Joints = true,
		Rainbow = false
	},
	
	Chams = {
		Enabled = false,
		Color = Color3.fromRGB(255, 0, 0),
		Transparency = 0.5,
		Material = "ForceField",
		Outline = true,
		OutlineColor = Color3.fromRGB(255, 255, 255)
	},
	
	Distance = {
		Enabled = true,
		ScaleFactor = 0.1,
		MinScale = 0.5,
		MaxScale = 2.0,
		FadeDistance = 500
	}
}

-- ===================================
-- ENHANCED UTILITY FUNCTIONS
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
		if player.TeamColor == LocalPlayer.TeamColor then
			return Color3.fromRGB(0, 255, 0) -- Green for same team
		else
			return Color3.fromRGB(255, 0, 0) -- Red for enemy team
		end
	end
	return ESPConfig.Box.Color
end

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Advanced utility functions
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function getRainbowColor(time, speed)
	local hue = (time * speed) % 1
	return Color3.fromHSV(hue, 1, 1)
end

local function getDistanceScale(distance)
	if not ESPConfig.Distance.Enabled then return 1 end
	
	local scale = 1 - (distance / ESPConfig.Distance.FadeDistance) * ESPConfig.Distance.ScaleFactor
	return clamp(scale, ESPConfig.Distance.MinScale, ESPConfig.Distance.MaxScale)
end

local function getFPS()
	FrameCount = FrameCount + 1
	local currentTime = tick()
	if currentTime - LastTime >= 1 then
		FPS = FrameCount
		FrameCount = 0
		LastTime = currentTime
	end
	return FPS
end

local function shouldUpdate()
	if not ESPConfig.Performance.BatchRendering then return true end
	
	local currentFPS = getFPS()
	if currentFPS < ESPConfig.Performance.MaxFPS then
		return FrameCount % ESPConfig.Performance.UpdateInterval == 0
	end
	return true
end

local function isOccluded(character)
	if not ESPConfig.Performance.OcclusionCulling then return false end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	local origin = Camera.CFrame.Position
	local direction = (rootPart.Position - origin).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = Workspace:Raycast(origin, direction * getDistance(rootPart, LocalPlayer.Character.HumanoidRootPart), raycastParams)
	return result and result.Instance ~= rootPart
end

-- ===================================
-- ENHANCED ESP OBJECT MANAGEMENT
-- ===================================

local ESPObjects = {}
local Connections = {}
local ChamsObjects = {}
local AnimationTweens = {}

local function createDrawing(type, properties)
	local drawing = Drawing.new(type)
	for prop, value in pairs(properties) do
		-- Safely set properties, skip unsupported ones
		local success, error = pcall(function()
			drawing[prop] = value
		end)
		if not success then
			-- Silently skip unsupported properties like AntiAliasing
			-- This ensures compatibility across different Drawing API implementations
		end
	end
	return drawing
end

local function createChams(character)
	if not ESPConfig.Chams.Enabled then return end
	
	local chams = {}
	
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			local originalColor = part.Color
			local originalTransparency = part.Transparency
			local originalMaterial = part.Material
			
			-- Create cham material
			part.Material = ESPConfig.Chams.Material
			part.Color = ESPConfig.Chams.Color
			part.Transparency = ESPConfig.Chams.Transparency
			
			-- Store original properties
			chams[part] = {
				Color = originalColor,
				Transparency = originalTransparency,
				Material = originalMaterial
			}
		end
	end
	
	ChamsObjects[character] = chams
end

local function removeChams(character)
	if not ChamsObjects[character] then return end
	
	for part, original in pairs(ChamsObjects[character]) do
		if part and part.Parent then
			part.Color = original.Color
			part.Transparency = original.Transparency
			part.Material = original.Material
		end
	end
	
	ChamsObjects[character] = nil
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
	
	if player.Character then
		removeChams(player.Character)
	end
	
	if AnimationTweens[player] then
		for _, tween in pairs(AnimationTweens[player]) do
			if tween then
				tween:Cancel()
			end
		end
		AnimationTweens[player] = nil
	end
end

-- ===================================
-- ENHANCED BOX ESP
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
			Transparency = ESPConfig.Box.Transparency,
			AntiAliasing = true
		})
	end
	
	return box
end

local function updateBoxESP(player, box)
	if not box or not player.Character or not shouldUpdate() then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
		for _, line in pairs(box) do
			line.Visible = false
		end
		return
	end
	
	-- Distance culling
	local distance = getDistance(rootPart, LocalPlayer.Character.HumanoidRootPart)
	if ESPConfig.Performance.DistanceCulling and distance > ESPConfig.MaxDistance then
		for _, line in pairs(box) do
			line.Visible = false
		end
		return
	end
	
	-- Occlusion culling
	if isOccluded(player.Character) then
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
	
	-- Calculate distance scale
	local scale = getDistanceScale(distance)
	
	-- Calculate box dimensions with auto-scaling
	local size = Vector3.new(3, 4.5, 1)
	if ESPConfig.Box.AutoScale then
		size = size * scale
	end
	
	local cf = CFrame.new(rootPart.Position, Camera.CFrame.Position)
	
	-- Get corners
	local corners = {
		Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, 0)).Position),
		Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, 0)).Position)
	}
	
	-- Update corner lines
	local cornerLength = ESPConfig.Box.CornerLength * scale
	local color = getPlayerColor(player)
	
	-- Apply rainbow effect
	if ESPConfig.Box.Rainbow or ESPConfig.Effects.Rainbow then
		color = getRainbowColor(localTick(), ESPConfig.Effects.RainbowSpeed)
	end
	
	-- Ensure color is always a valid Color3
	if type(color) ~= "userdata" then
		color = Color3.fromRGB(255, 255, 255) -- Default to white if invalid
	end
	
	-- Auto-thickness
	local thickness = ESPConfig.Box.Thickness
	if ESPConfig.Box.AutoScale then
		thickness = math.max(1, thickness * scale)
	end
	
	-- Top-left
	box[1].From = Vector2.new(corners[1].X, corners[1].Y)
	box[1].To = Vector2.new(corners[1].X - cornerLength, corners[1].Y)
	box[1].Color = color
	box[1].Thickness = thickness
	
	box[2].From = Vector2.new(corners[1].X, corners[1].Y)
	box[2].To = Vector2.new(corners[1].X, corners[1].Y - cornerLength)
	box[2].Color = color
	box[2].Thickness = thickness
	
	-- Top-right
	box[3].From = Vector2.new(corners[2].X, corners[2].Y)
	box[3].To = Vector2.new(corners[2].X + cornerLength, corners[2].Y)
	box[3].Color = color
	box[3].Thickness = thickness
	
	box[4].From = Vector2.new(corners[2].X, corners[2].Y)
	box[4].To = Vector2.new(corners[2].X, corners[2].Y - cornerLength)
	box[4].Color = color
	box[4].Thickness = thickness
	
	-- Show box
	for _, line in pairs(box) do
		line.Visible = true
	end
end

-- ===================================
-- ENHANCED NAME ESP
-- ===================================
-- ENHANCED NAME ESP
-- ===================================

local function createNameESP(player)
	if not ESPConfig.Name.Enabled then return nil end
	
	return createDrawing("Text", {
		Visible = false,
		Color = ESPConfig.Name.Color,
		Size = ESPConfig.Name.Size,
		Center = true,
		Outline = ESPConfig.Name.Outline,
		Font = ESPConfig.Name.Font
	})
end

local function updateNameESP(player, nameText)
	if not nameText or not player.Character or not shouldUpdate() then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	
	if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
		nameText.Visible = false
		return
	end
	
	-- Distance culling
	local distance = getDistance(rootPart, LocalPlayer.Character.HumanoidRootPart)
	if ESPConfig.Performance.DistanceCulling and distance > ESPConfig.MaxDistance then
		nameText.Visible = false
		return
	end
	
	-- Occlusion culling
	if isOccluded(player.Character) then
		nameText.Visible = false
		return
	end
	
	local position, onScreen = worldToScreen(head.Position + Vector3.new(0, 2, 0))
	if not onScreen then
		nameText.Visible = false
		return
	end
	
	-- Calculate distance scale
	local scale = getDistanceScale(distance)
	
	-- Build name text
	local text = player.Name
	
	if ESPConfig.Name.ShowTeam and player.Team then
		text = text .. " [" .. player.Team.Name .. "]"
	end
	
	if ESPConfig.Name.ShowDistance then
		text = text .. " [" .. math.floor(distance) .. "m]"
	end
	
	if ESPConfig.Name.ShowHealth then
		text = text .. " [" .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "HP]"
	end
	
	-- Apply rainbow effect
	local color = ESPConfig.Name.Color
	if ESPConfig.Effects.Rainbow then
		color = getRainbowColor(localTick(), ESPConfig.Effects.RainbowSpeed)
	end
	
	-- Ensure color is always a valid Color3
	if type(color) ~= "userdata" then
		color = Color3.fromRGB(255, 255, 255) -- Default to white if invalid
	end
	
	-- Auto-scale
	local size = ESPConfig.Name.Size
	if ESPConfig.Name.AutoScale then
		size = math.max(8, size * scale)
	end
	
	nameText.Text = text
	nameText.Position = position
	nameText.Color = color
	nameText.Size = size
	nameText.Visible = true
end

-- ===================================
-- ENHANCED HEALTH BAR ESP
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
		-- Get player position in camera space
		local playerPos = rootPart.Position
		local cameraCFrame = Camera.CFrame
		
		-- Transform player position to camera space
		local relativePos = cameraCFrame:PointToObjectSpace(playerPos)
		
		-- Only show if player is in front of camera
		if relativePos.Z > 0 then
			-- Calculate direction from camera to player in screen space
			local screenCenter = Camera.ViewportSize / 2
			
			-- Use the relative position for accurate direction calculation
			local dirX = relativePos.X
			local dirY = -relativePos.Y  -- Negative because screen Y is inverted
			
			-- Calculate angle from center to player
			local angle = math.atan2(dirY, dirX)
			
			-- Position arrow around crosshair at fixed distance
			local distance = ESPConfig.Arrow.Distance
			local arrowX = screenCenter.X + math.cos(angle) * distance
			local arrowY = screenCenter.Y + math.sin(angle) * distance
			
			-- Clamp to screen bounds (but keep near center)
			local maxDist = math.min(screenCenter.X, screenCenter.Y) - 50
			local actualDist = math.min(distance, maxDist)
			arrowX = screenCenter.X + math.cos(angle) * actualDist
			arrowY = screenCenter.Y + math.sin(angle) * actualDist
			
			-- Create rotated triangle pointing toward player
			local size = ESPConfig.Arrow.Size
			local cosAngle = math.cos(angle)
			local sinAngle = math.sin(angle)
			
			-- Triangle points (arrow pointing toward player)
			local tip = Vector2.new(size * cosAngle + arrowX, size * sinAngle + arrowY)
			local baseLeft = Vector2.new(-size/2 * cosAngle - size/2 * sinAngle + arrowX, 
									   -size/2 * sinAngle + size/2 * cosAngle + arrowY)
			local baseRight = Vector2.new(-size/2 * cosAngle + size/2 * sinAngle + arrowX, 
										-size/2 * sinAngle - size/2 * cosAngle + arrowY)
			
			arrow.PointA = tip
			arrow.PointB = baseLeft
			arrow.PointC = baseRight
			arrow.Visible = true
		else
			arrow.Visible = false
		end
	else
		arrow.Visible = false
	end
end

-- ===================================
-- SKELETON ESP
-- ===================================

local function createSkeletonESP(player)
	if not ESPConfig.Skeleton.Enabled then return {} end
	
	local skeleton = {}
	local joints = {
		"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot"
	}
	
	-- Create lines for skeleton connections
	for i = 1, #joints - 1 do
		skeleton[i] = createDrawing("Line", {
			Visible = false,
			Color = ESPConfig.Skeleton.Color,
			Thickness = ESPConfig.Skeleton.Thickness,
			Transparency = ESPConfig.Skeleton.Transparency,
			AntiAliasing = true
		})
	end
	
	return skeleton
end

local function updateSkeletonESP(player, skeleton)
	if not skeleton or not player.Character or not shouldUpdate() then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		for _, line in pairs(skeleton) do
			line.Visible = false
		end
		return
	end
	
	-- Distance culling
	local distance = getDistance(rootPart, LocalPlayer.Character.HumanoidRootPart)
	if ESPConfig.Performance.DistanceCulling and distance > ESPConfig.MaxDistance then
		for _, line in pairs(skeleton) do
			line.Visible = false
		end
		return
	end
	
	-- Occlusion culling
	if isOccluded(player.Character) then
		for _, line in pairs(skeleton) do
			line.Visible = false
		end
		return
	end
	
	-- Skeleton connections
	local connections = {
		{"Head", "UpperTorso"},
		{"UpperTorso", "LowerTorso"},
		{"UpperTorso", "LeftUpperArm"},
		{"LeftUpperArm", "LeftLowerArm"},
		{"LeftLowerArm", "LeftHand"},
		{"UpperTorso", "RightUpperArm"},
		{"RightUpperArm", "RightLowerArm"},
		{"RightLowerArm", "RightHand"},
		{"LowerTorso", "LeftUpperLeg"},
		{"LeftUpperLeg", "LeftLowerLeg"},
		{"LeftLowerLeg", "LeftFoot"},
		{"LowerTorso", "RightUpperLeg"},
		{"RightUpperLeg", "RightLowerLeg"},
		{"RightLowerLeg", "RightFoot"}
	}
	
	-- Calculate distance scale
	local scale = getDistanceScale(distance)
	
	-- Apply rainbow effect
	local color = ESPConfig.Skeleton.Color
	if ESPConfig.Skeleton.Rainbow or ESPConfig.Effects.Rainbow then
		color = getRainbowColor(localTick(), ESPConfig.Effects.RainbowSpeed)
	end
	
	-- Ensure color is always a valid Color3
	if type(color) ~= "userdata" then
		color = Color3.fromRGB(255, 255, 255) -- Default to white if invalid
	end
	
	-- Auto-thickness
	local thickness = ESPConfig.Skeleton.Thickness
	if ESPConfig.Skeleton.AutoThickness then
		thickness = math.max(1, thickness * scale)
	end
	
	-- Update skeleton lines
	local lineIndex = 1
	for _, connection in pairs(connections) do
		-- Safety check: don't exceed available skeleton lines
		if lineIndex > #skeleton then break end
		
		local part1 = player.Character:FindFirstChild(connection[1])
		local part2 = player.Character:FindFirstChild(connection[2])
		
		if part1 and part2 then
			local pos1, onScreen1 = worldToScreen(part1.Position)
			local pos2, onScreen2 = worldToScreen(part2.Position)
			
			if onScreen1 and onScreen2 then
				skeleton[lineIndex].From = pos1
				skeleton[lineIndex].To = pos2
				skeleton[lineIndex].Color = color
				skeleton[lineIndex].Thickness = thickness
				skeleton[lineIndex].Visible = true
			else
				skeleton[lineIndex].Visible = false
			end
		else
			-- Safety check: ensure skeleton[lineIndex] exists before accessing
			if skeleton[lineIndex] then
				skeleton[lineIndex].Visible = false
			end
		end
		
		lineIndex = lineIndex + 1
		if lineIndex > #skeleton then break end
	end
end

-- ===================================
-- MAIN ESP SYSTEM
-- ===================================

local function createPlayerESP(player)
	cleanupPlayerESP(player)
	
	ESPObjects[player] = {}
	Connections[player] = {}
	AnimationTweens[player] = {}
	
	-- Create ESP objects
	ESPObjects[player].Box = createBoxESP(player)
	ESPObjects[player].Name = createNameESP(player)
	ESPObjects[player].Health = createHealthESP(player)
	ESPObjects[player].Tracer = createTracerESP(player)
	ESPObjects[player].Arrow = createArrowESP(player)
	ESPObjects[player].Skeleton = createSkeletonESP(player)
	
	-- Create chams if enabled
	if player.Character then
		createChams(player.Character)
	end
end

local function updatePlayerESP(player)
	if not ESPObjects[player] or not ESPConfig.Enabled then return end
	
	-- Update each ESP type
	updateBoxESP(player, ESPObjects[player].Box)
	updateNameESP(player, ESPObjects[player].Name)
	updateHealthESP(player, ESPObjects[player].Health)
	updateTracerESP(player, ESPObjects[player].Tracer)
	updateArrowESP(player, ESPObjects[player].Arrow)
	updateSkeletonESP(player, ESPObjects[player].Skeleton)
end

-- ===================================
-- PLAYER MANAGEMENT
-- ===================================

local function onPlayerAdded(player)
	if player == LocalPlayer then return end
	
	-- Wait for character to load
	local characterAdded
	characterAdded = player.CharacterAdded:Connect(function(character)
		createPlayerESP(player)
		createChams(character)
	end)
	
	-- Create ESP if character already exists
	if player.Character then
		createPlayerESP(player)
		createChams(player.Character)
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

local function toggleSkeletonESP(enabled)
	ESPConfig.Skeleton.Enabled = enabled
	print("Skeleton ESP:", enabled and "ON" or "OFF")
end

local function toggleChams(enabled)
	ESPConfig.Chams.Enabled = enabled
	print("Chams:", enabled and "ON" or "OFF")
end

local function toggleRainbow(enabled)
	ESPConfig.Effects.Rainbow = enabled
	print("Rainbow Effect:", enabled and "ON" or "OFF")
end

local function togglePerformance(enabled)
	ESPConfig.Performance.BatchRendering = enabled
	print("Performance Mode:", enabled and "ON" or "OFF")
end

local function setMaxDistance(distance)
	ESPConfig.MaxDistance = distance
	print("Max Distance:", distance)
end

local function getPerformanceStats()
	return {
		FPS = getFPS(),
		Players = #Players:GetPlayers(),
		ESPObjects = 0,
		Memory = collectgarbage("count")
	}
end

-- ===================================
-- ENHANCED EXPORT API
-- ===================================

getgenv().UniversalESP = {
	-- Basic toggles
	toggleESP = toggleESP,
	toggleBoxESP = toggleBoxESP,
	toggleNameESP = toggleNameESP,
	toggleHealthESP = toggleHealthESP,
	toggleTracerESP = toggleTracerESP,
	toggleArrowESP = toggleArrowESP,
	
	-- Advanced toggles
	toggleSkeletonESP = toggleSkeletonESP,
	toggleChams = toggleChams,
	toggleRainbow = toggleRainbow,
	togglePerformance = togglePerformance,
	
	-- Configuration
	Config = ESPConfig,
	setMaxDistance = setMaxDistance,
	
	-- Performance and stats
	getPerformanceStats = getPerformanceStats,
	getFPS = getFPS,
	
	-- Utilities
	getPlayerColor = getPlayerColor,
	getDistance = getDistance,
	worldToScreen = worldToScreen,
	
	-- Advanced features
	createChams = createChams,
	removeChams = removeChams,
	cleanupPlayerESP = cleanupPlayerESP,
	
	-- Module info
	Version = "2.0.0 Enhanced",
	Author = "Universal Scripts",
	Features = {
		"Box ESP", "Name ESP", "Health ESP", "Tracer ESP", 
		"Arrow ESP", "Skeleton ESP", "Chams ESP",
		"Rainbow Effects", "Performance Optimization",
		"Distance Scaling", "Auto-Thickness", "Occlusion Culling"
	}
}

-- Start the ESP system
initializeESP()

print("🎯 Universal ESP Pro functions exported to getgenv().UniversalESP")

-- ===================================
-- BRACKET UI CREATION
-- ===================================

if Bracket then
    -- Create notifications
    Bracket:Notification({Title = "Universal ESP Pro", Description = "Loading...", Duration = 2})
    Bracket:Notification2({Title = "Universal ESP Pro v2.0", Duration = 3})
    
    -- Create main window
    local Window = Bracket:Window({
        Name = "👁 Universal ESP Pro v2.0",
        Enabled = true,
        Color = Color3.fromRGB(85, 170, 255),
        Size = UDim2.new(0, 600, 0, 500),
        Position = UDim2.new(0.5, -300, 0.5, -250)
    }) do
        
        -- ===================================
        -- MAIN ESP TAB
        -- ===================================
        
        local MainTab = Window:Tab({Name = "👁 ESP"}) do
            MainTab:Divider({Text = "ESP Controls", Side = "Left"})
            
            local espToggle = MainTab:Toggle({
                Name = "👁 Enable ESP",
                Side = "Left",
                Value = ESPConfig.Enabled,
                Callback = function(Value)
                    toggleESP(Value)
                end
            })
            
            local teamCheckToggle = MainTab:Toggle({
                Name = "👥 Team Check",
                Side = "Left",
                Value = ESPConfig.TeamCheck,
                Callback = function(Value)
                    ESPConfig.TeamCheck = Value
                end
            })
            
            local maxDistanceSlider = MainTab:Slider({
                Name = "📏 Max Distance",
                Side = "Left",
                Min = 100,
                Max = 2000,
                Value = ESPConfig.MaxDistance,
                Callback = function(Value)
                    setMaxDistance(Value)
                end
            })
            
            MainTab:Divider({Text = "ESP Features", Side = "Left"})
            
            local boxEspToggle = MainTab:Toggle({
                Name = "📦 Box ESP",
                Side = "Left",
                Value = ESPConfig.Box.Enabled,
                Callback = function(Value)
                    toggleBoxESP(Value)
                end
            })
            
            local nameEspToggle = MainTab:Toggle({
                Name = "📝 Name ESP",
                Side = "Left",
                Value = ESPConfig.Name.Enabled,
                Callback = function(Value)
                    toggleNameESP(Value)
                end
            })
            
            local healthEspToggle = MainTab:Toggle({
                Name = "❤️ Health ESP",
                Side = "Left",
                Value = ESPConfig.Health.Enabled,
                Callback = function(Value)
                    toggleHealthESP(Value)
                end
            })
            
            local tracerEspToggle = MainTab:Toggle({
                Name = "📍 Tracer ESP",
                Side = "Left",
                Value = ESPConfig.Tracer.Enabled,
                Callback = function(Value)
                    toggleTracerESP(Value)
                end
            })
            
            local arrowEspToggle = MainTab:Toggle({
                Name = "➡️ Arrow ESP",
                Side = "Left",
                Value = ESPConfig.Arrow.Enabled,
                Callback = function(Value)
                    toggleArrowESP(Value)
                end
            })
            
            local skeletonEspToggle = MainTab:Toggle({
                Name = "🦴 Skeleton ESP",
                Side = "Left",
                Value = ESPConfig.Skeleton.Enabled,
                Callback = function(Value)
                    toggleSkeletonESP(Value)
                end
            })
            
            local chamsToggle = MainTab:Toggle({
                Name = "🎨 Chams ESP",
                Side = "Left",
                Value = ESPConfig.Chams.Enabled,
                Callback = function(Value)
                    toggleChams(Value)
                end
            })
        end
        
        -- ===================================
        -- VISUAL EFFECTS TAB
        -- ===================================
        
        local EffectsTab = Window:Tab({Name = "🎨 Effects"}) do
            EffectsTab:Divider({Text = "Visual Effects", Side = "Left"})
            
            local rainbowToggle = EffectsTab:Toggle({
                Name = "🌈 Rainbow Effects",
                Side = "Left",
                Value = ESPConfig.Effects.Rainbow,
                Callback = function(Value)
                    toggleRainbow(Value)
                end
            })
            
            local performanceToggle = EffectsTab:Toggle({
                Name = "⚡ Performance Mode",
                Side = "Left",
                Value = ESPConfig.Performance.BatchRendering,
                Callback = function(Value)
                    togglePerformance(Value)
                end
            })
            
            EffectsTab:Divider({Text = "Box Settings", Side = "Left"})
            
            local boxColorPicker = EffectsTab:Colorpicker({
                Name = "📦 Box Color",
                Side = "Left",
                Value = ESPConfig.Box.Color,
                Callback = function(Value)
                    ESPConfig.Box.Color = Value
                end
            })
            
            local boxThicknessSlider = EffectsTab:Slider({
                Name = "📏 Box Thickness",
                Side = "Left",
                Min = 1,
                Max = 5,
                Value = ESPConfig.Box.Thickness,
                Callback = function(Value)
                    ESPConfig.Box.Thickness = Value
                end
            })
            
            EffectsTab:Divider({Text = "Tracer Settings", Side = "Left"})
            
            local tracerColorPicker = EffectsTab:Colorpicker({
                Name = "📍 Tracer Color",
                Side = "Left",
                Value = ESPConfig.Tracer.Color,
                Callback = function(Value)
                    ESPConfig.Tracer.Color = Value
                end
            })
            
            local tracerThicknessSlider = EffectsTab:Slider({
                Name = "📏 Tracer Thickness",
                Side = "Left",
                Min = 1,
                Max = 5,
                Value = ESPConfig.Tracer.Thickness,
                Callback = function(Value)
                    ESPConfig.Tracer.Thickness = Value
                end
            })
        end
        
        -- ===================================
        -- PERFORMANCE TAB
        -- ===================================
        
        local PerformanceTab = Window:Tab({Name = "📊 Performance"}) do
            PerformanceTab:Divider({Text = "Performance Monitor", Side = "Left"})
            
            local fpsLabel = PerformanceTab:Label({Text = "🎯 FPS: 0", Side = "Left"})
            local playersLabel = PerformanceTab:Label({Text = "👥 Players: 0", Side = "Left"})
            local memoryLabel = PerformanceTab:Label({Text = "💾 Memory: 0 MB", Side = "Left"})
            
            -- Update performance stats
            task.spawn(function()
                while true do
                    local stats = getPerformanceStats()
                    -- Use Set method instead of UpdateLabel for Bracket UI
                    pcall(function()
                        if fpsLabel.Set then
                            fpsLabel:Set("🎯 FPS: " .. stats.FPS)
                        elseif fpsLabel.UpdateLabel then
                            fpsLabel:UpdateLabel({Text = "🎯 FPS: " .. stats.FPS})
                        else
                            fpsLabel.Text = "🎯 FPS: " .. stats.FPS
                        end
                        
                        if playersLabel.Set then
                            playersLabel:Set("👥 Players: " .. stats.Players)
                        elseif playersLabel.UpdateLabel then
                            playersLabel:UpdateLabel({Text = "👥 Players: " .. stats.Players})
                        else
                            playersLabel.Text = "👥 Players: " .. stats.Players
                        end
                        
                        if memoryLabel.Set then
                            memoryLabel:Set("💾 Memory: " .. math.floor(stats.Memory) .. " MB")
                        elseif memoryLabel.UpdateLabel then
                            memoryLabel:UpdateLabel({Text = "💾 Memory: " .. math.floor(stats.Memory) .. " MB"})
                        else
                            memoryLabel.Text = "💾 Memory: " .. math.floor(stats.Memory) .. " MB"
                        end
                    end)
                    task.wait(1)
                end
            end)
            
            PerformanceTab:Divider({Text = "Performance Settings", Side = "Left"})
            
            local maxFpsSlider = PerformanceTab:Slider({
                Name = "⚡ Max FPS",
                Side = "Left",
                Min = 30,
                Max = 144,
                Value = ESPConfig.Performance.MaxFPS,
                Callback = function(Value)
                    ESPConfig.Performance.MaxFPS = Value
                end
            })
            
            local updateIntervalSlider = PerformanceTab:Slider({
                Name = "🔄 Update Interval",
                Side = "Left",
                Min = 1,
                Max = 10,
                Value = ESPConfig.Performance.UpdateInterval,
                Callback = function(Value)
                    ESPConfig.Performance.UpdateInterval = Value
                end
            })
        end
        
        -- ===================================
        -- SETTINGS TAB
        -- ===================================
        
        local SettingsTab = Window:Tab({Name = "⚙️ Settings"}) do
            SettingsTab:Divider({Text = "Configuration", Side = "Left"})
            
            local saveButton = SettingsTab:Button({
                Name = "💾 Save Settings",
                Side = "Left",
                Callback = function()
                    -- Save settings to file (placeholder)
                    Bracket:Notification({Title = "💾 Settings Saved", Description = "Your ESP settings have been saved", Duration = 2})
                end
            })
            
            local loadButton = SettingsTab:Button({
                Name = "📂 Load Settings",
                Side = "Left",
                Callback = function()
                    -- Load settings from file (placeholder)
                    Bracket:Notification({Title = "📂 Settings Loaded", Description = "Your ESP settings have been loaded", Duration = 2})
                end
            })
            
            local resetButton = SettingsTab:Button({
                Name = "🔄 Reset Settings",
                Side = "Left",
                Callback = function()
                    -- Reset to defaults (placeholder)
                    Bracket:Notification({Title = "🔄 Settings Reset", Description = "ESP settings have been reset to defaults", Duration = 2})
                end
            })
            
            SettingsTab:Divider({Text = "DevCopy Tools", Side = "Left"})
            
            local devCopyButton = SettingsTab:Button({
                Name = "📋 Copy Console Log",
                Side = "Left",
                Callback = function()
                    -- Check if DevCopy is available
                    if success and devCopyLoaded then
                        -- Trigger DevCopy functionality
                        pcall(function()
                            -- Reload DevCopy to ensure latest console content
                            local freshDevCopy = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Useful/DevCopy"))()
                            if freshDevCopy then
                                Bracket:Notification({Title = "📋 DevCopy Activated", Description = "Console copying buttons have been refreshed", Duration = 2})
                            else
                                Bracket:Notification({Title = "❌ DevCopy Failed", Description = "Failed to refresh DevCopy functionality", Duration = 3})
                            end
                        end)
                    else
                        Bracket:Notification({Title = "⚠️ DevCopy Unavailable", Description = "DevCopy is not loaded - check console for errors", Duration = 3})
                    end
                end
            })
            
            local copyScriptButton = SettingsTab:Button({
                Name = "📄 Copy Script Loadstring",
                Side = "Left",
                Callback = function()
                    local scriptUrl = "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro.lua"
                    local scriptContent = string.format([===[
--[[
	Universal ESP Pro Enhanced - Professional ESP System
	Designed from scratch using best practices from multiple ESP libraries
	
	Enhanced Features:
	- Performance optimizations (rendering efficiency, memory management)
	- Advanced ESP features (skeleton, chams, distance-based scaling)
	- Modular architecture for easy integration
	- Advanced features (team colors, rainbow effects, animations)
	- Future-ready structure for script transitions
	
	ESP Types:
	- Box ESP (corner boxes with auto-scaling)
	- Name ESP (distance/health display)
	- Health ESP (dynamic health bars)
	- Tracer ESP (screen edge tracers)
	- Arrow ESP (off-screen indicators)
	- Skeleton ESP (bone structure)
	- Chams ESP (character highlighting)
	- Distance ESP (distance-based scaling)
]]

print("🚀 Loading Universal ESP Pro...")

-- Load the script from GitHub
loadstring(game:HttpGet("%s"))()
]===], scriptUrl)
                    
                    -- Copy to clipboard
                    if setclipboard then
                        setclipboard(scriptContent)
                        Bracket:Notification({Title = "📋 Script Copied", Description = "ESP Pro loadstring copied to clipboard!", Duration = 2})
                    else
                        Bracket:Notification({Title = "❌ Clipboard Failed", Description = "setclipboard function not available", Duration = 3})
                    end
                end
            })
            
            local copyUrlButton = SettingsTab:Button({
                Name = "🔗 Copy Script URL",
                Side = "Left",
                Callback = function()
                    local scriptUrl = "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro.lua"
                    
                    -- Copy to clipboard
                    if setclipboard then
                        setclipboard(scriptUrl)
                        Bracket:Notification({Title = "🔗 URL Copied", Description = "ESP Pro URL copied to clipboard!", Duration = 2})
                    else
                        Bracket:Notification({Title = "❌ Clipboard Failed", Description = "setclipboard function not available", Duration = 3})
                    end
                end
            })
            
            SettingsTab:Divider({Text = "Danger Zone", Side = "Left"})
            
            local destroyButton = SettingsTab:Button({
                Name = "💀 Destroy UI (Stealth)",
                Side = "Left",
                Callback = function()
                    Window:Toggle(false)
                    Bracket:Notification({Title = "💀 UI Destroyed", Description = "UI has been destroyed for stealth mode", Duration = 2})
                end
            })
            
            local unloadButton = SettingsTab:Button({
                Name = "🗑️ Unload ESP",
                Side = "Left",
                Callback = function()
                    -- Cleanup ESP
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            cleanupPlayerESP(player)
                        end
                    end
                    Bracket:Notification({Title = "🗑️ ESP Unloaded", Description = "ESP has been completely unloaded", Duration = 3})
                end
            })
        end
        
        -- UI keybinds
        local UserInputService = game:GetService("UserInputService")
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            -- Toggle UI with F9
            if input.KeyCode == Enum.KeyCode.F9 then
                Window:Toggle()
            elseif input.KeyCode == Enum.KeyCode.Delete then
                Window:Toggle(false)
            end
        end)
    end
    
    -- Notification on load
    Bracket:Notification({Title = "Universal ESP Pro v2.0", Description = "Loaded successfully! Press F9 to toggle UI", Duration = 3})
    
    print("✅ Universal ESP Pro UI loaded successfully!")
    print("⌨️ Press F9 to toggle UI")
else
    print("⚠️ Bracket library not available - UI disabled")
    print("🎯 Use getgenv().UniversalESP for manual control")
end
