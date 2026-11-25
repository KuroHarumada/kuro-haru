--[[
	Guard (server only)
	Hold the guard key to block hits from the front.

	- Blocked hits do a little "chip" damage, a short blockstun and pushback,
	  and drain the guard meter. Empty meter = guard break (long stun).
	- Hits from behind are not blocked.
	- PARRY: if a hit lands within ParryWindowFrames of pressing guard, it is
	  parried instead: no damage, and the attacker gets stunned.
	  Pressing guard again too soon after the last press gives no parry window,
	  so mashing the key doesn't work.
	- Guard meter refills while not guarding.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Movers = require(script.Parent:WaitForChild("Movers"))

local frames = CombatSettings.FramesToSeconds
local States = CombatState.States

local Guard = {}

export type BlockResult = "Hit" | "Blocked" | "Parried" | "GuardBroken"

-- Bring the guard meter up to date (it refills while not guarding).
local function updateMeter(character: Model, record: CombatState.Record)
	local now = os.clock()
	if record.State ~= States.Guarding then
		local regen = CombatSettings.GuardMeterRegenPerSecond * (now - record.GuardMeterUpdatedAt)
		record.GuardMeter = math.min(CombatSettings.GuardMeterMax, record.GuardMeter + regen)
	end
	record.GuardMeterUpdatedAt = now
	character:SetAttribute("GuardMeter", math.floor(record.GuardMeter))
end

local function raiseGuard(character: Model, record: CombatState.Record, allowParry: boolean)
	updateMeter(character, record)
	record.GuardStartedAt = if allowParry then os.clock() else -math.huge
	CombatState.Set(character, States.Guarding)
end

-- Called when the guard key goes down or up.
function Guard.Request(character: Model, isPressed: boolean)
	local record = CombatState.Get(character)
	record.GuardHeld = isPressed

	if isPressed then
		local now = os.clock()
		local mashing = now - record.LastGuardPressAt < frames(CombatSettings.ParryCooldownFrames)
		record.LastGuardPressAt = now
		if CombatState.CanAct(character) then
			raiseGuard(character, record, not mashing)
		end
	elseif record.State == States.Guarding then
		updateMeter(character, record)
		CombatState.Set(character, States.Idle)
	end
end

-- Holding guard through hitstun (or an attack) puts guard back up as soon as
-- you're free, but without a parry window.
CombatState.OnBecameIdle = function(character, record)
	if record.GuardHeld then
		task.defer(function()
			if CombatState.CanAct(character) and record.GuardHeld then
				raiseGuard(character, record, false)
			end
		end)
	end
end

-- Is the attacker in front of the defender? (Guard only covers the front half.)
local function isInFront(defender: Model, attacker: Model): boolean
	local defenderRoot = defender:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerRoot = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not defenderRoot or not attackerRoot then
		return false
	end
	local offset = attackerRoot.Position - defenderRoot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 0.01 then
		return true
	end
	return Movers.FlatLook(defenderRoot):Dot(flat.Unit) > 0
end

-- Called by HitHandler before a hit does damage. Decides what happens.
-- Returns "Hit" when the hit should go through normally.
function Guard.TryBlock(attacker: Model, defender: Model, hit): BlockResult
	local record = CombatState.Get(defender)
	if record.State ~= States.Guarding or not isInFront(defender, attacker) then
		return "Hit"
	end

	local now = os.clock()
	local humanoid = defender:FindFirstChildOfClass("Humanoid") :: Humanoid

	-- Parry
	if now - record.GuardStartedAt <= frames(CombatSettings.ParryWindowFrames) then
		local attackerRecord = CombatState.Get(attacker)
		attackerRecord.ComboIndex = 0
		attackerRecord.BufferedM1At = nil
		CombatState.Set(attacker, States.Hitstun, CombatSettings.ParriedStunFrames)
		-- The defender drops guard so they can punish right away.
		record.GuardHeld = false
		CombatState.Set(defender, States.Idle)
		return "Parried"
	end

	-- Block
	updateMeter(defender, record)
	humanoid:TakeDamage(hit.Damage * CombatSettings.GuardChipMultiplier)
	record.GuardMeter -= hit.Damage * CombatSettings.GuardMeterPerDamage
	defender:SetAttribute("GuardMeter", math.max(0, math.floor(record.GuardMeter)))

	if record.GuardMeter <= 0 then
		record.GuardMeter = CombatSettings.GuardMeterMax
		record.GuardMeterUpdatedAt = now
		CombatState.Set(defender, States.GuardBroken, CombatSettings.GuardBreakStunFrames)
		return "GuardBroken"
	end

	record.BlockstunUntil = now + frames(hit.Hitstun * CombatSettings.BlockstunMultiplier)
	local attackerRoot = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if attackerRoot then
		local pushback = Movers.FlatLook(attackerRoot) * hit.Knockback * CombatSettings.BlockPushbackMultiplier
		Movers.Push(defender, pushback, CombatSettings.KnockbackFrames)
	end
	return "Blocked"
end

return Guard
