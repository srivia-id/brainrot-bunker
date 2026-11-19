-- EconomyService.luau
-- Owns every brainrot entry in the game and every rule that moves one:
-- buying from a runway, carrying it home on your head, placing it on a
-- pedestal, selling it back, and the one-second income tick that pays every
-- placed brainrot. All money decisions happen here, on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local EventService = require(script.Parent:WaitForChild("EventService"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local EconomyService = {}

local world = nil
local runwayEntries = {}
local droppedEntries = {}

local function remotes()
	return ReplicatedStorage:FindFirstChild("BrainrotRemotes")
end

local function announceTo(player, text)
	local folder = remotes()
	local banner = folder and folder:FindFirstChild("Banner")
	if banner then
		banner:FireClient(player, text)
	end
end

-- Push the numbers the HUD shows so it never has to guess.
function EconomyService.FireState(player)
	local data = PlayerData.Get(player)
	local folder = remotes()
	local event = folder and folder:FindFirstChild("StateChanged")
	if not data or not event then
		return
	end
	event:FireClient(player, {
		Cash = math.floor(data.Cash),
		PerSecond = math.floor(data.PerSecond),
		Rebirths = data.Rebirths,
		LockSeconds = BaseManager.LockSecondsLeft(player),
		LockCooldown = BaseManager.LockCooldownLeft(player),
		RebirthCost = Config.RebirthCost(data.Rebirths),
		CarryingName = data.Carrying and data.Carrying.Model.Name or "",
		PlacedCount = #data.Placed,
	})
end

local function displayName(entry)
	if entry.Mutation then
		return entry.Mutation.Name .. " " .. entry.Def.Name
	end
	return entry.Def.Name
end

local function clearPrompt(entry)
	if entry.Prompt then
		entry.Prompt:Destroy()
		entry.Prompt = nil
	end
end

local function carryEntry(player, entry)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local root = entry.Model and entry.Model.PrimaryPart
	if not head or not root then
		return false
	end
	clearPrompt(entry)
	root.Anchored = false
	root.CFrame = head.CFrame * CFrame.new(0, 2.5, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = root
	weld.Parent = root
	entry.CarryWeld = weld
	entry.State = "Carried"
	entry.Owner = player
	local data = PlayerData.Get(player)
	if data then
		data.Carrying = entry
	end
	return true
end

local function placeOnPedestal(player, entry)
	local data = PlayerData.Get(player)
	local base = BaseManager.GetBase(player)
	if not data or not base then
		return false
	end
	local used = {}
	for _, placed in ipairs(data.Placed) do
		if placed.PedestalIndex then
			used[placed.PedestalIndex] = true
		end
	end
	local chosen = nil
	for _, pedestal in ipairs(base.Pedestals) do
		if not used[pedestal.Index] then
			chosen = pedestal
			break
		end
	end
	if not chosen then
		announceTo(player, "Your base is full! Sell a brainrot or rebirth to make room.")
		return false
	end

	if entry.CarryWeld then
		entry.CarryWeld:Destroy()
		entry.CarryWeld = nil
	end
	local root = entry.Model.PrimaryPart
	root.Anchored = true
	local standPosition = chosen.TopPosition + Vector3.new(0, BrainrotFactory.FeetOffset, 0)
	root.CFrame = CFrame.lookAt(standPosition, Vector3.new(0, standPosition.Y, 0))
	entry.State = "Placed"
	entry.PedestalIndex = chosen.Index
	data.Carrying = nil
	table.insert(data.Placed, entry)

	local refund = math.floor(entry.Price * Config.SellRefundRate)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell"
	prompt.ObjectText = "+$" .. refund
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	entry.Prompt = prompt
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player and entry.State == "Placed" then
			EconomyService.SellPlaced(player, entry)
		end
	end)

	EconomyService.FireState(player)
	return true
end

function EconomyService.SellPlaced(player, entry)
	local data = PlayerData.Get(player)
	if not data or entry.State ~= "Placed" then
		return
	end
	for index, placed in ipairs(data.Placed) do
		if placed == entry then
			table.remove(data.Placed, index)
			break
		end
	end
	local refund = math.floor(entry.Price * Config.SellRefundRate)
	clearPrompt(entry)
	entry.State = "Sold"
	entry.PedestalIndex = nil
	if entry.Model then
		entry.Model:Destroy()
	end
	PlayerData.AddCash(player, refund)
	announceTo(player, "Sold " .. displayName(entry) .. " for $" .. refund)
	EconomyService.FireState(player)
end

-- Called by SpawnDirector for every fresh brainrot: park it in the runway
-- registry and hang its Buy prompt.
function EconomyService.RegisterRunwayEntry(entry)
	runwayEntries[entry.RunwayIndex] = entry
	local root = entry.Model.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = "$" .. entry.Price
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	entry.Prompt = prompt
	prompt.Triggered:Connect(function(player)
		EconomyService.TryBuy(player, entry)
	end)
end

function EconomyService.IsRunwayFree(index)
	return runwayEntries[index] == nil
end

function EconomyService.TryBuy(player, entry)
	local data = PlayerData.Get(player)
	if not data or entry.State ~= "Runway" then
		return
	end
	if data.Carrying then
		announceTo(player, "Your hands are full! Place the brainrot you are carrying first.")
		return
	end
	if not BaseManager.GetBase(player) then
		announceTo(player, "You need a base before you can collect brainrots.")
		return
	end
	if #data.Placed >= Config.PedestalsPerBase then
		announceTo(player, "Your base is full! Sell a brainrot or rebirth to make room.")
		return
	end
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then
		return
	end
	if not PlayerData.TrySpend(player, entry.Price) then
		announceTo(player, "Not enough cash for " .. displayName(entry)
			.. " ($" .. entry.Price .. ").")
		return
	end
	runwayEntries[entry.RunwayIndex] = nil
	entry.RunwayIndex = nil
	if not carryEntry(player, entry) then
		PlayerData.AddCash(player, entry.Price)
		announceTo(player, "Could not pick that up - you have been refunded.")
		return
	end
	announceTo(player, "Bought " .. displayName(entry) .. "! Carry it home to your base.")
	EconomyService.FireState(player)
end

-- A dropped steal (the goblin was caught) waits on the ground for its owner.
function EconomyService.DropStolenEntry(entry, groundPosition)
	if entry.CarryWeld then
		entry.CarryWeld:Destroy()
		entry.CarryWeld = nil
	end
	local root = entry.Model and entry.Model.PrimaryPart
	if not root then
		return
	end
	root.Anchored = true
	local standPosition = groundPosition + Vector3.new(0, BrainrotFactory.FeetOffset, 0)
	root.CFrame = CFrame.lookAt(standPosition, Vector3.new(0, standPosition.Y, 0))
	entry.State = "Dropped"
	droppedEntries[entry] = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = displayName(entry)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	entry.Prompt = prompt
	prompt.Triggered:Connect(function(player)
		if entry.State ~= "Dropped" then
			return
		end
		if player ~= entry.StolenFrom then
			announceTo(player, "That brainrot belongs to "
				.. (entry.StolenFrom and entry.StolenFrom.DisplayName or "someone else") .. "!")
			return
		end
		local data = PlayerData.Get(player)
		if data and data.Carrying then
			announceTo(player, "Your hands are full!")
			return
		end
		droppedEntries[entry] = nil
		entry.StolenFrom = nil
		if carryEntry(player, entry) then
			announceTo(player, "Recovered " .. displayName(entry) .. "! Quick, place it again.")
			EconomyService.FireState(player)
		end
	end)
end

-- Take one placed brainrot away from a victim. ThiefService calls this the
-- moment the goblin reaches the pedestal, then carries the entry off.
function EconomyService.StealRandomPlaced(victim)
	local data = PlayerData.Get(victim)
	if not data or #data.Placed == 0 then
		return nil
	end
	local pick = math.random(1, #data.Placed)
	local entry = table.remove(data.Placed, pick)
	clearPrompt(entry)
	entry.State = "Stolen"
	entry.PedestalIndex = nil
	entry.StolenFrom = victim
	EconomyService.FireState(victim)
	return entry
end

-- Wipe a player's pedestals (rebirth price, or they left the game).
function EconomyService.ClearPlaced(player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for _, entry in ipairs(data.Placed) do
		clearPrompt(entry)
		if entry.Model then
			entry.Model:Destroy()
		end
		entry.State = "Gone"
	end
	data.Placed = {}
	EconomyService.FireState(player)
end

-- If a player dies mid-carry, the catch goes back to a free runway instead
-- of vanishing with the character.
function EconomyService.ReturnCarriedToRunway(player)
	local data = PlayerData.Get(player)
	if not data or not data.Carrying or not world then
		return
	end
	local entry = data.Carrying
	data.Carrying = nil
	if entry.CarryWeld then
		entry.CarryWeld:Destroy()
		entry.CarryWeld = nil
	end
	for _, runway in ipairs(world.Runways) do
		if runwayEntries[runway.Index] == nil then
			local root = entry.Model.PrimaryPart
			root.Anchored = true
			local standPosition = runway.Center + Vector3.new(0, runway.TopY + BrainrotFactory.FeetOffset, 0)
			local facing = standPosition + runway.Outward
			root.CFrame = CFrame.lookAt(standPosition, Vector3.new(facing.X, standPosition.Y, facing.Z))
			entry.RunwayIndex = runway.Index
			entry.State = "Runway"
			entry.Owner = nil
			EconomyService.RegisterRunwayEntry(entry)
			return
		end
	end
	if entry.Model then
		entry.Model:Destroy()
	end
end

function EconomyService.CleanupPlayer(player)
	local data = PlayerData.Get(player)
	if data then
		if data.Carrying then
			if data.Carrying.Model then
				data.Carrying.Model:Destroy()
			end
			data.Carrying = nil
		end
		EconomyService.ClearPlaced(player)
	end
	for entry in pairs(droppedEntries) do
		if entry.StolenFrom == player then
			droppedEntries[entry] = nil
			clearPrompt(entry)
			if entry.Model then
				entry.Model:Destroy()
			end
		end
	end
end

function EconomyService.Init(gameWorld)
	world = gameWorld
	for _, base in ipairs(world.Bases) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PlacePrompt"
		prompt.ActionText = "Place"
		prompt.ObjectText = "PLACE HERE"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = Config.PromptDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = base.PlacePost
		prompt.Triggered:Connect(function(player)
			local data = PlayerData.Get(player)
			if data and data.Carrying and BaseManager.GetBase(player) == base then
				placeOnPedestal(player, data.Carrying)
			end
		end)
	end
end

-- The heartbeat of the whole game: once a second, every pedestal pays its
-- owner, scaled by their rebirth multiplier and any running event.
function EconomyService.StartIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.TickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = PlayerData.Get(player)
				if data then
					local baseIncome = 0
					for _, entry in ipairs(data.Placed) do
						baseIncome = baseIncome + entry.Income
					end
					local effective = baseIncome
						* PlayerData.GetIncomeMultiplier(player)
						* EventService.GetMultiplier()
					PlayerData.SetPerSecond(player, effective)
					if effective > 0 then
						PlayerData.AddCash(player, effective)
					end
					EconomyService.FireState(player)
				end
			end
		end
	end)
end

return EconomyService
