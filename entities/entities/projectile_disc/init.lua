INC_SERVER()

function ENT:Initialize()
	self:SetModelScale(0.3, 0)
	self:DrawShadow(false)
	self:SetModel("models/props_junk/sawblade001a.mdl")
	self:PhysicsInitSphere(3)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetupGenericProjectile(false)

	self:Fire("kill", "", 0.3)

	self.NextShoot = 0
	self.PostOwner = self:GetOwner()
end

function ENT:Think()
	if self.PhysicsData then
		self:Explode(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	end
end

function ENT:PhysicsCollide(data, physobj)
	self.PhysicsData = data
	self:NextThink(CurTime())
end

function ENT:OnRemove()
	local hitpos = self.PhysicsData and self.PhysicsData.HitPos or self:GetPos()
	local normal = self.PhysicsData and self.PhysicsData.HitNormal or Vector(0, 0, 1)

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(normal)
	util.Effect("explosion_fusordisc", effectdata)

	local owner = self.PostOwner
	local source = self.ProjSource
	local crafter, position = self.ZSCrafter, self:GetPos()
	local proxy

	local oldvel = self.PhysicsData and self.PhysicsData.OurOldVelocity or self:GetVelocity()

	local backvel = oldvel:GetNormalized()
	local pos = self:GetPos() - backvel * 10
	local dmg = self.ProjDamage or 0
	ZSDiscBurstSerial = (ZSDiscBurstSerial or 0) + 1
	local name, shot = "ZSDiscBurst" .. ZSDiscBurstSerial, 0
	timer.Create(name, 0.05, 8, function()
		if proxy and not IsValid(proxy) then timer.Remove(name); return end
		shot = shot + 1
		backvel.z = backvel.z + 0.001 * shot
		backvel = backvel:GetNormalized()
		local attacker = IsValid(owner) and owner:IsValidLivingHuman() and owner or game.GetWorld()
		local shooter = IsValid(source) and source:GetOwner() == attacker and source or nil
		if not shooter then
			if not proxy then
				proxy = ents.Create("info_target")
				if not IsValid(proxy) then timer.Remove(name); return end
				proxy:SetPos(position); proxy:Spawn(); proxy.ZSCrafter = crafter
				if IsValid(owner) then proxy:SetOwner(owner) end
			end
			shooter = proxy
		end
		shooter:FireBulletsLua(pos, -backvel, 1, 1, dmg / 2, attacker, 0.01, "tracer_fusor", BulletCallback, nil, nil, nil, nil, shooter)
		if shot == 8 and IsValid(proxy) then proxy:Remove() end
	end)
end

function ENT:Explode(hitpos, normal, hitent)
	if self.Exploded then return end
	self.Exploded = true

	self:Remove()
end
