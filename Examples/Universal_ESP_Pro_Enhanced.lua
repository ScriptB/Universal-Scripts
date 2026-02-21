-- Universal ESP Pro Enhanced v3.3
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
local repo = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"
local Library    = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

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

local function SaveConfig()
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(DeepSerialize(Settings)))
    end)
    if ok then
        print("[ESP] Config saved.")
        Library:Notify("Config saved!", 3)
    else
        warn("[ESP] Save failed: " .. tostring(err))
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
        Library:Notify("Config loaded!", 3)
    else
        Library:Notify("No config found.", 3)
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
    Title    = "Universal ESP Pro Enhanced",
    Center   = true,
    AutoShow = true,
})

local Tabs = {
    ESP     = Window:AddTab("ESP"),
    Visuals = Window:AddTab("Visuals"),
    Config  = Window:AddTab("Config"),
    UI      = Window:AddTab("UI Settings"),
}

-- ── ESP Tab ────────────────────────────────
local GbMaster = Tabs.ESP:AddLeftGroupbox("Master")
GbMaster:AddToggle("ESPEnabled", {
    Text     = "ESP Enabled",
    Default  = Settings.Enabled,
    Callback = function(v) Settings.Enabled = v end,
})
GbMaster:AddToggle("TeamCheck", {
    Text     = "Team Check",
    Default  = Settings.TeamCheck,
    Tooltip  = "Hide ESP for teammates",
    Callback = function(v) Settings.TeamCheck = v end,
})
GbMaster:AddToggle("TeamColor", {
    Text     = "Team Color",
    Default  = Settings.TeamColor,
    Tooltip  = "Use team color for ESP elements",
    Callback = function(v) Settings.TeamColor = v end,
})
GbMaster:AddSlider("MaxDist", {
    Text     = "Max Distance",
    Default  = Settings.MaxDist,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Suffix   = " studs",
    Callback = function(v) Settings.MaxDist = v end,
})

local GbBox = Tabs.ESP:AddRightGroupbox("Box ESP")
GbBox:AddToggle("BoxEnabled", {
    Text     = "Box Enabled",
    Default  = Settings.Box.Enabled,
    Callback = function(v) Settings.Box.Enabled = v end,
})
GbBox:AddSlider("BoxThickness", {
    Text     = "Thickness",
    Default  = Settings.Box.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Callback = function(v) Settings.Box.Thickness = v end,
})
GbBox:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default  = Settings.Box.Color,
    Callback = function(v) Settings.Box.Color = v end,
})

local GbTracer = Tabs.ESP:AddLeftGroupbox("Tracer ESP")
GbTracer:AddToggle("TracerEnabled", {
    Text     = "Tracer Enabled",
    Default  = Settings.Tracer.Enabled,
    Callback = function(v) Settings.Tracer.Enabled = v end,
})
GbTracer:AddSlider("TracerThickness", {
    Text     = "Thickness",
    Default  = Settings.Tracer.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Callback = function(v) Settings.Tracer.Thickness = v end,
})
GbTracer:AddLabel("Tracer Color"):AddColorPicker("TracerColor", {
    Default  = Settings.Tracer.Color,
    Callback = function(v) Settings.Tracer.Color = v end,
})
GbTracer:AddDropdown("TracerOrigin", {
    Values   = { "Bottom", "Center", "Top" },
    Default  = 1,
    Text     = "Origin",
    Callback = function(v) Settings.Tracer.Origin = v end,
})

local GbName = Tabs.ESP:AddRightGroupbox("Name ESP")
GbName:AddToggle("NameEnabled", {
    Text     = "Name Enabled",
    Default  = Settings.Name.Enabled,
    Callback = function(v) Settings.Name.Enabled = v end,
})
GbName:AddToggle("ShowDistance", {
    Text     = "Show Distance",
    Default  = Settings.Name.ShowDistance,
    Callback = function(v) Settings.Name.ShowDistance = v end,
})
GbName:AddToggle("ShowHealthName", {
    Text     = "Show Health",
    Default  = Settings.Name.ShowHealth,
    Callback = function(v) Settings.Name.ShowHealth = v end,
})
GbName:AddToggle("NameOutline", {
    Text     = "Outline",
    Default  = Settings.Name.Outline,
    Callback = function(v) Settings.Name.Outline = v end,
})
GbName:AddSlider("NameSize", {
    Text     = "Size",
    Default  = Settings.Name.Size,
    Min      = 10,
    Max      = 24,
    Rounding = 0,
    Callback = function(v) Settings.Name.Size = v end,
})
GbName:AddLabel("Name Color"):AddColorPicker("NameColor", {
    Default  = Settings.Name.Color,
    Callback = function(v) Settings.Name.Color = v end,
})

local GbHealth = Tabs.ESP:AddLeftGroupbox("Health Bar")
GbHealth:AddToggle("HealthEnabled", {
    Text     = "Health Bar Enabled",
    Default  = Settings.Health.Enabled,
    Callback = function(v) Settings.Health.Enabled = v end,
})
GbHealth:AddToggle("HealthText", {
    Text     = "Health Text",
    Default  = Settings.Health.ShowText,
    Callback = function(v) Settings.Health.ShowText = v end,
})
GbHealth:AddSlider("HealthThickness", {
    Text     = "Thickness",
    Default  = Settings.Health.Thickness,
    Min      = 1,
    Max      = 6,
    Rounding = 0,
    Callback = function(v) Settings.Health.Thickness = v end,
})

-- ── Visuals Tab ────────────────────────────
local GbRainbow = Tabs.Visuals:AddLeftGroupbox("Rainbow")
GbRainbow:AddToggle("RainbowEnabled", {
    Text     = "Rainbow Mode",
    Default  = Settings.Rainbow.Enabled,
    Tooltip  = "Cycles all ESP colors through rainbow",
    Callback = function(v) Settings.Rainbow.Enabled = v end,
})
GbRainbow:AddSlider("RainbowSpeed", {
    Text     = "Speed",
    Default  = Settings.Rainbow.Speed,
    Min      = 1,
    Max      = 10,
    Rounding = 0,
    Callback = function(v) Settings.Rainbow.Speed = v end,
})

-- ── Config Tab ─────────────────────────────
local GbConfig = Tabs.Config:AddLeftGroupbox("Configuration")
GbConfig:AddButton({ Text = "Save Config", Func = SaveConfig })
GbConfig:AddButton({ Text = "Load Config", Func = LoadConfig })
GbConfig:AddLabel("File: UniversalESP_Config.json", true)

-- ── UI Settings Tab ────────────────────────
local GbMenu = Tabs.UI:AddLeftGroupbox("Menu")
GbMenu:AddButton("Unload", function() Library:Unload() end)
GbMenu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI    = true,
    Text    = "Menu keybind",
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

RunService.RenderStepped:Connect(function()
    for _, e in pairs(ESPObjects) do
        pcall(UpdateESP, e)
    end
end)

-- ══════════════════════════════════════════
-- GLOBAL API
-- ══════════════════════════════════════════
getgenv().UniversalESP = {
    Settings   = Settings,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    Destroy    = function()
        for player in pairs(ESPObjects) do
            RemoveESP(player)
        end
        Library:Unload()
    end,
}

print("[Universal ESP Pro Enhanced v3.3] Loaded successfully.")
