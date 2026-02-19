-- LaqourLib - Fixed Version with Better Error Handling
-- Based on Bracket V3 but with enhanced compatibility

local Laqour = {Toggle = true, FirstTab = nil, TabCount = 0, ColorTable = {}}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function MakeDraggable(ClickObject, Object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil
	
	ClickObject.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPosition = Object.Position
			
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	
	ClickObject.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			DragInput = Input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - DragStart
			Object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		end
	end)
end

function Laqour:CreateWindow(Config, Parent)
	local WindowInit = {}
	
	-- Enhanced error handling for GUI assets
	local Folder
	local assetSuccess, assetResult = pcall(function()
		return game:GetObjects("rbxassetid://7141683860")
	end)
	
	if not assetSuccess then
		warn("❌ Failed to load GUI assets:", tostring(assetResult))
		warn("🔧 Creating fallback GUI...")
		
		-- Create fallback GUI programmatically
		Folder = {
			Bracket = Instance.new("ScreenGui")
		}
		
		local Screen = Folder.Bracket
		Screen.Name = "LaqourGUI"
		Screen.Parent = Parent or game:GetService("CoreGui")
		Screen.ResetOnSpawn = false
		
		-- Create main frame
		local Main = Instance.new("Frame")
		Main.Name = "Main"
		Main.Parent = Screen
		Main.Size = UDim2.new(0, 600, 0, 400)
		Main.Position = UDim2.new(0.5, -300, 0.5, -200)
		Main.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		Main.BorderSizePixel = 0
		
		-- Create topbar
		local Topbar = Instance.new("Frame")
		Topbar.Name = "Topbar"
		Topbar.Parent = Main
		Topbar.Size = UDim2.new(1, 0, 0, 30)
		Topbar.Position = UDim2.new(0, 0, 0, 0)
		Topbar.BackgroundColor3 = Color3.new(0, 0.7, 1)
		Topbar.BorderSizePixel = 0
		
		local WindowName = Instance.new("TextLabel")
		WindowName.Name = "WindowName"
		WindowName.Parent = Topbar
		WindowName.Size = UDim2.new(1, -60, 1, 0)
		WindowName.Position = UDim2.new(0, 10, 0, 0)
		WindowName.BackgroundTransparency = 1
		WindowName.Text = Config.WindowName or "Laqour GUI"
		WindowName.TextColor3 = Color3.new(1, 1, 1)
		WindowName.TextSize = 14
		WindowName.Font = Enum.Font.SourceSansBold
		WindowName.TextXAlignment = Enum.TextXAlignment.Left
		
		-- Create holder
		local Holder = Instance.new("Frame")
		Holder.Name = "Holder"
		Holder.Parent = Main
		Holder.Size = UDim2.new(1, 0, 1, -30)
		Holder.Position = UDim2.new(0, 0, 0, 30)
		Holder.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
		Holder.BorderSizePixel = 0
		
		local TContainer = Instance.new("ScrollingFrame")
		TContainer.Name = "TContainer"
		TContainer.Parent = Holder
		TContainer.Size = UDim2.new(1, 0, 1, 0)
		TContainer.Position = UDim2.new(0, 0, 0, 0)
		TContainer.BackgroundTransparency = 1
		TContainer.BorderSizePixel = 0
		TContainer.ScrollBarThickness = 0
		
		local TBContainer = Instance.new("Frame")
		TBContainer.Name = "TBContainer"
		TBContainer.Parent = Holder
		TBContainer.Size = UDim2.new(1, 0, 0, 30)
		TBContainer.Position = UDim2.new(0, 0, 0, 0)
		TBContainer.BackgroundTransparency = 1
		TBContainer.BorderSizePixel = 0
		
		local TBHolder = Instance.new("Frame")
		TBHolder.Name = "Holder"
		TBHolder.Parent = TBContainer
		TBHolder.Size = UDim2.new(1, 0, 1, 0)
		TBHolder.Position = UDim2.new(0, 0, 0, 0)
		TBHolder.BackgroundTransparency = 1
		
		-- Create tooltip
		local ToolTip = Instance.new("TextLabel")
		ToolTip.Name = "ToolTip"
		ToolTip.Parent = Screen
		ToolTip.Size = UDim2.new(0, 100, 0, 20)
		ToolTip.Position = UDim2.new(0, 0, 0, 0)
		ToolTip.BackgroundColor3 = Color3.new(0, 0, 0)
		ToolTip.BorderSizePixel = 1
		ToolTip.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
		ToolTip.Text = ""
		ToolTip.TextColor3 = Color3.new(1, 1, 1)
		ToolTip.TextSize = 12
		ToolTip.Font = Enum.Font.SourceSans
		ToolTip.Visible = false
		
		Folder.Bracket = Screen
	else
		Folder = assetResult
	end
	
	local Screen = Folder.Bracket:Clone()
	local Main = Screen.Main
	local Holder = Main.Holder
	local Topbar = Main.Topbar
	local TContainer = Holder.TContainer
	local TBContainer = Holder.TBContainer.Holder
	
	-- Laqour branding - protect GUI if syn is available
	if syn and syn.protect_gui then
		pcall(function() syn.protect_gui(Screen) end)
	end
	
	Screen.Name = HttpService:GenerateGUID(false)
	Screen.Parent = Parent or game:GetService("CoreGui")
	Topbar.WindowName.Text = Config.WindowName or "Laqour GUI"
	
	MakeDraggable(Topbar, Main)
	
	local function CloseAll()
		for _,Tab in pairs(TContainer:GetChildren()) do
			if Tab:IsA("ScrollingFrame") then
				Tab.Visible = false
			end
		end
	end
	
	local function ResetAll()
		for _,TabButton in pairs(TBContainer:GetChildren()) do
			if TabButton:IsA("TextButton") then
				TabButton.BackgroundTransparency = 1
			end
		end
		for _,TabButton in pairs(TBContainer:GetChildren()) do
			if TabButton:IsA("TextButton") then
				TabButton.Size = UDim2.new(0,480 / Laqour.TabCount,1,0)
			end
		end
		for _,Pallete in pairs(Screen:GetChildren()) do
			if Pallete:IsA("Frame") and Pallete.Name ~= "Main" then
				Pallete.Visible = false
			end
		end
	end
	
	local function KeepFirst()
		for _,Tab in pairs(TContainer:GetChildren()) do
			if Tab:IsA("ScrollingFrame") then
				if Tab.Name == Laqour.FirstTab .. " T" then
					Tab.Visible = true
				else
					Tab.Visible = false
				end
			end
		end
		for _,TabButton in pairs(TBContainer:GetChildren()) do
			if TabButton:IsA("TextButton") then
				if TabButton.Name == Laqour.FirstTab .. " TB" then
					TabButton.BackgroundTransparency = 0
				else
					TabButton.BackgroundTransparency = 1
				end
			end
		end
	end
	
	local function Toggle(State)
		if State then
			Main.Visible = true
		elseif not State then
			for _,Pallete in pairs(Screen:GetChildren()) do
				if Pallete:IsA("Frame") and Pallete.Name ~= "Main" then
					Pallete.Visible = false
				end
			end
			if Screen.ToolTip then
				Screen.ToolTip.Visible = false
			end
			Main.Visible = false
		end
		Laqour.Toggle = State
	end
	
	function WindowInit:Tab(Config)
		Laqour.TabCount = Laqour.TabCount + 1
		if Laqour.TabCount == 1 then
			Laqour.FirstTab = Config.Name
		end
		
		local TabInit = {}
		
		local TabButton = Instance.new("TextButton")
		TabButton.Name = Config.Name .. " TB"
		TabButton.Parent = TBContainer
		TabButton.Size = UDim2.new(0,480 / Laqour.TabCount,1,0)
		TabButton.BackgroundTransparency = 1
		TabButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
		TabButton.BorderSizePixel = 0
		TabButton.Text = "  " .. Config.Name
		TabButton.TextColor3 = Color3.new(1,1,1)
		TabButton.TextSize = 14
		TabButton.Font = Enum.Font.SourceSans
		TabButton.TextXAlignment = Enum.TextXAlignment.Left
		
		local Tab = Instance.new("ScrollingFrame")
		Tab.Name = Config.Name .. " T"
		Tab.Parent = TContainer
		Tab.Size = UDim2.new(1,0,1,0)
		Tab.Position = UDim2.new(0,0,0,0)
		Tab.BackgroundTransparency = 1
		Tab.BorderSizePixel = 0
		Tab.ScrollBarThickness = 0
		Tab.Visible = false
		
		local TabList = Instance.new("UIListLayout")
		TabList.Parent = Tab
		TabList.SortOrder = Enum.SortOrder.LayoutOrder
		TabList.Padding = UDim.new(0,5)
		
		TabButton.MouseButton1Click:Connect(function()
			CloseAll()
			ResetAll()
			Tab.Visible = true
			TabButton.BackgroundTransparency = 0
		end)
		
		if Laqour.TabCount == 1 then
			Tab.Visible = true
			TabButton.BackgroundTransparency = 0
		end
		
		ResetAll()
		KeepFirst()
		
		function TabInit:Divider(Config)
			local Divider = Instance.new("Frame")
			Divider.Name = "Divider"
			Divider.Parent = Tab
			Divider.Size = UDim2.new(1, -10, 0, 2)
			Divider.Position = UDim2.new(0, 5, 0, 0)
			Divider.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
			Divider.BorderSizePixel = 0
			
			local DividerLabel = Instance.new("TextLabel")
			DividerLabel.Name = "DividerLabel"
			DividerLabel.Parent = Divider
			DividerLabel.Size = UDim2.new(1, 0, 1, 0)
			DividerLabel.Position = UDim2.new(0, 0, 0, 0)
			DividerLabel.BackgroundTransparency = 1
			DividerLabel.Text = Config.Text or ""
			DividerLabel.TextColor3 = Color3.new(1,1,1)
			DividerLabel.TextSize = 14
			DividerLabel.Font = Enum.Font.SourceSansBold
			DividerLabel.TextXAlignment = Enum.TextXAlignment.Left
		end
		
		function TabInit:Label(Config)
			local Label = Instance.new("TextLabel")
			Label.Name = "Label"
			Label.Parent = Tab
			Label.Size = UDim2.new(1, -10, 0, 20)
			Label.Position = UDim2.new(0, 5, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = Config.Text or ""
			Label.TextColor3 = Color3.new(1,1,1)
			Label.TextSize = 14
			Label.Font = Enum.Font.SourceSans
			Label.TextXAlignment = Enum.TextXAlignment.Left
		end
		
		function TabInit:Toggle(Config)
			local Toggle = Instance.new("TextButton")
			Toggle.Name = Config.Name
			Toggle.Parent = Tab
			Toggle.Size = UDim2.new(1, -10, 0, 25)
			Toggle.Position = UDim2.new(0, 5, 0, 0)
			Toggle.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
			Toggle.BorderSizePixel = 1
			Toggle.BorderColor3 = Color3.new(0.3,0.3,0.3)
			Toggle.Text = "  " .. Config.Name
			Toggle.TextColor3 = Color3.new(1,1,1)
			Toggle.TextSize = 14
			Toggle.Font = Enum.Font.SourceSans
			Toggle.TextXAlignment = Enum.TextXAlignment.Left
			
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Name = "ToggleFrame"
			ToggleFrame.Parent = Toggle
			ToggleFrame.Size = UDim2.new(0, 20, 0, 10)
			ToggleFrame.Position = UDim2.new(1, -25, 0, 7.5)
			ToggleFrame.BackgroundColor3 = Config.Value and Color3.new(0,1,0) or Color3.new(1,0,0)
			ToggleFrame.BorderSizePixel = 0
			
			Toggle.MouseButton1Click:Connect(function()
				Config.Value = not Config.Value
				ToggleFrame.BackgroundColor3 = Config.Value and Color3.new(0,1,0) or Color3.new(1,0,0)
				if Config.Callback then
					Config.Callback(Config.Value)
				end
			end)
			
			if Config.Callback then
				Config.Callback(Config.Value)
			end
			
			return {
				SetValue = function(self, value)
					Config.Value = value
					ToggleFrame.BackgroundColor3 = value and Color3.new(0,1,0) or Color3.new(1,0,0)
					if Config.Callback then
						Config.Callback(value)
					end
				end
			}
		end
		
		function TabInit:Button(Config)
			local Button = Instance.new("TextButton")
			Button.Name = Config.Name
			Button.Parent = Tab
			Button.Size = UDim2.new(1, -10, 0, 25)
			Button.Position = UDim2.new(0, 5, 0, 0)
			Button.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
			Button.BorderSizePixel = 1
			Button.BorderColor3 = Color3.new(0.3,0.3,0.3)
			Button.Text = "  " .. Config.Name
			Button.TextColor3 = Color3.new(1,1,1)
			Button.TextSize = 14
			Button.Font = Enum.Font.SourceSans
			Button.TextXAlignment = Enum.TextXAlignment.Left
			
			Button.MouseButton1Click:Connect(function()
				if Config.Callback then
					Config.Callback()
				end
			end)
		end
		
		return TabInit
	end
	
	function WindowInit:Notification(Config)
		if not Screen.ToolTip then return end
		
		Screen.ToolTip.Text = Config.Description or "Notification"
		Screen.ToolTip.Size = UDim2.new(0, Screen.ToolTip.TextBounds.X + 10, 0, 25)
		Screen.ToolTip.Position = UDim2.new(0.5, -Screen.ToolTip.Size.X.Offset/2, 0.9, 0)
		Screen.ToolTip.Visible = true
		
		if Config.Duration and Config.Duration > 0 then
			task.wait(Config.Duration)
			Screen.ToolTip.Visible = false
		end
	end
	
	function WindowInit:Destroy()
		Screen:Destroy()
	end
	
	Toggle(true)
	return WindowInit
end

return Laqour
