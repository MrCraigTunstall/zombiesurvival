INC_SERVER()

local function PickupActive(status, object, owner)
	return IsValid(status) and not status.Removing and not status:IsMarkedForDeletion()
		and IsValid(object) and not object:IsMarkedForDeletion()
		and IsValid(owner) and owner:IsPlayer() and owner:Alive() and owner:Team() == TEAM_HUMAN
		and status:GetObject() == object and status:GetOwner() == owner
end

local function AcquireHoldFlags(status, object)
	local state = object.ZSServerHolding
	if not state then
		state = {holders = {}, team = object.IgnoreMeleeTeam, traces = object.IgnoreTraces, bullets = object.IgnoreBullets}
		object.ZSServerHolding = state
	end
	state.holders[status] = true
	status.HoldFlags, status.HoldFlagsObject = state, object
	object.IgnoreMeleeTeam, object.IgnoreTraces, object.IgnoreBullets = TEAM_HUMAN, true, true
end

local function ReleaseHoldFlags(status, object)
	local state = status.HoldFlags
	object = status.HoldFlagsObject or object
	status.HoldFlags, status.HoldFlagsObject = nil, nil
	if state then state.holders[status] = nil end
	if not IsValid(object) then return end
	if state then
		if object.ZSServerHolding ~= state then return end
		for other in pairs(state.holders) do
			if not IsValid(other) or other.Removing or other:IsMarkedForDeletion() then state.holders[other] = nil end
		end
		if next(state.holders) then return end
		if object.IgnoreMeleeTeam == TEAM_HUMAN then object.IgnoreMeleeTeam = state.team end
		if object.IgnoreTraces == true then object.IgnoreTraces = state.traces end
		if object.IgnoreBullets == true then object.IgnoreBullets = state.bullets end
		object.ZSServerHolding = nil
	elseif not status.HoldFlagsManaged and not object.ZSServerHolding then
		for _, other in ipairs(GAMEMODE:GetZSEquipmentEntities("status_human_holding", true)) do
			if other ~= status and IsValid(other) and not other.Removing and not other:IsMarkedForDeletion() and other:GetObject() == object then return end
		end
		if object.IgnoreMeleeTeam == TEAM_HUMAN then object.IgnoreMeleeTeam = nil end
		if object.IgnoreTraces == true then object.IgnoreTraces = nil end
		if object.IgnoreBullets == true then object.IgnoreBullets = nil end
	end
end

local function AcquireHoldVisual(status, object, physics)
	local state = object.ZSServerHoldVisual
	if not state then
		state = {holders = {}, group = object:GetCollisionGroup()}
		object.ZSServerHoldVisual = state
	end
	if physics and state.alpha == nil then state.alpha, state.mode = object:GetAlpha(), object:GetRenderMode() end
	state.holders[status] = physics
	status.HoldVisuals = status.HoldVisuals or {}
	status.HoldVisuals[object] = state
	object.PreHoldCollisionGroup = state.group
	if physics then
		object.PreHoldAlpha, object.PreHoldRenderMode = state.alpha, state.mode
		object:SetAlpha(180)
		object:SetRenderMode(RENDERMODE_TRANSALPHA)
	end
	object:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end

local function RestoreHoldColor(object, state)
	if state.alpha ~= nil and object:GetAlpha() == 180 then object:SetAlpha(state.alpha) end
	if state.mode ~= nil and object:GetRenderMode() == RENDERMODE_TRANSALPHA then object:SetRenderMode(state.mode) end
end

local function ReleaseHoldVisuals(status, root)
	local visuals = status.HoldVisuals
	status.HoldVisuals = nil
	local rootState, restoreRoot
	for object, state in pairs(visuals or {}) do
		state.holders[status] = nil
		for other in pairs(state.holders) do
			if not IsValid(other) or other.Removing or other:IsMarkedForDeletion() then state.holders[other] = nil end
		end
		if object == root then rootState = state end
		if IsValid(object) and object.ZSServerHoldVisual == state then
			if not next(state.holders) then
				object.ZSServerHoldVisual = nil
				if object == root then restoreRoot = true else
					if object:GetCollisionGroup() == COLLISION_GROUP_WEAPON then object:SetCollisionGroup(state.group) object:CollisionRulesChanged() end
					RestoreHoldColor(object, state)
				end
			else
				local colorHeld = false
				for _, physics in pairs(state.holders) do if physics then colorHeld = true break end end
				if not colorHeld then RestoreHoldColor(object, state) end
			end
		end
	end
	return rootState, restoreRoot
