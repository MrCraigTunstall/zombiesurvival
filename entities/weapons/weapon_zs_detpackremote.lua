SWEP.PrintNameTranslation = "wn_detpackremote"
SWEP.DescriptionTranslation = "wn_detpackremotedes"
AddCSLuaFile()

if CLIENT then
	SWEP.ViewModelFOV = 50
	SWEP.BobScale = 0.5
	SWEP.SwayScale = 0.5
	SWEP.PrintName = translate.Get("wn_detpackremote")
	SWEP.TranslatedPrintName = SWEP.PrintName
	SWEP.Description = translate.Get("wn_detpackremotedes")
	SWEP.TranslatedDescription = SWEP.Description

	SWEP.Slot = 4
	SWEP.SlotPos = 0
end

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.WalkSpeed = SPEED_NORMAL

SWEP.NoMagazine = true
SWEP.Undroppable = true
SWEP.NoPickupNotification = true

SWEP.HoldType = "slam"

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

if SERVER then
function SWEP:Think()
	local now = CurTime()
	if now < (self.NextOwnerCheck or 0) then return end
	self.NextOwnerCheck = now + 0.25
	if not IsValid(self.Owner) then self:Remove(); return end
	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_detpack")) do
		if ent:GetOwner() == self.Owner then
			return
		end
	end

	self.Owner:StripWeapon(self:GetClass())
end
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.2)
	self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

	if CLIENT then return end

	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_detpack")) do
		if ent:GetOwner() == self.Owner and ent:GetExplodeTime() == 0 then
			ent:SetExplodeTime(CurTime() + ent.ExplosionDelay)
		end
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	return false
end
	
function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	self:SendWeaponAnim(ACT_SLAM_DETONATOR_IDLE)

	return true
end

function SWEP:Holster()
	return true
end

if not CLIENT then return end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end

function SWEP:Think()
end
