--[[
	Class: Kuro
	Rush-down style: closes distance fast and mixes up the opponent's guard.

	Combo       Which M1 string this class uses (a file in Combat > Moves).
	Specials    The class's special moves. Slot names match the keybinds in
	            CombatSettings (Special1 = Z by default).

	TELEPORT KICK fields:
	  Range           How far away (studs) a target can be to teleport to it.
	  BehindDistance  How far behind the target (studs) Kuro appears.
	  VanishFrames    Frames before the teleport happens (the wind-up you can react to).
	  VanishAnimation Animation during the wind-up ("" = none yet).
	  Cooldown        Frames before it can be used again (60 = 1 second).
	  WhiffCooldown   Cooldown when there's no one in range (shorter, nothing happened).
	  Kick            The attack after the teleport. Same fields as a combo hit
	                  (see Moves/BasicCombo).

	Because Kuro appears BEHIND the target, a guard facing the old direction
	won't block it. The defender has VanishFrames to react and turn around.
]]

return {
	Name = "Kuro",
	Style = "Rush-down",
	Combo = "BasicCombo",

	Specials = {
		Special1 = {
			Type = "TeleportKick",
			Name = "Teleport Kick",
			Range = 30,
			BehindDistance = 3,
			VanishFrames = 14,
			VanishAnimation = "",
			Cooldown = 300,
			WhiffCooldown = 60,
			Kick = {
				Name = "TeleportKick",
				Animation = "",
				Damage = 8,
				Startup = 6,
				Active = 4,
				Recovery = 24,
				Hitstun = 32,
				Knockback = 35,
				Launch = 12,
				HitboxSize = Vector3.new(4.5, 5, 5),
				HitboxOffset = CFrame.new(0, 0, -3),
			},
		},
	},
}
