local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Questions = require(Shared:WaitForChild("Questions"))

local remotes = Instance.new("Folder")
remotes.Name = "QRunRemotes"
remotes.Parent = ReplicatedStorage
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes
local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes

local world = Instance.new("Folder")
world.Name = "QRunWorld"
world.Parent = workspace
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local sessions = {}
local nextLane = 0

local multipliers = { { 100, 64 }, { 70, 32 }, { 40, 16 }, { 20, 8 }, { 10, 4 }, { 5, 2 }, { 0, 1 } }
local function multiplier(streak)
	for _, entry in multipliers do
		if streak >= entry[1] then return entry[2] end
	end
	return 1
end

local function part(parent, name, size, cframe, color, material)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, cframe
	item.Anchored, item.Color, item.Material = true, color, material or Enum.Material.SmoothPlastic
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function labelOn(panel, text)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.AlwaysOnTop = true
	surface.Parent = panel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.Parent = surface
end

local function createLane(index)
	local lane = Instance.new("Model")
	lane.Name = "Lane_" .. index
	lane.Parent = world
	local x = index * Config.LaneSpacing
	part(lane, "Track", Vector3.new(Config.LaneWidth, 1, Config.LaneLength), CFrame.new(x, 0, 20), Color3.fromRGB(38, 46, 65))
	part(lane, "LeftRail", Vector3.new(1, 5, Config.LaneLength), CFrame.new(x - Config.LaneWidth / 2, 2, 20), Color3.fromRGB(48, 210, 255), Enum.Material.Neon)
	part(lane, "RightRail", Vector3.new(1, 5, Config.LaneLength), CFrame.new(x + Config.LaneWidth / 2, 2, 20), Color3.fromRGB(255, 71, 126), Enum.Material.Neon)
	local spawn = part(lane, "Spawn", Vector3.new(8, 0.4, 5), CFrame.new(x, 0.7, -3), Color3.fromRGB(87, 255, 129), Enum.Material.Neon)
	spawn.CanCollide = false
	return lane, Vector3.new(x, 4, -3)
end

local function clearRound(session)
	if session.roundModel then session.roundModel:Destroy() session.roundModel = nil end
end

local function send(session, kind, extra)
	extra = extra or {}
	extra.kind, extra.score, extra.streak = kind, session.score, session.streak
	extra.multiplier, extra.bestScore, extra.revives = multiplier(session.streak), session.bestScore, session.revives
	extra.freeRevive, extra.tickets = session.freeRevive, session.tickets
	stateEvent:FireClient(session.player, extra)
end

local function positionCharacter(session)
	local character = session.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root then root.CFrame = CFrame.new(session.spawn) * CFrame.Angles(0, math.pi, 0) end
	if humanoid then
		humanoid.WalkSpeed = math.min(24, 16 + session.streak * 0.08)
		humanoid.JumpPower = 0
		humanoid.Health = humanoid.MaxHealth
	end
end

local function addObstacle(session, model)
	local roll = session.random:NextNumber()
	if session.streak < 2 or roll > math.min(0.72, 0.15 + session.streak * 0.018) then return end
	local laneX = session.spawn.X
	if roll < 0.38 then
		for i = 1, math.min(3, 1 + math.floor(session.streak / 15)) do
			local x = laneX + session.random:NextNumber(-15, 15)
			local z = session.random:NextNumber(12, 34)
			local rock = part(model, "Rock", Vector3.new(4, 5, 4), CFrame.new(x, 2.5, z) * CFrame.Angles(0.2, roll * 4, 0.1), Color3.fromRGB(103, 91, 83), Enum.Material.Slate)
			rock.Anchored = true
		end
	elseif roll < 0.58 then
		local mud = part(model, "StickyMud", Vector3.new(16, 0.3, 10), CFrame.new(laneX, 0.7, 22), Color3.fromRGB(99, 63, 38), Enum.Material.Mud)
		mud.Touched:Connect(function(hit)
			local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid and Players:GetPlayerFromCharacter(hit.Parent) == session.player then
				humanoid.WalkSpeed = 8
				task.delay(1.1, function() if humanoid.Parent then humanoid.WalkSpeed = math.min(24, 16 + session.streak * 0.08) end end)
			end
		end)
	else
		local ice = part(model, "Ice", Vector3.new(24, 0.25, 13), CFrame.new(laneX, 0.68, 23), Color3.fromRGB(142, 229, 255), Enum.Material.Ice)
		ice.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.01, 0, 1, 1)
	end
end

