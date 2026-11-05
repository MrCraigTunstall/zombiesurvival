include("shared.lua")

function ENT:BindOwner()
	local owner = self:GetOwner()
	if self.BoundOwner == owner then return end
	local previous = self.BoundOwner
	if IsValid(previous) and previous.status_shadeambience == self then previous.status_shadeambience = nil end
	self.BoundOwner = IsValid(owner) and owner or nil
	if self.BoundOwner then owner.status_shadeambience = self end
end

function ENT:Initialize()
	self:DrawShadow(false)
	self.NextEmit = 0
	self.AmbientSound = CreateSound(self, "npc/antlion_guard/growl_idle.wav")
	if self.AmbientSound then self.AmbientSound:PlayEx(0.55, 130) end
	self:BindOwner()
end

function ENT:OnRemove()
	if self.AmbientSound then self.AmbientSound:Stop() end
	if IsValid(self.ParticleEmitter) then self.ParticleEmitter:Finish() end
	self.ParticleEmitter = nil
	local owner = self.BoundOwner
	if IsValid(owner) and owner.status_shadeambience == self then owner.status_shadeambience = nil end
end

function ENT:Think()
	self:BindOwner()
	if self.AmbientSound then self.AmbientSound:PlayEx(self:IsDormant() and 0 or 0.55, 130 + math.sin(RealTime())) end
	self:SetNextClientThink(CurTime() + 0.1)
	return true
end

function ENT:Draw()
	local now = CurTime()
	if self:IsDormant() or now < (self.NextEmit or 0) then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then self.NextEmit = now + 0.1 return end
	local delta = now - self:GetLastDamaged()
	if delta >= 1 or self:GetLastDamage() <= 0 then self.NextEmit = now + 0.1 return end
	local power = (1 - math.max(delta, 0)) * math.min(1, self:GetLastDamage() / 12)
	self.NextEmit = now + 0.02 + (1 - power) * 0.3
	local radius = owner:BoundingRadius() / 2
	local offset = VectorRand()
	offset:Normalize()
	offset:Mul(math.Rand(-radius, radius))
	offset:Add(owner:LocalToWorld(owner:OBBCenter()))
	local emitter = self.ParticleEmitter
	if not IsValid(emitter) then
		emitter = ParticleEmitter(offset)
		if not IsValid(emitter) then return end
		emitter:SetNearClip(24, 32)
		self.ParticleEmitter = emitter
	else emitter:SetPos(offset) end
	local particle = emitter:Add("sprites/glow04_noz", offset)
	if not particle then return end
	particle:SetDieTime(math.Rand(0.2, 0.4))
	particle:SetStartSize(1)
	particle:SetEndSize(power * 16)
	particle:SetStartAlpha(200)
	particle:SetEndAlpha(0)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-5, 5))
	particle:SetColor(255, 255, 190)
end
