# Libraries

This folder contains UI libraries and dependencies used by the scripts.

## Files

### BracketLib.lua
Modern UI library for creating professional interfaces:
- Tabbed interface support
- Multiple UI components
- Responsive design
- Easy integration

### Additional Libraries
- **LaqourLib**: Alternative UI library
- **NexacLib**: Modern UI framework
- **OrionLib**: Feature-rich GUI library

## Usage

### BracketLib Example
```lua
local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/BracketLib.lua"))()

local Window = Bracket:CreateWindow({
    Name = "My Script",
    Size = UDim2.new(0, 500, 0, 350)
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("Settings")

Section:CreateToggle("Enable Feature", function(state)
    print("Feature is now:", state)
end)
```

## Features

- ✅ Modern design patterns
- ✅ Responsive layouts
- ✅ Easy component creation
- ✅ Theme support
- ✅ Cross-platform compatibility
