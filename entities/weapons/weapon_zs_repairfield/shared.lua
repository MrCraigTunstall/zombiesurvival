SWEP.PrintNameTranslation = "weapon_repairfield"
SWEP.DescriptionTranslation = "weapon_repairfield_desc"
SWEP.Base = "weapon_zs_base"
SWEP.PrintName = translate.Get("weapon_repairfield")
SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.Description = translate.Get("weapon_repairfield_desc")
SWEP.TranslatedDescription = SWEP.Description
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Ammo = "pulse"
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.5
SWEP.Primary.Damage = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.EmptyWhenPurchased = false
SWEP.RepairRadius = 200
SWEP.RepairRate = 30
SWEP.RepairPerTarget = 10
SWEP.RepairInterval = 0.5
SWEP.RepairAimDot = 0.5
SWEP.MaxRepairTargets = 3
SWEP.MaxCandidates = 64
SWEP.MaxRepairTraces = 8

function SWEP:GetFieldCharge()
	local owner = self:GetOwner()
	return IsValid(owner) and owner:GetAmmoCount(self.Primary.Ammo) or 0
end

function SWEP:CanPrimaryAttack()
	local owner = self:GetOwner()
	return not self.Repairing and CurTime() >= self:GetNextPrimaryFire() and IsValid(owner)
		and owner:IsPlayer() and owner:Alive() and owner:Team() == TEAM_HUMAN and not owner:IsHolding()
		and not owner:GetBarricadeGhosting() and owner:GetAmmoCount(self.Primary.Ammo) > 0
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	if SERVER then
		local owner = self:GetOwner()
		self.Repairing = true
		local ok, healed = xpcall(GAMEMODE.RepairBarricadesInField, debug.traceback, GAMEMODE, self, owner, owner:GetShootPos(), CurTime(), owner:GetAimVector())
		self.Repairing = false
		if self.FieldRepairWork > 0 then
			owner:RemoveAmmo(1, self.Primary.Ammo)
			self:SetDTFloat(0, CurTime() + 0.2)
			self:EmitSound("ambient/energy/weld1.wav", 65, 110)
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		end
		if not ok then error(healed, 0) end
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end
