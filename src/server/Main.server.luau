--[[
	Combat server entry point.
	Receives button presses from players, checks they are allowed (anti-cheat),
	and passes them to the right handler.

	Step 2 (now): M1 runs the real combo. Guard and Dash still only print;
	step 3 adds guard, parry and dashes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local M1Combo = require(script.Parent:WaitForChild("M1Combo"))
local TestDummy = require(script.Parent:WaitForChild("TestDummy"))

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

function Handlers.M1(_player: Player, character: Model, isPressed: boolean)
	if isPressed then
		M1Combo.Request(character)
	end
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

local warnedAboutRig = false

local function onCharacterAdded(character: Model)
	CombatState.Reset(character)

	-- The game is built for R6. Warn (once) if the avatar setting lets R15 in.
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid and humanoid.RigType ~= Enum.HumanoidRigType.R6 and not warnedAboutRig then
		warnedAboutRig = true
		warn(
			"[Combat] A character spawned as R15. This game is made for R6: set it in "
				.. "Avatar Settings (or Game Settings > Avatar) in Studio, then publish."
		)
	end

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

TestDummy.Start()

debugPrint("Server loaded")
