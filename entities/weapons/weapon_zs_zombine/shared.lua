AddCSLuaFile()

SWEP.Base = "weapon_zs_zombie"
SWEP.MeleeDelay = 0.3
SWEP.MeleeReach = 40
SWEP.MeleeDamage = 40
SWEP.MeleeForceScale = 1
SWEP.MeleeSize = 1
SWEP.MeleeDamageType = DMG_SLASH
SWEP.Primary.Delay = 1
SWEP.Primary.Automatic = false
SWEP.Secondary.Delay = 10
SWEP.Secondary.Ammo = "pistol"
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.RequiredClip = 1
SWEP.MoanDelay = 1
SWEP.SpawnUseDelay = 5
SWEP.GrenadePullTime = 0.5
SWEP.SprintMultiplier = 1.8
SWEP.ViewModel = Model("models/weapons/zombine/v_zombine.mdl")
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

AccessorFuncDT(SWEP, "AttackAnimTime", "Float", 3)

function SWEP:SetupDataTables()
 self:NetworkVar("Bool", 5, "Grenading")
 self:NetworkVar("Float", 5, "SpawnedTime")
 self:NetworkVar("Float", 6, "GrenadeTime")
end

function SWEP:Think()
 local owner = self:GetOwner()
 if not IsValid(owner) then return end
 if SERVER and self:GetGrenading() and not owner:GetStatus("zombine_grenade") then
  self:SetGrenading(false)
  self:SetGrenadeTime(0)
 end
 if CLIENT and not self:GetGrenading() then self:RemoveGrenadeModel() end
 self:CheckMeleeAttack()
 self:CheckMoaning()
 self:CheckIdleAnimation()
end

function SWEP:PrimaryAttack()
 if self:GetGrenading() then return end
 self.BaseClass.PrimaryAttack(self)
 if self:IsSwinging() then self:SetAttackAnimTime(CurTime() + self.Primary.Delay) end
end

function SWEP:SendAttackAnim()
 self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:IsInAttackAnim()
 return self:GetAttackAnimTime() > CurTime()
end

function SWEP:StartMoaning()
 local owner = self:GetOwner()
 if not IsValid(owner) or not owner:Alive() or owner:Team() ~= TEAM_UNDEAD or self:IsMoaning()
  or IsValid(owner.Revive) or IsValid(owner.FeignDeath) then return end
 self:SetMoaning(true)
 self:SetMoanHealth(owner:Health())
 owner:SetWalkSpeed(owner:GetMaxSpeed() * self.SprintMultiplier)
 self:StartMoaningSound()
end

function SWEP:StopMoaning(damaged)
 local owner = self:GetOwner()
 if not self:IsMoaning() or damaged and IsValid(owner) and owner.m_Zombie_MoanGuard then return end
 self:SetMoaning(false)
 if IsValid(owner) then owner:ResetSpeed() end
 self:StopMoaningSound()
end

function SWEP:StartMoaningSound()
 if not SERVER then return end
 self:StopMoaningSound()
 self.ZSMoanSound = "weapons/npc/zombine/zombie_voice_idle" .. math.random(1, 10) .. ".wav"
 self:GetOwner():EmitSound(self.ZSMoanSound)
end

function SWEP:StopMoaningSound()
 local sound, owner = self.ZSMoanSound, self:GetOwner()
 self.ZSMoanSound = nil
 if sound and IsValid(owner) then owner:StopSound(sound) end
end

function SWEP:Deploy()
 self.BaseClass.Deploy(self)
 return true
end

function SWEP:OnRemove()
 self:StopMoaning()
 if CLIENT then self:RemoveGrenadeModel() end
end

function SWEP:Holster()
 self:OnRemove()
 return true
end

function SWEP:TakeAmmo()
 self:TakeSecondaryAmmo(self.RequiredClip)
end

function SWEP:PlayAttackSound()
 self:GetOwner():EmitSound("weapons/npc/zombine/zo_attack" .. math.random(1, 2) .. ".wav")
end

function SWEP:PlayAlertSound()
 self:GetOwner():EmitSound("weapons/npc/zombine/zombie_voice_idle" .. math.random(1, 10) .. ".wav")
end
SWEP.PlayIdleSound = SWEP.PlayAlertSound
