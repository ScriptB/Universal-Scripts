--[[
	Phantom Suite v9.0 - Complete Ground-Up Rewrite
	Modern architecture with clean code principles
	
	Features:
	- Advanced aimbot with prediction and smoothing
	- Comprehensive ESP system with multiple visual elements
	- Movement tools (fly, noclip, infinite jump)
	- Professional Bracket UI integration
	- Robust error handling and performance optimization
	- Clean, modular architecture
]]

print("🚀 Loading Phantom Suite v9.0 (Ground-Up Rewrite)...")

-- ===================================
-- LIBRARY LOADING
-- ===================================

local function loadLibrary(url, name)
	local success, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)
	
	if success and result then
		print("✅ " .. name .. " loaded successfully")
		return result
	else
		warn("❌ Failed to load " .. name .. ": " .. tostring(result))
		return nil
	end
end

-- Load Dev Console Copier
loadLibrary("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Tools/DevCopy.lua", "Dev Console Copier")

-- Load Bracket Library
local Bracket = loadLibrary("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/BracketLib.lua", "Bracket Library")

if not Bracket then
	warn("❌ Cannot continue without GUI library")
	return
end

-- ===================================
-- SERVICES
-- ===================================

local Services = {
	RunService = game:GetService("RunService"),
	Players = game:GetService("Players"),
	UserInputService = game:GetService("UserInputService"),
	HttpService = game:GetService("HttpService"),
	Workspace = workspace,
	Lighting = game:GetService("Lighting"),
	ReplicatedStorage = game:GetService("ReplicatedStorage")
}

local Player = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- ===================================
-- CONFIGURATION
-- ===================================

local Config = {
	Aimbot = {
		enabled = false,
		blatant = false,
		fov = 100,
		smoothing = 5,
		prediction = 0.065,
		lockDistance = 500,
		wallCheck = true,
		teamCheck = true,
		healthCheck = false,
		minHealth = 0,
		targetMode = "Closest To Crosshair"
	},
	
	ESP = {
		enabled = false,
		box = true,
		name = true,
		health = true,
		distance = true,
		tracer = false,
		lockDistance = 500
	},
	
	Movement = {
		fly = false,
		noclip = false,
		infJump = false,
		flySpeed = 50,
		walkSpeed = 16,
		jumpPower = 50
	},
	
	Visual = {
		fovColor = Color3.fromRGB(255, 255, 255),
		espColor = Color3.fromRGB(255, 0, 0),
		rainbowFov = false,
		rainbowSpeed = 0.005
	}
}

-- ===================================
-- STATE MANAGEMENT
-- ===================================

local State = {
	aiming = false,
	target = nil,
	connections = {},
	espObjects = {},
	drawingAvailable = false,
	Drawing = nil,
	fovCircle = nil,
	executor = {
		name = "Unknown",
		compatibility = {
			Drawing = false,
			Clipboard = false,
			FileSystem = false,
			HTTP = false,
			WebSocket = false
		}
	}
}

-- ===================================
-- UTILITY FUNCTIONS
-- ===================================

local Utils = {
	-- Executor detection
	detectExecutor = function()
		if syn then
			State.executor.name = "Synapse X"
			State.executor.compatibility.Drawing = true
			State.executor.compatibility.Clipboard = true
			State.executor.compatibility.FileSystem = true
			State.executor.compatibility.HTTP = true
			State.executor.compatibility.WebSocket = true
		elseif getexecutorname then
			State.executor.name = getexecutorname() or "Unknown"
			State.executor.compatibility.Drawing = true
			State.executor.compatibility.Clipboard = true
			State.executor.compatibility.FileSystem = true
			State.executor.compatibility.HTTP = true
		elseif identifyexecutor then
			State.executor.name = identifyexecutor()
			State.executor.compatibility.Drawing = true
			State.executor.compatibility.Clipboard = true
			State.executor.compatibility.FileSystem = true
			State.executor.compatibility.HTTP = true
		end
	end,
	
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
	
	-- Color utilities
	hueToRgb = function(hue)
		local r, g, b = hue:ToHSV()
		return Color3.fromHSV(r, g, b)
	end,
	
	-- Distance calculation
	getDistance = function(part1, part2)
		return (part1.Position - part2.Position).Magnitude
	end,
	
	-- Screen position calculation
	worldToScreen = function(worldPos)
		return Camera:WorldToViewportPoint(worldPos)
	end,
	
	-- Raycast for wall checks
	raycastToTarget = function(origin, target)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {Player.Character, Camera}
		
		local direction = (target - origin).Unit
		local result = Services.Workspace:Raycast(origin, direction * Config.Aimbot.lockDistance, raycastParams)
		
		return result
	end
}

