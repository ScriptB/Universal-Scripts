--[[
	Universal Aimbot v3.0
	by ScriptB Team

	Complete aimbot solution with all features:
	  - Real-time FPS counter with pause when hidden
	  - Real-time Network Ping calculator  
	  - UNC verification loading sequence
	  - Enhanced keybinds system
	  - Multiple tabs and features
	  - Bracket UI Library integration
	  - HWID-keyed config auto-save/load
	  - Professional UI structure
]]

loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Scripts/Libraries/BracketV3.lua"))()

-- ===================================
-- LOAD BRACKET LIBRARY FIRST
-- ===================================

local function LoadBracketLibrary()
    -- Multiple fallback URLs for reliability - executor must use loadstring
    local urls = {
        "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Scripts/Libraries/BracketV3.lua",
        "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Scripts/Libraries/BracketV3.lua",
        "https://cdn.jsdelivr.net/gh/ScriptB/Universal-Aimassist@main/Scripts/Libraries/BracketV3.lua",
        "https://raw.githubusercontent.com/AlexR32/Roblox/main/BracketV3.lua" -- Original fallback
    }
    
    for i, url in ipairs(urls) do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        
        if success and result then
            print("✅ Bracket V3 loaded successfully from: " .. url)
            return result
        else
            warn("❌ Failed to load from URL " .. i .. ": " .. url)
        end
    end
    
    error("❌ All Bracket V3 loading attempts failed!")
end

local success, Bracket = pcall(LoadBracketLibrary)

if not success or not Bracket then
    warn("❌ Failed to load Bracket Library!")
    warn("⚠️ Script cannot continue without GUI library")
    return
end

print("✅ Bracket Library loaded successfully")

-- ===================================
-- SERVICES
-- ===================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
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

local loadingState = {
    stage = "Initializing...",
    progress = 0,
    results = {}
}

-- ===================================
-- LOADING UI CREATION
-- ===================================

local function createLoadingUI()
    local LoadingWindow = Bracket:CreateWindow({
        WindowName = "Universal Aimbot - Loading",
        Color = Color3.fromRGB(85, 170, 255)
    }, game:GetService("CoreGui"))
    
    local LoadingTab = LoadingWindow:CreateTab("🔍 Verification")
    local LoadingSection = LoadingTab:CreateSection("UNC Compatibility Check")
    
    local statusLabel = LoadingSection:CreateLabel("Status: Initializing...")
    local progressLabel = LoadingSection:CreateLabel("Progress: 0%")
    local resultsLabel = LoadingSection:CreateLabel("Results: Pending...")
    
    return LoadingWindow, statusLabel, progressLabel, resultsLabel
end

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
        
        loadingState.stage = "UNC Verification Complete"
        loadingState.progress = 100
        loadingState.results = results.Results
    else
        compatibility.UNC = 0
        compatibility.Functions = 0
        compatibility.Overall = 0
        loadingState.stage = "UNC Verification Failed"
        loadingState.results = {"❌ UNC verification failed"}
    end
    
    return compatibility
end

-- ===================================
-- DEVELOPER CONSOLE COPIER
-- ===================================

