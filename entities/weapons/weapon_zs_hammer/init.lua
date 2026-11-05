INC_SERVER()

local function PryLive(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end

local function PryBound(action)
	local weapon, owner = action.weapon, action.owner
	return PryLive(weapon) and PryLive(owner) and owner:IsPlayer() and owner:Alive() and owner:Team() == TEAM_HUMAN
		and not owner:GetBarricadeGhosting() and weapon:GetOwner() == owner and owner:GetActiveWeapon() == weapon
		and weapon.ZSNailPryAction == action and owner.ZSNailPryAction == action
end

local function NearestPryNail(base, position, action)
	local found, distance
	for _, nail in pairs(base.Nails or {}) do
		if PryLive(nail) and not nail.m_PryingOut and not nail.m_IsRemoving
			and (not nail.ZSNailPryAction or nail.ZSNailPryAction == action)
			and nail:GetParent() == base and nail:GetBaseEntity() == base then
			local current = nail:GetActualPos():DistToSqr(position)
			if not distance or current < distance then found, distance = nail, current end
		end
	end
	return found
end

local function PryReady(action)
	return PryBound(action) and CurTime() >= action.weapon:GetNextPrimaryFire() and PryLive(action.base)
		and action.base:IsNailed() and PryLive(action.nail) and action.nail.ZSNailPryAction == action
		and action.nail:GetOwner() == action.nailowner and NearestPryNail(action.base, action.position, action) == action.nail
end

local function OtherNailOwner(action)
	local owner = action.nailowner
	return IsValid(owner) and owner:IsPlayer() and owner ~= action.owner and owner:Team() == TEAM_HUMAN
end

local function PryRefundRecipient(action)
	local owner = action.nailowner
	if OtherNailOwner(action) and owner:NearestPoint(action.position):DistToSqr(action.position) <= 589824
		and (owner:HasWeapon("weapon_zs_hammer") or owner:HasWeapon("weapon_zs_electrohammer")) then return owner end
	return action.owner
end

local function PryPenaltyDeath(action)
	return PryLive(action.owner) and not action.owner:Alive() and action.owner.ZSNailPryAction == action
		and (not IsValid(action.weapon) or action.weapon:GetOwner() == action.owner)
end

local function PerformNailPry(action)
	local weapon, owner = action.weapon, action.owner
	local tr = owner:MeleeTrace(weapon.MeleeRange, weapon.MeleeSize, owner:GetMeleeFilter())
	if not PryBound(action) or not tr or not tr.HitPos or not PryLive(tr.Entity) or not tr.Entity:IsNailed() then return end
	action.base = tr.Entity
	action.position = Vector(tr.HitPos.x, tr.HitPos.y, tr.HitPos.z)
	local nail = NearestPryNail(action.base, action.position, action)
	if not nail then return end
	action.nail, action.nailowner = nail, nail:GetOwner()
	nail.ZSNailPryAction = action
	if not gamemode.Call("CanRemoveNail", owner, nail) or not PryReady(action) then return end
	if OtherNailOwner(action) then
		local admin = gamemode.Call("PlayerIsAdmin", owner)
		if not PryReady(action) then return end
		if not admin then
			local allowed = gamemode.Call("CanRemoveOthersNail", owner, action.nailowner, nail)
			if not allowed or not PryReady(action) then return end
		end
	end
	if not PryReady(action) then return end
	local delay = #action.base.Nails > 2 and 0.5 or 1
	action.previousPrying = nail.m_PryingOut
	nail.m_PryingOut = true
	action.prying = true
	if action.base:RemoveNail(nail, nil, owner) ~= true then return end
	action.committed = true
	if not PryBound(action) then return end
	weapon:SetNextPrimaryFire(math.max(weapon:GetNextPrimaryFire(), CurTime() + delay))
	weapon:SendWeaponAnim(weapon.Alternate and ACT_VM_HITCENTER or ACT_VM_MISSCENTER)
	if not PryBound(action) then return end
	weapon.Alternate = not weapon.Alternate
	owner:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)
	if not PryBound(action) then return end
	owner:EmitSound("weapons/melee/crowbar/crowbar_hit-"..math.random(4)..".ogg")
	if not PryBound(action) then return end
	owner:ClearNailRemovalWarning()
	if not PryBound(action) then return end
	if PryLive(action.base) then action.base:SetPhysicsAttacker(owner) end
	if not PryBound(action) then return end
	local penalty = false
	if OtherNailOwner(action) and PryLive(action.base) and IsValid(nail) then
		penalty = gamemode.Call("PlayerShouldTakeNailRemovalPenalty", owner, nail, action.nailowner, action.base)
		if not PryBound(action) then return end
	end
	local recipient = PryRefundRecipient(action)
	if not PryBound(action) then return end
	if penalty then
		owner:GivePenalty(30)
		if not PryBound(action) then return end
		owner:ReflectDamage(20)
		if not PryBound(action) and not PryPenaltyDeath(action) then return end
	end
	if IsValid(recipient) and recipient:IsPlayer() and (recipient == owner or recipient:Team() == TEAM_HUMAN) then recipient:GiveAmmo(1, action.ammo) end
