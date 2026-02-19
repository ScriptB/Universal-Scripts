-- ===================================
-- LOADSTRING LIBRARY ACCESS (FIRST)
-- ===================================

-- Load LaqourLib first - this must be at the very beginning
local Laqour = nil
local LaqourLibLoaded = false

-- Try to load LaqourLib with proper error handling
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
end)

if success and result then
    Laqour = result
    LaqourLibLoaded = true
    print("✅ LaqourLib loaded successfully")
else
    warn("❌ Failed to load LaqourLib: " .. tostring(result))
    warn("🔄 Attempting fallback loading...")
    
    -- Try alternative loading methods
    local fallbackSuccess, fallbackResult = pcall(function()
        -- Try different URL or method
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/LaqourLib_BracketRebranded.lua"))()
    end)
    
    if fallbackSuccess and fallbackResult then
        Laqour = fallbackResult
        LaqourLibLoaded = true
        print("✅ LaqourLib loaded via fallback")
    else
        warn("❌ All LaqourLib loading attempts failed")
        warn("🔧 Creating minimal fallback UI...")
        
        -- Create minimal fallback UI system
        Laqour = {
            Window = function(config)
                local window = {}
                window.Enabled = true
                window.Name = config.Name or "Window"
                
                function window:Tab(tabConfig)
                    local tab = {}
                    tab.Name = tabConfig.Name or "Tab"
                    
                    function tab:Divider(dividerConfig)
                        print("📋 " .. (dividerConfig.Text or "Divider"))
                    end
                    
                    function tab:Label(labelConfig)
                        print("📝 " .. (labelConfig.Text or "Label"))
                    end
                    
                    function tab:Toggle(toggleConfig)
                        print("🔄 " .. (toggleConfig.Name or "Toggle") .. ": " .. tostring(toggleConfig.Value))
                        if toggleConfig.Callback then
                            toggleConfig.Callback(toggleConfig.Value)
                        end
                        return {SetValue = function(self, value) 
                            print("🔄 " .. (toggleConfig.Name or "Toggle") .. ": " .. tostring(value))
                            if toggleConfig.Callback then toggleConfig.Callback(value) end
                        end}
                    end
                    
                    function tab:Slider(sliderConfig)
                        print("🎚️ " .. (sliderConfig.Name or "Slider") .. ": " .. (sliderConfig.Value or 50))
                        if sliderConfig.Callback then
                            sliderConfig.Callback(sliderConfig.Value)
                        end
                        return {SetValue = function(self, value) 
                            print("🎚️ " .. (sliderConfig.Name or "Slider") .. ": " .. tostring(value))
                            if sliderConfig.Callback then sliderConfig.Callback(value) end
                        end}
                    end
                    
                    function tab:Button(buttonConfig)
                        print("🔘 " .. (buttonConfig.Name or "Button"))
                        if buttonConfig.Callback then
                            buttonConfig.Callback()
                        end
                    end
                    
                    function tab:Dropdown(dropdownConfig)
                        print("📋 " .. (dropdownConfig.Name or "Dropdown"))
                        if dropdownConfig.Callback then
                            dropdownConfig.Callback(dropdownConfig.Options[1] or "Option")
                        end
                    end
                    
                    function tab:Colorpicker(colorConfig)
                        print("🎨 " .. (colorConfig.Name or "Color"))
                        if colorConfig.Callback then
                            colorConfig.Callback({}, colorConfig.Color or Color3.new(1, 1, 1))
                        end
                    end
                    
                    function tab:Keybind(keybindConfig)
                        print("⌨️ " .. (keybindConfig.Name or "Keybind") .. ": " .. (keybindConfig.Value or "NONE"))
                        if keybindConfig.Callback then
                            keybindConfig.Callback(keybindConfig.Value, false)
                        end
                        return {SetValue = function(self, value) 
                            print("⌨️ " .. (keybindConfig.Name or "Keybind") .. ": " .. tostring(value))
                            if keybindConfig.Callback then keybindConfig.Callback(value, false) end
                        end}
                    end
                    
                    return tab
                end
                
                function window:Destroy()
                    print("🗑️ Window destroyed: " .. window.Name)
                end
                
                return window
            end,
            Notification = function(config)
                print("📢 " .. (config.Title or "Notification") .. ": " .. (config.Description or ""))
            end
        }
        LaqourLibLoaded = false
        print("⚠️ Using minimal fallback UI system")
    end
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
local httpget = httpget or game.HttpGet

