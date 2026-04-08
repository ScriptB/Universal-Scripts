-- ══════════════════════════════════════════════════════════════
--  AxiUI — InterfaceManager Module
-- ══════════════════════════════════════════════════════════════
local _env = (typeof(getgenv) == "function" and getgenv()) or _G
local Library = _env.Library or {}

-- ── Aliases ───────────────────────────────────────────────────
local Utils              = Library.Utils or {}
local New, Corner, Stroke, Pad, List, Gradient = Utils.New, Utils.Corner, Utils.Stroke, Utils.Pad, Utils.List, Utils.Gradient
local Theme              = Library.Theme or {}
local Tween, PlaySound   = Utils.Tween, Utils.PlaySound
local GetRoot           = Utils.GetRoot

-- ── SettingsManager ──────────────────────────────────────────
local SettingsManager = { _settingsFolder = "AxiUI_Settings" }
function SettingsManager:Init() if typeof(makefolder) == "function" and not isfolder(self._settingsFolder) then makefolder(self._settingsFolder) end end
function SettingsManager:SaveSettings(name, stateTable) self:Init(); Utils.SafeWrite(self._settingsFolder .. "/" .. name .. ".json", Utils.SafeJSON(stateTable)) end
function SettingsManager:LoadSettings(name) self:Init(); local data = Utils.SafeRead(self._settingsFolder .. "/" .. name .. ".json"); return data and Utils.SafeParse(data) or nil end
function SettingsManager:DeleteSettings(name) self:Init(); Utils.SafeDelete(self._settingsFolder .. "/" .. name .. ".json") end
function SettingsManager:ListSettings() self:Init(); local files = Utils.SafeList(self._settingsFolder); local out = {} for _, f in ipairs(files) do local n = f:match("([^/\\]+)%.json$") if n then table.insert(out, n) end end return out end
function SettingsManager:CollectState()
    local state = { Toggles = {}, Options = {} }
    local Toggles = _env.Toggles or {}
    local Options = _env.Options or {}
    for k, v in pairs(Toggles) do if type(v) == "table" and v.GetValue then state.Toggles[k] = v:GetValue() end end
    for k, v in pairs(Options) do if type(v) == "table" and v.GetValue then state.Options[k] = v:GetValue() end end
    return state
end
function SettingsManager:RestoreState(state)
    if not state then return end
    local Toggles = _env.Toggles or {}
    local Options = _env.Options or {}
    if state.Toggles then for k, v in pairs(state.Toggles) do if Toggles[k] and Toggles[k].SetValue then Toggles[k]:SetValue(v) end end end
    if state.Options then for k, v in pairs(state.Options) do if Options[k] and Options[k].SetValue then Options[k]:SetValue(v) end end end
end

-- ── PresetsManager ───────────────────────────────────────────
local PresetsManager = { _presetsFolder = "AxiUI_Presets" }
function PresetsManager:Init() if typeof(makefolder) == "function" and not isfolder(self._presetsFolder) then makefolder(self._presetsFolder) end end
function PresetsManager:SavePreset(name, themeTable, settingsTable) self:Init(); Utils.SafeWrite(self._presetsFolder .. "/" .. name .. ".json", Utils.SafeJSON({ Theme = themeTable, Settings = settingsTable })) end
function PresetsManager:LoadPreset(name) self:Init(); local data = Utils.SafeRead(self._presetsFolder .. "/" .. name .. ".json"); return data and Utils.SafeParse(data) or nil end
function PresetsManager:DeletePreset(name) self:Init(); Utils.SafeDelete(self._presetsFolder .. "/" .. name .. ".json") end
function PresetsManager:ListPresets() self:Init(); local files = Utils.SafeList(self._presetsFolder); local out = {} for _, f in ipairs(files) do local n = f:match("([^/\\]+)%.json$") if n then table.insert(out, n) end end return out end

