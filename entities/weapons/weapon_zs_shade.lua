AddCSLuaFile()

SWEP.Base = "weapon_zs_zombie"

SWEP.ViewModel = Model("models/weapons/v_fza.mdl")
SWEP.WorldModel = Model("models/weapons/w_crowbar.mdl")

if CLIENT then
	SWEP.ViewModelFOV = 70
end

SWEP.Primary.Automatic = false
SWEP.Secondary.Automatic = false
SWEP.PhysicsForce = 3500
SWEP.MutationMultiplier = 6000

function SWEP:Initialize()
	self:HideWorldModel()
end

function SWEP:SetupDataTables()
	self:NetworkVar("Entity", 20, "ShadeControl")
end

function SWEP:ReleaseShadeControl()
	if SERVER then GAMEMODE:ReleaseShadeControl(self:GetOwner(), self) end
end

function SWEP:Think()
end

function SWEP:PrimaryAttack()
	local now = CurTime()
	if now <= self:GetNextPrimaryFire() then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	self:SetNextPrimaryFire(now + 1.5)
	self:SetNextSecondaryFire(now + 0.4)
	if CLIENT then
		if IsValid(self:GetShadeControl()) then owner:DoAttackEvent() end
		return
	end
	if not GAMEMODE:IsShadeControllerOwner(owner, self) then self:ReleaseShadeControl() return end
	local control = GAMEMODE:GetShadeControl(owner)
	if not IsValid(control) then return end
	local obj = control:GetParent()
	if GAMEMODE:CanShadeHoldObject(obj) then
		local filter = team.GetPlayers(TEAM_UNDEAD)
		filter[#filter + 1] = obj
		local trace = owner:TraceLine(10240, MASK_SOLID, filter)
		local velocity = trace.HitPos - obj:WorldSpaceCenter()
		velocity:Normalize()
		velocity:Mul(owner.m_Shade_Force and self.MutationMultiplier or self.PhysicsForce)
		local phys = obj:GetPhysicsObject()
		phys:Wake()
		phys:SetVelocity(velocity)
		obj:SetPhysicsAttacker(owner, 10)
		phys:AddGameFlag(FVPHYSICS_WAS_THROWN)
		obj:EmitSound(")weapons/physcannon/superphys_launch" .. math.random(4) .. ".wav")
		owner:DoAttackEvent()
	end
	self:ReleaseShadeControl()
end

function SWEP:SecondaryAttack()
	local now = CurTime()
	if now <= self:GetNextSecondaryFire() then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	self:SetNextPrimaryFire(now + 0.25)
	self:SetNextSecondaryFire(now + 0.4)
	if CLIENT then return end
	if not GAMEMODE:IsShadeControllerOwner(owner, self) then self:ReleaseShadeControl() return end
	if GAMEMODE:GetShadeControl(owner) then self:ReleaseShadeControl() return end
	local obj = owner:TraceHull(400, MASK_SOLID, 4, {"player"}).Entity
	if not GAMEMODE:CanShadeHoldObject(obj) or GAMEMODE:GetShadeObjectControl(obj) then return end
	local control = ents.Create("env_shadecontrol")
	if not IsValid(control) then return end
	control:SetOwner(owner)
	control:SetControllerWeapon(self)
	control:Spawn()
	if control:AttachTo(obj, self) then obj:EmitSound(")weapons/physcannon/physcannon_claws_close.wav") end
end

function SWEP:Reload()
	self:ReleaseShadeControl()
end

function SWEP:OnRemove()
	self:ReleaseShadeControl()
end

function SWEP:Holster()
	self:ReleaseShadeControl()
	return true
end

if not CLIENT then return end

function SWEP:PreDrawViewModel(vm)
	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:CallZombieFunction("PreRenderEffects", vm)
	end
end

function SWEP:PostDrawViewModel(vm)
	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:CallZombieFunction("PostRenderEffects", vm)
	end
end
