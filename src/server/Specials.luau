--[[
	Specials (server only)
	Runs a class's special moves. Each special in a class file has a Type;
	this file has one function per Type. New special types get added here.

	Cooldowns are tracked per character and per slot, on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))

local AttackRunner = require(script.Parent:WaitForChild("AttackRunner"))
local Classes = require(script.Parent:WaitForChild("Classes"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Hitbox = require(script.Parent:WaitForChild("Hitbox"))
local Movers = require(script.Parent:WaitForChild("Movers"))

local EffectRemote: RemoteEvent = ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Effect")

local frames = CombatSettings.FramesToSeconds
local States = CombatState.States

local Specials = {}

-- Cooldowns: cooldownReadyAt[character][slot] = time it can be used again.
local cooldownReadyAt: { [Model]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any

local function setCooldown(character: Model, slot: string, cooldownFrames: number)
	cooldownReadyAt[character] = cooldownReadyAt[character] or {}
	cooldownReadyAt[character][slot] = os.clock() + frames(cooldownFrames)
	-- Copy to the character so a UI can show it later (seconds left = attribute - workspace time).
	character:SetAttribute(slot .. "Cooldown", workspace:GetServerTimeNow() + frames(cooldownFrames))
end

local function isOnCooldown(character: Model, slot: string): boolean
	local slots = cooldownReadyAt[character]
	return slots ~= nil and os.clock() < (slots[slot] or 0)
end

-- Closest living target within range (players and anything tagged CombatTarget).
local function findClosestTarget(character: Model, range: number): Model?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local candidates = {}
	for _, player in Players:GetPlayers() do
		table.insert(candidates, player.Character)
	end
	for _, model in game:GetService("CollectionService"):GetTagged(Hitbox.TargetTag) do
		table.insert(candidates, model)
	end

	local best, bestDistance = nil, range
	for _, candidate in candidates do
		if candidate and candidate ~= character then
			local humanoid = candidate:FindFirstChildOfClass("Humanoid")
			local candidateRoot = candidate:FindFirstChild("HumanoidRootPart") :: BasePart?
			if humanoid and humanoid.Health > 0 and candidateRoot then
				local distance = (candidateRoot.Position - root.Position).Magnitude
				if distance <= bestDistance then
					best, bestDistance = candidate, distance
				end
			end
		end
	end
	return best
end

-- Special types -----------------------------------------------------------------

local SpecialTypes = {}

-- Vanish, appear behind the closest opponent facing them, then kick.
function SpecialTypes.TeleportKick(character: Model, slot: string, move)
	local target = findClosestTarget(character, move.Range)
	if not target then
		setCooldown(character, slot, move.WhiffCooldown)
		if CombatSettings.Debug then
			print(`[Combat] {character.Name}: {move.Name} found no one in range`)
		end
		return
	end
	setCooldown(character, slot, move.Cooldown)

	local record = CombatState.Get(character)
	CombatState.Set(character, States.Attacking)
	local token = record.Token
	CombatState.PlayAnimation(character, move.VanishAnimation)
	EffectRemote:FireAllClients("TeleportStart", { Character = character })

	if CombatSettings.Debug then
		print(`[Combat] {character.Name} uses {move.Name} on {target.Name}`)
	end

	task.wait(frames(move.VanishFrames))
	if not CombatState.IsStillValid(character, record, token) then
		return
	end

	-- Re-check the target: they may have died or moved away during the wind-up.
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not root or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		CombatState.Set(character, States.Idle)
		return
	end

	-- "Behind" = opposite the way the target is facing. If a wall is in the way,
	-- stop just in front of the wall instead of teleporting into it.
	local backward = -Movers.FlatLook(targetRoot)
	local wallParams = RaycastParams.new()
	wallParams.FilterType = Enum.RaycastFilterType.Exclude
	wallParams.FilterDescendantsInstances = { character, target }
	local wall = workspace:Raycast(targetRoot.Position, backward * (move.BehindDistance + 1), wallParams)
	local distance = if wall
		then math.max(0, (wall.Position - targetRoot.Position).Magnitude - 1.5)
		else move.BehindDistance
	local behind = targetRoot.Position + backward * distance
	local facing = Vector3.new(targetRoot.Position.X, behind.Y, targetRoot.Position.Z)
	local from = root.Position
	Movers.Stop(character)
	character:PivotTo(CFrame.lookAt(behind, facing))

	EffectRemote:FireAllClients("Teleport", { Character = character, From = from, To = behind })

	if AttackRunner.Perform(character, record, token, move.Kick) then
		CombatState.Set(character, States.Idle)
	end
end

-- Called when a special key is pressed.
function Specials.Request(character: Model, slot: string)
	if not CombatState.CanAct(character) or isOnCooldown(character, slot) then
		return
	end
	local class = Classes.ForCharacter(character)
	local move = class and class.Specials[slot]
	if not move then
		return
	end
	local run = SpecialTypes[move.Type]
	if not run then
		warn(`[Combat] Unknown special type "{move.Type}" in class {class.Name}`)
		return
	end
	task.spawn(run, character, slot, move)
end

return Specials