-- ── ProfileManager ───────────────────────────────────────────
local ProfileManager = { _profileFolder = "AxiUI_Profiles" }
function ProfileManager:Init() if typeof(makefolder) == "function" and not isfolder(self._profileFolder) then makefolder(self._profileFolder) end end
function ProfileManager:SaveProfile(name, themeTable, settingsTable) self:Init(); Utils.SafeWrite(self._profileFolder .. "/" .. name .. ".json", Utils.SafeJSON({ Theme = themeTable, Settings = settingsTable })) end
function ProfileManager:LoadProfile(name) self:Init(); local data = Utils.SafeRead(self._profileFolder .. "/" .. name .. ".json"); return data and Utils.SafeParse(data) or nil end
function ProfileManager:DeleteProfile(name) self:Init(); Utils.SafeDelete(self._profileFolder .. "/" .. name .. ".json") end
function ProfileManager:ListProfiles() self:Init(); local files = Utils.SafeList(self._profileFolder); local out = {} for _, f in ipairs(files) do local n = f:match("([^/\\]+)%.json$") if n then table.insert(out, n) end end return out end

-- ── NotificationManager ──────────────────────────────────────
local NotificationManager = { _queue = {}, _active = false }
function NotificationManager:Notify(opts) table.insert(self._queue, opts); self:ProcessQueue() end
function NotificationManager:ProcessQueue()
    if self._active or #self._queue == 0 then return end
    self._active = true
    local opts = table.remove(self._queue, 1)
    Library:Notify(opts)
    local duration = (opts and opts.Duration) or 4
    task.delay(duration + 0.5, function() self._active = false; self:ProcessQueue() end)
end
function NotificationManager:NotifyPersistent(opts) opts = opts or {}; opts.Duration = 1e6; Library:Notify(opts) end
function NotificationManager:ClearAll() if Library._notifHolder then for _, c in ipairs(Library._notifHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end self._queue = {}; self._active = false end

-- ── Localization ─────────────────────────────────────────────
local Localization = { _languages = {}, _current = "en" }
function Localization:RegisterLanguage(code, t) self._languages[code] = t end
function Localization:SetLanguage(code) if self._languages[code] then self._current = code end end
function Localization:Get(key) local lang = self._languages[self._current] or {} return lang[key] or key end
function Localization:GetCurrent() return self._current end
function Localization:GetLanguages() local out = {} for k in pairs(self._languages) do table.insert(out, k) end return out end

-- ── CommandPalette ───────────────────────────────────────────
local CommandPalette = { _commands = {} }
function CommandPalette:RegisterCommand(name, desc, callback) table.insert(self._commands, { Name = name, Desc = desc, Callback = callback }) end
function CommandPalette:Open()
    local sg = New("ScreenGui", { Name = "AxiUI_CommandPalette", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10001, Parent = GetRoot() })
    local frame = New("Frame", { BackgroundColor3 = Theme.Panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.2, 0), Size = UDim2.new(0, 400, 0, 60), Parent = sg })
    Corner(frame, 8); Stroke(frame, Theme.Border, 1)
    local box = New("TextBox", { Text = "", PlaceholderText = "Type a command...", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.Text, BackgroundColor3 = Theme.Element, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 10), BorderSizePixel = 0, Parent = frame })
    Corner(box, 5)
    local results = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 40), Size = UDim2.new(1, -20, 0, 16), Parent = frame })
    local lbl = New("TextLabel", { Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = results })
    local function updateResults()
        local q = box.Text:lower()
        for _, cmd in ipairs(self._commands) do if cmd.Name:lower():find(q, 1, true) or (cmd.Desc and cmd.Desc:lower():find(q, 1, true)) then lbl.Text = cmd.Name .. " \226\128\148 " .. (cmd.Desc or ""); return cmd end end
        lbl.Text = "No command found"; return nil
    end
    box:GetPropertyChangedSignal("Text"):Connect(updateResults)
    box.FocusLost:Connect(function(enter) if enter then local cmd = updateResults(); if cmd then pcall(cmd.Callback) end end sg:Destroy() end)
    box:CaptureFocus()
end

-- ══════════════════════════════════════════════════════════════
--  LIBRARY INTERFACE METHODS
-- ══════════════════════════════════════════════════════════════

