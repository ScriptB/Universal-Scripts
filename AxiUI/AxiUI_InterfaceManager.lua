--[[
    AxiUI — InterfaceManager v1.0.0
    Requires AxiUI_Framework to be loaded first.

    Provides:
        SaveManager      — folder-aware config save/load
        Watermark        — floating top-centre label
        KeybindOverlay   — bottom-left keybind list panel
        Dialog           — modal confirm/dialog overlay
        CommandPalette   — searchable command launcher
        Localization     — string table i18n

    Usage:
        local Managers = loadstring(game:HttpGet("...AxiUI_InterfaceManager.lua"))()
        -- or access via AxiUI.SaveManager, AxiUI.Watermark, etc.
]]

local _env  = (typeof(getgenv) == "function" and getgenv()) or _G
local AxiUI = _env.AxiUI
assert(AxiUI, "[AxiUI] InterfaceManager: AxiUI_Framework must be loaded first.")

local TweenSvc   = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local HttpSvc    = game:GetService("HttpService")

local T = AxiUI.Theme

-- ─── LOCAL HELPERS ───────────────────────────────────────────────
local function Tw(obj, props, t)
    TweenSvc:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart), props):Play()
end

local function SafeParent(gui)
    local ok = pcall(function()
        if typeof(gethui) == "function" then gui.Parent = gethui()
        else gui.Parent = game:GetService("CoreGui") end
    end)
    if not ok or not gui.Parent then
        gui.Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
            or Players.LocalPlayer.PlayerGui
    end
end

