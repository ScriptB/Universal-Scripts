--[[
	Universal ESP Combined - Comprehensive ESP System
	Combines the best features from multiple ESP libraries
	
	Features:
	- Arrow ESP (off-screen indicators)
	- Corner Box ESP (corner boxes with rainbow)
	- Name ESP (player names with auto-scale)
	- View Tracer ESP (directional lines)
	- Skeleton ESP (bone structure)
	- Health ESP (health bars)
	- Distance ESP (distance display)
	- Team color support
	- Auto-scaling and thickness
	- Performance optimized
	- Clean modular architecture
]]

print("🚀 Loading Universal ESP Combined...")

-- ===================================
-- SERVICES
-- ===================================

local Services = {
	Players = game:GetService("Players"),
	Workspace = game:GetService("Workspace"),
	RunService = game:GetService("RunService"),
	Lighting = game:GetService("Lighting")
}

local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- ===================================
-- CONFIGURATION
-- ===================================

local Config = {
	-- General Settings
	Enabled = true,
	TeamCheck = false,
	TeamColor = false,
	MaxDistance = 1000,
	
	-- Arrow ESP Settings (Off-screen indicators)
	Arrow = {
		Enabled = true,
		DistanceFromCenter = 80,
		TriangleHeight = 16,
		TriangleWidth = 16,
		Filled = true,
		Transparency = 0,
		Thickness = 1,
		Color = Color3.fromRGB(255, 255, 255),
		AntiAliasing = false
	},
	
	-- Corner Box ESP Settings
	CornerBox = {
		Enabled = true,
		Color = Color3.fromRGB(255, 0, 0),
		Thickness = 2,
		AutoThickness = true,
		Rainbow = false,
		RainbowSpeed = 0.15,
		CornerLength = 15
	},
	
	-- Name ESP Settings
	Name = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Size = 15,
		Transparency = 1,
		AutoScale = true,
		ShowDistance = true,
		ShowHealth = true
	},
	
	-- View Tracer Settings
	ViewTracer = {
		Enabled = true,
		Color = Color3.fromRGB(255, 203, 138),
		Thickness = 1,
		Transparency = 1,
		AutoThickness = true,
		Length = 15,
		Smoothness = 0.2
	},
	
	-- Skeleton ESP Settings
	Skeleton = {
		Enabled = true,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 1,
		AutoThickness = true
	},
	
	-- Health Bar Settings
	HealthBar = {
		Enabled = true,
		Width = 4,
		Height = 50,
		Background = Color3.fromRGB(0, 0, 0),
		HealthColor = Color3.fromRGB(0, 255, 0),
		LowHealthColor = Color3.fromRGB(255, 0, 0)
	}
}

-- ===================================
-- STATE MANAGEMENT
-- ===================================

local State = {
	ESPObjects = {},
	Connections = {},
	DrawingAvailable = false,
	Drawing = nil
}

-- ===================================
-- UTILITY FUNCTIONS
-- ===================================

local Utils = {
	-- Drawing service detection
	setupDrawing = function()
		pcall(function()
			State.Drawing = Drawing
			if State.Drawing then
				State.drawingAvailable = pcall(function()
					local test = State.Drawing.new("Circle")
					test:Remove()
				end)
			end
		end)
	end,
	
	-- Math utilities
	lerp = function(a, b, t)
		return a + (b - a) * t
	end,
	
	clamp = function(value, min, max)
		return math.max(min, math.min(max, value))
	end,
	
	-- Color utilities
	hueToRgb = function(hue)
		return Color3.fromHSV(hue, 1, 1)
	end,
	
	-- Distance calculation
	getDistance = function(part1, part2)
		return (part1.Position - part2.Position).Magnitude
	end,
	
	-- Screen position calculation
	worldToScreen = function(worldPos)
		return Camera:WorldToViewportPoint(worldPos)
	end,
	
	-- Team color check
	getPlayerColor = function(player)
		if Config.TeamColor and player.Team then
			return player.TeamColor.Color
		elseif Config.TeamCheck and player.Team == Player.Team then
			return Color3.fromRGB(0, 255, 0)
		else
			return Config.CornerBox.Color
		end
	end,
	
	-- Auto-scale calculation
	getAutoScale = function(distance, minSize, maxSize, scaleFactor)
		return Utils.clamp(1/distance * scaleFactor, minSize, maxSize)
	end,
	
	-- Auto-thickness calculation
	getAutoThickness = function(distance, minThickness, maxThickness, scaleFactor)
		return Utils.clamp(1/distance * scaleFactor, minThickness, maxThickness)
	end,
	
	-- Rainbow effect
	getRainbowColor = function(speed)
		local hue = tick() * speed % 1
		return Utils.hueToRgb(hue)
	end
}

