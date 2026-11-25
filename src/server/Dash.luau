--[[
	Dash (server only)
	Press the dash key to dash the way you're walking (or forward if standing).
	In the air it becomes an air dash: one per jump, and it ignores gravity
	while it lasts. Ground and air dash have separate cooldowns.

	The client sends which way it's walking. That's the only thing we take
	from the client, and it's checked: a cheater can only pick a direction,
	not the speed or distance.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Movers = require(script.Parent:WaitForChild("Movers"))

local frames = CombatSettings.FramesToSeconds
local States = CombatState.States

local Dash = {}

-- R6: HumanoidRootPart sits about 3 studs above the feet.
local GROUND_CHECK_DISTANCE = 4

local function isGrounded(character: Model, root: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return workspace:Raycast(root.Position, Vector3.new(0, -GROUND_CHECK_DISTANCE, 0), params) ~= nil
end

-- Turn whatever the client sent into a safe flat direction (or nil).
local function cleanDirection(direction: unknown): Vector3?
	if typeof(direction) ~= "Vector3" then
		return nil
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	local length = flat.Magnitude
	if length < 0.1 or length ~= length or length == math.huge then -- too small, NaN or infinite
		return nil
	end
	return flat.Unit
end

function Dash.Request(character: Model, direction: unknown)
	if not CombatState.CanAct(character) then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local record = CombatState.Get(character)
	local now = os.clock()
	local grounded = isGrounded(character, root)
	local dir = cleanDirection(direction) or Movers.FlatLook(root)

	local speed, duration
	if grounded then
		if now < record.DashReadyAt then
			return
		end
		record.DashReadyAt = now + frames(CombatSettings.DashCooldownFrames)
		speed, duration = CombatSettings.DashSpeed, CombatSettings.DashFrames
	else
		if record.AirDashUsed or now < record.AirDashReadyAt then
			return
		end
		record.AirDashUsed = true
		record.AirDashReadyAt = now + frames(CombatSettings.AirDashCooldownFrames)
		speed, duration = CombatSettings.AirDashSpeed, CombatSettings.AirDashFrames
	end

	CombatState.Set(character, States.Dashing, duration)
	Movers.Push(character, dir * speed, duration)

	if CombatSettings.Debug then
		print(`[Combat] {character.Name} {grounded and "dashed" or "air dashed"}`)
	end
end

-- Lets the air dash be used again after landing. Checked on the server
-- (10 times a second, only while the air dash is used up), so it can't be faked.
function Dash.SetupCharacter(character: Model)
	task.spawn(function()
		if not character.Parent then
			character.AncestryChanged:Wait()
		end
		while character.Parent do
			local record = CombatState.Get(character)
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if record.AirDashUsed and root and isGrounded(character, root) then
				record.AirDashUsed = false
			end
			task.wait(0.1)
		end
	end)
end

return Dash
