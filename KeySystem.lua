--[[
	KeySystem.lua  v3.0
	by Asuneteric

	Phantom Suite key system - minimal UI by &R4, configured for Phantom Suite.
	Sets getgenv().SCRIPT_KEY on success. Fully decoupled from the aimbot.
]]

local Tsr = game:GetService("TweenService")
local Uis = game:GetService("UserInputService")
local Cgr = game:GetService("CoreGui")
local Hsr = game:GetService("HttpService")
local Wsp = game:GetService("Workspace")

local cfg = {
    title = "Phantom Suite",
    junkie_service = "Key System",
    junkie_identifier = "1032638",
    junkie_provider = "Linkvertise",
    discord_link = "https://discord.gg/Sakhwt7ChV",
    logo_asset = "",
    key_file = "phantom_suite_key.txt",
    primary_color = Color3.fromRGB(88, 166, 255),
    custom_theme = {
        main_background = Color3.fromRGB(13, 17, 23),
        header_background = Color3.fromRGB(22, 27, 34),
        footer_background = Color3.fromRGB(22, 27, 34),
        input_background = Color3.fromRGB(30, 36, 44),
        button_background = Color3.fromRGB(40, 90, 180),
        button_hover = Color3.fromRGB(88, 166, 255),
        text_color = Color3.fromRGB(230, 237, 243),
        accent_color = Color3.fromRGB(88, 166, 255),
    },
    fonts = {
        title = Enum.Font.GothamBold,
        button = Enum.Font.GothamBold,
        input = Enum.Font.Gotham,
        notification_title = Enum.Font.GothamBold,
        notification_body = Enum.Font.Gotham
    }
}

local BASE = "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/"
local function tuffmainscript()
    local function load(path)
        local src = game:HttpGet(BASE .. path)
        local fn, err = loadstring(src)
        if not fn then error("[Phantom] " .. path .. ": " .. tostring(err), 2) end
        local ok, err2 = pcall(fn)
        if not ok then error("[Phantom] " .. path .. ": " .. tostring(err2), 2) end
    end
    load("PhantomSuite.lua")
    load("PhantomCMD.lua")
end

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service    = cfg.junkie_service
Junkie.identifier = cfg.junkie_identifier
Junkie.provider   = cfg.junkie_provider

if getgenv().SCRIPT_KEY then tuffmainscript() return end

local function gen_clr(c)
    local h, s, v = c:ToHSV()
    return {
        mBg = Color3.fromHSV(h, s * 0.6, v * 0.15),
        hBg = Color3.fromHSV(h, s * 0.7, v * 0.25),
        fBg = Color3.fromHSV(h, s * 0.7, v * 0.25),
        iBg = Color3.fromHSV(h, s * 0.8, v * 0.1),
        bBg = Color3.fromHSV(h, s * 0.9, v * 0.35),
        bHv = Color3.fromHSV(h, s * 0.95, v * 0.45),
        tCl = Color3.fromHSV(h, s * 0.2, v * 0.95),
        aCl = Color3.fromHSV(h, s, v)
    }
end

local gen = gen_clr(cfg.primary_color)
local thm = {
    mBg = cfg.custom_theme.main_background or gen.mBg,
    hBg = cfg.custom_theme.header_background or gen.hBg,
    fBg = cfg.custom_theme.footer_background or gen.fBg,
    iBg = cfg.custom_theme.input_background or gen.iBg,
    bBg = cfg.custom_theme.button_background or gen.bBg,
    bHv = cfg.custom_theme.button_hover or gen.bHv,
    tCl = cfg.custom_theme.text_color or gen.tCl,
    aCl = cfg.custom_theme.accent_color or gen.aCl
}

local Icn = {
    x       = "rbxassetid://76821953846248",
    key     = "rbxassetid://96510194465420",
    shield  = "rbxassetid://89965059528921",
    check   = "rbxassetid://76078495178149",
    copy    = "rbxassetid://125851897718493",
    discord = "rbxassetid://83278450537116",
    heart   = "rbxassetid://116559368303288",
    alert   = "rbxassetid://140438367956051"
}

local ntl = {}
local has_logo = cfg.logo_asset ~= ""