local function Rnd(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = inst
    return c
end

local function Strk(inst, col, alpha, thick)
    local s = Instance.new("UIStroke")
    s.Color           = col   or T.Border
    s.Transparency    = 1 - (alpha or 0.08)
    s.Thickness       = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = inst
    return s
end

local function Lst(inst, pad, dir, hAlign)
    local l = Instance.new("UIListLayout")
    l.Padding            = UDim.new(0, pad or 4)
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.FillDirection      = dir or Enum.FillDirection.Vertical
    if hAlign then l.HorizontalAlignment = hAlign end
    l.Parent = inst
    return l
end

local function Pd(inst, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent = inst
end

local function Lbl(parent, text, size, color, xAlign, font)
    local l = Instance.new("TextLabel")
    l.Text                  = text or ""
    l.Font                  = font  or Enum.Font.GothamMedium
    l.TextSize              = size  or 11
    l.TextColor3            = color or T.TextSecondary
    l.BackgroundTransparency = 1
    l.BorderSizePixel       = 0
    l.TextXAlignment        = xAlign or Enum.TextXAlignment.Left
    l.Parent                = parent
    return l
end

-- ═══════════════════════════════════════════════════════════════
--  SAVE MANAGER
--  Folder-aware config save / load using AxiUI.Flags directly.
-- ═══════════════════════════════════════════════════════════════
local SaveManager = {
    _folder       = "AxiUI_Configs",
    _autoloadName = nil,
    _autoConn     = nil,
}

function SaveManager:SetFolder(path)
    self._folder = path
end

local function serializeFlags()
    local data = {}
    for k, v in pairs(AxiUI.Flags) do
        if not k:find("_obj$") then
            local t = type(v)
            if t == "boolean" or t == "number" or t == "string" then
                data[k] = v
            elseif typeof(v) == "EnumItem" then
                data[k] = { __enum = tostring(v) }
            elseif typeof(v) == "Color3" then
                data[k] = { __col = true, r = v.R, g = v.G, b = v.B }
            end
        end
    end
    return data
end

local function applyFlagData(data)
    for k, v in pairs(data) do
        local obj = AxiUI.Flags[k .. "_obj"]
        if obj and obj.Set then
            if type(v) == "table" and v.__col then
                pcall(obj.Set, obj, Color3.new(v.r, v.g, v.b))
            elseif type(v) == "table" and v.__enum then
                pcall(function()
                    local parts = v.__enum:split(".")
                    pcall(obj.Set, obj, (Enum :: any)[parts[2]][parts[3]])
                end)
            else
                pcall(obj.Set, obj, v)
            end
        end
    end
end

function SaveManager:Save(name)
    pcall(function()
        if typeof(makefolder) == "function" then
            if not isfolder(self._folder) then makefolder(self._folder) end
        end
    end)
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    local ok   = pcall(writefile, path, HttpSvc:JSONEncode(serializeFlags()))
    return ok
end

function SaveManager:Load(name)
    local path = self._folder .. "/" .. (name or "default") .. ".json"
    if typeof(isfile) == "function" and not isfile(path) then return false end
    local ok, raw = pcall(readfile, path)
    if not ok then return false end
    local ok2, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
    if not ok2 then return false end
    applyFlagData(data)
    return true
end

function SaveManager:ListConfigs()
    local out = {}
    pcall(function()
        if typeof(listfiles) == "function" and isfolder(self._folder) then
            for _, f in ipairs(listfiles(self._folder)) do
                local n = f:match("([^/\\]+)%.json$")
                if n then out[#out+1] = n end
            end
        end
    end)
    return out
end

function SaveManager:SetAutoload(name)
    self._autoloadName = name
end

function SaveManager:LoadAutoloadConfig()
    if self._autoloadName then return self:Load(self._autoloadName) end
    for _, n in ipairs(self:ListConfigs()) do
        if n:lower():find("autoload", 1, true) then return self:Load(n) end
    end
    return false
end

function SaveManager:AutoSave(interval, name)
    if self._autoConn then self._autoConn:Disconnect(); self._autoConn = nil end
    if not interval or interval <= 0 then return end
    local elapsed = 0
    self._autoConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= interval then elapsed = 0; self:Save(name or "autosave") end
    end)
end

function SaveManager:BuildConfigSection(tab)
    local gb = tab:AddGroupbox("Configs")
    gb:AddInput("IM_CfgName", { Text = "Config Name", Default = "default", Placeholder = "name" })
    gb:AddButton({ Text = "Save Config", Callback = function()
        local n = AxiUI.Flags["IM_CfgName"] or "default"
        local ok = self:Save(n)
        AxiUI:Notify("Config", ok and ("Saved: " .. n) or "Save failed", 3)
    end })
    gb:AddButton({ Text = "Load Config", Callback = function()
        local n = AxiUI.Flags["IM_CfgName"] or "default"
        local ok = self:Load(n)
        AxiUI:Notify("Config", ok and ("Loaded: " .. n) or "Not found", 3)
    end })
    gb:AddButton({ Text = "Autoload this", Callback = function()
        local n = AxiUI.Flags["IM_CfgName"] or "default"
        self:SetAutoload(n)
        AxiUI:Notify("Config", "Autoloading: " .. n, 3)
    end })
end

-- ═══════════════════════════════════════════════════════════════
--  WATERMARK
--  Floating top-centre label. Reads from T live so theme changes
--  don't require a watermark rebuild.
-- ═══════════════════════════════════════════════════════════════
local Watermark = {}

function Watermark:_init()
    if self._sg and self._sg.Parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "AxiUI_Watermark"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9998
    SafeParent(sg)

    local frame = Instance.new("Frame")
    frame.BackgroundColor3       = T.WindowBg
    frame.BackgroundTransparency = 1 - 0.88
    frame.AnchorPoint            = Vector2.new(0.5, 0)
    frame.Position               = UDim2.new(0.5, 0, 0, 6)
    frame.Size                   = UDim2.new(0, 0, 0, 22)
    frame.AutomaticSize          = Enum.AutomaticSize.X
    frame.BorderSizePixel        = 0
    frame.Parent                 = sg
    Rnd(frame, UDim.new(0, 7))
    Strk(frame, T.Accent, 0.20, 1)
    Pd(frame, 0, 0, 12, 12)

    local lbl = Instance.new("TextLabel")
    lbl.Text                  = "AxiUI"
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 12
    lbl.TextColor3            = T.AccentStrong
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel       = 0
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Size                  = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize         = Enum.AutomaticSize.X
    lbl.Parent                = frame

    self._sg    = sg
    self._frame = frame
    self._lbl   = lbl
end

function Watermark:Set(text)
    self:_init()
    self._lbl.Text = tostring(text or "AxiUI")
end

function Watermark:SetWithGame(prefix)
    local MPS  = game:GetService("MarketplaceService")
    local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
    local game_name = (ok and info and info.Name) or "Game"
    local parts = {}
    if prefix and prefix ~= "" then parts[#parts+1] = tostring(prefix) end
    parts[#parts+1] = game_name
    self:Set(table.concat(parts, "  ·  "))
end

function Watermark:SetVisible(v)
    self:_init()
    self._sg.Enabled = v == true
end

-- ═══════════════════════════════════════════════════════════════
--  KEYBIND OVERLAY
--  Bottom-left panel listing named keybinds. Call Register() to
--  add or update an entry; call SetVisible() to show/hide.
-- ═══════════════════════════════════════════════════════════════
local KeybindOverlay = { _keybinds = {} }

function KeybindOverlay:_init()
    if self._sg and self._sg.Parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "AxiUI_KeybindOverlay"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9997
    SafeParent(sg)

    local frame = Instance.new("Frame")
    frame.BackgroundColor3       = T.WindowBg
    frame.BackgroundTransparency = 1 - 0.88
    frame.AnchorPoint            = Vector2.new(0, 1)
    frame.Position               = UDim2.new(0, 6, 1, -6)
    frame.Size                   = UDim2.new(0, 172, 0, 0)
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.BorderSizePixel        = 0
    frame.Parent                 = sg
    Rnd(frame, UDim.new(0, 7))
    Strk(frame, T.Border, 0.08, 1)
    Pd(frame, 6, 6, 8, 8)
    Lst(frame, 3)

    local hdr = Lbl(frame, "KEYBINDS", 9, T.TextMuted,
        Enum.TextXAlignment.Left, Enum.Font.GothamBold)
    hdr.Size = UDim2.new(1, 0, 0, 12)

    self._sg    = sg
    self._frame = frame
end

local function kName(k)
    if k == nil or k == Enum.KeyCode.Unknown then return "—" end
    if k == Enum.UserInputType.MouseButton1   then return "MB1" end
    if k == Enum.UserInputType.MouseButton2   then return "MB2" end
    return typeof(k) == "EnumItem" and k.Name or tostring(k)
end

function KeybindOverlay:Register(idx, key)
    self:_init()
    -- Update existing entry
    if self._keybinds[idx] then
        self._keybinds[idx].key = key
        if self._keybinds[idx].keyLbl then
            self._keybinds[idx].keyLbl.Text = "[" .. kName(key) .. "]"
        end
        return
    end
    -- New row
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.BorderSizePixel        = 0
    row.Size                   = UDim2.new(1, 0, 0, 15)
    row.Parent                 = self._frame

    local nameLbl = Lbl(row, tostring(idx), 10, T.TextSecondary)
    nameLbl.Size = UDim2.new(0.60, 0, 1, 0)

    local keyLbl = Lbl(row, "[" .. kName(key) .. "]", 10, T.Accent,
        Enum.TextXAlignment.Right)
    keyLbl.Size     = UDim2.new(0.40, 0, 1, 0)
    keyLbl.Position = UDim2.new(0.60, 0, 0, 0)

    self._keybinds[idx] = { key = key, row = row, keyLbl = keyLbl }
end

function KeybindOverlay:Remove(idx)
    local entry = self._keybinds[idx]
    if entry and entry.row then
        pcall(function() entry.row:Destroy() end)
    end
    self._keybinds[idx] = nil
end

function KeybindOverlay:SetVisible(v)
    self:_init()
    self._sg.Enabled = v == true
end

-- ═══════════════════════════════════════════════════════════════
--  DIALOG / CONFIRM
--  Modal overlay with title, body text, and action buttons.
-- ═══════════════════════════════════════════════════════════════
local Dialog = {}

function Dialog:Open(opts)
    opts = opts or {}

    local sg = Instance.new("ScreenGui")
    sg.Name           = "AxiUI_Dialog"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 10000
    SafeParent(sg)

    local backdrop = Instance.new("TextButton")
    backdrop.Text                  = ""
    backdrop.AutoButtonColor       = false
    backdrop.BackgroundColor3      = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.Size                  = UDim2.new(1, 0, 1, 0)
    backdrop.BorderSizePixel       = 0
    backdrop.Parent                = sg

    local card = Instance.new("Frame")
    card.BackgroundColor3       = T.WindowBg
    card.BackgroundTransparency = 1
    card.AnchorPoint            = Vector2.new(0.5, 0.5)
    card.Position               = UDim2.new(0.5, 0, 0.5, 0)
    card.Size                   = UDim2.new(0, 370, 0, 0)
    card.AutomaticSize          = Enum.AutomaticSize.Y
    card.BorderSizePixel        = 0
    card.Parent                 = backdrop
    Rnd(card, UDim.new(0, 10))
    Strk(card, T.Accent, 0.22, 1)

    -- Header
    local hdr = Instance.new("Frame")
    hdr.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    hdr.BackgroundTransparency = 0.97
    hdr.BorderSizePixel        = 0
    hdr.Size                   = UDim2.new(1, 0, 0, 32)
    hdr.Parent                 = card
    Rnd(hdr, UDim.new(0, 10))
    -- Fill lower half so corners don't bleed into body
    local hdrFill = Instance.new("Frame")
    hdrFill.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    hdrFill.BackgroundTransparency = 0.97
    hdrFill.BorderSizePixel        = 0
    hdrFill.Size                   = UDim2.new(1, 0, 0.5, 0)
    hdrFill.Position               = UDim2.new(0, 0, 0.5, 0)
    hdrFill.Parent                 = hdr

    local titleLbl = Lbl(hdr, opts.Title or "Dialog", 12, T.TextPrimary,
        Enum.TextXAlignment.Left, Enum.Font.GothamBold)
    titleLbl.Size     = UDim2.new(1, -24, 1, 0)
    titleLbl.Position = UDim2.fromOffset(12, 0)

    local hdrDiv = Instance.new("Frame")
    hdrDiv.BackgroundColor3       = T.Border
    hdrDiv.BackgroundTransparency = 1 - T.BorderAlpha
    hdrDiv.BorderSizePixel        = 0
    hdrDiv.Size                   = UDim2.new(1, 0, 0, 1)
    hdrDiv.Position               = UDim2.new(0, 0, 1, -1)
    hdrDiv.Parent                 = hdr

    -- Body
    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.BorderSizePixel        = 0
    body.Position               = UDim2.fromOffset(0, 32)
    body.Size                   = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize          = Enum.AutomaticSize.Y
    body.Parent                 = card
    Pd(body, 10, 12, 14, 14)
    Lst(body, 10)

    local contentLbl = Lbl(body, opts.Content or "", 11, T.TextSecondary)
    contentLbl.Size           = UDim2.new(1, 0, 0, 0)
    contentLbl.AutomaticSize  = Enum.AutomaticSize.Y
    contentLbl.TextWrapped    = true

    -- Button row
    local btnRow = Instance.new("Frame")
    btnRow.BackgroundTransparency = 1
    btnRow.BorderSizePixel        = 0
    btnRow.Size                   = UDim2.new(1, 0, 0, 28)
    btnRow.Parent                 = body
    Lst(btnRow, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    local function close()
        Tw(backdrop, { BackgroundTransparency = 1 }, 0.14)
        Tw(card,     { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() pcall(function() sg:Destroy() end) end)
    end

    for _, b in ipairs(opts.Buttons or {{ Text = "OK" }}) do
        local btn = Instance.new("TextButton")
        btn.Text                  = b.Text or "OK"
        btn.Font                  = Enum.Font.GothamMedium
        btn.TextSize              = 11
        btn.TextColor3            = T.AccentStrong
        btn.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.94
        btn.BorderSizePixel       = 0
        btn.AutoButtonColor       = false
        btn.Size                  = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize         = Enum.AutomaticSize.X
        btn.Parent                = btnRow
        Rnd(btn, UDim.new(0, 5))
        Pd(btn, 0, 0, 10, 10)
        Strk(btn, T.Accent, 0.22, 1)
        btn.MouseEnter:Connect(function()  Tw(btn, { BackgroundTransparency = 0.85 }, 0.1) end)
        btn.MouseLeave:Connect(function()  Tw(btn, { BackgroundTransparency = 0.94 }, 0.1) end)
        btn.MouseButton1Click:Connect(function()
            pcall(b.Callback or function() end)
            close()
        end)
    end

    backdrop.MouseButton1Click:Connect(close)

    -- Animate in
    task.defer(function()
        Tw(backdrop, { BackgroundTransparency = 0.52 }, 0.15)
        Tw(card,     { BackgroundTransparency = 1 - 0.92 }, 0.15)
    end)

    return { Close = close }
end

function Dialog:Confirm(opts)
    opts = opts or {}
    return self:Open({
        Title   = opts.Title   or "Confirm",
        Content = opts.Content or "Are you sure?",
        Buttons = {
            { Text = opts.ConfirmText or "Confirm", Callback = opts.OnConfirm },
            { Text = opts.CancelText  or "Cancel",  Callback = opts.OnCancel  },
        },
    })
end

-- ═══════════════════════════════════════════════════════════════
--  COMMAND PALETTE
--  RightCtrl (or call :Open()) to search and run commands.
-- ═══════════════════════════════════════════════════════════════
local CommandPalette = { _commands = {}, _sg = nil }

function CommandPalette:Register(name, desc, callback)
    table.insert(self._commands, { Name = name, Desc = desc, Callback = callback })
end

function CommandPalette:Open()
    -- Toggle: second call closes
    if self._sg then
        pcall(function() self._sg:Destroy() end)
        self._sg = nil
        return
    end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "AxiUI_CommandPalette"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 10001
    SafeParent(sg)
    self._sg = sg

    local backdrop = Instance.new("TextButton")
    backdrop.Text                  = ""
    backdrop.AutoButtonColor       = false
    backdrop.BackgroundColor3      = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.55
    backdrop.Size                  = UDim2.new(1, 0, 1, 0)
    backdrop.BorderSizePixel       = 0
    backdrop.Parent                = sg

    local frame = Instance.new("Frame")
    frame.BackgroundColor3       = T.WindowBg
    frame.BackgroundTransparency = 1 - 0.94
    frame.AnchorPoint            = Vector2.new(0.5, 0)
    frame.Position               = UDim2.new(0.5, 0, 0.10, 0)
    frame.Size                   = UDim2.new(0, 420, 0, 0)
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.BorderSizePixel        = 0
    frame.Parent                 = backdrop
    Rnd(frame, UDim.new(0, 8))
    Strk(frame, T.Accent, 0.20, 1)
    Pd(frame, 8, 8, 8, 8)
    Lst(frame, 6)

    local box = Instance.new("TextBox")
    box.Text              = ""
    box.PlaceholderText   = "Search commands…"
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 13
    box.TextColor3        = T.TextPrimary
    box.PlaceholderColor3 = T.TextMuted
    box.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    box.BackgroundTransparency = 0.94
    box.BorderSizePixel   = 0
    box.ClearTextOnFocus  = false
    box.Size              = UDim2.new(1, 0, 0, 32)
    box.Parent            = frame
    Rnd(box, UDim.new(0, 6))
    Pd(box, 0, 0, 10, 10)
    Strk(box, T.Border, 0.10, 1)

    local resultLbl = Lbl(frame, "Start typing…", 11, T.TextMuted)
    resultLbl.Size = UDim2.new(1, 0, 0, 16)

    local matchedCmd = nil

    box:GetPropertyChangedSignal("Text"):Connect(function()
        local q = box.Text:lower()
        matchedCmd = nil
        if q == "" then
            resultLbl.Text      = "Start typing…"
            resultLbl.TextColor3 = T.TextMuted
            return
        end
        for _, cmd in ipairs(self._commands) do
            if cmd.Name:lower():find(q, 1, true)
            or (cmd.Desc and cmd.Desc:lower():find(q, 1, true)) then
                matchedCmd          = cmd
                resultLbl.Text      = cmd.Name .. (cmd.Desc and ("  —  " .. cmd.Desc) or "")
                resultLbl.TextColor3 = T.AccentStrong
                return
            end
        end
        resultLbl.Text      = "No results"
        resultLbl.TextColor3 = T.TextMuted
    end)

    box.FocusLost:Connect(function(enter)
        if enter and matchedCmd then pcall(matchedCmd.Callback) end
        self._sg = nil
        pcall(function() sg:Destroy() end)
    end)

    backdrop.MouseButton1Click:Connect(function()
        self._sg = nil
        pcall(function() sg:Destroy() end)
    end)

    box:CaptureFocus()
end

-- ═══════════════════════════════════════════════════════════════
--  LOCALIZATION
--  Register language tables; Get() returns the current-language
--  string for a key, falling back to the key itself.
-- ═══════════════════════════════════════════════════════════════
local Localization = { _langs = {}, _current = "en" }

function Localization:Register(code, t)
    self._langs[code] = t
end

function Localization:Set(code)
    if self._langs[code] then self._current = code end
end

function Localization:Get(key)
    local l = self._langs[self._current] or {}
    return l[key] or key
end

function Localization:GetCurrent()
    return self._current
end

function Localization:GetLanguages()
    local out = {}
    for k in pairs(self._langs) do out[#out+1] = k end
    return out
end

-- ═══════════════════════════════════════════════════════════════
--  ATTACH TO AXIUI
-- ═══════════════════════════════════════════════════════════════
local Managers = {
    SaveManager    = SaveManager,
    Watermark      = Watermark,
    KeybindOverlay = KeybindOverlay,
    Dialog         = Dialog,
    CommandPalette = CommandPalette,
    Localization   = Localization,
}

AxiUI.SaveManager    = SaveManager
AxiUI.Watermark      = Watermark
AxiUI.KeybindOverlay = KeybindOverlay
AxiUI.Dialog         = Dialog
AxiUI.CommandPalette = CommandPalette
AxiUI.Localization   = Localization
AxiUI.Managers       = Managers

return Managers