end

local function ReleaseNailPry(action)
	local weapon, owner, nail = action.weapon, action.owner, action.nail
	if IsValid(weapon) and weapon.ZSNailPryAction == action then weapon.ZSNailPryAction = nil end
	if IsValid(owner) and owner.ZSNailPryAction == action then owner.ZSNailPryAction = nil end
	if IsValid(nail) and nail.ZSNailPryAction == action then
		nail.ZSNailPryAction = nil
		if action.prying and not action.committed and nail.m_PryingOut == true then nail.m_PryingOut = action.previousPrying end
	end
end

function SWEP:Reload()
	if not PryLive(self) or CurTime() < self:GetNextPrimaryFire() or self.ZSNailPryAction or self.ZSNailPlaceAction then return end
	local owner = self:GetOwner()
	if not PryLive(owner) or not owner:IsPlayer() or not owner:Alive() or owner:Team() ~= TEAM_HUMAN
		or owner:GetBarricadeGhosting() or owner:GetActiveWeapon() ~= self or owner.ZSNailPryAction or owner.ZSNailPlaceAction then return end
	local action = {weapon = self, owner = owner, ammo = self.Primary.Ammo}
	self.ZSNailPryAction, owner.ZSNailPryAction = action, action
	local ok, failure = pcall(PerformNailPry, action)
	ReleaseNailPry(action)
	if not ok then error(failure, 0) end
end

function SWEP:OnMeleeHit(hitent, hitflesh, tr)
	if hitent:IsValid() then
		if hitent.HitByHammer and hitent:HitByHammer(self, self.Owner, tr) then
			return
		end

		if hitent:IsNailed() then
			local healstrength = GAMEMODE.NailHealthPerRepair * (self.Owner.HumanRepairMultiplier or 1) * self.HealStrength
			local oldhealth = hitent:GetBarricadeHealth()
			if oldhealth <= 0 or oldhealth >= hitent:GetMaxBarricadeHealth() or hitent:GetBarricadeRepairs() <= 0 then return end

			hitent:SetBarricadeHealth(math.min(hitent:GetMaxBarricadeHealth(), hitent:GetBarricadeHealth() + math.min(hitent:GetBarricadeRepairs(), healstrength)))
			local healed = hitent:GetBarricadeHealth() - oldhealth
			hitent:SetBarricadeRepairs(math.max(hitent:GetBarricadeRepairs() - healed, 0))
			self:PlayRepairSound(hitent)
			gamemode.Call("PlayerRepairedObject", self.Owner, hitent, healed, self)

			local effectdata = EffectData()
				effectdata:SetOrigin(tr.HitPos)
				effectdata:SetNormal(tr.HitNormal)
				effectdata:SetMagnitude(1)
			util.Effect("nailrepaired", effectdata, true, true)

			return true
		end
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	local owner = self.Owner
	
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay * (owner.Carpenter and 0.5 or 1))

	if self.SwingTime == 0 then
		self:MeleeSwing()
	else
		self:StartSwinging()
	end
end


local function PlacementNailCount(prop, ignored)
 local count = 0
 for _, nail in pairs(prop.Nails or {}) do
  if nail ~= ignored and PryLive(nail) and not nail.m_IsRemoving
   and (nail:GetBaseEntity() == prop or nail:GetAttachEntity() == prop) then count = count + 1 end
 end
 return count
end

local function PlacementPhysics(prop, bone, ignored, skipDamage)
 if not PryLive(prop) or not util.IsValidPhysicsObject(prop, bone) or prop.NoNails or prop:IsProjectile()
  or prop:GetMoveType() ~= MOVETYPE_VPHYSICS and not prop:GetNailFrozen()
  or prop:GetMaxHealth() == 1 and prop:Health() == 0 and not prop.TotalHealth then return end
 local physics = prop:GetPhysicsObjectNum(bone)
 if not IsValid(physics) or not prop:IsNailed() and not physics:IsMoveable() then return end
 local count = PlacementNailCount(prop, ignored)
 if count >= 8 or count > 0 and prop:GetPropsInContraption() >= GAMEMODE.MaxPropsInBarricade then return end
 if not skipDamage and prop:GetBarricadeHealth() <= 0 and prop:GetMaxBarricadeHealth() > 0 then return nil, "object_too_damaged_to_be_used" end
 return physics