end

local function ReleaseOwnerHold(status, owner)
	local holds, weapon = status.ServerOwnerHolds, status.ServerHolsteredWeapon
	status.ServerOwnerHolds, status.ServerHolsteredWeapon = nil, nil
	if holds then holds[status] = nil end
	if status.ServerOwnerManaged and not holds then return false end
	if not IsValid(owner) then return false end
	holds = holds or owner.ZSServerHolds
	local replacement
	if holds then
		holds[status] = nil
		for other in pairs(holds) do
			if IsValid(other) and not other.Removing and not other:IsMarkedForDeletion() then replacement = other else holds[other] = nil end
		end
		if owner.ZSServerHolds == holds and not next(holds) then owner.ZSServerHolds = nil end
	end
	local cached = owner.status_human_holding
	if cached == status or not IsValid(cached) or cached.Removing or cached:IsMarkedForDeletion() then owner.status_human_holding = replacement end
	cached = owner.status_human_holding
	local active = replacement or IsValid(cached) and not cached.Removing and not cached:IsMarkedForDeletion()
	if owner.ZSServerHolds and owner.ZSServerHolds ~= holds then active = true end
	if active then
		if replacement and weapon and not replacement.ServerHolsteredWeapon then replacement.ServerHolsteredWeapon = weapon end
		return false
	end
	return true, weapon
end

local function AcquireHoldPhysics(status, object, physics, owner)
	local state = object.ZSServerHoldPhysics
	if not state or not IsValid(state.physics) or state.physics ~= physics then
		local originalOwner, legacyMass = object:GetOwner(), object._OriginalMass
		if state then
			if originalOwner == state.appliedOwner then originalOwner = state.owner end
			if legacyMass == state.mass then legacyMass = state.legacyMass end
		end
		state = {object = object, physics = physics, mass = physics:GetMass(), legacyMass = legacyMass, gravity = physics:IsGravityEnabled(), owner = originalOwner, held = physics:HasGameFlag(FVPHYSICS_PLAYER_HELD), impact = physics:HasGameFlag(FVPHYSICS_NO_IMPACT_DMG), npcImpact = physics:HasGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG), holders = {}}
		object.ZSServerHoldPhysics = state
	end
	state.holders[status] = owner
	state.controller = status
	status.HoldPhysics = state
	status:SetObjectMass(state.mass)
	object._OriginalMass = state.mass
	physics:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
	physics:AddGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)
	physics:AddGameFlag(FVPHYSICS_PLAYER_HELD)
	physics:EnableGravity(false)
	physics:SetMass(2)
	state.appliedOwner = owner
	object:SetOwner(owner)
end

local function ReleaseHoldPhysics(status, object, state)
	if not state or not state.holders then return true end
	state.holders[status] = nil
	if state.released then return false end
	local replacement
	for other in pairs(state.holders) do
		if IsValid(other) and not other.Removing and not other:IsMarkedForDeletion() and other.HoldPhysics == state and PickupActive(other, object, state.holders[other]) then
			if other == state.controller or not replacement then replacement = other end
		else
			state.holders[other] = nil
		end
	end
	if replacement then
		state.controller = replacement
		if IsValid(object) and object.ZSServerHoldPhysics == state and object:GetOwner() == state.appliedOwner then
			state.appliedOwner = state.holders[replacement]
			object:SetOwner(state.appliedOwner)
		end
		return false
	end
	state.released, state.controller = true, nil
	if not IsValid(object) or object.ZSServerHoldPhysics ~= state then return false end
	object.ZSServerHoldPhysics = nil
	return true
end

