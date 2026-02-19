# Orion UI Library - GitHub Loadstring

## Raw URL
```
https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/master/Orion-Library/source.lua
```

## Usage Instructions

### Basic Loadstring
```lua
local Orion = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/master/Orion-Library/source.lua"))()

local Window = OrionLib:MakeWindow({
    Name = "My Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionConfig"
})

local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345875",
    PremiumOnly = false
})

Tab:AddButton({
    Name = "Example Button",
    Callback = function()
        print("Button clicked!")
    end
})
```

### Features
- ✅ Full Orion UI API compatibility
- ✅ No external HTTP requests for icons
- ✅ Self-contained single file
- ✅ GitHub hosted for reliability
- ✅ Loadstring ready

### Notes
- The library uses placeholder icons instead of external HTTP requests
- All original Orion UI functionality is preserved
- Compatible with most Roblox executors supporting HTTP requests

## File Location
The hosted library is located at: `Orion-Library/source.lua` in the repository
