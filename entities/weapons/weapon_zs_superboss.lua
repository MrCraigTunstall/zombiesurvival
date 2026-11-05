AddCSLuaFile()
SWEP.Base = "weapon_zs_zombie"
SWEP.PrintName = "Super Boss Claws"
SWEP.Spawnable = false
SWEP.LeapCooldown = 4
SWEP.SpitCooldown = 5
SWEP.SpitCount = 1

function SWEP:CanUseBossAbility()
	local pl = self:GetOwner()
	local class = IsValid(pl) and pl:GetZombieClassTable()
	return class and class.SuperBoss and pl:Alive() and pl:Team() == TEAM_UNDEAD and pl:GetActiveWeapon() == self and not pl:IsFrozen()
end

function SWEP:BossLeap()
	if not self:CanUseBossAbility() or CurTime() < self:GetNextSecondaryFire() then return false end
	local pl = self:GetOwner()
	if not pl:OnGround() then return false end
	self:SetNextSecondaryFire(CurTime() + self.LeapCooldown)
	if SERVER then
		local direction = pl:GetAimVector(); direction.z = 0; direction:Normalize()
		pl:SetVelocity(direction * 500 + Vector(0, 0, 260) - pl:GetVelocity())
		pl:EmitSound("npc/fast_zombie/leap1.wav", 75)
	end
	return true
end

function SWEP:BossSpit()
	if not self:CanUseBossAbility() or CurTime() < (self.ZSNextBossSpit or 0) then return false end
	self.ZSNextBossSpit = CurTime() + self.SpitCooldown
	if SERVER then
		local pl = self:GetOwner()
		local aim, position = pl:GetAimVector(), pl:GetShootPos()
		local trace = util.TraceLine({start = position, endpos = position + aim * 20, filter = pl, mask = MASK_SOLID})
		if trace.StartSolid or trace.AllSolid then return false end
		local spawn = trace.Hit and trace.HitPos - aim * 2 or position + aim * 20
		for index = 1, math.min(self.SpitCount, 3) do
			local projectile = ents.Create("projectile_poisonpuke")
			if IsValid(projectile) then
				projectile:SetPos(spawn); projectile:SetOwner(pl); projectile.Damage = 10; projectile:Spawn()
				local phys = projectile:GetPhysicsObject()
				if IsValid(phys) then phys:SetVelocityInstantaneous(aim * 650 + Vector(0, 0, 20 * index)) else projectile:Remove() end
			end
		end
		pl:EmitSound("npc/barnacle/barnacle_digesting1.wav", 75)
	end
	return true
end

function SWEP:SecondaryAttack() return self:BossLeap() end
function SWEP:Reload() return self:BossSpit() end