-- ===================================
-- ARROW ESP SYSTEM
-- ===================================

local ArrowESP = {
	getRelative = function(pos, char)
		if not char then return Vector2.new(0,0) end
		
		local rootP = char.PrimaryPart.Position
		local camP = Camera.CFrame.Position
		local relative = CFrame.new(Vector3.new(rootP.X, camP.Y, rootP.Z), camP):PointToObjectSpace(pos)
		
		return Vector2.new(relative.X, relative.Z)
	end,
	
	relativeToCenter = function(v)
		return Camera.ViewportSize/2 - v
	end,
	
	rotateVector = function(v, angle)
		angle = math.rad(angle)
		local x = v.x * math.cos(angle) - v.y * math.sin(angle)
		local y = v.x * math.sin(angle) + v.y * math.cos(angle)
		
		return Vector2.new(x, y)
	end,
	
	createArrow = function(player)
		if not State.drawingAvailable or not Config.Arrow.Enabled then return end
		
		local arrow = State.Drawing.new("Triangle")
		arrow.Visible = false
		arrow.Color = Config.Arrow.Color
		arrow.Filled = Config.Arrow.Filled
		arrow.Thickness = Config.Arrow.Thickness
		arrow.Transparency = 1 - Config.Arrow.Transparency
		
		return arrow
	end,
	
	updateArrow = function(player, arrow)
		if not arrow or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not rootPart or humanoid.Health <= 0 then
			arrow.Visible = false
			return
		end
		
		local _, onScreen = Utils.worldToScreen(rootPart.Position)
		
		if not onScreen then
			local rel = ArrowESP.getRelative(rootPart.Position, Player.Character)
			local direction = rel.Unit
			
			local base = direction * Config.Arrow.DistanceFromCenter
			local sideLength = Config.Arrow.TriangleWidth / 2
			local baseL = base + ArrowESP.rotateVector(direction, 90) * sideLength
			local baseR = base + ArrowESP.rotateVector(direction, -90) * sideLength
			
			local tip = direction * (Config.Arrow.DistanceFromCenter + Config.Arrow.TriangleHeight)
			
			if Config.Arrow.AntiAliasing then
				arrow.PointA = Vector2.new(math.round(ArrowESP.relativeToCenter(baseL).X), math.round(ArrowESP.relativeToCenter(baseL).Y))
				arrow.PointB = Vector2.new(math.round(ArrowESP.relativeToCenter(baseR).X), math.round(ArrowESP.relativeToCenter(baseR).Y))
				arrow.PointC = Vector2.new(math.round(ArrowESP.relativeToCenter(tip).X), math.round(ArrowESP.relativeToCenter(tip).Y))
			else
				arrow.PointA = ArrowESP.relativeToCenter(baseL)
				arrow.PointB = ArrowESP.relativeToCenter(baseR)
				arrow.PointC = ArrowESP.relativeToCenter(tip)
			end
			
			arrow.Visible = true
		else
			arrow.Visible = false
		end
	end
}

-- ===================================
-- CORNER BOX ESP SYSTEM
-- ===================================