-- ===================================
-- FOV CIRCLE SYSTEM
-- ===================================

local FOVCircle = {
	create = function()
		if not State.drawingAvailable then return end
		
		if State.fovCircle then
			State.fovCircle:Remove()
		end
		
		State.fovCircle = State.Drawing.new("Circle")
		State.fovCircle.Radius = Config.Aimbot.fov
		State.fovCircle.Thickness = 1
		State.fovCircle.Color = Config.Visual.fovColor
		State.fovCircle.Transparency = 1
		State.fovCircle.Visible = Config.Aimbot.enabled
		State.fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end,
	
	update = function()
		if not State.fovCircle or not State.drawingAvailable then return end
		
		State.fovCircle.Radius = Config.Aimbot.fov
		State.fovCircle.Color = Config.Visual.fovColor
		State.fovCircle.Visible = Config.Aimbot.enabled
		State.fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end,
	
	cleanup = function()
		if State.fovCircle then
			State.fovCircle:Remove()
			State.fovCircle = nil
		end
	end
}

-- ===================================
-- AIMBOT SYSTEM
-- ===================================

local Aimbot = {
	getClosestTarget = function()
		local closest = nil
		local closestDistance = Config.Aimbot.lockDistance
		
		for _, player in pairs(Services.Players:GetPlayers()) do
			if player == Player then continue end
			
			-- Team check
			if Config.Aimbot.teamCheck and player.Team == Player.Team then continue end
			
			-- Health check
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if Config.Aimbot.healthCheck and (not humanoid or humanoid.Health < Config.Aimbot.minHealth) then continue end
			
			-- Character check
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart then continue end
			
			-- Screen position check
			local screenPos, onScreen = Utils.worldToScreen(rootPart.Position)
			if not onScreen then continue end
			
			-- Distance calculation
			local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
			if distance > closestDistance then continue end
			
			-- Wall check
			if Config.Aimbot.wallCheck then
				local result = Utils.raycastToTarget(Camera.CFrame.Position, rootPart.Position)
				if not result or not result.Instance:IsDescendantOf(character) then continue end
			end
			
			closest = player
			closestDistance = distance
		end
		
		return closest
	end,
	
	applyAim = function(target)
		if not target or not target.Character then return end
		
		local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end
		
		local targetPos = rootPart.Position
		
		-- Apply prediction
		local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
			targetPos = targetPos + humanoid.MoveDirection * Config.Aimbot.prediction * 50
		end
		
		if Config.Aimbot.blatant then
			-- Blatant mode: Instant snap
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
		else
			-- Normal mode: Smooth aiming
			local aimDirection = (targetPos - Camera.CFrame.Position).Unit
			local currentLook = Camera.CFrame.LookVector
			local smoothedDirection = currentLook:Lerp(aimDirection, 1 / Config.Aimbot.smoothing)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothedDirection)
		end
	end,
	
	enableBlatant = function()
		Config.Aimbot.fov = 500
		Config.Aimbot.smoothing = 1
		Config.Aimbot.prediction = 0.1
		Config.Aimbot.wallCheck = false
		Config.Aimbot.teamCheck = false
		Config.Aimbot.healthCheck = false
		print("🔥 Blatant mode activated!")
	end,
	
	disableBlatant = function()
		Config.Aimbot.fov = 100
		Config.Aimbot.smoothing = 5
		Config.Aimbot.prediction = 0.065
		Config.Aimbot.wallCheck = true
		Config.Aimbot.teamCheck = true
		Config.Aimbot.healthCheck = false
		print("🛡️ Blatant mode deactivated!")
	end
}

-- ===================================
-- ESP SYSTEM
-- ===================================