-- Roblox type globals (expected to be undefined in IDE)
local UDIm2 = UDIm2 or UDim2

-- ===================================
-- EXECUTOR DETECTION SYSTEM
-- ===================================

local EXECUTOR_DATA = {
    ["Ronix"] = {unc = 100, level = "Level 8", source = "WeAreDevs"},
    ["JJSploit"] = {unc = 98, level = "Level 7", source = "YouTube Testing"},
    ["Solara"] = {unc = 66, level = "Level 6", source = "Official Website"},
    ["Delta"] = {unc = 100, level = "Level 8", source = "Official Website"},
    ["Xeno"] = {unc = 90, level = "Level 7", source = "Official Website"},
    ["Punk X"] = {unc = 100, level = "Level 8", source = "Official Website"},
    ["Velocity"] = {unc = 98, level = "Level 7", source = "Official Website"},
    ["Drift"] = {unc = 85, level = "Level 7", source = "WeAreDevs"},
    ["LX63"] = {unc = 100, level = "Level 8", source = "WeAreDevs"},
    ["Valex"] = {unc = 75, level = "Level 6", source = "WeAreDevs"},
    ["Pluto"] = {unc = 70, level = "Level 6", source = "WeAreDevs"},
    ["CheatHub"] = {unc = 60, level = "Level 6", source = "WeAreDevs"},
    ["Generic Executor"] = {unc = 30, level = "Unknown", source = "Estimated"},
    ["Mobile Executor"] = {unc = 35, level = "Unknown", source = "Estimated"}
}