local CornerBoxESP = {
	createCornerBox = function(player)
		if not State.drawingAvailable or not Config.CornerBox.Enabled then return end
		
		local cornerBox = {}
		
		-- Create 8 lines for corner box (2 lines per corner)
		for i = 1, 8 do
			local line = State.Drawing.new("Line")
			line.Visible = false
			line.Color = Config.CornerBox.Color
			line.Thickness = Config.CornerBox.Thickness
			line.Transparency = 1
			table.insert(cornerBox, line)
		end
		
		return cornerBox
	end,
	
	updateCornerBox = function(player, cornerBox)
		if not cornerBox or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		local head = player.Character:FindFirstChild("Head")
		
		if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
			for _, line in pairs(cornerBox) do
				line.Visible = false
			end
			return
		end
		
		local position, onScreen = Utils.worldToScreen(rootPart.Position)
		if not onScreen then
			for _, line in pairs(cornerBox) do
				line.Visible = false
			end
			return
		end
		
		-- Calculate box dimensions
		local size = Vector3.new(rootPart.Size.X, rootPart.Size.Y * 1.5, rootPart.Size.Z)
		local cframe = CFrame.new(rootPart.Position, Camera.CFrame.Position)
		
		-- Get corner positions
		local corners = {
			Camera:WorldToViewportPoint((cframe * CFrame.new(size.X/2, size.Y/2, 0)).Position),
			Camera:WorldToViewportPoint((cframe * CFrame.new(-size.X/2, size.Y/2, 0)).Position),
			Camera:WorldToViewportPoint((cframe * CFrame.new(size.X/2, -size.Y/2, 0)).Position),
			Camera:WorldToViewportPoint((cframe * CFrame.new(-size.X/2, -size.Y/2, 0)).Position)
		}
		
		-- Update colors
		local color = Utils.getPlayerColor(player)
		if Config.CornerBox.Rainbow then
			color = Utils.getRainbowColor(Config.CornerBox.RainbowSpeed)
		end
		
		for _, line in pairs(cornerBox) do
			line.Color = color
		end
		
		-- Calculate corner length
		local distance = Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)
		local cornerLength = Utils.getAutoScale(distance, 5, 25, 50)
		
		-- Update corner lines
		-- Top-left corner
		cornerBox[1].From = Vector2.new(corners[1].X, corners[1].Y)
		cornerBox[1].To = Vector2.new(corners[1].X - cornerLength, corners[1].Y)
		cornerBox[2].From = Vector2.new(corners[1].X, corners[1].Y)
		cornerBox[2].To = Vector2.new(corners[1].X, corners[1].Y - cornerLength)
		
		-- Top-right corner
		cornerBox[3].From = Vector2.new(corners[2].X, corners[2].Y)
		cornerBox[3].To = Vector2.new(corners[2].X + cornerLength, corners[2].Y)
		cornerBox[4].From = Vector2.new(corners[2].X, corners[2].Y)
		cornerBox[4].To = Vector2.new(corners[2].X, corners[2].Y - cornerLength)
		
		-- Bottom-left corner
		cornerBox[5].From = Vector2.new(corners[3].X, corners[3].Y)
		cornerBox[5].To = Vector2.new(corners[3].X - cornerLength, corners[3].Y)
		cornerBox[6].From = Vector2.new(corners[3].X, corners[3].Y)
		cornerBox[6].To = Vector2.new(corners[3].X, corners[3].Y + cornerLength)
		
		-- Bottom-right corner
		cornerBox[7].From = Vector2.new(corners[4].X, corners[4].Y)
		cornerBox[7].To = Vector2.new(corners[4].X + cornerLength, corners[4].Y)
		cornerBox[8].From = Vector2.new(corners[4].X, corners[4].Y)
		cornerBox[8].To = Vector2.new(corners[4].X, corners[4].Y + cornerLength)
		
		-- Update thickness
		if Config.CornerBox.AutoThickness then
			local thickness = Utils.getAutoThickness(distance, 0.5, 3, 100)
			for _, line in pairs(cornerBox) do
				line.Thickness = thickness
			end
		else
			for _, line in pairs(cornerBox) do
				line.Thickness = Config.CornerBox.Thickness
			end
		end
		
		-- Show corner box
		for _, line in pairs(cornerBox) do
			line.Visible = true
		end
	end
}

-- ===================================
-- NAME ESP SYSTEM
-- ===================================