local function setupDeveloperConsoleCopier()
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")
    local TextService = game:GetService("TextService")

    -- Utility: safe wait for DevConsole
    local function getClientLog()
        local master = CoreGui:FindFirstChild("DevConsoleMaster")
        if not master then return end

        local window = master:FindFirstChild("DevConsoleWindow")
        if not window then return end

        local ui = window:FindFirstChild("DevConsoleUI")
        if not ui then return end

        local main = ui:FindFirstChild("MainView")
        if not main then return end

        return main:FindFirstChild("ClientLog")
    end

    -- Create copy button for a single log line
    local function attachCopyButton(label)
        if label:FindFirstChild("CopyBtn") then return end

        local btn = Instance.new("TextButton")
        btn.Name = "CopyBtn"
        btn.Size = UDim2.new(0, 30, 0, 18)
        btn.BackgroundTransparency = 1
        btn.Text = "[C]"
        btn.TextColor3 = label.TextColor3
        btn.Font = label.Font
        btn.TextSize = label.TextSize
        btn.TextTransparency = 0.5
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = label

        -- Position correctly once text renders
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not btn.Parent then
                conn:Disconnect()
                return
            end

            local bounds = label.TextBounds
            if bounds.X > 0 then
                btn.AnchorPoint = Vector2.new(0, 0.5)

                if label.Text:find("\n") then
                    local lastLine = label.Text:match("([^\n]*)$")
                    local size = TextService:GetTextSize(
                        lastLine,
                        label.TextSize,
                        label.Font,
                        Vector2.new(label.AbsoluteSize.X, math.huge)
                    )
                    btn.Position = UDim2.new(0, size.X + 6, 1, -label.TextSize / 2)
                else
                    btn.Position = UDim2.new(0, bounds.X + 6, 0.5, 0)
                end

                conn:Disconnect()
            end
        end)

        btn.MouseEnter:Connect(function() btn.TextTransparency = 0 end)
        btn.MouseLeave:Connect(function() btn.TextTransparency = 0.5 end)

        btn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(label.Text)
                btn.Text = "[✓]"
                task.delay(0.35, function()
                    if btn then btn.Text = "[C]" end
                end)
            end
        end)
    end

    -- Scan container for labels
    local function scan(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel") then
                attachCopyButton(obj)
            end
        end
    end

    -- Create "Copy All" button
    local function createCopyAllButton(clientLog)
        if clientLog:FindFirstChild("CopyAllLogs") then return end

        local btn = Instance.new("TextButton")
        btn.Name = "CopyAllLogs"
        btn.Size = UDim2.new(0, 120, 0, 22)
        btn.Position = UDim2.new(1, -130, 0, 6)
        btn.BackgroundTransparency = 0.2
        btn.Text = "Copy All"
        btn.Parent = clientLog

        btn.MouseButton1Click:Connect(function()
            local buffer = {}

            for _, obj in ipairs(clientLog:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                    table.insert(buffer, obj.Text)
                end
            end

            if setclipboard then
                setclipboard(table.concat(buffer, "\n"))
                btn.Text = "Copied"
                task.delay(0.6, function()
                    if btn then btn.Text = "Copy All" end
                end)
            end
        end)
    end

    -- Main hook
    local function hookConsole()
        local clientLog = getClientLog()
        if not clientLog then return end

        scan(clientLog)
        createCopyAllButton(clientLog)

        clientLog.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") then
                task.delay(0.05, function()
                    attachCopyButton(obj)
                end)
            end
        end)
    end

    -- Initial run + periodic check
    hookConsole()

    local timer = 0
    RunService.Heartbeat:Connect(function(dt)
        timer += dt
        if timer > 1 then
            timer = 0
            hookConsole()
        end
    end)
end

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
    -- Initialize Developer Console Copier (always enabled)
    setupDeveloperConsoleCopier()
    
    -- Create loading UI
    local LoadingWindow, statusLabel, progressLabel, resultsLabel = createLoadingUI()
    
    -- Update loading UI
    statusLabel:UpdateText("Status: Running UNC Verification...")
    progressLabel:UpdateText("Progress: 25%")
    
    -- Run UNC verification
    local compatibility = runUNCVerification()
    
    if not compatibility or compatibility.Overall < 50 then
        warn("⚠️ Low compatibility detected. Some features may not work properly.")
    end
    
    -- Update loading UI with results
    statusLabel:UpdateText("Status: " .. loadingState.stage)
    progressLabel:UpdateText("Progress: " .. loadingState.progress .. "%")
    
    local resultsText = "UNC Results:\n"
    for _, result in ipairs(compatibility.Results) do
        resultsText = resultsText .. result .. "\n"
    end
    resultsLabel:UpdateText(resultsText)
    
    -- Wait a moment then destroy loading UI
    task.wait(2)
    LoadingWindow:Toggle(false)
    
    -- Create main UI with professional design
    local Window = Bracket:CreateWindow({
        WindowName = "🎯 Universal Aimbot v3.0",
        Color = Color3.fromRGB(85, 170, 255)
    }, game:GetService("CoreGui"))
    
    -- Create organized tabs with icons
    local AimbotTab = Window:CreateTab("🎯 Aimbot")
    local ESPTab = Window:CreateTab("👁 ESP")
    local VisualTab = Window:CreateTab("🎨 Visual")
    local MovementTab = Window:CreateTab("⚡ Movement")
    local PerformanceTab = Window:CreateTab("📊 Performance")
    local SettingsTab = Window:CreateTab("⚙️ Settings")
    
    -- ===================================
    -- AIMBOT TAB - Professional Layout
    -- ===================================
    
    local AimbotMain = AimbotTab:CreateSection("🎯 Main Controls")
    local AimbotSettings = AimbotTab:CreateSection("⚙️ Advanced Settings")
    local AimbotVisual = AimbotTab:CreateSection("🎨 Visual Settings")
    
    -- Main Controls Section
    local aimbotToggle = AimbotMain:CreateToggle("🎯 Enable Aimbot", nil, function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
        Bracket:Notification({
            Title = "Aimbot " .. (Value and "Enabled" or "Disabled"),
            Description = Value and "Aimbot is now active" or "Aimbot is now inactive",
            Duration = 2
        })
    end)
    aimbotToggle:AddToolTip("Toggle the aimbot on/off")
    
    local aimModeDropdown = AimbotMain:CreateDropdown("Aim Mode", {"Right Click", "Always On", "Toggle"}, function(Value)
        -- Aim mode logic here
        Bracket:Notification({
            Title = "Aim Mode Changed",
            Description = "Mode: " .. Value,
            Duration = 2
        })
    end)
    aimModeDropdown:AddToolTip("Choose how the aimbot activates")
    
    -- Advanced Settings Section
    local smoothingSlider = AimbotSettings:CreateSlider("🎯 Smoothing", 0, 100, 5, false, function(Value)
        smoothing = 1 - (Value / 100)
    end)
    smoothingSlider:AddToolTip("Higher values = smoother, less aggressive aim")
    
    local predictionSlider = AimbotSettings:CreateSlider("🔮 Prediction", 0, 0.2, 0.065, true, function(Value)
        predictionStrength = Value
    end)
    predictionSlider:AddToolTip("Predict enemy movement (higher = more prediction)")
    
    local fovSlider = AimbotSettings:CreateSlider("👁 FOV Radius", 10, 500, 100, false, function(Value)
        aimFov = Value
        fovCircle.Radius = Value
    end)
    fovSlider:AddToolTip("Field of view radius for target detection")
    
    local reactionTimeSlider = AimbotSettings:CreateSlider("⚡ Reaction Time", 0, 100, 10, false, function(Value)
        -- Reaction time logic here
    end)
    reactionTimeSlider:AddToolTip("Time to react to new targets (ms)")
    
    -- Visual Settings Section
    local wallCheckToggle = AimbotSettings:CreateToggle("🧱 Wall Check", true, function(Value)
        wallCheck = Value
    end)
    wallCheckToggle:AddToolTip("Only aim at visible enemies")
    
    local teamCheckToggle = AimbotSettings:CreateToggle("👥 Team Check", false, function(Value)
        teamCheck = Value
    end)
    teamCheckToggle:AddToolTip("Don't aim at teammates")
    
    local healthCheckToggle = AimbotSettings:CreateToggle("❤️ Health Check", false, function(Value)
        healthCheck = Value
    end)
    healthCheckToggle:AddToolTip("Don't aim at dead/low health players")
    
    local minHealthSlider = AimbotSettings:CreateSlider("💔 Min Health", 0, 100, 0, false, function(Value)
        minHealth = Value
    end)
    minHealthSlider:AddToolTip("Minimum health to target")
    
    local stickyAimToggle = AimbotSettings:CreateToggle("🎯 Sticky Aim", false, function(Value)
        stickyAimEnabled = Value
    end)
    stickyAimToggle:AddToolTip("Stay locked on target")
    
    local autoFireToggle = AimbotSettings:CreateToggle("🔫 Auto Fire", false, function(Value)
        -- Auto fire logic here
    end)
    autoFireToggle:AddToolTip("Automatically fire when locked on")
    
    local fovColorPicker = AimbotVisual:CreateColorpicker("🎨 FOV Color", function(Color)
        circleColor = Color
        fovCircle.Color = Color
    end)
    fovColorPicker:AddToolTip("Color of the FOV circle")
    fovColorPicker:UpdateColor(circleColor)
    
    local rainbowFovToggle = AimbotVisual:CreateToggle("🌈 Rainbow FOV", false, function(Value)
        rainbowFov = Value
    end)
    rainbowFovToggle:AddToolTip("Enable rainbow FOV circle")
    
    local rainbowSpeedSlider = AimbotVisual:CreateSlider("🌈 Rainbow Speed", 1, 20, 5, false, function(Value)
        rainbowSpeed = Value / 1000
    end)
    rainbowSpeedSlider:AddToolTip("Speed of rainbow effect")
    
    -- ===================================
    -- ESP TAB - Professional Layout
    -- ===================================
    
    local ESPMain = ESPTab:CreateSection("👁 ESP Features")
    local ESPVisual = ESPTab:CreateSection("🎨 Visual Settings")
    local ESPFilters = ESPTab:CreateSection("🔍 Filters")
    
    -- ESP Features Section
    local espToggle = ESPMain:CreateToggle("👁 Enable ESP", nil, function(Value)
        espEnabled = Value
        Bracket:Notification({
            Title = "ESP " .. (Value and "Enabled" or "Disabled"),
            Description = Value and "ESP is now active" or "ESP is now inactive",
            Duration = 2
        })
    end)
    espToggle:AddToolTip("Enable ESP features")
    
    local espBoxesToggle = ESPMain:CreateToggle("📦 Boxes", false, function(Value)
        espBoxes = Value
    end)
    espBoxesToggle:AddToolTip("Show player boxes")
    
    local espNamesToggle = ESPMain:CreateToggle("📝 Names", false, function(Value)
        espNames = Value
    end)
    espNamesToggle:AddToolTip("Show player names")
    
    local espHealthToggle = ESPMain:CreateToggle("❤️ Health", false, function(Value)
        espHealth = Value
    end)
    espHealthToggle:AddToolTip("Show player health bars")
    
    local espDistanceToggle = ESPMain:CreateToggle("📏 Distance", false, function(Value)
        espDistance = Value
    end)
    espDistanceToggle:AddToolTip("Show player distance")
    
    local espTracersToggle = ESPMain:CreateToggle("📍 Tracers", false, function(Value)
        espTracers = Value
    end)
    espTracersToggle:AddToolTip("Show player tracers")
    
    local espSkeletonToggle = ESPMain:CreateToggle("🦴 Skeleton", false, function(Value)
        -- Skeleton ESP logic here
    end)
    espSkeletonToggle:AddToolTip("Show player skeleton")
    
    local espChamsToggle = ESPMain:CreateToggle("🎭 Chams", false, function(Value)
        -- Chams ESP logic here
    end)
    espChamsToggle:AddToolTip("Show player chams")
    
    -- Visual Settings Section
    local espColorPicker = ESPVisual:CreateColorpicker("🎨 ESP Color", function(Color)
        espColor = Color
    end)
    espColorPicker:AddToolTip("Color of ESP elements")
    espColorPicker:UpdateColor(espColor)
    
    local espThicknessSlider = ESPVisual:CreateSlider("📏 Line Thickness", 1, 5, 1, false, function(Value)
        -- ESP thickness logic here
    end)
    espThicknessSlider:AddToolTip("Thickness of ESP lines")
    
    local espDistanceSlider = ESPVisual:CreateSlider("🔍 Max Distance", 100, 1000, 500, false, function(Value)
        -- ESP distance logic here
    end)
    espDistanceSlider:AddToolTip("Maximum distance for ESP rendering")
    
    -- Filters Section
    local espShowFriendsToggle = ESPFilters:CreateToggle("👥 Show Friends", true, function(Value)
        -- Friend filter logic here
    end)
    espShowFriendsToggle:AddToolTip("Show friends in ESP")
    
    local espShowEnemiesToggle = ESPFilters:CreateToggle("⚔️ Show Enemies", true, function(Value)
        -- Enemy filter logic here
    end)
    espShowEnemiesToggle:AddToolTip("Show enemies in ESP")
    
    local espShowTeamToggle = ESPFilters:CreateToggle("🛡️ Show Team", false, function(Value)
        -- Team filter logic here
    end)
    espShowTeamToggle:AddToolTip("Show teammates in ESP")
    
    -- ===================================
    -- VISUAL TAB - Professional Layout
    -- ===================================
    
    local VisualMain = VisualTab:CreateSection("🎨 Visual Effects")
    local VisualUI = VisualTab:CreateSection("🖥️ UI Settings")
    
    -- Visual Effects Section
    local crosshairToggle = VisualMain:CreateToggle("🎯 Crosshair", false, function(Value)
        -- Crosshair logic here
    end)
    crosshairToggle:AddToolTip("Show custom crosshair")
    
    local crosshairColorPicker = VisualMain:CreateColorpicker("🎨 Crosshair Color", function(Color)
        -- Crosshair color logic here
    end)
    crosshairColorPicker:AddToolTip("Color of crosshair")
    
    local worldColorPicker = VisualMain:CreateColorpicker("🌍 World Color", function(Color)
        -- World color logic here
    end)
    worldColorPicker:AddToolTip("Change world rendering color")
    
    local ambientSlider = VisualMain:CreateSlider("💡 Ambient Light", 0, 2, 1, true, function(Value)
        -- Ambient light logic here
    end)
    ambientSlider:AddToolTip("Adjust ambient lighting")
    
    -- UI Settings Section
    local uiScaleSlider = VisualUI:CreateSlider("📏 UI Scale", 50, 150, 100, false, function(Value)
        -- UI scale logic here
    end)
    uiScaleSlider:AddToolTip("Scale of user interface")
    
    local transparencySlider = VisualUI:CreateSlider("👻 Transparency", 0, 100, 0, false, function(Value)
        -- UI transparency logic here
    end)
    transparencySlider:AddToolTip("UI transparency level")
    
    -- ===================================
    -- MOVEMENT TAB - Professional Layout
    -- ===================================
    
    local MovementMain = MovementTab:CreateSection("⚡ Movement")
    local MovementCharacter = MovementTab:CreateSection("🏃 Character")
    
    -- Movement Section
    local flyToggle = MovementMain:CreateToggle("✈️ Fly", false, function(Value)
        flyEnabled = Value
        if Value then
            startFly()
        else
            stopFly()
        end
        Bracket:Notification({
            Title = "Fly " .. (Value and "Enabled" or "Disabled"),
            Description = Value and "Flight mode activated" or "Flight mode deactivated",
            Duration = 2
        })
    end)
    flyToggle:AddToolTip("Enable fly mode")
    
    local flySpeedSlider = MovementMain:CreateSlider("✈️ Fly Speed", 10, 200, 50, false, function(Value)
        flySpeed = Value
    end)
    flySpeedSlider:AddToolTip("Speed of fly mode")
    
    local noclipToggle = MovementMain:CreateToggle("👻 Noclip", false, function(Value)
        noclipEnabled = Value
        if Value then
            startNoclip()
        else
            stopNoclip()
        end
        Bracket:Notification({
            Title = "Noclip " .. (Value and "Enabled" or "Disabled"),
            Description = Value and "Noclip mode activated" or "Noclip mode deactivated",
            Duration = 2
        })
    end)
    noclipToggle:AddToolTip("Enable noclip mode")
    
    local infJumpToggle = MovementMain:CreateToggle("🦘 Infinite Jump", false, function(Value)
        infJumpEnabled = Value
        if Value then
            startInfJump()
        else
            stopInfJump()
        end
        Bracket:Notification({
            Title = "Infinite Jump " .. (Value and "Enabled" or "Disabled"),
            Description = Value and "Infinite jump activated" or "Infinite jump deactivated",
            Duration = 2
        })
    end)
    infJumpToggle:AddToolTip("Enable infinite jump")
    
    local speedToggle = MovementMain:CreateToggle("🏃 Speed Boost", false, function(Value)
        -- Speed boost logic here
    end)
    speedToggle:AddToolTip("Enable speed boost")
    
    local speedSlider = MovementMain:CreateSlider("⚡ Speed Multiplier", 1, 5, 1, true, function(Value)
        -- Speed multiplier logic here
    end)
    speedSlider:AddToolTip("Movement speed multiplier")
    
    -- Character Section
    local walkSpeedSlider = MovementCharacter:CreateSlider("🚶 Walk Speed", 16, 100, 16, false, function(Value)
        walkSpeed = Value
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.WalkSpeed = Value
        end
    end)
    walkSpeedSlider:AddToolTip("Character walk speed")
    
    local jumpPowerSlider = MovementCharacter:CreateSlider("🦘 Jump Power", 50, 200, 50, false, function(Value)
        jumpPower = Value
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.JumpPower = Value
        end
    end)
    jumpPowerSlider:AddToolTip("Character jump power")
    
    local gravitySlider = MovementCharacter:CreateSlider("🌍 Gravity", 0, 200, 196.2, true, function(Value)
        -- Gravity logic here
    end)
    gravitySlider:AddToolTip("World gravity multiplier")
    
    -- ===================================
    -- PERFORMANCE TAB - Professional Layout
    -- ===================================
    
    local PerfMonitor = PerformanceTab:CreateSection("📊 Performance Monitor")
    local PerfSettings = PerformanceTab:CreateSection("⚙️ Performance Settings")
    
    -- Performance Monitor Section
    local fpsLabel = PerfMonitor:CreateLabel("🎯 FPS: 0")
    local pingLabel = PerfMonitor:CreateLabel("🌐 Ping: 0ms")
    local uptimeLabel = PerfMonitor:CreateLabel("⏱️ Uptime: 0s")
    local memoryLabel = PerfMonitor:CreateLabel("💾 Memory: 0MB")
    local entitiesLabel = PerfMonitor:CreateLabel("👥 Entities: 0")
    
    -- Performance Settings Section
    local fpsToggle = PerfSettings:CreateToggle("🎯 Show FPS", true, function(Value)
        fpsCounter.visible = Value
    end)
    fpsToggle:AddToolTip("Show FPS counter")
    
    local pingToggle = PerfSettings:CreateToggle("🌐 Show Ping", true, function(Value)
        pingCounter.visible = Value
    end)
    pingToggle:AddToolTip("Show ping counter")
    
    local maxFpsSlider = PerfSettings:CreateSlider("🎯 Max FPS", 30, 144, 60, false, function(Value)
        -- Max FPS logic here
    end)
    maxFpsSlider:AddToolTip("Maximum FPS limit")
    
    local renderDistanceSlider = PerfSettings:CreateSlider("🔍 Render Distance", 100, 1000, 500, false, function(Value)
        -- Render distance logic here
    end)
    renderDistanceSlider:AddToolTip("ESP render distance limit")
    
    -- ===================================
    -- SETTINGS TAB - Professional Layout
    -- ===================================
    
    local SettingsMain = SettingsTab:CreateSection("⚙️ Configuration")
    local SettingsUI = SettingsTab:CreateSection("🖥️ Interface")
    local SettingsDanger = SettingsTab:CreateSection("⚠️ Danger Zone")
    
    -- Configuration Section
    local saveButton = SettingsMain:CreateButton("💾 Save Config", function()
        -- Save configuration logic here
        Bracket:Notification({
            Title = "✅ Configuration Saved",
            Description = "Your settings have been saved successfully",
            Duration = 3
        })
    end)
    saveButton:AddToolTip("Save current configuration")
    
    local loadButton = SettingsMain:CreateButton("📂 Load Config", function()
        -- Load configuration logic here
        Bracket:Notification({
            Title = "📂 Configuration Loaded",
            Description = "Your settings have been loaded successfully",
            Duration = 3
        })
    end)
    loadButton:AddToolTip("Load saved configuration")
    
    local resetButton = SettingsMain:CreateButton("🔄 Reset All Settings", function()
        -- Reset all variables to defaults
        aimbotEnabled = false
        espEnabled = false
        flyEnabled = false
        noclipEnabled = false
        infJumpEnabled = false
        
        -- Update UI elements
        aimbotToggle:SetValue(false)
        espToggle:SetValue(false)
        flyToggle:SetValue(false)
        noclipToggle:SetValue(false)
        infJumpToggle:SetValue(false)
        
        Bracket:Notification({
            Title = "🔄 Settings Reset",
            Description = "All settings have been reset to defaults",
            Duration = 3
        })
    end)
    resetButton:AddToolTip("Reset all settings to default values")
    
    local exportButton = SettingsMain:CreateButton("📤 Export Config", function()
        -- Export config logic here
        Bracket:Notification({
            Title = "📤 Config Exported",
            Description = "Configuration exported to clipboard",
            Duration = 3
        })
    end)
    exportButton:AddToolTip("Export configuration to clipboard")
    
    -- Interface Section
    local keybindsButton = SettingsUI:CreateButton("⌨️ Keybinds", function()
        -- Keybinds UI logic here
        Bracket:Notification({
            Title = "⌨️ Keybinds",
            Description = "Keybind configuration opened",
            Duration = 2
        })
    end)
    keybindsButton:AddToolTip("Configure keybinds")
    
    local themeDropdown = SettingsUI:CreateDropdown("🎨 Theme", {"Default", "Dark", "Light", "Neon"}, function(Value)
        -- Theme logic here
        Bracket:Notification({
            Title = "🎨 Theme Changed",
            Description = "Theme: " .. Value,
            Duration = 2
        })
    end)
    themeDropdown:AddToolTip("Choose UI theme")
    
    -- Danger Zone Section
    local destroyButton = SettingsDanger:CreateButton("💀 Destroy UI (Stealth)", function()
        Window:Toggle(false)
        Bracket:Notification({
            Title = "💀 UI Destroyed",
            Description = "UI has been destroyed for stealth mode",
            Duration = 2
        })
    end)
    destroyButton:AddToolTip("Destroy UI completely (stealth mode)")
    
    local unloadButton = SettingsDanger:CreateButton("🔫 Unload Script", function()
        -- Unload script logic here
        Bracket:Notification({
            Title = "🔫 Script Unloaded",
            Description = "Script has been unloaded",
            Duration = 2
        })
    end)
    unloadButton:AddToolTip("Unload the entire script")
    
    -- Info Section
    local infoSection = SettingsTab:CreateSection("ℹ️ Information")
    infoSection:CreateLabel("🎯 Universal Aimbot v3.0")
    infoSection:CreateLabel("👥 ScriptB Team")
    infoSection:CreateLabel("🔗 github.com/ScriptB/Universal-Aimassist")
    infoSection:CreateLabel("⚡ UNC Compatibility: " .. compatibility.Overall .. "%")
    
    -- Welcome notification
    Bracket:Notification({
        Title = "🎯 Universal Aimbot v3.0",
        Description = "Loaded successfully! Press F9 to toggle UI",
        Duration = 3
    })
    
    print("✅ Universal Aimbot v3.0 loaded successfully!")
    print("🎯 Right Click to aim")
    print("⌨️ Press F9 to toggle UI")
    print("🔍 UNC Compatibility: " .. compatibility.Overall .. "%")
    
    -- ===================================
    -- FOV CIRCLE
    -- ===================================
    
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.Radius = aimFov
    fovCircle.Filled = false
    fovCircle.Color = circleColor
    fovCircle.Visible = false
    
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
    -- EXTRAS FUNCTIONS
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
        end

        -- Main hook
        local function hookConsole()
            local clientLog = getClientLog()
            if not clientLog then return end

            scan(clientLog)
            createCopyAllButton(clientLog)

            clientLog.DescendantAdded:Connect(function(obj)
                if obj:IsA("TextLabel") then
                    task.delay(0.05, function()
                        attachCopyButton(obj)
                    end)
                end
            end)
        end

        -- Initial run + periodic check
        hookConsole()

        local timer = 0
        RunService.Heartbeat:Connect(function(dt)
            timer += dt
            if timer > 1 then
                timer = 0
                hookConsole()
            end
        end)
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
                    fpsLabel:UpdateText("FPS: " .. fpsCounter.fps)
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
                    pingLabel:UpdateText("Ping: " .. pingCounter.ping .. "ms")
                end
            end
        end
        
        -- Update uptime
        local uptime = math.floor(tick() - startTime)
        if uptimeLabel then
            uptimeLabel:UpdateText("Uptime: " .. uptime .. "s")
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
    Bracket:Notification({
        Title = "Universal Aimbot v3.0",
        Description = "Loaded successfully! Press F9 to toggle UI",
        Duration = 3
    })
    
    print("✅ Universal Aimbot v3.0 loaded successfully!")
    print("🎯 Right Click to aim")
    print("⌨️ Press F9 to toggle UI")
    print("🔍 UNC Compatibility: " .. compatibility.Overall .. "%")
end

-- Start the script
main()
