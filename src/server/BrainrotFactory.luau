-- BrainrotFactory.luau
-- Assembles every character model out of plain Parts: a body, a head with
-- eyes, two legs, two arms and a hat picked from the character's dressing
-- hints. No meshes, no decals, no uploaded assets, so a model looks exactly
-- the same on any machine that opens the place.

local Config = require(script.Parent:WaitForChild("Config"))

local BrainrotFactory = {}

-- How far below a model's root centre its feet reach; callers add this to a
-- surface height when they stand a model on a pad or pedestal.
BrainrotFactory.FeetOffset = 2.1
BrainrotFactory.GoblinFeetOffset = 2.3

local function makePart(name, size, cframe, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	if shape then
		part.Shape = shape
	end
	return part
end

local function weldTo(model, root, part)
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function addLabel(root, lines)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(230, 78)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui

	for index, line in ipairs(lines) do
		local label = Instance.new("TextLabel")
		label.Name = line.Name
		label.LayoutOrder = index
		label.Size = UDim2.new(1, 0, 0, line.Height)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = line.Text
		label.TextColor3 = line.Color
		label.TextStrokeTransparency = 0.35
		label.Parent = gui
	end

	gui.Parent = root
	return gui
end

local function buildHat(model, root, hatKind, accentColor)
	if hatKind == "Antenna" then
		local rod = makePart("HatRod", Vector3.new(0.18, 0.9, 0.18),
			CFrame.new(0, 2.95, 0) * CFrame.Angles(0, 0, math.rad(90)),
			accentColor, Enum.PartType.Cylinder)
		rod.Shape = Enum.PartType.Cylinder
		weldTo(model, root, rod)
		local tip = makePart("HatTip", Vector3.new(0.42, 0.42, 0.42),
			CFrame.new(0, 3.45, 0), accentColor, Enum.PartType.Ball)
		tip.Material = Enum.Material.Neon
		weldTo(model, root, tip)
	elseif hatKind == "Cap" then
		local dome = makePart("HatDome", Vector3.new(0.3, 1.7, 1.7),
			CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
			accentColor, Enum.PartType.Cylinder)
		weldTo(model, root, dome)
		local brim = makePart("HatBrim", Vector3.new(0.95, 0.12, 0.85),
			CFrame.new(0, 2.52, -1.05), accentColor)
		weldTo(model, root, brim)
	elseif hatKind == "TopHat" then
		local dark = Color3.fromRGB(35, 35, 42)
		local brim = makePart("HatBrim", Vector3.new(0.16, 2.15, 2.15),
			CFrame.new(0, 2.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
			dark, Enum.PartType.Cylinder)
		weldTo(model, root, brim)
		local top = makePart("HatTop", Vector3.new(1.35, 1.5, 1.5),
			CFrame.new(0, 3.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
			dark, Enum.PartType.Cylinder)
		weldTo(model, root, top)
	elseif hatKind == "Crown" then
		local gold = Color3.fromRGB(255, 205, 45)
		local band = makePart("HatBand", Vector3.new(0.7, 1.6, 1.6),
			CFrame.new(0, 2.85, 0) * CFrame.Angles(0, 0, math.rad(90)),
			gold, Enum.PartType.Cylinder)
		band.Material = Enum.Material.Neon
		weldTo(model, root, band)
		for i = 1, 4 do
			local angle = (i / 4) * math.pi * 2
			local spike = makePart("HatSpike", Vector3.new(0.3, 0.55, 0.3),
				CFrame.new(math.cos(angle) * 0.62, 3.35, math.sin(angle) * 0.62), gold)
			weldTo(model, root, spike)
		end
	elseif hatKind == "Horn" then
		local horn = Instance.new("WedgePart")
		horn.Name = "HatHorn"
		horn.Size = Vector3.new(0.36, 1.05, 0.36)
		horn.CFrame = CFrame.new(0, 3.1, 0) * CFrame.Angles(math.rad(-18), 0, 0)
		horn.Color = Color3.fromRGB(250, 244, 224)
		horn.Material = Enum.Material.SmoothPlastic
		horn.CanCollide = false
		horn.CanQuery = false
		horn.CanTouch = false
		horn.Massless = true
		weldTo(model, root, horn)
	end
end

-- Build one collectible character. The mutation, when present, repaints the
-- body and prefixes the display name; the income the caller passes in has
-- already had the mutation multiplier applied.
function BrainrotFactory.BuildCharacter(def, mutation, effectiveIncome)
	local model = Instance.new("Model")
	model.Name = def.Name

	local bodyColor = def.Color
	if mutation then
		bodyColor = mutation.Color
	end

	local bodySize = Vector3.new(2.2, 2.6, 1.6)
	local bodyShape = nil
	if def.Body == "Ball" then
		bodySize = Vector3.new(2.6, 2.6, 2.6)
		bodyShape = Enum.PartType.Ball
	elseif def.Body == "Cylinder" then
		bodySize = Vector3.new(2.6, 2.4, 2.6)
		bodyShape = Enum.PartType.Cylinder
	end

	local bodyCFrame = CFrame.new(0, 0, 0)
	if def.Body == "Cylinder" then
		bodyCFrame = CFrame.Angles(0, 0, math.rad(90))
	end
	local body = makePart("Body", bodySize, bodyCFrame, bodyColor, bodyShape)
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body

	local legColor = Color3.fromRGB(52, 52, 60)
	for _, side in ipairs({ -0.55, 0.55 }) do
		local leg = makePart("Leg", Vector3.new(0.55, 0.8, 0.55),
			CFrame.new(side, -1.7, 0), legColor)
		weldTo(model, body, leg)
	end

	for _, side in ipairs({ -1.35, 1.35 }) do
		local arm = makePart("Arm", Vector3.new(0.45, 1.6, 0.45),
			CFrame.new(side, -0.2, 0), def.Accent)
		weldTo(model, body, arm)
	end

	local headColor = def.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	local head = makePart("Head", Vector3.new(1.5, 1.5, 1.5),
		CFrame.new(0, 1.85, 0), headColor, Enum.PartType.Ball)
	weldTo(model, body, head)

	for _, side in ipairs({ -0.32, 0.32 }) do
		local eye = makePart("Eye", Vector3.new(0.22, 0.22, 0.22),
			CFrame.new(side, 1.98, -0.68), Color3.fromRGB(20, 20, 24), Enum.PartType.Ball)
		weldTo(model, body, eye)
	end
	local mouth = makePart("Mouth", Vector3.new(0.5, 0.1, 0.06),
		CFrame.new(0, 1.6, -0.74), Color3.fromRGB(60, 30, 30))
	weldTo(model, body, mouth)

	buildHat(model, body, def.Hat, def.Accent)

	local rarity = Config.GetRarity(def.Rarity)
	local displayName = def.Name
	if mutation then
		displayName = mutation.Name .. " " .. def.Name
	end
	addLabel(body, {
		{ Name = "NameLine", Text = displayName, Color = Color3.new(1, 1, 1), Height = 30 },
		{ Name = "RarityLine", Text = def.Rarity, Color = rarity and rarity.Color or Color3.new(1, 1, 1), Height = 22 },
		{ Name = "IncomeLine", Text = "$" .. tostring(effectiveIncome) .. "/s", Color = Color3.fromRGB(120, 255, 130), Height = 26 },
	})

	model:SetAttribute("CharacterName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	return model
end

-- Build the Sneaky Goblin: green, long ears, a brown sack on his back for
-- whatever he is about to run off with. His root starts anchored because
-- ThiefService walks him by CFrame, never by physics.
function BrainrotFactory.BuildGoblin()
	local model = Instance.new("Model")
	model.Name = "Sneaky Goblin"

	local skin = Color3.fromRGB(74, 160, 60)
	local root = makePart("Root", Vector3.new(2, 2.8, 1.6), CFrame.new(0, 0, 0), skin)
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root

	for _, side in ipairs({ -0.5, 0.5 }) do
		local leg = makePart("Leg", Vector3.new(0.6, 0.9, 0.6),
			CFrame.new(side, -1.85, 0), Color3.fromRGB(90, 64, 40))
		weldTo(model, root, leg)
	end

	local head = makePart("Head", Vector3.new(1.6, 1.6, 1.6),
		CFrame.new(0, 2.05, 0), skin:Lerp(Color3.new(1, 1, 1), 0.15), Enum.PartType.Ball)
	weldTo(model, root, head)

	for _, side in ipairs({ -1, 1 }) do
		local ear = makePart("Ear", Vector3.new(1.15, 0.3, 0.16),
			CFrame.new(side * 1.05, 2.45, 0) * CFrame.Angles(0, 0, side * math.rad(24)), skin)
		weldTo(model, root, ear)
		local eyeWhite = makePart("EyeWhite", Vector3.new(0.36, 0.36, 0.36),
			CFrame.new(side * 0.36, 2.2, -0.72), Color3.new(1, 1, 1), Enum.PartType.Ball)
		weldTo(model, root, eyeWhite)
		local pupil = makePart("Pupil", Vector3.new(0.17, 0.17, 0.17),
			CFrame.new(side * 0.36, 2.2, -0.92), Color3.fromRGB(15, 15, 15), Enum.PartType.Ball)
		weldTo(model, root, pupil)
	end

	local sack = makePart("Sack", Vector3.new(1.35, 1.35, 1.35),
		CFrame.new(0, 0.7, 1.35), Color3.fromRGB(128, 92, 52), Enum.PartType.Ball)
	weldTo(model, root, sack)

	addLabel(root, {
		{ Name = "NameLine", Text = "Sneaky Goblin", Color = Color3.fromRGB(255, 120, 120), Height = 30 },
	})

	return model
end

return BrainrotFactory
