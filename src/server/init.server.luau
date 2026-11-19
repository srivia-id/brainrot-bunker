-- init.server.luau
-- Brainrot Bunker bootstrap. Creates the shared remote folder, builds the
-- world, wires every service together, and looks after players as they
-- join, respawn and leave. All real work lives in the module children of
-- this script; this file only connects them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes first: the services and the client HUD all talk through this one
-- folder in ReplicatedStorage.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
for _, eventName in ipairs({ "RebirthRequest", "LockRequest", "StateChanged", "Banner" }) do
	local event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local PlayerData = require(script:WaitForChild("PlayerData"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BaseManager = require(script:WaitForChild("BaseManager"))
local EconomyService = require(script:WaitForChild("EconomyService"))
local SpawnDirector = require(script:WaitForChild("SpawnDirector"))
local ThiefService = require(script:WaitForChild("ThiefService"))
local EventService = require(script:WaitForChild("EventService"))
local RebirthService = require(script:WaitForChild("RebirthService"))

local world = WorldBuilder.Build()
BaseManager.Init(world)
EconomyService.Init(world)
SpawnDirector.Init(world)
ThiefService.Init(world)

remotes:WaitForChild("LockRequest").OnServerEvent:Connect(function(player)
	local _, message = BaseManager.TryLock(player)
	local banner = remotes:FindFirstChild("Banner")
	if banner and message then
		banner:FireClient(player, message)
	end
	EconomyService.FireState(player)
end)

remotes:WaitForChild("RebirthRequest").OnServerEvent:Connect(function(player)
	RebirthService.TryRebirth(player)
end)

local function onCharacterAdded(player, character)
	local base = BaseManager.GetBase(player)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if base and root then
		root.CFrame = base.SpawnCFrame
	end
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			EconomyService.ReturnCarriedToRunway(player)
			task.wait(3)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end
	EconomyService.FireState(player)
end

local function onPlayerAdded(player)
	PlayerData.Init(player)
	BaseManager.AssignBase(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	-- The place project turns CharacterAutoLoads off, so the first character
	-- is loaded by hand here.
	player:LoadCharacter()
end

local function onPlayerRemoving(player)
	EconomyService.CleanupPlayer(player)
	BaseManager.ReleaseBase(player)
	PlayerData.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

BaseManager.Start()
EconomyService.StartIncomeLoop()
SpawnDirector.Start()
EventService.Start()
ThiefService.Start()