function ENT:Initialize()
	self.HoldFlagsManaged = true
	self.HoldInitialized = true
	self.ServerOwnerManaged = true
	self:InvalidateHoldingMovement()
	local object, owner = self:GetObject(), self:GetOwner()
	if not PickupActive(self, object, owner) then self:Remove() return end
	self.HeldOwner = owner

	self:DrawShadow(false)

	if owner:IsValid() and owner:IsPlayer() then
		local holds = owner.ZSServerHolds
		if not holds then holds = {} owner.ZSServerHolds = holds end
		holds[self] = true
		self.ServerOwnerHolds = holds
		owner.status_human_holding = self

		owner:DrawWorldModel(false)
		if not PickupActive(self, object, owner) then if IsValid(self) then self:Remove() end return end

		local info = GAMEMODE:GetHandsModel(owner)
		if not PickupActive(self, object, owner) then if IsValid(self) then self:Remove() end return end
		if info then
			self:SetModel(info.model)
			self:SetSkin(info.skin)
			self:SetBodyGroups(info.body)
		end

		local wep = owner:GetActiveWeapon()
		if wep:IsValid() then
			if not wep.NoHolsterOnCarry then
				self.ServerHolsteredWeapon = wep
				local holstered = false
				for other in pairs(holds) do
					if other ~= self and IsValid(other) and not other.Removing and not other:IsMarkedForDeletion() and other.ServerHolsteredWeapon == wep then holstered = true break end
				end
				if not holstered then wep:SendWeaponAnim(ACT_VM_HOLSTER) end
			end
			if not PickupActive(self, object, owner) then if IsValid(self) then self:Remove() end return end
			if IsValid(wep) and wep.SetIronsights then
				wep:SetIronsights(false)
			end
		end
	else
		self:SetModel("models/weapons/c_arms_citizen.mdl")
	end

	if not PickupActive(self, object, owner) then
		if IsValid(self) then self:Remove() end
		return
	end
	if object:IsValid() then
		self.HeldObject = object
		AcquireHoldFlags(self, object)

		local name = object:GetName()
		for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("logic_pickupdrop", true)) do
			if IsValid(ent) and ent.EntityToWatch == name then
				ent:Input("onpickedup", owner, object, "")
				if not PickupActive(self, object, owner) then
					if IsValid(self) then self:Remove() end
					return
				end
			end
		end

		self.RemovingPickupGhosts = true
		for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("point_propnocollide", true)) do
			if ent:IsValid() and ent:GetProp() == object then
				ent:OnRemove()
				if IsValid(ent) then ent:Remove() end
				if not PickupActive(self, object, owner) then break end
			end
		end
		self.RemovingPickupGhosts = nil
		if not PickupActive(self, object, owner) then
			if IsValid(self) then self:Remove() end
			return
		end

		local objectphys = object:GetPhysicsObject()
		if objectphys:IsValid() then
			AcquireHoldPhysics(self, object, objectphys, owner)
			AcquireHoldVisual(self, object, true)

			self.StartX = owner.InputMouseX or 0
			self.StartY = owner.InputMouseY or 0

			local children = object:GetChildren()
			for _, child in pairs(children) do
				if not child:IsValid() then continue end

				AcquireHoldVisual(self, child, child:IsPhysicsModel())
				child:CollisionRulesChanged()
			end

			object:CollisionRulesChanged()
		end
	end
end

local function RestoreFlag(physics, flag, enabled)
	if enabled then physics:AddGameFlag(flag) else physics:ClearGameFlag(flag) end
end

