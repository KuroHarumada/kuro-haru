--[[
	CombatEffects (client)
	Listens for combat events from the server and shows feedback.

	THIS IS THE PLACE FOR VFX. Right now each event just flashes a color.
	Swap the inside of onHit / onBlocked / onParried / onGuardBroken for your own
	effects (particles, sounds, camera shake).
	`data` holds: Attacker (Model), Victim (Model, the one being hit or guarding),
	Move (string, e.g. "Jab1") and Damage (number).
	Teleport events instead hold Character, and From / To positions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EffectRemote: RemoteEvent = ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Effect")

local CombatEffects = {}

-- Placeholder feedback: a quick colored flash on the victim.
local function flash(target: unknown, color: Color3, duration: number)
	if typeof(target) ~= "Instance" or not target.Parent then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 0.2
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.4
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = target
	task.delay(duration, highlight.Destroy, highlight)
end

-- Clean hit: white flash on the victim.
local function onHit(data)
	flash(data.Victim, Color3.new(1, 1, 1), 0.08)
end

-- Blocked: blue flash on the defender.
local function onBlocked(data)
	flash(data.Victim, Color3.fromRGB(80, 160, 255), 0.08)
end

-- Parried: gold flash on the defender, red on the stunned attacker.
local function onParried(data)
	flash(data.Victim, Color3.fromRGB(255, 210, 60), 0.15)
	flash(data.Attacker, Color3.fromRGB(255, 60, 60), 0.3)
end

-- Guard broken: long orange flash on the defender.
local function onGuardBroken(data)
	flash(data.Victim, Color3.fromRGB(255, 120, 0), 0.4)
end

-- A quick glowing ball that fades out, used as placeholder teleport VFX.
local function puff(position: unknown, color: Color3)
	if typeof(position) ~= "Vector3" then
		return
	end
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * 4
	ball.Position = position
	ball.Parent = workspace
	TweenService:Create(ball, TweenInfo.new(0.25), { Size = Vector3.one * 7, Transparency = 1 }):Play()
	task.delay(0.3, ball.Destroy, ball)
end

-- Kuro's teleport: wind-up started (data.Character).
local function onTeleportStart(data)
	flash(data.Character, Color3.fromRGB(120, 60, 255), 0.2)
end

-- Kuro's teleport: moved from data.From to data.To (positions).
local function onTeleport(data)
	puff(data.From, Color3.fromRGB(120, 60, 255))
	puff(data.To, Color3.fromRGB(120, 60, 255))
end

local handlers = {
	Hit = onHit,
	Blocked = onBlocked,
	Parried = onParried,
	GuardBroken = onGuardBroken,
	TeleportStart = onTeleportStart,
	Teleport = onTeleport,
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
