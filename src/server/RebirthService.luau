-- RebirthService.luau
-- The long game: hand over the rebirth price in cash and every brainrot on
-- your pedestals, and walk away with a permanent +1x on all future income.
-- The price quadruples each time, so the ladder never truly ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local RebirthService = {}

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("BrainrotRemotes")
	local banner = remotes and remotes:FindFirstChild("Banner")
	if banner then
		banner:FireClient(player, text)
	end
end

function RebirthService.GetCost(player)
	local data = PlayerData.Get(player)
	if not data then
		return Config.RebirthBaseCost
	end
	return Config.RebirthCost(data.Rebirths)
end

function RebirthService.TryRebirth(player)
	local data = PlayerData.Get(player)
	if not data then
		return false
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		announceTo(player, "Rebirth needs $" .. cost .. " - keep collecting!")
		return false
	end

	PlayerData.TrySpend(player, cost)
	EconomyService.ClearPlaced(player)
	data.Rebirths = data.Rebirths + 1
	PlayerData.SetPerSecond(player, 0)
	announceTo(player, "REBIRTH! Your income multiplier is now x"
		.. PlayerData.GetIncomeMultiplier(player) .. " - rebuild your bunker!")
	EconomyService.FireState(player)
	return true
end

return RebirthService