function ENT:OnRemove()
	if self.Removing then return end
	self.Removing = true
	hook.Remove("Move", self)
	local held = self:GetObject()
	if IsValid(held) and held.ZSHoldingStatus == self then held.ZSHoldingStatus = nil end
	if IsValid(self.HeldObject) and self.HeldObject.ZSHoldingStatus == self then self.HeldObject.ZSHoldingStatus = nil end

	local owner = self.HeldOwner or self:GetOwner()
	local currentOwner = self:GetOwner()
	if currentOwner ~= owner and IsValid(currentOwner) and currentOwner.status_human_holding == self then currentOwner.status_human_holding = nil end

	local object = self.HeldObject or not self.HoldInitialized and self:GetObject() or NULL
	ReleaseHoldFlags(self, object)
	local visual, restoreVisual = ReleaseHoldVisuals(self, object)
	local saved = self.HoldPhysics
	local restorePhysics = ReleaseHoldPhysics(self, object, saved)
	if object:IsValid() then
		local objectphys = object:GetPhysicsObject()
		local legacy = not self.HoldInitialized
		if restorePhysics and objectphys:IsValid() and (legacy or saved and IsValid(saved.physics) and objectphys == saved.physics) then
			RestoreFlag(objectphys, FVPHYSICS_PLAYER_HELD, saved and saved.held)
			RestoreFlag(objectphys, FVPHYSICS_NO_IMPACT_DMG, saved and saved.impact)
			RestoreFlag(objectphys, FVPHYSICS_NO_NPC_IMPACT_DMG, saved and saved.npcImpact)
			objectphys:EnableGravity(not saved or saved.gravity)
			local mass = saved and saved.mass or object._OriginalMass
			if mass then objectphys:SetMass(mass) end
		end
		if restorePhysics then
			if saved then object._OriginalMass = saved.legacyMass elseif legacy then object._OriginalMass = nil end
		end
		if restorePhysics and (saved or legacy and objectphys:IsValid()) and (not saved or not saved.holders or object:GetOwner() == saved.appliedOwner) then object:SetOwner(saved and IsValid(saved.owner) and saved.owner or NULL) end

		local ghostGroup
		if visual and restoreVisual then
			if visual.alpha ~= nil and object:GetAlpha() == 180 then object:SetAlpha(visual.alpha) end
			if visual.mode ~= nil and object:GetRenderMode() == RENDERMODE_TRANSALPHA then object:SetRenderMode(visual.mode) end
			if object:GetCollisionGroup() == COLLISION_GROUP_WEAPON then
				ghostGroup = visual.group
				object:SetCollisionGroup(ghostGroup)
			end
		elseif not visual and legacy and objectphys:IsValid() and not self:GetIsHeavy() and not object.ZSServerHoldVisual then
			ghostGroup = object.PreHoldCollisionGroup or COLLISION_GROUP_NONE
			object:SetCollisionGroup(ghostGroup)
			object:SetAlpha(object.PreHoldAlpha or 255)
			object:SetRenderMode(object.PreHoldRenderMode or RENDERMODE_NORMAL)
			local children = object:GetChildren()
			for _, child in pairs(children) do
				if not child:IsValid() or child.ZSServerHoldVisual then continue end

				child:SetCollisionGroup(child.PreHoldCollisionGroup or COLLISION_GROUP_NONE)
				if child:IsPhysicsModel() then
					child:SetAlpha(child.PreHoldAlpha or 255)
					child:SetRenderMode(child.PreHoldRenderMode or RENDERMODE_NORMAL)
				end

				child:CollisionRulesChanged()
			end
		end

		if ghostGroup ~= nil then object:GhostAllPlayersInMe(4, true, ghostGroup) end
		if IsValid(object) and not object:IsMarkedForDeletion() then
			object:CollisionRulesChanged()

			object._LastDroppedBy = owner
			object._LastDropped = CurTime()

			local name = object:GetName()
			for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("logic_pickupdrop", true)) do
				if IsValid(ent) and ent.EntityToWatch == name then
					ent:Input("ondropped", owner, object, "")
					if not IsValid(object) or object:IsMarkedForDeletion() then break end
				end
			end
		end
	end
	self.HoldPhysics, self.HeldObject, self.HeldOwner = nil, nil, nil
	self.HoldForce, self.HoldBasis, self.ObjectPosition, self.ObjectAngles, self.ShadowParams = nil, nil, nil, nil, nil
	local show, holstered = ReleaseOwnerHold(self, owner)
	if show then
		owner:DrawWorldModel(true)

		if IsValid(owner) and not owner.ZSServerHolds and not IsValid(owner.status_human_holding) and owner:Alive() and owner:Team() == TEAM_HUMAN then
			local wep = owner:GetActiveWeapon()
			if wep:IsValid() and not wep.NoHolsterOnCarry and (wep == holstered or not self.ServerOwnerManaged) then
				wep:SendWeaponAnim(ACT_VM_DRAW)
			end
		end
	end

end