local NameESP = {
	createName = function(player)
		if not State.drawingAvailable or not Config.Name.Enabled then return end
		
		local name = State.Drawing.new("Text")
		name.Visible = false
		name.Text = ""
		name.Position = Vector2.new(0, 0)
		name.Color = Config.Name.Color
		name.Size = Config.Name.Size
		name.Center = true
		name.Transparency = Config.Name.Transparency
		name.Outline = true
		
		return name
	end,
	
	updateName = function(player, name)
		if not name or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		local head = player.Character:FindFirstChild("Head")
		
		if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
			name.Visible = false
			return
		end
		
		local position, onScreen = Utils.worldToScreen(head.Position + Vector3.new(0, 2, 0))
		if not onScreen then
			name.Visible = false
			return
		end
		
		-- Build name text
		local text = player.Name
		
		if Config.Name.ShowDistance then
			local distance = Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)
			text = text .. " [" .. math.floor(distance) .. "m]"
		end
		
		if Config.Name.ShowHealth then
			text = text .. " [" .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "HP]"
		end
		
		name.Text = text
		name.Position = Vector2.new(position.X, position.Y)
		
		-- Auto-scale
		if Config.Name.AutoScale then
			local distance = Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)
			local size = Utils.getAutoScale(distance, 8, 20, 1000)
			name.Size = size
		else
			name.Size = Config.Name.Size
		end
		
		name.Visible = true
	end
}

-- ===================================
-- VIEW TRACER ESP SYSTEM
-- ===================================

local ViewTracerESP = {
	createViewTracer = function(player)
		if not State.drawingAvailable or not Config.ViewTracer.Enabled then return end
		
		local tracer = State.Drawing.new("Line")
		tracer.Visible = false
		tracer.From = Vector2.new(0, 0)
		tracer.To = Vector2.new(0, 0)
		tracer.Color = Config.ViewTracer.Color
		tracer.Thickness = Config.ViewTracer.Thickness
		tracer.Transparency = Config.ViewTracer.Transparency
		
		return tracer
	end,
	
	updateViewTracer = function(player, tracer)
		if not tracer or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		local head = player.Character:FindFirstChild("Head")
		
		if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
			tracer.Visible = false
			return
		end
		
		local headPos, onScreen = Utils.worldToScreen(head.Position)
		if not onScreen then
			tracer.Visible = false
			return
		end
		
		tracer.From = Vector2.new(headPos.X, headPos.Y)
		
		-- Auto-thickness
		if Config.ViewTracer.AutoThickness then
			local distance = Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)
			local thickness = Utils.getAutoThickness(distance, 0.1, 3, 100)
			tracer.Thickness = thickness
		else
			tracer.Thickness = Config.ViewTracer.Thickness
		end
		
		-- Calculate tracer end point
		local offsetCFrame = CFrame.new(0, 0, -Config.ViewTracer.Length)
		local check = false
		
		repeat
			local dir = head.CFrame:ToWorldSpace(offsetCFrame)
			offsetCFrame = offsetCFrame * CFrame.new(0, 0, Config.ViewTracer.Smoothness)
			local dirPos, vis = Utils.worldToScreen(Vector3.new(dir.X, dir.Y, dir.Z))
			
			if vis then
				check = true
				tracer.To = Vector2.new(dirPos.X, dirPos.Y)
				tracer.Visible = true
				offsetCFrame = CFrame.new(0, 0, -Config.ViewTracer.Length)
			end
		until check == true
	end
}

-- ===================================
-- HEALTH BAR ESP SYSTEM
-- ===================================

local HealthBarESP = {
	createHealthBar = function(player)
		if not State.drawingAvailable or not Config.HealthBar.Enabled then return end
		
		local healthBar = {
			background = State.Drawing.new("Square"),
			health = State.Drawing.new("Square")
		}
		
		-- Setup background
		healthBar.background.Visible = false
		healthBar.background.Color = Config.HealthBar.Background
		healthBar.background.Transparency = 1
		healthBar.background.Filled = true
		
		-- Setup health bar
		healthBar.health.Visible = false
		healthBar.health.Color = Config.HealthBar.HealthColor
		healthBar.health.Transparency = 1
		healthBar.health.Filled = true
		
		return healthBar
	end,
	
	updateHealthBar = function(player, healthBar)
		if not healthBar or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		local head = player.Character:FindFirstChild("Head")
		
		if not humanoid or not rootPart or not head or humanoid.Health <= 0 then
			healthBar.background.Visible = false
			healthBar.health.Visible = false
			return
		end
		
		local position, onScreen = Utils.worldToScreen(rootPart.Position)
		if not onScreen then
			healthBar.background.Visible = false
			healthBar.health.Visible = false
			return
		end
		
		-- Calculate health percentage
		local healthPercent = Utils.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		
		-- Position health bar
		local barX = position.X - 30
		local barY = position.Y - 25
		
		-- Update background
		healthBar.background.Size = Vector2.new(Config.HealthBar.Width, Config.HealthBar.Height)
		healthBar.background.Position = Vector2.new(barX, barY)
		
		-- Update health bar
		healthBar.health.Size = Vector2.new(Config.HealthBar.Width, Config.HealthBar.Height * healthPercent)
		healthBar.health.Position = Vector2.new(barX, barY + Config.HealthBar.Height * (1 - healthPercent))
		
		-- Update color based on health
		if healthPercent < 0.3 then
			healthBar.health.Color = Config.HealthBar.LowHealthColor
		else
			healthBar.health.Color = Config.HealthBar.HealthColor
		end
		
		healthBar.background.Visible = true
		healthBar.health.Visible = true
	end
}

