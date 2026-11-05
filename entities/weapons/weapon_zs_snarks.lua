AddCSLuaFile()
SWEP.Base="weapon_zs_basemelee"
SWEP.PrintName="Snark Carrier"
SWEP.Description="Throw an allied Snark. Three charges, three active companions, twelve-second lifespan."
SWEP.ViewModel="models/weapons/c_bugbait.mdl"
SWEP.WorldModel="models/weapons/w_bugbait.mdl"
SWEP.UseHands=true
SWEP.HoldType="grenade"
SWEP.IsMelee=false
SWEP.NoWeaponForge=true
SWEP.WalkSpeed=SPEED_FAST
SWEP.Primary.ClipSize=3
SWEP.Primary.DefaultClip=3
SWEP.Primary.Automatic=false
SWEP.Primary.Ammo="none"
SWEP.Primary.Delay=1
SWEP.Secondary.ClipSize=-1
SWEP.Secondary.DefaultClip=-1
SWEP.Secondary.Ammo="none"
local failures={empty="All three Snark charges have been used.",limit="The active Snark limit has been reached.",blocked="There is no room to release a Snark here.",cooldown="Wait before releasing another Snark.",unavailable="You cannot release a Snark right now.",failed="The Snark could not be released."}
function SWEP:PrimaryAttack()
 if not IsFirstTimePredicted()then return end
 if SERVER then
  local owner=self:GetOwner()
  local ok,reason=GAMEMODE:DeployTraitSnark(owner,self)
  if not ok then
   self:SetNextPrimaryFire(CurTime()+0.25)
   if IsValid(owner)and not owner:IsBot()then owner:CenterNotify(COLOR_RED,failures[reason]or failures.failed)end
   return
  end
  self:SetNextPrimaryFire(CurTime()+1);self:SendWeaponAnim(ACT_VM_THROW);owner:DoAttackEvent();self:EmitSound("WeaponFrag.Throw")
 end
end
function SWEP:SecondaryAttack()end
function SWEP:Reload()end
if CLIENT then
 function SWEP:DrawHUD()
  GAMEMODE:DrawMeleeCrosshair()
  GAMEMODE:DrawTraitSnarkHUD(self:GetOwner(),self)
 end
end
