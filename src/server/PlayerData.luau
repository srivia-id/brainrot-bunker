-- PlayerData.luau
-- The one and only store of per-player state. Every other module asks this
-- one for a player's cash, rebirths, base and brainrots, and every change to
-- those numbers flows back through here so the leaderstats never drift away
-- from the truth.

local Config = require(script.Parent:WaitForChild("Config"))

local PlayerData = {}

local store = {}

local function syncLeaderstats(player, data)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	stats:FindFirstChild("Cash").Value = math.floor(data.Cash)
	stats:FindFirstChild("Rebirths").Value = data.Rebirths
	stats:FindFirstChild("PerSecond").Value = math.floor(data.PerSecond)
end

-- Create the state record and the leaderstats folder for a joining player.
function PlayerData.Init(player)
	if store[player] then
		return store[player]
	end

	local data = {
		Cash = Config.StartingCash,
		Rebirths = 0,
		PerSecond = 0,
		BaseIndex = nil,
		Carrying = nil,
		Placed = {},
		LockUntil = 0,
		LockReadyAt = 0,
	}
	store[player] = data

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats

	local perSecond = Instance.new("IntValue")
	perSecond.Name = "PerSecond"
	perSecond.Parent = stats

	stats.Parent = player
	syncLeaderstats(player, data)
	return data
end

function PlayerData.Get(player)
	return store[player]
end

-- Add (or, with a negative amount, remove) cash without ever letting the
-- wallet drop below zero. Returns the new balance.
function PlayerData.AddCash(player, amount)
	local data = store[player]
	if not data then
		return 0
	end
	data.Cash = math.max(0, data.Cash + amount)
	syncLeaderstats(player, data)
	return data.Cash
end

-- Spend only when the wallet truly covers the price: the server, never the
-- client, decides whether a purchase happens.
function PlayerData.TrySpend(player, amount)
	local data = store[player]
	if not data then
		return false
	end
	if data.Cash < amount then
		return false
	end
	data.Cash = data.Cash - amount
	syncLeaderstats(player, data)
	return true
end

function PlayerData.SetPerSecond(player, value)
	local data = store[player]
	if not data then
		return
	end
	data.PerSecond = value
	syncLeaderstats(player, data)
end

-- Rebirths buy a permanent income multiplier: every rebirth adds one more
-- times on top of the base rate.
function PlayerData.GetIncomeMultiplier(player)
	local data = store[player]
	if not data then
		return 1
	end
	return 1 + data.Rebirths
end

function PlayerData.Remove(player)
	store[player] = nil
end

return PlayerData