-- ===================================
-- SKELETON ESP SYSTEM
-- ===================================

local SkeletonESP = {
	boneConnections = {
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
	},
	
	createSkeleton = function(player)
		if not State.drawingAvailable or not Config.Skeleton.Enabled then return end
		
		local skeleton = {}
		
		-- Create lines for each bone connection
		for i = 1, #SkeletonESP.boneConnections do
			local line = State.Drawing.new("Line")
			line.Visible = false
			line.Color = Config.Skeleton.Color
			line.Thickness = Config.Skeleton.Thickness
			line.Transparency = Config.Skeleton.Transparency
			table.insert(skeleton, line)
		end
		
		return skeleton
	end,
	
	updateSkeleton = function(player, skeleton)
		if not skeleton or not player.Character then return end
		
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not rootPart or humanoid.Health <= 0 then
			for _, line in pairs(skeleton) do
				line.Visible = false
			end
			return
		end
		
		-- Update each bone connection
		for i, connection in pairs(SkeletonESP.boneConnections) do
			local part1 = player.Character:FindFirstChild(connection[1])
			local part2 = player.Character:FindFirstChild(connection[2])
			local line = skeleton[i]
			
			if part1 and part2 and line then
				local pos1, onScreen1 = Utils.worldToScreen(part1.Position)
				local pos2, onScreen2 = Utils.worldToScreen(part2.Position)
				
				if onScreen1 and onScreen2 then
					line.From = Vector2.new(pos1.X, pos1.Y)
					line.To = Vector2.new(pos2.X, pos2.Y)
					
					-- Auto-thickness
					if Config.Skeleton.AutoThickness then
						local distance = Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)
						local thickness = Utils.getAutoThickness(distance, 0.5, 2, 100)
						line.Thickness = thickness
					else
						line.Thickness = Config.Skeleton.Thickness
					end
					
					line.Visible = true
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	end
}

-- ===================================
-- MAIN ESP MANAGER
-- ===================================

