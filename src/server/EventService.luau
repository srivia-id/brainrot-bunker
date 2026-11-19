-- EventService.luau
-- Runs the Lucky Rain: every few minutes the plaza gets thirty seconds of
-- golden coin rain and every pedestal in the game earns at double rate.
-- EconomyService asks this module for the current income multiplier; this
-- module never touches anyone's wallet itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent:WaitForChild("Config"))

local EventService = {}

local rainActive = false

local function bannerEvent()
	local remotes = ReplicatedStorage:FindFirstChild("BrainrotRemotes")
	if remotes then
		return remotes:FindFirstChild("Banner")
	end
	return nil
end

local function announce(text)
	local event = bannerEvent()
	if event then
		event:FireAllClients(text)
	end
end

function EventService.IsActive()
	return rainActive
end

function EventService.GetMultiplier()
	if rainActive then
		return Config.LuckyRainMultiplier
	end
	return 1
end

-- Coins are simple anchored cylinders stepped downward by hand, so the rain
-- costs no physics at all and stops the moment the event ends.
local function runCoinRain(duration)
	local folder = Instance.new("Folder")
	folder.Name = "LuckyRainCoins"
	folder.Parent = Workspace
	local coins = {}
	local rng = Random.new()
	local startedAt = os.clock()

	task.spawn(function()
		while os.clock() - startedAt < duration do
			local coin = Instance.new("Part")
			coin.Name = "Coin"
			coin.Shape = Enum.PartType.Cylinder
			coin.Size = Vector3.new(0.35, 1.5, 1.5)
			coin.Color = Color3.fromRGB(255, 205, 45)
			coin.Material = Enum.Material.Neon
			coin.Anchored = true
			coin.CanCollide = false
			coin.CanQuery = false
			coin.CanTouch = false
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(4, 52)
			coin.CFrame = CFrame.new(math.cos(angle) * radius, 42, math.sin(angle) * radius)
				* CFrame.Angles(0, 0, math.rad(90))
			coin.Parent = folder
			table.insert(coins, coin)
			if #coins > 130 then
				local oldest = table.remove(coins, 1)
				oldest:Destroy()
			end
			task.wait(0.08)
		end
	end)

	task.spawn(function()
		while os.clock() - startedAt < duration + 1 do
			local dt = task.wait()
			for index = #coins, 1, -1 do
				local coin = coins[index]
				coin.CFrame = coin.CFrame - Vector3.new(0, 46 * dt, 0)
				if coin.Position.Y < 1 then
					coin:Destroy()
					table.remove(coins, index)
				end
			end
		end
		folder:Destroy()
	end)
end

function EventService.Start()
	task.spawn(function()
		while true do
			task.wait(Config.LuckyRainInterval)
			rainActive = true
			announce("LUCKY RAIN! Every pedestal earns x" .. Config.LuckyRainMultiplier
				.. " for " .. Config.LuckyRainDuration .. " seconds!")
			runCoinRain(Config.LuckyRainDuration)
			task.wait(Config.LuckyRainDuration)
			rainActive = false
			announce("The Lucky Rain has passed.")
		end
	end)
end

return EventService