local function ntf(tit, msg, dur, iconType)
    local nsg = Instance.new("ScreenGui")
    nsg.ResetOnSpawn = false
    nsg.DisplayOrder = 2147483647
    nsg.Parent = Cgr

    local scl = math.clamp(math.min(Wsp.CurrentCamera.ViewportSize.X, Wsp.CurrentCamera.ViewportSize.Y) / 1366, 0.6, 1.6)
    local wid = math.clamp(300 * scl, 220, 400)
    local hgt = math.clamp(70 * scl, 60, 100)

    local nfr = Instance.new("Frame")
    nfr.Size = UDim2.new(0, wid, 0, hgt)
    nfr.Position = UDim2.new(1, wid + 20, 1, -12)
    nfr.AnchorPoint = Vector2.new(1, 1)
    nfr.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    nfr.BorderSizePixel = 0
    nfr.Parent = nsg
    Instance.new("UICorner", nfr).CornerRadius = UDim.new(0, 10)

    local pbg = Instance.new("Frame")
    pbg.Size = UDim2.new(1, 0, 0, 4)
    pbg.Position = UDim2.new(0, 0, 1, -4)
    pbg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    pbg.BorderSizePixel = 0
    pbg.Parent = nfr
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 2)

    local pbr = Instance.new("Frame")
    pbr.Size = UDim2.new(1, 0, 1, 0)
    pbr.BackgroundColor3 = thm.aCl
    pbr.BorderSizePixel = 0
    pbr.Parent = pbg
    Instance.new("UICorner", pbr).CornerRadius = UDim.new(0, 2)

    local icn = Instance.new("ImageLabel")
    icn.Size = UDim2.new(0, hgt - 30, 0, hgt - 30)
    icn.Position = UDim2.new(0, 12, 0.5, 0)
    icn.AnchorPoint = Vector2.new(0, 0.5)
    icn.BackgroundTransparency = 1
    icn.ImageColor3 = Color3.new(1, 1, 1)
    icn.ScaleType = Enum.ScaleType.Fit
    icn.Image = (iconType and Icn[iconType]) or (has_logo and cfg.logo_asset) or Icn.alert
    icn.Parent = nfr

    local textX = 12 + (hgt - 30) + 12

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, -(textX + 10), 0, 20)
    ttl.Position = UDim2.new(0, textX, 0, 12)
    ttl.BackgroundTransparency = 1
    ttl.Font = cfg.fonts.notification_title
    ttl.TextSize = math.clamp(14 * scl, 12, 18)
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.TextColor3 = Color3.new(1, 1, 1)
    ttl.Text = tit
    ttl.TextTruncate = Enum.TextTruncate.AtEnd
    ttl.Parent = nfr

    local sbt = Instance.new("TextLabel")
    sbt.Size = UDim2.new(1, -(textX + 10), 0, 20)
    sbt.Position = UDim2.new(0, textX, 0, 32)
    sbt.BackgroundTransparency = 1
    sbt.Font = cfg.fonts.notification_body
    sbt.TextSize = math.clamp(12 * scl, 10, 14)
    sbt.TextXAlignment = Enum.TextXAlignment.Left
    sbt.TextColor3 = Color3.fromRGB(180, 180, 180)
    sbt.Text = msg
    sbt.TextTruncate = Enum.TextTruncate.AtEnd
    sbt.Parent = nfr

    local id = tick() .. Hsr:GenerateGUID(false)
    table.insert(ntl, {id = id, frame = nfr, gui = nsg, h = hgt})

    local function restack()
        local y = 0
        for i = #ntl, 1, -1 do
            local n = ntl[i]
            if n and n.frame and n.frame.Parent then
                Tsr:Create(n.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -12, 1, -12 - y)}):Play()
                y = y + n.h + 8
            end
        end
    end

    Tsr:Create(nfr, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -12, 1, -12)}):Play()
    task.wait(0.1)
    restack()

    local function dismiss()
        for i, n in ipairs(ntl) do
            if n.id == id then table.remove(ntl, i) break end
        end
        Tsr:Create(nfr, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, wid + 20, nfr.Position.Y.Scale, nfr.Position.Y.Offset)}):Play()
        task.wait(0.3)
        nsg:Destroy()
        restack()
    end

    if dur and dur > 0 then
        Tsr:Create(pbr, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
        task.delay(dur, dismiss)
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = nfr
    btn.MouseButton1Click:Connect(dismiss)
end

-- Check saved key first
if readfile and isfile and isfile(cfg.key_file) then
    local ok, saved = pcall(readfile, cfg.key_file)
    if ok and saved and saved ~= "" then
        ntf("Checking", "Validating saved key...", 1.5, "shield")
        task.wait(0.3)
        local validation = Junkie.check_key(saved)
        if validation and validation.valid then
            getgenv().SCRIPT_KEY = saved
            ntf("Welcome Back!", "Key validated successfully!", 2, "check")
            task.wait(2)
            tuffmainscript()
            return
        else
            ntf("Expired", "Saved key is no longer valid", 3, "alert")
            pcall(function() delfile(cfg.key_file) end)
        end
    end
end

local sgu = Instance.new("ScreenGui")
sgu.ZIndexBehavior = Enum.ZIndexBehavior.Global
sgu.ResetOnSpawn = false
sgu.IgnoreGuiInset = true
sgu.Parent = Cgr

local mfr = Instance.new("Frame")
mfr.Size = UDim2.new(0, 370, 0, 180)
mfr.Position = UDim2.new(0.5, 0, 0.5, 0)
mfr.AnchorPoint = Vector2.new(0.5, 0.5)
mfr.BackgroundColor3 = thm.mBg
mfr.BorderSizePixel = 0
mfr.Parent = sgu
Instance.new("UICorner", mfr).CornerRadius = UDim.new(0, 10)

local tfr = Instance.new("Frame")
tfr.Size = UDim2.new(1, 0, 0, 40)
tfr.BackgroundColor3 = thm.hBg
tfr.BorderSizePixel = 0
tfr.Active = true
tfr.Parent = mfr
Instance.new("UICorner", tfr).CornerRadius = UDim.new(0, 10)

local tfc = Instance.new("Frame")
tfc.Size = UDim2.new(1, 0, 0, 15)
tfc.Position = UDim2.new(0, 0, 1, -15)
tfc.BackgroundColor3 = thm.hBg
tfc.BorderSizePixel = 0
tfc.Parent = tfr

local titleOffset = 12
if has_logo then
    local lgo = Instance.new("ImageLabel")
    lgo.Size = UDim2.new(0, 26, 0, 26)
    lgo.Position = UDim2.new(0, 10, 0.5, 0)
    lgo.AnchorPoint = Vector2.new(0, 0.5)
    lgo.BackgroundTransparency = 1
    lgo.Image = cfg.logo_asset
    lgo.ImageColor3 = Color3.new(1, 1, 1)
    lgo.ScaleType = Enum.ScaleType.Fit
    lgo.Parent = tfr
    titleOffset = 44
end

local tlb = Instance.new("TextLabel")
tlb.Size = UDim2.new(1, -titleOffset - 30, 1, 0)
tlb.Position = UDim2.new(0, titleOffset, 0, 0)
tlb.BackgroundTransparency = 1
tlb.Text = cfg.title
tlb.TextColor3 = thm.tCl
tlb.TextSize = 18
tlb.Font = cfg.fonts.title
tlb.TextXAlignment = Enum.TextXAlignment.Left
tlb.Parent = tfr

local cib = Instance.new("ImageButton")
cib.Size = UDim2.new(0, 18, 0, 18)
cib.Position = UDim2.new(1, -12, 0.5, 0)
cib.AnchorPoint = Vector2.new(1, 0.5)
cib.BackgroundTransparency = 1
cib.Image = Icn.x
cib.ImageColor3 = thm.tCl
cib.ScaleType = Enum.ScaleType.Fit
cib.Parent = tfr

local ifr = Instance.new("Frame")
ifr.Size = UDim2.new(0.88, 0, 0, 38)
ifr.Position = UDim2.new(0.5, 0, 0, 58)
ifr.AnchorPoint = Vector2.new(0.5, 0)
ifr.BackgroundColor3 = thm.iBg
ifr.BackgroundTransparency = 0.2
ifr.BorderSizePixel = 0
ifr.Parent = mfr
Instance.new("UICorner", ifr).CornerRadius = UDim.new(0, 8)

local ist = Instance.new("UIStroke")
ist.Color = thm.aCl
ist.Thickness = 1
ist.Transparency = 0.6
ist.Parent = ifr

local tbx = Instance.new("TextBox")
tbx.Size = UDim2.new(0.92, 0, 1, 0)
tbx.Position = UDim2.new(0.5, 0, 0.5, 0)
tbx.AnchorPoint = Vector2.new(0.5, 0.5)
tbx.BackgroundTransparency = 1
tbx.Text = ""
tbx.TextColor3 = thm.tCl
tbx.PlaceholderText = "Enter your key..."
tbx.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
tbx.TextSize = 14
tbx.Font = cfg.fonts.input
tbx.ClearTextOnFocus = false
tbx.Parent = ifr

local bfr = Instance.new("Frame")
bfr.Size = UDim2.new(0.92, 0, 0, 32)
bfr.Position = UDim2.new(0.5, 0, 1, -28)
bfr.AnchorPoint = Vector2.new(0.5, 1)
bfr.BackgroundTransparency = 1
bfr.Parent = mfr

local function mkBtn(txt, pos, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.32, 0, 1, 0)
    b.Position = UDim2.new(pos, 0, 0, 0)
    b.AnchorPoint = Vector2.new(0.5, 0)
    b.BackgroundColor3 = thm.bBg
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.Parent = bfr
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local im = Instance.new("ImageLabel")
    im.Size = UDim2.new(0, 14, 0, 14)
    im.Position = UDim2.new(0.5, -18, 0.5, 0)
    im.AnchorPoint = Vector2.new(0.5, 0.5)
    im.BackgroundTransparency = 1
    im.Image = Icn[icon]
    im.ImageColor3 = Color3.new(1, 1, 1)
    im.ScaleType = Enum.ScaleType.Fit
    im.Parent = b

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -20, 1, 0)
    lb.Position = UDim2.new(0, 18, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = txt
    lb.TextColor3 = Color3.new(1, 1, 1)
    lb.TextSize = 10
    lb.Font = cfg.fonts.button
    lb.Parent = b

    b.MouseEnter:Connect(function() Tsr:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = thm.bHv}):Play() end)
    b.MouseLeave:Connect(function() Tsr:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = thm.bBg}):Play() end)

    return b