local beginRound
local function fail(session, reason)
	if not session.running then return end
	session.running = false
	clearRound(session)
	session.bestScore = math.max(session.bestScore, session.score)
	send(session, "failed", { reason = reason, canRevive = session.revives < Config.MaximumRevives and (session.freeRevive or session.tickets > 0) })
end

beginRound = function(session)
	if not session.player.Parent then return end
	session.running = true
	positionCharacter(session)
	clearRound(session)
	local question = Questions.next(session.random, session.questionId)
	session.questionId = question.id
	local model = Instance.new("Model")
	model.Name = "Round"
	model.Parent = session.lane
	session.roundModel = model
	addObstacle(session, model)
	local x = session.spawn.X
	local doorWidth = Config.LaneWidth / 2
	local colors = { Color3.fromRGB(30, 195, 255), Color3.fromRGB(255, 66, 119) }
	local panels = {}
	for side = 1, 2 do
		local offset = side == 1 and -doorWidth / 2 or doorWidth / 2
		local panel = part(model, side == 1 and "LeftAnswer" or "RightAnswer", Vector3.new(doorWidth - 1, 13, 2), CFrame.new(x + offset, 6.5, Config.WallStartZ), colors[side], Enum.Material.Neon)
		panel.Transparency = side == question.correct and 0.65 or 0
		panel.CanCollide = side ~= question.correct
		labelOn(panel, question.answers[side])
		panels[side] = panel
	end
	local answerTime = math.max(Config.MinimumAnswerTime, Config.BaseAnswerTime - session.streak * Config.AnswerTimeDecay)
	send(session, "question", { prompt = question.prompt, answers = question.answers, duration = answerTime, category = question.category })
	for _, panel in panels do
		TweenService:Create(panel, TweenInfo.new(answerTime, Enum.EasingStyle.Linear), { CFrame = CFrame.new(panel.Position.X, panel.Position.Y, Config.WallEndZ) }):Play()
	end
	task.delay(answerTime, function()
		if not session.running or session.roundModel ~= model then return end
		local root = session.player.Character and session.player.Character:FindFirstChild("HumanoidRootPart")
		if not root then fail(session, "fell") return end
		local chosen = root.Position.X < x and 1 or 2
		if chosen == question.correct then
			session.streak += 1
			session.bestStreak = math.max(session.bestStreak, session.streak)
			session.score += Config.BasePoints * multiplier(session.streak)
			session.bestScore = math.max(session.bestScore, session.score)
			send(session, "correct", { chosen = chosen })
			task.delay(0.55, function() if session.running then beginRound(session) end end)
		else
			fail(session, "wrong_answer")
		end
	end)
end

local function newRun(session)
	session.score, session.streak, session.revives = 0, 0, 0
	session.freeRevive = true
	beginRound(session)
end

actionEvent.OnServerEvent:Connect(function(player, action)
	local session = sessions[player]
	if not session then return end
	if action == "restart" and not session.running then
		newRun(session)
	elseif action == "revive" and not session.running and session.revives < Config.MaximumRevives then
		if session.freeRevive then
			session.freeRevive = false
		elseif session.tickets > 0 then
			session.tickets -= 1
		else return end
		session.revives += 1
		send(session, "revived")
		task.delay(0.5, function() beginRound(session) end)
	end
end)

local function save(session)
	pcall(function()
		store:UpdateAsync("player_" .. session.player.UserId, function(old)
			old = old or {}
			old.bestScore = math.max(tonumber(old.bestScore) or 0, session.bestScore)
			old.bestStreak = math.max(tonumber(old.bestStreak) or 0, session.bestStreak)
			old.tickets = session.tickets
			return old
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	nextLane += 1
	local lane, spawnPosition = createLane(nextLane)
	local data = {}
	pcall(function() data = store:GetAsync("player_" .. player.UserId) or {} end)
	if type(data) ~= "table" then data = {} end
	local session = { player = player, lane = lane, spawn = spawnPosition, score = 0, streak = 0, bestScore = data.bestScore or 0, bestStreak = data.bestStreak or 0, tickets = data.tickets or 0, revives = 0, freeRevive = true, running = false, random = Random.new(player.UserId + os.time()) }
	sessions[player] = session
	player.CharacterAdded:Connect(function() task.wait(0.2) if sessions[player] then positionCharacter(session) end end)
	if player.Character then positionCharacter(session) end
	task.delay(1, function() if sessions[player] then newRun(session) end end)
end)

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if not session then return end
	save(session)
	session.lane:Destroy()
	sessions[player] = nil
end)

game:BindToClose(function()
	for _, session in sessions do task.spawn(save, session) end
	task.wait(2)
end)
