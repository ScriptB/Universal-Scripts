-- Universal ESP Pro Enhanced v3.8
-- UI: LinoriaLib | Full ESP | Aimbot | Config System
-- Features: Advanced ESP, Silent Aimbot, Third Person Aimbot, Rainbow Effects, Performance Optimized
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced.lua", true))()

-- ══════════════════════════════════════════
-- POLYFILLS & COMPATIBILITY
-- ══════════════════════════════════════════
local function safe_getgenv()
    return (type(getgenv) == "function" and getgenv()) or _G
end
local getgenv = safe_getgenv

-- Polyfills
local tick = tick or os.clock
local print = print or warn or function(...) end
local warn = warn or print or function(...) end

-- Safe warn function
local function SafeWarn(...)
    if type(warn) == "function" then 
        pcall(warn, ...) 
    elseif type(print) == "function" then 
        pcall(print, "[WARN]", ...) 
    end
end

-- Ensure essential functions exist
if not getgenv().setclipboard then getgenv().setclipboard = function(s) end end
if not getgenv().Drawing then 
    getgenv().Drawing = { new = function(t) return {Visible = false, Remove = function() end} end } 
end

-- Service aliases for speed and safety
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

-- ══════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded()

-- Performance tracking
local _startTime = tick()
local _memoryUsage = 0
local _lastCleanup = tick()
local _fps          = 60
local _frameTimer   = tick()
local _frameCounter = 0
local _ping         = 0

-- ══════════════════════════════════════════
-- NOTIFICATION ON LOAD
-- ══════════════════════════════════════════
if Library then
    Library:Notify("Loaded", "Universal ESP & Aimbot v3.8 Loaded!", 5)
end

-- Wait for character to load
local LocalPlayer = Players.LocalPlayer
-- Removed infinite yield for character to ensure UI loads even in menus

-- Utility functions
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

local function IsValidPlayer(player)
    return player and player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid")
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- ══════════════════════════════════════════
-- LOAD LINORIA UI LIBRARY
-- ══════════════════════════════════════════
print("[DEBUG] Loading Linoria UI Library...")
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua", true))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua", true))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua", true))()
print("[DEBUG] Linoria UI Library loaded successfully!")

-- ══════════════════════════════════════════
-- ESP SETTINGS (Enhanced)
-- ══════════════════════════════════════════
local Settings = {
    Enabled   = true,
    TeamCheck = false,
    TeamColor = false,
    MaxDist   = 1000,
    Performance = {
        UpdateRate = 60,  -- FPS limit for ESP updates
        CullingDistance = 2000,
        CleanupInterval = 30,  -- seconds
    },
    Box = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Style     = "Corner",  -- Corner, Full, 3D
        CornerSize = 8,
    },
    Tracer = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Origin    = "Bottom",
        Style     = "Line",  -- Line, Arrow
    },
    Name = {
        Enabled      = true,
        Color        = Color3.fromRGB(255, 255, 255),
        Size         = 14,
        ShowDistance = true,
        ShowHealth   = false,
        ShowWeapon   = true,
        Outline      = true,
        Font         = "UI",
    },
    Health = {
        Enabled   = true,
        ShowBar   = true,
        ShowText  = false,
        Thickness = 3,
        Style     = "Bar",  -- Bar, Text, Both
        Position  = "Left",  -- Left, Right, Top, Bottom
    },
    Rainbow = {
        Enabled = false,
        Speed   = 1,
        Saturation = 1,
        Value = 1,
    },
    Chams = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.5,
        Material = "ForceField",
    },
}

-- ══════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════
local CONFIG_FILE = "UniversalESP_Config.json"

local function SerializeColor(c)
    return { R = c.R, G = c.G, B = c.B }
end
local function DeserializeColor(d)
    return Color3.new(d.R, d.G, d.B)
