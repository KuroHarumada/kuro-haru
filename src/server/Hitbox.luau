--[[
	Hitbox (server only)
	Finds which characters are inside an attack's hitbox right now.
	Runs on the server using the server's view of positions, so a cheating
	client can't hit people from across the map.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))

local Hitbox = {}

-- Anything with this tag can be hit even if it isn't a player (test dummies, NPCs).
Hitbox.TargetTag = "CombatTarget"

-- Everyone who could be hit, except the attacker.
local function getPossibleTargets(attacker: Model): { Instance }
	local targets = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character ~= attacker then
			table.insert(targets, character)
		end
	end
	for _, model in CollectionService:GetTagged(Hitbox.TargetTag) do
		if model ~= attacker then
			table.insert(targets, model)
		end
	end
	return targets
end

local function showHitbox(boxCFrame: CFrame, size: Vector3)
	local part = Instance.new("Part")
	part.Name = "HitboxPreview"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(255, 40, 40)
	part.Transparency = 0.3
	part.Size = size
	part.CFrame = boxCFrame
	part.Parent = workspace
	task.delay(0.15, part.Destroy, part)
end

-- Returns a list of characters (Models with a living Humanoid) inside the box.
-- `move` needs HitboxSize (Vector3) and HitboxOffset (CFrame).
function Hitbox.Query(attacker: Model, move: { HitboxSize: Vector3, HitboxOffset: CFrame }): { Model }
	local root = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return {}
	end

	local boxCFrame = root.CFrame * move.HitboxOffset
	local size = move.HitboxSize + Vector3.one * CombatSettings.LagLeniencyStuds

	if CombatSettings.ShowHitboxes then
		showHitbox(boxCFrame, size)
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = getPossibleTargets(attacker)

	local found: { Model } = {}
	local seen: { [Model]: boolean } = {}
	for _, part in workspace:GetPartBoundsInBox(boxCFrame, size, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		-- Accessories are inside the character, so walk up until we find the Humanoid's model.
		while model and not model:FindFirstChildOfClass("Humanoid") do
			model = model:FindFirstAncestorOfClass("Model")
		end
		if model and not seen[model] then
			seen[model] = true
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(found, model)
			end
		end
	end
	return found
end

return Hitbox