end

local function PlacementBound(action)
 local weapon, owner = action.weapon, action.owner
 return PryLive(weapon) and PryLive(owner) and owner:IsPlayer() and owner:Alive() and owner:Team() == TEAM_HUMAN
  and not owner:GetBarricadeGhosting() and weapon:GetOwner() == owner and owner:GetActiveWeapon() == weapon
  and weapon.ZSNailPlaceAction == action and owner.ZSNailPlaceAction == action
  and weapon:GetPrimaryAmmoCount() > 0 and weapon:GetNextPrimaryFire() <= action.deadline
end

local function PlacementEndpointLive(entity, world)
 if world then return entity == game.GetWorld() and not entity:IsMarkedForDeletion() end
 return PryLive(entity)
end

local function PlacementReady(action)
 action.denialReason = nil
 if not PlacementBound(action) then return false end
 local tr, position, front = action.trace, action.position, action.front
 if tr.Entity ~= front or tr.PhysicsBone ~= action.frontBone or tr.Fraction ~= action.fraction or tr.MatType ~= action.material
  or not tr.HitPos or tr.HitPos.x ~= position.x or tr.HitPos.y ~= position.y or tr.HitPos.z ~= position.z then return false end
 local physics, reason = PlacementPhysics(front, action.frontBone, action.nail)
 if physics ~= action.frontPhysics then action.denialReason = reason return false end
 if front.PreHoldCollisionGroup and (front.PreHoldCollisionGroup == COLLISION_GROUP_DEBRIS
  or front.PreHoldCollisionGroup == COLLISION_GROUP_DEBRIS_TRIGGER or front.PreHoldCollisionGroup == COLLISION_GROUP_INTERACTIVE_DEBRIS) then return false end
 local count = 0
 for _, nail in pairs(front.Nails or {}) do
  if nail ~= action.nail and PryLive(nail) and not nail.m_IsRemoving then
   if nail:GetDeployer() == action.owner then count = count + 1 if count >= GAMEMODE.MaxNails then return false end end
   if nail:GetParent() == front and nail:GetActualPos():DistToSqr(position) <= 81 then return false end
  end
 end
 if action.back then
  if not PlacementEndpointLive(action.back, action.world) then return false end
  if action.world then
   if not action.back:IsWorld() or action.back.NoNails then return false end
  else
   physics, reason = PlacementPhysics(action.back, action.backBone, action.nail)
   if not action.backPhysics or physics ~= action.backPhysics then action.denialReason = reason return false end
  end
 end
 return true
end

local function PlacementDenied(action, reason)
 local owner = action.owner
 if PryLive(owner) and owner:IsPlayer() then owner:NotifyNailDenied(reason or action.denialReason or "nail_cannot_place") end
end

local function PlacementMaterial(action, material)
 if material == MAT_GRATE or material == MAT_CLIP then PlacementDenied(action, "impossible")return false end
 if material == MAT_GLASS then PlacementDenied(action, "trying_to_put_nails_in_glass")return false end
 return true
end

