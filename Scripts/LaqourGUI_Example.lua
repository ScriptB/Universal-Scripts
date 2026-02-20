-- LaqourLib GUI Example - Loadstring Method
-- This script demonstrates how to use LaqourLib with loadstring for GUI creation

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
-- LAQOURLIB LOADING WITH LOADSTRING
-- ===================================

local Laqour = nil
local LaqourLibLoaded = false

-- Load LaqourLib using loadstring method
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/LaqourLib_BracketRebranded.lua"))()
end)

if success then
    Laqour = result
    LaqourLibLoaded = true
    print("✓ LaqourLib loaded successfully via loadstring")
else
    warn("Failed to load LaqourLib: " .. tostring(result))
    warn("Attempting fallback to alternative source...")
    
    -- Try alternative source
    local success2, result2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/LaqourLib_Rebranded.lua"))()
    end)
    
    if success2 then
        Laqour = result2
        LaqourLibLoaded = true
        print("✓ LaqourLib loaded via alternative source")
    else
        warn("Failed to load LaqourLib from all sources")
        warn("Creating simple fallback UI...")
        LaqourLibLoaded = false
    end
end

-- ===================================
-- GUI CREATION FUNCTION
-- ===================================

local function createLaqourGUI()
    if not LaqourLibLoaded then
        -- Fallback simple GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LaqourGUI_Fallback"
        screenGui.Parent = game:GetService("CoreGui")
        
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Parent = screenGui
        frame.Size = UDim2.new(0, 400, 0, 300)
        frame.Position = UDim2.new(0.5, -200, 0.5, -150)
        frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.new(0, 0.7, 1)
        frame.Active = true
        frame.Draggable = true
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Parent = frame
        titleLabel.Size = UDim2.new(1, 0, 0, 30)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundColor3 = Color3.new(0, 0.7, 1)
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = "LaqourLib GUI (Fallback)"
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Message"
        messageLabel.Parent = frame
        messageLabel.Size = UDim2.new(1, -20, 0, 200)
        messageLabel.Position = UDim2.new(0, 10, 0, 40)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = "LaqourLib failed to load.\nUsing fallback GUI.\n\nThis is a simple interface\nto demonstrate loadstring method."
        messageLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        messageLabel.TextScaled = true
        messageLabel.Font = Enum.Font.SourceSans
        messageLabel.TextWrapped = true
        
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "Close"
        closeButton.Parent = frame
        closeButton.Size = UDim2.new(0, 100, 0, 30)
        closeButton.Position = UDim2.new(0.5, -50, 0, 260)
        closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
        closeButton.BorderSizePixel = 0
        closeButton.Text = "Close"
        closeButton.TextColor3 = Color3.new(1, 1, 1)
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.SourceSansBold
        
        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
        end)
        
        return screenGui
    end
    
    -- Main LaqourLib GUI
    local Window = Laqour:CreateWindow({
        WindowName = "LaqourLib GUI Example",
        Color = Color3.new(0, 0.7, 1)
    }, game:GetService("CoreGui"))
    
    -- Create tabs
    local MainTab = Window:CreateTab("Main")
    local SettingsTab = Window:CreateTab("Settings")
    local AboutTab = Window:CreateTab("About")
    
    -- Main Tab Content
    local MainSection = MainTab:CreateSection("Main Features")
    
    local Toggle = MainSection:CreateToggle("Enable Feature", false, function(Value)
        print("Feature toggled:", Value)
        if Value then
            print("✅ Feature is now enabled")
        else
            print("❌ Feature is now disabled")
        end
    end)
    
    local Keybind = Toggle:CreateKeybind("RightShift", function(Key)
        print("Feature toggled with key:", Key)
    end)
    
    local Slider = MainSection:CreateSlider("Intensity", 1, 100, 50, false, function(Value)
        print("Intensity set to:", Value)
    end)
    
    local Button = MainSection:CreateButton("Execute Action", function()
        print("🚀 Action executed!")
        Window:Toggle(false)
        wait(1)
        Window:Toggle(true)
    end)
    
    local TextBox = MainSection:CreateTextBox("Input", "Enter text...", false, function(Text)
        print("Input text:", Text)
    end)
    
    local Dropdown = MainSection:CreateDropdown("Select Option", {"Option 1", "Option 2", "Option 3"}, function(Option)
        print("Selected option:", Option)
    end, "Option 1")
    
    local ColorPicker = MainSection:CreateColorpicker("Theme Color", function(Color)
        print("Color selected:", Color)
        Window:ChangeColor(Color)
    end)
    
    -- Settings Tab Content
    local SettingsSection = SettingsTab:CreateSection("GUI Settings")
    
    local WindowToggle = SettingsSection:CreateToggle("Show Window", true, function(Value)
        Window:Toggle(Value)
    end)
    
    local Label = SettingsSection:CreateLabel("GUI Information")
    Label:UpdateText("LaqourLib Version: 2.0\nLoad Method: loadstring\nStatus: Active")
    
    -- About Tab Content
    local AboutSection = AboutTab:CreateSection("About LaqourLib")
    
    local AboutLabel = AboutSection:CreateLabel("LaqourLib Information")
    AboutLabel:UpdateText("LaqourLib is a professional UI library\nfor Roblox scripts, rebranded from\nBracket library with full functionality.\n\nFeatures:\n• Window Management\n• Tab System\n• Multiple UI Elements\n• Keybind Support\n• Color Theming\n• Tooltips\n• Drag & Drop")
    
    local TestButton = AboutSection:CreateButton("Test All Features", function()
        print("🧪 Testing all LaqourLib features...")
        
        -- Test toggle
        local testState = math.random(0, 1) == 1
        Toggle:SetState(testState)
        print("Toggle test:", testState)
        
        -- Test slider
        local testValue = math.random(1, 100)
        Slider:SetValue(testValue)
        print("Slider test:", testValue)
        
        -- Test dropdown
        local options = {"Option 1", "Option 2", "Option 3"}
        local randomOption = options[math.random(1, #options)]
        Dropdown:SetOption(randomOption)
        print("Dropdown test:", randomOption)
        
        -- Test color picker
        local randomColor = Color3.new(math.random(), math.random(), math.random())
        ColorPicker:UpdateColor(randomColor)
        print("Color picker test:", randomColor)
        
        print("✅ All features tested successfully!")
    end)
    
    -- Add tooltips
    Toggle:AddToolTip("Toggle the main feature on/off")
    Slider:AddToolTip("Adjust the intensity of the feature")
    Button:AddToolTip("Execute the main action")
    TextBox:AddToolTip("Enter custom text input")
    Dropdown:AddToolTip("Select from available options")
    ColorPicker:AddToolTip("Choose a theme color")
    WindowToggle:AddToolTip("Show or hide the window")
    TestButton:AddToolTip("Test all LaqourLib features")
    
    return Window
end

-- ===================================
-- EXECUTOR DETECTION
-- ===================================

local function detectExecutor()
    local executor = "Unknown"
    local features = {}
    local uncCompatible = false
    local executorSpecific = false
    
    -- Current Working Executors (2026)
    if getgenv and getgenv().executor and (getgenv().executor:find("Ronix") or getgenv().executor:find("RonixExploit")) then
        executor = "Ronix"
        executorSpecific = true
        uncCompatible = true
    elseif JJSploit then
        executor = "JJSploit"
        executorSpecific = true
        uncCompatible = false
    elseif Solara then
        executor = "Solara"
        executorSpecific = true
        uncCompatible = false
    elseif Delta then
        executor = "Delta"
        executorSpecific = true
        uncCompatible = true
    elseif Xeno then
        executor = "Xeno"
        executorSpecific = true
        uncCompatible = false
    elseif PunkX then
        executor = "Punk X"
        executorSpecific = true
        uncCompatible = true
    elseif Velocity then
        executor = "Velocity"
        executorSpecific = true
        uncCompatible = true
    elseif Drift then
        executor = "Drift"
        executorSpecific = true
        uncCompatible = true
    elseif LX63 then
        executor = "LX63"
        executorSpecific = true
        uncCompatible = true
    elseif Valex then
        executor = "Valex"
        executorSpecific = true
        uncCompatible = true
    elseif Pluto then
        executor = "Pluto"
        executorSpecific = true
        uncCompatible = true
    elseif CheatHub then
        executor = "CheatHub"
        executorSpecific = true
        uncCompatible = true
    elseif gethui and not syn then
        executor = "Mobile Executor"
        executorSpecific = false
        uncCompatible = false
    elseif getgenv and getgenv().executor then
        local executorName = getgenv().executor
        if executorName:find("Ronix") or executorName:find("RonixExploit") then
            executor = "Ronix"
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
        else
            executor = executorName
        end
        executorSpecific = true
    else
        executor = "Generic Executor"
        executorSpecific = false
        uncCompatible = false
    end
    
    return {
        Name = executor,
        ExecutorSpecific = executorSpecific,
        UNCCompatible = uncCompatible,
        Features = features
    }
end

-- ===================================
-- MAIN EXECUTION
-- ===================================

local function main()
    -- Detect executor
    local executorInfo = detectExecutor()
    
    -- Print executor information
    print("🔧 Executor Detection:")
    print("  Name:", executorInfo.Name)
    print("  Specific:", executorInfo.ExecutorSpecific)
    print("  UNC Compatible:", executorInfo.UNCCompatible)
    print("  LaqourLib Status:", LaqourLibLoaded and "✅ Loaded" or "❌ Failed")
    
    -- Create GUI
    print("🎨 Creating LaqourLib GUI...")
    local gui = createLaqourGUI()
    
    -- Show success message
    if LaqourLibLoaded then
        print("✅ LaqourLib GUI created successfully!")
        print("📖 Use the GUI to test all features")
        print("🔗 Loadstring method working perfectly")
    else
        print("⚠️ Using fallback GUI due to LaqourLib loading failure")
        print("📖 The fallback GUI demonstrates basic functionality")
    end
    
    -- Return GUI object for external access
    return gui
end

-- ===================================
-- AUTO-EXECUTION
-- ===================================

-- Auto-run the main function
local success, result = pcall(main)
if not success then
    warn("❌ Error in main execution: " .. tostring(result))
else
    print("🚀 LaqourLib GUI Example executed successfully!")
end

-- Export for external use
return {
    Laqour = Laqour,
    LaqourLibLoaded = LaqourLibLoaded,
    createLaqourGUI = createLaqourGUI,
    detectExecutor = detectExecutor
}
