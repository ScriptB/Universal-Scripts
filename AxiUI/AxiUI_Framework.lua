-- ══════════════════════════════════════════════════════════════
--  AxiUI — UI Framework Module (High-Fidelity)
-- ══════════════════════════════════════════════════════════════
local _env = (typeof(getgenv) == "function" and getgenv()) or _G
local Library = _env.Library or {
    _VERSION       = "2.3.1",
    _windows       = {},
    _conns         = {},
    _keybinds      = {},
    _configFolder  = "AxiUI_Configs",
    Unloaded       = false,
    Theme          = {},
    Utils          = {}
}
Library._windows = Library._windows or {}
Library._conns   = Library._conns   or {}
Library.Theme    = Library.Theme    or {}
Library.Utils    = Library.Utils    or {}

-- ──────── SERVICES ────────
local UIS            = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local TextService     = game:GetService("TextService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer
local Mouse           = LocalPlayer:GetMouse()

-- ──────── UTILITIES ────────
local Utils = Library.Utils

function Utils.GetRoot()
    return (game:GetService("CoreGui"):FindFirstChild("RobloxGui") or game:GetService("CoreGui"))
end

function Utils.New(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    return i
end

function Utils.Corner(parent, radius)
    return Utils.New("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function Utils.Stroke(parent, color, thickness, trans)
    return Utils.New("UIStroke", {
        Color            = color or Color3.new(1, 1, 1),
        Thickness        = thickness or 1,
        Transparency     = trans or 0,
        ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
        Parent           = parent
    })
end

function Utils.Pad(parent, t, b, l, r)
    return Utils.New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        Parent        = parent
    })
end

function Utils.List(parent, pad, dir, horiz, vert)
    return Utils.New("UIListLayout", {
        Padding             = UDim.new(0, pad or 0),
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = horiz or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = vert or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Parent              = parent
    })
end

function Utils.Gradient(parent, c1, c2, rot)
    return Utils.New("UIGradient", {
        Color    = ColorSequence.new(c1, c2),
        Rotation = rot or 0,
        Parent   = parent
    })
end

function Utils.Tween(obj, props, time, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function Utils.PlaySound(id, vol, pitch)
    local s = Utils.New("Sound", { SoundId = id, Volume = vol or 0.5, Pitch = pitch or 1, Parent = game:GetService("SoundService") })
    s:Play()
    task.delay(s.TimeLength + 0.1, function() s:Destroy() end)
end

function Utils.Clamp(v, min, max) return math.clamp(v, min, max) end
function Utils.Round(v, r) if r == 0 then return math.floor(v + 0.5) end local m = 10^r return math.floor(v * m + 0.5) / m end
function Utils.Lerp(a, b, t) return a + (b - a) * t end

-- ── FILE SYSTEM UTILS ──
function Utils.SafeWrite(path, data) pcall(function() if typeof(writefile) == "function" then writefile(path, data) end end) end
function Utils.SafeRead(path) local ok, d = pcall(function() if typeof(readfile) == "function" and isfile(path) then return readfile(path) end end) return ok and d or nil end
function Utils.SafeDelete(path) pcall(function() if typeof(delfile) == "function" and isfile(path) then delfile(path) end end) end
function Utils.SafeList(folder) if typeof(listfiles) == "function" then local ok, f = pcall(function() return listfiles(folder) end) if ok and type(f) == "table" then return f end end return {} end
function Utils.SafeJSON(data) return game:GetService("HttpService"):JSONEncode(data) end
function Utils.SafeParse(data) local ok, d = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end) return ok and d or {} end

local Sounds = {
    Click  = "rbxassetid://6895079857",
    Toggle = "rbxassetid://6895080051",
    Notify = "rbxassetid://6895080130",
    Open   = "rbxassetid://6895080277",
}
Library.Sounds = Sounds

-- ──────── CORE ────────
local Toggles, Options = {}, {}
_env.Toggles, _env.Options = Toggles, Options

function Library:_connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self._conns, conn)
    return conn
end

function Library:_fire(cb, list, ...)
    if cb then pcall(cb, ...) end
    if list then for _, fn in ipairs(list) do pcall(fn, ...) end end
