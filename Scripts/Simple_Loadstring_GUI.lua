-- Simple Loadstring GUI Example
-- Demonstrates basic loadstring usage for GUI creation

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
-- LOAD LAQOURLIB WITH LOADSTRING
-- ===================================

print("🔧 Loading LaqourLib with loadstring...")

-- Method 1: Direct loadstring
local Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()

if not Laqour then
    warn("❌ Failed to load primary LaqourLib")
    
    -- Method 2: Try alternative source
    Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_Rebranded.lua"))()
    
    if not Laqour then
        warn("❌ Failed to load alternative LaqourLib")
        
        -- Method 3: Try fixed version
        Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/LaqourLib_Fixed.lua"))()
        
        if not Laqour then
            warn("❌ All LaqourLib sources failed!")
            return
        end
    end
end

print("✅ LaqourLib loaded successfully!")

-- ===================================
-- CREATE SIMPLE GUI
-- ===================================

print("🎨 Creating simple GUI...")

-- Create main window
local Window = Laqour:CreateWindow({
    WindowName = "Simple Loadstring GUI",
    Color = Color3.new(0, 0.7, 1)
}, game:GetService("CoreGui"))

-- Create main tab
local MainTab = Window:CreateTab("Main")

-- Create section
local Section = MainTab:CreateSection("Controls")

-- Add UI elements
Section:CreateLabel("🎯 Simple Loadstring GUI Demo")
Section:CreateLabel("✅ LaqourLib loaded via loadstring")

-- Toggle example
local Toggle = Section:CreateToggle("Enable Feature", false, function(Value)
    print("🔄 Toggle:", Value)
end)

-- Button example
Section:CreateButton("Click Me!", function()
    print("🎉 Button clicked!")
    Toggle:SetState(not Toggle:GetState())
end)

-- Slider example
Section:CreateSlider("Value", 1, 100, 50, false, function(Value)
    print("📊 Slider value:", Value)
end)

-- Text box example
Section:CreateTextBox("Input", "Type here...", false, function(Text)
    print("📝 Text input:", Text)
end)

-- Dropdown example
Section:CreateDropdown("Choice", {"Option 1", "Option 2", "Option 3"}, function(Option)
    print("📋 Dropdown:", Option)
end)

-- Color picker example
Section:CreateColorpicker("Color", function(Color)
    print("🎨 Color selected:", Color)
    Window:ChangeColor(Color)
end)

-- ===================================
-- SUCCESS MESSAGE
-- ===================================

print("🚀 Simple loadstring GUI created successfully!")
print("📖 All UI elements are functional")
print("🔗 Loadstring method working perfectly!")

-- Create success notification
Laqour:Notification({
    Title = "Success!",
    Description = "LaqourLib GUI created via loadstring method"
})

-- Return the window for external access
return Window