end
local function DeepSerialize(t)
    local o = {}
    for k, v in pairs(t) do
        if typeof(v) == "Color3" then
            o[k] = SerializeColor(v)
        elseif type(v) == "table" then
            o[k] = DeepSerialize(v)
        else
            o[k] = v
        end
    end
    return o
end
local function DeepDeserialize(t)
    local o = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            if v.R ~= nil and v.G ~= nil and v.B ~= nil then
                o[k] = DeserializeColor(v)
            else
                o[k] = DeepDeserialize(v)
            end
        else
            o[k] = v
        end
    end
    return o
end

local function Notify(title, content, duration)
    Library:Notify(title .. "\n" .. content, duration or 4)
end

local function SaveConfig()
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(DeepSerialize(Settings)))
    end)
    if ok then
        print("[ESP] Config saved.")
        Notify("Config Saved", "Written to " .. CONFIG_FILE, 3)
    else
        warn("[ESP] Save failed: " .. tostring(err))
        Notify("Save Failed", tostring(err), 5)
    end
end

local function LoadConfig()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and data then
        local loaded = DeepDeserialize(data)
        for k, v in pairs(loaded) do
            if Settings[k] ~= nil then
                if type(v) == "table" and type(Settings[k]) == "table" then
                    for sk, sv in pairs(v) do
                        Settings[k][sk] = sv
                    end
                else
                    Settings[k] = v
                end
            end
        end
        print("[ESP] Config loaded.")
        Notify("Config Loaded", "Restored from " .. CONFIG_FILE, 3)
    else
        Notify("No Config Found", "Save a config first.", 4)
    end
end

-- ══════════════════════════════════════════
-- ESP CORE (Enhanced)
-- ══════════════════════════════════════════
local ESPObjects = {}
local _lastESPUpdate = 0
local _espUpdateCount = 0

-- Enhanced color function with more options
local function GetColor(player, default)
    if Settings.Rainbow.Enabled then
        return Color3.fromHSV((tick() * Settings.Rainbow.Speed) % 1, Settings.Rainbow.Saturation, Settings.Rainbow.Value)
    end
    if Settings.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    return default
end

-- Enhanced drawing function with better error handling
local function NewDrawing(class, props)
    local success, obj = SafeCall(Drawing.new, class)
    if not success or not obj then
        return { Visible = false, Remove = function() end, Color = Color3.new(1,1,1), Thickness = 1 }
    end
    
    -- Apply properties safely
    if props then
        for k, v in pairs(props) do
            SafeCall(function() obj[k] = v end)
        end
    end
    
    return obj
end

-- Optimized ESP hiding function
local function HideESP(e)
    if not e then return end
    
    -- Hide all drawing objects
    if e.Boxes then
        for _, l in ipairs(e.Boxes) do
            pcall(function() l.Visible = false end)
        end
    end
    
    local objects = {e.Tracer, e.Name, e.HpBg, e.HpBar, e.HpText, e.CornerBox, e.Chams}
    for _, obj in pairs(objects) do
        if obj then
            SafeCall(function() obj.Visible = false end)
        end
    end
end

