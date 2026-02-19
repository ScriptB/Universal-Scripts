-- ===================================
-- LOADSTRING LIBRARY ACCESS (FIRST)
-- ===================================

-- Load LaqourLib first - this must be at the very beginning
local Laqour = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua"))()

-- ===================================
-- SCRIPT LOGIC (AFTER LIBRARY LOAD)
-- ===================================

-- Roblox services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Example GUI creation using loaded LaqourLib
local Window = Laqour:Window({
    Name = "Loadstring Example",
    Color = Color3.fromRGB(0, 255, 0),
    Size = UDim2.new(0, 400, 0, 300),
    Position = UDim2.new(0.5, -200, 0.5, -150)
})

-- Create tab
local Tab = Window:Tab({Name = "Example"})

-- Create section
local Section = Tab:Section({Name = "Demo Controls"})

-- Add toggle
local Toggle = Section:Toggle({
    Name = "Example Toggle",
    Side = "Left",
    Value = false,
    Callback = function(Value)
        print("Toggle changed to:", Value)
    end
})

-- Add button
Section:Button({
    Name = "Example Button",
    Side = "Left",
    Callback = function()
        print("Button clicked!")
        Laqour:Notification({
            Title = "Loadstring Example",
            Description = "Button was clicked!",
            Duration = 3
        })
    end
})

-- Add slider
Section:Slider({
    Name = "Example Slider",
    Side = "Left",
    Min = 0,
    Max = 100,
    Value = 50,
    Precise = 0,
    Unit = "%",
    Callback = function(Value)
        print("Slider value:", Value)
    end
})

-- Add keybind
Section:Keybind({
    Name = "Example Keybind",
    Side = "Left",
    Value = "NONE",
    Mouse = false,
    Blacklist = {"W", "A", "S", "D"},
    Callback = function(Key, Pressed)
        if Pressed then
            print("Keybind pressed:", Key)
        end
    end
})

-- Add color picker
Section:Colorpicker({
    Name = "Example Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Table, Color)
        print("Color changed to:", Color)
    end
})

-- Add label
Section:Label({
    Name = "This GUI was created using loadstring!",
    Side = "Left"
})

-- Add dropdown
Section:Dropdown({
    Name = "Example Dropdown",
    Side = "Left",
    Options = {"Option 1", "Option 2", "Option 3"},
    Callback = function(Option)
        print("Dropdown selected:", Option)
    end
})

-- Add textbox
Section:Textbox({
    Name = "Example Textbox",
    Side = "Left",
    Default = "Type here...",
    Callback = function(Text)
        print("Textbox text:", Text)
    end
})

-- Success notification
Laqour:Notification({
    Title = "Loadstring Example",
    Description = "LaqourLib loaded successfully via loadstring!",
    Duration = 5
})

print("✅ Loadstring example script executed successfully!")
print("🎨 LaqourLib loaded via loadstring method")
print("📦 Library size reduced in main script")
print("🚀 Ready for UI creation")