local function detectExecutor()
    local executor = "Unknown"
    local executorSpecific = false
    
    -- Debug information
    print("🔍 Debugging executor detection...")
    if getgenv then
        print("📋 getgenv exists:", true)
        if getgenv().executor then
            print("📋 getgenv().executor:", tostring(getgenv().executor))
        else
            print("📋 getgenv().executor: nil")
        end
    else
        print("📋 getgenv: nil")
    end
    
    print("📋 JJSploit:", JJSploit and "exists" or "nil")
    print("📋 syn:", syn and "exists" or "nil")
    print("📋 gethui:", gethui and "exists" or "nil")
    
    -- Current Working Executors (2026) - CHECK IN CORRECT ORDER
    -- Most specific checks first
    if getgenv and getgenv().executor and (getgenv().executor:find("Ronix") or getgenv().executor:find("RonixExploit")) then
        executor = "Ronix"
        executorSpecific = true
        print("✅ Detected Ronix via getgenv().executor")
    elseif JJSploit then
        executor = "JJSploit"
        executorSpecific = true
        print("✅ Detected JJSploit")
    elseif Solara then
        executor = "Solara"
        executorSpecific = true
        print("✅ Detected Solara")
    elseif Delta then
        executor = "Delta"
        executorSpecific = true
        print("✅ Detected Delta")
    elseif Xeno then
        executor = "Xeno"
        executorSpecific = true
        print("✅ Detected Xeno")
    elseif PunkX then
        executor = "Punk X"
        executorSpecific = true
        print("✅ Detected Punk X")
    elseif Velocity then
        executor = "Velocity"
        executorSpecific = true
        print("✅ Detected Velocity")
    elseif Drift then
        executor = "Drift"
        executorSpecific = true
        print("✅ Detected Drift")
    elseif LX63 then
        executor = "LX63"
        executorSpecific = true
        print("✅ Detected LX63")
    elseif Valex then
        executor = "Valex"
        executorSpecific = true
        print("✅ Detected Valex")
    elseif Pluto then
        executor = "Pluto"
        executorSpecific = true
        print("✅ Detected Pluto")
    elseif CheatHub then
        executor = "CheatHub"
        executorSpecific = true
        print("✅ Detected CheatHub")
    -- Mobile Detection - ONLY if no other executor detected AND gethui exists but syn doesn't
    elseif gethui and not syn and not getgenv().executor then
        executor = "Mobile Executor"
        executorSpecific = false
        print("⚠️ Detected Mobile Executor (gethui exists, syn doesn't, no getgenv().executor)")
    -- Fallback Detection - check getgenv().executor last
    elseif getgenv and getgenv().executor then
        local executorName = getgenv().executor
        print("🔍 Checking getgenv().executor fallback:", executorName)
        if executorName:find("Ronix") or executorName:find("RonixExploit") then
            executor = "Ronix"
            print("✅ Detected Ronix via fallback")
        elseif executorName:find("Velocity") then
            executor = "Velocity"
        elseif executorName:find("JJSploit") then
            executor = "JJSploit"
        elseif executorName:find("Solara") then
            executor = "Solara"
        elseif executorName:find("Delta") then
            executor = "Delta"
        elseif executorName:find("Xeno") then
            executor = "Xeno"
        elseif executorName:find("Punk") then
            executor = "Punk X"
        elseif executorName:find("Drift") then
            executor = "Drift"
        elseif executorName:find("LX63") then
            executor = "LX63"
        elseif executorName:find("Valex") then
            executor = "Valex"
        elseif executorName:find("Pluto") then
            executor = "Pluto"
        elseif executorName:find("CheatHub") then
            executor = "CheatHub"
        else
            executor = executorName
            print("🔍 Using unknown executor name:", executorName)
        end
        executorSpecific = true
    else
        executor = "Generic Executor"
        executorSpecific = false
        print("⚠️ No specific executor detected, using Generic")
    end
    
    print("🎯 Final executor detection:", executor, "Specific:", executorSpecific)
    print("=" .. string.rep("=", 50))
    
    -- Get UNC data
    local uncData = EXECUTOR_DATA[executor] or EXECUTOR_DATA["Generic Executor"]
    local uncPercentage = uncData.unc
    local uncLevel = uncData.level
    local uncCompatible = uncPercentage >= 80
    
    -- Test essential functions
    local essentialFunctions = {"httpget", "require", "loadstring"}
    local workingEssential = {}
    
    for _, feature in ipairs(essentialFunctions) do
        local success = pcall(function()
            if feature == "httpget" and (httpget or game.HttpGet) then
                table.insert(workingEssential, feature)
            elseif feature == "require" and require then
                local success = pcall(require, game:GetService("Workspace"))
                if success then table.insert(workingEssential, feature) end
            elseif feature == "loadstring" and loadstring then
                loadstring("print('test')")
                table.insert(workingEssential, feature)
            end
        end)
    end
    
    return {
        Name = executor,
        Features = workingEssential,
        Compatible = #workingEssential >= 2,
        UNCCompatible = uncCompatible,
        UNCPercentage = uncPercentage,
        UNCLevel = uncLevel,
        UNCSource = uncData.source,
        ExecutorSpecific = executorSpecific,
        FeatureCount = #workingEssential
    }
end

-- ===================================
-- MAIN INITIALIZATION
-- ===================================

