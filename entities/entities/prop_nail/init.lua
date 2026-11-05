INC_SERVER()

ENT.m_NextStrainSound = 0

if not ZSNailsByOwner then
	ZSNailsByOwner = {}
	for _, nail in ipairs(ents.FindByClass("prop_nail")) do
		local uid = nail:GetOwnerUID()
		if uid then
			ZSNailsByOwner[uid] = ZSNailsByOwner[uid] or {}
			ZSNailsByOwner[uid][nail] = true
		end
	end
end

hook.Add("PlayerInitialSpawn", "NailPlayerInitialSpawn", function(pl)
	if pl:IsBot() then return end
	local uid = pl:UniqueID()
	for nail in pairs(ZSNailsByOwner[uid] or {}) do
		if IsValid(nail) and nail:GetOwnerUID() == uid then
			nail:SetDeployer(pl)
		end
	end
end)

function ENT:Initialize()
	self:SetModel("models/crossbow_bolt.mdl")
	self:SetModelScale(0.75)
	self.m_NailUnremovable = self.m_NailUnremovable or false
	self.HealthOveride = self.HealthOveride or -1
	self.HealthMultiplier = self.HealthMultiplier or 1
end

function ENT:OnDamaged(damage, attacker, inflictor, dmginfo)
	if CurTime() >= self.m_NextStrainSound then
		self.m_NextStrainSound = CurTime() + math.min(damage * 0.025, 1)
		self:EmitSound("physics/metal/metal_box_impact_hard"..math.random(3)..".wav", math.Clamp(damage * 2.5, 60, 80), math.min(255, 150 + (1 - (self:GetNailHealth() / self:GetMaxNailHealth())) * 100))
	end
end

