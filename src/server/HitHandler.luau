--[[
	HitHandler (server only)
	What happens when an attack connects: damage, hitstun, knockback, and
	telling every client to show the hit effect.

	Guard decides first whether the hit is blocked, parried or breaks guard.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Movers = require(script.Parent:WaitForChild("Movers"))

local EffectRemote: RemoteEvent = ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Effect")

local HitHandler = {}

export type HitData = {
	Name: string,
	Damage: number,
	Hitstun: number,
	Knockback: number,
	Launch: number,
}

local function applyKnockback(attacker: Model, victim: Model, hit: HitData)
	local attackerRoot = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerRoot then
		return
	end
	-- Push in the direction the attacker is facing, plus upward for launchers.
	local velocity = Movers.FlatLook(attackerRoot) * hit.Knockback + Vector3.yAxis * hit.Launch
	Movers.Push(victim, velocity, CombatSettings.KnockbackFrames)
end

local function sendEffect(effectName: string, attacker: Model, victim: Model, hit: HitData)
	-- Tell every client so they can show VFX, sounds and screen shake.
	EffectRemote:FireAllClients(effectName, {
		Attacker = attacker,
		Victim = victim,
		Move = hit.Name,
		Damage = hit.Damage,
	})
end

function HitHandler.Apply(attacker: Model, victim: Model, hit: HitData)
	local humanoid = victim:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local result = Guard.TryBlock(attacker, victim, hit)
	if result ~= "Hit" then
		-- Effect names: "Blocked", "Parried", "GuardBroken"
		sendEffect(result, attacker, victim, hit)
		if CombatSettings.Debug then
			print(`[Combat] {victim.Name}: {result} {attacker.Name}'s {hit.Name}`)
		end
		return
	end

	humanoid:TakeDamage(hit.Damage)

	-- Getting hit cancels whatever the victim was doing and resets their own combo.
	local victimRecord = CombatState.Get(victim)
	victimRecord.ComboIndex = 0
	victimRecord.BufferedM1At = nil
	CombatState.Set(victim, CombatState.States.Hitstun, hit.Hitstun)

	applyKnockback(attacker, victim, hit)

	sendEffect("Hit", attacker, victim, hit)

	if CombatSettings.Debug then
		print(`[Combat] {attacker.Name} hit {victim.Name} with {hit.Name} for {hit.Damage}`)
	end
end

return HitHandler
