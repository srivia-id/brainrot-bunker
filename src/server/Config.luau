-- Config.luau
-- Brainrot Bunker keeps every balance and tuning number in this single
-- module. No other script hard-codes a price, a timer or a chance: if a
-- number matters to gameplay, it is written here and read from here.

local Config = {}

-- Wallet and tick ------------------------------------------------------------
Config.StartingCash = 100
Config.TickSeconds = 1

-- Runway spawning -------------------------------------------------------------
Config.SpawnInterval = 4
Config.RunwayCount = 8

-- Bases -----------------------------------------------------------------------
Config.BaseCount = 6
Config.PedestalsPerBase = 6
Config.LockDuration = 60
Config.LockCooldown = 30

-- Economy ---------------------------------------------------------------------
Config.SellRefundRate = 0.5
Config.PromptDistance = 14

-- Rebirth ---------------------------------------------------------------------
Config.RebirthBaseCost = 10000
Config.RebirthCostGrowth = 4

-- Lucky Rain event --------------------------------------------------------------
Config.LuckyRainInterval = 180
Config.LuckyRainDuration = 30
Config.LuckyRainMultiplier = 2

-- Sneaky Goblin -----------------------------------------------------------------
Config.GoblinFirstVisit = 75
Config.GoblinVisitMinGap = 55
Config.GoblinVisitMaxGap = 95
Config.GoblinSpeed = 15
Config.GoblinCatchDistance = 6

-- Rarity ladder. Weight is the relative spawn chance of one tier against the
-- others, so Common shows up constantly and a Brainrot God is a parade.
Config.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(168, 168, 172), Weight = 46 },
	{ Name = "Rare", Color = Color3.fromRGB(41, 140, 255), Weight = 27 },
	{ Name = "Epic", Color = Color3.fromRGB(166, 92, 255), Weight = 15 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 190, 26), Weight = 8 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 105, 198), Weight = 3 },
	{ Name = "Brainrot God", Color = Color3.fromRGB(94, 255, 178), Weight = 1 },
}

-- Mutations roll onto a fresh spawn before its price is ever paid; they only
-- multiply the income, never the price, so a mutated catch is pure luck.
Config.Mutations = {
	{ Name = "Gold", Multiplier = 2, Chance = 0.10, Color = Color3.fromRGB(255, 205, 45) },
	{ Name = "Diamond", Multiplier = 5, Chance = 0.04, Color = Color3.fromRGB(140, 235, 255) },
	{ Name = "Rainbow", Multiplier = 10, Chance = 0.015, Color = Color3.fromRGB(255, 120, 220) },
}

