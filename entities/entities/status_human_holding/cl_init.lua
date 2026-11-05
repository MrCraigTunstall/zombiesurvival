INC_CLIENT()

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.AnimTime = 0.25

local function ReleaseObject(status)
	local object = status.ClientHeldObject
	status.ClientHeldObject = nil
	if not IsValid(object) then return end
	if object.ZSHoldingStatus == status then object.ZSHoldingStatus = nil end
	local state = object.ZSClientHolding
	if not state then return end
	state.holders[status] = nil
	for other in pairs(state.holders) do
		if not IsValid(other) or other.Removing then state.holders[other] = nil end
	end
	if next(state.holders) then return end
	if object.IgnoreMelee == true then object.IgnoreMelee = state.melee end
	if object.IgnoreTraces == true then object.IgnoreTraces = state.traces end
	if object.IgnoreBullets == true then object.IgnoreBullets = state.bullets end
	object.ZSClientHolding = nil
end

local function ReleaseWeapon(status)
	local owner, weapon = status.ClientOwner, status.ClientWeapon
	if status.ClientHolstered and IsValid(owner) and owner == MySelf and IsValid(weapon) and owner:GetActiveWeapon() == weapon then
		for other in pairs(owner.ZSClientHolds or {}) do
			if other ~= status and IsValid(other) and not other.Removing and other.ClientHolstered then
				status.ClientWeapon, status.ClientHolstered = nil, nil
				return
			end
		end
		local other = owner.status_human_holding
		if other == status or not IsValid(other) or other.Removing then weapon:SendWeaponAnim(ACT_VM_DRAW) end
	end
	status.ClientWeapon, status.ClientHolstered = nil, nil
end

local function ReleaseOwner(status)
	local owner = status.ClientOwner
	if IsValid(owner) then
		local holds = owner.ZSClientHolds
		local replacement
		if holds then
			holds[status] = nil
			for other in pairs(holds) do
				if IsValid(other) and not other.Removing then replacement = other else holds[other] = nil end
			end
			if not next(holds) then owner.ZSClientHolds = nil end
		end
		if owner.status_human_holding == status then owner.status_human_holding = replacement end
	end
	status.ClientOwner = nil
end

function ENT:UpdateClientHold()
	if self.Removing then return end
	local object = self:GetObject()
	if not IsValid(object) then object = nil end
	if object ~= self.ClientHeldObject then
		ReleaseObject(self)
		if object then
			local state = object.ZSClientHolding
			if not state then
				state = {holders = {}, melee = object.IgnoreMelee, traces = object.IgnoreTraces, bullets = object.IgnoreBullets}
				object.ZSClientHolding = state
			end
			state.holders[self] = true
			self.ClientHeldObject = object
			object.IgnoreMelee, object.IgnoreTraces, object.IgnoreBullets = true, true, true
		end
	end
	local owner = self:GetOwner()
	if not IsValid(owner) then owner = nil end
	if owner ~= self.ClientOwner then
		ReleaseWeapon(self)
		ReleaseOwner(self)
		self.ClientOwner = owner
		if owner then
			local holds = owner.ZSClientHolds
			if not holds then holds = {} owner.ZSClientHolds = holds end
			holds[self] = true
			owner.status_human_holding = self
		end
	end
	local weapon = owner and owner == MySelf and object and owner:GetActiveWeapon() or nil
	if not IsValid(weapon) then weapon = nil end
	local noHolster = not weapon or not not weapon.NoHolsterOnCarry
	if weapon ~= self.ClientWeapon or noHolster ~= self.NoHolster then
		ReleaseWeapon(self)
		self.ClientWeapon, self.NoHolster = weapon, noHolster
		if weapon and not noHolster then
			weapon:SendWeaponAnim(ACT_VM_HOLSTER)
			self.ClientHolstered = true
			self.Created = CurTime()
		end
	end
	return owner
end

function ENT:OnRemove(fullUpdate)
	if self.Removing then
		if not fullUpdate then self.ClientFullUpdate = nil end
		return
	end
	self.Removing = true
	self.ClientFullUpdate = fullUpdate == true or nil
	ReleaseWeapon(self)
	ReleaseOwner(self)
	ReleaseObject(self)
	self.NoHolster = true
	self.BaseClass.OnRemove(self)
end

function ENT:Initialize()
	self.Removing, self.ClientFullUpdate = nil, nil
	self:InvalidateHoldingMovement()
	self.Created, self.NoHolster = CurTime(), true
	self.BaseClass.Initialize(self)
	self:UpdateClientHold()
end

function ENT:Think()
	if self.ClientFullUpdate then
		if self:IsDormant() then return end
		self.ClientFullUpdate, self.Removing = nil, nil
		self:InvalidateHoldingMovement()
	end
	local owner = self:UpdateClientHold()
	if not owner or owner ~= MySelf then return end
	if not self.NoHolster then
		self:SetSequence(2)
		self:SetCycle(0.68 + math.sin(CurTime() * math.pi) * 0.01)
	end
	self:SetPos(owner:EyePos())
end

function ENT:Draw()
	if self.Removing or self.ClientOwner ~= MySelf or self.NoHolster or not IsValid(MySelf) or MySelf:ShouldDrawLocalPlayer() then return end
	local pos, ang = EyePos(), EyeAngles()
	pos = pos + -16 * (1 - math.Clamp((CurTime() - self.Created) / self.AnimTime, 0, 1) ^ 0.5) * ang:Up()
	self:SetPos(pos)
	self:SetAngles(ang)
	self:DrawModel()
end