local ESPManager = {
	createESPObjects = function(player)
		if not State.drawingAvailable then return end
		
		-- Cleanup existing objects
		ESPManager.cleanupESPObjects(player)
		
		State.ESPObjects[player] = {}
		
		-- Create ESP objects
		if Config.Arrow.Enabled then
			State.ESPObjects[player].arrow = ArrowESP.createArrow(player)
		end
		
		if Config.CornerBox.Enabled then
			State.ESPObjects[player].cornerBox = CornerBoxESP.createCornerBox(player)
		end
		
		if Config.Name.Enabled then
			State.ESPObjects[player].name = NameESP.createName(player)
		end
		
		if Config.ViewTracer.Enabled then
			State.ESPObjects[player].viewTracer = ViewTracerESP.createViewTracer(player)
		end
		
		if Config.HealthBar.Enabled then
			State.ESPObjects[player].healthBar = HealthBarESP.createHealthBar(player)
		end
		
		if Config.Skeleton.Enabled then
			State.ESPObjects[player].skeleton = SkeletonESP.createSkeleton(player)
		end
	end,
	
	updateESPObjects = function(player)
		if not State.drawingAvailable or not State.ESPObjects[player] then return end
		
		local objects = State.ESPObjects[player]
		
		-- Update each ESP type
		if objects.arrow then
			ArrowESP.updateArrow(player, objects.arrow)
		end
		
		if objects.cornerBox then
			CornerBoxESP.updateCornerBox(player, objects.cornerBox)
		end
		
		if objects.name then
			NameESP.updateName(player, objects.name)
		end
		
		if objects.viewTracer then
			ViewTracerESP.updateViewTracer(player, objects.viewTracer)
		end
		
		if objects.healthBar then
			HealthBarESP.updateHealthBar(player, objects.healthBar)
		end
		
		if objects.skeleton then
			SkeletonESP.updateSkeleton(player, objects.skeleton)
		end
	end,
	
	cleanupESPObjects = function(player)
		if State.ESPObjects[player] then
			for _, objects in pairs(State.ESPObjects[player]) do
				if type(objects) == "table" then
					for _, obj in pairs(objects) do
						if obj and obj.Remove then
							obj:Remove()
						end
					end
				elseif objects and objects.Remove then
					objects:Remove()
				end
			end
			State.ESPObjects[player] = nil
		end
	end,
	
	hideESPObjects = function(player)
		if State.ESPObjects[player] then
			for _, objects in pairs(State.ESPObjects[player]) do
				if type(objects) == "table" then
					for _, obj in pairs(objects) do
						if obj and obj.Visible ~= nil then
							obj.Visible = false
						end
					end
				elseif objects and objects.Visible ~= nil then
					objects.Visible = false
				end
			end
		end
	end
}

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
	-- Setup drawing
	Utils.setupDrawing()
	
	if not State.drawingAvailable then
		warn("❌ Drawing service not available - ESP disabled")
		return
	end
	
	print("✅ Universal ESP Combined loaded successfully!")
	
	-- Setup ESP for existing players
	for _, player in pairs(Services.Players:GetPlayers()) do
		if player ~= Player then
			ESPManager.createESPObjects(player)
		end
	end
	
	-- Player events
	Services.Players.PlayerAdded:Connect(function(player)
		if player ~= Player then
			ESPManager.createESPObjects(player)
		end
	end)
	
	Services.Players.PlayerRemoving:Connect(function(player)
		ESPManager.cleanupESPObjects(player)
	end)
	
	-- Main update loop
	Services.RunService.RenderStepped:Connect(function()
		if not Config.Enabled then
			-- Hide all ESP objects when disabled
			for _, player in pairs(Services.Players:GetPlayers()) do
				if player ~= Player then
					ESPManager.hideESPObjects(player)
				end
			end
			return
		end
		
		-- Update ESP for all players
		for _, player in pairs(Services.Players:GetPlayers()) do
			if player ~= Player then
				ESPManager.updateESPObjects(player)
			end
		end
	end)
end

-- Start the ESP system
main()

-- ===================================
-- CONFIGURATION FUNCTIONS
-- ===================================

local function toggleESP(enabled)
	Config.Enabled = enabled
	print("ESP:", enabled and "ON" or "OFF")
end

local function toggleArrowESP(enabled)
	Config.Arrow.Enabled = enabled
	print("Arrow ESP:", enabled and "ON" or "OFF")
end

local function toggleCornerBoxESP(enabled)
	Config.CornerBox.Enabled = enabled
	print("Corner Box ESP:", enabled and "ON" or "OFF")
end

local function toggleNameESP(enabled)
	Config.Name.Enabled = enabled
	print("Name ESP:", enabled and "ON" or "OFF")
end

local function toggleViewTracerESP(enabled)
	Config.ViewTracer.Enabled = enabled
	print("View Tracer ESP:", enabled and "ON" or "OFF")
end

local function toggleHealthBarESP(enabled)
	Config.HealthBar.Enabled = enabled
	print("Health Bar ESP:", enabled and "ON" or "OFF")
end

local function toggleSkeletonESP(enabled)
	Config.Skeleton.Enabled = enabled
	print("Skeleton ESP:", enabled and "ON" or "OFF")
end

-- ===================================
-- EXPORT FUNCTIONS
-- ===================================

getgenv().UniversalESP = {
	toggleESP = toggleESP,
	toggleArrowESP = toggleArrowESP,
	toggleCornerBoxESP = toggleCornerBoxESP,
	toggleNameESP = toggleNameESP,
	toggleViewTracerESP = toggleViewTracerESP,
	toggleHealthBarESP = toggleHealthBarESP,
	toggleSkeletonESP = toggleSkeletonESP,
	Config = Config
}

print("🎯 Universal ESP Combined functions exported to getgenv().UniversalESP")
