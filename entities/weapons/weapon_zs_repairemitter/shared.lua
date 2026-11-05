SWEP.Base = "weapon_zs_ffemitter"
SWEP.PrintName = translate.Get("worth_repairemitter")
SWEP.Description = translate.Get("worth_repairemitter_desc")
SWEP.WorldModel = Model("models/props_lab/reciever01b.mdl")
SWEP.Primary.Ammo = "repairemitter"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1

function SWEP:CanPrimaryAttack()
	return CurTime() >= self:GetNextPrimaryFire() and self.BaseClass.CanPrimaryAttack(self)
end
