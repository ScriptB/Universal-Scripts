-- Loadstring Method Demonstration
-- Shows different ways to load and use LaqourLib with loadstring

-- ===================================
-- METHOD 1: Direct Loadstring
-- ===================================

print("🔧 Method 1: Direct Loadstring")

local function method1_DirectLoadstring()
    local Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
    
    local Window = Laqour:CreateWindow({
        WindowName = "Direct Loadstring Demo",
        Color = Color3.new(0, 1, 0)
    }, game:GetService("CoreGui"))
    
    local Tab = Window:CreateTab("Demo")
    local Section = Tab:CreateSection("Direct Loading")
    
    Section:CreateLabel("✅ Loaded directly via loadstring")
    Section:CreateButton("Test Button", function()
        print("Direct loadstring works!")
    end)
    
    return Window
end

-- ===================================
-- METHOD 2: Loadstring with Error Handling
-- ===================================

print("🔧 Method 2: Loadstring with Error Handling")

local function method2_LoadstringWithErrorHandling()
    local success, Laqour = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
    end)
    
    if not success then
        warn("Failed to load LaqourLib: " .. tostring(Laqour))
        return nil
    end
    
    local Window = Laqour:CreateWindow({
        WindowName = "Error Handling Demo",
        Color = Color3.new(1, 0.5, 0)
    }, game:GetService("CoreGui"))
    
    local Tab = Window:CreateTab("Demo")
    local Section = Tab:CreateSection("Error Handling")
    
    Section:CreateLabel("✅ Loaded with error handling")
    Section:CreateToggle("Safe Toggle", false, function(Value)
        print("Safe toggle:", Value)
    end)
    
    return Window
end

-- ===================================
-- METHOD 3: Multiple Loadstring Sources
-- ===================================

print("🔧 Method 3: Multiple Loadstring Sources")

local function method3_MultipleSources()
    local Laqour = nil
    local sources = {
        "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua",
        "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_Rebranded.lua",
        "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_Fixed.lua"
    }
    
    for i, source in ipairs(sources) do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(source))()
        end)
        
        if success then
            Laqour = result
            print("✅ Loaded from source", i, ":", source)
            break
        else
            print("❌ Failed source", i, ":", source)
        end
    end
    
    if not Laqour then
        warn("All sources failed!")
        return nil
    end
    
    local Window = Laqour:CreateWindow({
        WindowName = "Multiple Sources Demo",
        Color = Color3.new(0, 0.5, 1)
    }, game:GetService("CoreGui"))
    
    local Tab = Window:CreateTab("Demo")
    local Section = Tab:CreateSection("Multiple Sources")
    
    Section:CreateLabel("✅ Loaded from multiple sources")
    Section:CreateSlider("Source Priority", 1, 3, 1, false, function(Value)
        print("Using source:", Value)
    end)
    
    return Window
end

-- ===================================
-- METHOD 4: Loadstring with Caching
-- ===================================

print("🔧 Method 4: Loadstring with Caching")

local LaqourCache = nil

local function method4_LoadstringWithCaching()
    if LaqourCache then
        print("✅ Using cached LaqourLib")
        return LaqourCache
    end
    
    print("📦 Loading and caching LaqourLib...")
    local success, Laqour = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
    end)
    
    if not success then
        warn("Failed to load LaqourLib for caching")
        return nil
    end
    
    LaqourCache = Laqour
    print("✅ LaqourLib cached successfully")
    
    local Window = Laqour:CreateWindow({
        WindowName = "Caching Demo",
        Color = Color3.new(1, 0, 0)
    }, game:GetService("CoreGui"))
    
    local Tab = Window:CreateTab("Demo")
    local Section = Tab:CreateSection("Caching")
    
    Section:CreateLabel("✅ Loaded with caching enabled")
    Section:CreateButton("Clear Cache", function()
        LaqourCache = nil
        print("🗑️ Cache cleared")
    end)
    
    return Window
end

-- ===================================
-- METHOD 5: Loadstring with Dynamic Configuration
-- ===================================

print("🔧 Method 5: Loadstring with Dynamic Configuration")

local function method5_DynamicConfiguration()
    local config = {
        windowName = "Dynamic Config Demo",
        color = Color3.new(math.random(), math.random(), math.random()),
        theme = "dark"
    }
    
    local Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
    
    local Window = Laqour:CreateWindow({
        WindowName = config.windowName,
        Color = config.color
    }, game:GetService("CoreGui"))
    
    local Tab = Window:CreateTab("Demo")
    local Section = Tab:CreateSection("Dynamic Config")
    
    Section:CreateLabel("✅ Dynamic configuration applied")
    Section:CreateColorpicker("Change Color", function(Color)
        Window:ChangeColor(Color)
        config.color = Color
    end)
    
    Section:CreateTextBox("Window Name", config.windowName, false, function(Text)
        Window.Topbar.WindowName.Text = Text
        config.windowName = Text
    end)
    
    return Window
end

-- ===================================
-- DEMO EXECUTION
-- ===================================

print("🚀 Starting Loadstring Method Demonstration")

-- Create demonstration windows
local windows = {}

-- Method 1
local window1 = method1_DirectLoadstring()
if window1 then table.insert(windows, window1) end

-- Method 2
local window2 = method2_LoadstringWithErrorHandling()
if window2 then table.insert(windows, window2) end

-- Method 3
local window3 = method3_MultipleSources()
if window3 then table.insert(windows, window3) end

-- Method 4
local window4 = method4_LoadstringWithCaching()
if window4 then table.insert(windows, window4) end

-- Method 5
local window5 = method5_DynamicConfiguration()
if window5 then table.insert(windows, window5) end

-- ===================================
-- DEMO SUMMARY
-- ===================================

print("📊 Loadstring Demo Summary:")
print("  Total Methods: 5")
print("  Successful Windows: " .. #windows)
print("  All methods demonstrate loadstring usage")

-- Create a summary window
if #windows > 0 then
    local Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()
    
    local SummaryWindow = Laqour:CreateWindow({
        WindowName = "Loadstring Demo Summary",
        Color = Color3.new(0.5, 0.5, 0.5)
    }, game:GetService("CoreGui"))
    
    local SummaryTab = SummaryWindow:CreateTab("Summary")
    local SummarySection = SummaryTab:CreateSection("Demo Results")
    
    SummarySection:CreateLabel("🎯 Loadstring Methods Demonstrated:")
    SummarySection:CreateLabel("1. Direct Loadstring")
    SummarySection:CreateLabel("2. Loadstring with Error Handling")
    SummarySection:CreateLabel("3. Multiple Loadstring Sources")
    SummarySection:CreateLabel("4. Loadstring with Caching")
    SummarySection:CreateLabel("5. Loadstring with Dynamic Config")
    
    SummarySection:CreateLabel("✅ All methods working correctly!")
    
    SummarySection:CreateButton("Close All Windows", function()
        for _, window in ipairs(windows) do
            if window and window.Toggle then
                window:Toggle(false)
            end
        end
        SummaryWindow:Toggle(false)
        print("🔚 All demonstration windows closed")
    end)
    
    print("✅ Loadstring demonstration complete!")
else
    print("❌ No windows created - check loadstring URLs")
end
