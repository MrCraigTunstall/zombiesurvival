local function Owner(gm, pl)
	return IsValid(pl) and pl:IsPlayer() and pl:Team() == TEAM_HUMAN and gm:HasPlayerTrait(pl, "explosivetouch")
end

function GM:TriggerTraitExplosiveTouch(ent, attacker, nails)
	if self.RoundEnded or not IsValid(ent) or ent.ZSTraitExplosiveTouch or not IsValid(attacker)
		or not attacker:IsPlayer() or attacker:Team() ~= TEAM_UNDEAD then return false end
	local owner
	if nails then
		for i = 1, #nails do
			local nail = nails[i]
			if IsValid(nail) and nail:GetBaseEntity() == ent then
				local deployer = nail:GetDeployer()
				if Owner(self, deployer) and (not owner or deployer:EntIndex() < owner:EntIndex()) then owner = deployer end
			end
		end
	else
		owner = ent.GetObjectOwner and ent:GetObjectOwner() or ent:GetOwner()
		if not Owner(self, owner) then
			owner = ent:GetOwner()
			if not Owner(self, owner) then return false end
		end
	end
	if not owner then return false end
	local origin = ent:WorldSpaceCenter()
	local x, y, z = origin.x, origin.y, origin.z
	if x ~= x or y ~= y or z ~= z or math.abs(x) == math.huge or math.abs(y) == math.huge or math.abs(z) == math.huge then return false end
	ent.ZSTraitExplosiveTouch = true
	timer.Simple(0, function()
		if self.RoundEnded or not Owner(self, owner) then return end
		local source = ents.Create("info_target")
		if not IsValid(source) then return end
		local ok, failure = xpcall(function()
			local position = Vector(x, y, z)
			source:SetPos(position)
			source:SetOwner(owner)
			source.TraitExplosive = true
			source:Spawn()
			util.BlastDamage2(source, owner, position, 256, 256, ent)
			local effect = EffectData()
			effect:SetOrigin(position)
			util.Effect("Explosion", effect)
		end, debug.traceback)
		source:Remove()
		if not ok then ErrorNoHalt("ZS Explosive Touch: " .. tostring(failure) .. "\n") end
	end)
	return true
end

function GM:DamageTraitObject(ent, info)
	local health, damage = ent:GetObjectHealth(), info:GetDamage()
	if health > 0 and damage >= health and damage < math.huge then
		self:TriggerTraitExplosiveTouch(ent, info:GetAttacker())
	end
	ent:SetObjectHealth(health - damage)
end