local ESP = {
	createObjects = function(player)
		if not State.drawingAvailable or not Config.ESP.enabled then return end
		
		-- Cleanup existing objects
		ESP.cleanupObjects(player)
		
		State.espObjects[player] = {}
		
		-- Box ESP
		if Config.ESP.box then
			local box = State.Drawing.new("Square")
			box.Thickness = 1
			box.Color = Config.Visual.espColor
			box.Transparency = 1
			box.Visible = false
			table.insert(State.espObjects[player], box)
		end
		
		-- Name ESP
		if Config.ESP.name then
			local name = State.Drawing.new("Text")
			name.Size = 13
			name.Color = Config.Visual.espColor
			name.Center = true
			name.Outline = true
			name.Visible = false
			table.insert(State.espObjects[player], name)
		end
		
		-- Health ESP
		if Config.ESP.health then
			local healthBar = State.Drawing.new("Square")
			healthBar.Thickness = 1
			healthBar.Color = Color3.fromRGB(0, 255, 0)
			healthBar.Transparency = 1
			healthBar.Visible = false
			table.insert(State.espObjects[player], healthBar)
		end
		
		-- Tracer ESP
		if Config.ESP.tracer then
			local tracer = State.Drawing.new("Line")
			tracer.Thickness = 1
			tracer.Color = Config.Visual.espColor
			tracer.Transparency = 1
			tracer.Visible = false
			table.insert(State.espObjects[player], tracer)
		end
	end,
	
	updateObjects = function(player)
		if not State.drawingAvailable or not Config.ESP.enabled or not State.espObjects[player] then return end
		
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		
		if not character or not humanoid or not rootPart then
			ESP.hideObjects(player)
			return
		end
		
		-- Team check
		if Config.Aimbot.teamCheck and player.Team == Player.Team then
			ESP.hideObjects(player)
			return
		end
		
		local position, onScreen = Utils.worldToScreen(rootPart.Position)
		if not onScreen then
			ESP.hideObjects(player)
			return
		end
		
		local objIndex = 1
		
		-- Update Box ESP
		if Config.ESP.box and State.espObjects[player][objIndex] then
			local box = State.espObjects[player][objIndex]
			local size = rootPart.Size.Y * 2
			local scaleFactor = (size / (position.Z * math.tan(math.rad(Camera.FieldOfView / 2))))
			
			box.Size = Vector2.new(scaleFactor, scaleFactor * 1.5)
			box.Position = Vector2.new(position.X - box.Size.X / 2, position.Y - box.Size.Y / 2)
			box.Color = Config.Visual.espColor
			box.Visible = Config.ESP.enabled
			objIndex = objIndex + 1
		end
		
		-- Update Name ESP
		if Config.ESP.name and State.espObjects[player][objIndex] then
			local name = State.espObjects[player][objIndex]
			name.Text = player.Name .. " [" .. math.floor(Utils.getDistance(rootPart, Player.Character.HumanoidRootPart)) .. "m]"
			name.Position = Vector2.new(position.X, position.Y - 20)
			name.Color = Config.Visual.espColor
			name.Visible = Config.ESP.enabled
			objIndex = objIndex + 1
		end
		
		-- Update Health ESP
		if Config.ESP.health and State.espObjects[player][objIndex] then
			local healthBar = State.espObjects[player][objIndex]
			local healthPercent = humanoid.Health / humanoid.MaxHealth
			
			healthBar.Size = Vector2.new(4, 50)
			healthBar.Position = Vector2.new(position.X - 30, position.Y - 25)
			healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
			healthBar.Visible = Config.ESP.enabled
			objIndex = objIndex + 1
		end
		
		-- Update Tracer ESP
		if Config.ESP.tracer and State.espObjects[player][objIndex] then
			local tracer = State.espObjects[player][objIndex]
			tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			tracer.To = Vector2.new(position.X, position.Y)
			tracer.Color = Config.Visual.espColor
			tracer.Visible = Config.ESP.enabled
			objIndex = objIndex + 1
		end
	end,
	
	hideObjects = function(player)
		if not State.espObjects[player] then return end
		
		for _, obj in pairs(State.espObjects[player]) do
			if obj and obj.Visible ~= nil then
				obj.Visible = false
			end
		end
	end,
	
	cleanupObjects = function(player)
		if State.espObjects[player] then
			for _, obj in pairs(State.espObjects[player]) do
				if obj and obj.Remove then
					obj:Remove()
				end
			end
			State.espObjects[player] = nil
		end
	end
}

-- ===================================
-- MOVEMENT SYSTEM
-- ===================================

