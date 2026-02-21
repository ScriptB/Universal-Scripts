-- Universal ESP Pro Enhanced v3.5
-- UI: LinoriaLib | Full ESP | Config System
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced.lua", true))()

repeat task.wait() until game:IsLoaded()

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- LOAD LINORIA UI LIBRARY
-- ══════════════════════════════════════════
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua", true))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua", true))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua", true))()

-- ══════════════════════════════════════════
-- ESP SETTINGS
-- ══════════════════════════════════════════
local Settings = {
    Enabled   = true,
    TeamCheck = false,
    TeamColor = false,
    MaxDist   = 1000,
    Box = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
    },
    Tracer = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Origin    = "Bottom",
    },
    Name = {
        Enabled      = true,
        Color        = Color3.fromRGB(255, 255, 255),
        Size         = 14,
        ShowDistance = true,
        ShowHealth   = false,
        Outline      = true,
    },
    Health = {
        Enabled   = true,
        ShowBar   = true,
        ShowText  = false,
        Thickness = 3,
    },
    Rainbow = {
        Enabled = false,
        Speed   = 1,
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
-- ESP CORE
-- ══════════════════════════════════════════
local ESPObjects = {}

local function GetColor(player, default)
    if Settings.Rainbow.Enabled then
        return Color3.fromHSV((tick() * Settings.Rainbow.Speed) % 1, 1, 1)
    end
    if Settings.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    return default
end

local function NewDrawing(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if not ok then
        return { Visible = false, Remove = function() end }
    end
    for k, v in pairs(props) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function HideESP(e)
    for _, l in ipairs(e.Boxes) do l.Visible = false end
    e.Tracer.Visible  = false
    e.Name.Visible    = false
    e.HpBg.Visible    = false
    e.HpBar.Visible   = false
    e.HpText.Visible  = false
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    local e = {
        Player = player,
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
    }
    ESPObjects[player] = e
end

local function RemoveESP(player)
    local e = ESPObjects[player]
    if not e then return end
    for _, l in ipairs(e.Boxes) do pcall(function() l:Remove() end) end
    pcall(function() e.Tracer:Remove() end)
    pcall(function() e.Name:Remove() end)
    pcall(function() e.HpBg:Remove() end)
    pcall(function() e.HpBar:Remove() end)
    pcall(function() e.HpText:Remove() end)
    ESPObjects[player] = nil
end

local function UpdateESP(e)
    local player = e.Player
    local char   = player.Character
    if not char then HideESP(e); return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then HideESP(e); return end

    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
    if dist > Settings.MaxDist then HideESP(e); return end
    if Settings.TeamCheck and player.Team == LocalPlayer.Team then HideESP(e); return end

    local rv, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then HideESP(e); return end

    local sf = 1 / rv.Z
    local w  = math.clamp(35 * sf * 100, 20, 200)
    local h  = math.clamp(55 * sf * 100, 30, 300)
    local cx, cy = rv.X, rv.Y

    local tl = Vector2.new(cx - w/2, cy - h/2)
    local tr = Vector2.new(cx + w/2, cy - h/2)
    local bl = Vector2.new(cx - w/2, cy + h/2)
    local br = Vector2.new(cx + w/2, cy + h/2)

    local bc = GetColor(player, Settings.Box.Color)
    local bv = Settings.Enabled and Settings.Box.Enabled
    local bt = Settings.Box.Thickness
    e.Boxes[1].From = tl; e.Boxes[1].To = tr; e.Boxes[1].Color = bc; e.Boxes[1].Thickness = bt; e.Boxes[1].Visible = bv
    e.Boxes[2].From = tr; e.Boxes[2].To = br; e.Boxes[2].Color = bc; e.Boxes[2].Thickness = bt; e.Boxes[2].Visible = bv
    e.Boxes[3].From = br; e.Boxes[3].To = bl; e.Boxes[3].Color = bc; e.Boxes[3].Thickness = bt; e.Boxes[3].Visible = bv
    e.Boxes[4].From = bl; e.Boxes[4].To = tl; e.Boxes[4].Color = bc; e.Boxes[4].Thickness = bt; e.Boxes[4].Visible = bv

    local tOrigin
    if Settings.Tracer.Origin == "Top" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif Settings.Tracer.Origin == "Center" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
    e.Tracer.From      = tOrigin
    e.Tracer.To        = Vector2.new(cx, cy + h/2)
    e.Tracer.Color     = GetColor(player, Settings.Tracer.Color)
    e.Tracer.Thickness = Settings.Tracer.Thickness
    e.Tracer.Visible   = Settings.Enabled and Settings.Tracer.Enabled

    local nameStr = player.Name
    if Settings.Name.ShowDistance then nameStr = nameStr .. " [" .. math.floor(dist) .. "m]" end
    if Settings.Name.ShowHealth and hum then nameStr = nameStr .. " [" .. math.floor(hum.Health) .. "hp]" end
    e.Name.Text     = nameStr
    e.Name.Size     = Settings.Name.Size
    e.Name.Color    = GetColor(player, Settings.Name.Color)
    e.Name.Outline  = Settings.Name.Outline
    e.Name.Position = Vector2.new(cx, tl.Y - Settings.Name.Size - 2)
    e.Name.Visible  = Settings.Enabled and Settings.Name.Enabled

    if hum and Settings.Health.Enabled and Settings.Health.ShowBar then
        local ratio  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bx     = tl.X - 6
        local hColor = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
        e.HpBg.From       = Vector2.new(bx, tl.Y)
        e.HpBg.To         = Vector2.new(bx, bl.Y)
        e.HpBg.Thickness  = Settings.Health.Thickness + 1
        e.HpBg.Visible    = Settings.Enabled
        e.HpBar.From      = Vector2.new(bx, bl.Y - (bl.Y - tl.Y) * ratio)
        e.HpBar.To        = Vector2.new(bx, bl.Y)
        e.HpBar.Color     = hColor
        e.HpBar.Thickness = Settings.Health.Thickness
        e.HpBar.Visible   = Settings.Enabled
        if Settings.Health.ShowText then
            e.HpText.Text     = math.floor(hum.Health) .. "hp"
            e.HpText.Position = Vector2.new(bx, tl.Y - 12)
            e.HpText.Visible  = Settings.Enabled
        else
            e.HpText.Visible = false
        end
    else
        e.HpBg.Visible   = false
        e.HpBar.Visible  = false
        e.HpText.Visible = false
    end
end

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

-- ══════════════════════════════════════════
-- ESP RUNTIME
-- ══════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

local _wmConn = RunService.RenderStepped:Connect(function()
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
Notify("Universal ESP Pro Enhanced", "Loaded! Press End to toggle menu.", 5)
print("[Universal ESP Pro Enhanced v3.5] Loaded successfully.")
