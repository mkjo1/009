-- ================================================================
-- HAK ADMIN SYSTEM — SERVER SCRIPT
-- Location: ServerScriptService > New Script (NOT LocalScript)
-- ================================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents
local AdminEvent = Instance.new("RemoteEvent")
AdminEvent.Name   = "AdminEvent"
AdminEvent.Parent = ReplicatedStorage

local RegisterAdmin = Instance.new("RemoteEvent")
RegisterAdmin.Name   = "RegisterAdmin"
RegisterAdmin.Parent = ReplicatedStorage

-- Admin state
local adminUserId = nil
local debounce    = {}

-- Register first player who opens panel as admin
RegisterAdmin.OnServerEvent:Connect(function(player)
	if adminUserId == nil then
		adminUserId = player.UserId
		RegisterAdmin:FireClient(player, true)
		print("[HAK] Admin set: " .. player.Name)
	end
end)

-- Security check
local function isAdmin(player)
	return player.UserId == adminUserId
end

-- Debounce
local function canRun(player, action)
	local key = tostring(player.UserId) .. action
	local now = tick()
	if debounce[key] and (now - debounce[key]) < 0.8 then return false end
	debounce[key] = now
	return true
end

-- Get humanoid safely
local function getHum(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- Kill All
local function killAll(admin)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId ~= admin.UserId then
			local h = getHum(p.Character)
			if h then h.Health = 0 end
		end
	end
end

-- Freeze All
local function freezeAll(admin)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId ~= admin.UserId then
			local h = getHum(p.Character)
			if h then h.WalkSpeed = 0; h.JumpPower = 0 end
			if not p:FindFirstChild("HAK_Frozen") then
				local tag = Instance.new("BoolValue")
				tag.Name = "HAK_Frozen"
				tag.Parent = p
			end
		end
	end
end

-- Keep frozen on respawn
local function watchPlayer(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		if p:FindFirstChild("HAK_Frozen") then
			local h = getHum(char)
			if h then h.WalkSpeed = 0; h.JumpPower = 0 end
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

-- Send message to all
local function sendMsg()
	for _, p in ipairs(Players:GetPlayers()) do
		AdminEvent:FireClient(p, "ShowMessage", "تسجيل دخول HAK")
	end
end

-- Main handler
AdminEvent.OnServerEvent:Connect(function(sender, action)
	if not isAdmin(sender) then
		warn("[HAK] Blocked: " .. sender.Name)
		return
	end
	if not canRun(sender, action) then return end

	if     action == "KillAll"   then killAll(sender)
	elseif action == "FreezeAll" then freezeAll(sender)
	elseif action == "Message"   then sendMsg()
	end
end)
-- ================================================================
-- HAK ADMIN SYSTEM — LOCAL SCRIPT
-- Location: StarterPlayerScripts > New LocalScript (NOT Script)
-- ================================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for remotes created by the ServerScript
local AdminEvent    = ReplicatedStorage:WaitForChild("AdminEvent",    15)
local RegisterAdmin = ReplicatedStorage:WaitForChild("RegisterAdmin", 15)

if not AdminEvent or not RegisterAdmin then
	warn("[HAK] Remotes missing — is ServerScript placed correctly?")
	return
end

-- Ask server to register this player as admin
RegisterAdmin:FireServer()

-- Only build the GUI if the server confirms admin status
RegisterAdmin.OnClientEvent:Connect(function(confirmed)
	if not confirmed then return end

	-- ============================================================
	-- GUI
	-- ============================================================
	local screen = Instance.new("ScreenGui")
	screen.Name           = "HAK_Panel"
	screen.ResetOnSpawn   = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent         = player.PlayerGui

	-- Main frame
	local main = Instance.new("Frame")
	main.Size             = UDim2.new(0, 248, 0, 300)
	main.Position         = UDim2.new(0, 14, 0.5, -150)
	main.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
	main.BorderSizePixel  = 0
	main.ClipsDescendants = true
	main.Parent           = screen
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

	-- Top bar
	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(1, 0, 0, 50)
	bar.BackgroundColor3 = Color3.fromRGB(80, 0, 220)
	bar.BorderSizePixel  = 0
	bar.Parent           = main
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 16)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 0, 140)),
	})
	grad.Rotation = 135
	grad.Parent   = bar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                  = UDim2.new(0.8, 0, 1, 0)
	titleLbl.Position              = UDim2.new(0.05, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                  = "⚡  HAK Admin Panel"
	titleLbl.TextColor3            = Color3.new(1, 1, 1)
	titleLbl.Font                  = Enum.Font.GothamBold
	titleLbl.TextSize              = 15
	titleLbl.TextXAlignment        = Enum.TextXAlignment.Left
	titleLbl.Parent                = bar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 30, 0, 30)
	closeBtn.Position         = UDim2.new(1, -40, 0.5, -15)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
	closeBtn.Text             = "✕"
	closeBtn.TextColor3       = Color3.new(1, 1, 1)
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextSize         = 13
	closeBtn.BorderSizePixel  = 0
	closeBtn.Parent           = bar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	-- Content
	local content = Instance.new("Frame")
	content.Size                  = UDim2.new(1, 0, 1, -50)
	content.Position              = UDim2.new(0, 0, 0, 50)
	content.BackgroundTransparency = 1
	content.Parent                = main

	-- Toggle open/close
	local open = true
	closeBtn.MouseButton1Click:Connect(function()
		open = not open
		content.Visible = open
		closeBtn.Text   = open and "✕" or "☰"
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
			Size = open
				and UDim2.new(0, 248, 0, 300)
				or  UDim2.new(0, 248, 0, 50)
		}):Play()
	end)

	-- ============================================================
	-- Button factory
	-- ============================================================
	local nextY = 14

	local function makeBtn(icon, label, color)
		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(0.88, 0, 0, 52)
		btn.Position         = UDim2.new(0.06, 0, 0, nextY)
		btn.BackgroundColor3 = color
		btn.Text             = ""
		btn.BorderSizePixel  = 0
		btn.AutoButtonColor  = false
		btn.Parent           = content
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

		local iconL = Instance.new("TextLabel")
		iconL.Size                  = UDim2.new(0, 38, 1, 0)
		iconL.Position              = UDim2.new(0, 10, 0, 0)
		iconL.BackgroundTransparency = 1
		iconL.Text                  = icon
		iconL.TextSize              = 22
		iconL.Font                  = Enum.Font.GothamBold
		iconL.TextColor3            = Color3.new(1, 1, 1)
		iconL.Parent                = btn

		local nameL = Instance.new("TextLabel")
		nameL.Size                  = UDim2.new(1, -54, 1, 0)
		nameL.Position              = UDim2.new(0, 52, 0, 0)
		nameL.BackgroundTransparency = 1
		nameL.Text                  = label
		nameL.TextSize              = 14
		nameL.Font                  = Enum.Font.GothamBold
		nameL.TextColor3            = Color3.new(1, 1, 1)
		nameL.TextXAlignment        = Enum.TextXAlignment.Left
		nameL.Parent                = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundColor3 = color
			}):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.07), {
				Size = UDim2.new(0.84, 0, 0, 49)
			}):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.07), {
				Size = UDim2.new(0.88, 0, 0, 52)
			}):Play()
		end)

		nextY = nextY + 66
		return btn
	end

	-- ============================================================
	-- Buttons
	-- ============================================================
	local killBtn   = makeBtn("💀", "قتل الجميع",    Color3.fromRGB(185, 25, 25))
	local freezeBtn = makeBtn("❄️",  "تجميد الجميع",  Color3.fromRGB(0, 145, 210))
	local msgBtn    = makeBtn("📢", "رسالة للجميع",   Color3.fromRGB(140, 90, 0))

	killBtn.MouseButton1Click:Connect(function()
		AdminEvent:FireServer("KillAll")
	end)

	freezeBtn.MouseButton1Click:Connect(function()
		AdminEvent:FireServer("FreezeAll")
	end)

	msgBtn.MouseButton1Click:Connect(function()
		AdminEvent:FireServer("Message")
	end)

	-- Slide in
	main.Position = UDim2.new(-0.3, 0, 0.5, -150)
	TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0, 14, 0.5, -150)
	}):Play()