end

local gkb = mkBtn("Get Key",  0.16, "key")
local dcb = mkBtn("Discord",  0.5,  "discord")
local vfb = mkBtn("Validate", 0.84, "shield")

local dragging, dragStart, startPos
tfr.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mfr.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Uis.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mfr.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local errorMessages = {
    KEY_INVALID      = "Key not found in system",
    KEY_EXPIRED      = "Key has expired",
    HWID_BANNED      = "Hardware banned",
    KEY_INVALIDATED  = "Key was disabled",
    ALREADY_USED     = "One-time key already used",
    HWID_MISMATCH    = "HWID limit reached",
    SERVICE_NOT_FOUND   = "Service doesn't exist",
    SERVICE_MISMATCH    = "Key is for different service",
    PREMIUM_REQUIRED    = "Premium key required",
    ERROR               = "Network error - try again"
}

local function validate()
    local key = tbx.Text:gsub("%s+", "")
    if key == "" then ntf("Error", "Please enter your key", 3, "alert") return end
    ntf("Checking", "Validating key...", 2)
    task.wait(0.3)

    local validation = Junkie.check_key(key)

    if validation and validation.valid then
        if writefile then pcall(function() writefile(cfg.key_file, key) end) end
        getgenv().SCRIPT_KEY = key
        ntf("Success", "Key validated!", 2, "check")
        Tsr:Create(mfr, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, 0, -0.5, 0), BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        sgu:Destroy()
        tuffmainscript()
    else
        local err = (validation and validation.error) or "Unknown error"
        local msg = errorMessages[err] or err

        if err == "HWID_BANNED" then
            ntf("Banned", msg, 5, "alert")
            task.wait(3)
            game.Players.LocalPlayer:Kick("Hardware banned from service")
        else
            ntf("Invalid Key", msg, 4, "alert")
        end
    end
