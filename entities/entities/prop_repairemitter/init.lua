AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local repairPhase = 0

function ENT:Initialize()
	self:SetModel("models/props_lab/reciever01b.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
	self:SetObjectHealth(self:GetMaxObjectHealth())
	self.RepairCursor = 0
	self.RepairTrace = {mask = MASK_SOLID_BRUSHONLY}
	repairPhase = (repairPhase + 1) % 16
	self:NextThink(CurTime() + self.RepairInterval * (repairPhase + 1) / 16)
end

function ENT:RepairNearby(now)
	return GAMEMODE:RepairBarricadesInField(self, self:GetObjectOwner(), nil, now)
end

function ENT:Think()
	if self:GetObjectHealth() <= 0 then self:Remove() return end
	local owner = self:GetObjectOwner()
	if IsValid(owner) and owner:IsPlayer() and owner:Team() ~= TEAM_HUMAN then self:SetObjectOwner(NULL) end
	self:RepairNearby(CurTime())
	self:NextThink(CurTime() + self.RepairInterval)
	return true
end

function ENT:OnTakeDamage(info)
	local attacker = info:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN then return end
	self:TakePhysicsDamage(info)
	if IsValid(attacker) and attacker.LifeBarricadeDamage ~= nil and self:HumanNearby() then attacker:AddLifeBarricadeDamage(info:GetDamage()) end
	GAMEMODE:DamageTraitObject(self, info)
	if self:GetObjectHealth() <= 0 then self:Remove() end
end

function ENT:AltUse(activator)
	if IsValid(activator) and activator:IsPlayer() and activator:Team() == TEAM_HUMAN then self:PackUp(activator) end
end

function ENT:OnPackedUp(pl)
	if self:GetObjectHealth() <= 0 then return true end
	pl:GiveEmptyWeapon("weapon_zs_repairemitter")
	pl:GiveAmmo(1, "repairemitter")
	pl:PushPackedItem(self:GetClass(), self:GetObjectHealth())
	self:Remove()
end
