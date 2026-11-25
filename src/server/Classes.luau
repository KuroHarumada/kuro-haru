--[[
	Classes (server only)
	Every player has a class, stored as the "Class" attribute on the Player.
	New players get CombatSettings.DefaultClass. A class picker can later just
	change that attribute (on the server).

	Class files live in ReplicatedStorage > Combat > Classes. Adding a new class
	is: copy Kuro, rename it, change its moves.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Combat")
local CombatSettings = require(Shared:WaitForChild("CombatSettings"))
local ClassFolder = Shared:WaitForChild("Classes")
local MovesFolder = Shared:WaitForChild("Moves")

local Classes = {}

local loaded = {}
for _, module in ClassFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		loaded[module.Name] = require(module)
	end
end

local combos = {}
for _, module in MovesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		combos[module.Name] = require(module)
	end
end

-- The class table for a character, or nil (e.g. a test dummy has no class).
function Classes.ForCharacter(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end
	return loaded[player:GetAttribute("Class")] or loaded[CombatSettings.DefaultClass]
end

-- The M1 string (list of hits) this character uses.
function Classes.ComboFor(character: Model)
	local class = Classes.ForCharacter(character)
	return combos[class and class.Combo or "BasicCombo"]
end

function Classes.Start()
	assert(
		loaded[CombatSettings.DefaultClass],
		`[Combat] DefaultClass "{CombatSettings.DefaultClass}" has no class file`
	)
	local function onPlayerAdded(player: Player)
		if player:GetAttribute("Class") == nil then
			player:SetAttribute("Class", CombatSettings.DefaultClass)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return Classes
