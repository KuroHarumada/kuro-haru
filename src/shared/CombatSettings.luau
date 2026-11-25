--[[
	CombatSettings
	Global numbers that affect ALL combat, no matter which class is used.
	Safe to tweak: change a number, sync with Rojo, and test.

	Timing is written in FRAMES (like fighting games), at 60 frames per second.
	  60 frames = 1 second, 30 frames = half a second, 6 frames = 0.1 seconds.
	Use CombatSettings.FramesToSeconds(frames) when code needs seconds.
]]

local CombatSettings = {}

CombatSettings.FPS = 60

-- Combo --------------------------------------------------------------------
-- How long (frames) after a hit before the M1 string resets back to hit 1.
CombatSettings.ComboResetFrames = 45

-- Guard and parry (used from step 3) -------------------------------------
-- How much damage still goes through a guard (0.1 = 10%, called "chip").
CombatSettings.GuardChipMultiplier = 0.1
-- How much guard meter a player has before their guard breaks.
CombatSettings.GuardMeterMax = 100
-- How long (frames) a guard-broken player is stunned and open.
CombatSettings.GuardBreakStunFrames = 60
-- The timing window (frames) after pressing guard where a hit counts as a parry.
CombatSettings.ParryWindowFrames = 8
-- How long (frames) the attacker is stunned after being parried.
CombatSettings.ParriedStunFrames = 40

-- Movement (used from step 3) -----------------------------------------------
CombatSettings.DashCooldownFrames = 60
CombatSettings.AirDashCooldownFrames = 90

-- Anti-cheat ------------------------------------------------------------------
-- The most action requests one player may send per second. Extra ones are ignored.
CombatSettings.MaxRequestsPerSecond = 20
-- Extra distance (studs) the server allows on hitboxes to make up for lag.
CombatSettings.LagLeniencyStuds = 2

-- Debug -------------------------------------------------------------------------
-- When true, the Output window prints what the combat system is doing.
-- Turn this off before publishing.
CombatSettings.Debug = true

-- Keybinds (the client reads these) -----------------------------------------------
-- Names match Enum.KeyCode / Enum.UserInputType in Roblox.
CombatSettings.Keybinds = {
	M1 = { Enum.UserInputType.MouseButton1 },
	Guard = { Enum.KeyCode.F },
	Dash = { Enum.KeyCode.Q },
}

function CombatSettings.FramesToSeconds(frames: number): number
	return frames / CombatSettings.FPS
end

return CombatSettings
