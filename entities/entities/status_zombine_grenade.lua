AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "status__base"

ENT.LifeTime = 4
ENT.NextTickSound = 0
ENT.GrenadeDamage = 45
ENT.GrenadeRadius = 256

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.DieTime = CurTime() + self.LifeTime
end

if SERVER then

local effectCells, effectStart, effectUntil = {}, 0, 0
local effectTrace = {mask = MASK_SOLID_BRUSHONLY}
local function BlastEffect(pos)
	local now = CurTime()
	if now >= effectUntil or now < effectStart then effectCells, effectStart, effectUntil = {}, now, now + 0.05 end
	local key = math.floor(pos.x / 128) .. ":" .. math.floor(pos.y / 128) .. ":" .. math.floor(pos.z / 128)
	local previous = effectCells[key]
	if previous then
		effectTrace.start, effectTrace.endpos = previous, pos
		if not util.TraceLine(effectTrace).Hit then return end
	end
	effectCells[key] = pos
	local data = EffectData()
	data:SetOrigin(pos)
	util.Effect("zombineblast", data)
end

local function LiveUndead(owner)
	return IsValid(owner) and not owner:IsMarkedForDeletion() and owner:IsPlayer() and owner:Alive() and owner:Team() == TEAM_UNDEAD
end

function ENT:Think()
	if self.Exploded then self:Remove() return end
	local owner = self:GetOwner()
	if not LiveUndead(owner) then self:Remove() return end
	if self.DieTime <= CurTime() then
		self:Explode()
		if IsValid(self) and not self:IsMarkedForDeletion() and self:GetOwner() == owner and LiveUndead(owner) then owner:Kill() end
	end
end

function ENT:Explode()
	if self.Exploded or not IsValid(self) or self:IsMarkedForDeletion() then return end
	self.Exploded = true
	local owner = self:GetOwner()
	if not LiveUndead(owner) then return end
	local pos = self:GetPos()
	util.PoisonBlastDamage(self, owner, pos, self.GrenadeRadius, self.GrenadeDamage, true)
	BlastEffect(pos)
end

end

if not CLIENT then return end

function ENT:Think()
	
	local curtime = CurTime()

	if curtime >= self.NextTickSound then
		local delta = self.DieTime - curtime

		self.NextTickSound = curtime + math.max(0.2, delta * 0.25)
		self:EmitSound("weapons/grenade/tick1.wav", 75, math.Clamp((1 - delta / self.LifeTime) * 160, 100, 160))
	end
	

end
