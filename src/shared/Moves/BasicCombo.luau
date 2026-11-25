--[[
	BasicCombo (the M1 string)
	One entry per hit, in order. The last one is the finisher.

	What each field means:
	  Animation   The animation's asset id, e.g. "rbxassetid://1234567890". Leave "" until you have one.
	  Damage      Health removed on a clean hit.
	  Startup     Frames from pressing the button until the hitbox appears (the wind-up).
	  Active      Frames the hitbox stays out and can hit someone.
	  Recovery    Frames after the hitbox ends before the attacker can act again.
	  Hitstun     Frames the victim can't act after being hit.
	  Knockback   How hard the victim is pushed away (studs per second).
	  Launch      How hard the victim is pushed upward (0 = stays on the ground).
	  HitboxSize  Box size in studs (width, height, depth).
	  HitboxOffset  Where the box sits relative to the attacker's HumanoidRootPart.
	                Negative Z = in front of the character.

	Rule of thumb for a working combo: each hit's Hitstun must be longer than
	(this hit's Active + Recovery + the next hit's Startup), plus ~4 frames of
	safety for server timing. Otherwise the victim can escape mid-string.
	Current values: Jab1 needs 16, Jab2 needs 17 (both have 22). Jab3 needs 22, has 28.
	(60 frames = 1 second.)
]]

return {
	{
		Name = "Jab1",
		Animation = "",
		Damage = 3,
		Startup = 5,
		Active = 3,
		Recovery = 8,
		Hitstun = 22,
		Knockback = 2,
		Launch = 0,
		HitboxSize = Vector3.new(4, 5, 4),
		HitboxOffset = CFrame.new(0, 0, -3),
	},
	{
		Name = "Jab2",
		Animation = "",
		Damage = 3,
		Startup = 5,
		Active = 3,
		Recovery = 8,
		Hitstun = 22,
		Knockback = 2,
		Launch = 0,
		HitboxSize = Vector3.new(4, 5, 4),
		HitboxOffset = CFrame.new(0, 0, -3),
	},
	{
		Name = "Jab3",
		Animation = "",
		Damage = 4,
		Startup = 6,
		Active = 3,
		Recovery = 10,
		Hitstun = 28,
		Knockback = 3,
		Launch = 0,
		HitboxSize = Vector3.new(4, 5, 4.5),
		HitboxOffset = CFrame.new(0, 0, -3),
	},
	{
		Name = "Finisher",
		Animation = "",
		Damage = 6,
		Startup = 9,
		Active = 4,
		Recovery = 20,
		Hitstun = 35,
		Knockback = 45,
		Launch = 15,
		HitboxSize = Vector3.new(5, 5, 5),
		HitboxOffset = CFrame.new(0, 0, -3.5),
	},
}
