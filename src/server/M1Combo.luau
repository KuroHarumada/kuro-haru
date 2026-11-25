--[[
	M1Combo (server only)
	Runs the character's M1 string (which one depends on their class, see Classes).

	Each swing goes: Startup (wind-up) -> Active (hitbox out) -> Recovery,
	then back to Idle. Getting hit at any point cancels the swing.
	Pressing M1 near the end of a swing queues the next one (input buffer).
	Waiting too long after a swing ends resets the string back to hit 1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))

local AttackRunner = require(script.Parent:WaitForChild("AttackRunner"))
local Classes = require(script.Parent:WaitForChild("Classes"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))

local frames = CombatSettings.FramesToSeconds

local M1Combo = {}

local function runSwing(character: Model)
	local combo = Classes.ComboFor(character)
	if not combo then
		return
	end
	local record = CombatState.Get(character)

	-- Pick which hit of the string comes next.
	local tooLate = os.clock() - record.LastComboTime > frames(CombatSettings.ComboResetFrames)
	if tooLate or record.ComboIndex >= #combo then
		record.ComboIndex = 0
	end
	record.ComboIndex += 1
	local hitIndex = record.ComboIndex
	local hit = combo[hitIndex]

	CombatState.Set(character, CombatState.States.Attacking)
	local token = record.Token

	if CombatSettings.Debug then
		print(`[Combat] {character.Name} swings {hit.Name} ({hitIndex}/{#combo})`)
	end

	if not AttackRunner.Perform(character, record, token, hit) then
		return
	end
	record.LastComboTime = os.clock()
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
