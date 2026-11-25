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

-- The class every player starts as (a file name in Combat > Classes).
CombatSettings.DefaultClass = "Kuro"

-- Combo --------------------------------------------------------------------
-- How long (frames) after a swing before the M1 string resets back to hit 1.
CombatSettings.ComboResetFrames = 45
-- If you press M1 this many frames (or fewer) before your current swing ends,
-- the next swing comes out automatically as soon as it can ("input buffer").
CombatSettings.InputBufferFrames = 10
-- How long (frames) the knockback push lasts on the victim.
CombatSettings.KnockbackFrames = 9

-- Movement while fighting ------------------------------------------------------
-- Walk speed while swinging. Normal walk speed and jump come from StarterPlayer.
-- While stunned you can't walk or jump at all.
CombatSettings.AttackingWalkSpeed = 6

-- Guard (hold the guard key) ----------------------------------------------------
-- Guard only blocks hits from the FRONT. Hits from behind go through.
-- Walk speed while guarding.
CombatSettings.GuardWalkSpeed = 6
-- How much damage still goes through a guard (0.1 = 10%, called "chip").
CombatSettings.GuardChipMultiplier = 0.1
-- How much guard meter a player has before their guard breaks.
CombatSettings.GuardMeterMax = 100
-- Guard meter lost per point of damage blocked (a 3 damage jab costs 3 x 4 = 12).
CombatSettings.GuardMeterPerDamage = 4
-- Guard meter refilled per second while NOT guarding.
CombatSettings.GuardMeterRegenPerSecond = 20
-- Blocked hits still lock you briefly ("blockstun"): this times the move's Hitstun.
CombatSettings.BlockstunMultiplier = 0.6
-- Blocked hits still push you back: this times the move's Knockback.
CombatSettings.BlockPushbackMultiplier = 0.5
-- How long (frames) a guard-broken player is stunned and open.
CombatSettings.GuardBreakStunFrames = 60

-- Parry (press guard right before a hit lands) --------------------------------------
-- How many frames after pressing guard a hit counts as a parry instead of a block.
CombatSettings.ParryWindowFrames = 8
-- How long (frames) the attacker is stunned after being parried.
CombatSettings.ParriedStunFrames = 40
-- Pressing guard again within this many frames gives NO parry window (stops mashing).
CombatSettings.ParryCooldownFrames = 30

-- Dash (dash key) ---------------------------------------------------------------------
-- Dashes go the way you're walking, or forward if you're standing still.
CombatSettings.DashSpeed = 70 -- studs per second
CombatSettings.DashFrames = 10 -- how long the dash lasts (70 x 10/60 = about 12 studs)
CombatSettings.DashCooldownFrames = 60
-- Air dash: one per jump, ignores gravity while it lasts.
CombatSettings.AirDashSpeed = 60
CombatSettings.AirDashFrames = 12
CombatSettings.AirDashCooldownFrames = 90

-- Anti-cheat ------------------------------------------------------------------
-- The most action requests one player may send per second. Extra ones are ignored.
CombatSettings.MaxRequestsPerSecond = 20
-- Extra distance (studs) the server allows on hitboxes to make up for lag.
CombatSettings.LagLeniencyStuds = 2

-- Debug and testing -----------------------------------------------------------------
-- Turn ALL of these off before publishing.
-- Prints what the combat system is doing in the Output window.
CombatSettings.Debug = true
-- Shows every hitbox as a see-through red box while it is active.
CombatSettings.ShowHitboxes = true
-- Spawns an R6 training dummy so you can test combos alone.
CombatSettings.SpawnTestDummy = true
-- When true, the dummy holds guard forever, so you can test blocking and guard
-- breaks alone (hit it from behind to get past the guard).
CombatSettings.TestDummyGuards = false
-- Where the dummy spawns. nil = 12 studs in front of the first SpawnLocation.
CombatSettings.TestDummyPosition = nil :: Vector3?

-- Keybinds (the client reads these) -----------------------------------------------
-- Names match Enum.KeyCode / Enum.UserInputType in Roblox.
CombatSettings.Keybinds = {
	M1 = { Enum.UserInputType.MouseButton1 },
	Guard = { Enum.KeyCode.F },
	Dash = { Enum.KeyCode.Q },
	Special1 = { Enum.KeyCode.Z },
}

function CombatSettings.FramesToSeconds(frames: number): number
	return frames / CombatSettings.FPS
end

return CombatSettings
