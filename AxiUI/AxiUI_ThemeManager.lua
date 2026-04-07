-- ══════════════════════════════════════════════════════════════
--  AxiUI — ThemeManager Module
-- ══════════════════════════════════════════════════════════════
local _env = (typeof(getgenv) == "function" and getgenv()) or _G
local Library     = _env.Library or {}
local Utils       = Library.Utils

-- ── Default Theme (Unique dark-violet / electric-cyan) ────────
local Theme = {
    Background  = Color3.fromRGB(10,  10,  18),
    Panel       = Color3.fromRGB(16,  16,  28),
    PanelAlt    = Color3.fromRGB(22,  22,  38),
    PanelDeep   = Color3.fromRGB(13,  13,  23),
    Element     = Color3.fromRGB(28,  28,  48),
    ElementHov  = Color3.fromRGB(36,  36,  62),
    ElementAct  = Color3.fromRGB(44,  44,  74),
    Accent      = Color3.fromRGB(82,  210, 255),
    AccentDim   = Color3.fromRGB(40,  120, 160),
    AccentGlow  = Color3.fromRGB(120, 230, 255),
    Violet      = Color3.fromRGB(140, 100, 255),
    VioletDim   = Color3.fromRGB(80,  55,  160),
    Gold        = Color3.fromRGB(255, 200, 80),
    Text        = Color3.fromRGB(225, 225, 240),
    SubText     = Color3.fromRGB(130, 130, 165),
    MutedText   = Color3.fromRGB(70,  70,  100),
    Border      = Color3.fromRGB(42,  42,  70),
    BorderBright= Color3.fromRGB(65,  65,  100),
    ToggleOff   = Color3.fromRGB(44,  44,  72),
    ToggleOn    = Color3.fromRGB(82,  210, 255),
    SliderTrack = Color3.fromRGB(28,  28,  50),
    SliderFill  = Color3.fromRGB(82,  210, 255),
    SliderKnob  = Color3.fromRGB(240, 240, 255),
    Danger      = Color3.fromRGB(240, 72,  72),
    Success     = Color3.fromRGB(72,  215, 135),
    Warning     = Color3.fromRGB(255, 200, 70),
    Info        = Color3.fromRGB(82,  210, 255),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
    Transparent = Color3.fromRGB(0,   0,   0),
    TitleLeft   = Color3.fromRGB(18,  18,  34),
    TitleRight  = Color3.fromRGB(24,  16,  44),
}

