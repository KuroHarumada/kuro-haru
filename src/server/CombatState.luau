--[[
	CombatState (server only)
	Keeps track of what every character is doing right now: idle, attacking,
	stunned, guarding, and so on. Only the server changes this, so a cheating
	client can't just say "I'm not stunned".

	The current state is also copied onto the character as an attribute
	called "CombatState", so client scripts (VFX, UI, animations) can read it.

	Changing state also sets how fast the character can walk and whether
	they can jump (e.g. no walking or jumping while in hitstun).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))

local CombatState = {}

CombatState.States = {
	Idle = "Idle",
	Attacking = "Attacking",
	Hitstun = "Hitstun",
	Guarding = "Guarding",
	GuardBroken = "GuardBroken",
	Dashing = "Dashing",
}

-- Walk speed for each state. nil = the game's normal walk speed (StarterPlayer).
local WALK_SPEED_BY_STATE = {
	Idle = nil,
	Attacking = CombatSettings.AttackingWalkSpeed,
	Hitstun = 0,
	Guarding = CombatSettings.GuardWalkSpeed,
	GuardBroken = 0,
	Dashing = nil,
}

-- States where the character's current attack animation gets cut off.
local INTERRUPTING_STATES = {
	Hitstun = true,
	GuardBroken = true,
}

-- One entry per character. Weak keys let Roblox clean up removed characters.
local records = setmetatable({}, { __mode = "k" })

local function newRecord()
	return {
		State = CombatState.States.Idle,
		Token = 0, -- changes every time the state changes, so old timers know they're outdated
		ComboIndex = 0, -- which hit of the M1 string was used last (0 = none yet)
		LastComboTime = 0,
		BufferedM1At = nil :: number?, -- when M1 was pressed during a swing (input buffer)
		-- Guard
		GuardHeld = false, -- is the guard key held down right now?
		GuardStartedAt = 0, -- when guard went up (the parry window counts from here)
		LastGuardPressAt = -math.huge,
		BlockstunUntil = 0, -- can't act until this time after blocking a hit
		GuardMeter = CombatSettings.GuardMeterMax,
		GuardMeterUpdatedAt = os.clock(),
		-- Dash
		DashReadyAt = 0,
		AirDashReadyAt = 0,
		AirDashUsed = false,
		AnimationTracks = {} :: { [string]: AnimationTrack },
		CurrentTrack = nil :: AnimationTrack?,
	}
end

export type Record = typeof(newRecord())

local function applyMovement(character: Model, state: string)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = WALK_SPEED_BY_STATE[state] or StarterPlayer.CharacterWalkSpeed

	local canJump = state == CombatState.States.Idle or state == CombatState.States.Dashing
	humanoid.JumpPower = canJump and StarterPlayer.CharacterJumpPower or 0
	humanoid.JumpHeight = canJump and StarterPlayer.CharacterJumpHeight or 0
end

function CombatState.Get(character: Model): Record
	local record = records[character]
	if not record then
		record = newRecord()
		records[character] = record
	end
	return record
end

function CombatState.GetState(character: Model): string
	return CombatState.Get(character).State
end

-- Change a character's state. If durationFrames is given, the character
-- automatically goes back to Idle after that many frames (unless something
-- else changed their state in the meantime).
function CombatState.Set(character: Model, state: string, durationFrames: number?)
	assert(CombatState.States[state], "Unknown combat state: " .. tostring(state))

	local record = CombatState.Get(character)
	record.Token += 1
	record.State = state
	character:SetAttribute("CombatState", state)
	applyMovement(character, state)

	if INTERRUPTING_STATES[state] and record.CurrentTrack then
		record.CurrentTrack:Stop(0.05)
		record.CurrentTrack = nil
	end

	if durationFrames then
		local myToken = record.Token
		task.delay(CombatSettings.FramesToSeconds(durationFrames), function()
			if records[character] == record and record.Token == myToken then
				CombatState.Set(character, CombatState.States.Idle)
			end
		end)
	end

	if CombatSettings.Debug then
		print(`[Combat] {character.Name} -> {state}` .. (durationFrames and ` ({durationFrames}f)` or ""))
	end

	-- Run last, because the hook may change the state again (e.g. straight back into Guarding).
	if state == CombatState.States.Idle and CombatState.OnBecameIdle then
		CombatState.OnBecameIdle(character, record)
	end
end

-- True while `record` is still this character's current record and nothing
-- has changed their state since `token` was taken. Long actions (like a swing)
-- check this after every wait, so getting hit cancels them.
function CombatState.IsStillValid(character: Model, record: Record, token: number): boolean
	if records[character] ~= record or record.Token ~= token then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and character.Parent ~= nil
end

-- Can this character start a new action (attack, dash...) right now?
function CombatState.CanAct(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local record = CombatState.Get(character)
	return record.State == CombatState.States.Idle and os.clock() >= record.BlockstunUntil
end

-- Optional hook, called every time a character goes back to Idle.
-- (Guard uses it so holding the guard key through hitstun puts guard back up.)
CombatState.OnBecameIdle = nil :: ((character: Model, record: Record) -> ())?

-- Play an animation on the character from the server (it shows for everyone).
-- Does nothing if animationId is empty.
function CombatState.PlayAnimation(character: Model, animationId: string)
	if animationId == "" then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local record = CombatState.Get(character)
	local track = record.AnimationTracks[animationId]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		track = animator:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		record.AnimationTracks[animationId] = track
	end

	if record.CurrentTrack and record.CurrentTrack ~= track then
		record.CurrentTrack:Stop(0.05)
	end
	track:Play(0.05)
	record.CurrentTrack = track
end

-- Fresh start, e.g. when a character spawns.
function CombatState.Reset(character: Model)
	records[character] = newRecord()
	character:SetAttribute("CombatState", CombatState.States.Idle)
end

function CombatState.Remove(character: Model)
	records[character] = nil
end

return CombatState