-- ── Notifications ─────────────────────────────────────────────
function Library:_buildNotifSG()
    if self._notifSG then return end
    local sg = New("ScreenGui", { Name = "AxiUI_Notifs", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Parent = GetRoot() })
    local holder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 310, 1, -28), Parent = sg })
    New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    self._notifSG = sg; self._notifHolder = holder
end

function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"; local content = opts.Content or ""; local duration = opts.Duration or 4; local ntype = opts.Type or "info"; local actions = opts.Actions or {}
    PlaySound(Library.Sounds.Notify, 0.45, 1.0)
    local acol = ({ info = Theme.Accent, success = Theme.Success, warning = Theme.Warning, error = Theme.Danger })[ntype] or Theme.Accent
    local icon = ({ info = "i", success = "v", warning = "!", error = "x" })[ntype] or "i"
    self:_buildNotifSG()
    local card = New("Frame", { BackgroundColor3 = Theme.PanelAlt, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, #actions > 0 and 88 or 68), Parent = self._notifHolder })
    Corner(card, 10); local st = Stroke(card, acol, 1, 0.5)
    Tween(st, { Transparency = 0 }, 0.25)
    local stripe = New("Frame", { BackgroundColor3 = acol, Size = UDim2.new(0, 4, 1, -12), Position = UDim2.new(0, 0, 0, 6), Parent = card }); Corner(stripe, 2)
    local icFrame = New("Frame", { BackgroundColor3 = acol, BackgroundTransparency = 0.75, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 14, 0, #actions > 0 and 8 or 10), Parent = card }); Corner(icFrame, 14)
    New("TextLabel", { Text = icon, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = acol, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = icFrame })
    local textFrame = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 52, 0, 8), Size = UDim2.new(1, -60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card })
    New("TextLabel", { Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = textFrame })
    New("TextLabel", { Text = content, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 0, 0, 20), Parent = textFrame })
    if #actions > 0 then
        local btnRow = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 52, 1, -28), Size = UDim2.new(1, -60, 0, 22), Parent = card })
        List(btnRow, 6, Enum.FillDirection.Horizontal)
        for _, act in ipairs(actions) do
            local ab = New("TextButton", { Text = act.Text or "OK", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = acol, BackgroundColor3 = Theme.Element, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = btnRow })
            Corner(ab, 4); Pad(ab, 0, 0, 8, 8)
            ab.MouseButton1Click:Connect(function() pcall(act.Callback or function() end); Tween(card, { BackgroundTransparency = 1 }, 0.2); task.delay(0.25, function() card:Destroy() end) end)
        end
    end
    card.Position = UDim2.new(1, 10, 0, 0); Tween(card, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.22)
    task.delay(duration, function() if card.Parent then Tween(card, { BackgroundTransparency = 1, Position = UDim2.new(1, 10, 0, 0) }, 0.28); task.delay(0.3, function() pcall(function() card:Destroy() end) end) end end)
end

function Library:NotifySuccess(t, c, d) self:Notify({ Title = t or "Success", Content = c or "", Duration = d or 4, Type = "success" }) end
function Library:NotifyWarning(t, c, d) self:Notify({ Title = t or "Warning", Content = c or "", Duration = d or 4, Type = "warning" }) end
function Library:NotifyError(t, c, d) self:Notify({ Title = t or "Error", Content = c or "", Duration = d or 4, Type = "error" }) end