-- ── Preset Themes ─────────────────────────────────────────────
local Themes = {
    Default = (function() local t={} for k,v in pairs(Theme) do t[k]=v end return t end)(),
    Ocean = {
        Background = Color3.fromRGB(6, 14, 22), Panel = Color3.fromRGB(10, 20, 34), PanelAlt = Color3.fromRGB(14, 26, 44), PanelDeep = Color3.fromRGB(8, 16, 26),
        Element = Color3.fromRGB(16, 30, 52), ElementHov = Color3.fromRGB(22, 40, 68), ElementAct = Color3.fromRGB(28, 50, 82),
        Accent = Color3.fromRGB(50, 200, 180), AccentDim = Color3.fromRGB(28, 110, 100), AccentGlow = Color3.fromRGB(90, 230, 210),
        Violet = Color3.fromRGB(60, 160, 220), VioletDim = Color3.fromRGB(30, 90, 130), Gold = Color3.fromRGB(255, 210, 90),
        Text = Color3.fromRGB(210, 230, 235), SubText = Color3.fromRGB(100, 140, 155), MutedText = Color3.fromRGB(55, 80, 95),
        Border = Color3.fromRGB(28, 50, 72), BorderBright = Color3.fromRGB(50, 80, 110), ToggleOff = Color3.fromRGB(22, 48, 72), ToggleOn = Color3.fromRGB(50, 200, 180),
        SliderTrack = Color3.fromRGB(16, 36, 58), SliderFill = Color3.fromRGB(50, 200, 180), SliderKnob = Color3.fromRGB(220, 245, 245),
        Danger = Color3.fromRGB(240, 72, 72), Success = Color3.fromRGB(60, 210, 140), Warning = Color3.fromRGB(240, 190, 60), Info = Color3.fromRGB(50, 200, 180),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(10, 22, 38), TitleRight = Color3.fromRGB(12, 28, 50),
    },
    Rose = {
        Background = Color3.fromRGB(18, 10, 16), Panel = Color3.fromRGB(28, 14, 24), PanelAlt = Color3.fromRGB(36, 18, 32), PanelDeep = Color3.fromRGB(22, 12, 20),
        Element = Color3.fromRGB(44, 22, 40), ElementHov = Color3.fromRGB(58, 28, 52), ElementAct = Color3.fromRGB(70, 34, 62),
        Accent = Color3.fromRGB(255, 110, 160), AccentDim = Color3.fromRGB(150, 60, 100), AccentGlow = Color3.fromRGB(255, 150, 190),
        Violet = Color3.fromRGB(200, 80, 230), VioletDim = Color3.fromRGB(110, 44, 130), Gold = Color3.fromRGB(255, 200, 80),
        Text = Color3.fromRGB(240, 220, 230), SubText = Color3.fromRGB(160, 110, 140), MutedText = Color3.fromRGB(90, 55, 80),
        Border = Color3.fromRGB(68, 30, 58), BorderBright = Color3.fromRGB(100, 48, 86), ToggleOff = Color3.fromRGB(58, 26, 50), ToggleOn = Color3.fromRGB(255, 110, 160),
        SliderTrack = Color3.fromRGB(44, 22, 40), SliderFill = Color3.fromRGB(255, 110, 160), SliderKnob = Color3.fromRGB(255, 235, 245),
        Danger = Color3.fromRGB(255, 70, 70), Success = Color3.fromRGB(80, 220, 130), Warning = Color3.fromRGB(255, 200, 80), Info = Color3.fromRGB(255, 110, 160),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(28, 14, 26), TitleRight = Color3.fromRGB(40, 16, 36),
    },
    Raycast = {
        Background = Color3.fromRGB(15, 15, 20), Panel = Color3.fromRGB(24, 25, 34), PanelAlt = Color3.fromRGB(31, 33, 48), PanelDeep = Color3.fromRGB(22, 24, 37),
        Element = Color3.fromRGB(20, 22, 36), ElementHov = Color3.fromRGB(32, 35, 56), ElementAct = Color3.fromRGB(42, 45, 65),
        Accent = Color3.fromRGB(255, 46, 99), AccentDim = Color3.fromRGB(224, 38, 88), AccentGlow = Color3.fromRGB(0, 229, 168),
        Violet = Color3.fromRGB(108, 99, 255), VioletDim = Color3.fromRGB(90, 82, 224), Gold = Color3.fromRGB(255, 176, 32),
        Text = Color3.fromRGB(245, 247, 255), SubText = Color3.fromRGB(184, 190, 214), MutedText = Color3.fromRGB(122, 128, 153),
        Border = Color3.fromRGB(42, 45, 61), BorderBright = Color3.fromRGB(47, 51, 74), ToggleOff = Color3.fromRGB(42, 45, 61), ToggleOn = Color3.fromRGB(255, 46, 99),
        SliderTrack = Color3.fromRGB(35, 37, 54), SliderFill = Color3.fromRGB(255, 46, 99), SliderKnob = Color3.fromRGB(245, 247, 255),
        Danger = Color3.fromRGB(255, 59, 59), Success = Color3.fromRGB(0, 230, 118), Warning = Color3.fromRGB(255, 176, 32), Info = Color3.fromRGB(108, 99, 255),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(22, 24, 37), TitleRight = Color3.fromRGB(31, 33, 48),
    },
    Carbon = {
        Background = Color3.fromRGB(10, 10, 10), Panel = Color3.fromRGB(18, 18, 18), PanelAlt = Color3.fromRGB(26, 26, 26), PanelDeep = Color3.fromRGB(13, 13, 13),
        Element = Color3.fromRGB(30, 30, 30), ElementHov = Color3.fromRGB(42, 42, 42), ElementAct = Color3.fromRGB(55, 55, 55),
        Accent = Color3.fromRGB(228, 228, 228), AccentDim = Color3.fromRGB(165, 165, 165), AccentGlow = Color3.fromRGB(255, 255, 255),
        Violet = Color3.fromRGB(140, 140, 255), VioletDim = Color3.fromRGB(90, 90, 200), Gold = Color3.fromRGB(255, 198, 60),
        Text = Color3.fromRGB(235, 235, 235), SubText = Color3.fromRGB(155, 155, 155), MutedText = Color3.fromRGB(88, 88, 88),
        Border = Color3.fromRGB(44, 44, 44), BorderBright = Color3.fromRGB(62, 62, 62), ToggleOff = Color3.fromRGB(44, 44, 44), ToggleOn = Color3.fromRGB(228, 228, 228),
        SliderTrack = Color3.fromRGB(26, 26, 26), SliderFill = Color3.fromRGB(228, 228, 228), SliderKnob = Color3.fromRGB(16, 16, 16),
        Danger = Color3.fromRGB(255, 65, 65), Success = Color3.fromRGB(60, 220, 110), Warning = Color3.fromRGB(255, 185, 35), Info = Color3.fromRGB(100, 185, 255),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(16, 16, 16), TitleRight = Color3.fromRGB(26, 26, 26),
    },
    Midnight = {
        Background = Color3.fromRGB(4, 8, 22), Panel = Color3.fromRGB(8, 14, 34), PanelAlt = Color3.fromRGB(12, 20, 46), PanelDeep = Color3.fromRGB(6, 10, 26),
        Element = Color3.fromRGB(14, 24, 54), ElementHov = Color3.fromRGB(20, 34, 70), ElementAct = Color3.fromRGB(28, 46, 90),
        Accent = Color3.fromRGB(115, 155, 255), AccentDim = Color3.fromRGB(75, 105, 200), AccentGlow = Color3.fromRGB(160, 195, 255),
        Violet = Color3.fromRGB(165, 105, 255), VioletDim = Color3.fromRGB(110, 68, 195), Gold = Color3.fromRGB(255, 212, 80),
        Text = Color3.fromRGB(218, 228, 255), SubText = Color3.fromRGB(125, 145, 200), MutedText = Color3.fromRGB(65, 82, 130),
        Border = Color3.fromRGB(22, 36, 82), BorderBright = Color3.fromRGB(34, 52, 112), ToggleOff = Color3.fromRGB(18, 30, 68), ToggleOn = Color3.fromRGB(115, 155, 255),
        SliderTrack = Color3.fromRGB(12, 22, 52), SliderFill = Color3.fromRGB(115, 155, 255), SliderKnob = Color3.fromRGB(218, 228, 255),
        Danger = Color3.fromRGB(255, 72, 92), Success = Color3.fromRGB(58, 220, 140), Warning = Color3.fromRGB(255, 192, 52), Info = Color3.fromRGB(100, 182, 255),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(6, 12, 30), TitleRight = Color3.fromRGB(14, 24, 54),
    },
    Emerald = {
        Background = Color3.fromRGB(6, 14, 10), Panel = Color3.fromRGB(10, 22, 16), PanelAlt = Color3.fromRGB(14, 30, 22), PanelDeep = Color3.fromRGB(8, 16, 12),
        Element = Color3.fromRGB(16, 36, 26), ElementHov = Color3.fromRGB(22, 48, 34), ElementAct = Color3.fromRGB(30, 62, 44),
        Accent = Color3.fromRGB(48, 218, 138), AccentDim = Color3.fromRGB(30, 152, 92), AccentGlow = Color3.fromRGB(88, 255, 168),
        Violet = Color3.fromRGB(96, 178, 255), VioletDim = Color3.fromRGB(58, 118, 200), Gold = Color3.fromRGB(255, 210, 58),
        Text = Color3.fromRGB(212, 240, 222), SubText = Color3.fromRGB(118, 162, 138), MutedText = Color3.fromRGB(62, 98, 78),
        Border = Color3.fromRGB(24, 54, 38), BorderBright = Color3.fromRGB(36, 76, 54), ToggleOff = Color3.fromRGB(20, 46, 32), ToggleOn = Color3.fromRGB(48, 218, 138),
        SliderTrack = Color3.fromRGB(12, 28, 20), SliderFill = Color3.fromRGB(48, 218, 138), SliderKnob = Color3.fromRGB(212, 240, 222),
        Danger = Color3.fromRGB(255, 72, 80), Success = Color3.fromRGB(48, 218, 138), Warning = Color3.fromRGB(255, 196, 50), Info = Color3.fromRGB(58, 182, 255),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0), Transparent = Color3.fromRGB(0, 0, 0),
        TitleLeft = Color3.fromRGB(8, 18, 13), TitleRight = Color3.fromRGB(16, 34, 24),
    }
}

