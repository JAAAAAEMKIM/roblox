local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("QRunRemotes")
local stateEvent = remotes:WaitForChild("State")
local actionEvent = remotes:WaitForChild("Action")

local gui = Instance.new("ScreenGui")
gui.Name = "QRunUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function textLabel(name, size, position, text, textSize)
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.Position = name, size, position
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundColor3 = Color3.fromRGB(14, 18, 31)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 12) corner.Parent = label
	return label
end

local question = textLabel("Question", UDim2.fromScale(0.72, 0.115), UDim2.fromScale(0.5, 0.055), "GET READY!", 34)
question.TextScaled = true
local stats = textLabel("Stats", UDim2.fromScale(0.72, 0.06), UDim2.fromScale(0.5, 0.18), "STREAK 0   •   ×1   •   SCORE 0", 24)
stats.BackgroundTransparency = 0.25
local left = textLabel("LeftHint", UDim2.fromScale(0.3, 0.075), UDim2.fromScale(0.22, 0.82), "← LEFT", 25)
left.BackgroundColor3 = Color3.fromRGB(0, 137, 207)
local right = textLabel("RightHint", UDim2.fromScale(0.3, 0.075), UDim2.fromScale(0.78, 0.82), "RIGHT →", 25)
right.BackgroundColor3 = Color3.fromRGB(210, 35, 91)

local result = textLabel("Result", UDim2.fromScale(0.68, 0.32), UDim2.fromScale(0.5, 0.31), "", 28)
result.Visible = false
result.TextWrapped = true
local revive = Instance.new("TextButton")
revive.Size, revive.Position, revive.AnchorPoint = UDim2.fromScale(0.28, 0.08), UDim2.fromScale(0.35, 0.66), Vector2.new(0.5, 0)
revive.BackgroundColor3, revive.TextColor3 = Color3.fromRGB(69, 221, 112), Color3.new(1, 1, 1)
revive.Font, revive.TextSize, revive.Text = Enum.Font.GothamBlack, 22, "SECOND WIND"
revive.Visible, revive.Parent = false, gui
local restart = revive:Clone()
restart.Position, restart.BackgroundColor3, restart.Text = UDim2.fromScale(0.65, 0.66), Color3.fromRGB(255, 75, 100), "NEW RUN"
restart.Parent = gui

local function refreshStats(data)
	stats.Text = string.format("STREAK %d   •   ×%d   •   SCORE %s", data.streak, data.multiplier, tostring(data.score))
end

stateEvent.OnClientEvent:Connect(function(data)
	refreshStats(data)
	if data.kind == "question" then
		result.Visible, revive.Visible, restart.Visible = false, false, false
		question.Text = data.prompt
		left.Text, right.Text = "← " .. data.answers[1], data.answers[2] .. " →"
	elseif data.kind == "correct" then
		question.Text = "CORRECT!  +" .. tostring(100 * data.multiplier)
		question.BackgroundColor3 = Color3.fromRGB(32, 183, 102)
		TweenService:Create(question, TweenInfo.new(0.45), { BackgroundColor3 = Color3.fromRGB(14, 18, 31) }):Play()
	elseif data.kind == "failed" then
		question.Text = "WRONG SIDE!"
		result.Text = string.format("STREAK SAVED?\n\nSCORE %s  •  BEST %s\nCONTINUES %d / 5", data.score, data.bestScore, data.revives)
		result.Visible, restart.Visible = true, true
		revive.Visible = data.canRevive
		revive.Text = data.freeRevive and "FREE SECOND WIND" or "USE REVIVE TICKET"
	elseif data.kind == "revived" then
		result.Visible, revive.Visible, restart.Visible = false, false, false
		question.Text = "SECOND WIND!"
	end
end)

revive.Activated:Connect(function() revive.Visible = false actionEvent:FireServer("revive") end)
restart.Activated:Connect(function() restart.Visible = false result.Visible = false actionEvent:FireServer("restart") end)
