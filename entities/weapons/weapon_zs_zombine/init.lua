AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function SWEP:Equip()
 self.NextMoanToggle = 0
 self:SetSpawnedTime(CurTime() + self.SpawnUseDelay)
 self:SetGrenadeTime(0)
 self:SetGrenading(false)
end

function SWEP:Reload()
 local now = CurTime()
 if now < (self.NextMoanToggle or 0) or self:IsInAttackAnim()
  or self:GetGrenading() and now < self:GetGrenadeTime() then return end
 self.NextMoanToggle = now + self.MoanDelay
 if self:IsMoaning() then self:StopMoaning() else self:StartMoaning() end
end

function SWEP:SecondaryAttack()
 local owner, now = self:GetOwner(), CurTime()
 if not IsValid(owner) or not owner:Alive() or owner:Team() ~= TEAM_UNDEAD or not owner:OnGround()
  or self:GetGrenading() or self:IsInAttackAnim() or now < self:GetSpawnedTime() or now < self:GetNextSecondaryFire()
  or self:Clip2() < self.RequiredClip or owner:GetStatus("zombine_grenade") then return end
 local status = owner:GiveStatus("zombine_grenade")
 if not IsValid(status) then return end
 self:SetGrenading(true)
 self:SetGrenadeTime(now + self.GrenadePullTime)
 self.NextMoanToggle = math.max(self.NextMoanToggle or 0, now + self.GrenadePullTime)
 self:SetNextSecondaryFire(now + self.Secondary.Delay)
 self:TakeAmmo()
 self:StopMoaning()
 self:DoAlert()
 self:SendWeaponAnim(ACT_VM_DRAW)
end