-- ── ThemeManager Object ───────────────────────────────────────
local ThemeManager = { _themeFolder = "AxiUI_Themes" }

function ThemeManager:Init()
    if typeof(makefolder) == "function" and not isfolder(self._themeFolder) then makefolder(self._themeFolder) end
end

function ThemeManager:SaveTheme(name, themeTable)
    self:Init()
    Utils.SafeWrite(self._themeFolder .. "/" .. name .. ".json", Utils.SafeJSON(themeTable))
end

function ThemeManager:LoadTheme(name)
    self:Init()
    local data = Utils.SafeRead(self._themeFolder .. "/" .. name .. ".json")
    return data and Utils.SafeParse(data) or nil
end

function ThemeManager:DeleteTheme(name)
    self:Init()
    Utils.SafeDelete(self._themeFolder .. "/" .. name .. ".json")
end

function ThemeManager:ListThemes()
    self:Init()
    local files = Utils.SafeList(self._themeFolder)
    local out = {}
    for _, f in ipairs(files) do local n = f:match("([^/\\]+)%.json$") if n then table.insert(out, n) end end
    return out
end

function ThemeManager:GetNames() return Library:GetThemeNames() end
function ThemeManager:Apply(name) Library:SetTheme(name) end

-- ── Integration functions ─────────────────────────────────────
local function repaintTree(root, oldMap, activeTheme)
    local props = { "BackgroundColor3", "TextColor3", "ImageColor3" }
    local function c2s(c) return math.floor(c.R*255+0.5)..","..math.floor(c.G*255+0.5)..","..math.floor(c.B*255+0.5) end
    
    local stack = { root }
    while #stack > 0 do
        local inst = table.remove(stack)
        pcall(function()
            for _, prop in ipairs(props) do
                local ok, v = pcall(function() return inst[prop] end)
                if ok and typeof(v) == "Color3" then
                    local key = oldMap[c2s(v)]
                    if key then pcall(function() inst[prop] = activeTheme[key] end) end
                end
            end
            local sk = inst:FindFirstChildOfClass("UIStroke")
            if sk then
                local ok, v = pcall(function() return sk.Color end)
                if ok then local key = oldMap[c2s(v)] if key then sk.Color = activeTheme[key] end end
            end
            local gd = inst:FindFirstChildOfClass("UIGradient")
            if gd then
                pcall(function()
                    local kps = gd.Color.Keypoints
                    local changed, newKps = false, {}
                    for i, kp in ipairs(kps) do
                        local key = oldMap[c2s(kp.Value)]
                        newKps[i] = ColorSequenceKeypoint.new(kp.Time, key and activeTheme[key] or kp.Value)
                        if key then changed = true end
                    end
                    if changed then gd.Color = ColorSequence.new(newKps) end
                end)
            end
        end)
        for _, child in ipairs(inst:GetChildren()) do table.insert(stack, child) end
    end
