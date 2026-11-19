-- ThiefService.luau
-- The Sneaky Goblin. Every so often he creeps out of his cave, crosses the
-- map on a ring path that keeps him clear of the Meme Machine, snatches a
-- brainrot from any base careless enough to be unlocked, and dashes home.
-- The victim can chase him down: get close enough during the escape and he
-- drops the catch where he stands.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local ThiefService = {}

local world = nil
local goblin = nil
local rng = Random.new()

local function announce(text)
	local remotes = ReplicatedStorage:FindFirstChild("BrainrotRemotes")
	local banner = remotes and remotes:FindFirstChild("Banner")
	if banner then
		banner:FireAllClients(text)
	end
end

local function goblinRoot()
	return goblin and goblin.PrimaryPart
end

local function parkGoblin()
	local root = goblinRoot()
	if root and world then
		local inside = world.CaveInsideCFrame
		root.CFrame = CFrame.new(inside.Position + Vector3.new(0, BrainrotFactory.GoblinFeetOffset, 0))
			* inside.Rotation
	end
end

-- Walk the goblin's root toward a ground point. When a victim is given,
-- every step also checks whether that victim has run him down.
local function walkTo(groundTarget, groundHeight, victim)
	local root = goblinRoot()
	if not root then
		return "arrived"
	end
	while root.Parent do
		local dt = task.wait()
		local target = Vector3.new(groundTarget.X,
			groundHeight + BrainrotFactory.GoblinFeetOffset, groundTarget.Z)
		local position = root.Position
		local delta = target - position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if flat.Magnitude < 1.1 then
			return "arrived"
		end
		local step = math.min(flat.Magnitude, Config.GoblinSpeed * dt)
		local newPosition = position + flat.Unit * step
		newPosition = Vector3.new(newPosition.X,
			position.Y + math.clamp(delta.Y, -Config.GoblinSpeed * dt, Config.GoblinSpeed * dt),
			newPosition.Z)
		root.CFrame = CFrame.lookAt(newPosition, newPosition + flat)

		if victim then
			local character = victim.Character
			local victimRoot = character and character:FindFirstChild("HumanoidRootPart")
			if victimRoot then
				local gap = (Vector3.new(victimRoot.Position.X, 0, victimRoot.Position.Z)
					- Vector3.new(newPosition.X, 0, newPosition.Z)).Magnitude
				if gap < Config.GoblinCatchDistance then
					return "caught"
				end
			end
		end
	end
	return "arrived"
end

-- Waypoints from the cave to a base and back: out of the mouth, along the
-- ring road at radius 70 (outside the plaza, inside the bases, never
-- through the Meme Machine), then in to the base itself.
local function ringPath(fromPosition, baseCenter)
	local points = {}
	local fromAngle = math.atan2(fromPosition.Z, fromPosition.X)
	local toAngle = math.atan2(baseCenter.Z, baseCenter.X)
	local sweep = toAngle - fromAngle
	while sweep > math.pi do
		sweep = sweep - math.pi * 2
	end
	while sweep < -math.pi do
		sweep = sweep + math.pi * 2
	end
	local steps = math.max(1, math.ceil(math.abs(sweep) / math.rad(50)))
	for step = 1, steps do
		local angle = fromAngle + sweep * (step / steps)
		table.insert(points, Vector3.new(math.cos(angle) * 70, 0, math.sin(angle) * 70))
	end
	local approach = baseCenter - baseCenter.Unit * 13
	table.insert(points, Vector3.new(approach.X, 0, approach.Z))
	return points
end

local function walkPath(points, groundHeight, victim)
	for _, point in ipairs(points) do
		local result = walkTo(point, groundHeight, victim)
		if result == "caught" then
			return "caught"
		end
	end
	return "arrived"
end

local function pickVictim()
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.Get(player)
		if data and #data.Placed > 0 and not BaseManager.IsLocked(player) then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

local function runRaid()
	local victim = pickVictim()
	if not victim or not world then
		return
	end
	local base = BaseManager.GetBase(victim)
	if not base then
		return
	end
	local root = goblinRoot()
	if not root then
		return
	end

	announce("A Sneaky Goblin is creeping out of his cave...")
	walkTo(world.CaveMouthCFrame.Position, 0, nil)
	local outward = ringPath(root.Position, base.Center)
	walkPath(outward, 0, nil)

	local data = PlayerData.Get(victim)
	if not data or #data.Placed == 0 or victim.Parent == nil then
		walkPath(ringPath(base.Center, world.CaveMouthCFrame.Position), 0, nil)
		parkGoblin()
		return
	end
	if BaseManager.IsLocked(victim) then
		announce("The Sneaky Goblin found " .. victim.DisplayName .. "'s base LOCKED and slunk away!")
		walkPath(ringPath(base.Center, world.CaveMouthCFrame.Position), 0, nil)
		parkGoblin()
		return
	end

	local entry = EconomyService.StealRandomPlaced(victim)
	if not entry or not entry.Model or not entry.Model.PrimaryPart then
		walkPath(ringPath(base.Center, world.CaveMouthCFrame.Position), 0, nil)
		parkGoblin()
		return
	end

	local lootPosition = entry.Model.PrimaryPart.Position
	walkTo(lootPosition, base.PlotTop, nil)

	local lootRoot = entry.Model.PrimaryPart
	lootRoot.Anchored = false
	lootRoot.CFrame = root.CFrame * CFrame.new(0, 3.4, 0.9)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = lootRoot
	weld.Parent = lootRoot
	entry.CarryWeld = weld

	announce("The Sneaky Goblin stole " .. entry.Def.Name .. " from "
		.. victim.DisplayName .. "'s base! Chase him down!")

	local homeward = ringPath(base.Center, world.CaveMouthCFrame.Position)
	local result = walkPath(homeward, 0, victim)
	if result == "caught" then
		local dropGround = Vector3.new(root.Position.X,
			root.Position.Y - BrainrotFactory.GoblinFeetOffset, root.Position.Z)
		EconomyService.DropStolenEntry(entry, dropGround)
		announce("Caught! The goblin dropped the " .. entry.Def.Name .. "!")
		walkTo(world.CaveMouthCFrame.Position, 0, nil)
		parkGoblin()
		return
	end

	walkTo(world.CaveMouthCFrame.Position, 0, nil)
	parkGoblin()
	if entry.Model then
		entry.Model:Destroy()
	end
	entry.State = "Gone"
	announce("The goblin got away with the " .. entry.Def.Name .. "!")
end

function ThiefService.Init(gameWorld)
	world = gameWorld
	goblin = BrainrotFactory.BuildGoblin()
	goblin.Parent = Workspace
	parkGoblin()
end

function ThiefService.Start()
	task.spawn(function()
		task.wait(Config.GoblinFirstVisit)
		while true do
			local ok, err = pcall(runRaid)
			if not ok then
				warn("Goblin raid failed: " .. tostring(err))
				parkGoblin()
			end
			task.wait(rng:NextNumber(Config.GoblinVisitMinGap, Config.GoblinVisitMaxGap))
		end
	end)
end

return ThiefService
