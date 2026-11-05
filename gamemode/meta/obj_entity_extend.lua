local meta = FindMetaTable("Entity")
if not meta then return end

local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team
local E_IsValid = meta.IsValid
local vector_origin = vector_origin
local TEAM_HUMAN = TEAM_HUMAN
local TEAM_UNDEAD = TEAM_UNDEAD
local HITGROUP_HEAD = HITGROUP_HEAD

local clipHullFrames = {}
local clipHullDepth = 0
local function TracePlayerClipHull(self, distance, size, start, dir)
 clipHullDepth = clipHullDepth + 1
 local frame = clipHullFrames[clipHullDepth]
 if not frame then
  frame = {bullets = {}, response = {effects = false, damage = false}}
  frame.callback = function(from, tr)
   frame.result = tr
   frame.response.effects, frame.response.damage = false, false
   return frame.response
  end
  clipHullFrames[clipHullDepth] = frame
 end
 local bullets = frame.bullets
 bullets.Damage, bullets.Force, bullets.Tracer = 0, 0, 0
 bullets.Src, bullets.Dir, bullets.HullSize, bullets.Distance = start, dir, size, distance
 bullets.Callback = frame.callback
 frame.result = nil
 local ok, failure = pcall(self.FireBullets, self, bullets)
 local result = frame.result
 frame.result = nil
 for key in pairs(bullets) do bullets[key] = nil end
 clipHullDepth = clipHullDepth - 1
 if not ok then error(failure, 0) end
 if result and result.HitNonWorld and result.Entity:IsValid() and result.Entity:IsPlayer() and distance >= 0 and result.HitPos:DistToSqr(start) <= distance * distance then
  return result
 end
end

local meleeLagDepth = setmetatable({}, {__mode = "k"})
local function CompensatedMelee(self, method, ...)
 local depth = meleeLagDepth[self] or 0
 if depth == 0 then self:LagCompensation(true) end
 meleeLagDepth[self] = depth + 1
 local ok, result = pcall(method, self, ...)
 if depth == 0 then
  meleeLagDepth[self] = nil
  self:LagCompensation(false)
 else
  meleeLagDepth[self] = depth
 end
 if not ok then error(result, 0) end
 return result
end

function meta:ClipHullTraceHull(distance, size, start, dir)
 start = start or self:GetShootPos()
 dir = dir or self:GetAimVector()
 return TracePlayerClipHull(self, distance, size, start, dir) or self:TraceHull(distance, nil, size, nil, start)
end

function meta:ClipHullMeleeTrace(distance, size, filter, start)
 start = start or self:GetShootPos()
 local cliphullpretrace = TracePlayerClipHull(self, distance, size, start, self:GetAimVector())
 if cliphullpretrace then return cliphullpretrace end
 return CompensatedMelee(self, self.MeleeTrace, distance, size, filter, start)
end

function meta:PenetratingClipHullMeleeTrace(distance, size, prehit, start, dir)
 start = start or self:GetShootPos()
 dir = dir or self:GetAimVector()
 local cliphullpretrace = TracePlayerClipHull(self, distance, size, start, dir)
 local result = CompensatedMelee(self, self.PenetratingMeleeTrace, distance, size, prehit, start, dir)
 if cliphullpretrace and cliphullpretrace.Entity ~= prehit and not (result[1] and result[1].Entity:IsValid() and result[1].Entity == cliphullpretrace.Entity) then
  table.insert(result, 1, cliphullpretrace)
 end
 return result
end

function meta:ApplyPlayerProperties(ply)
	if not IsValid(self) or not IsValid(ply) or self == ply then return end
	local getcolor = ply.GetPlayerColor
	if type(getcolor) ~= "function" then return end
	local color = getcolor(ply)
	if not IsValid(self) or not IsValid(ply) then return end
	local owner = ply
	self.GetPlayerColor = function()
		if owner then
			if E_IsValid(owner) then color = getcolor(owner) else owner, getcolor = nil, nil end
		end
		return color
	end
	local groups = math.min(self:GetNumBodyGroups(), ply:GetNumBodyGroups())
	for index = 0, groups - 1 do
		local maximum = self:GetBodygroupCount(index) - 1
		if maximum > 0 then self:SetBodygroup(index, math.max(0, math.min(ply:GetBodygroup(index), maximum))) end
	end
	self:SetMaterial(ply:GetMaterial())
	self:SetSkin(math.max(0, math.min(ply:GetSkin() or 0, self:SkinCount() - 1)))