end

function Library:_attachHover(btn, normal, hover)
    local Theme = Library.Theme
    normal = normal or Theme.Element
    hover  = hover  or Theme.ElementHov
    btn.MouseEnter:Connect(function() Utils.Tween(btn, { BackgroundColor3 = hover }, 0.1) end)
    btn.MouseLeave:Connect(function() Utils.Tween(btn, { BackgroundColor3 = normal }, 0.1) end)
end

local function MakeRipple(btn, x, y, color)
    local r = Utils.New("Frame", {
        BackgroundColor3       = color or Library.Theme.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, x, 0, y),
        Size                   = UDim2.new(0, 0, 0, 0),
        ZIndex                 = btn.ZIndex + 1,
        Parent                 = btn,
    })
    Utils.Corner(r, 100)
    Utils.Tween(r, { Size = UDim2.new(0, 300, 0, 300), Position = UDim2.new(0, x - 150, 0, y - 150), BackgroundTransparency = 1 }, 0.6)
    task.delay(0.6, function() r:Destroy() end)
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Library.Unloaded then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end end)
    UIS.InputChanged:Connect(function(input) if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end end)
end

-- ══════════════════════════════════════════════════════════════
--  WINDOW / TAB / GROUPBOX
-- ══════════════════════════════════════════════════════════════

