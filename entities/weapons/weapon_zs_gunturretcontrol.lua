SWEP.PrintNameTranslation = "wn_turretcontroll"
SWEP.DescriptionTranslation = "wn_turretcontrolldes"
AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = translate.Get("wn_turretcontroll")
	SWEP.TranslatedPrintName = SWEP.PrintName
	SWEP.Description = translate.Get("wn_turretcontrolldes")
	SWEP.TranslatedDescription = SWEP.Description

	SWEP.ViewModelFOV = 50

	SWEP.BobScale = 0.5
	SWEP.SwayScale = 0.5

	SWEP.Slot = 4
	SWEP.SlotPos = 0
end

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.Primary.Delay = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Delay = 20
SWEP.Secondary.Heal = 10

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.WalkSpeed = SPEED_FAST

SWEP.NoMagazine = true
SWEP.Undroppable = true
SWEP.NoPickupNotification = true

SWEP.HoldType = "slam"

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	self:SetDeploySpeed(10)
end

function SWEP:Think()
	if self.IdleAnimation and self.IdleAnimation <= CurTime() then
		self.IdleAnimation = nil
		self:SendWeaponAnim(ACT_VM_IDLE)
	end

	if SERVER and CurTime() >= (self.NextOwnedCheck or 0) then
		self.NextOwnedCheck = CurTime() + 0.1
		local owner = self:GetOwner()
		if IsValid(owner) and not self:ControlClosestTurret() then owner:StripWeapon(self:GetClass()) end
	end
end

function SWEP:ControlClosestTurret()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	local closest, closestdist
	local ownerpos = owner:GetPos()
	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_gunturret")) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:GetObjectOwner() == owner then
			local dist = ent:NearestPoint(ownerpos):DistToSqr(ownerpos)
			if not closestdist or dist < closestdist then closest, closestdist = ent, dist end
		end
	end
	if self:GetTurret() ~= (closest or NULL) then self:SetTurret(closest or NULL) end
	return closest
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
	if IsFirstTimePredicted() then
		self:SetDTBool(0, not self:GetDTBool(0))

		if CLIENT then
			LocalPlayer():EmitSound(self:GetDTBool(0) and "buttons/button17.wav" or "buttons/button19.wav", 0)
		end
	end
end

function SWEP:GetTurret()
	return self:GetDTEntity(0)
end

function SWEP:SetTurret(ent)
	self:SetDTEntity(0, ent)
end

function SWEP:Reload()
	return false
end
	
function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	self.IdleAnimation = CurTime() + self:SequenceDuration()

	return true
end

function SWEP:Holster()
	return true
end

function SWEP:Reload()
end

if not CLIENT then return end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end
