INC_SERVER()

ENT.TickTime = 0.45
ENT.Ticks = 12
ENT.Damage = 7

function ENT:Initialize()
	self:DrawShadow(false)

	self:Fire("burn", "", self.TickTime)
	self:Fire("kill", "", self.TickTime * self.Ticks + 0.01)

	self:DropToFloor()
end

function ENT:AcceptInput(name, activator, caller, arg)
	if name ~= "burn" then return end
	if self.Ticks <= 0 then return true end

	self.Ticks = self.Ticks - 1

	local owner = self:GetOwner()
	local human = IsValid(owner) and owner:IsValidLivingHuman()
	if not human then owner = self end

	local vPos = self:GetPos()
	for _, ent in ipairs(ents.FindInSphere(vPos, self.Radius)) do
		if ent and (ent:IsValidLivingPlayer() and (ent:Team() == TEAM_UNDEAD or ent == owner)) and WorldVisible(vPos, ent:NearestPoint(vPos)) then
			GAMEMODE:IgniteMolotovTarget(ent, owner, 2, self.ZSCrafter)

			if human then
				ent:AddLegDamage(7)
				ent:TakeSpecialDamage(self.Damage, DMG_BURN, owner, self)
			end
		end
	end

	if self.Ticks > 0 then
		self:Fire("burn", "", self.TickTime)
	end

	return true
end
