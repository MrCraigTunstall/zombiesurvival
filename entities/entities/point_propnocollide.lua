ENT.Type = "point"

AccessorFunc(ENT, "m_fTimeOut", "TimeOut", FORCE_NUMBER)
AccessorFunc(ENT, "m_fExtraRadius", "ExtraRadius", FORCE_NUMBER)
AccessorFunc(ENT, "m_iTeam", "Team", FORCE_NUMBER)
AccessorFunc(ENT, "m_entProp", "Prop")

ENT.PushRamp = 2.5

ENT.PushPeak = 0

local DownTrace = Vector(0, 0, -80)
local PushRate = Vector(0, 0, 0)

function ENT:Initialize()
	self.PushPeak = CurTime() + self.PushRamp
	self.PushTrace = {mask = MASK_SOLID_BRUSHONLY}

	self:SetTimeOut(0)
	self:SetExtraRadius(8)
	self:SetProp(NULL)
end

local function ReleaseGhostProp(self)
	local ent = self.GhostTarget or self:GetProp()
	local managed, changed = self.GhostManaged, self.GhostChanged
	local material, group = self.OldMaterial, self.RestoreCollisionGroup
	self.GhostTarget, self.GhostChanged, self.OldMaterial, self.RestoreCollisionGroup = nil, nil, nil, nil
	if not IsValid(ent) then return end
	local other = ent.ZSGhostController
	if other == self then
		ent.ZSGhostController = nil
	elseif IsValid(other) and not other.Removing and not other:IsMarkedForDeletion() and other:GetProp() == ent then
		return
	end
	if managed and not changed then return end
	if material ~= nil and (not managed or ent:GetMaterial() == "models/spawn_effect") then ent:SetMaterial(material) end
	if not managed then group = ent.PreHoldCollisionGroup end
	if group == nil or managed and ent:GetCollisionGroup() ~= COLLISION_GROUP_WEAPON then return end
	for _, e in ipairs(GAMEMODE:GetZSEquipmentEntities("status_human_holding", true)) do
		if IsValid(e) and not e.Removing and not e.RemovingPickupGhosts and not e:IsMarkedForDeletion() and e:GetObject() == ent then
			return
		end
	end
	ent:SetCollisionGroup(group)
	ent:CollisionRulesChanged()
end

local function CurrentGhostBinding(self, ent, version)
	return not self.Removing and not self:IsMarkedForDeletion() and self.GhostBindingVersion == version
		and IsValid(ent) and not ent:IsMarkedForDeletion() and self:GetProp() == ent
end

local function CanGhostPush(pl)
	return IsValid(pl) and (pl:IsValidLivingHuman() or pl:IsPlayer() and pl:Alive() and pl:Team() == TEAM_UNDEAD and pl:GetZombieClassTable().Boss)
end

local function GhostPlayerOverlaps(self, ent, pl, minimum, maximum)
	local low, high
	if pl:Crouching() then low, high = pl:GetHullDuck() else low, high = pl:GetHull() end
	local position = pl:GetPos()
	local extra = math.max(0, self:GetExtraRadius())
	if position.x + high.x + extra < minimum.x or position.x + low.x - extra > maximum.x
		or position.y + high.y + extra < minimum.y or position.y + low.y - extra > maximum.y
		or position.z + high.z + extra < minimum.z or position.z + low.z - extra > maximum.z then return false end
	local trace = self.GhostOverlapTrace
	if not trace then
		trace = {filter = {ent}, whitelist = true, ignoreworld = true, mask = MASK_SOLID, collisiongroup = COLLISION_GROUP_NONE, output = {}}
		self.GhostOverlapTrace = trace
	else
		trace.filter[1] = ent
	end
	low.x, low.y, low.z = low.x - extra, low.y - extra, low.z - extra
	high.x, high.y, high.z = high.x + extra, high.y + extra, high.z + extra
	trace.mins, trace.maxs = low, high
	trace.start = position
	trace.endpos = trace.start
	local result = util.TraceHull(trace)
	return IsValid(pl) and (result.Hit or result.StartSolid), true
end

function ENT:SetProp(ent, restoreGroup)
	if self.Removing or self:IsMarkedForDeletion() then return end
	if self.GhostChanged and self.GhostTarget == ent and self:GetProp() == ent then
		if restoreGroup ~= nil then self.RestoreCollisionGroup = restoreGroup end
		return
	end
	local version = (self.GhostBindingVersion or 0) + 1
	self.GhostBindingVersion = version
	ReleaseGhostProp(self)
	if self.Removing or self:IsMarkedForDeletion() or self.GhostBindingVersion ~= version then return end
	self.GhostOverlapTrace = nil
	self.PushMoveTrace = nil
	self.PushMoveFilters = nil
	self.m_entProp, self.GhostManaged = NULL, true
	if not IsValid(ent) or ent:IsMarkedForDeletion() then return end
	for _, other in ipairs(GAMEMODE:GetZSEquipmentEntities(self:GetClass(), true)) do
		if other ~= self and IsValid(other) and other:GetProp() == ent and not other.Removing then
			if not other:IsMarkedForDeletion() then return end
			other:OnRemove()
		end
	end
	if self.Removing or self:IsMarkedForDeletion() or self.GhostBindingVersion ~= version or not IsValid(ent) or ent:IsMarkedForDeletion() then return end
	self.m_entProp, self.GhostTarget = ent, ent
	ent.ZSGhostController = self
	local inrad = false
	local minimum, maximum = ent:WorldSpaceAABB()
	for _, pl in player.Iterator() do
		if IsValid(pl) and pl:IsValidLivingPlayer() then
			if not CurrentGhostBinding(self, ent, version) then return end
			local overlaps, traced = GhostPlayerOverlaps(self, ent, pl, minimum, maximum)
			if traced and not CurrentGhostBinding(self, ent, version) then return end
			if overlaps and IsValid(pl) and pl:IsValidLivingPlayer() then inrad = true break end
		end
	end
	if not inrad then
		if restoreGroup ~= nil and restoreGroup ~= ent:GetCollisionGroup() then ent:SetCollisionGroup(restoreGroup) ent:CollisionRulesChanged() end
		return
	end
	self.OldMaterial = ent:GetMaterial()
	self.RestoreCollisionGroup = restoreGroup == nil and ent:GetCollisionGroup() or restoreGroup
	self.GhostChanged = true
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ent:SetMaterial("models/spawn_effect")
	ent:CollisionRulesChanged()
