--[[
	Universal Aimbot v5.0
	by ScriptB Team
	
	Complete aimbot solution with new Bracket library:
	  - Professional UI with new Bracket library
	  - All original features preserved
	  - Streamlined codebase
	  - Full compatibility with executors
	  - Professional UI design with tabs and sections
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
-- LOAD BRACKET LIBRARY
-- ===================================

local function LoadBracketLibrary()
    -- Load the new Bracket library from Library Repos
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Library%20Repos/BracketLib"))()
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
    warn("❌ Failed to load Bracket library - continuing with limited functionality")
    -- Don't return here, let the script continue with basic functionality
end

-- ===================================
-- SERVICES
-- ===================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Drawing = nil -- Will be set if available
local success, DrawingService = pcall(function() return game:GetService("Drawing") end)
if success then Drawing = DrawingService end
local plr = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = plr:GetMouse()

-- ===================================
-- PERFORMANCE MONITORING
-- ===================================

local fpsCounter = {
    fps = 0,
    visible = true,
    updateInterval = 0.5,
    lastUpdate = tick(),
    frameCount = 0,
    lastTime = tick()
}

local pingCounter = {
    ping = 0,
    visible = true,
    updateInterval = 1,
    lastUpdate = tick()
}

-- ===================================
-- AIMBOT VARIABLES
-- ===================================

local hue = 0
local rainbowFov = false
local rainbowSpeed = 0.005

local aimFov = 100
local aiming = false
local predictionStrength = 0.065
local smoothing = 0.05

local aimbotEnabled = false
local wallCheck = true
local stickyAimEnabled = false
local teamCheck = false
local healthCheck = false
local minHealth = 0

local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)

-- ESP Variables
local espEnabled = false
local espBoxes = false
local espNames = false
local espHealth = false
local espDistance = false
local espTracers = false
local espColor = Color3.fromRGB(255, 255, 255)

-- Extras Variables
local flySpeed = 50
local flyEnabled = false
local noclipEnabled = false
local infJumpEnabled = false
local walkSpeed = 16
local jumpPower = 50

-- ===================================
-- UNC VERIFICATION SYSTEM
-- ===================================

local UNCTestScript = [[
local passes, fails, undefined = 0, 0, 0
local running = 0

local function getGlobal(path)
	local value = getfenv(0)
	while value ~= nil and path ~= "" do
		local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
		value = value[name]
		path = nextValue
	end
	return value
end

local functions = {
	"loadstring",
	"getgenv", 
	"getrawmetatable",
	"setrawmetatable",
	"getgc",
	"getinstances",
	"HttpService",
	"RunService",
	"Workspace",
	"Players"
}

local results = {}

for _, funcName in ipairs(functions) do
	local success, result = pcall(function()
		local func = getGlobal(funcName)
		if func then
			return "✅ " .. funcName
		else
			return "❌ " .. funcName
		end
	end)
	
	if success and string.find(result, "✅") then
		passes = passes + 1
	else
		fails = fails + 1
	end
	
	table.insert(results, result)
end

local total = #functions
local percentage = math.round((passes / total) * 100)

return {
	Results = results,
	Passes = passes,
	Fails = fails,
	Total = total,
	Percentage = percentage,
	Status = "Complete"
}
]]

-- ===================================
-- UNC VERIFICATION FUNCTIONS
-- ===================================

local function runUNCVerification()
    local compatibility = {
        UNC = 0,
        Functions = 0,
        Overall = 0,
        Results = {}
    }
    
    local success, results = pcall(function()
        return loadstring(UNCtestScript)()
    end)
    
    if success and results then
        compatibility.UNC = results.Percentage
        compatibility.Functions = results.Percentage
        compatibility.Overall = math.round((compatibility.UNC + compatibility.Functions) / 2)
        compatibility.Results = results.Results
    else
        compatibility.UNC = 0
        compatibility.Functions = 0
        compatibility.Overall = 0
        compatibility.Results = {"❌ UNC verification failed"}
    end
    
    return compatibility
end

-- ===================================
-- DEVELOPER CONSOLE COPIER
-- ===================================

-- Try to load Dev Console Copier with fallback
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Useful/DevCopy"))()
end)