-- ── Dialogs ───────────────────────────────────────────────────
function Library:Dialog(opts)
    opts = opts or {}
    local sg = New("ScreenGui", { Name = "AxiUI_Dialog", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10000, Parent = GetRoot() })
    local backdrop = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = sg })
    local card = New("Frame", { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 12), Size = UDim2.new(0, 380, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = backdrop })
    Corner(card, 10); Stroke(card, Theme.Border, 1)
    local top = New("Frame", { BackgroundColor3 = Theme.PanelAlt, Size = UDim2.new(1, 0, 0, 36), Parent = card }); Corner(top, 10)
    New("TextLabel", { Text = opts.Title or "Dialog", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0), Parent = top })
    local body = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card }); Pad(body, 10, 10, 12, 12); List(body, 10)
    New("TextLabel", { Text = opts.Content or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = body })
    local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = body }); List(row, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)
    local function close() Tween(backdrop, { BackgroundTransparency = 1 }, 0.12); Tween(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 12) }, 0.14); task.delay(0.16, function() sg:Destroy() end) end
    for _, b in ipairs(opts.Buttons or {{Text="OK"}}) do
        local btn = New("TextButton", { Text = b.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent, BackgroundColor3 = Theme.Element, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = row }); Corner(btn, 6); Pad(btn, 0, 0, 10, 10)
        btn.MouseButton1Click:Connect(function() pcall(b.Callback or function() end); close() end)
    end
    Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.12); Tween(card, { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.14)
    return { Close = close }
end

function Library:Confirm(opts) return self:Dialog({ Title = opts.Title or "Confirm", Content = opts.Content or "Are you sure?", Buttons = { {Text=opts.ConfirmText or "Confirm", Callback=opts.OnConfirm}, {Text=opts.CancelText or "Cancel", Callback=opts.OnCancel} } }) end

-- ── Watermark ─────────────────────────────────────────────────
function Library:_buildWatermarkSG()
    if self._wmSG then return end
    local sg = New("ScreenGui", { Name = "AxiUI_Watermark", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9998, Parent = GetRoot() })
    local frame = New("Frame", { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), AutomaticSize = Enum.AutomaticSize.X, Parent = sg }); Corner(frame, 7); Stroke(frame, Theme.Border, 1); Pad(frame, 0, 0, 14, 14)
    Gradient(frame, Theme.TitleLeft, Theme.TitleRight, 90)
    local lbl = New("TextLabel", { Text = "AxiUI", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Parent = frame })
    self._wmSG = sg; self._wmLabel = lbl
end
function Library:SetWatermark(t) self:_buildWatermarkSG(); self._wmLabel.Text = tostring(t or "AxiUI") end
function Library:SetWatermarkGame(p) local ok, name = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId).Name end); self:SetWatermark((p and (p.."  \194\183  ") or "") .. (ok and name or "Game")) end
function Library:SetWatermarkVisibility(v) self:_buildWatermarkSG(); self._wmSG.Enabled = v == true end

-- ── Keybind Overlay ───────────────────────────────────────────
function Library:_buildKeybindOverlay()
    if self._kbSG then return end
    local sg = New("ScreenGui", { Name = "AxiUI_KeybindOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9997, Parent = GetRoot() })
    local frame = New("Frame", { BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -6), Size = UDim2.new(0, 160, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = sg }); Corner(frame, 8); Stroke(frame, Theme.Border, 1); Pad(frame, 6, 6, 8, 8); List(frame, 3)
    New("TextLabel", { Text = "KEYBINDS", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.MutedText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Parent = frame })
    self._kbSG = sg; self._kbFrame = frame; self._kbRows = {}
end

function Library:_registerKeybind(idx, key, cb, mode)
    self:_buildKeybindOverlay()
    if not self._keybindListenersReady then
        self._keybindListenersReady = true
        UIS.InputBegan:Connect(function(i, gp) if gp then return end for _, kb in pairs(Library._keybinds or {}) do if (typeof(kb.key) == "EnumItem" and kb.key == i.KeyCode) or (kb.key == i.UserInputType) then if kb.mode == "Toggle" then kb.enabled = not kb.enabled; pcall(kb.cb, kb.enabled) elseif kb.mode == "Hold" then if not kb.enabled then kb.enabled = true; pcall(kb.cb, true) end elseif kb.mode == "Always" then pcall(kb.cb, true) end end end end)
        UIS.InputEnded:Connect(function(i) for _, kb in pairs(Library._keybinds or {}) do if kb.mode == "Hold" and ((typeof(kb.key) == "EnumItem" and kb.key == i.KeyCode) or (kb.key == i.UserInputType)) and kb.enabled then kb.enabled = false; pcall(kb.cb, false) end end end)
    end
    local kd = function(k) return typeof(k) == "EnumItem" and k.Name or tostring(k or "None") end
    if Library._keybinds[idx] then Library._keybinds[idx].key = key; if Library._keybinds[idx].overlayLabel then Library._keybinds[idx].overlayLabel.Text = "[" .. kd(key) .. "]" end return end
    local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Parent = self._kbFrame })
    New("TextLabel", { Text = idx, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0), Parent = row })
    local kl = New("TextLabel", { Text = "[" .. kd(key) .. "]", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), Parent = row })
    Library._keybinds[idx] = { key = key, cb = cb or function() end, mode = mode or "Toggle", enabled = false, overlayLabel = kl }
