-- WorldBuilder.luau
-- Builds the whole Brainrot Bunker world out of Parts when the server
-- starts: the plaza and Meme Machine, eight runways, six player bases, the
-- rainbow gate, decorations and the Goblin Cave. Nothing in the place file
-- itself has to be placed by hand, and this module hands back references to
-- everything the other services need (pads, pedestals, posts, walls).

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local PLAZA_TOP = 0.6
local RUNWAY_TOP = 1.1
local PLOT_TOP = 0.75
local BASE_RADIUS = 95

local BASE_COLORS = {
	Color3.fromRGB(224, 62, 62),
	Color3.fromRGB(52, 116, 235),
	Color3.fromRGB(66, 184, 84),
	Color3.fromRGB(245, 197, 48),
	Color3.fromRGB(146, 88, 235),
	Color3.fromRGB(245, 130, 42),
}

local RAINBOW = {
	Color3.fromRGB(235, 62, 62),
	Color3.fromRGB(245, 130, 42),
	Color3.fromRGB(245, 210, 48),
	Color3.fromRGB(66, 184, 84),
	Color3.fromRGB(52, 116, 235),
	Color3.fromRGB(146, 88, 235),
}

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Parent = parent
	return part
end

-- A board whose message reads from both sides, so nobody ever has to care
-- which way the part happens to face.
local function makeBoard(parent, name, size, cframe, boardColor, text, textColor)
	local board = makePart(parent, name, size, cframe, boardColor)
	local labels = {}
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = textColor
		label.Parent = gui
		table.insert(labels, label)
	end
	return board, labels
end

local function buildMachine(parent)
	local machine = Instance.new("Model")
	machine.Name = "MemeMachine"
	machine.Parent = parent

	makePart(machine, "Body", Vector3.new(16, 19, 16),
		CFrame.new(0, PLAZA_TOP + 9.5, 0), Color3.fromRGB(122, 74, 205))

	for _, side in ipairs({ -9.5, 9.5 }) do
		local pipe = makePart(machine, "Pipe", Vector3.new(13, 2.2, 2.2),
			CFrame.new(side, PLAZA_TOP + 6.5, 0),
			Color3.fromRGB(90, 200, 220), Enum.Material.Neon)
		pipe.Shape = Enum.PartType.Cylinder
	end

	local button = makePart(machine, "BigButton", Vector3.new(1.2, 3.6, 3.6),
		CFrame.new(0, PLAZA_TOP + 7, 8.4) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(235, 62, 84), Enum.Material.Neon)
	button.Shape = Enum.PartType.Cylinder

	makeBoard(machine, "NameBoard", Vector3.new(21, 4.6, 0.8),
		CFrame.new(0, PLAZA_TOP + 16.8, 8.2),
		Color3.fromRGB(38, 34, 54), "THE MEME MACHINE", Color3.fromRGB(255, 226, 92))

	local spinner = makePart(machine, "Spinner", Vector3.new(1.6, 13, 13),
		CFrame.new(0, PLAZA_TOP + 20.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 150, 66), Enum.Material.Neon)
	local spinnerHome = spinner.Position
	task.spawn(function()
		local angle = 0
		while spinner.Parent do
			local dt = task.wait()
			angle = angle + math.rad(45) * dt
			spinner.CFrame = CFrame.new(spinnerHome)
				* CFrame.Angles(0, angle, 0)
				* CFrame.Angles(0, 0, math.rad(90))
		end
	end)

	return machine
end

