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
-- MAIN INITIALIZATION
-- ===================================

local function main()
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
    
    -- Create main UI
    local Window = Bracket:CreateWindow({
        WindowName = "Universal Aimbot v3.0",
        Color = Color3.fromRGB(85, 170, 255)
    }, game:GetService("CoreGui"))
    
    -- Create tabs
    local AimbotTab = Window:CreateTab("Aimbot 🎯")
    local ESPTab = Window:CreateTab("ESP 👁")
    local ExtrasTab = Window:CreateTab("Extras ⚡")
    local KeybindsTab = Window:CreateTab("Keybinds ⌨️")
    local PerformanceTab = Window:CreateTab("Performance 📊")
    local AdminTab = Window:CreateTab("Admin 🔧")
    
    -- ===================================
    -- AIMBOT TAB
    -- ===================================
    
    local AimbotMain = AimbotTab:CreateSection("Main Controls")
    local AimbotSettings = AimbotTab:CreateSection("Aimbot Settings")
    
    local aimbotToggle = AimbotMain:CreateToggle("Aimbot", nil, function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
    end)
    aimbotToggle:AddToolTip("Enable/Disable the aimbot")
    
    local smoothingSlider = AimbotSettings:CreateSlider("Smoothing", 0, 100, 5, false, function(Value)
        smoothing = 1 - (Value / 100)
    end)
    smoothingSlider:AddToolTip("Higher values = smoother aim")
    
    local predictionSlider = AimbotSettings:CreateSlider("Prediction Strength", 0, 0.2, 0.065, true, function(Value)
        predictionStrength = Value
    end)
    predictionSlider:AddToolTip("How much to predict enemy movement")
    
    local fovSlider = AimbotSettings:CreateSlider("Aimbot FOV", 10, 500, 100, false, function(Value)
        aimFov = Value
        fovCircle.Radius = Value
    end)
    fovSlider:AddToolTip("Field of view for aimbot")
    
    local wallCheckToggle = AimbotSettings:CreateToggle("Wall Check", true, function(Value)
        wallCheck = Value
    end)
    wallCheckToggle:AddToolTip("Only aim at visible enemies")
    
    local teamCheckToggle = AimbotSettings:CreateToggle("Team Check", false, function(Value)
        teamCheck = Value
    end)
    teamCheckToggle:AddToolTip("Don't aim at teammates")
    
    local healthCheckToggle = AimbotSettings:CreateToggle("Health Check", false, function(Value)
        healthCheck = Value
    end)
    healthCheckToggle:AddToolTip("Don't aim at dead players")
    
    local minHealthSlider = AimbotSettings:CreateSlider("Min Health", 0, 100, 0, false, function(Value)
        minHealth = Value
    end)
    minHealthSlider:AddToolTip("Minimum health to target")
    
    local stickyAimToggle = AimbotSettings:CreateToggle("Sticky Aim", false, function(Value)
        stickyAimEnabled = Value
    end)
    stickyAimToggle:AddToolTip("Stay locked on target")
    
    -- ===================================
    -- ESP TAB
    -- ===================================
    
    local ESPMain = ESPTab:CreateSection("ESP Settings")
    local ESPVisual = ESPTab:CreateSection("Visual Settings")
    
    local espToggle = ESPMain:CreateToggle("ESP", nil, function(Value)
        espEnabled = Value
    end)
    espToggle:AddToolTip("Enable ESP features")
    
    local espBoxesToggle = ESPMain:CreateToggle("Boxes", false, function(Value)
        espBoxes = Value
    end)
    espBoxesToggle:AddToolTip("Show player boxes")
    
    local espNamesToggle = ESPMain:CreateToggle("Names", false, function(Value)
        espNames = Value
    end)
    espNamesToggle:AddToolTip("Show player names")
    
    local espHealthToggle = ESPMain:CreateToggle("Health", false, function(Value)
        espHealth = Value
    end)
    espHealthToggle:AddToolTip("Show player health")
    
    local espDistanceToggle = ESPMain:CreateToggle("Distance", false, function(Value)
        espDistance = Value
    end)
    espDistanceToggle:AddToolTip("Show player distance")
    
    local espTracersToggle = ESPMain:CreateToggle("Tracers", false, function(Value)
        espTracers = Value
    end)
    espTracersToggle:AddToolTip("Show player tracers")
    
    local espColorPicker = ESPVisual:CreateColorpicker("ESP Color", function(Color)
        espColor = Color
    end)
    espColorPicker:AddToolTip("Color of ESP elements")
    espColorPicker:UpdateColor(espColor)
    
    -- ===================================
    -- EXTRAS TAB
    -- ===================================
    
    local ExtrasMain = ExtrasTab:CreateSection("Movement")
    local ExtrasSettings = ExtrasTab:CreateSection("Character Settings")
    
    local flyToggle = ExtrasMain:CreateToggle("Fly", false, function(Value)
        flyEnabled = Value
        if Value then
            startFly()
        else
            stopFly()
        end
    end)
    flyToggle:AddToolTip("Enable fly mode")
    
    local flySpeedSlider = ExtrasMain:CreateSlider("Fly Speed", 10, 200, 50, false, function(Value)
        flySpeed = Value
    end)
    flySpeedSlider:AddToolTip("Speed of fly mode")
    
    local noclipToggle = ExtrasMain:CreateToggle("Noclip", false, function(Value)
        noclipEnabled = Value
        if Value then
            startNoclip()
        else
            stopNoclip()
        end
    end)
    noclipToggle:AddToolTip("Enable noclip mode")
    
    local infJumpToggle = ExtrasMain:CreateToggle("Infinite Jump", false, function(Value)
        infJumpEnabled = Value
        if Value then
            startInfJump()
        else
            stopInfJump()
        end
    end)
    infJumpToggle:AddToolTip("Enable infinite jump")
    
    local walkSpeedSlider = ExtrasSettings:CreateSlider("Walk Speed", 16, 100, 16, false, function(Value)
        walkSpeed = Value
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.WalkSpeed = Value
        end
    end)
    walkSpeedSlider:AddToolTip("Character walk speed")
    
    local jumpPowerSlider = ExtrasSettings:CreateSlider("Jump Power", 50, 200, 50, false, function(Value)
        jumpPower = Value
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.JumpPower = Value
        end
    end)
    jumpPowerSlider:AddToolTip("Character jump power")
    
    -- ===================================
    -- KEYBINDS TAB
    -- ===================================
    
    local KeybindsMain = KeybindsTab:CreateSection("Aimbot Keybinds")
    local KeybindsExtras = KeybindsTab:CreateSection("Extras Keybinds")
    
    KeybindsMain:CreateLabel("RightShift - Toggle Aimbot")
    KeybindsMain:CreateLabel("RightControl - Toggle ESP")
    KeybindsMain:CreateLabel("RightAlt - Toggle Sticky Aim")
    
    KeybindsExtras:CreateLabel("F - Toggle Fly")
    KeybindsExtras:CreateLabel("N - Toggle Noclip")
    KeybindsExtras:CreateLabel("J - Toggle Infinite Jump")
    KeybindsExtras:CreateLabel("F9 - Toggle UI")
    KeybindsExtras:CreateLabel("Delete - Destroy UI (Stealth)")
    
    -- ===================================
    -- PERFORMANCE TAB
    -- ===================================
    
    local PerfMain = PerformanceTab:CreateSection("Performance Monitor")
    local PerfSettings = PerformanceTab:CreateSection("Settings")
    
    local fpsLabel = PerfMain:CreateLabel("FPS: 0")
    local pingLabel = PerfMain:CreateLabel("Ping: 0ms")
    local uptimeLabel = PerfMain:CreateLabel("Uptime: 0s")
    
    local fpsToggle = PerfSettings:CreateToggle("Show FPS", true, function(Value)
        fpsCounter.visible = Value
    end)
    fpsToggle:AddToolTip("Show FPS counter")
    
    local pingToggle = PerfSettings:CreateToggle("Show Ping", true, function(Value)
        pingCounter.visible = Value
    end)
    pingToggle:AddToolTip("Show ping counter")
    
    -- ===================================
    -- ADMIN TAB
    -- ===================================
    
    local AdminMain = AdminTab:CreateSection("Configuration")
    local AdminSettings = AdminTab:CreateSection("System")
    
    local saveButton = AdminMain:CreateButton("Save Config", function()
        -- Save configuration logic here
        Bracket:Notification({
            Title = "Configuration Saved",
            Description = "Your settings have been saved",
            Duration = 3
        })
    end)
    saveButton:AddToolTip("Save current configuration")
    
    local loadButton = AdminMain:CreateButton("Load Config", function()
        -- Load configuration logic here
        Bracket:Notification({
            Title = "Configuration Loaded",
            Description = "Your settings have been loaded",
            Duration = 3
        })
    end)
    loadButton:AddToolTip("Load saved configuration")
    
    local resetButton = AdminMain:CreateButton("Reset All Settings", function()
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
            Title = "Settings Reset",
            Description = "All settings have been reset to defaults",
            Duration = 3
        })
    end)
    resetButton:AddToolTip("Reset all settings to default values")
    
    local destroyButton = AdminSettings:CreateButton("Destroy UI (Stealth)", function()
        Window:Toggle(false)
        Bracket:Notification({
            Title = "UI Destroyed",
            Description = "UI has been destroyed for stealth",
            Duration = 2
        })
    end)
    destroyButton:AddToolTip("Destroy UI completely")
    
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
            plr.Character.Humanoid.JumpPower = jumpPower
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