function ENT:Think()
	if self.Removing or self:IsMarkedForDeletion() then return end
	local ct = CurTime()

	local frametime = ct - (self.LastThink or ct)
	self.LastThink = ct

	local object = self:GetObject()
	local owner = self:GetOwner()
	if self.HeldObject and object ~= self.HeldObject or self.HeldOwner and owner ~= self.HeldOwner
		or not object:IsValid() or object:IsMarkedForDeletion() or object:IsNailed() or not owner:IsValid() or not owner:Alive() or owner:Team() ~= TEAM_HUMAN then
		self:Remove()
		return
	end

	local objectphys = object:GetPhysicsObject()
	local hold = self.HoldPhysics
	if not objectphys:IsValid() or hold and (not IsValid(hold.physics) or objectphys ~= hold.physics
		or hold.holders and (hold.released or object.ZSServerHoldPhysics ~= hold or not hold.holders[self]))
		or object:GetMoveType() ~= MOVETYPE_VPHYSICS or owner:GetGroundEntity() == object then
		self:Remove()
		return
	end
	if hold and hold.controller and hold.controller ~= self then
		self:NextThink(ct)
		return true
	end

	local heavy = self:GetIsHeavy()
	local pullpos, hingepos, shootpos
	if heavy then
		pullpos, hingepos = self:GetPullPos(), self:GetHingePos()
		if hingepos:DistToSqr(pullpos) >= 4096 then
			self:Remove()
			return
		end
	else
		shootpos = owner:GetShootPos()
		if object:NearestPoint(shootpos):DistToSqr(shootpos) >= 4096 then
			self:Remove()
			return
		end
	end

	objectphys:Wake()

	if owner:KeyPressed(IN_ATTACK) then
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	elseif heavy then
		local force = self.HoldForce
		if not force then force = Vector() self.HoldForce = force end
		force:Set(pullpos)
		force:Sub(hingepos)
		force:Normalize()
		force:Mul(objectphys:GetMass() * frametime * 450)
		objectphys:ApplyForceOffset(force, hingepos)
	elseif owner:KeyDown(IN_ATTACK2) and not owner:GetActiveWeapon().NoPropThrowing then
		owner:ConCommand("-attack2")
		local force = self.HoldForce
		if not force then force = Vector() self.HoldForce = force end
		force:Set(owner:GetAimVector())
		force:Mul(objectphys:GetMass() * math.Clamp(1.25 - math.min(1, (object:OBBMins():Length() + object:OBBMaxs():Length()) / CARRY_DRAG_VOLUME), 0.25, 1) * 500)
		force:Mul(owner.ObjectThrowStrengthMul or 1)
		objectphys:ApplyForceCenter(force)
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	else
		if not self.ObjectPosition or not owner:KeyDown(IN_SPEED) then
			local obbcenter = object:OBBCenter()
			local objectpos, basis = self.ObjectPosition, self.HoldBasis
			if not objectpos then objectpos = Vector() self.ObjectPosition = objectpos end
			if not basis then basis = Vector() self.HoldBasis = basis end
			objectpos:Set(owner:GetAimVector())
			objectpos:Mul(48)
			objectpos:Add(shootpos)
			basis:Set(object:GetUp()) basis:Mul(obbcenter.z) objectpos:Sub(basis)
			basis:Set(object:GetRight()) basis:Mul(obbcenter.y) objectpos:Add(basis)
			basis:Set(object:GetForward()) basis:Mul(obbcenter.x) objectpos:Sub(basis)
			if not self.ObjectAngles then
				self.ObjectAngles = object:GetAngles()
			end
		end

		if owner:KeyDown(IN_SPEED) then
			if owner:KeyPressed(IN_SPEED) then
				self.ObjectAngles = object:GetAngles()
			end
		elseif owner:KeyDown(IN_WALK) then
			local xdiff = math.NormalizeAngle(self.StartX - (owner.InputMouseX or 0))
			local ydiff = math.NormalizeAngle(self.StartY - (owner.InputMouseY or 0))
			local rotation = FrameTime() * 8
			local sxdiff = xdiff * rotation
			local sydiff = ydiff * rotation

			self.ObjectAngles:RotateAroundAxis(owner:GetUp(), sxdiff)
			self.ObjectAngles:RotateAroundAxis(owner:GetRight(), sydiff)

			self.StartX = math.NormalizeAngle(self.StartX - (sxdiff))
			self.StartY = math.NormalizeAngle(self.StartY - (sydiff))
		end

		local shadow = self.ShadowParams
		if not shadow then
			shadow = {secondstoarrive = 0.01, maxangular = 1000, maxangulardamp = 10000, maxspeed = 500, maxspeeddamp = 1000, dampfactor = 0.65, teleportdistance = 0}
			self.ShadowParams = shadow
		end
		shadow.pos = self.ObjectPosition
		shadow.angle = self.ObjectAngles
		shadow.deltatime = frametime
		objectphys:ComputeShadowControl(shadow)
	end

	object:SetPhysicsAttacker(owner)
	object.LastHeld = ct

	self:NextThink(ct)
	return true
end
