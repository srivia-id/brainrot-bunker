-- Hud.client.luau
-- The whole client side of Brainrot Bunker: one tidy panel in the top-right
-- (well clear of Roblox's own top-left menu buttons) showing cash, income
-- per second, rebirths and whatever is riding on the player's head, plus
-- the Lock and Rebirth buttons and a banner for game announcements. The HUD
-- only ever displays state and asks; the server decides everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local function formatCash(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 10000 then
		return string.format("$%.1fk", amount / 1000)
	end
	return "$" .. tostring(amount)
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -14, 0, 14)
panel.Size = UDim2.new(0, 268, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(30, 28, 44)
panel.BackgroundTransparency = 0.12
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 10)
panelPadding.PaddingBottom = UDim.new(0, 10)
panelPadding.PaddingLeft = UDim.new(0, 12)
panelPadding.PaddingRight = UDim.new(0, 12)
panelPadding.Parent = panel

local panelLayout = Instance.new("UIListLayout")
panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
panelLayout.Padding = UDim.new(0, 5)
panelLayout.Parent = panel

local function addLabel(name, order, text, color, height)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, height or 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.TextColor3 = color
	label.Parent = panel
	return label
end

addLabel("Title", 1, "BRAINROT BUNKER", Color3.fromRGB(255, 226, 92), 26)
local cashLabel = addLabel("Cash", 2, "Cash: $0", Color3.new(1, 1, 1), 26)
local perSecondLabel = addLabel("PerSecond", 3, "+$0/s", Color3.fromRGB(120, 255, 130), 22)
local rebirthLabel = addLabel("Rebirths", 4, "Rebirths: 0 (income x1)", Color3.fromRGB(190, 200, 255), 20)
local carryingLabel = addLabel("Carrying", 5, "Carrying: -", Color3.fromRGB(255, 190, 120), 20)

local function addButton(name, order, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = color
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = true
	button.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button
	return button
end

local lockButton = addButton("LockButton", 6, "LOCK BASE - 60s", Color3.fromRGB(46, 130, 200))
local rebirthButton = addButton("RebirthButton", 7, "REBIRTH", Color3.fromRGB(150, 70, 200))

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Name = "Banner"
bannerLabel.AnchorPoint = Vector2.new(0.5, 0)
bannerLabel.Position = UDim2.new(0.5, 0, 0, 66)
bannerLabel.Size = UDim2.new(0, 720, 0, 52)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Font = Enum.Font.GothamBold
bannerLabel.TextScaled = true
bannerLabel.Text = ""
bannerLabel.TextColor3 = Color3.fromRGB(255, 226, 92)
bannerLabel.TextStrokeTransparency = 0.3
bannerLabel.Visible = false
bannerLabel.Parent = gui

local bannerToken = 0
local function showBanner(text)
	bannerToken = bannerToken + 1
	local myToken = bannerToken
	bannerLabel.Text = text
	bannerLabel.Visible = true
	task.delay(4.5, function()
		if bannerToken == myToken then
			bannerLabel.Visible = false
		end
	end)
end

local stats = player:WaitForChild("leaderstats")
local cashValue = stats:WaitForChild("Cash")
local rebirthsValue = stats:WaitForChild("Rebirths")
local perSecondValue = stats:WaitForChild("PerSecond")

local function refreshStats()
	cashLabel.Text = "Cash: " .. formatCash(cashValue.Value)
	perSecondLabel.Text = "+" .. formatCash(perSecondValue.Value) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. rebirthsValue.Value
		.. " (income x" .. (rebirthsValue.Value + 1) .. ")"
end
cashValue.Changed:Connect(refreshStats)
rebirthsValue.Changed:Connect(refreshStats)
perSecondValue.Changed:Connect(refreshStats)
refreshStats()

remotes:WaitForChild("StateChanged").OnClientEvent:Connect(function(state)
	if state.CarryingName and state.CarryingName ~= "" then
		carryingLabel.Text = "Carrying: " .. state.CarryingName
	else
		carryingLabel.Text = "Carrying: -"
	end
	if state.LockSeconds and state.LockSeconds > 0 then
		lockButton.Text = "LOCKED - " .. state.LockSeconds .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
	elseif state.LockCooldown and state.LockCooldown > 0 then
		lockButton.Text = "Lock recharging - " .. state.LockCooldown .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
	else
		lockButton.Text = "LOCK BASE - 60s"
		lockButton.BackgroundColor3 = Color3.fromRGB(46, 130, 200)
	end
	if state.RebirthCost then
		rebirthButton.Text = "REBIRTH - " .. formatCash(state.RebirthCost)
	end
end)

remotes:WaitForChild("Banner").OnClientEvent:Connect(function(text)
	if type(text) == "string" then
		showBanner(text)
	end
end)

lockButton.Activated:Connect(function()
	remotes:WaitForChild("LockRequest"):FireServer()
end)

rebirthButton.Activated:Connect(function()
	remotes:WaitForChild("RebirthRequest"):FireServer()
end)
