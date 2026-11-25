--[[
	TestDummy (server only)
	Spawns an R6 training dummy so you can test combos without a second player.
	Turn it off with CombatSettings.SpawnTestDummy = false.
	It respawns 3 seconds after dying.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSettings = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatSettings"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))
local Hitbox = require(script.Parent:WaitForChild("Hitbox"))

local TestDummy = {}

local function getSpawnCFrame(): CFrame
	if CombatSettings.TestDummyPosition then
		return CFrame.new(CombatSettings.TestDummyPosition)
	end
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		local base = spawnLocation.CFrame + Vector3.new(0, spawnLocation.Size.Y / 2 + 3, 0)
		-- 12 studs in front, turned to face the spawn.
		local position = (base * CFrame.new(0, 0, -12)).Position
		return CFrame.lookAt(position, Vector3.new(base.X, position.Y, base.Z))
	end
	return CFrame.new(0, 5, 0)
end

local function spawnDummy()
	local ok, dummy = pcall(function()
		return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	end)
	if not ok then
		warn("[Combat] Couldn't create the test dummy:", dummy)
		return
	end

	dummy.Name = "TestDummy"
	local humanoid = dummy:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = "Test Dummy"

	CollectionService:AddTag(dummy, Hitbox.TargetTag)
	dummy:PivotTo(getSpawnCFrame())
	dummy.Parent = workspace
	CombatState.Reset(dummy)

	humanoid.Died:Connect(function()
		CombatState.Remove(dummy)
		task.delay(3, function()
			dummy:Destroy()
			spawnDummy()
		end)
	end)
end

function TestDummy.Start()
	if CombatSettings.SpawnTestDummy then
		spawnDummy()
	end
end

return TestDummy