-- Enhanced ESP creation with more features
local function CreateESP(player)
    if not IsValidPlayer(player) or ESPObjects[player] then return end
    
    local e = {
        Player = player,
        LastUpdate = tick(),
        Visible = true,
        Distance = 0,
        
        -- Standard ESP elements
        Boxes = {
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        },
        Tracer = NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        Name   = NewDrawing("Text", { Text = player.Name, Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        HpBg   = NewDrawing("Line", { Thickness = 4, Color = Color3.new(0,0,0), Transparency = 0.5, Visible = false }),
        HpBar  = NewDrawing("Line", { Thickness = 3, Color = Color3.new(0,1,0), Transparency = 1, Visible = false }),
        HpText = NewDrawing("Text", { Text = "100hp", Size = 11, Center = true, Outline = true, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        
        -- Enhanced features
        CornerBox = NewDrawing("Square", { Visible = false, Color = Color3.new(1,1,1), Thickness = 1, Size = Vector2.new(10,10), Filled = false }),
        Chams = {},  -- Will be populated if enabled
    }
    
    ESPObjects[player] = e
end

-- Enhanced ESP removal with proper cleanup
local function RemoveESP(player)
    local e = ESPObjects[player]
    if not e then return end
    
    -- Safely remove all drawing objects
    if e.Boxes then
        for _, l in ipairs(e.Boxes) do
            SafeCall(function() l:Remove() end)
        end
    end
    
    local objects = {e.Tracer, e.Name, e.HpBg, e.HpBar, e.HpText, e.CornerBox}
    for _, obj in pairs(objects) do
        if obj then
            SafeCall(function() obj:Remove() end)
        end
    end
    
    -- Remove chams if they exist
    if e.Chams then
        for _, cham in pairs(e.Chams) do
            SafeCall(function() cham:Remove() end)
        end
    end
    
    ESPObjects[player] = nil
end

-- Performance monitoring and cleanup
local function PerformCleanup()
    local currentTime = tick()
    if (currentTime - _lastCleanup) < Settings.Performance.CleanupInterval then return end
    
    _lastCleanup = currentTime
    local removedCount = 0
    
    for player, e in pairs(ESPObjects) do
        if not IsValidPlayer(player) then
            RemoveESP(player)
            removedCount = removedCount + 1
        end
    end
    
    if removedCount > 0 then
        print("[ESP] Cleaned up " .. removedCount .. " invalid ESP objects")
    end
end

-- Enhanced ESP update function with performance optimizations
local function UpdateESP(e)
    if not e or not e.Player then return end
    
    local player = e.Player
    local char = player.Character
    
    -- Quick validation checks
    if not char or not IsValidPlayer(player) then
        HideESP(e)
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        HideESP(e)
        return
    end
    
    -- Distance and visibility checks
    local Camera = workspace.CurrentCamera
    if not Camera then return end
    
    local distance = GetDistance(hrp.Position, Camera.CFrame.Position)
    e.Distance = distance
    
    if distance > Settings.Performance.CullingDistance then
        HideESP(e)
        return
    end
    
    if Settings.TeamCheck and player.Team == LocalPlayer.Team then
        HideESP(e)
        return
    end
    
    -- Screen position calculation
    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        HideESP(e)
        return
    end
    
    -- Update timing for performance
    e.LastUpdate = tick()
    
    -- Calculate box dimensions
    local scaleFactor = 1 / screenPos.Z
    local boxWidth = math.clamp(35 * scaleFactor * 100, 20, 200)
    local boxHeight = math.clamp(55 * scaleFactor * 100, 30, 300)
    local centerX, centerY = screenPos.X, screenPos.Y
    
    -- Box corners
    local topLeft = Vector2.new(centerX - boxWidth/2, centerY - boxHeight/2)
    local topRight = Vector2.new(centerX + boxWidth/2, centerY - boxHeight/2)
    local bottomLeft = Vector2.new(centerX - boxWidth/2, centerY + boxHeight/2)
    local bottomRight = Vector2.new(centerX + boxWidth/2, centerY + boxHeight/2)
    
    -- Get colors
    local boxColor = GetColor(player, Settings.Box.Color)
    local tracerColor = GetColor(player, Settings.Tracer.Color)
    local nameColor = GetColor(player, Settings.Name.Color)
    
    -- Update boxes based on style
    local boxVisible = Settings.Enabled and Settings.Box.Enabled
    if Settings.Box.Style == "Corner" and e.CornerBox then
        -- Corner box style
        e.CornerBox.Visible = boxVisible
        e.CornerBox.Position = topLeft
        e.CornerBox.Size = Vector2.new(boxWidth, boxHeight)
        e.CornerBox.Color = boxColor
        e.CornerBox.Thickness = Settings.Box.Thickness
        
        -- Hide regular boxes
        for _, box in ipairs(e.Boxes) do
            SafeCall(function() box.Visible = false end)
        end
    else
        -- Full box style
        e.Boxes[1].From = topLeft; e.Boxes[1].To = topRight; e.Boxes[1].Color = boxColor; e.Boxes[1].Thickness = Settings.Box.Thickness; e.Boxes[1].Visible = boxVisible
        e.Boxes[2].From = topRight; e.Boxes[2].To = bottomRight; e.Boxes[2].Color = boxColor; e.Boxes[2].Thickness = Settings.Box.Thickness; e.Boxes[2].Visible = boxVisible
        e.Boxes[3].From = bottomRight; e.Boxes[3].To = bottomLeft; e.Boxes[3].Color = boxColor; e.Boxes[3].Thickness = Settings.Box.Thickness; e.Boxes[3].Visible = boxVisible
        e.Boxes[4].From = bottomLeft; e.Boxes[4].To = topLeft; e.Boxes[4].Color = boxColor; e.Boxes[4].Thickness = Settings.Box.Thickness; e.Boxes[4].Visible = boxVisible
        
        -- Hide corner box
        if e.CornerBox then
            SafeCall(function() e.CornerBox.Visible = false end)
        end
    end
    
    -- Update tracer
    local tracerOrigin
    if Settings.Tracer.Origin == "Top" then
        tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif Settings.Tracer.Origin == "Center" then
        tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
    
    e.Tracer.From = tracerOrigin
    e.Tracer.To = Vector2.new(centerX, centerY + boxHeight/2)
    e.Tracer.Color = tracerColor
    e.Tracer.Thickness = Settings.Tracer.Thickness
    e.Tracer.Visible = Settings.Enabled and Settings.Tracer.Enabled
    
    -- Update name with enhanced information
    local nameText = player.Name
    if Settings.Name.ShowDistance then
        nameText = nameText .. " [" .. math.floor(distance) .. "m]"
    end
    if Settings.Name.ShowHealth then
        nameText = nameText .. " [" .. math.floor(hum.Health) .. "hp]"
    end
    if Settings.Name.ShowWeapon then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        if tool and tool.Name then
            nameText = nameText .. " [" .. tool.Name .. "]"
        end
    end
    
    e.Name.Text = nameText
    e.Name.Position = Vector2.new(centerX, centerY - boxHeight/2 - 15)
    e.Name.Color = nameColor
    e.Name.Size = Settings.Name.Size
    e.Name.Visible = Settings.Enabled and Settings.Name.Enabled
    
    -- Update health bar
    if Settings.Health.Enabled then
        local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local healthColor = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        
        -- Health bar positioning based on setting
        local barX, barY
        if Settings.Health.Position == "Left" then
            barX, barY = centerX - boxWidth/2 - 10, centerY
        elseif Settings.Health.Position == "Right" then
            barX, barY = centerX + boxWidth/2 + 10, centerY
        elseif Settings.Health.Position == "Top" then
            barX, barY = centerX, centerY - boxHeight/2 - 10
        else -- Bottom
            barX, barY = centerX, centerY + boxHeight/2 + 10
        end
        
        if Settings.Health.Position == "Left" or Settings.Health.Position == "Right" then
            -- Vertical health bar
            e.HpBg.From = Vector2.new(barX, barY - boxHeight/2)
            e.HpBg.To = Vector2.new(barX, barY + boxHeight/2)
            e.HpBar.From = Vector2.new(barX, barY + boxHeight/2 - (boxHeight * healthPercent))
            e.HpBar.To = Vector2.new(barX, barY + boxHeight/2)
        else
            -- Horizontal health bar
            e.HpBg.From = Vector2.new(barX - boxWidth/2, barY)
            e.HpBg.To = Vector2.new(barX + boxWidth/2, barY)
            e.HpBar.From = Vector2.new(barX - boxWidth/2, barY)
            e.HpBar.To = Vector2.new(barX - boxWidth/2 + (boxWidth * healthPercent), barY)
        end
        
        e.HpBg.Color = Color3.new(0, 0, 0)
        e.HpBg.Thickness = Settings.Health.Thickness + 1
        e.HpBg.Visible = Settings.Enabled and Settings.Health.ShowBar
        
        e.HpBar.Color = healthColor
        e.HpBar.Thickness = Settings.Health.Thickness
        e.HpBar.Visible = Settings.Enabled and Settings.Health.ShowBar
        
        -- Health text
        if Settings.Health.ShowText then
            e.HpText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
            e.HpText.Position = Vector2.new(centerX, barY + 15)
            e.HpText.Color = healthColor
            e.HpText.Visible = Settings.Enabled and Settings.Health.ShowText
        else
            e.HpText.Visible = false
        end
    else
        e.HpBg.Visible = false
        e.HpBar.Visible = false
        e.HpText.Visible = false
    end
end

-- ══════════════════════════════════════════
-- AIMBOT CORE (Removed)
-- ══════════════════════════════════════════

-- ══════════════════════════════════════════
-- BUILD LINORIA UI
-- ══════════════════════════════════════════
local Window = Library:CreateWindow({
    Title        = "Universal ESP Pro Enhanced",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 10,
    MenuFadeTime = 0.35,
})

local Tabs = {
    ESP     = Window:AddTab("ESP"),
    Visuals = Window:AddTab("Visuals"),
    Config  = Window:AddTab("Config"),
    UI      = Window:AddTab("UI Settings"),
}

-- ══════════════════════════════════════════
-- TAB: ESP
-- ══════════════════════════════════════════

-- LEFT: General + Box + Health
local GbMaster = Tabs.ESP:AddLeftGroupbox("General")
GbMaster:AddToggle("ESPEnabled", {
    Text    = "ESP Enabled",
    Default = Settings.Enabled,
    Tooltip = "Master switch — turns off all ESP rendering",
})
GbMaster:AddLabel("Toggle Keybind"):AddKeyPicker("ESPKeybind", {
    Default         = "RightShift",
    SyncToggleState = true,
    Mode            = "Toggle",
    Text            = "ESP On/Off",
    Tooltip         = "Keybind synced to the ESP Enabled toggle",
})
GbMaster:AddDivider()
GbMaster:AddToggle("TeamCheck", {
    Text    = "Team Check",
    Default = Settings.TeamCheck,
    Tooltip = "Skip ESP for players on your team",
})
GbMaster:AddToggle("TeamColor", {
    Text    = "Team Color",
    Default = Settings.TeamColor,
    Tooltip = "Use each player's team color instead of custom colors",
})
GbMaster:AddDivider()
GbMaster:AddSlider("MaxDist", {
    Text     = "Max Distance",
    Default  = Settings.MaxDist,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Suffix   = " st",
    Compact  = false,
    Tooltip  = "ESP hidden beyond this distance",
})

local GbBox = Tabs.ESP:AddLeftGroupbox("Box")
GbBox:AddToggle("BoxEnabled", {
    Text    = "Enabled",
    Default = Settings.Box.Enabled,
    Tooltip = "Bounding box around each player",
})
local DepBox = GbBox:AddDependencyBox()
DepBox:AddSlider("BoxThickness", {
    Text     = "Thickness",
    Default  = Settings.Box.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Box line thickness",
})
DepBox:AddLabel("Color"):AddColorPicker("BoxColor", {
    Default = Settings.Box.Color,
    Title   = "Box Color",
})
DepBox:SetupDependencies({ { Toggles.BoxEnabled, true } })

local GbHealth = Tabs.ESP:AddLeftGroupbox("Health Bar")
GbHealth:AddToggle("HealthEnabled", {
    Text    = "Enabled",
    Default = Settings.Health.Enabled,
    Tooltip = "Side health bar for each player",
})
local DepHealth = GbHealth:AddDependencyBox()
DepHealth:AddToggle("HealthText", {
    Text    = "Show HP Number",
    Default = Settings.Health.ShowText,
    Tooltip = "Show numeric HP above the bar",
})
DepHealth:AddSlider("HealthThickness", {
    Text     = "Thickness",
    Default  = Settings.Health.Thickness,
    Min      = 1,
    Max      = 6,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Health bar line thickness",
})
DepHealth:SetupDependencies({ { Toggles.HealthEnabled, true } })

-- RIGHT: Tracer + Name
local GbTracer = Tabs.ESP:AddRightGroupbox("Tracer")
GbTracer:AddToggle("TracerEnabled", {
    Text    = "Enabled",
    Default = Settings.Tracer.Enabled,
    Tooltip = "Line from screen edge to each player",
})
local DepTracer = GbTracer:AddDependencyBox()
DepTracer:AddDropdown("TracerOrigin", {
    Values  = { "Bottom", "Center", "Top" },
    Default = 1,
    Text    = "Origin Point",
    Tooltip = "Where the tracer starts on screen",
})
DepTracer:AddSlider("TracerThickness", {
    Text     = "Thickness",
    Default  = Settings.Tracer.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Tracer line thickness",
})
DepTracer:AddLabel("Color"):AddColorPicker("TracerColor", {
    Default = Settings.Tracer.Color,
    Title   = "Tracer Color",
})
DepTracer:SetupDependencies({ { Toggles.TracerEnabled, true } })

local GbName = Tabs.ESP:AddRightGroupbox("Name Label")
GbName:AddToggle("NameEnabled", {
    Text    = "Enabled",
    Default = Settings.Name.Enabled,
    Tooltip = "Player name above their character",
})
local DepName = GbName:AddDependencyBox()
DepName:AddToggle("ShowDistance", {
    Text    = "Distance",
    Default = Settings.Name.ShowDistance,
    Tooltip = "Append [Xm] to the name",
})
DepName:AddToggle("ShowHealthName", {
    Text    = "Health",
    Default = Settings.Name.ShowHealth,
    Tooltip = "Append [Xhp] to the name",
})
DepName:AddToggle("NameOutline", {
    Text    = "Outline",
    Default = Settings.Name.Outline,
    Tooltip = "Dark outline behind text",
})
DepName:AddSlider("NameSize", {
    Text     = "Size",
    Default  = Settings.Name.Size,
    Min      = 10,
    Max      = 24,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Name text size",
})
DepName:AddLabel("Color"):AddColorPicker("NameColor", {
    Default = Settings.Name.Color,
    Title   = "Name Color",
})
DepName:SetupDependencies({ { Toggles.NameEnabled, true } })

-- ══════════════════════════════════════════
-- TAB: AIMBOT (Removed)
-- ══════════════════════════════════════════

-- ══════════════════════════════════════════
-- TAB: VISUALS
-- ══════════════════════════════════════════
local GbRainbow = Tabs.Visuals:AddLeftGroupbox("Rainbow")
GbRainbow:AddToggle("RainbowEnabled", {
    Text    = "Rainbow Mode",
    Default = Settings.Rainbow.Enabled,
    Tooltip = "Cycle all ESP colors through the spectrum",
})
local DepRainbow = GbRainbow:AddDependencyBox()
DepRainbow:AddSlider("RainbowSpeed", {
    Text     = "Speed",
    Default  = Settings.Rainbow.Speed,
    Min      = 1,
    Max      = 20,
    Rounding = 0,
    Compact  = true,
    Suffix   = "x",
    Tooltip  = "Rainbow cycle speed",
})
DepRainbow:SetupDependencies({ { Toggles.RainbowEnabled, true } })

local GbColorNote = Tabs.Visuals:AddRightGroupbox("Color Priority")
GbColorNote:AddLabel("1. Rainbow (overrides all)", true)
GbColorNote:AddLabel("2. Team Color (per player)", true)
GbColorNote:AddLabel("3. Custom colors (default)", true)
GbColorNote:AddDivider()
GbColorNote:AddLabel("Set colors in the ESP tab\nunder each feature.", true)

-- ══════════════════════════════════════════
-- TAB: CONFIG
-- ══════════════════════════════════════════
local GbConfig = Tabs.Config:AddLeftGroupbox("ESP Config")
GbConfig:AddButton({
    Text    = "Save Config",
    Func    = SaveConfig,
    Tooltip = "Save current settings to " .. CONFIG_FILE,
})
GbConfig:AddButton({
    Text    = "Load Config",
    Func    = LoadConfig,
    Tooltip = "Load settings from " .. CONFIG_FILE,
})
GbConfig:AddDivider()
GbConfig:AddLabel("File: " .. CONFIG_FILE, true)

local GbScriptInfo = Tabs.Config:AddRightGroupbox("About")
GbScriptInfo:AddLabel("Universal ESP Pro Enhanced", true)
GbScriptInfo:AddLabel("v3.5  |  LinoriaLib", true)
GbScriptInfo:AddDivider()
GbScriptInfo:AddLabel("Loadstring in script header.", true)
GbScriptInfo:AddDivider()
GbScriptInfo:AddButton({
    Text    = "Copy Loadstring",
    Func    = function()
        if setclipboard then
            setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced.lua",true))()')
            Notify("Copied!", "Loadstring copied to clipboard.", 3)
        else
            Notify("Unavailable", "setclipboard not supported.", 3)
        end
    end,
    Tooltip = "Copy the loadstring to clipboard",
})

-- ══════════════════════════════════════════
-- TAB: UI SETTINGS
-- ══════════════════════════════════════════
local GbMenu = Tabs.UI:AddLeftGroupbox("Menu")
GbMenu:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI    = true,
    Text    = "Toggle Menu",
    Tooltip = "Show/hide the menu",
})
GbMenu:AddDivider()
GbMenu:AddButton({
    Text    = "Unload Script",
    Func    = function()
        Notify("Unloading", "Removing all ESP...", 2)
        task.wait(0.6)
        Library:Unload()
    end,
    Tooltip = "Remove all ESP and destroy the UI",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("UniversalESP")
SaveManager:SetFolder("UniversalESP")
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)

-- ══════════════════════════════════════════
-- ONCHANGED CALLBACKS (decoupled from UI)
-- ══════════════════════════════════════════
Toggles.ESPEnabled:OnChanged(function()    Settings.Enabled          = Toggles.ESPEnabled.Value    end)
Toggles.TeamCheck:OnChanged(function()     Settings.TeamCheck         = Toggles.TeamCheck.Value     end)
Toggles.TeamColor:OnChanged(function()     Settings.TeamColor         = Toggles.TeamColor.Value     end)
Options.MaxDist:OnChanged(function()       Settings.MaxDist           = Options.MaxDist.Value       end)

Toggles.BoxEnabled:OnChanged(function()    Settings.Box.Enabled       = Toggles.BoxEnabled.Value    end)
Options.BoxThickness:OnChanged(function()  Settings.Box.Thickness      = Options.BoxThickness.Value  end)
Options.BoxColor:OnChanged(function()      Settings.Box.Color          = Options.BoxColor.Value      end)

Toggles.TracerEnabled:OnChanged(function()   Settings.Tracer.Enabled   = Toggles.TracerEnabled.Value   end)
Options.TracerThickness:OnChanged(function() Settings.Tracer.Thickness  = Options.TracerThickness.Value end)
Options.TracerOrigin:OnChanged(function()    Settings.Tracer.Origin     = Options.TracerOrigin.Value    end)
Options.TracerColor:OnChanged(function()     Settings.Tracer.Color      = Options.TracerColor.Value     end)

Toggles.NameEnabled:OnChanged(function()    Settings.Name.Enabled      = Toggles.NameEnabled.Value    end)
Toggles.ShowDistance:OnChanged(function()   Settings.Name.ShowDistance  = Toggles.ShowDistance.Value   end)
Toggles.ShowHealthName:OnChanged(function() Settings.Name.ShowHealth    = Toggles.ShowHealthName.Value  end)
Toggles.NameOutline:OnChanged(function()    Settings.Name.Outline       = Toggles.NameOutline.Value     end)
Options.NameSize:OnChanged(function()       Settings.Name.Size          = Options.NameSize.Value        end)
Options.NameColor:OnChanged(function()      Settings.Name.Color         = Options.NameColor.Value       end)

Toggles.HealthEnabled:OnChanged(function()   Settings.Health.Enabled    = Toggles.HealthEnabled.Value   end)
Toggles.HealthText:OnChanged(function()      Settings.Health.ShowText    = Toggles.HealthText.Value      end)
Options.HealthThickness:OnChanged(function() Settings.Health.Thickness   = Options.HealthThickness.Value end)

Toggles.RainbowEnabled:OnChanged(function() Settings.Rainbow.Enabled    = Toggles.RainbowEnabled.Value  end)
Options.RainbowSpeed:OnChanged(function()   Settings.Rainbow.Speed       = Options.RainbowSpeed.Value    end)

Options.ESPKeybind:OnClick(function()
    Settings.Enabled = Toggles.ESPEnabled.Value
end)


-- ══════════════════════════════════════════
-- WATERMARK
-- ══════════════════════════════════════════
-- Watermark: bottom-left
Library:SetWatermarkVisibility(true)
Library.Watermark.Position = UDim2.new(0, 10, 1, -30)

-- KeybindFrame: bottom-left above watermark, auto-hide after 10s
Library.KeybindFrame.Position = UDim2.new(0, 10, 1, -55)
Library.KeybindFrame.Visible = true
task.delay(10, function()
    if Library.KeybindFrame then
        Library.KeybindFrame.Visible = false
    end
end)

-- NotificationArea: bottom-right corner exactly at screen corner
Library.NotificationArea.AnchorPoint = Vector2.new(1, 1)
Library.NotificationArea.Position    = UDim2.new(1, 0, 1, 0)
Library.NotificationArea.Size        = UDim2.new(0, 300, 0, 600)
-- Make the list layout stack from the bottom upward
local _notifLayout = Library.NotificationArea:FindFirstChildOfClass("UIListLayout")
if _notifLayout then
    _notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

local _frameTimer   = tick()
local _frameCounter = 0
local _fps          = 60
local _ping         = 0

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

local _wmConn = RunService.RenderStepped:Connect(function(dt)
    _frameCounter += 1
    if (tick() - _frameTimer) >= 1 then
        _fps          = _frameCounter
        _frameTimer   = tick()
        _frameCounter = 0
    end
    local ok, p = pcall(function()
        return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    _ping = ok and p or _ping
    Library:SetWatermark(("Universal ESP v3.5  |  %d fps  |  %dms  |  %d players"):format(
        math.floor(_fps), _ping,
        math.max(0, #Players:GetPlayers() - 1)
    ))
    for _, e in pairs(ESPObjects) do
        pcall(UpdateESP, e)
    end
end)

Library:OnUnload(function()
    _wmConn:Disconnect()
    UserInputService.MouseDeltaSensitivity = 1
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
    print("[Universal ESP] Unloaded.")
end)

-- ══════════════════════════════════════════
-- GLOBAL API
-- ══════════════════════════════════════════
getgenv().UniversalESP = {
    Settings   = Settings,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    Destroy    = function() Library:Unload() end,
}

SaveManager:LoadAutoloadConfig()
print("[DEBUG] Config loaded, showing notification...")
Notify("Universal ESP Pro Enhanced", "Loaded! Press End to toggle menu.", 5)
print("[DEBUG] Universal ESP Pro Enhanced v3.8 loaded successfully!")
print("[DEBUG] Script is ready. Press End key to toggle UI.")
print("[DEBUG] Third Person Aimbot Mode: Select 'Third Person' in Lock Mode dropdown!")