end

function meta:GetVolume()
	local mins, maxs = self:OBBMins(), self:OBBMaxs()
	return (maxs.x - mins.x) + (maxs.y - mins.y) + (maxs.z - mins.z)
end

local function DamageSources(self, attacker, inflictor)
	if not (attacker and (E_IsValid(attacker) or attacker:IsWorld())) then attacker = self end
	if not (inflictor and (E_IsValid(inflictor) or inflictor:IsWorld())) then inflictor = attacker end
	return attacker, inflictor
end

function meta:TakeSpecialDamage(damage, damagetype, attacker, inflictor, hitpos, damageforce)
	if not E_IsValid(self) then return end
	attacker, inflictor = DamageSources(self, attacker, inflictor)

	local nearest = hitpos or self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter())))

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	dmginfo:SetDamagePosition(hitpos or nearest)
	dmginfo:SetDamageType(damagetype)
	if damageforce then
		dmginfo:SetDamageForce(damageforce)
	end
	self:TakeDamageInfo(dmginfo)

	return dmginfo
end

function meta:IsProjectile()
	return IsValid(self) and self:GetCollisionGroup() == COLLISION_GROUP_PROJECTILE or self.AlwaysProjectile
end

function meta:SetupGenericProjectile(gravity)
	if not E_IsValid(self) then return end
	self:SetCustomCollisionCheck(true)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(1)
		phys:SetBuoyancyRatio(0.0001)
		phys:EnableMotion(true)
		phys:EnableGravity(gravity and true or false)
		phys:EnableDrag(false)
		phys:Wake()
	end
end

function meta:ProjectileDamageSource()
	return (self.ProjSource and E_IsValid(self.ProjSource)) and self.ProjSource or self
end

function meta:ResetBones(onlyscale)
	if not E_IsValid(self) then return end
	local count = self:GetBoneCount() or 0
	if count <= 0 then return end
	local v = Vector(1, 1, 1)
	if onlyscale then
		for i=0, count - 1 do
			self:ManipulateBoneScale(i, v)
		end
	else
		local a = Angle(0, 0, 0)
		for i=0, count - 1 do
			self:ManipulateBoneScale(i, v)
			self:ManipulateBoneAngles(i, a)
			self:ManipulateBonePosition(i, vector_origin)
		end
	end
end

function meta:SetBarricadeHealth(m)
	self:SetDTFloat(1, m)
end

function meta:GetBarricadeHealth()
	return self:GetDTFloat(1)
end

function meta:SetMaxBarricadeHealth(m)
	self:SetDTFloat(2, m)
end

function meta:GetMaxBarricadeHealth()
	return self:GetDTFloat(2)
end

function meta:SetBarricadeRepairs(m)
	self:SetDTFloat(3, m)
end

function meta:GetBarricadeRepairs()
	return self:GetDTFloat(3)
end

function meta:GetMaxBarricadeRepairs()
	return self:GetMaxBarricadeHealth() * 1.5
end

function meta:GetBonePositionMatrixed(index)
	local matrix = self:GetBoneMatrix(index)
	if matrix then
		return matrix:GetTranslation(), matrix:GetAngles()
	end

	return self:GetPos(), self:GetAngles()
end

local GetBonePositionMatrixed = meta.GetBonePositionMatrixed
function meta:NearestBone(pos)
	if not E_IsValid(self) then return end
	local count = self:GetBoneCount() or 0
	if count <= 0 then return end
	local getposition = self.GetBonePositionMatrixed
	local standard = getposition == GetBonePositionMatrixed
	local nearest, nearestdist
	for boneid = 0, count - 1 do
		local bonepos
		if standard then
			local matrix = self:GetBoneMatrix(boneid)
			bonepos = matrix and matrix:GetTranslation() or self:GetPos()
		else
			bonepos = getposition(self, boneid)
		end
		local distance = bonepos:DistToSqr(pos)
		if not nearest or distance < nearestdist then nearest, nearestdist = boneid, distance end
	end
	return nearest
end

ZSNativeEntityCollisionRulesChanged = ZSNativeEntityCollisionRulesChanged or meta.CollisionRulesChanged
meta.CollisionRulesChanged = ZSNativeEntityCollisionRulesChanged

