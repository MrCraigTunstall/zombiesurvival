CLASS.Base = "zombie"
CLASS.Name = "Doom"
CLASS.TranslationName = "class_doom"
CLASS.Description = "description_doom"
CLASS.Help = "controls_doom"
CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true
CLASS.SuperBoss = true
CLASS.IsDefault = false
CLASS.Revives = false
CLASS.CanFeignDeath = false
CLASS.Health = 3000
CLASS.Speed = 200
CLASS.JumpPower = 300
CLASS.FearPerInstance = 2
CLASS.Points = 50
CLASS.SWEP = "weapon_zs_doom"
CLASS.Model = Model("models/player/zombie_fast.mdl")
CLASS.VoicePitch = 0.6
CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true
function CLASS:ProcessDamage(pl, info) info:ScaleDamage(0.9) end
function CLASS:OnSpawned(pl) pl.ZSSuperBoss = true; pl:SetJumpPower(self.JumpPower) end
if CLIENT then
	local material, color = Material("sprites/light_glow02_add"), Color(200, 0, 0, 120)
	function CLASS:PostPlayerDraw(pl)
		render.SetMaterial(material); render.DrawSprite(pl:GetPos() + Vector(0, 0, 20), 60, 60, color)
	end
end
