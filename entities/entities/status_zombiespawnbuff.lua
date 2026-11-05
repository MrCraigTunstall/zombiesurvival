AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "status__base"

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	hook.Add("Move", self, self.Move)
end

function ENT:Move(pl, move)
	if pl ~= self:GetOwner() or pl:Team() ~= TEAM_UNDEAD then return end

	move:SetMaxSpeed(move:GetMaxSpeed() * 1.45)
	move:SetMaxClientSpeed(move:GetMaxSpeed())
end

function ENT:EntityTakeDamage(ent, dmginfo)
	if ent ~= self:GetOwner() or ent:Team() ~= TEAM_UNDEAD then return end

	local attacker = dmginfo:GetAttacker()
	if attacker:IsValid() and attacker:IsPlayer() then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.4)
	end
end

hook.Add("EntityTakeDamage", "ZSZombieSpawnDamage", function(ent, dmginfo)
	local status = ent.status_zombiespawnbuff
	if status and status:IsValid() then
		return status:EntityTakeDamage(ent, dmginfo)
	end
end)

if not CLIENT then return end

function ENT:Think()
	self.BaseClass.Think(self)
	local owner = self:GetOwner()
	local previous = self.ZSSpawnBuffOwner
	if previous ~= owner then
		if previous and previous:IsValid() and previous.status_zombiespawnbuff == self then
			previous.status_zombiespawnbuff = nil
		end
		self.ZSSpawnBuffOwner = owner
	end
	if owner:IsValid() then
		local current = owner.status_zombiespawnbuff
		if not current or not current:IsValid() then
			owner.status_zombiespawnbuff = self
		end
	end
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	local owner = self.ZSSpawnBuffOwner
	if owner and owner:IsValid() and owner.status_zombiespawnbuff == self then
		owner.status_zombiespawnbuff = nil
	end
end

hook.Add("PrePlayerDraw", "ZSZombieSpawnPreDraw", function(pl)
	local status = pl.status_zombiespawnbuff
	if status and status:IsValid() then
		return status:PrePlayerDraw(pl)
	end
end)

hook.Add("PostPlayerDraw", "ZSZombieSpawnPostDraw", function(pl)
	local status = pl.status_zombiespawnbuff
	if status and status:IsValid() then
		return status:PostPlayerDraw(pl)
	end
end)

function ENT:PrePlayerDraw(pl)
	if pl ~= self:GetOwner() or pl:Team() ~= TEAM_UNDEAD then return end

	local r = math.abs(math.sin((CurTime() + self:EntIndex()) * 3)) * 0.6
	render.SetColorModulation(r, 1, r)
end

function ENT:PostPlayerDraw(pl)
	if pl ~= self:GetOwner() or pl:Team() ~= TEAM_UNDEAD then return end

	render.SetColorModulation(1, 1, 1)
end