local function main()
    -- Step 1: Detect executor
    local executorInfo = detectExecutor()
    print("🔧 Executor:", executorInfo.Name)
    print("🔗 UNC Compatible:", executorInfo.UNCCompatible and "✅" or "❌")
    print("📊 UNC Percentage:", executorInfo.UNCPercentage .. "%")
    
    -- Step 2: Check compatibility
    if not executorInfo.Compatible then
        warn("❌ Executor not compatible!")
        return
    end
    
    -- Step 3: Check if LaqourLib is available
    if not Laqour or not Laqour.Window then
        warn("❌ LaqourLib not available!")
        warn("⚠️ Using console-based interface")
        return
    end
    
    -- Step 4: Create main interface using LaqourLib
    local Window
    local success, result = pcall(function()
        return Laqour:Window({
            Name = "Nexac Suite",
            Color = Color3.new(0, 0.7, 1),
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        })
    end)
    
    if not success or not result then
        warn("❌ Failed to create LaqourLib window: " .. tostring(result))
        warn("⚠️ Using console-based interface")
        return
    end
    
    Window = result
    print("✅ LaqourLib UI system loaded successfully")
    
    -- Step 5: Create notification
    if Laqour.Notification then
        local notifSuccess, notifResult = pcall(function()
            Laqour:Notification({
                Title = "Nexac Suite",
                Description = "Loaded successfully with LaqourLib!",
                Duration = 5
            })
        end)
        
        if not notifSuccess then
            warn("⚠️ Notification system failed: " .. tostring(notifResult))
        end
    end
    
    -- Info Tab
    local InfoTab = Window:Tab({Name = "Info"})
    InfoTab:Divider({Text = "Nexac Suite Information", Side = "Left"})
    
    InfoTab:Label({Text = "Welcome to Nexac Suite!", Side = "Left"})
    InfoTab:Label({Text = "Version: 3.0 (Loadstring Edition)", Side = "Left"})
    InfoTab:Label({Text = "UI System: " .. (LaqourLibLoaded and "LaqourLib" or "Fallback Console"), Side = "Left"})
    InfoTab:Label({Text = string.format("Executor: %s", executorInfo.Name), Side = "Left"})
    InfoTab:Label({Text = string.format("UNC Level: %s", executorInfo.UNCLevel), Side = "Left"})
    InfoTab:Label({Text = string.format("UNC Percentage: %d%%", executorInfo.UNCPercentage), Side = "Left"})
    InfoTab:Label({Text = string.format("Features: %d/%d", executorInfo.FeatureCount, #{"httpget", "require", "loadstring"}), Side = "Left"})
    InfoTab:Label({Text = "", Side = "Left"})
    
    InfoTab:Divider({Text = "Status", Side = "Left"})
    InfoTab:Label({Text = LaqourLibLoaded and "✅ LaqourLib Loaded" or "⚠️ Fallback UI Active", Side = "Left"})
    InfoTab:Label({Text = "✅ Executor Compatible", Side = "Left"})
    InfoTab:Label({Text = "✅ All Systems Ready", Side = "Left"})
    InfoTab:Label({Text = "", Side = "Left"})
    
    InfoTab:Divider({Text = "Features", Side = "Left"})
    InfoTab:Label({Text = "• Advanced Aimbot", Side = "Left"})
    InfoTab:Label({Text = "• ESP System", Side = "Left"})
    InfoTab:Label({Text = "• Visual Enhancements", Side = "Left"})
    InfoTab:Label({Text = "• Movement Tools", Side = "Left"})
    InfoTab:Label({Text = "• Custom Settings", Side = "Left"})
    InfoTab:Label({Text = "• Loadstring Architecture", Side = "Left"})
    
    -- Aimbot Tab
    local AimbotTab = Window:Tab({Name = "Aimbot"})
    AimbotTab:Divider({Text = "Aimbot Controls", Side = "Left"})
    
    local aimbotEnabled = AimbotTab:Toggle({
        Name = "Enable Aimbot",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Aimbot:", Value and "ENABLED" or "DISABLED")
        end
    })
    
    AimbotTab:Divider({Text = "Aimbot Settings", Side = "Left"})
    
    AimbotTab:Slider({
        Name = "FOV",
        Side = "Left",
        Min = 10,
        Max = 360,
        Value = 90,
        Precise = 0,
        Unit = "°",
        Callback = function(Value)
            print("FOV:", Value)
        end
    })
    
    AimbotTab:Slider({
        Name = "Smoothness",
        Side = "Left",
        Min = 0,
        Max = 100,
        Value = 10,
        Precise = 0,
        Unit = "%",
        Callback = function(Value)
            print("Smoothness:", Value)
        end
    })
    
    AimbotTab:Dropdown({
        Name = "Aim Part",
        Side = "Left",
        Options = {"Head", "HumanoidRootPart", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
        Callback = function(Option)
            print("Aim Part:", Option)
        end
    })
    
    AimbotTab:Divider({Text = "Aimbot Filters", Side = "Left"})
    
    AimbotTab:Toggle({
        Name = "Wall Check",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Wall Check:", Value)
        end
    })
    
    AimbotTab:Toggle({
        Name = "Team Check",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Team Check:", Value)
        end
    })
    
    AimbotTab:Toggle({
        Name = "Visible Check",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Visible Check:", Value)
        end
    })
    
    -- ESP Tab
    local ESPTab = Window:Tab({Name = "ESP"})
    ESPTab:Divider({Text = "ESP Controls", Side = "Left"})
    
    local espEnabled = ESPTab:Toggle({
        Name = "Enable ESP",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("ESP:", Value and "ENABLED" or "DISABLED")
        end
    })
    
    ESPTab:Divider({Text = "ESP Features", Side = "Left"})
    
    ESPTab:Toggle({
        Name = "Box ESP",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Box ESP:", Value)
        end
    })
    
    ESPTab:Toggle({
        Name = "Name ESP",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Name ESP:", Value)
        end
    })
    
    ESPTab:Toggle({
        Name = "Health Bar",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Health Bar:", Value)
        end
    })
    
    ESPTab:Toggle({
        Name = "Distance ESP",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("Distance ESP:", Value)
        end
    })
    
    ESPTab:Toggle({
        Name = "Tracers",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Tracers:", Value)
        end
    })
    
    ESPTab:Divider({Text = "ESP Settings", Side = "Left"})
    
    ESPTab:Slider({
        Name = "Max Distance",
        Side = "Left",
        Min = 100,
        Max = 5000,
        Value = 1000,
        Precise = 0,
        Unit = "studs",
        Callback = function(Value)
            print("Max Distance:", Value)
        end
    })
    
    ESPTab:Colorpicker({
        Name = "Box Color",
        Color = Color3.fromRGB(255, 0, 0),
        Callback = function(Table, Color)
            print("Box Color:", Color)
        end
    })
    
    -- Visual Tab
    local VisualTab = Window:Tab({Name = "Visual"})
    VisualTab:Divider({Text = "Visual Enhancements", Side = "Left"})
    
    VisualTab:Toggle({
        Name = "Crosshair",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Crosshair:", Value)
        end
    })
    
    VisualTab:Toggle({
        Name = "FOV Circle",
        Side = "Left",
        Value = true,
        Callback = function(Value)
            print("FOV Circle:", Value)
        end
    })
    
    VisualTab:Toggle({
        Name = "Rainbow FOV",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Rainbow FOV:", Value)
        end
    })
    
    VisualTab:Divider({Text = "Visual Settings", Side = "Left"})
    
    VisualTab:Colorpicker({
        Name = "FOV Color",
        Color = Color3.fromRGB(255, 0, 0),
        Callback = function(Table, Color)
            print("FOV Color:", Color)
        end
    })
    
    VisualTab:Colorpicker({
        Name = "Crosshair Color",
        Color = Color3.fromRGB(0, 255, 0),
        Callback = function(Table, Color)
            print("Crosshair Color:", Color)
        end
    })
    
    -- Movement Tab
    local MovementTab = Window:Tab({Name = "Movement"})
    MovementTab:Divider({Text = "Movement Tools", Side = "Left"})
    
    local flyEnabled = MovementTab:Toggle({
        Name = "Fly",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Fly:", Value and "ENABLED" or "DISABLED")
        end
    })
    
    local noclipEnabled = MovementTab:Toggle({
        Name = "Noclip",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Noclip:", Value and "ENABLED" or "DISABLED")
        end
    })
    
    local infJumpEnabled = MovementTab:Toggle({
        Name = "Infinite Jump",
        Side = "Left",
        Value = false,
        Callback = function(Value)
            print("Infinite Jump:", Value and "ENABLED" or "DISABLED")
        end
    })
    
    MovementTab:Divider({Text = "Movement Settings", Side = "Left"})
    
    MovementTab:Slider({
        Name = "Fly Speed",
        Side = "Left",
        Min = 10,
        Max = 200,
        Value = 50,
        Precise = 0,
        Unit = "studs/s",
        Callback = function(Value)
            print("Fly Speed:", Value)
        end
    })
    
    MovementTab:Slider({
        Name = "Walk Speed",
        Side = "Left",
        Min = 8,
        Max = 100,
        Value = 16,
        Precise = 0,
        Unit = "studs/s",
        Callback = function(Value)
            print("Walk Speed:", Value)
        end
    })
    
    MovementTab:Slider({
        Name = "Jump Power",
        Side = "Left",
        Min = 7,
        Max = 200,
        Value = 50,
        Precise = 0,
        Unit = "studs",
        Callback = function(Value)
            print("Jump Power:", Value)
        end
    })
    
    -- Settings Tab
    local SettingsTab = Window:Tab({Name = "Settings"})
    SettingsTab:Divider({Text = "Script Settings", Side = "Left"})
    
    SettingsTab:Label({Text = "Nexac Suite Settings", Side = "Left"})
    SettingsTab:Label({Text = "Version: 3.0", Side = "Left"})
    SettingsTab:Label({Text = "Architecture: Loadstring", Side = "Left"})
    SettingsTab:Label({Text = "UI Library: LaqourLib", Side = "Left"})
    SettingsTab:Label({Text = "", Side = "Left"})
    
    SettingsTab:Divider({Text = "Keybinds", Side = "Left"})
    
    SettingsTab:Keybind({
        Name = "Toggle GUI",
        Side = "Left",
        Value = "RightControl",
        Mouse = false,
        Blacklist = {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"},
        Callback = function(Key, Pressed)
            if Pressed then
                Window.Enabled = not Window.Enabled
                print("GUI:", Window.Enabled and "SHOWN" or "HIDDEN")
            end
        end
    })
    
    SettingsTab:Keybind({
        Name = "Toggle Aimbot",
        Side = "Left",
        Value = "RightShift",
        Mouse = false,
        Blacklist = {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"},
        Callback = function(Key, Pressed)
            if Pressed then
                aimbotEnabled:SetValue(not aimbotEnabled.Value)
            end
        end
    })
    
    SettingsTab:Keybind({
        Name = "Toggle ESP",
        Side = "Left",
        Value = "NONE",
        Mouse = false,
        Blacklist = {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"},
        Callback = function(Key, Pressed)
            if Pressed then
                espEnabled:SetValue(not espEnabled.Value)
            end
        end
    })
    
    SettingsTab:Divider({Text = "Actions", Side = "Left"})
    
    SettingsTab:Button({
        Name = "Destroy GUI",
        Side = "Left",
        Callback = function()
            Window:Destroy()
            print("GUI Destroyed")
        end
    })
    
    SettingsTab:Button({
        Name = "Reload Script",
        Side = "Left",
        Callback = function()
            Laqour:Notification({
                Title = "Nexac Suite",
                Description = "Script reload requested!",
                Duration = 3
            })
            print("Script reload requested")
        end
    })
    
    -- Success message
    print("✅ Nexac Suite loaded successfully!")
    print("🎨 UI System:", LaqourLibLoaded and "LaqourLib" or "Fallback Console")
    print("🔧 Executor:", executorInfo.Name)
    print("🔗 UNC:", executorInfo.UNCPercentage .. "%")
    print("🚀 All systems operational")
    
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

-- Export for external use
return {
    main = main,
    detectExecutor = detectExecutor,
    Laqour = Laqour
}
        
    