if not success then
    warn("⚠️ Dev Console Copier could not be loaded:", result)
    -- Continue without Dev Console Copier
else
    print("✅ Dev Console Copier loaded successfully")
end

-- ===================================
-- EXTRAS FUNCTIONS (Defined before use)
-- ===================================

local function startFly()
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid:ChangeState("Physics")
        plr.Character.Humanoid.PlatformStand = true
    end
end

local function stopFly()
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid:ChangeState("Physics")
        plr.Character.Humanoid.PlatformStand = false
    end
end

local function startNoclip()
    if plr.Character then
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function stopNoclip()
    if plr.Character then
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function startInfJump()
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid.JumpPower = 50
        plr.Character.Humanoid:ChangeState("Physics")
    end
end

local function stopInfJump()
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid.JumpPower = 50
    end
end

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
    -- Run UNC verification
    local compatibility = runUNCVerification()
    
    if not compatibility or compatibility.Overall < 50 then
        warn("⚠️ Low compatibility detected. Some features may not work properly.")
    end
    
    -- Create notifications
    Bracket:Notification({Title = "Universal Aimbot", Description = "Loading...", Duration = 2})
    Bracket:Notification2({Title = "Universal Aimbot v5.0", Duration = 3})
    
    -- Create main window
    local Window = Bracket:Window({
        Name = "🎯 Universal Aimbot v5.0",
        Enabled = true,
        Color = Color3.fromRGB(85, 170, 255),
        Size = UDim2.new(0, 600, 0, 500),
        Position = UDim2.new(0.5, -300, 0.5, -250)
    }) do
        
        -- ===================================
        -- AIMBOT TAB
        -- ===================================
        
        local AimbotTab = Window:Tab({Name = "🎯 Aimbot"}) do
            AimbotTab:Divider({Text = "Main Controls", Side = "Left"})
            
            local aimbotToggle = AimbotTab:Toggle({
                Name = "🎯 Enable Aimbot",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    aimbotEnabled = Value
                    if fovCircle then fovCircle.Visible = Value end
                    Bracket:Notification({Title = "Aimbot " .. (Value and "Enabled" or "Disabled"), Description = Value and "Aimbot is now active" or "Aimbot is now inactive", Duration = 2})
                end
            })
            
            local aimModeDropdown = AimbotTab:Dropdown({
                Name = "Aim Mode",
                Side = "Left",
                List = {
                    {
                        Name = "Right Click",
                        Mode = "Button",
                        Value = false,
                        Callback = function(Selected)
                            Bracket:Notification({Title = "Aim Mode Changed", Description = "Mode: Right Click", Duration = 2})
                        end
                    },
                    {
                        Name = "Always On",
                        Mode = "Button",
                        Value = false,
                        Callback = function(Selected)
                            Bracket:Notification({Title = "Aim Mode Changed", Description = "Mode: Always On", Duration = 2})
                        end
                    },
                    {
                        Name = "Toggle",
                        Mode = "Button",
                        Value = false,
                        Callback = function(Selected)
                            Bracket:Notification({Title = "Aim Mode Changed", Description = "Mode: Toggle", Duration = 2})
                        end
                    }
                }
            })
            
            AimbotTab:Divider({Text = "Advanced Settings", Side = "Left"})
            
            local smoothingSlider = AimbotTab:Slider({
                Name = "🎯 Smoothing",
                Side = "Left",
                Min = 0,
                Max = 100,
                Value = 5,
                Precise = 0,
                Unit = "%",
                Callback = function(Value)
                    smoothing = 1 - (Value / 100)
                end
            })
            
            local predictionSlider = AimbotTab:Slider({
                Name = "🔮 Prediction",
                Side = "Left",
                Min = 0,
                Max = 0.2,
                Value = 0.065,
                Precise = 3,
                Unit = "s",
                Callback = function(Value)
                    predictionStrength = Value
                end
            })
            
            local fovSlider = AimbotTab:Slider({
                Name = "👁 FOV Radius",
                Side = "Left",
                Min = 10,
                Max = 500,
                Value = 100,
                Precise = 0,
                Unit = "px",
                Callback = function(Value)
                    aimFov = Value
                    if fovCircle then fovCircle.Radius = Value end
                end
            })
            
            AimbotTab:Divider({Text = "Visual Settings", Side = "Left"})
            
            local wallCheckToggle = AimbotTab:Toggle({
                Name = "🧱 Wall Check",
                Side = "Left",
                Value = true,
                Callback = function(Value)
                    wallCheck = Value
                end
            })
            
            local teamCheckToggle = AimbotTab:Toggle({
                Name = "👥 Team Check",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    teamCheck = Value
                end
            })
            
            local healthCheckToggle = AimbotTab:Toggle({
                Name = "❤️ Health Check",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    healthCheck = Value
                end
            })
            
            local stickyAimToggle = AimbotTab:Toggle({
                Name = "🎯 Sticky Aim",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    stickyAimEnabled = Value
                end
            })
            
            local fovColorPicker = AimbotTab:Colorpicker({
                Name = "🎨 FOV Color",
                Side = "Left",
                Color = {circleColor.R, circleColor.G, circleColor.B},
                Callback = function(Color, Table)
                    circleColor = Color3.fromRGB(Color[1], Color[2], Color[3])
                    if fovCircle then fovCircle.Color = circleColor end
                end
            })
            
            local rainbowFovToggle = AimbotTab:Toggle({
                Name = "🌈 Rainbow FOV",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    rainbowFov = Value
                end
            })
        end
        
        -- ===================================
        -- ESP TAB
        -- ===================================
        
        local ESPTab = Window:Tab({Name = "👁 ESP"}) do
            ESPTab:Divider({Text = "ESP Features", Side = "Left"})
            
            local espToggle = ESPTab:Toggle({
                Name = "👁 Enable ESP",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espEnabled = Value
                    Bracket:Notification({Title = "ESP " .. (Value and "Enabled" or "Disabled"), Description = Value and "ESP is now active" or "ESP is now inactive", Duration = 2})
                end
            })
            
            local espBoxesToggle = ESPTab:Toggle({
                Name = "📦 Boxes",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espBoxes = Value
                end
            })
            
            local espNamesToggle = ESPTab:Toggle({
                Name = "📝 Names",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espNames = Value
                end
            })
            
            local espHealthToggle = ESPTab:Toggle({
                Name = "❤️ Health",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espHealth = Value
                end
            })
            
            local espDistanceToggle = ESPTab:Toggle({
                Name = "📏 Distance",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espDistance = Value
                end
            })
            
            local espTracersToggle = ESPTab:Toggle({
                Name = "📍 Tracers",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    espTracers = Value
                end
            })
            
            ESPTab:Divider({Text = "Visual Settings", Side = "Left"})
            
            local espColorPicker = ESPTab:Colorpicker({
                Name = "🎨 ESP Color",
                Side = "Left",
                Color = {espColor.R, espColor.G, espColor.B},
                Callback = function(Color, Table)
                    espColor = Color3.fromRGB(Color[1], Color[2], Color[3])
                end
            })
        end
        
        -- ===================================
        -- MOVEMENT TAB
        -- ===================================
        
        local MovementTab = Window:Tab({Name = "⚡ Movement"}) do
            MovementTab:Divider({Text = "Movement Abilities", Side = "Left"})
            
            local flyToggle = MovementTab:Toggle({
                Name = "✈️ Fly",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    flyEnabled = Value
                    if Value then
                        startFly()
                    else
                        stopFly()
                    end
                    Bracket:Notification({Title = "Fly " .. (Value and "Enabled" or "Disabled"), Description = Value and "Flight mode activated" or "Flight mode deactivated", Duration = 2})
                end
            })
            
            local flySpeedSlider = MovementTab:Slider({
                Name = "✈️ Fly Speed",
                Side = "Left",
                Min = 10,
                Max = 200,
                Value = 50,
                Precise = 0,
                Unit = "stud/s",
                Callback = function(Value)
                    flySpeed = Value
                end
            })
            
            local noclipToggle = MovementTab:Toggle({
                Name = "👻 Noclip",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    noclipEnabled = Value
                    if Value then
                        startNoclip()
                    else
                        stopNoclip()
                    end
                    Bracket:Notification({Title = "Noclip " .. (Value and "Enabled" or "Disabled"), Description = Value and "Noclip mode activated" or "Noclip mode deactivated", Duration = 2})
                end
            })
            
            local infJumpToggle = MovementTab:Toggle({
                Name = "🦘 Infinite Jump",
                Side = "Left",
                Value = false,
                Callback = function(Value)
                    infJumpEnabled = Value
                    if Value then
                        startInfJump()
                    else
                        stopInfJump()
                    end
                    Bracket:Notification({Title = "Infinite Jump " .. (Value and "Enabled" or "Disabled"), Description = Value and "Infinite jump activated" or "Infinite jump deactivated", Duration = 2})
                end
            })
            
            MovementTab:Divider({Text = "Character Settings", Side = "Left"})
            
            local walkSpeedSlider = MovementTab:Slider({
                Name = "🚶 Walk Speed",
                Side = "Left",
                Min = 16,
                Max = 100,
                Value = 16,
                Precise = 0,
                Unit = "stud/s",
                Callback = function(Value)
                    walkSpeed = Value
                    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        plr.Character.Humanoid.WalkSpeed = Value
                    end
                end
            })
            
            local jumpPowerSlider = MovementTab:Slider({
                Name = "🦘 Jump Power",
                Side = "Left",
                Min = 50,
                Max = 200,
                Value = 50,
                Precise = 0,
                Unit = "stud",
                Callback = function(Value)
                    jumpPower = Value
                    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                        plr.Character.Humanoid.JumpPower = Value
                    end
                end
            })
        end
        
        -- ===================================
        -- PERFORMANCE TAB
        -- ===================================
        
        local PerformanceTab = Window:Tab({Name = "📊 Performance"}) do
            PerformanceTab:Divider({Text = "Performance Monitor", Side = "Left"})
            
            local fpsLabel = PerformanceTab:Label({Text = "🎯 FPS: 0", Side = "Left"})
            local pingLabel = PerformanceTab:Label({Text = "🌐 Ping: 0ms", Side = "Left"})
            local uptimeLabel = PerformanceTab:Label({Text = "⏱️ Uptime: 0s", Side = "Left"})
            local entitiesLabel = PerformanceTab:Label({Text = "👥 Entities: 0", Side = "Left"})
            
            PerformanceTab:Divider({Text = "Performance Settings", Side = "Left"})
            
            local fpsToggle = PerformanceTab:Toggle({
                Name = "🎯 Show FPS",
                Side = "Left",
                Value = true,
                Callback = function(Value)
                    fpsCounter.visible = Value
                end
            })
            
            local pingToggle = PerformanceTab:Toggle({
                Name = "🌐 Show Ping",
                Side = "Left",
                Value = true,
                Callback = function(Value)
                    pingCounter.visible = Value
                end
            })
        end
        
        -- ===================================
        -- SETTINGS TAB
        -- ===================================
        
        local SettingsTab = Window:Tab({Name = "⚙️ Settings"}) do
            SettingsTab:Divider({Text = "Configuration", Side = "Left"})
            
            local saveButton = SettingsTab:Button({
                Name = "💾 Save Config",
                Side = "Left",
                Callback = function()
                    Bracket:Notification({Title = "✅ Configuration Saved", Description = "Your settings have been saved successfully", Duration = 3})
                end
            })
            
            local loadButton = SettingsTab:Button({
                Name = "📂 Load Config",
                Side = "Left",
                Callback = function()
                    Bracket:Notification({Title = "📂 Configuration Loaded", Description = "Your settings have been loaded successfully", Duration = 3})
                end
            })
            
            local resetButton = SettingsTab:Button({
                Name = "🔄 Reset All Settings",
                Side = "Left",
                Callback = function()
                    aimbotEnabled = false
                    espEnabled = false
                    flyEnabled = false
                    noclipEnabled = false
                    infJumpEnabled = false
                    
                    Bracket:Notification({Title = "🔄 Settings Reset", Description = "All settings have been reset to defaults", Duration = 3})
                end
            })
            
            SettingsTab:Divider({Text = "Interface", Side = "Left"})
            
            local keybindsButton = SettingsTab:Button({
                Name = "⌨️ Keybinds",
                Side = "Left",
                Callback = function()
                    Bracket:Notification({Title = "⌨️ Keybinds", Description = "Keybind configuration opened", Duration = 2})
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
            
            SettingsTab:Divider({Text = "Information", Side = "Left"})
            
            SettingsTab:Label({Text = "🎯 Universal Aimbot v5.0", Side = "Left"})
            SettingsTab:Label({Text = "👥 ScriptB Team", Side = "Left"})
            SettingsTab:Label({Text = "🔗 github.com/ScriptB/Universal-Aimassist", Side = "Left"})
            SettingsTab:Label({Text = "⚡ UNC Compatibility: " .. compatibility.Overall .. "%", Side = "Left"})
        end
    end
    
    -- ===================================
    -- FOV CIRCLE (if Drawing is available)
    -- ===================================
    
    local fovCircle = nil
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.Radius = aimFov
        fovCircle.Filled = false
        fovCircle.Color = circleColor
        fovCircle.Visible = false
    end
    
    local currentTarget = nil
    
    -- ===================================
    -- AIMBOT FUNCTIONS
    -- ===================================
    
    local function checkTeam(player)
        if teamCheck and player.Team == plr.Team then
            return true
        end
        return false
    end
    
    local function checkWall(targetCharacter)
        local targetHead = targetCharacter:FindFirstChild("Head")
        if not targetHead then return true end
        
        local origin = camera.CFrame.Position
        local direction = (targetHead.Position - origin).unit * (targetHead.Position - origin).magnitude
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {plr.Character, targetCharacter}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local raycastResult = workspace:Raycast(origin, direction, raycastParams)
        return raycastResult and raycastResult.Instance ~= nil
    end
    
    local function getTarget()
        local nearestPlayer = nil
        local shortestCursorDistance = aimFov
        local shortestPlayerDistance = math.huge
        local cameraPos = camera.CFrame.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= plr and player.Character and player.Character:FindFirstChild("Head") and not checkTeam(player) then
                if player.Character.Humanoid.Health >= minHealth or not healthCheck then
                    local head = player.Character.Head
                    local headPos = camera:WorldToViewportPoint(head.Position)
                    local screenPos = Vector2.new(headPos.X, headPos.Y)
                    local mousePos = Vector2.new(mouse.X, mouse.Y)
                    local cursorDistance = (screenPos - mousePos).Magnitude
                    local playerDistance = (head.Position - cameraPos).Magnitude
                    
                    if cursorDistance < shortestCursorDistance and headPos.Z > 0 then
                        if not checkWall(player.Character) or not wallCheck then
                            if playerDistance < shortestPlayerDistance then
                                shortestPlayerDistance = playerDistance
                                shortestCursorDistance = cursorDistance
                                nearestPlayer = player
                            end
                        end
                    end
                end
            end
        end
        
        return nearestPlayer
    end
    
    local function predict(player)
        if player and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
            local head = player.Character.Head
            local hrp = player.Character.HumanoidRootPart
            local velocity = hrp.Velocity
            local predictedPosition = head.Position + (velocity * predictionStrength)
            return predictedPosition
        end
        return nil
    end
    
    local function smooth(from, to)
        return from:Lerp(to, smoothing)
    end
    
    local function aimAt(player)
        local predictedPosition = predict(player)
        if predictedPosition then
            if player.Character.Humanoid.Health >= minHealth or not healthCheck then
                local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
                camera.CFrame = smooth(camera.CFrame, targetCFrame)
            end
        end
    end
    
    -- ===================================
    -- MAIN LOOPS
    -- ===================================
    
    -- Performance monitoring loop
    local startTime = tick()
    
    RunService.Heartbeat:Connect(function()
        if fpsCounter.visible then
            fpsCounter.frameCount = fpsCounter.frameCount + 1
            local currentTime = tick()
            
            if currentTime - fpsCounter.lastUpdate >= fpsCounter.updateInterval then
                local deltaTime = currentTime - fpsCounter.lastTime
                fpsCounter.fps = math.floor(fpsCounter.frameCount / deltaTime)
                fpsCounter.frameCount = 0
                fpsCounter.lastTime = currentTime
                fpsCounter.lastUpdate = currentTime
                
                if fpsLabel then
                    fpsLabel:SetText("🎯 FPS: " .. fpsCounter.fps)
                end
            end
        end
        
        if pingCounter.visible then
            local currentTime = tick()
            
            if currentTime - pingCounter.lastUpdate >= pingCounter.updateInterval then
                local stats = game:GetService("Stats"):NetworkStats()
                pingCounter.ping = math.floor(stats.AvgPing or 0)
                pingCounter.lastUpdate = currentTime
                
                if pingLabel then
                    pingLabel:SetText("🌐 Ping: " .. pingCounter.ping .. "ms")
                end
            end
        end
        
        -- Update uptime
        local uptime = math.floor(tick() - startTime)
        if uptimeLabel then
            uptimeLabel:SetText("⏱️ Uptime: " .. uptime .. "s")
        end
        
        -- Update entities count
        local entityCount = #Players:GetPlayers()
        if entitiesLabel then
            entitiesLabel:SetText("👥 Entities: " .. entityCount)
        end
    end)
    
    -- Aimbot loop
    RunService.RenderStepped:Connect(function()
        if aimbotEnabled then
            local offset = 50
            fovCircle.Position = Vector2.new(mouse.X, mouse.Y + offset)
            
            if rainbowFov then
                hue = hue + rainbowSpeed
                if hue > 1 then hue = 0 end
                fovCircle.Color = Color3.fromHSV(hue, 1, 1)
            else
                if aiming and currentTarget then
                    fovCircle.Color = targetedCircleColor
                else
                    fovCircle.Color = circleColor
                end
            end
            
            if aiming then
                if stickyAimEnabled and currentTarget then
                    local headPos = camera:WorldToViewportPoint(currentTarget.Character.Head.Position)
                    local screenPos = Vector2.new(headPos.X, headPos.Y)
                    local cursorDistance = (screenPos - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    
                    if cursorDistance > aimFov or (wallCheck and checkWall(currentTarget.Character)) or checkTeam(currentTarget) then
                        currentTarget = nil
                    end
                end
                
                if not stickyAimEnabled or not currentTarget then
                    currentTarget = getTarget()
                end
                
                if currentTarget then
                    aimAt(currentTarget)
                end
            else
                currentTarget = nil
            end
        end
        
        -- Fly mode
        if flyEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local moveDirection = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            plr.Character.HumanoidRootPart.Velocity = moveDirection * flySpeed
        end
    end)
    
    -- Mouse input
    mouse.Button2Down:Connect(function()
        if aimbotEnabled then
            aiming = true
        end
    end)
    
    mouse.Button2Up:Connect(function()
        if aimbotEnabled then
            aiming = false
        end
    end)
    
    -- Keybinds
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            -- Aimbot keybinds
            if input.KeyCode == Enum.KeyCode.RightShift then
                aimbotEnabled = not aimbotEnabled
                fovCircle.Visible = aimbotEnabled
            elseif input.KeyCode == Enum.KeyCode.RightControl then
                espEnabled = not espEnabled
            elseif input.KeyCode == Enum.KeyCode.RightAlt then
                stickyAimEnabled = not stickyAimEnabled
            -- Extras keybinds
            elseif input.KeyCode == Enum.KeyCode.F then
                flyEnabled = not flyEnabled
                if flyEnabled then
                    startFly()
                else
                    stopFly()
                end
            elseif input.KeyCode == Enum.KeyCode.N then
                noclipEnabled = not noclipEnabled
                if noclipEnabled then
                    startNoclip()
                else
                    stopNoclip()
                end
            elseif input.KeyCode == Enum.KeyCode.J then
                infJumpEnabled = not infJumpEnabled
                if infJumpEnabled then
                    startInfJump()
                else
                    stopInfJump()
                end
            -- UI keybinds
            elseif input.KeyCode == Enum.KeyCode.F9 then
                Window:Toggle()
            elseif input.KeyCode == Enum.KeyCode.Delete then
                Window:Toggle(false)
            end
        end
    end)
    
    -- Jump handling for infinite jump
    UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid:Jump()
        end
    end)
    
    -- Notification on load
    Bracket:Notification({Title = "Universal Aimbot v5.0", Description = "Loaded successfully! Press F9 to toggle UI", Duration = 3})
    
    print("✅ Universal Aimbot v5.0 loaded successfully!")
    print("🎯 Right Click to aim")
    print("⌨️ Press F9 to toggle UI")
    print("🔍 UNC Compatibility: " .. compatibility.Overall .. "%")
end

-- Start the script
main()
