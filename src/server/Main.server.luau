--[[
	Combat server entry point.
	Receives button presses from players, checks they are allowed (anti-cheat),
	and passes them to the right handler.

	Step 1 (now): the pipeline only. Handlers print what they WOULD do.
	Step 2 adds the real M1 combo, step 3 adds guard, parry and dashes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))

local Remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local ActionRemote: RemoteEvent = Remotes:WaitForChild("Action")

local function debugPrint(...)
	if CombatSettings.Debug then
		print("[Combat]", ...)
	end
end

-- Handlers --------------------------------------------------------------------
-- Each one gets (player, character, isPressed). isPressed is true when the
-- button goes down and false when it is let go (used for holding guard).

local Handlers = {}

function Handlers.M1(player: Player, character: Model, isPressed: boolean)
	if not isPressed then
		return
	end
	if not CombatState.CanAct(character) then
		debugPrint(player.Name, "M1 ignored, state is", CombatState.GetState(character))
		return
	end
	debugPrint(player.Name, "pressed M1 (combo comes in step 2)")
end

function Handlers.Guard(player: Player, character: Model, isPressed: boolean)
	debugPrint(player.Name, isPressed and "started guarding" or "stopped guarding", "(guard comes in step 3)")
end

function Handlers.Dash(player: Player, character: Model, isPressed: boolean)
	if not isPressed then
		return
	end
	debugPrint(player.Name, "pressed Dash (dash comes in step 3)")
end

-- Anti-cheat: request rate limit -------------------------------------------------

local requestLog: { [Player]: { windowStart: number, count: number } } = {}

local function isWithinRateLimit(player: Player): boolean
	local now = os.clock()
	local log = requestLog[player]
	if not log or now - log.windowStart >= 1 then
		log = { windowStart = now, count = 0 }
		requestLog[player] = log
	end
	log.count += 1
	return log.count <= CombatSettings.MaxRequestsPerSecond
end

-- Incoming requests ----------------------------------------------------------------

ActionRemote.OnServerEvent:Connect(function(player: Player, actionName: unknown, isPressed: unknown)
	-- Never trust what the client sends: check every value's type first.
	if typeof(actionName) ~= "string" or typeof(isPressed) ~= "boolean" then
		return
	end
	local handler = Handlers[actionName]
	if not handler then
		return
	end
	if not isWithinRateLimit(player) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	handler(player, character, isPressed)
end)

-- Character setup and cleanup ------------------------------------------------------

local function onCharacterAdded(character: Model)
	CombatState.Reset(character)
	character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			CombatState.Remove(character)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	requestLog[player] = nil
end)

debugPrint("Server loaded")
