--[[
	Movers (server only)
	Pushes a character at a set velocity for a few frames. Used by knockback
	and dashes. Only one push runs at a time per character: a new one (like
	getting hit mid-dash) replaces the old one.

	A LinearVelocity made on the server also works on players' own characters,
	because it gets copied to the client that controls that character.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))

local Movers = {}

local MOVER_NAME = "CombatMover"

function Movers.Push(character: Model, velocity: Vector3, durationFrames: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	Movers.Stop(character)

	local attachment = Instance.new("Attachment")
	attachment.Name = MOVER_NAME

	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.VectorVelocity = velocity
	mover.MaxForce = math.huge
	mover.Parent = attachment

	attachment.Parent = root
	task.delay(CombatSettings.FramesToSeconds(durationFrames), function()
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

function Movers.Stop(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	local old = root and root:FindFirstChild(MOVER_NAME)
	if old then
		old:Destroy()
	end
end

-- The direction `from` is facing, flattened so it ignores looking up or down.
function Movers.FlatLook(part: BasePart): Vector3
	local look = part.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		return Vector3.zAxis
	end
	return flat.Unit
end

return Movers