local function buildGate(parent)
	local gate = Instance.new("Folder")
	gate.Name = "RainbowGate"
	gate.Parent = parent
	local gateZ = 56

	for _, side in ipairs({ -11, 11 }) do
		makePart(gate, "Post", Vector3.new(1.8, 11.5, 1.8),
			CFrame.new(side, PLAZA_TOP + 5.75, gateZ), Color3.fromRGB(240, 240, 245))
	end
	for step = 0, 12 do
		local angle = (step / 12) * math.pi
		local color = RAINBOW[(step % #RAINBOW) + 1]
		makePart(gate, "Arc", Vector3.new(2, 2, 2),
			CFrame.new(math.cos(angle) * 11, PLAZA_TOP + 11 + math.sin(angle) * 11, gateZ)
				* CFrame.Angles(0, 0, angle),
			color)
	end

	makeBoard(gate, "TitleBoard", Vector3.new(25, 6.5, 1),
		CFrame.new(0, 8.5, 69),
		Color3.fromRGB(38, 34, 54),
		"BRAINROT BUNKER - Collect, Earn, Defend!", Color3.fromRGB(140, 255, 190))
	for _, side in ipairs({ -10, 10 }) do
		makePart(gate, "TitlePost", Vector3.new(1.2, 8.5, 1.2),
			CFrame.new(side, 4.25, 69), Color3.fromRGB(90, 84, 110))
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GateSpawn"
	spawn.Size = Vector3.new(9, 1, 9)
	spawn.CFrame = CFrame.new(0, PLAZA_TOP + 0.5, 62)
	spawn.Color = Color3.fromRGB(120, 220, 160)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = gate
end

local function buildBase(parent, index, angleRad)
	local color = BASE_COLORS[index]
	local center = Vector3.new(math.cos(angleRad) * BASE_RADIUS, 0, math.sin(angleRad) * BASE_RADIUS)
	local baseCFrame = CFrame.lookAt(center, Vector3.new(0, 0, 0))

	local model = Instance.new("Model")
	model.Name = "Base" .. index
	model.Parent = parent

	local function localPart(name, size, localPos, partColor, material)
		return makePart(model, name, size, baseCFrame * CFrame.new(localPos), partColor, material)
	end

	localPart("Plot", Vector3.new(36, 1, 36), Vector3.new(0, 0.25, 0), color)
	local trimColor = color:Lerp(Color3.new(0, 0, 0), 0.25)
	localPart("TrimFront", Vector3.new(36.8, 1.3, 1), Vector3.new(0, 0.35, -18), trimColor)
	localPart("TrimBack", Vector3.new(36.8, 1.3, 1), Vector3.new(0, 0.35, 18), trimColor)
	localPart("TrimLeft", Vector3.new(1, 1.3, 36.8), Vector3.new(-18, 0.35, 0), trimColor)
	localPart("TrimRight", Vector3.new(1, 1.3, 36.8), Vector3.new(18, 0.35, 0), trimColor)

	local pedestals = {}
	local pedestalNumber = 0
	for _, localZ in ipairs({ -5, 5.5 }) do
		for _, localX in ipairs({ -9.5, 0, 9.5 }) do
			pedestalNumber = pedestalNumber + 1
			local pedestal = makePart(model, "Pedestal" .. pedestalNumber,
				Vector3.new(0.8, 3.4, 3.4),
				baseCFrame * CFrame.new(localX, PLOT_TOP + 0.4, localZ)
					* CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(238, 238, 242))
			pedestal.Shape = Enum.PartType.Cylinder
			local topPosition = (baseCFrame * CFrame.new(localX, PLOT_TOP + 0.8, localZ)).Position
			table.insert(pedestals, { Part = pedestal, TopPosition = topPosition, Index = pedestalNumber })
		end
	end

	for _, side in ipairs({ -7, 7 }) do
		localPart("SignPost", Vector3.new(0.7, 6, 0.7), Vector3.new(side, PLOT_TOP + 3, 15),
			Color3.fromRGB(90, 84, 110))
	end
	local _, signLabels = makeBoard(model, "OwnerSign", Vector3.new(19, 5, 0.9),
		baseCFrame * CFrame.new(0, PLOT_TOP + 6.5, 15),
		Color3.fromRGB(38, 34, 54), "EMPTY BASE", Color3.new(1, 1, 1))

	local placePost = localPart("PlacePost", Vector3.new(0.8, 5.5, 0.8),
		Vector3.new(0, PLOT_TOP + 2.75, -13.5), Color3.fromRGB(255, 226, 92))
	local postTop = makePart(model, "PlacePostTop", Vector3.new(1.35, 1.35, 1.35),
		baseCFrame * CFrame.new(0, PLOT_TOP + 5.9, -13.5),
		Color3.fromRGB(255, 226, 92), Enum.Material.Neon)
	postTop.Shape = Enum.PartType.Ball
	local postGui = Instance.new("BillboardGui")
	postGui.Name = "PostLabel"
	postGui.Size = UDim2.fromOffset(150, 40)
	postGui.StudsOffset = Vector3.new(0, 3.6, 0)
	postGui.AlwaysOnTop = true
	postGui.LightInfluence = 0
	local postText = Instance.new("TextLabel")
	postText.Size = UDim2.new(1, 0, 1, 0)
	postText.BackgroundTransparency = 1
	postText.Font = Enum.Font.GothamBold
	postText.TextScaled = true
	postText.Text = "PLACE HERE"
	postText.TextColor3 = Color3.fromRGB(255, 226, 92)
	postText.TextStrokeTransparency = 0.4
	postText.Parent = postGui
	postGui.Parent = placePost

	local lockPad = makePart(model, "LockPad", Vector3.new(0.4, 6.5, 6.5),
		baseCFrame * CFrame.new(11.5, PLOT_TOP + 0.2, -9)
			* CFrame.Angles(0, 0, math.rad(90)),
		color:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.Neon)
	lockPad.Shape = Enum.PartType.Cylinder

	localPart("SpawnPad", Vector3.new(6, 0.5, 6), Vector3.new(-11.5, PLOT_TOP + 0.25, 8),
		color:Lerp(Color3.new(1, 1, 1), 0.5))

	local walls = {}
	local wallColor = Color3.fromRGB(120, 235, 255)
	local function energyWall(name, size, localPos)
		local wall = localPart(name, size, localPos, wallColor, Enum.Material.ForceField)
		wall.Transparency = 1
		wall.CanCollide = false
		table.insert(walls, wall)
		return wall
	end
	energyWall("WallFront", Vector3.new(37, 6.5, 0.7), Vector3.new(0, PLOT_TOP + 3.25, -18))
	energyWall("WallBack", Vector3.new(37, 6.5, 0.7), Vector3.new(0, PLOT_TOP + 3.25, 18))
	energyWall("WallLeft", Vector3.new(0.7, 6.5, 37), Vector3.new(-18, PLOT_TOP + 3.25, 0))
	energyWall("WallRight", Vector3.new(0.7, 6.5, 37), Vector3.new(18, PLOT_TOP + 3.25, 0))

	return {
		Index = index,
		Color = color,
		Center = center,
		Model = model,
		Pedestals = pedestals,
		PlacePost = placePost,
		LockPad = lockPad,
		SignLabels = signLabels,
		Walls = walls,
		SpawnCFrame = baseCFrame * CFrame.new(-11.5, PLOT_TOP + 3, 8),
		PlotTop = PLOT_TOP,
	}
end

local function buildCave(parent)
	local angleRad = math.rad(200)
	local center = Vector3.new(math.cos(angleRad) * 168, 0, math.sin(angleRad) * 168)
	local caveCFrame = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	local cave = Instance.new("Model")
	cave.Name = "GoblinCave"
	cave.Parent = parent

	local rockColor = Color3.fromRGB(72, 72, 80)
	local function rock(name, size, localPos)
		return makePart(cave, name, size, caveCFrame * CFrame.new(localPos), rockColor, Enum.Material.Slate)
	end
	rock("RockLeft", Vector3.new(7, 11, 12), Vector3.new(-7.5, 5.5, 0))
	rock("RockRight", Vector3.new(7, 11, 12), Vector3.new(7.5, 5.5, 0))
	rock("RockTop", Vector3.new(22, 6, 13), Vector3.new(0, 13, 0))
	rock("RockBack", Vector3.new(22, 13, 3), Vector3.new(0, 6.5, 6))
	makePart(cave, "CaveFloor", Vector3.new(20, 0.6, 16),
		caveCFrame * CFrame.new(0, 0.3, 0), Color3.fromRGB(40, 38, 46))
	makeBoard(cave, "CaveSign", Vector3.new(15, 3.6, 0.8),
		caveCFrame * CFrame.new(0, 17.5, -2),
		Color3.fromRGB(30, 28, 36), "GOBLIN CAVE", Color3.fromRGB(255, 110, 110))

	return {
		MouthCFrame = caveCFrame * CFrame.new(0, 1, -13),
		InsideCFrame = caveCFrame * CFrame.new(0, 1, 3),
		Center = center,
	}
end

local function buildDecor(parent, bases, caveCenter)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = parent

	local function farFromBases(position, distance)
		for _, base in ipairs(bases) do
			if (Vector3.new(position.X, 0, position.Z) - base.Center).Magnitude < distance then
				return false
			end
		end
		if (Vector3.new(position.X, 0, position.Z) - caveCenter).Magnitude < distance then
			return false
		end
		return true
	end

	local candyColors = {
		Color3.fromRGB(255, 110, 180), Color3.fromRGB(110, 220, 255),
		Color3.fromRGB(170, 255, 120), Color3.fromRGB(255, 190, 90),
	}
	for i = 1, 18 do
		local angle = i * 2.4
		local radius = 72 + (i % 5) * 21
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if farFromBases(position, 27) then
			local trunk = makePart(decor, "CandyTrunk", Vector3.new(3.4, 0.9, 0.9),
				CFrame.new(position.X, 1.7, position.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(130, 88, 54))
			trunk.Shape = Enum.PartType.Cylinder
			local crownColor = candyColors[(i % #candyColors) + 1]
			local crown = makePart(decor, "CandyCrown", Vector3.new(4.8, 4.8, 4.8),
				CFrame.new(position.X, 5.4, position.Z), crownColor)
			crown.Shape = Enum.PartType.Ball
			local topBall = makePart(decor, "CandyTop", Vector3.new(3.1, 3.1, 3.1),
				CFrame.new(position.X + 1.2, 7.3, position.Z),
				crownColor:Lerp(Color3.new(1, 1, 1), 0.25))
			topBall.Shape = Enum.PartType.Ball
		end
	end

	for i = 1, 10 do
		local angle = math.rad((i - 1) * 36)
		local position = Vector3.new(math.cos(angle) * 61, 0, math.sin(angle) * 61)
		makePart(decor, "LampPost", Vector3.new(0.35, 5.6, 0.35),
			CFrame.new(position.X, PLAZA_TOP + 2.8, position.Z), Color3.fromRGB(50, 50, 58))
		local bulb = makePart(decor, "LampBulb", Vector3.new(0.95, 0.95, 0.95),
			CFrame.new(position.X, PLAZA_TOP + 5.9, position.Z),
			Color3.fromRGB(255, 230, 160), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 224, 150)
		light.Range = 20
		light.Brightness = 1.1
		light.Parent = bulb
	end

	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45 + 20)
		local radius = 45 + (i % 4) * 32
		local basePos = Vector3.new(math.cos(angle) * radius, 52 + (i % 3) * 6, math.sin(angle) * radius)
		for j = 1, 3 do
			local puff = makePart(decor, "Cloud", Vector3.new(9 + j * 2.5, 2.2, 6 + j),
				CFrame.new(basePos.X + (j - 2) * 5, basePos.Y, basePos.Z + (j % 2) * 3),
				Color3.fromRGB(250, 250, 252))
			puff.CanCollide = false
		end
	end

	local fenceColors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(120, 200, 255) }
	local half = 196
	for side = 1, 4 do
		for step = 0, 16 do
			local along = -half + step * (half * 2 / 16)
			local position
			if side == 1 then
				position = Vector3.new(along, 0, -half)
			elseif side == 2 then
				position = Vector3.new(along, 0, half)
			elseif side == 3 then
				position = Vector3.new(-half, 0, along)
			else
				position = Vector3.new(half, 0, along)
			end
			makePart(decor, "FencePost", Vector3.new(0.55, 3.4, 0.55),
				CFrame.new(position.X, 1.7, position.Z), fenceColors[(step % 2) + 1])
		end
		for _, railY in ipairs({ 1.6, 2.9 }) do
			local railSize = side <= 2 and Vector3.new(half * 2, 0.35, 0.35) or Vector3.new(0.35, 0.35, half * 2)
			local railPos
			if side == 1 then
				railPos = Vector3.new(0, railY, -half)
			elseif side == 2 then
				railPos = Vector3.new(0, railY, half)
			elseif side == 3 then
				railPos = Vector3.new(-half, railY, 0)
			else
				railPos = Vector3.new(half, railY, 0)
			end
			makePart(decor, "FenceRail", railSize, CFrame.new(railPos), Color3.fromRGB(240, 240, 245))
		end
	end
end

-- Build everything and hand back the reference table the services share.
function WorldBuilder.Build()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(170, 170, 185)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 155, 175)

	local folder = Instance.new("Folder")
	folder.Name = "BrainrotWorld"
	folder.Parent = Workspace

	local brainrots = Instance.new("Folder")
	brainrots.Name = "Brainrots"
	brainrots.Parent = Workspace

	makePart(folder, "Ground", Vector3.new(400, 1, 400),
		CFrame.new(0, -0.5, 0), Color3.fromRGB(96, 190, 84), Enum.Material.Grass)

	local plaza = makePart(folder, "Plaza", Vector3.new(0.6, 112, 112),
		CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 196, 92))
	plaza.Shape = Enum.PartType.Cylinder

	buildMachine(folder)
	buildGate(folder)

	local runways = {}
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local position = Vector3.new(math.cos(angle) * 32, 0, math.sin(angle) * 32)
		local pad = makePart(folder, "Runway" .. i, Vector3.new(9, 0.5, 9),
			CFrame.new(position.X, PLAZA_TOP + 0.25, position.Z),
			RAINBOW[(i % #RAINBOW) + 1])
		table.insert(runways, {
			Index = i,
			Pad = pad,
			TopY = RUNWAY_TOP,
			Center = Vector3.new(position.X, 0, position.Z),
			Outward = Vector3.new(math.cos(angle), 0, math.sin(angle)),
		})
	end

	local bases = {}
	for i = 1, 6 do
		local angle = math.rad((i - 1) * 60)
		table.insert(bases, buildBase(folder, i, angle))
	end

	local cave = buildCave(folder)
	buildDecor(folder, bases, cave.Center)

	return {
		Folder = folder,
		Runways = runways,
		Bases = bases,
		CaveMouthCFrame = cave.MouthCFrame,
		CaveInsideCFrame = cave.InsideCFrame,
		PlazaTop = PLAZA_TOP,
	}
end

return WorldBuilder
