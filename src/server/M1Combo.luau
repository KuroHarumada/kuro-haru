--[[
	M1Combo (server only)
	Runs the basic M1 string from ReplicatedStorage.Combat.Moves.BasicCombo.

	Each swing goes: Startup (wind-up) -> Active (hitbox out) -> Recovery,
	then back to Idle. Getting hit at any point cancels the swing.
	Pressing M1 near the end of a swing queues the next one (input buffer).
	Waiting too long between swings resets the string back to hit 1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Combat")
local CombatSettings = require(Shared:WaitForChild("CombatSettings"))
local BasicCombo = require(Shared:WaitForChild("Moves"):WaitForChild("BasicCombo"))

local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Hitbox = require(script.Parent:WaitForChild("Hitbox"))
local HitHandler = require(script.Parent:WaitForChild("HitHandler"))

local frames = CombatSettings.FramesToSeconds

local M1Combo = {}

local function runSwing(character: Model)
	local record = CombatState.Get(character)
	local now = os.clock()

	-- Pick which hit of the string comes next.
	local tooLate = now - record.LastComboTime > frames(CombatSettings.ComboResetFrames)
	if tooLate or record.ComboIndex >= #BasicCombo then
		record.ComboIndex = 0
	end
	record.ComboIndex += 1
	local hitIndex = record.ComboIndex
	local hit = BasicCombo[hitIndex]

	CombatState.Set(character, CombatState.States.Attacking)
	local token = record.Token
	CombatState.PlayAnimation(character, hit.Animation)

	if CombatSettings.Debug then
		print(`[Combat] {character.Name} swings {hit.Name} ({hitIndex}/{#BasicCombo})`)
	end

	-- Startup
	task.wait(frames(hit.Startup))
	if not CombatState.IsStillValid(character, record, token) then
		return
	end

	-- Active: check the hitbox every frame, but hit each victim only once per swing.
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
		return
	end
	record.LastComboTime = os.clock()

	-- Recovery
	task.wait(frames(hit.Recovery))
	if not CombatState.IsStillValid(character, record, token) then
		return
	end
	CombatState.Set(character, CombatState.States.Idle)

	-- Input buffer: if M1 was pressed near the end of this swing, do the next one now.
	local bufferedAt = record.BufferedM1At
	record.BufferedM1At = nil
	if bufferedAt and os.clock() - bufferedAt <= frames(CombatSettings.InputBufferFrames) then
		M1Combo.Request(character)
	end
end

-- Called when the player presses M1.
function M1Combo.Request(character: Model)
	if CombatState.CanAct(character) then
		task.spawn(runSwing, character)
	elseif CombatState.GetState(character) == CombatState.States.Attacking then
		CombatState.Get(character).BufferedM1At = os.clock()
	end
end

return M1Combo
