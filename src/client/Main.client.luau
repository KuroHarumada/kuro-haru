--[[
	Combat client entry point.
	Listens for the combat keybinds and tells the server about them.
	The client only ASKS to attack; the server decides whether it happens.

	Hit feedback (VFX) lives in CombatEffects.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatEffects = require(script.Parent:WaitForChild("CombatEffects"))
local ActionRemote: RemoteEvent = ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Action")

-- Build a lookup: input -> action name, from the keybinds in CombatSettings.
local inputToAction = {}
for actionName, inputs in CombatSettings.Keybinds do
	for _, input in inputs do
		inputToAction[input] = actionName
	end
end

local function getAction(input: InputObject): string?
	return inputToAction[input.KeyCode] or inputToAction[input.UserInputType]
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	-- gameProcessedEvent is true when typing in chat or clicking a UI button.
	if gameProcessedEvent then
		return
	end
	local action = getAction(input)
	if action == "Dash" then
		-- Tell the server which way we're walking (zero = standing still).
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		ActionRemote:FireServer(action, true, humanoid and humanoid.MoveDirection or Vector3.zero)
	elseif action then
		ActionRemote:FireServer(action, true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	-- Release events are always sent (even over UI) so a held guard can't get stuck.
	local action = getAction(input)
	if action then
		ActionRemote:FireServer(action, false)
	end
end)

CombatEffects.Start()

if CombatSettings.Debug then
	print("[Combat] Client loaded")
end