-- The fifteen collectible characters. Income is dollars per second earned
-- while the character stands on a pedestal, Price is what the runway asks.
-- Body and Hat are dressing hints that BrainrotFactory reads when it builds
-- the procedural model.
Config.Characters = {
	{ Name = "Noodle Knight", Rarity = "Common", Income = 1, Price = 25, Body = "Block", Hat = "Antenna", Color = Color3.fromRGB(245, 214, 130), Accent = Color3.fromRGB(198, 88, 66) },
	{ Name = "Banana Slipper", Rarity = "Common", Income = 2, Price = 50, Body = "Ball", Hat = "None", Color = Color3.fromRGB(255, 225, 64), Accent = Color3.fromRGB(120, 84, 40) },
	{ Name = "Pigeon Accountant", Rarity = "Common", Income = 3, Price = 90, Body = "Block", Hat = "Cap", Color = Color3.fromRGB(140, 152, 170), Accent = Color3.fromRGB(64, 70, 84) },
	{ Name = "Disco Broccoli", Rarity = "Rare", Income = 6, Price = 200, Body = "Ball", Hat = "Antenna", Color = Color3.fromRGB(74, 178, 84), Accent = Color3.fromRGB(38, 110, 52) },
	{ Name = "Turbo Toaster", Rarity = "Rare", Income = 9, Price = 400, Body = "Block", Hat = "None", Color = Color3.fromRGB(196, 200, 208), Accent = Color3.fromRGB(220, 60, 50) },
	{ Name = "Sir Boba", Rarity = "Rare", Income = 13, Price = 650, Body = "Cylinder", Hat = "TopHat", Color = Color3.fromRGB(243, 226, 190), Accent = Color3.fromRGB(112, 72, 44) },
	{ Name = "DJ Watermelon", Rarity = "Epic", Income = 20, Price = 1200, Body = "Ball", Hat = "Cap", Color = Color3.fromRGB(52, 168, 74), Accent = Color3.fromRGB(238, 82, 104) },
	{ Name = "Captain Cactus", Rarity = "Epic", Income = 28, Price = 2000, Body = "Cylinder", Hat = "Cap", Color = Color3.fromRGB(46, 140, 74), Accent = Color3.fromRGB(240, 200, 60) },
	{ Name = "Unicorn Plumber", Rarity = "Epic", Income = 38, Price = 3200, Body = "Block", Hat = "Horn", Color = Color3.fromRGB(246, 240, 250), Accent = Color3.fromRGB(240, 130, 200) },
	{ Name = "Mecha Potato", Rarity = "Legendary", Income = 55, Price = 6000, Body = "Ball", Hat = "Antenna", Color = Color3.fromRGB(168, 118, 66), Accent = Color3.fromRGB(120, 128, 140) },
	{ Name = "Wizard Washing Machine", Rarity = "Legendary", Income = 80, Price = 10000, Body = "Block", Hat = "TopHat", Color = Color3.fromRGB(232, 236, 242), Accent = Color3.fromRGB(70, 110, 220) },
	{ Name = "Disco Yeti", Rarity = "Legendary", Income = 110, Price = 16000, Body = "Ball", Hat = "None", Color = Color3.fromRGB(238, 246, 250), Accent = Color3.fromRGB(110, 210, 235) },
	{ Name = "Golden Traffic Cone", Rarity = "Mythic", Income = 170, Price = 30000, Body = "Cylinder", Hat = "None", Color = Color3.fromRGB(255, 140, 26), Accent = Color3.fromRGB(255, 210, 60) },
	{ Name = "CEO of Mondays", Rarity = "Mythic", Income = 240, Price = 50000, Body = "Block", Hat = "TopHat", Color = Color3.fromRGB(52, 62, 96), Accent = Color3.fromRGB(214, 48, 60) },
	{ Name = "The Final Cucumber", Rarity = "Brainrot God", Income = 500, Price = 120000, Body = "Cylinder", Hat = "Crown", Color = Color3.fromRGB(64, 200, 110), Accent = Color3.fromRGB(255, 214, 64) },
}

-- Lookup helpers ---------------------------------------------------------------

local rarityByName = {}
for _, rarity in ipairs(Config.Rarities) do
	rarityByName[rarity.Name] = rarity
end

local characterByName = {}
local charactersByRarity = {}
for _, character in ipairs(Config.Characters) do
	characterByName[character.Name] = character
	local bucket = charactersByRarity[character.Rarity]
	if not bucket then
		bucket = {}
		charactersByRarity[character.Rarity] = bucket
	end
	table.insert(bucket, character)
end

function Config.GetRarity(rarityName)
	return rarityByName[rarityName]
end

function Config.GetCharacter(characterName)
	return characterByName[characterName]
end

function Config.GetCharactersOfRarity(rarityName)
	return charactersByRarity[rarityName] or {}
end

-- Weighted rarity roll: one random ticket against the summed ladder weights.
function Config.RollRarity(rng)
	local total = 0
	for _, rarity in ipairs(Config.Rarities) do
		total = total + rarity.Weight
	end
	local ticket = rng:NextNumber(0, total)
	local running = 0
	for _, rarity in ipairs(Config.Rarities) do
		running = running + rarity.Weight
		if ticket <= running then
			return rarity
		end
	end
	return Config.Rarities[1]
end

-- Mutation roll: rarest first, so a Rainbow ticket can never be "wasted"
-- landing on Gold instead.
function Config.RollMutation(rng)
	local roll = rng:NextNumber()
	local cumulative = 0
	for index = #Config.Mutations, 1, -1 do
		local mutation = Config.Mutations[index]
		cumulative = cumulative + mutation.Chance
		if roll <= cumulative then
			return mutation
		end
	end
	return nil
end

-- The cash a player must hand over for their next rebirth, given how many
-- rebirths they have already done.
function Config.RebirthCost(rebirthsDone)
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirthsDone))
end

return Config
