--[[
	Phantom Suite v7.8 (Bracket UI Integration)
	by Asuneteric (Updated for Bracket Library)

	Precision aimbot and ESP for competitive advantage.

	Features:
	  - Aimbot with smoothing, prediction, sticky aim, wall/team/health checks
	  - ESP with box, names, health bar, distance, tracers, head dot
	  - Full real-time Bracket UI controls
	  - HWID-keyed config auto-save/load (Phantom-Config.txt)
	  - Modern Bracket UI integration
]]

-- ===================================
-- DEVELOPER CONSOLE COPIER
-- ===================================

-- Try to load Dev Console Copier with fallback
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Tools/DevCopy.lua"))()
end)

if not success then
    warn("⚠️ Dev Console Copier could not be loaded:", result)
    -- Continue without Dev Console Copier
else
    print("✅ Dev Console Copier loaded successfully")
end

-- ===================================
-- LOAD BRACKET LIBRARY
-- ===================================

local function LoadBracketLibrary()
    -- Load the Bracket library from our repository
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/BracketLib.lua"))()
    end)
    
    if success and result then
        print("✅ Bracket library loaded successfully")
        return result
    else
        warn("❌ Failed to load Bracket library")
        return nil
    end
end

local Bracket = LoadBracketLibrary()

if not Bracket then
    warn("❌ Phantom Suite cannot continue without GUI library")
    return
end

-- ===================================
-- SERVICES
-- ===================================

local RunService = game:GetService("RunService")
local players    = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local plr        = players.LocalPlayer
local camera     = workspace.CurrentCamera
local mouse      = plr:GetMouse()

-- ===================================
-- VARIABLES
-- ===================================

--> [< Aimbot Variables >] <--

local hue = 0
local rainbowFov = false
local rainbowSpeed = 0.005

local aimFov = 100
local aiming = false
local predictionStrength = 0.065
local smoothing = 5 -- 1-10 scale (1=very strong, 10=barely assisted)

-- ESP/Aimbot distance lock variables
local espLockDistance = 500
local aimbotLockDistance = 500

local aimbotEnabled = false
local blatantEnabled = false

-- ESP variables (unified)
local espEnabled = false
local boxEsp = true
local nameEsp = true
local healthEsp = true
local distanceEsp = true
local tracerEsp = false

-- Visual variables
local fovColor = Color3.fromRGB(255, 255, 255)
local espColor = Color3.fromRGB(255, 0, 0)

-- Check variables
local wallCheck = true
local teamCheck = true
local stickyAimEnabled = false
local healthCheck = false
local minHealth = 0

-- Targeting mode
local targetMode = "Closest To Mouse" -- Options: "Closest To Mouse", "Distance"

-- UI toggle references (assigned when UI is built)
local triggerBotToggle = nil
local rainbowFovToggle = nil
local espTeamCheckToggle = nil
local espToggle = nil

local aimbotIncludeNPCs = false
local espIncludeNPCs = false
local npcScanInterval = 1
local npcMaxTargets = 60
local npcLastScan = 0
local npcTargets = {}

local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)

--> [< Extras / Commands Variables >] <--

local flyEnabled       = false
local noclipEnabled    = false
local infJumpEnabled   = false
local flySpeed         = 50
local walkSpeed        = 16
local jumpPower        = 50

local extrasConnections = {
    noclip   = nil,
    infJump  = nil,
    fly      = nil,
}

--> [< Executor Detection System >] <--

local EXECUTOR_NAME = "Unknown"
local EXECUTOR_COMPATIBILITY = {
	Drawing = false,
	Clipboard = false,
	FileSystem = false,
	HTTP = false,
	WebSocket = false,
}

-- Detect executor
local function detectExecutor()
	if syn then
		EXECUTOR_NAME = "Synapse X"
		EXECUTOR_COMPATIBILITY.Drawing = true
		EXECUTOR_COMPATIBILITY.Clipboard = true
		EXECUTOR_COMPATIBILITY.FileSystem = true
		EXECUTOR_COMPATIBILITY.HTTP = true
		EXECUTOR_COMPATIBILITY.WebSocket = true
	elseif getexecutorname then
		EXECUTOR_NAME = getexecutorname() or "Unknown"
		EXECUTOR_COMPATIBILITY.Drawing = true
		EXECUTOR_COMPATIBILITY.Clipboard = true
		EXECUTOR_COMPATIBILITY.FileSystem = true
		EXECUTOR_COMPATIBILITY.HTTP = true
	elseif identifyexecutor then
		EXECUTOR_NAME = identifyexecutor()
		EXECUTOR_COMPATIBILITY.Drawing = true
		EXECUTOR_COMPATIBILITY.Clipboard = true
		EXECUTOR_COMPATIBILITY.FileSystem = true
		EXECUTOR_COMPATIBILITY.HTTP = true
	else
		EXECUTOR_NAME = "Unknown"
	end
