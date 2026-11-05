AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:Initialize()
	self.Touched = {}
	self.OriginalAngles = self:GetAngles()
	
	self:Fire("kill", "", 15)
	
	self:SetModel("models/Items/CrossbowRounds.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetTrigger(true)
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(4)
		phys:SetBuoyancyRatio(0.01)
		phys:EnableDrag(false)
		phys:Wake()
	end
	
	self:EmitSound("weapons/crossbow/bolt_fly4.wav")
end

function ENT:FinishImpact(pos, normal, hitent)
	if not self:IsValid() then return end
	self:Fire("kill", "", 8)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:EnableMotion(false) end
	self:EmitSound("physics/metal/sawblade_stick" .. math.random(3) .. ".wav")
	self:SetPos(pos)
	self:SetAngles(normal:Angle())
	if IsValid(hitent) then
		local hitphys = hitent:GetPhysicsObject()
		if hitphys:IsValid() and hitphys:IsMoveable() then self:SetParent(hitent) end
	end
end

function ENT:PhysicsCollide(data, physobj)
	if self.Done then return end
	self.Done = true
	local pos, normal, hitent = Vector(data.HitPos), Vector(data.HitNormal), data.HitEntity
	timer.Simple(0, function() if IsValid(self) then self:FinishImpact(pos, normal, hitent) end end)
end

function ENT:StartTouch(ent)
	if self.Done or self.Touched[ent] or not ent:IsValid() then return end

	local owner = self:GetOwner()
	if not owner:IsValid() then owner = self end

	if ent == owner or ent:IsPlayer() and (ent:Team() == self.Team or not ent:Alive()) then return end

	self.Touched[ent] = true

	ent:TakeDamage(self.ProjDamage or 100, owner, self)
	ent:EmitSound("weapons/crossbow/hitbod"..math.random(2)..".wav")
end