end

function ENT:OnRemove()
	if self.Removing then return end
	self.Removing = true
	self.PushTrace = nil
	self.GhostOverlapTrace = nil
	self.PushMoveTrace = nil
	self.PushMoveFilters = nil
	ReleaseGhostProp(self)
end

local function PushStillValid(self, ent, pl, version)
	return CurrentGhostBinding(self, ent, version) and CanGhostPush(pl)
end

local function ClearPushDirection(self, ent, pl, diff, version)
	if diff.x == 0 and diff.y == 0 then return true end
	local trace = self.PushMoveTrace
	if not trace then
		trace = {mask = MASK_PLAYERSOLID, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT, filter = {}, output = {}, endpos = Vector()}
		self.PushMoveTrace = trace
	end
	local filters = self.PushMoveFilters
	if not filters then filters = {epoch = 1} self.PushMoveFilters = filters end
	trace.filter = GAMEMODE:GetGhostMovementFilter(pl, ent, filters)
	if pl:Crouching() then trace.mins, trace.maxs = pl:GetHullDuck() else trace.mins, trace.maxs = pl:GetHull() end
	trace.start = pl:GetPos()
	local x, y = diff.x, diff.y
	for attempt = 1, 4 do
		trace.endpos:Set(trace.start)
		trace.endpos:Add(diff)
		local result = util.TraceHull(trace)
		if not PushStillValid(self, ent, pl, version) then return false end
		if type(trace.filter) == "table" and (result.Hit or result.StartSolid) and IsValid(result.Entity) and GAMEMODE:ShouldCollide(pl, result.Entity) == false then
			trace.filter = GAMEMODE:GetGhostMovementFilter(pl, ent, filters, true)
			result = util.TraceHull(trace)
			if not PushStillValid(self, ent, pl, version) then return false end
		end
		if not result.Hit and not result.StartSolid then return true end
		if attempt == 1 then diff.x, diff.y = -y, x
		elseif attempt == 2 then diff.x, diff.y = y, -x
		elseif attempt == 3 then diff.x, diff.y = -x, -y end
	end
	return false
end

function ENT:Think()
	if self.Removing or self:IsMarkedForDeletion() then return end
	local ent = self:GetProp()
	if not IsValid(ent) or ent:IsMarkedForDeletion() then
		self:Remove()
		return
	end
	if self.PushMoveFilters then self.PushMoveFilters.epoch = self.PushMoveFilters.epoch + 1 end
	local version = self.GhostBindingVersion

	local pushout = false
	local now, deadline = CurTime(), self:GetTimeOut()
	local timeout = deadline > 0 and now >= deadline
	--local teamid = self:GetTeam()
	local rate = 900 * FrameTime()
	local center = ent:LocalToWorld(ent:OBBCenter())
	local trace = self.PushTrace or {mask = MASK_SOLID_BRUSHONLY}
	self.PushTrace = trace

	rate = rate * math.Clamp(1 - (self.PushPeak - now) / self.PushRamp, 0, 1)
	PushRate.x = rate
	rate = PushRate.x

	local minimum, maximum = ent:WorldSpaceAABB()
	for _, pl in player.Iterator() do
		if CanGhostPush(pl) then
			if not CurrentGhostBinding(self, ent, version) then break end
			local overlaps, traced = GhostPlayerOverlaps(self, ent, pl, minimum, maximum)
			if traced and not CurrentGhostBinding(self, ent, version) then break end
			if overlaps and CanGhostPush(pl) then
				pushout = true

				if timeout then
					if ent:IsBarricadeProp() and pl:Team() == TEAM_HUMAN then
						pl:SetBarricadeGhosting(true)
					end
				elseif not pl:GetBarricadeGhosting() then
					local plpos = pl:LocalToWorld(pl:OBBCenter())
					local diff = plpos - center
					diff.z = 0
					if diff.x == 0 and diff.y == 0 then diff.x = 1 end
					diff:Normalize()
					diff:Mul(rate)
					if not trace.start then trace.start, trace.endpos = Vector(), Vector() end
					if not trace.output then trace.output = {} end
					if ClearPushDirection(self, ent, pl, diff, version) then
						trace.start:Set(plpos)
						trace.start:Add(diff)
						trace.endpos:Set(trace.start)
						trace.endpos:Add(DownTrace)
						if util.TraceLine(trace).Hit and PushStillValid(self, ent, pl, version) then
							pl:SetVelocity(diff)
						end
					end
				end
			end
		end
	end

	if self.Removing or self:IsMarkedForDeletion() then return end
	if not IsValid(ent) or ent:IsMarkedForDeletion() then self:Remove() return end
	if self.GhostBindingVersion ~= version or self:GetProp() ~= ent then self:NextThink(now) return true end
	if not pushout or timeout then
		self:Remove()
		return
	end

	self:NextThink(now)
	return true
end
