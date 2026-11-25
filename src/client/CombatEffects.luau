--[[
	CombatEffects (client)
	Listens for combat events from the server and shows feedback.

	THIS IS THE PLACE FOR VFX. Right now a hit just flashes the victim white.
	Swap the inside of onHit for your own effects (particles, sounds, camera shake).
	`data` holds: Attacker (Model), Victim (Model), Move (string, e.g. "Jab1"),
	and Damage (number).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectRemote: RemoteEvent = ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Effect")

local CombatEffects = {}

local function onHit(data)
	local victim = data.Victim
	if typeof(victim) ~= "Instance" or not victim.Parent then
		return
	end

	-- Placeholder: quick white flash on the victim.
	local flash = Instance.new("Highlight")
	flash.FillColor = Color3.new(1, 1, 1)
	flash.FillTransparency = 0.2
	flash.OutlineTransparency = 1
	flash.DepthMode = Enum.HighlightDepthMode.Occluded
	flash.Parent = victim
	task.delay(0.08, flash.Destroy, flash)
end

local handlers = {
	Hit = onHit,
}

function CombatEffects.Start()
	EffectRemote.OnClientEvent:Connect(function(effectName, data)
		local handler = handlers[effectName]
		if handler then
			handler(data)
		end
	end)
end

return CombatEffects
