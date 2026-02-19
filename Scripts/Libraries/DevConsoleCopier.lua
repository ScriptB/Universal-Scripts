-- Developer Console Copier v1.0
-- Improved, cleaner, safer, and adds "Copy All" feature

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Utility: safe wait for DevConsole
local function getClientLog()
    local master = CoreGui:FindFirstChild("DevConsoleMaster")
    if not master then return end

    local window = master:FindFirstChild("DevConsoleWindow")
    if not window then return end

    local ui = window:FindFirstChild("DevConsoleUI")
    if not ui then return end

    local main = ui:FindFirstChild("MainView")
    if not main then return end

    return main:FindFirstChild("ClientLog")
end

-- Create copy button for a single log line
local function attachCopyButton(label)
    if label:FindFirstChild("CopyBtn") then return end

    local btn = Instance.new("TextButton")
    btn.Name = "CopyBtn"
    btn.Size = UDim2.new(0, 30, 0, 18)
    btn.BackgroundTransparency = 1
    btn.Text = "[C]"
    btn.TextColor3 = label.TextColor3
    btn.Font = label.Font
    btn.TextSize = label.TextSize
    btn.TextTransparency = 0.5
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = label

    -- Position correctly once text renders
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not btn.Parent then
            conn:Disconnect()
            return
        end

        local bounds = label.TextBounds
        if bounds.X > 0 then
            btn.AnchorPoint = Vector2.new(0, 0.5)

            if label.Text:find("\n") then
                local lastLine = label.Text:match("([^\n]*)$")
                local size = TextService:GetTextSize(
                    lastLine,
                    label.TextSize,
                    label.Font,
                    Vector2.new(label.AbsoluteSize.X, math.huge)
                )
                btn.Position = UDim2.new(0, size.X + 6, 1, -label.TextSize / 2)
            else
                btn.Position = UDim2.new(0, bounds.X + 6, 0.5, 0)
            end

            conn:Disconnect()
        end
    end)

    btn.MouseEnter:Connect(function() btn.TextTransparency = 0 end)
    btn.MouseLeave:Connect(function() btn.TextTransparency = 0.5 end)

    btn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(label.Text)
            btn.Text = "[✓]"
            task.delay(0.35, function()
                if btn then btn.Text = "[C]" end
            end)
        end
    end)
end

-- Scan container for labels
local function scan(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") then
            attachCopyButton(obj)
        end
    end
end

-- Create "Copy All" button
local function createCopyAllButton(clientLog)
    if clientLog:FindFirstChild("CopyAllLogs") then return end

    local btn = Instance.new("TextButton")
    btn.Name = "CopyAllLogs"
    btn.Size = UDim2.new(0, 120, 0, 22)
    btn.Position = UDim2.new(1, -130, 0, 6)
    btn.BackgroundTransparency = 0.2
    btn.Text = "Copy All"
    btn.Parent = clientLog

    btn.MouseButton1Click:Connect(function()
        local buffer = {}

        for _, obj in ipairs(clientLog:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                table.insert(buffer, obj.Text)
            end
        end

        if setclipboard then
            setclipboard(table.concat(buffer, "\n"))
            btn.Text = "Copied"
            task.delay(0.6, function()
                if btn then btn.Text = "Copy All" end
            end)
        end
    end)
end

-- Main hook
local function hookConsole()
    local clientLog = getClientLog()
    if not clientLog then return end

    scan(clientLog)
    createCopyAllButton(clientLog)

    clientLog.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") then
            task.delay(0.05, function()
                attachCopyButton(obj)
            end)
        end
    end)
end

-- Initial run + periodic check
hookConsole()

local timer = 0
RunService.Heartbeat:Connect(function(dt)
    timer += dt
    if timer > 1 then
        timer = 0
        hookConsole()
    end
end)
