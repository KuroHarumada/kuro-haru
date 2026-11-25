--[[
	HitHandler (server only)
	What happens when an attack connects: damage, hitstun, knockback, and
	telling every client to show the hit effect.

	Step 3 will add guard and parry checks at the top of HitHandler.Apply.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))

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
	local victimRoot = victim:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerRoot or not victimRoot then
		return
	end

	-- Push in the direction the attacker is facing (flat), plus upward for launchers.
	local look = attackerRoot.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.zAxis
	end
	local velocity = flat.Unit * hit.Knockback + Vector3.yAxis * hit.Launch

	-- Replace any knockback that is still running from the previous hit.
	local old = victimRoot:FindFirstChild("CombatKnockback")
	if old then
		old:Destroy()
	end

	-- A LinearVelocity made on the server also works on players' own characters,
	-- because it gets copied to the client that controls that character.
	local attachment = Instance.new("Attachment")
	attachment.Name = "CombatKnockback"

	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.VectorVelocity = velocity
	mover.MaxForce = math.huge
	mover.Parent = attachment

	attachment.Parent = victimRoot
	task.delay(CombatSettings.FramesToSeconds(CombatSettings.KnockbackFrames), function()
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

function HitHandler.Apply(attacker: Model, victim: Model, hit: HitData)
	local humanoid = victim:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- (Step 3: guard, parry and guard break checks go here.)

	humanoid:TakeDamage(hit.Damage)

	-- Getting hit cancels whatever the victim was doing and resets their own combo.
	local victimRecord = CombatState.Get(victim)
	victimRecord.ComboIndex = 0
	victimRecord.BufferedM1At = nil
	CombatState.Set(victim, CombatState.States.Hitstun, hit.Hitstun)

	applyKnockback(attacker, victim, hit)

	-- Tell every client so they can show VFX, sounds and screen shake.
	EffectRemote:FireAllClients("Hit", {
		Attacker = attacker,
		Victim = victim,
		Move = hit.Name,
		Damage = hit.Damage,
	})

	if CombatSettings.Debug then
		print(`[Combat] {attacker.Name} hit {victim.Name} with {hit.Name} for {hit.Damage}`)
	end
end

return HitHandler