function Library:CreateWindow(opts)
    opts = opts or {}
    local name = opts.Name or opts.Title or "AxiUI"; local sub = opts.SubTitle or opts.Sub or "Framework"; local size = opts.Size or UDim2.new(0, 580, 0, 420); local Theme = self.Theme; local _tKey = { v = Enum.KeyCode.RightControl }; self._conns = {}
    local sg = Utils.New("ScreenGui", { Name = "AxiUI_" .. name:gsub("%s+", ""), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9990, Parent = Utils.GetRoot() })
    local shadowWrap = Utils.New("CanvasGroup", { Name = "ShadowWrap", BackgroundTransparency = 1, Size = UDim2.new(1, 40, 1, 40), Position = UDim2.new(0, -20, 0, -20), Parent = sg })
    local win = Utils.New("Frame", { Name = "Main", BackgroundColor3 = Theme.Background, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = size, Parent = shadowWrap }); Utils.Corner(win, 10); local winStroke = Utils.Stroke(win, Theme.Border, 1)
    local header = Utils.New("Frame", { Name = "Header", BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 44), Parent = win }); Utils.Corner(header, 10); MakeDraggable(win, header)
    Utils.New("TextLabel", { Text = name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.25, 0), Size = UDim2.new(0.5, 0, 0, 16), Parent = header })
    Utils.New("TextLabel", { Text = sub, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.MutedText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.62, 0), Size = UDim2.new(0.5, 0, 0, 12), Parent = header })
    local tabBar = Utils.New("Frame", { Name = "TabBar", BackgroundColor3 = Theme.PanelAlt, Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 44), Parent = win })
    local tabScroll = Utils.New("ScrollingFrame", { BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), ZIndex = 4, Parent = tabBar }); Utils.List(tabScroll, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center); Utils.Pad(tabScroll, 0, 0, 8, 8)
    local content = Utils.New("Frame", { Name = "Content", BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.new(0, 0, 0, 76), Size = UDim2.new(1, 0, 1, -76), ZIndex = 1, Parent = win })

    local Win = { _sg = sg, _win = win, _content = content, _tabs = {}, _activeTab = nil }
    Win.__index = Win
    function Win:SetVisible(v) if v then sg.Enabled = true; shadowWrap.Visible = true; Utils.PlaySound(Library.Sounds.Open, 0.4, 1.0) else shadowWrap.Visible = false; sg.Enabled = false end end
    function Win:Toggle() self:SetVisible(not shadowWrap.Visible) end
    Library:_connect(UIS.InputBegan, function(i) if i.KeyCode == _tKey.v then Win:Toggle() end end)

    function Win:AddTab(tName, icon)
        local tab = { _name = tName, _win = self, _elements = {} }
        local tBtn = Utils.New("TextButton", { Text = tName, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.MutedText, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = tabScroll })
        Utils.Pad(tBtn, 0, 0, 12, 12); local tInd = Utils.New("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), Parent = tBtn })
        local page = Utils.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = content }); Utils.Pad(page, 10, 10, 12, 12)
        local function mkC(xP, xS) local sc = Utils.New("ScrollingFrame", { BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Size = UDim2.new(xS, -8, 1, 0), Position = UDim2.new(xP, xP == 0 and 0 or 8, 0, 0), Parent = page }); Utils.List(sc, 8); return sc end
        tab._leftCol, tab._rightCol = mkC(0, 0.5), mkC(0.5, 0.5)

        if #self._tabs == 0 then page.Visible = true; tBtn.TextColor3 = Theme.Accent; tInd.Size = UDim2.new(1, 0, 0, 2); self._activeTab = tab end
        tBtn.MouseButton1Click:Connect(function() if self._activeTab and self._activeTab ~= tab then self._activeTab._page.Visible = false; self._activeTab._tBtn.TextColor3 = Theme.MutedText; self._activeTab._tInd.Size = UDim2.new(0, 0, 0, 2) end page.Visible = true; self._activeTab = tab; tBtn.TextColor3 = Theme.Accent; tInd.Size = UDim2.new(1, 0, 0, 2) end)
        tab._tBtn, tab._tInd, tab._page = tBtn, tInd, page; table.insert(self._tabs, tab)

        local function _newGB(gbN, pnt)
            local gb = {}
            local wrap = Utils.New("Frame", { BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = pnt }); Utils.Corner(wrap, 8); Utils.Stroke(wrap, Theme.Border, 1)
            local hdr = Utils.New("Frame", { BackgroundColor3 = Theme.PanelAlt, Size = UDim2.new(1, 0, 0, 30), Parent = wrap }); Utils.Corner(hdr, 8); Utils.New("Frame", { BackgroundColor3 = Theme.PanelAlt, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Parent = hdr })
            Utils.New("TextLabel", { Text = gbN:upper(), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0), Parent = hdr })
            local body = Utils.New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = wrap }); Utils.Pad(body, 8, 8, 8, 8); Utils.List(body, 6); gb._body = body

            function gb:AddToggle(idx, gO)
                gO = gO or {}; local obj = { Value = gO.Default or false, _cbs = {} }; Toggles[idx] = obj
                local row = Utils.New("TextButton", { Text = "", BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 32), Parent = body }); Utils.Corner(row, 6)
                Utils.New("TextLabel", { Text = gO.Text or idx, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -60, 1, 0), Parent = row })
                local trk = Utils.New("Frame", { BackgroundColor3 = obj.Value and Theme.Accent or Theme.ToggleOff, Size = UDim2.new(0, 36, 0, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Parent = row }); Utils.Corner(trk, 9)
                local knb = Utils.New("Frame", { BackgroundColor3 = Theme.White, Size = UDim2.new(0, 14, 0, 14), Position = obj.Value and UDim2.new(0, 20, 0, 2) or UDim2.new(0, 2, 0, 2), Parent = trk }); Utils.Corner(knb, 7)
                row.MouseButton1Click:Connect(function() obj.Value = not obj.Value; Utils.Tween(trk, { BackgroundColor3 = obj.Value and Theme.Accent or Theme.ToggleOff }, 0.15); Utils.Tween(knb, { Position = obj.Value and UDim2.new(0, 20, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.15); Library:_fire(gO.Callback, obj._cbs, obj.Value) end)
                function obj:SetValue(v) self.Value = v; Utils.Tween(trk, { BackgroundColor3 = v and Theme.Accent or Theme.ToggleOff }, 0.1); Utils.Tween(knb, { Position = v and UDim2.new(0, 20, 0, 2) or UDim2.new(0, 2, 0, 2) }, 0.1); Library:_fire(nil, self._cbs, v) end
                function obj:OnChanged(f) table.insert(self._cbs, f) end; return obj
            end
            
            function gb:AddButton(gO)
                local btn = Utils.New("TextButton", { Text = gO.Text or "Button", Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = Theme.Text, BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 32), Parent = body }); Utils.Corner(btn, 6)
                btn.MouseButton1Click:Connect(function() MakeRipple(btn, Mouse.X-btn.AbsolutePosition.X, Mouse.Y-btn.AbsolutePosition.Y); pcall(gO.Callback or gO.Func or function() end) end); return btn
            end

            function gb:AddSlider(idx, gO)
                gO = gO or {}; local min, max = gO.Min or 0, gO.Max or 100; local obj = { Value = gO.Default or min, _cbs = {} }; Options[idx] = obj
                local row = Utils.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = body })
                Utils.New("TextLabel", { Text = gO.Text or idx, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = row })
                local val = Utils.New("TextLabel", { Text = tostring(obj.Value) .. (gO.Suffix or ""), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = row })
                local trk = Utils.New("Frame", { BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 28), Parent = row }); Utils.Corner(trk, 3)
                local fill = Utils.New("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new((obj.Value - min)/(max - min), 0, 1, 0), Parent = trk }); Utils.Corner(fill, 3)
                local dragging = false; local function update(input) local r = math.clamp((input.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1); local v = math.floor(min + r * (max - min)); obj.Value = v; fill.Size = UDim2.new(r, 0, 1, 0); val.Text = tostring(v) .. (gO.Suffix or ""); Library:_fire(gO.Callback, obj._cbs, v) end
                trk.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end end)
                UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                function obj:SetValue(v) local r = (v-min)/(max-min); self.Value = v; fill.Size = UDim2.new(r, 0, 1, 0); val.Text = tostring(v) .. (gO.Suffix or ""); Library:_fire(nil, self._cbs, v) end
                function obj:OnChanged(f) table.insert(self._cbs, f) end; return obj
            end

            function gb:AddDropdown(idx, gO)
                gO = gO or {}; local obj = { Value = gO.Default, _cbs = {} }; Options[idx] = obj; local items = gO.Values or {}
                local row = Utils.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = body })
                Utils.New("TextLabel", { Text = gO.Text or idx, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = row })
                local btn = Utils.New("TextButton", { Text = tostring(obj.Value or "Select..."), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 20), Parent = row }); Utils.Corner(btn, 5); Utils.Pad(btn, 0, 0, 10, 10)
                function obj:SetValue(v) self.Value = v; btn.Text = tostring(v); Library:_fire(gO.Callback, self._cbs, v) end
                function obj:SetValues(v) items = v end; return obj
            end

            function gb:AddInput(idx, gO)
                gO = gO or {}; local obj = { Value = gO.Default or "", _cbs = {} }; Options[idx] = obj
                local row = Utils.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = body })
                Utils.New("TextLabel", { Text = gO.Text or idx, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = row })
                local box = Utils.New("TextBox", { Text = obj.Value, PlaceholderText = gO.PlaceholderText or "...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 20), BorderSizePixel = 0, Parent = row }); Utils.Corner(box, 5); Utils.Pad(box, 0, 0, 10, 10)
                box.FocusLost:Connect(function() obj.Value = box.Text; Library:_fire(gO.Callback, obj._cbs, box.Text) end)
                function obj:SetValue(v) self.Value = v; box.Text = v; Library:_fire(nil, self._cbs, v) end
                return obj
            end

            function gb:AddLabel(txt) return Utils.New("TextLabel", { Text = txt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = body }) end
            function gb:AddDivider() return Utils.New("Frame", { BackgroundColor3 = Theme.Border, Size = UDim2.new(1, 0, 0, 1), Parent = body }) end

            return gb
        end
        function tab:AddGroupbox(name) return _newGB(name, tab._leftCol) end
        function tab:AddLeftGroupbox(name) return _newGB(name, tab._leftCol) end
        function tab:AddRightGroupbox(name) return _newGB(name, tab._rightCol) end
        return tab
    end
    table.insert(self._windows, Win); Win:SetVisible(true); return Win
end

function Library:Unload()
    self.Unloaded = true
    for _, c in ipairs(self._conns or {}) do pcall(function() c:Disconnect() end) end
    for _, w in ipairs(self._windows or {}) do pcall(function() w._sg:Destroy() end) end
    if self._notifSG then pcall(function() self._notifSG:Destroy() end) end
end

_env.Library = Library
return Library