end)

-- ============================================================
-- Display incoming message
-- ============================================================
AdminEvent.OnClientEvent:Connect(function(action, message)
	if action ~= "ShowMessage" then return end

	local old = player.PlayerGui:FindFirstChild("HAK_Msg")
	if old then old:Destroy() end

	local msgScreen = Instance.new("ScreenGui")
	msgScreen.Name         = "HAK_Msg"
	msgScreen.ResetOnSpawn = false
	msgScreen.Parent       = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.AnchorPoint       = Vector2.new(0.5, 0)
	frame.Size              = UDim2.new(0, 370, 0, 88)
	frame.Position          = UDim2.new(0.5, 0, -0.2, 0)
	frame.BackgroundColor3  = Color3.fromRGB(8, 8, 16)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel   = 0
	frame.Parent            = msgScreen
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

	local strip = Instance.new("Frame")
	strip.Size             = UDim2.new(1, 0, 0, 4)
	strip.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
	strip.BorderSizePixel  = 0
	strip.Parent           = frame
	Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 16)

	local sub = Instance.new("TextLabel")
	sub.Size                  = UDim2.new(1, -20, 0, 22)
	sub.Position              = UDim2.new(0, 12, 0, 6)
	sub.BackgroundTransparency = 1
	sub.Text                  = "⚡  HAK System"
	sub.TextColor3            = Color3.fromRGB(180, 130, 255)
	sub.Font                  = Enum.Font.GothamBold
	sub.TextSize              = 11
	sub.TextXAlignment        = Enum.TextXAlignment.Left
	sub.Parent                = frame

	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(1, -20, 0, 48)
	lbl.Position              = UDim2.new(0, 12, 0, 30)
	lbl.BackgroundTransparency = 1
	lbl.Text                  = message
	lbl.TextColor3            = Color3.fromRGB(255, 240, 100)
	lbl.Font                  = Enum.Font.GothamBold
	lbl.TextSize              = 22
	lbl.TextWrapped           = true
	lbl.TextXAlignment        = Enum.TextXAlignment.Left
	lbl.Parent                = frame

	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0.06, 0)
	}):Play()

	task.delay(5, function()
		if msgScreen and msgScreen.Parent then
			TweenService:Create(frame, TweenInfo.new(0.3), {
				Position = UDim2.new(0.5, 0, -0.2, 0)
			}):Play()
			task.wait(0.35)
			msgScreen:Destroy()
		end
	end)
end)

print("✅ HAK Client loaded — " .. player.Name)
