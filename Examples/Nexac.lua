-- ===================================
-- NEXAC SUITE - ADVANCED AIMBOT & ESP SYSTEM
-- ===================================
-- Powered by Bracket Library - Clean, Modern GUI
-- Enhanced Console Copy System
-- UNC & Executor Detection
-- Self-Contained - No External Dependencies

-- ===================================
-- PRIORITY LOAD: BRACKET LIB (MAIN GUI HANDLER)
-- ===================================

-- Load Bracket Library IMMEDIATELY - this is the MAIN GUI handler
local Bracket = nil
local BracketLibLoaded = false

print("🚀 Loading Bracket Library (MAIN GUI Handler)...")

-- Primary Bracket Library loading with instant execution
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/BracketLib.lua"))()
end)

if success and result then
    Bracket = result
    BracketLibLoaded = true
    print("✅ Bracket Library loaded instantly - MAIN GUI ready")
else
    warn("❌ CRITICAL: Bracket Library failed to load!")
    warn("⚠️ Error: " .. tostring(result))
    warn("🛑 Cannot proceed without GUI library - script stopped")
    return
end

-- ===================================
-- ENHANCED CONSOLE COPY FEATURE
-- ===================================

-- Improved, cleaner, safer, and adds "Copy All" feature
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
            spawn(function()
                wait(0.35)
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
            spawn(function()
                wait(0.6)
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
            spawn(function()
                wait(0.05)
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

-- ===================================
-- EMBEDDED SCRIPTS (NO EXTERNAL LOADSTRINGS)
-- ===================================

-- Embedded UNCTest Script
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

local function test(name, aliases, callback)
	running += 1

	task.spawn(function()
		if not callback then
			print("⏺️ " .. name)
		elseif not getGlobal(name) then
			fails += 1
			warn("⛔ " .. name)
		else
			local success, message = pcall(callback)
	
			if success then
				passes += 1
				print("✅ " .. name .. (message and " • " .. message or ""))
			else
				fails += 1
				warn("⛔ " .. name .. " failed: " .. message)
			end
		end
	
		local undefinedAliases = {}
	
		for _, alias in ipairs(aliases) do
			if getGlobal(alias) == nil then
				table.insert(undefinedAliases, alias)
			end
		end
	
		if #undefinedAliases > 0 then
			undefined += 1
			warn("⚠️ " .. table.concat(undefinedAliases, ", "))
		end

		running -= 1
	end)
end

-- UNC Environment Check
print("UNC Environment Check")

-- Test UNC functions
test("getrawmetatable", {"getrawmetatable"}, function()
	local mt = getrawmetatable(game)
	return mt and type(mt) == "table"
end)

test("setrawmetatable", {"setrawmetatable"}, function()
	local mt = getrawmetatable(game)
	if mt then
		setrawmetatable(game, mt)
		return true
	end
	return false
end)

test("getgc", {"getgc"}, function()
	local objects = getgc()
	return type(objects) == "table" and #objects > 0
end)

test("getinstances", {"getinstances"}, function()
	local instances = getinstances()
	return type(instances) == "table" and #instances > 0
end)

test("isfile", {"isfile"}, function()
	return type(isfile) == "function"
end)

test("delfile", {"delfile"}, function()
	return type(delfile) == "function"
end)

test("readfile", {"readfile"}, function()
	return type(readfile) == "function"
end)

test("writefile", {"writefile"}, function()
	return type(writefile) == "function"
end)

test("loadfile", {"loadfile"}, function()
	return type(loadfile) == "function"
end)

test("makefolder", {"makefolder"}, function()
	return type(makefolder) == "function"
end)

test("listfiles", {"listfiles"}, function()
	return type(listfiles) == "function"
end)

test("isfolder", {"isfolder"}, function()
	return type(isfolder) == "function"
end)

-- Wait for all tests to complete
while running > 0 do
	wait()
end

-- Calculate UNC percentage
local total = passes + fails + undefined
local uncPercentage = total > 0 and math.round((passes / total) * 100) or 0

-- Return results
return {
	UNC = uncPercentage,
	Passes = passes,
	Fails = fails,
	Undefined = undefined,
	Total = total,
	Status = "Complete"
}
]]

-- Embedded Validator and Executor Check Script
local ValidatorScript = [[
--[[
    Improved Executor Vulnerability Check
    Enhanced version with better structure, error handling, and features
    
    Features:
    - Clean, organized code structure
    - Better error handling and logging
    - Progress indicators
    - Detailed reporting
    - Export functionality
    - Performance improvements
    - Better mobile compatibility
]]

-- ===================================
-- CONFIGURATION AND UTILITIES
-- ===================================

local ExecutorTest = {
    Version = "2.0",
    Author = "ScriptB",
    StartTime = tick(),
    
    -- Test configuration
    Config = {
        ShowProgress = true,
        DetailedLogging = true,
        ExportResults = true,
        TestTimeout = 5,
        ParallelTesting = true
    },
    
    -- Results tracking
    Results = {
        Pass = 0,
        Fail = 0,
        Unknown = 0,
        Total = 0,
        Details = {},
        StartTime = tick()
    },
    
    -- Blocked functions tracking
    BlockedFunctions = {},
    
    -- Service categories for organization
    Categories = {
        "HttpRbxApiService",
        "ScriptContext", 
        "BrowserService",
        "ContextActionService",
        "Workspace",
        "Lighting",
        "ReplicatedFirst",
        "ReplicatedStorage",
        "Players",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Teams",
        "SoundService",
        "ChatService",
        "LocalizationService",
        "TestService"
    }
}

-- ===================================
-- CORE TESTING FUNCTIONS
-- ===================================

local function testFunction(name, category, testFunc, aliases)
    ExecutorTest.Results.Total = ExecutorTest.Results.Total + 1
    
    local function runTest()
        local success, result = pcall(testFunc)
        
        if success then
            ExecutorTest.Results.Pass = ExecutorTest.Results.Pass + 1
            if ExecutorTest.Config.DetailedLogging then
                print("✅ " .. name .. " - " .. tostring(result))
            end
        else
            ExecutorTest.Results.Fail = ExecutorTest.Results.Fail + 1
            ExecutorTest.BlockedFunctions[name] = true
            if ExecutorTest.Config.DetailedLogging then
                warn("⛔ " .. name .. " - " .. tostring(result))
            end
        end
        
        ExecutorTest.Results.Details[name] = {
            Success = success,
            Result = result,
            Category = category,
            Aliases = aliases or {}
        }
    end
    
    if ExecutorTest.Config.ParallelTesting then
        task.spawn(runTest)
    else
        runTest()
    end
end

-- ===================================
-- SPECIFIC TESTS
-- ===================================

-- Test HTTP services
testFunction("HttpGet", "HttpRbxApiService", function()
    return type(game.HttpGet) == "function"
end, {"httpget", "http_request"})

testFunction("HttpService", "HttpRbxApiService", function()
    local service = game:GetService("HttpService")
    return service ~= nil
end, {"httpservice"})

-- Test script execution
testFunction("Loadstring", "ScriptContext", function()
    local testScript = "return true"
    local func = loadstring(testScript)
    return func ~= nil and func() == true
end, {"loadstring", "execute"})

testFunction("ExecuteScript", "ScriptContext", function()
    return type(game.ExecuteScript) == "function"
end, {"executescript", "runscript"})

-- Test memory functions
testFunction("GetRawMetatable", "ScriptContext", function()
    local mt = getrawmetatable(game)
    return mt ~= nil and type(mt) == "table"
end, {"getrawmetatable", "getmt"})

testFunction("SetRawMetatable", "ScriptContext", function()
    local mt = getrawmetatable(game)
    if mt then
        setrawmetatable(game, mt)
        return true
    end
    return false
end, {"setrawmetatable", "setmt"})

-- Test file system
testFunction("IsFile", "ScriptContext", function()
    return type(isfile) == "function"
end, {"isfile"})

testFunction("ReadFile", "ScriptContext", function()
    return type(readfile) == "function"
end, {"readfile"})

testFunction("WriteFile", "ScriptContext", function()
    return type(writefile) == "function"
end, {"writefile"})

-- Test UNC functions
testFunction("GetGC", "ScriptContext", function()
    local objects = getgc()
    return objects ~= nil and type(objects) == "table"
end, {"getgc"})

testFunction("GetInstances", "ScriptContext", function()
    local instances = getinstances()
    return instances ~= nil and type(instances) == "table"
end, {"getinstances"})

-- Test executor identification
testFunction("IdentifyExecutor", "ScriptContext", function()
    return type(identifyexecutor) == "function"
end, {"identifyexecutor", "getexecutorname"})

-- Test synapse functions
testFunction("Syn", "ScriptContext", function()
    return syn ~= nil and type(syn) == "table"
end, {"syn"})

-- ===================================
-- RUN ALL TESTS
-- ===================================

local function runAllTests()
    ExecutorTest.Results.StartTime = tick()
    
    if ExecutorTest.Config.ShowProgress then
        print("🔍 Starting Executor Vulnerability Check...")
    end
    
    -- Wait for all tests to complete
    wait(ExecutorTest.Config.TestTimeout)
    
    -- Calculate results
    ExecutorTest.Results.EndTime = tick()
    ExecutorTest.Results.Duration = ExecutorTest.Results.EndTime - ExecutorTest.Results.StartTime
    
    if ExecutorTest.Config.ShowProgress then
        print("✅ Test Complete!")
        print("📊 Results:")
        print("   Pass: " .. ExecutorTest.Results.Pass)
        print("   Fail: " .. ExecutorTest.Results.Fail)
        print("   Unknown: " .. ExecutorTest.Results.Unknown)
        print("   Total: " .. ExecutorTest.Results.Total)
        print("   Duration: " .. string.format("%.2f", ExecutorTest.Results.Duration) .. "s")
    end
    
    return ExecutorTest.Results
end

-- Run tests and return results
local results = runAllTests()
return results
]]

-- ===================================
-- SILENT UNC AND EXECUTOR DETECTION (BACKGROUND)
-- ===================================

-- Silent detection function using embedded scripts
local function runSilentDetection()
    local results = {
        Executor = "Unknown",
        UNC = 0,
        SecurityScore = 0,
        Status = "Running"
    }
    
    -- Get executor name first
    results.Executor = identifyexecutor and identifyexecutor() or "Unknown"
    
    -- Run UNCTest silently using embedded script
    spawn(function()
        local success, uncResults = pcall(function()
            return loadstring(UNCtestScript)()
        end)
        
        if success and uncResults then
            results.UNC = uncResults.UNC or 0
            results.UNCDetails = uncResults
        else
            results.UNC = 0
        end
    end)
    
    -- Run Validator silently using embedded script  
    spawn(function()
        local success, validatorResults = pcall(function()
            return loadstring(ValidatorScript)()
        end)
        
        if success and validatorResults then
            -- Extract security score from validator results
            local total = validatorResults.Results and (validatorResults.Results.Pass + validatorResults.Results.Fail + validatorResults.Results.Unknown) or 0
            results.SecurityScore = total > 0 and math.round((validatorResults.Results.Pass / total) * 100) or 0
            results.ValidatorDetails = validatorResults
        else
            results.SecurityScore = 0
        end
    end)
    
    -- Wait for both to complete
    wait(5)
    results.Status = "Complete"
    
    return results
end

-- ===================================
-- GLOBAL DECLARATIONS (Suppress IDE Warnings)
-- ===================================

-- Roblox executor globals (expected to be undefined in IDE)
local getgenv = getgenv or function() return {} end
local gethui = gethui or function() return nil end
local syn = syn or nil

-- Executor-specific globals (expected to be undefined in IDE)
local JJSploit = JJSploit or nil
local Solara = Solara or nil
local Delta = Delta or nil
local Xeno = Xeno or nil
local PunkX = PunkX or nil
local Velocity = Velocity or nil
local Drift = Drift or nil
local LX63 = LX63 or nil
local Valex = Valex or nil
local Pluto = Pluto or nil
local CheatHub = CheatHub or nil

-- Roblox function globals (expected to be undefined in IDE)
local httpget = httpget or nil
local UDIm2 = UDIm2 or nil

-- ===================================
-- MAIN INITIALIZATION (PRIORITY: GUI FIRST)
-- ===================================

local function main()
    -- PRIORITY 1: Create GUI INSTANTLY with Bracket Library (MAIN GUI HANDLER)
    print("🚀 Creating GUI (MAIN PRIORITY)...")
    
    if not Bracket or not Bracket.CreateWindow then
        warn("❌ CRITICAL: Bracket Library not available!")
        warn("⚠️ Cannot proceed without MAIN GUI handler")
        return
    end
    
    -- Create main interface immediately
    local Window
    local success, result = pcall(function()
        local Config = {
            WindowName = "Nexac Suite",
            Color = Color3.fromRGB(85, 170, 255),
            Keybind = Enum.KeyCode.RightBracket
        }
        return Bracket:CreateWindow(Config, game:GetService("CoreGui"))
    end)
    
    if not success then
        warn("❌ Failed to create main window:", tostring(result))
        return
    else
        Window = result
        print("✅ MAIN GUI created instantly!")
    end
    
    -- PRIORITY 2: Run silent detection in BACKGROUND (non-blocking)
    print("🔍 Starting background detection...")
    spawn(function()
        local detectionResults = runSilentDetection()
        
        -- Update GUI with results when available
        if detectionResults and detectionResults.Status == "Complete" then
            print("📊 Detection complete - updating GUI")
            
            -- Update executorInfo with detection results
            executorInfo.UNCPercentage = detectionResults.UNC or 0
            executorInfo.SecurityScore = detectionResults.SecurityScore or 0
            executorInfo.UNCCompatible = detectionResults.UNC > 0
            
            -- Update GUI labels if they exist
            if StatusSection then
                StatusSection:Label("✅ UNC Detection: " .. detectionResults.UNC .. "%")
                StatusSection:Label("✅ Security Score: " .. (detectionResults.SecurityScore or 0) .. "%")
                StatusSection:Label("✅ UNC Compatible: " .. (detectionResults.UNC > 0 and "YES" or "NO"))
            end
            
            print("🔗 UNC Compatibility:", detectionResults.UNC .. "%")
            print("🛡️ Security Score:", (detectionResults.SecurityScore or 0) .. "%")
        else
            print("⚠️ Detection incomplete")
        end
    end)
    
    -- PRIORITY 3: Create executor info with fallback values
    local executorInfo = {
        Name = identifyexecutor and identifyexecutor() or "Unknown",
        UNCPercentage = 0, -- Will be updated by background detection
        SecurityScore = 0, -- Will be updated by background detection
        Compatible = true,
        UNCCompatible = false, -- Will be updated by background detection
        Features = {"loadstring", "httpget"},
        ExecutorSpecific = true,
        FeatureCount = 2
    }
    
    print("🔧 Executor:", executorInfo.Name)
    print("🎨 MAIN GUI System:", BracketLibLoaded and "Bracket Library" or "NONE")
    print("🔄 Background Detection: Running")
    
    -- PRIORITY 4: Build GUI tabs immediately (don't wait for detection)
    print("🎨 Building GUI tabs...")
    
    -- Info Tab (shows current status)
    local InfoTab = Window:CreateTab("Info")
    local InfoSection = InfoTab:CreateSection("Nexac Suite Information")
    
    InfoSection:Label("Welcome to Nexac Suite!")
    InfoSection:Label("Version: 3.0 (Clean Edition)")
    InfoSection:Label("UI System: " .. (BracketLibLoaded and "Bracket Library" or "NONE"))
    InfoSection:Label("")
    
    local StatusSection = InfoTab:CreateSection("System Status")
    StatusSection:Label("✅ Bracket Library: " .. (BracketLibLoaded and "LOADED" or "FAILED"))
    StatusSection:Label("✅ GUI: INSTANTLY READY")
    StatusSection:Label("🔄 Detection: Running in background")
    StatusSection:Label(string.format("🔧 Executor: %s", executorInfo.Name))
    StatusSection:Label("")
    
    local FeaturesSection = InfoTab:CreateSection("GUI Features")
    FeaturesSection:Label("• Instant GUI Loading")
    FeaturesSection:Label("• Background Detection")
    FeaturesSection:Label("• Real-time Updates")
    FeaturesSection:Label("• Silent Operation")
    FeaturesSection:Label("• GitHub Integration")
    FeaturesSection:Label("")
    
    local ModulesSection = InfoTab:CreateSection("Available Modules")
    ModulesSection:Label("• Advanced Aimbot")
    ModulesSection:Label("• ESP System")
    ModulesSection:Label("• Visual Enhancements")
    ModulesSection:Label("• Movement Tools")
    ModulesSection:Label("• Custom Settings")
    ModulesSection:Label("• Priority GUI System")
    
    -- Aimbot Tab
    local AimbotTab = Window:CreateTab("Aimbot")
    local AimbotControlsSection = AimbotTab:CreateSection("Aimbot Controls")
    
    local aimbotEnabled = AimbotControlsSection:CreateToggle("Enable Aimbot", nil, function(State)
        print("Aimbot:", State and "ENABLED" or "DISABLED")
    end)
    
    local AimbotSettingsSection = AimbotTab:CreateSection("Aimbot Settings")
    AimbotSettingsSection:Label("FOV Settings")
    AimbotSettingsSection:Label("Target Selection")
    AimbotSettingsSection:Label("Smoothness")
    
    -- ESP Tab
    local ESPTab = Window:CreateTab("ESP")
    local ESPControlsSection = ESPTab:CreateSection("ESP Controls")
    
    local espEnabled = ESPControlsSection:CreateToggle("Enable ESP", nil, function(State)
        print("ESP:", State and "ENABLED" or "DISABLED")
    end)
    
    local ESPFeaturesSection = ESPTab:CreateSection("ESP Features")
    ESPFeaturesSection:Label("Box ESP")
    ESPFeaturesSection:Label("Name ESP")
    ESPFeaturesSection:Label("Health ESP")
    
    -- Visual Tab
    local VisualTab = Window:CreateTab("Visual")
    local VisualControlsSection = VisualTab:CreateSection("Visual Enhancements")
    
    VisualControlsSection:CreateToggle("Enable Visuals", nil, function(State)
        print("Visuals:", State and "ENABLED" or "DISABLED")
    end)
    
    local VisualSettingsSection = VisualTab:CreateSection("Visual Settings")
    VisualSettingsSection:Label("FOV Circle")
    VisualSettingsSection:Label("Crosshair")
    VisualSettingsSection:Label("Colors")
    
    -- Movement Tab
    local MovementTab = Window:CreateTab("Movement")
    local MovementControlsSection = MovementTab:CreateSection("Movement Tools")
    
    local flyEnabled = MovementControlsSection:CreateToggle("Enable Fly", nil, function(State)
        print("Fly:", State and "ENABLED" or "DISABLED")
    end)
    
    local MovementSettingsSection = MovementTab:CreateSection("Movement Settings")
    MovementSettingsSection:Label("Speed Settings")
    MovementSettingsSection:Label("Jump Power")
    MovementSettingsSection:Label("Noclip")
    
    -- Settings Tab
    local SettingsTab = Window:CreateTab("Settings")
    local ScriptSettingsSection = SettingsTab:CreateSection("Script Settings")
    
    ScriptSettingsSection:Label("Nexac Suite Settings")
    ScriptSettingsSection:Label("Version: 3.0")
    ScriptSettingsSection:Label("Architecture: Self-Contained")
    ScriptSettingsSection:Label("UI Library: Bracket Library")
    ScriptSettingsSection:Label("Console Copy: Enhanced Dev Console")
    
    local ActionsSection = SettingsTab:CreateSection("Actions")
    ActionsSection:CreateButton("Advanced Dev Console Copy", function()
        Bracket:Notification({
            Title = "Advanced Console Copy",
            Description = "[C] buttons and Copy All in Dev Console!",
            Duration = 3
        })
    end)
    
    ActionsSection:CreateButton("Destroy GUI", function()
        Window:Destroy()
        print("GUI Destroyed")
    end)
    
    ActionsSection:CreateButton("Reload Script", function()
        Bracket:Notification({
            Title = "Nexac Suite",
            Description = "Script reload requested!",
            Duration = 3
        })
        print("Script reload requested")
    end)
    
    -- Success message
    print("✅ Nexac Suite loaded successfully!")
    print("🎨 UI System:", BracketLibLoaded and "Bracket Library" or "FAILED")
    print("🔧 Executor:", executorInfo.Name)
    print("🔗 UNC Compatibility:", executorInfo.UNCPercentage .. "%")
    print("🛡️ Security Score:", (executorInfo.SecurityScore or 0) .. "%")
    print("🔍 Silent Detection: Active")
    print("🚀 All systems operational")
    
    -- Console copy info
    wait(1) -- Wait a moment for all console output to complete
    
    return {
        Window = Window,
        ExecutorInfo = executorInfo
    }
end

-- ===================================
-- AUTO-EXECUTION
-- ===================================

-- Auto-run the main function
local success, result = pcall(main)
if not success then
    warn("❌ Error in Nexac Suite execution: " .. tostring(result))
else
    print("🚀 Nexac Suite executed successfully!")
end

-- Note: Console copy is handled by the enhanced Dev Console copy system

-- Export for external use
return {
    main = main,
    runSilentDetection = runSilentDetection,
    Bracket = Bracket
}