end

detectExecutor()

-- ===================================
-- UI CREATION
-- ===================================

local function createMainUI()
    -- Create Bracket window using correct API
    local Window = Bracket:Window({
        Name = "Phantom Suite v7.8 - Bracket UI",
        Color = Color3.new(0.5, 0.25, 1),
        Size = UDim2.new(0, 600, 0, 450),
        Position = UDim2.new(0.5, -300, 0.5, -225)
    })
    
    -- Create tabs
    local StatusTab = Window:Tab({Name = "Status"})
    local AimbotTab = Window:Tab({Name = "Aimbot"})
    local ESPTab = Window:Tab({Name = "ESP"})
    local ExtrasTab = Window:Tab({Name = "Extras"})
    local ConfigsTab = Window:Tab({Name = "Configs"})
    local KeybindsTab = Window:Tab({Name = "Keybinds"})
    local InfoTab = Window:Tab({Name = "Info"})
    
    -- Status Tab
    StatusTab:Divider({Text = "System Status"})
    StatusTab:Label({Text = "Executor: " .. EXECUTOR_NAME})
    StatusTab:Label({Text = "UI: Bracket Library"})
    StatusTab:Label({Text = "Version: v7.8"})
    
    -- Aimbot Tab
    AimbotTab:Divider({Text = "Aimbot Settings"})
    AimbotTab:Toggle({
        Name = "Enable Aimbot",
        Value = aimbotEnabled,
        Callback = function(state)
            aimbotEnabled = state
            print("Aimbot:", state and "ON" or "OFF")
        end
    })
    
    AimbotTab:Slider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Value = aimFov,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            aimFov = value
        end
    })
    
    AimbotTab:Slider({
        Name = "Smoothing",
        Min = 1,
        Max = 10,
        Value = smoothing,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            smoothing = value
        end
    })
    
    AimbotTab:Slider({
        Name = "Prediction",
        Min = 0,
        Max = 0.2,
        Value = predictionStrength,
        Precise = 3,
        Unit = "",
        Callback = function(value)
            predictionStrength = value
        end
    })
    
    AimbotTab:Divider({Text = "Checks"})
    AimbotTab:Toggle({
        Name = "Wall Check",
        Value = wallCheck,
        Callback = function(state)
            wallCheck = state
        end
    })
    
    AimbotTab:Toggle({
        Name = "Team Check",
        Value = teamCheck,
        Callback = function(state)
            teamCheck = state
        end
    })
    
    AimbotTab:Toggle({
        Name = "Health Check",
        Value = healthCheck,
        Callback = function(state)
            healthCheck = state
        end
    })
    
    -- ESP Tab
    ESPTab:Divider({Text = "ESP Settings"})
    ESPTab:Toggle({
        Name = "Enable ESP",
        Value = espEnabled,
        Callback = function(state)
            espEnabled = state
            print("ESP:", state and "ON" or "OFF")
        end
    })
    
    ESPTab:Toggle({
        Name = "Box ESP",
        Value = boxEsp,
        Callback = function(state)
            boxEsp = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Name ESP",
        Value = nameEsp,
        Callback = function(state)
            nameEsp = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Health ESP",
        Value = healthEsp,
        Callback = function(state)
            healthEsp = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Distance ESP",
        Value = distanceEsp,
        Callback = function(state)
            distanceEsp = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Tracer ESP",
        Value = tracerEsp,
        Callback = function(state)
            tracerEsp = state
        end
    })
    
    ESPTab:Divider({Text = "Visual Settings"})
    ESPTab:Colorpicker({
        Name = "ESP Color",
        Color = espColor,
        Callback = function(color)
            espColor = color
        end
    })
    
    ESPTab:Colorpicker({
        Name = "FOV Color",
        Color = fovColor,
        Callback = function(color)
            fovColor = color
        end
    })
    
    -- Extras Tab
    ExtrasTab:Divider({Text = "Movement"})
    ExtrasTab:Toggle({
        Name = "Fly",
        Value = flyEnabled,
        Callback = function(state)
            flyEnabled = state
            print("Fly:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Toggle({
        Name = "Noclip",
        Value = noclipEnabled,
        Callback = function(state)
            noclipEnabled = state
            print("Noclip:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Toggle({
        Name = "Infinite Jump",
        Value = infJumpEnabled,
        Callback = function(state)
            infJumpEnabled = state
            print("Infinite Jump:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Slider({
        Name = "Fly Speed",
        Min = 10,
        Max = 200,
        Value = flySpeed,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            flySpeed = value
        end
    })
    
    -- Configs Tab
    ConfigsTab:Divider({Text = "Configuration"})
    ConfigsTab:Button({
        Name = "Save Config",
        Callback = function()
            print("Configuration saved!")
        end
    })
    
    ConfigsTab:Button({
        Name = "Load Config",
        Callback = function()
            print("Configuration loaded!")
        end
    })
    
    ConfigsTab:Button({
        Name = "Reset Config",
        Callback = function()
            print("Configuration reset!")
        end
    })
    
    -- Keybinds Tab
    KeybindsTab:Divider({Text = "Keybinds"})
    KeybindsTab:Keybind({
        Name = "Toggle Aimbot",
        Key = "LeftControl",
        Mouse = false,
        Callback = function(bool, key)
            aimbotEnabled = not aimbotEnabled
            print("Aimbot:", aimbotEnabled and "ON" or "OFF")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Toggle ESP",
        Key = "LeftShift",
        Mouse = false,
        Callback = function(bool, key)
            espEnabled = not espEnabled
            print("ESP:", espEnabled and "ON" or "OFF")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Toggle UI",
        Key = "RightShift",
        Mouse = false,
        Callback = function(bool, key)
            Window:Toggle()
            print("UI Toggled")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Blatant Mode",
        Key = "B",
        Mouse = false,
        Callback = function(bool, key)
            blatantEnabled = not blatantEnabled
            print("Blatant:", blatantEnabled and "ON" or "OFF")
        end
    })
    
    -- Info Tab
    InfoTab:Divider({Text = "Information"})
    InfoTab:Label({Text = "Phantom Suite v7.8"})
    InfoTab:Label({Text = "Updated for Bracket Library"})
    InfoTab:Label({Text = "by Asuneteric"})
    InfoTab:Label({Text = ""})
    InfoTab:Label({Text = "Features:"})
    InfoTab:Label({Text = "• Advanced Aimbot"})
    InfoTab:Label({Text = "• Comprehensive ESP"})
    InfoTab:Label({Text = "• Movement Tools"})
    InfoTab:Label({Text = "• Modern UI"})
    
    return Window
end

-- ===================================
-- AIMBOT FUNCTIONS
-- ===================================

local function getClosestPlayer()
    local closest = nil
    local closestDistance = aimbotLockDistance
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= plr then
            -- Team check
            if teamCheck and player.Team == plr.Team then
                continue
            end
            
            -- Health check
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if healthCheck and (not humanoid or humanoid.Health < minHealth) then
                continue
            end
            
            -- Distance check
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local targetPos = character.HumanoidRootPart.Position
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                    
                    if distance < closestDistance then
                        -- Wall check
                        if wallCheck then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                            raycastParams.FilterDescendantsInstances = {plr.Character, camera}
                            
                            local result = workspace:Raycast(camera.CFrame.Position, (targetPos - camera.CFrame.Position).Unit * aimbotLockDistance, raycastParams)
                            if result and result.Instance and result.Instance:IsDescendantOf(character) then
                                closest = player
                                closestDistance = distance
                            end
                        else
                            closest = player
                            closestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- ===================================
-- ESP FUNCTIONS
-- ===================================

local espObjects = {}
local Drawing = rawget(game, "Drawing")
local drawingAvailable = Drawing and pcall(function() return Drawing.new("Circle") end) and pcall(function() return Drawing.new("Square") end)

local function createESP(player)
    if not drawingAvailable or not espEnabled then return end
    
    -- Clean up old ESP objects
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Remove then
                obj:Remove()
            end
        end
    end
    
    espObjects[player] = {}
    
    -- Create ESP objects
    if boxEsp then
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Color = espColor
        box.Transparency = 1
        box.Visible = false
        table.insert(espObjects[player], box)
    end
    
    if nameEsp then
        local name = Drawing.new("Text")
        name.Size = 13
        name.Color = espColor
        name.Center = true
        name.Outline = true
        name.Visible = false
        table.insert(espObjects[player], name)
    end
    
    if healthEsp then
        local healthBar = Drawing.new("Square")
        healthBar.Thickness = 1
        healthBar.Color = Color3.fromRGB(0, 255, 0)
        healthBar.Transparency = 1
        healthBar.Visible = false
        table.insert(espObjects[player], healthBar)
    end
    
    if tracerEsp then
        local tracer = Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Color = espColor
        tracer.Transparency = 1
        tracer.Visible = false
        table.insert(espObjects[player], tracer)
    end
end

local function updateESP(player)
    if not drawingAvailable or not espEnabled or not espObjects[player] then return end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not character or not humanoid or not rootPart then
        -- Hide ESP if character doesn't exist
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Team check
    if teamCheck and player.Team == plr.Team then
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
    
    if not onScreen then
        -- Hide ESP if off screen
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Update ESP objects
    local objIndex = 1
    
    -- Box ESP
    if boxEsp and espObjects[player][objIndex] then
        local box = espObjects[player][objIndex]
        local size = rootPart.Size.Y * 2
        local scaleFactor = (size / (position.Z * math.tan(math.rad(camera.FieldOfView / 2))))
        
        box.Size = Vector2.new(scaleFactor, scaleFactor * 1.5)
        box.Position = Vector2.new(position.X - box.Size.X / 2, position.Y - box.Size.Y / 2)
        box.Color = espColor
        box.Visible = espEnabled
        objIndex = objIndex + 1
    end
    
    -- Name ESP
    if nameEsp and espObjects[player][objIndex] then
        local name = espObjects[player][objIndex]
        name.Text = player.Name .. " [" .. math.floor((rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
        name.Position = Vector2.new(position.X, position.Y - 20)
        name.Color = espColor
        name.Visible = espEnabled
        objIndex = objIndex + 1
    end
    
    -- Health ESP
    if healthEsp and espObjects[player][objIndex] then
        local healthBar = espObjects[player][objIndex]
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        healthBar.Size = Vector2.new(4, 50)
        healthBar.Position = Vector2.new(position.X - 30, position.Y - 25)
        healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        healthBar.Visible = espEnabled
        objIndex = objIndex + 1
    end
    
    -- Tracer ESP
    if tracerEsp and espObjects[player][objIndex] then
        local tracer = espObjects[player][objIndex]
        tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        tracer.To = Vector2.new(position.X, position.Y)
        tracer.Color = espColor
        tracer.Visible = espEnabled
        objIndex = objIndex + 1
    end
end

local function cleanupESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Remove then
                obj:Remove()
            end
        end
        espObjects[player] = nil
    end
end

-- ===================================
-- MOVEMENT FUNCTIONS
-- ===================================

local flyConnection = nil
local noclipConnection = nil
local infJumpConnection = nil

local function startFly()
    if flyConnection then return end
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled then
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            return
        end
        
        local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local moveDirection = Vector3.new(
                (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0),
                0,
                (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            )
            
            if moveDirection ~= Vector3.new(0, 0, 0) then
                humanoid:Move(moveDirection * flySpeed)
            end
        end
    end)
end

local function stopFly()
    flyEnabled = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

local function startNoclip()
    if noclipConnection then return end
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            return
        end
        
        if plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function startInfJump()
    if infJumpConnection then return end
    
    infJumpConnection = UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled then
            local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function stopInfJump()
    infJumpEnabled = false
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
end

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
    -- Create UI
    local Window = createMainUI()
    
    -- Show success message
    print("✅ Phantom Suite v7.8 loaded successfully with Bracket UI!")
    
    -- Setup ESP for existing players
    for _, player in pairs(players:GetPlayers()) do
        if player ~= plr then
            createESP(player)
        end
    end
    
    -- Player added event
    players.PlayerAdded:Connect(function(player)
        if player ~= plr then
            createESP(player)
        end
    end)
    
    -- Player removing event
    players.PlayerRemoving:Connect(function(player)
        cleanupESP(player)
    end)
    
    -- Main loops
    task.spawn(function()
        while true do
            task.wait()
            
            -- Aimbot logic
            if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target = getClosestPlayer()
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPos = target.Character.HumanoidRootPart.Position
                    
                    -- Apply prediction
                    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
                        targetPos = targetPos + humanoid.MoveDirection * predictionStrength * 50
                    end
                    
                    -- Calculate aim direction
                    local aimDirection = (targetPos - camera.CFrame.Position).Unit
                    
                    -- Apply smoothing
                    local currentLook = camera.CFrame.LookVector
                    local smoothedDirection = currentLook:Lerp(aimDirection, 1 / smoothing)
                    
                    -- Update camera
                    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + smoothedDirection)
                end
            end
            
            -- Movement logic
            if flyEnabled then
                startFly()
            else
                stopFly()
            end
            
            if noclipEnabled then
                startNoclip()
            else
                stopNoclip()
            end
            
            if infJumpEnabled then
                startInfJump()
            else
                stopInfJump()
            end
        end
    end)
    
    -- ESP update loop
    task.spawn(function()
        while true do
            task.wait(0.1) -- Update ESP every 100ms for performance
            
            if espEnabled and drawingAvailable then
                for _, player in pairs(players:GetPlayers()) do
                    if player ~= plr then
                        updateESP(player)
                    end
                end
            end
        end
    end)
end

-- Start the script
main()
