-- BaseManager.luau
-- Hands out the six bases, keeps the owner signs honest, and runs the base
-- lock: sixty seconds of energy walls, then a cooldown before the owner can
-- lock again. The lock state itself lives in PlayerData; this module owns
-- the visuals and the rules around it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

local world = nil
local ownerByIndex = {}

local function stateChangedEvent()
	local remotes = ReplicatedStorage:FindFirstChild("BrainrotRemotes")
	if remotes then
		return remotes:FindFirstChild("StateChanged")
	end
	return nil
end

local function setWalls(base, on)
	for _, wall in ipairs(base.Walls) do
		wall.Transparency = on and 0.35 or 1
		wall.CanCollide = on
	end
end

local function setSign(base, text)
	for _, label in ipairs(base.SignLabels) do
		label.Text = text
	end
end

function BaseManager.Init(gameWorld)
	world = gameWorld
	for _, base in ipairs(world.Bases) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LockPrompt"
		prompt.ActionText = "Lock Base"
		prompt.ObjectText = "60 seconds"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = Config.PromptDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = base.LockPad
		prompt.Triggered:Connect(function(player)
			if ownerByIndex[base.Index] == player then
				BaseManager.TryLock(player)
			end
		end)
	end
end

-- Give a joining player the first free base and put their name over it.
function BaseManager.AssignBase(player)
	local data = PlayerData.Get(player)
	if not data or not world then
		return nil
	end
	if data.BaseIndex then
		return world.Bases[data.BaseIndex]
	end
	for _, base in ipairs(world.Bases) do
		if not ownerByIndex[base.Index] then
			ownerByIndex[base.Index] = player
			data.BaseIndex = base.Index
			setSign(base, player.DisplayName .. "'s Base")
			return base
		end
	end
	return nil
end

function BaseManager.ReleaseBase(player)
	local data = PlayerData.Get(player)
	if not data or not data.BaseIndex or not world then
		return
	end
	local base = world.Bases[data.BaseIndex]
	ownerByIndex[data.BaseIndex] = nil
	data.BaseIndex = nil
	if base then
		setWalls(base, false)
		setSign(base, "EMPTY BASE")
	end
end

function BaseManager.GetBase(player)
	local data = PlayerData.Get(player)
	if not data or not data.BaseIndex or not world then
		return nil
	end
	return world.Bases[data.BaseIndex]
end

function BaseManager.IsLocked(player)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	return os.clock() < data.LockUntil
end

function BaseManager.LockSecondsLeft(player)
	local data = PlayerData.Get(player)
	if not data then
		return 0
	end
	return math.max(0, math.ceil(data.LockUntil - os.clock()))
end

function BaseManager.LockCooldownLeft(player)
	local data = PlayerData.Get(player)
	if not data then
		return 0
	end
	return math.max(0, math.ceil(data.LockReadyAt - os.clock()))
end

-- Lock the caller's base if the rules allow it. Returns true on success, or
-- false plus a plain-language reason the HUD can show.
function BaseManager.TryLock(player)
	local data = PlayerData.Get(player)
	local base = BaseManager.GetBase(player)
	if not data or not base then
		return false, "You have no base to lock"
	end
	local now = os.clock()
	if now < data.LockUntil then
		return false, "Base is already locked"
	end
	if now < data.LockReadyAt then
		return false, "Lock recharging: " .. math.ceil(data.LockReadyAt - now) .. "s"
	end
	data.LockUntil = now + Config.LockDuration
	data.LockReadyAt = data.LockUntil + Config.LockCooldown
	setWalls(base, true)
	local event = stateChangedEvent()
	if event then
		event:FireClient(player)
	end
	return true, "Base locked for " .. Config.LockDuration .. " seconds"
end

-- Watch the clocks and drop the walls the moment a lock runs out.
function BaseManager.Start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			if world then
				for index, owner in pairs(ownerByIndex) do
					local data = PlayerData.Get(owner)
					local base = world.Bases[index]
					if data and base then
						local locked = os.clock() < data.LockUntil
						local wallsOn = base.Walls[1].CanCollide
						if locked ~= wallsOn then
							setWalls(base, locked)
							local event = stateChangedEvent()
							if event then
								event:FireClient(owner)
							end
						end
					end
				end
			end
		end
	end)
end

return BaseManager