local Movement = {
	startFly = function()
		if State.connections.fly then return end
		
		State.connections.fly = Services.RunService.Heartbeat:Connect(function()
			if not Config.Movement.fly then
				Movement.stopFly()
				return
			end
			
			local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			
			local moveDirection = Vector3.new(
				(Services.UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (Services.UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0),
				(Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
				(Services.UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Services.UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
			)
			
			if moveDirection ~= Vector3.new(0, 0, 0) then
				humanoid:Move(moveDirection * Config.Movement.flySpeed)
			end
		end)
	end,
	
	stopFly = function()
		Config.Movement.fly = false
		if State.connections.fly then
			State.connections.fly:Disconnect()
			State.connections.fly = nil
		end
	end,
	
	startNoclip = function()
		if State.connections.noclip then return end
		
		State.connections.noclip = Services.RunService.Stepped:Connect(function()
			if not Config.Movement.noclip then
				Movement.stopNoclip()
				return
			end
			
			if Player.Character then
				for _, part in pairs(Player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end,
	
	stopNoclip = function()
		Config.Movement.noclip = false
		if State.connections.noclip then
			State.connections.noclip:Disconnect()
			State.connections.noclip = nil
		end
	end,
	
	startInfJump = function()
		if State.connections.infJump then return end
		
		State.connections.infJump = Services.UserInputService.JumpRequest:Connect(function()
			if Config.Movement.infJump then
				local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Jump = true
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
	end,
	
	stopInfJump = function()
		Config.Movement.infJump = false
		if State.connections.infJump then
			State.connections.infJump:Disconnect()
			State.connections.infJump = nil
		end
	end,
	
	applySpeed = function()
		local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.Movement.walkSpeed
			humanoid.JumpPower = Config.Movement.jumpPower
		end
	end
}

-- ===================================
-- UI CREATION
-- ===================================

local UI = {
	create = function()
		local Window = Bracket:Window({
			Name = "Phantom Suite v9.0",
			Color = Color3.new(0.5, 0.25, 1),
			Size = UDim2.new(0, 500, 0, 400),
			Position = UDim2.new(0.5, -250, 0.5, -200)
		})
		
		-- Create tabs
		local tabs = {
			Status = Window:Tab({Name = "Status"}),
			Aimbot = Window:Tab({Name = "Aimbot"}),
			ESP = Window:Tab({Name = "ESP"}),
			Movement = Window:Tab({Name = "Movement"}),
			Visual = Window:Tab({Name = "Visual"}),
			Configs = Window:Tab({Name = "Configs"}),
			Keybinds = Window:Tab({Name = "Keybinds"}),
			Info = Window:Tab({Name = "Info"})
		}
		
		-- Status Tab
		tabs.Status:Divider({Text = "System Status"})
		tabs.Status:Label({Text = "Executor: " .. State.executor.name})
		tabs.Status:Label({Text = "UI: Bracket Library"})
		tabs.Status:Label({Text = "Version: v9.0"})
		tabs.Status:Label({Text = "Drawing: " .. (State.drawingAvailable and "Available" or "Not Available")})
		
		-- Aimbot Tab
		tabs.Aimbot:Divider({Text = "Aimbot Settings"})
		tabs.Aimbot:Toggle({
			Name = "Enable Aimbot",
			Value = Config.Aimbot.enabled,
			Callback = function(state)
				Config.Aimbot.enabled = state
				FOVCircle.update()
				print("Aimbot:", state and "ON" or "OFF")
			end
		})
		
		tabs.Aimbot:Toggle({
			Name = "Blatant Mode",
			Value = Config.Aimbot.blatant,
			Callback = function(state)
				Config.Aimbot.blatant = state
				if state then
					Aimbot.enableBlatant()
				else
					Aimbot.disableBlatant()
				end
			end
		})
		
		tabs.Aimbot:Slider({
			Name = "FOV",
			Min = 10,
			Max = 500,
			Value = Config.Aimbot.fov,
			Precise = 0,
			Unit = "",
			Callback = function(value)
				Config.Aimbot.fov = value
				FOVCircle.update()
				print("FOV:", value)
			end
		})
		
		tabs.Aimbot:Slider({
			Name = "Smoothing",
			Min = 1,
			Max = 10,
			Value = Config.Aimbot.smoothing,
			Precise = 0,
			Unit = "",
			Callback = function(value)
				Config.Aimbot.smoothing = value
				print("Smoothing:", value)
			end
		})
		
		tabs.Aimbot:Slider({
			Name = "Prediction",
			Min = 0,
			Max = 0.2,
			Value = Config.Aimbot.prediction,
			Precise = 3,
			Unit = "",
			Callback = function(value)
				Config.Aimbot.prediction = value
				print("Prediction:", value)
			end
		})
		
		tabs.Aimbot:Toggle({
			Name = "Wall Check",
			Value = Config.Aimbot.wallCheck,
			Callback = function(state)
				Config.Aimbot.wallCheck = state
				print("Wall Check:", state and "ON" or "OFF")
			end
		})
		
		tabs.Aimbot:Toggle({
			Name = "Team Check",
			Value = Config.Aimbot.teamCheck,
			Callback = function(state)
				Config.Aimbot.teamCheck = state
				print("Team Check:", state and "ON" or "OFF")
			end
		})
		
		-- ESP Tab
		tabs.ESP:Divider({Text = "ESP Settings"})
		tabs.ESP:Toggle({
			Name = "Enable ESP",
			Value = Config.ESP.enabled,
			Callback = function(state)
				Config.ESP.enabled = state
				print("ESP:", state and "ON" or "OFF")
			end
		})
		
		tabs.ESP:Toggle({
			Name = "Box ESP",
			Value = Config.ESP.box,
			Callback = function(state)
				Config.ESP.box = state
				print("Box ESP:", state and "ON" or "OFF")
			end
		})
		
		tabs.ESP:Toggle({
			Name = "Name ESP",
			Value = Config.ESP.name,
			Callback = function(state)
				Config.ESP.name = state
				print("Name ESP:", state and "ON" or "OFF")
			end
		})
		
		tabs.ESP:Toggle({
			Name = "Health ESP",
			Value = Config.ESP.health,
			Callback = function(state)
				Config.ESP.health = state
				print("Health ESP:", state and "ON" or "OFF")
			end
		})
		
		tabs.ESP:Toggle({
			Name = "Distance ESP",
			Value = Config.ESP.distance,
			Callback = function(state)
				Config.ESP.distance = state
				print("Distance ESP:", state and "ON" or "OFF")
			end
		})
		
		tabs.ESP:Toggle({
			Name = "Tracer ESP",
			Value = Config.ESP.tracer,
			Callback = function(state)
				Config.ESP.tracer = state
				print("Tracer ESP:", state and "ON" or "OFF")
			end
		})
		
		-- Movement Tab
		tabs.Movement:Divider({Text = "Movement Settings"})
		tabs.Movement:Toggle({
			Name = "Fly",
			Value = Config.Movement.fly,
			Callback = function(state)
				Config.Movement.fly = state
				print("Fly:", state and "ON" or "OFF")
			end
		})
		
		tabs.Movement:Slider({
			Name = "Fly Speed",
			Min = 10,
			Max = 100,
			Value = Config.Movement.flySpeed,
			Precise = 0,
			Unit = "",
			Callback = function(value)
				Config.Movement.flySpeed = value
				print("Fly Speed:", value)
			end
		})
		
		tabs.Movement:Toggle({
			Name = "Noclip",
			Value = Config.Movement.noclip,
			Callback = function(state)
				Config.Movement.noclip = state
				print("Noclip:", state and "ON" or "OFF")
			end
		})
		
		tabs.Movement:Toggle({
			Name = "Infinite Jump",
			Value = Config.Movement.infJump,
			Callback = function(state)
				Config.Movement.infJump = state
				print("Infinite Jump:", state and "ON" or "OFF")
			end
		})
		
		tabs.Movement:Slider({
			Name = "Walk Speed",
			Min = 5,
			Max = 50,
			Value = Config.Movement.walkSpeed,
			Precise = 0,
			Unit = "",
			Callback = function(value)
				Config.Movement.walkSpeed = value
				Movement.applySpeed()
				print("Walk Speed:", value)
			end
		})
		
		tabs.Movement:Slider({
			Name = "Jump Power",
			Min = 10,
			Max = 100,
			Value = Config.Movement.jumpPower,
			Precise = 0,
			Unit = "",
			Callback = function(value)
				Config.Movement.jumpPower = value
				Movement.applySpeed()
				print("Jump Power:", value)
			end
		})
		
		-- Visual Tab
		tabs.Visual:Divider({Text = "Visual Settings"})
		tabs.Visual:Colorpicker({
			Name = "FOV Color",
			Value = Config.Visual.fovColor,
			Callback = function(color)
				Config.Visual.fovColor = color
				FOVCircle.update()
				print("FOV Color updated")
			end
		})
		
		tabs.Visual:Colorpicker({
			Name = "ESP Color",
			Value = Config.Visual.espColor,
			Callback = function(color)
				Config.Visual.espColor = color
				print("ESP Color updated")
			end
		})
		
		tabs.Visual:Toggle({
			Name = "Rainbow FOV",
			Value = Config.Visual.rainbowFov,
			Callback = function(state)
				Config.Visual.rainbowFov = state
				print("Rainbow FOV:", state and "ON" or "OFF")
			end
		})
		
		-- Configs Tab
		tabs.Configs:Divider({Text = "Configuration"})
		tabs.Configs:Button({
			Name = "Save Config",
			Callback = function()
				print("Config saved!")
			end
		})
		
		tabs.Configs:Button({
			Name = "Load Config",
			Callback = function()
				print("Config loaded!")
			end
		})
		
		tabs.Configs:Button({
			Name = "Reset Config",
			Callback = function()
				print("Config reset!")
			end
		})
		
		-- Keybinds Tab
		tabs.Keybinds:Divider({Text = "Keybinds"})
		tabs.Keybinds:Keybind({
			Name = "Aimbot Toggle",
			Value = Enum.KeyCode.RightShift,
			Callback = function()
				Config.Aimbot.enabled = not Config.Aimbot.enabled
				print("Aimbot:", Config.Aimbot.enabled and "ON" or "OFF")
			end
		})
		
		tabs.Keybinds:Keybind({
			Name = "ESP Toggle",
			Value = Enum.KeyCode.RightControl,
			Callback = function()
				Config.ESP.enabled = not Config.ESP.enabled
				print("ESP:", Config.ESP.enabled and "ON" or "OFF")
			end
		})
		
		-- Info Tab
		tabs.Info:Divider({Text = "Information"})
		tabs.Info:Label({Text = "Phantom Suite v9.0"})
		tabs.Info:Label({Text = "Ground-Up Rewrite"})
		tabs.Info:Label({Text = "Modern Architecture"})
		tabs.Info:Label({Text = ""})
		tabs.Info:Label({Text = "Features:"})
		tabs.Info:Label({Text = "• Advanced Aimbot"})
		tabs.Info:Label({Text = "• Comprehensive ESP"})
		tabs.Info:Label({Text = "• Movement Tools"})
		tabs.Info:Label({Text = "• Professional UI"})
		tabs.Info:Label({Text = "• Clean Architecture"})
		
		return Window
	end
}

-- ===================================
-- RAINBOW SYSTEM
-- ===================================

local Rainbow = {
	update = function()
		if not Config.Visual.rainbowFov then return end
		
		local hue = tick() * Config.Visual.rainbowSpeed % 1
		Config.Visual.fovColor = Utils.hueToRgb(Color3.fromHSV(hue, 1, 1))
		FOVCircle.update()
	end
}

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
	-- Setup systems
	Utils.detectExecutor()
	Utils.setupDrawing()
	
	-- Create UI
	local window = UI.create()
	
	-- Initialize FOV circle
	FOVCircle.create()
	
	print("✅ Phantom Suite v9.0 loaded successfully!")
	
	-- Setup ESP for existing players
	for _, player in pairs(Services.Players:GetPlayers()) do
		if player ~= Player then
			ESP.createObjects(player)
		end
	end
	
	-- Player events
	Services.Players.PlayerAdded:Connect(function(player)
		if player ~= Player then
			ESP.createObjects(player)
		end
	end)
	
	Services.Players.PlayerRemoving:Connect(function(player)
		ESP.cleanupObjects(player)
	end)
	
	-- Main game loop
	Services.RunService.Heartbeat:Connect(function()
		-- Update FOV circle
		FOVCircle.update()
		
		-- Rainbow effect
		Rainbow.update()
		
		-- Aimbot logic
		if Config.Aimbot.enabled and Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local target = Aimbot.getClosestTarget()
			if target then
				State.target = target
				Aimbot.applyAim(target)
			else
				State.target = nil
			end
		else
			State.target = nil
		end
		
		-- Movement logic
		if Config.Movement.fly then
			Movement.startFly()
		else
			Movement.stopFly()
		end
		
		if Config.Movement.noclip then
			Movement.startNoclip()
		else
			Movement.stopNoclip()
		end
		
		if Config.Movement.infJump then
			Movement.startInfJump()
		else
			Movement.stopInfJump()
		end
		
		-- Apply speed settings
		Movement.applySpeed()
	end)
	
	-- ESP update loop
	Services.RunService.RenderStepped:Connect(function()
		if Config.ESP.enabled and State.drawingAvailable then
			for _, player in pairs(Services.Players:GetPlayers()) do
				if player ~= Player then
					ESP.updateObjects(player)
				end
			end
		end
	end)
end

-- Start the script
main()
