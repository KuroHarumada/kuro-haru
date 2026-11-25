--[[
	AttackRunner (server only)
	Plays out one attack: Startup (wind-up) -> Active (hitbox out) -> Recovery.
	Used by the M1 combo and by specials so every attack times hits the same way.

	The character must already be in the Attacking state; pass the token you
	got right after setting it. If anything changes their state (like getting
	hit or parried), the attack stops and Perform returns false.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Hitbox = require(script.Parent:WaitForChild("Hitbox"))
local HitHandler = require(script.Parent:WaitForChild("HitHandler"))

local frames = CombatSettings.FramesToSeconds

local AttackRunner = {}

-- Returns true if the attack finished its recovery without being interrupted.
function AttackRunner.Perform(character: Model, record: CombatState.Record, token: number, hit): boolean
	CombatState.PlayAnimation(character, hit.Animation)

	-- Startup
	task.wait(frames(hit.Startup))
	if not CombatState.IsStillValid(character, record, token) then
		return false
	end

	-- Active: check the hitbox every frame, but hit each victim only once.
	local alreadyHit: { [Model]: boolean } = {}
	local activeEnds = os.clock() + frames(hit.Active)
	repeat
		for _, victim in Hitbox.Query(character, hit) do
			if not alreadyHit[victim] then
				alreadyHit[victim] = true
				HitHandler.Apply(character, victim, hit)
			end
		end
		RunService.Heartbeat:Wait()
	until os.clock() >= activeEnds or not CombatState.IsStillValid(character, record, token)

	if not CombatState.IsStillValid(character, record, token) then
		return false
	end

	-- Recovery
	task.wait(frames(hit.Recovery))
	return CombatState.IsStillValid(character, record, token)
end

return AttackRunner
