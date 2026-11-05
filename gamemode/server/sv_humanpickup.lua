local function Live(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end

local function Eligible(gm, pl, entity, now)
	return not gm.ZombieEscape and Live(pl) and pl:IsPlayer() and not pl.NoObjectPickup and pl:Alive() and pl:Team() == TEAM_HUMAN
		and Live(entity) and not entity.m_NoPickup
		and not (entity.NoPickupsTime and now < entity.NoPickupsTime and entity.NoPickupsOwner ~= pl)
end

function GM:DisallowHumanPickup(pl, entity)
end

function GM:TryHumanPickup(pl, entity)
	local now = CurTime()
	if not Eligible(self, pl, entity, now) then return end
	if gamemode.Call("DisallowHumanPickup", pl, entity) then return end
	if not Eligible(self, pl, entity, now) or pl:IsHolding() or not (now >= (pl.NextHold or 0)) then return end
	local physics = entity:GetPhysicsObject()
	if IsValid(physics) and physics:HasGameFlag(FVPHYSICS_PLAYER_HELD) then return end
	local prefix = string.sub(entity:GetClass(), 1, 12)
	if prefix ~= "prop_physics" and prefix ~= "func_physbox" then
		if type(entity.HumanHoldable) ~= "function" or not entity:HumanHoldable(pl) then return end
		if not Eligible(self, pl, entity, now) or pl:IsHolding() or not (now >= (pl.NextHold or 0)) then return end
		physics = entity:GetPhysicsObject()
		if IsValid(physics) and physics:HasGameFlag(FVPHYSICS_PLAYER_HELD) then return end
	end
	if entity:IsNailed() or entity:GetMoveType() ~= MOVETYPE_VPHYSICS or not IsValid(physics) or not physics:IsMoveable() then return end
	local capacity = pl.PropCarryCapacityMul or 1
	if type(capacity) ~= "number" or capacity ~= capacity or capacity <= 0 or capacity == math.huge then return end
	if not (physics:GetMass() <= CARRY_MAXIMUM_MASS * capacity) or not (entity:OBBMins():Length() + entity:OBBMaxs():Length() <= CARRY_MAXIMUM_VOLUME * capacity) then return end
	if entity:GetHolder() then return end
	local shootpos = pl:GetShootPos()
	if not (shootpos:DistToSqr(entity:NearestPoint(shootpos)) <= 4096) or pl:GetGroundEntity() == entity then return end
	local status = ents.Create("status_human_holding")
	if not Live(status) then return end
	if not Eligible(self, pl, entity, now) or pl:IsHolding() or not (now >= (pl.NextHold or 0))
		or entity:IsNailed() or entity:GetMoveType() ~= MOVETYPE_VPHYSICS or not IsValid(physics) then status:Remove() return end
	local currentPhysics = entity:GetPhysicsObject()
	if not IsValid(currentPhysics) or currentPhysics ~= physics or not currentPhysics:IsMoveable() or currentPhysics:HasGameFlag(FVPHYSICS_PLAYER_HELD) then status:Remove() return end
	pl.NextHold, pl.NextUnHold = now + 0.25, now + 0.05
	status:SetPos(pl:GetShootPos())
	status:SetOwner(pl)
	status:SetParent(pl)
	status:SetObject(entity)
	status:Spawn()
	if Live(status) and not status.Removing and Live(pl) and pl:Alive() and pl:Team() == TEAM_HUMAN
		and Live(entity) and status:GetOwner() == pl and status:GetObject() == entity then
		self:ReturnEquipmentRisk(pl, entity, true)
	end
end