function meta:GetIsNailed()
	return self:GetNWBool("IsNailed", false)
end

function meta:IsNailed()
	return self:GetIsNailed()
end

function meta:GetAlpha()
	return self:GetColor().a
end

function meta:SetAlpha(a)
	local col = self:GetColor()
	col.a = a
	self:SetColor(col)
end

function meta:TemporaryBarricadeObject()
 if self.IsBarricadeObject then return end
 if SERVER and GAMEMODE:HasTemporaryCollisionOverlap(self, true) then
  GAMEMODE:SetTemporaryBarricadeGhostEligibility(self, true)
  GAMEMODE:TrackTemporaryCollision(self, true)
 end
end

function meta:IsBarricadeProp()
 return GAMEMODE:IsEntityBarricadeGhostEligible(self)
end

function meta:GetHolder()
	if not IsValid(self) or self.IsMarkedForDeletion and self:IsMarkedForDeletion() then return end
	local cached = self.ZSHoldingStatus
	if IsValid(cached) and not cached.Removing and not (cached.IsMarkedForDeletion and cached:IsMarkedForDeletion()) and cached:GetObject() == self and (not cached.HeldObject or cached.HeldObject == self) then
		local owner = cached:GetOwner()
		if IsValid(owner) and owner:IsPlayer() and owner:Alive() and (not cached.HeldOwner or cached.HeldOwner == owner) then return owner, cached end
	end
	self.ZSHoldingStatus = nil
	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("status_human_holding")) do
		if IsValid(ent) and not ent.Removing and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion()) and ent:GetObject() == self and (not ent.HeldObject or ent.HeldObject == self) then
			local owner = ent:GetOwner()
			if IsValid(owner) and owner:IsPlayer() and owner:Alive() and (not ent.HeldOwner or ent.HeldOwner == owner) then self.ZSHoldingStatus = ent; return owner, ent end
		end
	end
end

function meta:ThrowFromPosition(pos, force, noknockdown)
	if force == 0 or self:IsProjectile() or self.NoThrowFromPosition then return false end

	local isplayer = self:IsPlayer()
	if isplayer and self:ActiveBarricadeGhosting() then return false end
	local movetype = self:GetMoveType()

	if movetype == MOVETYPE_VPHYSICS then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() and phys:IsMoveable() then
			local nearest = self:NearestPoint(pos)
			local dir = nearest - pos
			dir:Normalize()
			dir:Mul(force * 50)
			phys:ApplyForceOffset(dir, nearest)
		end

		return true
	elseif movetype >= MOVETYPE_WALK and movetype < MOVETYPE_PUSH then
		self:SetGroundEntity(NULL)
		if SERVER and not noknockdown and isplayer then
			local absforce = math.abs(force)
			if absforce >= 512 or self.Clumsy and self:Team() ~= TEAM_UNDEAD and absforce >= 32 then
				self:KnockDown()
			end
		end
		local dir = self:LocalToWorld(self:OBBCenter()) - pos
		dir:Normalize()
		dir:Mul(force)
		self:SetVelocity(dir)

		return true
	end
end

function meta:ThrowFromPositionSetZ(pos, force, zmul, noknockdown)
	if force == 0 or self:IsProjectile() or self.NoThrowFromPosition then return false end
	zmul = zmul or 0.7

	local isplayer = self:IsPlayer()
	if isplayer and self:ActiveBarricadeGhosting() then return false end
	local movetype = self:GetMoveType()

	if movetype == MOVETYPE_VPHYSICS then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() and phys:IsMoveable() then
			local nearest = self:NearestPoint(pos)
			local dir = nearest - pos
			dir.z = 0
			dir:Normalize()
			dir.z = zmul
			dir:Mul(force * 50)
			phys:ApplyForceOffset(dir, nearest)
		end

		return true
	elseif movetype >= MOVETYPE_WALK and movetype < MOVETYPE_PUSH then
		self:SetGroundEntity(NULL)
		if SERVER and not noknockdown and isplayer then
			local absforce = math.max(math.abs(force) * math.abs(zmul), math.abs(force))
			if absforce >= 512 or self.Clumsy and self:Team() ~= TEAM_UNDEAD and absforce >= 32 then
				self:KnockDown()
			end
		end

		local dir = self:LocalToWorld(self:OBBCenter()) - pos
		dir.z = 0
		dir:Normalize()
		dir.z = zmul
		dir:Mul(force)
		self:SetVelocity(dir)

		return true
	end
