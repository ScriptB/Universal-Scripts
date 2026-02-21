-- Universal ESP Pro Enhanced v3.0
-- UI: VapeV4 Library | Full ESP | Config System
-- Toggle GUI: RightShift (VapeV4 default)
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced.lua", true))()

repeat task.wait() until game:IsLoaded()

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local Camera          = workspace.CurrentCamera
local LocalPlayer     = Players.LocalPlayer

-- ══════════════════════════════════════════
-- LOAD VAPE V4 LIBRARY
-- ══════════════════════════════════════════
local GuiLibrary = loadstring(game:HttpGet("https://vxperblx.xyz/NewGuiLibrary.lua", true))()
shared.GuiLibrary = GuiLibrary

-- ══════════════════════════════════════════
-- ESP SETTINGS
-- ══════════════════════════════════════════
local Settings = {
    Enabled    = true,
    TeamCheck  = false,
    TeamColor  = false,
    MaxDist    = 1000,
    Box = {
        Enabled      = true,
        Color        = Color3.fromRGB(255, 255, 255),
        Thickness    = 1,
        Transparency = 1,
        Filled       = false,
    },
    Tracer = {
        Enabled      = true,
        Color        = Color3.fromRGB(255, 255, 255),
        Thickness    = 1,
        Transparency = 1,
        Origin       = "Bottom",
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
        if typeof(v) == "Color3" then o[k] = SerializeColor(v)
        elseif type(v) == "table" then o[k] = DeepSerialize(v)
        else o[k] = v end
    end
    return o
end
local function DeepDeserialize(t)
    local o = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            if v.R ~= nil and v.G ~= nil and v.B ~= nil then o[k] = DeserializeColor(v)
            else o[k] = DeepDeserialize(v) end
        else o[k] = v end
    end
    return o
end

local function SaveConfig()
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(DeepSerialize(Settings)))
    end)
    if ok then print("[ESP] Config saved.") else warn("[ESP] Save failed: " .. tostring(err)) end
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
                    for sk, sv in pairs(v) do Settings[k][sk] = sv end
                else Settings[k] = v end
            end
        end
        print("[ESP] Config loaded.")
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
    if not ok then return { Visible = false, Remove = function() end } end
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
            NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
            NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
            NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
            NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
        },
        Tracer  = NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
        Name    = NewDrawing("Text", { Text=player.Name, Size=14, Center=true, Outline=true, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
        HpBg    = NewDrawing("Line", { Thickness=4, Color=Color3.new(0,0,0), Transparency=0.5, Visible=false }),
        HpBar   = NewDrawing("Line", { Thickness=3, Color=Color3.new(0,1,0), Transparency=1, Visible=false }),
        HpText  = NewDrawing("Text", { Text="100hp", Size=11, Center=true, Outline=true, Color=Color3.new(1,1,1), Transparency=1, Visible=false }),
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

    -- Box
    local bc  = GetColor(player, Settings.Box.Color)
    local bv  = Settings.Enabled and Settings.Box.Enabled
    local bt  = Settings.Box.Thickness
    local btr = Settings.Box.Transparency
    e.Boxes[1].From=tl; e.Boxes[1].To=tr; e.Boxes[1].Color=bc; e.Boxes[1].Thickness=bt; e.Boxes[1].Transparency=btr; e.Boxes[1].Visible=bv
    e.Boxes[2].From=tr; e.Boxes[2].To=br; e.Boxes[2].Color=bc; e.Boxes[2].Thickness=bt; e.Boxes[2].Transparency=btr; e.Boxes[2].Visible=bv
    e.Boxes[3].From=br; e.Boxes[3].To=bl; e.Boxes[3].Color=bc; e.Boxes[3].Thickness=bt; e.Boxes[3].Transparency=btr; e.Boxes[3].Visible=bv
    e.Boxes[4].From=bl; e.Boxes[4].To=tl; e.Boxes[4].Color=bc; e.Boxes[4].Thickness=bt; e.Boxes[4].Transparency=btr; e.Boxes[4].Visible=bv

    -- Tracer
    local tOrigin
    if Settings.Tracer.Origin == "Top" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif Settings.Tracer.Origin == "Center" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
    e.Tracer.From        = tOrigin
    e.Tracer.To          = Vector2.new(cx, cy + h/2)
    e.Tracer.Color       = GetColor(player, Settings.Tracer.Color)
    e.Tracer.Thickness   = Settings.Tracer.Thickness
    e.Tracer.Transparency= Settings.Tracer.Transparency
    e.Tracer.Visible     = Settings.Enabled and Settings.Tracer.Enabled

    -- Name
    local nameStr = player.Name
    if Settings.Name.ShowDistance then nameStr = nameStr .. " [" .. math.floor(dist) .. "m]" end
    if Settings.Name.ShowHealth and hum then nameStr = nameStr .. " [" .. math.floor(hum.Health) .. "hp]" end
    e.Name.Text     = nameStr
    e.Name.Size     = Settings.Name.Size
    e.Name.Color    = GetColor(player, Settings.Name.Color)
    e.Name.Outline  = Settings.Name.Outline
    e.Name.Position = Vector2.new(cx, tl.Y - Settings.Name.Size - 2)
    e.Name.Visible  = Settings.Enabled and Settings.Name.Enabled

    -- Health Bar
    if hum and Settings.Health.Enabled and Settings.Health.ShowBar then
        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bx    = tl.X - 6
        local hColor = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 0)
        e.HpBg.From      = Vector2.new(bx, tl.Y)
        e.HpBg.To        = Vector2.new(bx, bl.Y)
        e.HpBg.Thickness = Settings.Health.Thickness + 1
        e.HpBg.Visible   = Settings.Enabled
        e.HpBar.From     = Vector2.new(bx, bl.Y - (bl.Y - tl.Y) * ratio)
        e.HpBar.To       = Vector2.new(bx, bl.Y)
        e.HpBar.Color    = hColor
        e.HpBar.Thickness= Settings.Health.Thickness
        e.HpBar.Visible  = Settings.Enabled
        if Settings.Health.ShowText then
            e.HpText.Text     = math.floor(hum.Health) .. "hp"
            e.HpText.Position = Vector2.new(bx, tl.Y - 12)
            e.HpText.Visible  = Settings.Enabled
        else
            e.HpText.Visible = false
        end
    else
        e.HpBg.Visible  = false
        e.HpBar.Visible = false
        e.HpText.Visible= false
    end
end

-- ══════════════════════════════════════════
-- BUILD VAPE V4 UI
-- ══════════════════════════════════════════
local GUI     = GuiLibrary.CreateMainWindow()

local ESPWin  = GuiLibrary.CreateWindow({ Name = "ESP",     IconSize = 16 })
local VisWin  = GuiLibrary.CreateWindow({ Name = "Visuals", IconSize = 16 })
local CfgWin  = GuiLibrary.CreateWindow({ Name = "Config",  IconSize = 16 })

-- Sidebar navigation buttons
GUI.CreateDivider()
GUI.CreateButton({ Name = "ESP",     Function = function(cb) ESPWin.SetVisible(cb) end })
GUI.CreateButton({ Name = "Visuals", Function = function(cb) VisWin.SetVisible(cb) end })
GUI.CreateButton({ Name = "Config",  Function = function(cb) CfgWin.SetVisible(cb) end })
GUI.CreateDivider()

-- ── Master Controls (main GUI sidebar section) ────
local MasterSection = GUI.CreateDivider2("Master Controls")

MasterSection.CreateToggle({
    Name     = "ESP Enabled",
    Default  = Settings.Enabled,
    Function = function(v) Settings.Enabled = v end,
    HoverText = "Master toggle for all ESP features",
})

MasterSection.CreateToggle({
    Name     = "Team Check",
    Default  = Settings.TeamCheck,
    Function = function(v) Settings.TeamCheck = v end,
    HoverText = "Hide ESP for teammates",
})

MasterSection.CreateToggle({
    Name     = "Team Color",
    Default  = Settings.TeamColor,
    Function = function(v) Settings.TeamColor = v end,
    HoverText = "Use team color for ESP elements",
})

MasterSection.CreateSlider({
    Name     = "Max Distance",
    Min      = 100,
    Max      = 5000,
    Default  = Settings.MaxDist,
    Function = function(v) Settings.MaxDist = v end,
})

-- ── ESP Window ──────────────────────────────────
ESPWin.CreateToggle({
    Name     = "Box ESP",
    Default  = Settings.Box.Enabled,
    Function = function(v) Settings.Box.Enabled = v end,
})

ESPWin.CreateSlider({
    Name     = "Box Thickness",
    Min      = 1,
    Max      = 5,
    Default  = Settings.Box.Thickness,
    Function = function(v) Settings.Box.Thickness = v end,
})

ESPWin.CreateColorSlider({
    Name     = "Box Color",
    Function = function(h, s, v)
        Settings.Box.Color = Color3.fromHSV(h, s, v)
    end,
})

-- Tracer ESP
ESPWin.CreateToggle({
    Name     = "Tracer ESP",
    Default  = Settings.Tracer.Enabled,
    Function = function(v) Settings.Tracer.Enabled = v end,
})

ESPWin.CreateSlider({
    Name     = "Tracer Thickness",
    Min      = 1,
    Max      = 5,
    Default  = Settings.Tracer.Thickness,
    Function = function(v) Settings.Tracer.Thickness = v end,
})

ESPWin.CreateColorSlider({
    Name     = "Tracer Color",
    Function = function(h, s, v)
        Settings.Tracer.Color = Color3.fromHSV(h, s, v)
    end,
})

ESPWin.CreateDropdown({
    Name     = "Tracer Origin",
    List     = { "Bottom", "Center", "Top" },
    Function = function(v) Settings.Tracer.Origin = v end,
})

-- Name ESP
ESPWin.CreateToggle({
    Name     = "Name ESP",
    Default  = Settings.Name.Enabled,
    Function = function(v) Settings.Name.Enabled = v end,
})

ESPWin.CreateToggle({
    Name     = "Show Distance",
    Default  = Settings.Name.ShowDistance,
    Function = function(v) Settings.Name.ShowDistance = v end,
})

ESPWin.CreateToggle({
    Name     = "Show Health (Name)",
    Default  = Settings.Name.ShowHealth,
    Function = function(v) Settings.Name.ShowHealth = v end,
})

ESPWin.CreateSlider({
    Name     = "Name Size",
    Min      = 10,
    Max      = 24,
    Default  = Settings.Name.Size,
    Function = function(v) Settings.Name.Size = v end,
})

ESPWin.CreateColorSlider({
    Name     = "Name Color",
    Function = function(h, s, v)
        Settings.Name.Color = Color3.fromHSV(h, s, v)
    end,
})

-- Health Bar
ESPWin.CreateToggle({
    Name     = "Health Bar",
    Default  = Settings.Health.Enabled,
    Function = function(v) Settings.Health.Enabled = v end,
})

ESPWin.CreateToggle({
    Name     = "Health Text",
    Default  = Settings.Health.ShowText,
    Function = function(v) Settings.Health.ShowText = v end,
})

ESPWin.CreateSlider({
    Name     = "Health Bar Thickness",
    Min      = 1,
    Max      = 6,
    Default  = Settings.Health.Thickness,
    Function = function(v) Settings.Health.Thickness = v end,
})

-- ── Visuals Window ─────────────────────────
VisWin.CreateToggle({
    Name     = "Rainbow Mode",
    Default  = Settings.Rainbow.Enabled,
    Function = function(v) Settings.Rainbow.Enabled = v end,
    HoverText = "Cycles all ESP colors through rainbow",
})

VisWin.CreateSlider({
    Name     = "Rainbow Speed",
    Min      = 1,
    Max      = 10,
    Default  = Settings.Rainbow.Speed,
    Function = function(v) Settings.Rainbow.Speed = v end,
})

VisWin.CreateToggle({
    Name     = "Name Outline",
    Default  = Settings.Name.Outline,
    Function = function(v) Settings.Name.Outline = v end,
})

-- ── Config Window ──────────────────────────
CfgWin.CreateButton2({
    Name     = "SAVE CONFIG",
    Function = SaveConfig,
})

CfgWin.CreateButton2({
    Name     = "LOAD CONFIG",
    Function = LoadConfig,
})

-- ── GUI Settings (main sidebar) ────────────────
local GUISettings = GUI.CreateDivider2("GUI Settings")

GUISettings.CreateToggle({
    Name     = "Show Tooltips",
    Default  = true,
    Function = function(v) GuiLibrary.ToggleTooltips = v end,
    HoverText = "Toggles visibility of hover tooltips",
})

GUISettings.CreateToggle({
    Name     = "Notifications",
    Default  = true,
    Function = function(v) GuiLibrary.Notifications = v end,
    HoverText = "Shows notifications",
})

GUI.CreateColorSlider("GUI Theme", function(h, s, v)
    GuiLibrary.UpdateUI(h, s, v)
end)

GUI.CreateGUIBind()

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
        for player, _ in pairs(ESPObjects) do
            RemoveESP(player)
        end
        GuiLibrary.SelfDestruct()
    end,
}

print("[Universal ESP Pro Enhanced v3.0] Loaded successfully.")