local function PerformNailPlacement(action)
 local weapon, owner = action.weapon, action.owner
 if GAMEMODE:IsClassicMode() then return PlacementDenied(action, "cant_do_that_in_classic_mode") end
 local tr = owner:TraceLine(64, MASK_SOLID, owner:GetMeleeFilter())
 if not PlacementBound(action) or not tr or not tr.HitPos or tr.Fraction == 0 or not PryLive(tr.Entity) then return PlacementDenied(action) end
 action.trace, action.front, action.frontBone = tr, tr.Entity, tr.PhysicsBone
 action.position = Vector(tr.HitPos.x, tr.HitPos.y, tr.HitPos.z)
 action.fraction, action.material = tr.Fraction, tr.MatType
 action.frontPhysics = PlacementPhysics(action.front, action.frontBone, nil, true)
 if not action.frontPhysics then return PlacementDenied(action) end
 local allowed = gamemode.Call("CanPlaceNail", owner, tr)
 if not allowed or not PlacementReady(action) then return PlacementDenied(action) end
 if not PlacementMaterial(action, action.material) then return end
 local rope = constraint.FindConstraint(action.front, "Rope")
 if rope then
  if IsValid(rope.Ent1) and rope.Ent1:GetClass() == "prop_drone" then return end
  if IsValid(rope.Ent2) and rope.Ent2:GetClass() == "prop_drone" then return end
 end
 if not PlacementReady(action) then return PlacementDenied(action) end
 local aim = owner:GetAimVector()
 local backTrace = util.TraceLine({start = action.position, endpos = action.position + aim * 24,
  filter = function(hit) return hit ~= action.front and not hit:IsPlayer() and not hit.IgnoreTraces and not hit.NoBlockExplosions and string.sub(hit:GetClass(), 1, 11) ~= "projectile_" end, mask = MASK_SOLID})
 if not backTrace or backTrace.HitSky or not PlacementEndpointLive(backTrace.Entity, backTrace.HitWorld == true) then return PlacementDenied(action) end
 action.back, action.backBone, action.world = backTrace.Entity, backTrace.PhysicsBone, backTrace.HitWorld == true
 if not action.world then
  action.backPhysics, action.denialReason = PlacementPhysics(action.back, action.backBone)
  if not action.backPhysics then return PlacementDenied(action)end
 end
 if not PlacementReady(action) then return PlacementDenied(action) end
 if not PlacementMaterial(action, backTrace.MatType) then return end
 if GAMEMODE:EntityWouldBlockSpawn(action.back) or not PlacementReady(action) then return PlacementDenied(action) end
 local nail = ents.Create("prop_nail")
 action.nail = nail
 if not PryLive(nail) or not PlacementReady(action) then return PlacementDenied(action) end
 nail:SetActualOffset(action.position, action.front)
 nail:SetPos(action.position - aim * 8)
 nail:SetAngles(aim:Angle())
 nail:Spawn()
 if not PryLive(nail) or not PlacementReady(action) then return PlacementDenied(action) end
 local weld = nail:AttachTo(action.front, action.back, action.frontBone, action.backBone)
 if not IsValid(weld) or not PryLive(nail) or not PlacementBound(action) or not PryLive(action.front) or not PlacementEndpointLive(action.back, action.world)
  or action.front:GetPhysicsObjectNum(action.frontBone) ~= action.frontPhysics
  or not action.world and action.back:GetPhysicsObjectNum(action.backBone) ~= action.backPhysics then return PlacementDenied(action) end
 nail:SetDeployer(owner)
 if not PryLive(nail) or not PlacementBound(action) then return PlacementDenied(action) end
 action.committed = true
 weapon:SetNextPrimaryFire(math.max(weapon:GetNextPrimaryFire(), CurTime() + (owner.Carpenter and 0.5 or 1)))
 weapon:TakePrimaryAmmo(1)
 weapon:SendWeaponAnim(weapon.Alternate and ACT_VM_HITCENTER or ACT_VM_MISSCENTER)
 weapon.Alternate = not weapon.Alternate
 owner:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)
 owner:ClearNailWarning()
 gamemode.Call("OnNailCreated", action.front, action.back, nail)
 if PryLive(nail) then nail:EmitSound(string.format("weapons/melee/crowbar/crowbar_hit-%d.ogg", math.random(4)))end
end

local function ReleaseNailPlacement(action)
 if IsValid(action.weapon) and action.weapon.ZSNailPlaceAction == action then action.weapon.ZSNailPlaceAction = nil end
 if IsValid(action.owner) and action.owner.ZSNailPlaceAction == action then action.owner.ZSNailPlaceAction = nil end
 if not action.committed and PryLive(action.nail) then action.nail:Remove() end
end

function SWEP:SecondaryAttack()
 if not PryLive(self) or self.ZSNailPlaceAction or self.ZSNailPryAction or CurTime() < self:GetNextPrimaryFire() then return end
 local owner = self:GetOwner()
 if not PryLive(owner) or not owner:IsPlayer() or not owner:Alive() or owner:Team() ~= TEAM_HUMAN or owner:GetBarricadeGhosting()
  or owner:GetActiveWeapon() ~= self or owner.ZSNailPlaceAction or owner.ZSNailPryAction or self:GetPrimaryAmmoCount() <= 0 then return end
 local action = {weapon = self, owner = owner, deadline = CurTime() + 0.25}
 self.ZSNailPlaceAction, owner.ZSNailPlaceAction = action, action
 self:SetNextPrimaryFire(action.deadline)
 local ok, failure = pcall(PerformNailPlacement, action)
 local cleaned, cleanupFailure = pcall(ReleaseNailPlacement, action)
 if not ok then error(failure, 0)end
 if not cleaned then error(cleanupFailure, 0)end
end