local function AttachmentLive(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end

local function AttachmentEndpointLive(entity)
	return (IsValid(entity) or entity == game.GetWorld()) and not entity:IsMarkedForDeletion()
end

local function NailMembership(entity, nail)
	local count = 0
	for _, candidate in ipairs(entity and entity.Nails or {}) do
		if candidate == nail then count = count + 1 end
	end
	return count
end

local function UnlinkNail(entity, nail)
	local nails = entity and entity.Nails
	if not nails then return end
	for index = #nails, 1, -1 do
		if nails[index] == nail then table.remove(nails, index) end
	end
end

local function SharedNailConstraint(cons, baseent, attachent, except)
	for _, entity in ipairs({baseent, attachent}) do
		for _, nail in ipairs(entity and entity.Nails or {}) do
			if nail ~= except and AttachmentLive(nail) and not nail.m_IsRemoving and nail:GetNailConstraint() == cons then return true end
		end
	end
	return false
end

local function RefreshNailEndpoint(entity)
	if not AttachmentLive(entity) then return end
	if not entity:IsWorld() then
		local nailed = entity:IsNailed()
		if AttachmentLive(entity) then entity:SetIsNailed(nailed) end
	end
	if AttachmentLive(entity) then entity:CollisionRulesChanged() end
end

function ENT:AttachTo(baseent, attachent, physbone, physbone2)
	if self.m_AttachmentBusy or self.m_IsRemoving or self.m_PryingOut or not AttachmentLive(self)
		or not AttachmentEndpointLive(baseent) or not AttachmentEndpointLive(attachent) or baseent == self or attachent == self then return false end
	physbone, physbone2 = physbone or 0, physbone2 or 0
	local oldbase, oldattach, oldcons, oldparent = self:GetBaseEntity(), self:GetAttachEntity(), self:GetNailConstraint(), self:GetParent()
	local cons, created, committed, unlinked
	local token = {}
	self.m_AttachmentBusy = token
	local function Stable()
		return self.m_AttachmentBusy == token and AttachmentLive(self) and AttachmentEndpointLive(baseent) and AttachmentEndpointLive(attachent) and AttachmentLive(cons)
			and (committed and self:GetBaseEntity() == baseent and self:GetAttachEntity() == attachent and self:GetParent() == baseent
				and self:GetNailConstraint() == cons and NailMembership(baseent, self) == 1 and (attachent == baseent or NailMembership(attachent, self) == 1)
				or not committed and self:GetBaseEntity() == oldbase and self:GetAttachEntity() == oldattach and self:GetNailConstraint() == oldcons and self:GetParent() == oldparent)
	end
	local ok, result = xpcall(function()
		cons = constraint.Find(baseent, attachent, "Weld", physbone, physbone2)
		if not AttachmentLive(self) or not AttachmentEndpointLive(baseent) or not AttachmentEndpointLive(attachent) then return false end
		if not AttachmentLive(cons) then
			cons = constraint.Weld(baseent, attachent, physbone, physbone2, 0, true)
			created = AttachmentLive(cons)
		end
		if not Stable() then return false end
		if oldbase == baseent and oldattach == attachent and oldcons == cons and self:GetParent() == baseent
			and NailMembership(baseent, self) == 1 and (attachent == baseent or NailMembership(attachent, self) == 1) then return cons end
		local actual
		if oldbase ~= baseent and AttachmentLive(oldbase) and NailMembership(oldbase, self) > 0 then actual = self:GetActualPos() end
		if AttachmentLive(oldcons) and oldcons ~= cons then
			oldcons:DontDeleteOnRemove(self)
			unlinked = true
			if not Stable() then return false end
		end
		UnlinkNail(oldbase, self)
		if oldattach ~= oldbase then UnlinkNail(oldattach, self) end
		UnlinkNail(baseent, self)
		if attachent ~= baseent then UnlinkNail(attachent, self) end
		self:SetBaseEntity(baseent)
		self.m_AttachEntity = attachent
		self:SetNailConstraint(cons)
		self.m_NailPhysicsBone1, self.m_NailPhysicsBone2 = physbone, physbone2
		baseent.Nails = baseent.Nails or {}
		table.insert(baseent.Nails, self)
		if attachent ~= baseent then
			attachent.Nails = attachent.Nails or {}
			table.insert(attachent.Nails, self)
		end
		committed = true
		if actual then self:SetActualOffset(actual, baseent) end
		self:SetParentPhysNum(physbone)
		self:SetParent(baseent)
		if not Stable() then return false end
		cons:DeleteOnRemove(self)
		if not Stable() then return false end
		if AttachmentLive(oldcons) and oldcons ~= cons and not SharedNailConstraint(oldcons, oldbase, oldattach, self) then oldcons:Remove() end
		if not Stable() then return false end
		if oldbase ~= baseent and oldbase ~= attachent then
			if AttachmentLive(oldbase) then oldbase:RecalculateNailBonuses() end
			RefreshNailEndpoint(oldbase)
		end
		if oldattach ~= oldbase and oldattach ~= baseent and oldattach ~= attachent then RefreshNailEndpoint(oldattach) end
		RefreshNailEndpoint(baseent)
		if attachent ~= baseent then RefreshNailEndpoint(attachent) end
		if not Stable() then return false end
		local currenthealth = baseent:GetBarricadeHealth()
		if not Stable() then return false end
		if currenthealth == 0 then
			local health = baseent:GetDefaultBarricadeHealth()
			if not Stable() then return false end
			if self.HealthOveride and self.HealthOveride > 0 then health = self.HealthOveride end
			health = health * (self.HealthMultiplier or 1)
			baseent:SetMaxBarricadeHealth(health)
			if not Stable() then return false end
			baseent:SetBarricadeHealth(health)
			if not Stable() then return false end
			baseent:SetBarricadeRepairs(baseent:GetMaxBarricadeRepairs())
			if not Stable() then return false end
		end
		baseent:RecalculateNailBonuses()
		if not Stable() then return false end
		GAMEMODE:QueuePropFreeze(baseent)
		if not Stable() then return false end
		return cons
	end, debug.traceback)
	if self.m_AttachmentBusy == token then self.m_AttachmentBusy = nil end
	if not ok or not result then
		if committed then
			UnlinkNail(baseent, self)
			if attachent ~= baseent then UnlinkNail(attachent, self) end
			if IsValid(cons) then cons:DontDeleteOnRemove(self) end
			if AttachmentLive(self) then self.m_IsRemoving = true self:Remove() end
			RefreshNailEndpoint(baseent)
			if attachent ~= baseent then RefreshNailEndpoint(attachent) end
			if AttachmentLive(oldcons) and not SharedNailConstraint(oldcons, oldbase, oldattach, self) then oldcons:Remove() end
		elseif unlinked and AttachmentLive(oldcons) and AttachmentLive(self) then
			oldcons:DeleteOnRemove(self)
		end
		if created and AttachmentLive(cons) and not SharedNailConstraint(cons, baseent, attachent, self) then cons:Remove() end
	end
	if not ok then error(result, 0) end
	return result
end

function ENT:SetAttachEntity(ent, physbone1, physbone2)
	return self:AttachTo(self:GetBaseEntity(), ent, physbone1, physbone2)
end

function ENT:SetNailConstraint(const)
	self.m_Constraint = const
end

function ENT:GetNailConstraint()
	return self.m_Constraint or NULL
end

function ENT:SetOwnerUID(uid)
	local previous = self.OwnerUID
	if previous == uid then return end
	local bucket = previous and ZSNailsByOwner[previous]
	if bucket then
		bucket[self] = nil
		if next(bucket) == nil then ZSNailsByOwner[previous] = nil end
	end
	self.OwnerUID = uid
	if uid then
		bucket = ZSNailsByOwner[uid]
		if not bucket then bucket = {} ZSNailsByOwner[uid] = bucket end
		bucket[self] = true
	end
end

function ENT:GetOwnerUID()
	return self.OwnerUID
end

function ENT:SetDeployer(pl)
	if not pl then return end

	if type(pl) == "string" then
		self:SetDTString(0, pl)
		self:SetOwner(NULL)
		self:SetOwnerUID(nil)
	elseif pl:IsValid() then
		self:SetDTString(0, "")
		self:SetOwner(pl)
		self:SetOwnerUID(not pl:IsBot() and pl:UniqueID() or nil)
	end
end

function ENT:SetNewHealth(health)
	local baseent = self:GetBaseEntity()
	if IsValid(baseent) then baseent:SetBarricadeHealth(health) end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if name == "attachto" then
		local ent = ents.FindByName(args)[1]
		if ent and ent:IsValid() then
			if NailMembership(self:GetBaseEntity(), self) > 0 or AttachmentLive(self:GetNailConstraint()) then
				self:AttachTo(ent, self:GetAttachEntity(), self.m_NailPhysicsBone1 or self:GetParentPhysNum(), self.m_NailPhysicsBone2)
			else
				self:SetParent(ent)
			end
		end

		return true
	elseif name == "nailto" then
		if self:GetParent():IsValid() then
			local ent = args == "worldspawn" and game.GetWorld() or ents.FindByName(args)[1]
			if ent then
				self:AttachTo(self:GetParent(), ent)
			end
		end

		return true
	elseif name == "setname" or name == "setdeployer" then
		self:SetDeployer(args)

		return true
	elseif name == "sethealth" then
		self:SetNewHealth(args)

		return true
	elseif name == "setunremoveable" or name == "setunremovable" then
		self.m_NailUnremovable = tonumber(args) == 1

		return true
	elseif name == "toggleunremoveable" or name == "toggleunremovable" then
		self.m_NailUnremovable = not self.m_NailUnremovable

		return true
	end
end

function ENT:OnRemove()
	self:SetOwnerUID(nil)
	if self.m_IsRemoving then return end

	local baseent = self:GetBaseEntity()
	if baseent:IsValid() and not baseent:IsWorld() then
		baseent:RemoveNail(self, nil, nil, true)
	end
	local attachent = self:GetAttachEntity()
	if attachent:IsValid() and not attachent:IsWorld() then
		attachent:RemoveNail(self, nil, nil, true)
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "unremoveable" or key == "unremovable" then
		self.m_NailUnremovable = tonumber(value) == 1
	elseif key == "healthoverride" then
		self.HealthOveride = tonumber(value)
	elseif key == "healthmultiplier" then
		self.HealthMultiplier = tonumber(value)
	end
end