end
function Library:SetKeybindOverlayVisible(v) self:_buildKeybindOverlay(); self._kbSG.Enabled = v == true end

-- ── Scaling ───────────────────────────────────────────────────
function Library:SetUIScale(s)
    self._uiScale = math.clamp(s or 1, 0.5, 2)
    for _, w in ipairs(self._windows or {}) do if w._sg then local us = w._sg:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = w._sg }); us.Scale = self._uiScale end end
end
function Library:GetUIScale() return self._uiScale or 1 end

-- ── SaveManager ──────────────────────────────────────────────
local SaveManager = { _dirty = false }
function SaveManager:SetFolder(path) Library._configFolder = path end
function SaveManager:Save(name)
    local data = {}
    local Toggles = _env.Toggles or {}
    local Options = _env.Options or {}
    for k, v in pairs(Toggles) do if type(v) == "table" and v.GetValue then data["t_" .. k] = v:GetValue() end end
    for k, v in pairs(Options) do
        if type(v) == "table" and v.GetValue then
            local val = v:GetValue()
            if typeof(val) == "Color3" then val = { __col = true, r = val.R, g = val.G, b = val.B } end
            data["o_" .. k] = val
        end
    end
    Utils.SafeWrite(Library._configFolder .. "/" .. (name or "default") .. ".json", Utils.SafeJSON(data))
    self._dirty = false
end
function SaveManager:Load(name)
    local data = Utils.SafeRead(Library._configFolder .. "/" .. (name or "default") .. ".json")
    if not data then return false end
    local decoded = Utils.SafeParse(data)
    local Toggles = _env.Toggles or {}
    local Options = _env.Options or {}
    for k, v in pairs(decoded) do
        local tIdx = k:match("^t_(.+)$")
        if tIdx and Toggles[tIdx] then Toggles[tIdx]:SetValue(v) end
        local oIdx = k:match("^o_(.+)$")
        if oIdx and Options[oIdx] then
            if type(v) == "table" and v.__col then Options[oIdx]:SetValue(Color3.new(v.r, v.g, v.b))
            else Options[oIdx]:SetValue(v) end
        end
    end
    return true
end
function SaveManager:AutoSave(interval, name)
    if self._autoConn then self._autoConn:Disconnect(); self._autoConn = nil end
    if not interval or interval <= 0 then return end
    local RunService = game:GetService("RunService")
    local elapsed = 0
    self._autoConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= interval then
            elapsed = 0
            if self._dirty then self:Save(name or "autoload") end
        end
    end)
    -- Mark dirty on changes (will need to wrap SetValue or use listeners)
end
function SaveManager:BuildUI(gb)
    if not gb then return end
    local profileInput = gb:AddInput("SM_ProfileName", { Text = "Profile Name", Default = "default" })
    gb:AddButton({ Text = "Save Profile", Callback = function() self:Save(profileInput.Value) end })
    gb:AddButton({ Text = "Load Profile", Callback = function() self:Load(profileInput.Value) end })
end

-- ── Attach Managers ───────────────────────────────────────────
Library.Managers = {
    Settings = SettingsManager,
    Presets  = PresetsManager,
    Profile  = ProfileManager,
    Notification = NotificationManager,
    Localization = Localization,
    CommandPalette = CommandPalette
}
Library.SaveManager = SaveManager

return Library.Managers
