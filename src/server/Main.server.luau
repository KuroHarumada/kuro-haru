--[[
	Combat server entry point.
	Receives button presses from players, checks they are allowed (anti-cheat),
	and passes them to the right handler.

	M1 = combo (M1Combo), Guard = hold to block / tap to parry (Guard),
	Dash = dash and air dash (Dash), Special1 = class special (Specials).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local M1Combo = require(script.Parent:WaitForChild("M1Combo"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Dash = require(script.Parent:WaitForChild("Dash"))
local Classes = require(script.Parent:WaitForChild("Classes"))
local Specials = require(script.Parent:WaitForChild("Specials"))
local TestDummy = require(script.Parent:WaitForChild("TestDummy"))

local Remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local ActionRemote: RemoteEvent = Remotes:WaitForChild("Action")

local function debugPrint(...)
	if CombatSettings.Debug then
		print("[Combat]", ...)
	end
end

-- Handlers --------------------------------------------------------------------
-- Each one gets (character, isPressed, extra). isPressed is true when the
-- button goes down and false when it is let go (used for holding guard).
-- `extra` is anything else the client sent. NEVER trust it: each handler checks it.

local Handlers = {}

function Handlers.M1(character: Model, isPressed: boolean, _extra: unknown)
	if isPressed then
		M1Combo.Request(character)
	end
end

function Handlers.Guard(character: Model, isPressed: boolean, _extra: unknown)
	Guard.Request(character, isPressed)
end

function Handlers.Dash(character: Model, isPressed: boolean, direction: unknown)
	if isPressed then
		Dash.Request(character, direction)
	end
end

function Handlers.Special1(character: Model, isPressed: boolean, _extra: unknown)
	if isPressed then
		Specials.Request(character, "Special1")
	end
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

ActionRemote.OnServerEvent:Connect(function(player: Player, actionName: unknown, isPressed: unknown, extra: unknown)
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

	handler(character, isPressed, extra)
end)

-- Character setup and cleanup ------------------------------------------------------

local warnedAboutRig = false

local function onCharacterAdded(character: Model)
	CombatState.Reset(character)
	Dash.SetupCharacter(character)

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

Classes.Start()
TestDummy.Start()

debugPrint("Server loaded")
