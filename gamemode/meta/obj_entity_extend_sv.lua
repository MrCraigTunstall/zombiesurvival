local meta = FindMetaTable("Entity")
if not meta then return end

local function FiniteHealingNumber(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function meta:HealPlayer(pl, amount, pointmul, nobymsg, poisononly)
	if not IsValid(pl) then return end
	pointmul = pointmul or 1
	if not FiniteHealingNumber(amount) or amount <= 0 or not FiniteHealingNumber(pointmul) then return 0 end
	local healed, rmv = 0, 0

	local health, missing_health
	if not poisononly then
		health = pl:Health()
		missing_health = pl:GetMaxHealth() - health
	end
	local poison = pl:GetPoisonDamage()
	local bleed = not poisononly and pl:GetBleedDamage() or 0

	local healrec = (pl.HealingReceived or 1)
	local healmul = self.MedicHealMul or 1
	if not FiniteHealingNumber(healrec) or not FiniteHealingNumber(healmul) or healrec < 0 or healmul < 0 then return 0 end
	local multiplier = healmul + healrec - 1
	local regamount = healmul * amount

	amount = amount * multiplier

	if not FiniteHealingNumber(amount) or amount <= 0 or not FiniteHealingNumber(regamount) then return 0 end

	-- Heal bleed first.
	if not poisononly and bleed > 0 and pl.AddBleedDamage then
		rmv = math.min(amount, bleed)
		pl:AddBleedDamage(-rmv)
		healed = healed + rmv
		amount = amount - rmv
	end

	-- Heal poison next.
	if poison > 0 and amount > 0 and pl.AddPoisonDamage then
		rmv = math.min(amount, poison)
		pl:AddPoisonDamage(-rmv)
		healed = healed + rmv
		amount = amount - rmv
	end

	-- Then heal missing health.
	if not poisononly and missing_health > 0 and amount > 0 then
		local targethealth = health + math.min(amount, missing_health)
		targethealth = targethealth < 0 and math.ceil(targethealth) or math.floor(targethealth)
		rmv = targethealth - health
		if rmv > 0 then
			pl:SetHealth(targethealth)
			healed = healed + rmv
			amount = amount - rmv
		end
	end

	if healed > 0 and self:IsPlayer() then
		pointmul = regamount > 0 and pointmul / (math.max(healed, regamount) / regamount) or 0
		gamemode.Call("PlayerHealedTeamMember", self, pl, healed, self:GetActiveWeapon(), pointmul, nobymsg, healed >= 10)
	end

	return healed
end

function meta:GetDefaultBarricadeHealth()
	local mass = 2
	if self._OriginalMass then
		mass = self._OriginalMass
	else
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			mass = phys:GetMass()
		end
	end

	return math.Clamp(mass * GAMEMODE.BarricadeHealthMassFactor + self:GetVolume() * GAMEMODE.BarricadeHealthVolumeFactor, GAMEMODE.BarricadeHealthMin, GAMEMODE.BarricadeHealthMax)
end

function meta:HitFence(data, phys)
	local pos = phys:GetPos()
	local vel = data.OurOldVelocity
	local endpos = vel:GetNormalized()
	endpos:Add(data.HitPos)
	local trace = {start = pos, endpos = endpos, mask = MASK_SOLID, filter = self}
	local solid = util.TraceLine(trace).Hit
	if solid then
		for key in pairs(trace) do trace[key] = nil end
		trace.start, trace.endpos, trace.mask, trace.filter = pos, endpos, MASK_SHOT, self
	end
	if solid and not util.TraceLine(trace).Hit then
		self:SetPos(data.HitPos)
		phys:SetPos(data.HitPos)
		phys:SetVelocityInstantaneous(vel)

		return true
	end

	return false
end

function meta:GhostAllPlayersInMe(timeout, allowrepeat, collisionGroup)
	if not IsValid(self) or self:IsMarkedForDeletion() or not allowrepeat and self.GhostedBefore then return end
	local ent = self.ZSGhostController
	local group = collisionGroup == nil and self:GetCollisionGroup() or collisionGroup
	if group == COLLISION_GROUP_DEBRIS_TRIGGER then
		if IsValid(ent) and not ent.Removing and not ent:IsMarkedForDeletion() and ent:GetProp() == self then
			if collisionGroup ~= nil then self:SetCollisionGroup(group) self:CollisionRulesChanged() end
			ent:OnRemove()
			ent:Remove()
		end
		return
	end
	if IsValid(ent) and not ent.Removing and not ent:IsMarkedForDeletion() and ent:GetProp() == self then
		if collisionGroup ~= nil then ent:SetProp(self, collisionGroup) end
	else
		self.ZSGhostController = nil
		ent = ents.Create("point_propnocollide")
		if not IsValid(ent) then return end
		ent:SetPos(self:GetPos())
		ent:Spawn()
		if not IsValid(self) or self:IsMarkedForDeletion() or not IsValid(ent) then
			if IsValid(ent) then ent:Remove() end
			return
		end
		if timeout then ent:SetTimeOut(CurTime() + timeout) end
		ent:SetTeam(TEAM_HUMAN)
		ent:SetProp(self, collisionGroup)
	end
	if not IsValid(self) or self:IsMarkedForDeletion() then
		if IsValid(ent) and (ent:GetProp() == self or not IsValid(ent:GetProp())) then ent:Remove() end
		return
	end
	if not IsValid(ent) or ent.Removing or ent:IsMarkedForDeletion() or ent:GetProp() ~= self then
		if self.ZSGhostController == ent then self.ZSGhostController = nil end
		if IsValid(ent) and (ent.Removing or ent:IsMarkedForDeletion() or not IsValid(ent:GetProp())) then ent:Remove() end
		ent = nil
		for _, candidate in ipairs(GAMEMODE:GetZSEquipmentEntities("point_propnocollide")) do
			if IsValid(candidate) and not candidate.Removing and not candidate:IsMarkedForDeletion() and candidate:GetProp() == self then ent = candidate break end
		end
	end
	if not ent then return end
	self.ZSGhostController = ent
	if not allowrepeat then self.GhostedBefore = true end
	return ent
end

function meta:AddUselessDamage(damage)
	if not FiniteHealingNumber(damage) or damage < 0 then return end
	local debt = self.UselessDamage or 0
	if not FiniteHealingNumber(debt) or debt < 0 then debt = 0 end
	local total = debt + damage
	if FiniteHealingNumber(total) then self.UselessDamage = total end
end

function meta:RemoveUselessDamage(damage)
	if not FiniteHealingNumber(damage) or damage < 0 then return 0 end
	local debt = self.UselessDamage
	if not FiniteHealingNumber(debt) or debt < 0 then return 0 end
	damage = math.min(debt, damage)
	self.UselessDamage = debt - damage
	return damage
end

function meta:ClearUselessDamage()
	self.UselessDamage = nil
end

function meta:ItemCreated()
	self.Created = self.Created or CurTime()
	GAMEMODE:QueueDroppedItemCleanup()
end

function meta:IsNailed()
	if self:IsValid() and self.Nails then -- In case we're the world.
		for _, nail in pairs(self.Nails) do
			if nail and nail:IsValid() and (nail:GetAttachEntity() == self or nail:GetBaseEntity() == self) then
				return true
			end
		end
	end

	return false
end

function meta:IsNailedToWorld(hierarchy)
	if self.Nails then
		for _, nail in pairs(self.Nails) do
			if IsValid(nail) then
				local base, attached = nail:GetBaseEntity(), nail:GetAttachEntity()
				if (base == self or attached == self) and attached and attached:IsWorld() then return true end
			end
		end
	end
	if hierarchy then
		for ent in pairs(constraint.GetAllConstrainedEntities(self) or {}) do
			if ent ~= self and IsValid(ent) and ent:IsNailedToWorld() then return true end
		end
	end
	return false
end

function meta:IsNailedToWorldHierarchy()
	return self:IsNailedToWorld(true)
end

function meta:GetNailFrozen()
	return self.m_NailFrozen
end
meta.IsNailFrozen = meta.GetNailFrozen

function meta:SetNailFrozen(frozen)
	if frozen then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() and phys:IsMoveable() then
			self.m_NailFrozen = true
			phys:EnableMotion(false)
		end
	elseif self:IsNailFrozen() then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			self.m_NailFrozen = false
			phys:EnableMotion(true)
			phys:Wake()
		end
	end
end

function constraint.GetAllConstrainedEntitiesOrdered(ent)
	local allcons = constraint.GetAllConstrainedEntities(ent)

	local tab = {}

	if allcons then
		for k, v in pairs(allcons) do
			tab[#tab + 1] = v
		end
	end

	return tab
end

function meta:GetAllConstrainedEntities()
	local allcons = constraint.GetAllConstrainedEntitiesOrdered(self)
	if not allcons or #allcons == 0 then
		return {self}
	end

	return allcons
end

function meta:PackUp(pl)
	if not IsValid(self) or not self.CanPackUp or not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN then return end

	local cur = pl:GetStatus("packup")
	if cur and cur:IsValid() then return end

	local status = pl:GiveStatus("packup")
	if IsValid(status) then
		if not IsValid(self) or not IsValid(pl) then status:Remove() return end
		status:SetPackUpEntity(self)
		status:SetEndTime(CurTime() + (self.PackUpTime or 4))

		if self.GetObjectOwner then
			local owner = self:GetObjectOwner()
			if IsValid(owner) and owner:IsPlayer() and owner:Team() ~= TEAM_UNDEAD and owner ~= pl and not gamemode.Call("PlayerIsAdmin", pl) then
				status:SetNotOwner(true)
			end
		end
	end
end

function meta:SigilTeleport(pl)
	if not IsValid(self) or not IsValid(pl) or not pl:IsPlayer() or pl:Team() ~= TEAM_SURVIVOR or not pl:Alive() or pl:GetBarricadeGhosting() or pl.ZSReturns and pl.ZSReturns.divinehatred then return end
	
	local cur = pl:GetStatus("sigil_teleport")
	if cur and cur:IsValid() then return end

	local status = pl:GiveStatus("sigil_teleport")
	if IsValid(status) then
		if not IsValid(self) or not IsValid(pl) then status:Remove() return end
		status:SetCurrentSigil(self)
		status:SetEndTime(CurTime() + (pl.FastTeleport and GAMEMODE.SigilTeleportTimeTrait or GAMEMODE.SigilTeleportTime))
	end
end

function meta:GetPropsInContraption()
	local count = 0
	for ent in pairs(constraint.GetAllConstrainedEntities(self) or {}) do
		if IsValid(ent) and not ent:IsWorld() then count = count + 1 end
	end
	return math.max(1, count)
end

function meta:HumanNearby()
	for _, pl in player.Iterator() do
		if pl:Team() == TEAM_HUMAN and pl:Alive() then
			local plpos = pl:GetPos()
			if self:NearestPoint(plpos):DistToSqr(plpos) <= 512 * 512 then return true end
		end
	end
end

function meta:ResetLastBarricadeAttacker(attacker, dmginfo)
	if attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD then
		self.m_LastDamagedByZombie = CurTime()

		if self:HumanNearby() then
			local dmg = math.ceil(dmginfo:GetDamage())
			attacker.BarricadeDamage = attacker.BarricadeDamage + dmg
			if attacker.LifeBarricadeDamage ~= nil then
				attacker:AddLifeBarricadeDamage(dmg)
			end
			if attacker:GetZombieClassTable().Name == "Crow" then
				attacker.CrowBarricadeDamage = attacker.CrowBarricadeDamage + dmg
			end
		end
	end
end

meta.OldSetPhysicsAttacker = meta.OldSetPhysicsAttacker or meta.SetPhysicsAttacker
function meta:SetPhysicsAttacker(ent)
	if string.sub(self:GetClass(), 1, 12) == "func_physbox" and ent:IsValid() then
		self.PBAttacker = ent
		self.NPBAttacker = CurTime() + 5
	end
	self:OldSetPhysicsAttacker(ent)
end

-- Return true to override default behavior.
function meta:DamageNails(attacker, inflictor, damage, dmginfo)
	if not self:IsNailed() or self.m_NailsDontAbsorb then return end

	-- Props that don't have barricade health yet might still be nailed to something.
	local nails = self:GetLivingNails()
	if self:GetBarricadeHealth() <= 0 then
		local isattach = false
		for _, nail in ipairs(nails) do
			if self == nail:GetAttachEntity() then isattach = true break end
		end
		if not isattach then return end
	end

	if not gamemode.Call("CanDamageNail", self, attacker, inflictor, damage, dmginfo) then
		if dmginfo then
			dmginfo:SetDamage(0)
			dmginfo:SetDamageType(DMG_GENERIC)
		end

		return true
	end

	-- No physics damage to props. Stops ramming/thrown weapons damaging them.
	if damage < 0 or bit.band(dmginfo:GetDamageType(), DMG_CRUSH) ~= 0 then
		if dmginfo then
			dmginfo:SetDamage(0)
		end

		return true
	end

	if gamemode.Call("IsEscapeDoorOpen") then
		local multi = gamemode.Call("GetEscapeStage") * 1.5

		dmginfo:SetDamage(dmginfo:GetDamage() * multi)
		damage = damage * multi
	end

	self:ResetLastBarricadeAttacker(attacker, dmginfo)

	if #nails <= 0 then return end
	local health = self:GetBarricadeHealth()
	if health > 0 and damage >= health and damage < math.huge then GAMEMODE:TriggerTraitExplosiveTouch(self, attacker, nails) end
	self:SetBarricadeHealth(health - damage)
	for i, nail in ipairs(nails) do
		nail:OnDamaged(damage, attacker, inflictor, dmginfo)
	end

	-- No points for repairing damage from fire, trigger_hurt, etc.
	if not attacker:IsZombie() then
		self:AddUselessDamage(damage)
	else
		GAMEMODE:DamageFloater(attacker, self, dmginfo)
	end

	attacker.LastBarricadeHit = CurTime()

	if dmginfo then dmginfo:SetDamage(0) end

	if self:GetBarricadeHealth() <= 0 then
		if self:GetModel() ~= "" and self:GetModel() ~= "models/error.mdl" then
			if self:GetName() == "" and self:GetVolume() < 100 then
				self:Fire("break", "", 0.01)
				self:Fire("kill", "", 0.05)
			else
				local ent = ents.Create("env_propbroken")
				if ent:IsValid() then
					ent:Spawn()
					ent:AttachTo(self)
				end
			end
		end

		for _, nail in pairs(nails) do
			self:RemoveNail(nail, nil, nil, true)
		end
	end

	return true
end

function meta:GetNails()
	local tab = {}

	if self.Nails then
		for _, nail in pairs(self.Nails) do
			if nail and nail:IsValid() then
				tab[#tab + 1] = nail
			end
		end
	end

	return tab
end

function meta:GetLivingNails()
	local tab = {}

	if self.Nails then
		for _, nail in pairs(self.Nails) do
			if nail and nail:IsValid() and nail:GetNailHealth() > 0 then
				tab[#tab + 1] = nail
			end
		end
	end

	return tab
end

function meta:NumLivingNails(limit)
	local amount = 0
	if limit and limit <= 0 then return 0 end

	if self.Nails then
		for _, nail in pairs(self.Nails) do
			if nail and nail:IsValid() and nail:GetNailHealth() > 0 then
				amount = amount + 1
				if limit and amount >= limit then return amount end
			end
		end
	end

	return amount
end

function meta:GetFirstNail()
	if self.Nails then
		for i, nail in ipairs(self.Nails) do
			if nail and nail:IsValid() and not nail:GetAttachEntity():IsValid() then return nail end
		end
		for i, nail in ipairs(self.Nails) do
			if nail and nail:IsValid() then return nail end
		end
	end
end

local function GetNailOwner(nail, filter)
	local ent = nail:GetBaseEntity()
	if ent and ent ~= filter and ent.Nails and ent:IsValid() then
		for _, candidate in pairs(ent.Nails) do
			if candidate == nail then return ent end
		end
	end
	ent = nail:GetAttachEntity()
	if ent and ent ~= filter and ent.Nails and ent:IsValid() then
		for _, candidate in pairs(ent.Nails) do
			if candidate == nail then return ent end
		end
	end
	return game.GetWorld()
end

function meta:RemoveNail(nail, dontremoveentity, removedby, forceremoveconstraint)
	if not self:IsNailed() then return end

	if not nail then
		nail = self:GetFirstNail()
	end

	if not nail or not nail:IsValid() then return end

	if nail.m_IsRemoving then return end
	local attached = false
	for _, candidate in ipairs(self.Nails or {}) do
		if candidate == nail then attached = true break end
	end
	if not attached then return end

	local cons = nail:GetNailConstraint()
	local othernails = 0
	if not forceremoveconstraint then
		for _, othernail in pairs(self.Nails or {}) do
			if othernail ~= nail and IsValid(othernail) and not othernail.m_IsRemoving and othernail:GetNailConstraint() == cons then
				othernails = 1
				break
			end
		end
	end

	-- Only remove the constraint if it's the last nail.
	if othernails == 0 and cons:IsValid() then
		if self.PropHealth and self:GetBarricadeHealth() > 0 then
			local repairs_frac = self:GetBarricadeRepairs() / self:GetMaxBarricadeRepairs()

			if repairs_frac < 0.5 then
				self.PropHealth = math.min(self.PropHealth, self:GetBarricadeHealth())

				local brit = math.Clamp(self.PropHealth / self.TotalHealth, 0, 1)
				local col = self:GetColor()
				col.r = 255
				col.g = 255 * brit
				col.b = 255 * brit
				self:SetColor(col)
			end
		end
		cons:Remove()
	end

	local ent2 = GetNailOwner(nail, self)

	for i, n in ipairs(self.Nails) do
		if n == nail then
			table.remove(self.Nails, i)
			break
		end
	end

	if ent2 and ent2.Nails then
		for i, n in ipairs(ent2.Nails) do
			if n == nail then
				table.remove(ent2.Nails, i)
				ent2:TemporaryBarricadeObject()
				break
			end
		end
	end

	self:TemporaryBarricadeObject()

	gamemode.Call("OnNailRemoved", nail, self, ent2, removedby)

	if not dontremoveentity then
		nail.m_IsRemoving = true
		nail:Remove()
	end

	self:RecalculateNailBonuses()
	if not self:IsWorld() then self:SetIsNailed(self:IsNailed()) end
	if ent2 and ent2:IsValid() and not ent2:IsWorld() then ent2:SetIsNailed(ent2:IsNailed()) end
	self:CollisionRulesChanged()

	if ent2 and ent2:IsValid() then
		ent2:CollisionRulesChanged()
	end

	return true
end

function meta:RemoveNextFrame(time)
	self.Removing = true
	self:Fire("kill", "", time or 0.01)
end

function meta:SetIsNailed(IsNailed)
	self:SetNWBool("IsNailed", IsNailed)
	GAMEMODE:SyncBarricadeGhostPropEligibility(self)
end

function meta:RecalculateNailBonuses()
	local max_health = self:GetMaxBarricadeHealth()
	if max_health == 0 then return end

	local num_extra_nails = math.Clamp(self:NumLivingNails(4) - 1, 0, 3)
	self.OriginalMaxHealth = self.OriginalMaxHealth or max_health
	local new_max_health = self.OriginalMaxHealth + num_extra_nails * GAMEMODE.ExtraHealthPerExtraNail
	if new_max_health == max_health or self.ZSLastNailBonusTarget == new_max_health and self.ZSLastNailBonusMaximum == max_health then return end
	local max_repairs = self:GetMaxBarricadeRepairs()
	local repairs_frac = max_repairs > 0 and self:GetBarricadeRepairs() / max_repairs or 0
	local health = self:GetBarricadeHealth()
	self:SetMaxBarricadeHealth(new_max_health)
	self:SetBarricadeHealth(health / max_health * new_max_health)

	self:SetBarricadeRepairs(repairs_frac * self:GetMaxBarricadeRepairs())
	self.ZSLastNailBonusTarget = new_max_health
	self.ZSLastNailBonusMaximum = self:GetMaxBarricadeHealth()
end

timer.Remove("CachedInvisibleEntities")
GM.CachedInvisibleEntities = nil
