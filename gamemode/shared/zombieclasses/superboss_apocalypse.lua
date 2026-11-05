CLASS.Base = "zombie"
CLASS.Name = "Apocalypse"
CLASS.TranslationName = "class_apocalypse"
CLASS.Description = "description_apocalypse"
CLASS.Help = "controls_apocalypse"
CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true
CLASS.SuperBoss = true
CLASS.IsDefault = false
CLASS.Revives = false
CLASS.CanFeignDeath = false
CLASS.Health = 3500
CLASS.Speed = 180
CLASS.JumpPower = 320
CLASS.FearPerInstance = 2
CLASS.Points = 50
CLASS.SWEP = "weapon_zs_apocalypse"
CLASS.Model = Model("models/player/zombie_classic.mdl")
CLASS.VoicePitch = 0.5
CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true
function CLASS:ProcessDamage(pl, info) info:ScaleDamage(0.85) end
function CLASS:OnSpawned(pl) pl.ZSSuperBoss = true; pl:SetJumpPower(self.JumpPower) end
if CLIENT then
	local material, color = Material("sprites/light_glow02_add"), Color(255, 50, 50, 100)
	function CLASS:PostPlayerDraw(pl)
		render.SetMaterial(material); render.DrawSprite(pl:GetPos() + Vector(0, 0, 30), 80, 80, color)
	end
end
