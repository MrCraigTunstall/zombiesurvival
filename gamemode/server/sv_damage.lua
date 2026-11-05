function GM:ShouldAntiGrief(ent, attacker, dmginfo, health)
	return ent.m_AntiGrief and self.GriefMinimumHealth <= health and attacker:IsPlayer() and attacker:Team() ~= TEAM_UNDEAD and not dmginfo:IsExplosionDamage()
end

function GM:PropBreak(attacker, ent)
	gamemode.Call("PropBroken", ent, attacker)
end

function GM:PropBroken(ent, attacker)
end

function GM:NestDestroyed(ent, attacker)
end

function GM:EntityTakeDamage(ent, dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	local fireOwner = inflictor.ZSMolotovOwner
	if fireOwner and IsValid(fireOwner) and fireOwner:IsValidHuman() then dmginfo:SetAttacker(fireOwner); attacker = fireOwner end
	if inflictor.ZSCrafter then self:ApplyCraftDamage(dmginfo, attacker, inflictor) end

	if attacker == inflictor and attacker:IsProjectile() and dmginfo:GetDamageType() == DMG_CRUSH then
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return
	end

	if ent._BARRICADEBROKEN and not (attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD) then
		dmginfo:SetDamage(dmginfo:GetDamage() * 3)
	end

	if ent.GetObjectHealth and not (attacker:IsPlayer() and attacker:Team() ~= TEAM_UNDEAD) then
		ent.m_LastDamaged = CurTime()
	end

	if ent.ProcessDamage and ent:ProcessDamage(dmginfo) then return end
	attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()


	if self:GetWave() <= 0 and string.sub(ent:GetClass(), 1, 12) == "prop_physics" and inflictor.NoPropDamageDuringWave0 then
		dmginfo:SetDamage(0)
		dmginfo:SetDamageType(DMG_BULLET)
		return
	end


	if inflictor:IsValid() then
		local dmgtype = dmginfo:GetDamageType()
		if ent:IsPlayer() and (dmgtype == DMG_ALWAYSGIB or dmgtype == DMG_BURN or dmgtype == DMG_SLOWBURN) and string.sub(inflictor:GetClass(), 1, 12) == "prop_physics" then
			if inflictor.LastDamagedByTeam == ent:Team() and inflictor.LastDamagedBy ~= ent then
				dmginfo:SetDamage(0)
				dmginfo:ScaleDamage(0)
				return
			end
		elseif string.sub(ent:GetClass(), 1, 12) == "prop_physics" then
			if inflictor:IsPlayer() then
				ent.LastDamagedByTeam = inflictor:Team()
				ent.LastDamagedBy = inflictor
			elseif (dmgtype == DMG_ALWAYSGIB or dmgtype == DMG_BURN or dmgtype == DMG_SLOWBURN) and string.sub(inflictor:GetClass(), 1, 12) == "prop_physics" then
				if inflictor.LastDamagedByTeam then
					ent.LastDamagedByTeam = inflictor.LastDamagedByTeam
					ent.LastDamagedBy = inflictor.LastDamagedBy
				end
			end
		end
	end


	if ent:DamageNails(attacker, inflictor, dmginfo:GetDamage(), dmginfo) then return end

	local dispatchdamagedisplay = false

	local entclass = ent:GetClass()

	if ent:IsPlayer() then
		dispatchdamagedisplay = true
		elseif self.ZombieEscape then
	elseif ent.PropHealth then
		if self.NoPropDamageFromHumanMelee and attacker:IsPlayer() and attacker:Team() ~= TEAM_UNDEAD and inflictor.IsMelee then
			dmginfo:SetDamage(0)
			return
		end

		if gamemode.Call("ShouldAntiGrief", ent, attacker, dmginfo, ent.PropHealth) then
			attacker:AntiGrief(dmginfo)
			if dmginfo:GetDamage() <= 0 then return end
		end

		ent.PropHealth = ent.PropHealth - dmginfo:GetDamage()

		dispatchdamagedisplay = true

		if ent.PropHealth <= 0 then
			local effectdata = EffectData()
				effectdata:SetOrigin(ent:GetPos())
			util.Effect("Explosion", effectdata, true, true)
			ent:Fire("break")

			gamemode.Call("PropBroken", ent, attacker)
		else
			local brit = math.Clamp(ent.PropHealth / ent.TotalHealth, 0, 1)
			local col = ent:GetColor()
			col.r = 255
			col.g = 255 * brit
			col.b = 255 * brit
			ent:SetColor(col)
		end
	elseif entclass == "func_door_rotating" then
		if ent:GetKeyValues().damagefilter == "invul" or ent.Broken then return end

		if not ent.Heal then
			local br = ent:BoundingRadius()
			if br > 80 then return end

			local health = br * 35
			ent.Heal = health
			ent.TotalHeal = health
		end

		if gamemode.Call("ShouldAntiGrief", ent, attacker, dmginfo, ent.TotalHeal) then
			attacker:AntiGrief(dmginfo)
			if dmginfo:GetDamage() <= 0 then return end
		end

		if dmginfo:GetDamage() >= 20 and attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD then
			ent:EmitSound(math.random(2) == 1 and "npc/zombie/zombie_pound_door.wav" or "ambient/materials/door_hit1.wav")
		end

		ent.Heal = ent.Heal - dmginfo:GetDamage()
		local brit = math.Clamp(ent.Heal / ent.TotalHeal, 0, 1)
		local col = ent:GetColor()
		col.r = 255
		col.g = 255 * brit
		col.b = 255 * brit
		ent:SetColor(col)

		dispatchdamagedisplay = true

		if ent.Heal <= 0 then
			ent.Broken = true

			ent:EmitSound("Breakable.Metal")
			ent:Fire("unlock", "", 0)
			ent:Fire("open", "", 0.01)
			ent:Fire("break", "", 0.1)
			ent:Fire("kill", "", 0.15)
		end
	elseif entclass == "prop_door_rotating" then
		if ent:GetKeyValues().damagefilter == "invul" or ent:HasSpawnFlags(2048) or ent.Broken then return end

		ent.Heal = ent.Heal or ent:BoundingRadius() * 35
		ent.TotalHeal = ent.TotalHeal or ent.Heal

		if gamemode.Call("ShouldAntiGrief", ent, attacker, dmginfo, ent.TotalHeal) then
			attacker:AntiGrief(dmginfo)
			if dmginfo:GetDamage() <= 0 then return end
		end

		if dmginfo:GetDamage() >= 20 and attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD then
			ent:EmitSound(math.random(2) == 1 and "npc/zombie/zombie_pound_door.wav" or "ambient/materials/door_hit1.wav")
		end

		ent.Heal = ent.Heal - dmginfo:GetDamage()
		local brit = math.Clamp(ent.Heal / ent.TotalHeal, 0, 1)
		local col = ent:GetColor()
		col.r = 255
		col.g = 255 * brit
		col.b = 255 * brit
		ent:SetColor(col)

		dispatchdamagedisplay = true

		if ent.Heal <= 0 then
			ent.Broken = true

			ent:EmitSound("Breakable.Metal")
			ent:Fire("unlock", "", 0)
			ent:Fire("open", "", 0.01)
			ent:Fire("break", "", 0.1)
			ent:Fire("kill", "", 0.15)

			local physprop = ents.Create("prop_physics")
			if physprop:IsValid() then
				physprop:SetPos(ent:GetPos())
				physprop:SetAngles(ent:GetAngles())
				physprop:SetSkin(ent:GetSkin() or 0)
				physprop:SetMaterial(ent:GetMaterial())
				physprop:SetModel(ent:GetModel())
				physprop:Spawn()
				physprop:SetPhysicsAttacker(attacker)
				if attacker:IsValid() then
					local phys = physprop:GetPhysicsObject()
					if phys:IsValid() then
						phys:SetVelocityInstantaneous((physprop:NearestPoint(attacker:EyePos()) - attacker:EyePos()):GetNormalized() * math.Clamp(dmginfo:GetDamage() * 3, 40, 300))
					end
				end
				if physprop:GetMaxHealth() == 1 and physprop:Health() == 0 then
					local health = math.ceil((physprop:OBBMins():Length() + physprop:OBBMaxs():Length()) * 2)
					if health < 2000 then
						physprop.PropHealth = health
						physprop.TotalHealth = health
					end
				end
			end
		end
	elseif string.sub(entclass, 1, 12) == "func_physbox" then
		local holder, status = ent:GetHolder()
		if holder then status:Remove() end

		if ent:GetKeyValues().damagefilter == "invul" then return end

		ent.Heal = ent.Heal or ent:BoundingRadius() * 35
		ent.TotalHeal = ent.TotalHeal or ent.Heal

		if gamemode.Call("ShouldAntiGrief", ent, attacker, dmginfo, ent.TotalHeal) then
			attacker:AntiGrief(dmginfo)
			if dmginfo:GetDamage() <= 0 then return end
		end

		ent.Heal = ent.Heal - dmginfo:GetDamage()
		local brit = math.Clamp(ent.Heal / ent.TotalHeal, 0, 1)
		local col = ent:GetColor()
		col.r = 255
		col.g = 255 * brit
		col.b = 255 * brit
		ent:SetColor(col)

		dispatchdamagedisplay = true

		if ent.Heal <= 0 then
			local foundaxis = false
			local entname = ent:GetName()
			local allaxis = ents.FindByClass("phys_hinge")
			for _, axis in pairs(allaxis) do
				local keyvalues = axis:GetKeyValues()
				if keyvalues.attach1 == entname or keyvalues.attach2 == entname then
					foundaxis = true
					axis:Remove()
					ent.Heal = ent.Heal + 120
				end
			end

			if not foundaxis then
				ent:Fire("break", "", 0)
			end
		end
	elseif entclass == "func_breakable" then
		if ent:GetKeyValues().damagefilter == "invul" then return end

		if gamemode.Call("ShouldAntiGrief", ent, attacker, dmginfo, ent:GetMaxHealth()) then
			attacker:AntiGrief(dmginfo, true)
			if dmginfo:GetDamage() <= 0 then return end
		end

		if ent:Health() == 0 and ent:GetMaxHealth() == 1 then return end

		local brit = math.Clamp(ent:Health() / ent:GetMaxHealth(), 0, 1)
		local col = ent:GetColor()
		col.r = 255
		col.g = 255 * brit
		col.b = 255 * brit
		ent:SetColor(col)

		dispatchdamagedisplay = true
	elseif ent:IsBarricadeProp() and attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD then
		dispatchdamagedisplay = true
	end

	if dmginfo:GetDamage() > 0 or ent:IsPlayer() and ent:GetZombieClassTable().Name == "Shade" then
		local holder, status = ent:GetHolder()
		if holder then status:Remove() end

		if attacker:IsPlayer() and dispatchdamagedisplay then
			self:DamageFloater(attacker, ent, dmginfo)
		end
	end
end

function GM:DamageFloater(attacker, victim, dmginfo)
	if attacker:IsBot() then INFDAMAGEFLOATER = nil return end
	local dmgpos = dmginfo:GetDamagePosition()
	if dmgpos == vector_origin then dmgpos = victim:NearestPoint(attacker:EyePos()) end

	net.Start(victim:IsPlayer() and "zs_dmg" or "zs_dmg_prop")
		if INFDAMAGEFLOATER then
			INFDAMAGEFLOATER = nil
			net.WriteUInt(9999, 16)
		else
			net.WriteUInt(math.ceil(dmginfo:GetDamage()), 16)
		end
		net.WriteVector(dmgpos)
	net.Send(attacker)
end

function GM:PlayerShouldTakeDamage(pl, attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then
		attacker = attacker.PBAttacker
	end

	if attacker:IsPlayer() and attacker ~= pl and not attacker.AllowTeamDamage and not pl.AllowTeamDamage and attacker:Team() == pl:Team() then return false end

	return true
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
	if healthremaining > 0 then
		if victim:Team() == TEAM_UNDEAD then victim:PlayZombiePainSound()
		else victim:PlayPainSound() end
		if victim:Team() ~= TEAM_UNDEAD then
			victim.BonusDamageCheck = CurTime()
			if healthremaining < 75 then victim:ResetSpeed(nil, healthremaining) end
		end
	end

	damage = math.max(0, math.min(damage, victim.m_PreHurtHealth or damage + math.max(0, healthremaining)))
	victim.m_PreHurtHealth = math.max(0, healthremaining)
	if not IsValid(attacker) then return end
	if attacker:IsPlayer() then
		victim:SetLastAttacker(attacker)
		local myteam, otherteam = attacker:Team(), victim:Team()
		if myteam == otherteam then return end
		attacker.DamageDealt = attacker.DamageDealt or {}
		attacker.DamageDealt[myteam] = (attacker.DamageDealt[myteam] or 0) + damage
		if myteam == TEAM_UNDEAD then
			if otherteam == TEAM_HUMAN or otherteam == TEAM_REDEEMER then
				attacker:AddLifeHumanDamage(damage)
				attacker:AddTokens(math.ceil(damage * 3))
			end
		else
			self:QueueZombieDamagePoints(attacker, victim, damage, healthremaining)
		end
	elseif attacker:GetClass() == "trigger_hurt" then
		victim.LastHitWithTriggerHurt = CurTime()
	end
end

