--[[
	CombatState (server only)
	Keeps track of what every character is doing right now: idle, attacking,
	stunned, guarding, and so on. Only the server changes this, so a cheating
	client can't just say "I'm not stunned".

	The current state is also copied onto the character as an attribute
	called "CombatState", so client scripts (VFX, UI, animations) can read it.
]]

local CombatSettings =
	require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("CombatSettings"))

local CombatState = {}

CombatState.States = {
	Idle = "Idle",
	Attacking = "Attacking",
	Hitstun = "Hitstun",
	Guarding = "Guarding",
	GuardBroken = "GuardBroken",
	Dashing = "Dashing",
}

-- One entry per character. Weak keys let Roblox clean up removed characters.
local records = setmetatable({}, { __mode = "k" })

local function newRecord()
	return {
		State = CombatState.States.Idle,
		Token = 0, -- changes every time the state changes, so old timers know they're outdated
		ComboIndex = 0, -- which hit of the M1 string comes next (0 = none yet)
		LastComboTime = 0,
		GuardMeter = CombatSettings.GuardMeterMax,
	}
end

function CombatState.Get(character: Model)
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
end

-- Can this character start a new action (attack, dash...) right now?
function CombatState.CanAct(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	return CombatState.GetState(character) == CombatState.States.Idle
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