end

util.PrecacheSound("player/pl_pain5.wav")
util.PrecacheSound("player/pl_pain6.wav")
util.PrecacheSound("player/pl_pain7.wav")
function meta:PoisonDamage(damage, attacker, inflictor, hitpos, noreduction)
	if not E_IsValid(self) then return end
	damage = damage or 1

	local isplayer = self:IsPlayer()
	if isplayer and (self:Team() ~= TEAM_HUMAN or GAMEMODE:HasPlayerTrait(self, "venomimmunity")) then return end
	local dmginfo = DamageInfo()

	if isplayer then

		if self.BuffResistant then
			damage = damage / 2
		end
		
		if self.Allergic then
			damage = damage * 2
		end

		self:ViewPunch(Angle(math.random(-10, 10), math.random(-10, 10), math.random(-20, 20)))
		self:EmitSound("player/pl_pain"..math.random(5, 7)..".wav")
		if not E_IsValid(self) then return end

		if SERVER then
			local recovery = self:GiveStatus("poisonrecovery")
			if IsValid(recovery) then recovery:AddDamage(math.floor(damage * 0.75)) end
		end

		dmginfo:SetDamageType(DMG_ACID)
	else
		if not noreduction then
			damage = damage / 3
		end
		dmginfo:SetDamageType(DMG_SLASH) -- Fixes not doing damage to props.
	end

	if not E_IsValid(self) then return end
	attacker, inflictor = DamageSources(self, attacker, inflictor)

	dmginfo:SetDamagePosition(hitpos or self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter()))))
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	self:TakeDamageInfo(dmginfo)
end

if CLIENT then
	function meta:SetModelScaleVector(vec)
		local bonecount = self:GetBoneCount()
		if bonecount and bonecount > 1 then
			local scale
			if type(vec) == "number" then
				scale = vec
			else
				scale = math.min(vec.x, vec.y, vec.z)
			end
			self._ModelScale = Vector(scale, scale, scale)
			self:SetModelScale(scale, 0)
		else
			if type(vec) == "number" then
				vec = Vector(vec, vec, vec)
			end

			self._ModelScale = vec
			local m = Matrix()
			m:Scale(vec)
			self:EnableMatrix("RenderMultiply", m)
		end
	end

	if not meta.TakeDamageInfo then
		meta.TakeDamageInfo = function() end
	end
	if not meta.SetPhysicsAttacker then
		meta.SetPhysicsAttacker = function() end
	end
end

local string_sub = string.sub
function meta:IsAPhysicsProp()
	if not IsValid(self) then return false end
	
	if not self.CheckedIsPhysProp then
		local class = string_sub(self:GetClass(), 1, 12)
		self.CheckedIsPhysProp = (class == "prop_physics" or class == "func_physbox") and 1 or 0
	end
	return self.CheckedIsPhysProp==1
end

meta.ZSOriginalSequenceDuration = meta.ZSOriginalSequenceDuration or meta.SequenceDuration
local OldSequenceDuration = meta.ZSOriginalSequenceDuration
function meta:SequenceDuration(seqid)
	return OldSequenceDuration(self, seqid) or 0
end

function meta:IsValidPlayer()
	return self:IsValid() and self:IsPlayer()
end

function meta:IsValidHuman()
	return E_IsValid(self) and self:IsPlayer() and P_Team(self) == TEAM_HUMAN
end

function meta:IsValidZombie()
	return E_IsValid(self) and self:IsPlayer() and P_Team(self) == TEAM_UNDEAD
end

function meta:IsHuman()
	return self:IsPlayer() and P_Team(self) == TEAM_HUMAN
end

function meta:IsZombie()
	return self:IsPlayer() and P_Team(self) == TEAM_UNDEAD
end

function meta:IsValidLivingPlayer()
	return self:IsValidPlayer() and self:Alive()
end

function meta:IsValidLivingHuman()
	return self:IsValidHuman() and self:Alive()
end

function meta:IsValidLivingZombie()
	return self:IsValidZombie() and self:Alive()
end


function meta:SetLastHitGroup(group)

	self.m_LastHitGroup = group

end

function meta:LastHitGroup()
	return self.m_LastHitGroup or HITGROUP_CHEST
end