end

-- ── Library Methods ───────────────────────────────────────────
function Library:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    if self._themeSwitching then return end
    self._themeSwitching = true

    local function c2s(c) return math.floor(c.R*255+0.5)..","..math.floor(c.G*255+0.5)..","..math.floor(c.B*255+0.5) end
    local oldMap = {}
    for k, v in pairs(Library.Theme) do oldMap[c2s(v)] = k end

    -- Update the active theme
    for k, v in pairs(t) do Library.Theme[k] = v end

    for _, w in ipairs(Library._windows or {}) do pcall(function() repaintTree(w._sg, oldMap, Library.Theme) end) end
    if Library._wmSG then pcall(function() repaintTree(Library._wmSG, oldMap, Library.Theme) end) end
    if Library._kbSG then pcall(function() repaintTree(Library._kbSG, oldMap, Library.Theme) end) end
    if Library._notifSG then pcall(function() repaintTree(Library._notifSG, oldMap, Library.Theme) end) end

    if self._onThemeChanged then for _, fn in ipairs(self._onThemeChanged) do pcall(fn, name) end end
    self._themeSwitching = false
end

function Library:OnThemeChanged(fn) self._onThemeChanged = self._onThemeChanged or {} table.insert(self._onThemeChanged, fn) end
function Library:GetThemeNames() local n = {} for k in pairs(Themes) do table.insert(n, k) end return n end
function Library:GetTheme() return self._theme or Theme end
function Library:GetThemeValue(key) return (self._theme or Theme)[key] end

-- ── UI Builder ────────────────────────────────────────────────
function ThemeManager:BuildUI(gb)
    if not gb then return end
    local themeDD = gb:AddDropdown("TM_ThemePicker", {
        Text     = "Active Theme",
        Values   = self:GetNames(),
        Default  = self._current,
        Callback = function(v) self:Apply(v) end,
    })
    gb:AddButton({ Text = "Refresh Themes", Callback = function() themeDD:SetValues(self:GetNames()) end })
    gb:AddButton({ Text = "Save Theme", Callback = function() self:SaveTheme("custom", Library:GetTheme()) end })
end

-- Attach to Library
Library.ThemeManager = ThemeManager
Library.Themes       = Themes

-- Initialize Default
if not next(Library.Theme) then Library:SetTheme("Default") end

return ThemeManager
