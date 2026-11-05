AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = translate.Get("wn_manhackcontroll")
	SWEP.Description = translate.Get("wn_manhackcontrolldes")

	SWEP.ViewModelFOV = 50

	SWEP.BobScale = 0.5
	SWEP.SwayScale = 0.5

	SWEP.Slot = 4
	SWEP.SlotPos = 0
end

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.EntityClass = "prop_manhack"

SWEP.Primary.Delay = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Delay = 20
SWEP.Secondary.Heal = 10

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
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
		if not IsValid(owner) then return end
		for _, ent in ipairs(GAMEMODE:GetZSClassEntities(self.EntityClass)) do
			if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:GetOwner() == owner then return end
		end
		owner:StripWeapon(self:GetClass())
	end
end

function SWEP:PrimaryAttack()
	if IsFirstTimePredicted() then
		self:SetDTBool(0, not self:GetDTBool(0))

		if CLIENT then
			LocalPlayer():EmitSound(self:GetDTBool(0) and "buttons/button17.wav" or "buttons/button19.wav", 0)
		end
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) or not GAMEMODE:HasPlayerTrait(owner, "dronepilot") then return end
	self:SetNextSecondaryFire(CurTime() + 0.2)
	if SERVER then GAMEMODE:FireTraitDrone(owner, self) end
end

	
function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	self.IdleAnimation = CurTime() + self:SequenceDuration()

	return true
end

function SWEP:Holster()
	self:SetDTBool(0, false)

	return true
end

function SWEP:Reload()
	if SERVER then GAMEMODE:UpgradeTraitDrone(self:GetOwner(), self) end
	return false
end

if not CLIENT then return end

function SWEP:DrawHUD()
	if GAMEMODE:DrawTraitDroneHUD(self:GetOwner(), self) and GetConVar("crosshair"):GetInt() == 1 and self.DrawCrosshairDot then
		self:DrawCrosshairDot()
	end
end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end
