-- SpawnDirector.luau
-- Feeds the runways around the Meme Machine: every few seconds it rolls a
-- rarity on the ladder, picks one of that tier's characters, rolls a lucky
-- mutation, builds the model and hands it to EconomyService to sell.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent:WaitForChild("Config"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local SpawnDirector = {}

local world = nil
local rng = Random.new()

function SpawnDirector.Init(gameWorld)
	world = gameWorld
end

local function freeRunways()
	local free = {}
	if not world then
		return free
	end
	for _, runway in ipairs(world.Runways) do
		if EconomyService.IsRunwayFree(runway.Index) then
			table.insert(free, runway)
		end
	end
	return free
end

local function spawnOne()
	local free = freeRunways()
	if #free == 0 then
		return
	end
	local runway = free[rng:NextInteger(1, #free)]

	local rarity = Config.RollRarity(rng)
	local cast = Config.GetCharactersOfRarity(rarity.Name)
	if #cast == 0 then
		return
	end
	local def = cast[rng:NextInteger(1, #cast)]
	local mutation = Config.RollMutation(rng)
	local effectiveIncome = def.Income * (mutation and mutation.Multiplier or 1)

	local model = BrainrotFactory.BuildCharacter(def, mutation, effectiveIncome)
	local standPosition = runway.Center
		+ Vector3.new(0, runway.TopY + BrainrotFactory.FeetOffset, 0)
	local facing = standPosition + runway.Outward
	model.PrimaryPart.CFrame = CFrame.lookAt(
		standPosition, Vector3.new(facing.X, standPosition.Y, facing.Z))
	model.Parent = Workspace:FindFirstChild("Brainrots") or Workspace

	local entry = {
		Def = def,
		Mutation = mutation,
		Income = effectiveIncome,
		Price = def.Price,
		Model = model,
		State = "Runway",
		Owner = nil,
		RunwayIndex = runway.Index,
		PedestalIndex = nil,
		StolenFrom = nil,
		CarryWeld = nil,
		Prompt = nil,
	}
	EconomyService.RegisterRunwayEntry(entry)
end

function SpawnDirector.Start()
	task.spawn(function()
		-- Stock half the runways up front so the first player through the
		-- gate already has something to buy.
		for _ = 1, 4 do
			spawnOne()
		end
		while true do
			task.wait(Config.SpawnInterval)
			spawnOne()
		end
	end)
end

return SpawnDirector