end

vfb.MouseButton1Click:Connect(validate)
tbx.FocusLost:Connect(function(e) if e then validate() end end)

gkb.MouseButton1Click:Connect(function()
    ntf("Generating", "Creating key link...", 1.5, "key")
    task.wait(0.3)

    local link, err = Junkie.get_key_link()

    if link then
        if setclipboard then
            setclipboard(link)
            ntf("Copied", "Key link copied to clipboard!", 3, "copy")
        else
            ntf("Link Ready", "Check console for link", 3, "check")
            print("Get Key Link:", link)
        end
    else
        if err == "RATE_LIMITTED" then
            ntf("Rate Limited", "Wait 5 minutes before requesting again", 5, "alert")
        else
            ntf("Error", err or "Failed to generate link", 3, "alert")
        end
    end
end)

dcb.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(cfg.discord_link)
        ntf("Discord", "Link copied!", 2, "discord")
    else
        ntf("Discord", cfg.discord_link, 4, "discord")
    end
end)

cib.MouseButton1Click:Connect(function()
    ntf("Goodbye", "See you!", 1, "heart")
    Tsr:Create(mfr, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, 0, -0.5, 0), BackgroundTransparency = 1}):Play()
    task.wait(0.3)
    sgu:Destroy()
end)

tbx.Focused:Connect(function()
    Tsr:Create(ifr, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    Tsr:Create(ist, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
end)

tbx.FocusLost:Connect(function()
    Tsr:Create(ifr, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    Tsr:Create(ist, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
end)

-- Block until validated
while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end
