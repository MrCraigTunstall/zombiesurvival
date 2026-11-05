local entityMeta = FindMetaTable("Entity")
local EntityValid, NearestPoint = entityMeta.IsValid, entityMeta.NearestPoint

local function Finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function Blast(inflictor, attacker, origin, radius, damage, kind, mode, ignored)
	local output = (mode == "allocate" or mode == "collect") and {} or nil
	if not SERVER or not IsValid(inflictor) or not IsValid(attacker) or not isvector(origin)
		or not Finite(origin.x) or not Finite(origin.y) or not Finite(origin.z) or not Finite(radius) or radius <= 0 then return output or 0 end
	if mode ~= "collect" then
		if not Finite(damage) or damage <= 0 then return output or 0 end
		if kind and bit.band(kind, DMG_BLAST) ~= 0 then damage = damage * GAMEMODE:GetTraitBlastScale(attacker, inflictor) end
		if not Finite(damage) then return output or 0 end
	end
	ignored = IsValid(ignored) and ignored or nil
	local inverse, count = 1 / radius, 0
	local fallback = mode == "allocate" or mode == "collect"
	local collect, exclude = mode == "collect", mode == "exclude"
	local entities = ents.FindInSphere(origin, radius)
	if not exclude then
		for index, ent in ipairs(entities) do
			if ent == attacker then table.insert(entities, table.remove(entities, index)); break end
		end
	end
	for _, ent in ipairs(entities) do
		if (not exclude or ent ~= attacker and ent ~= inflictor) and ent ~= ignored and EntityValid(ent) then
			local nearest = NearestPoint(ent, origin)
			local distance = nearest:Distance(origin)
			if distance < radius then
				local visible
				if fallback then
					visible = TrueVisibleFilters(origin, nearest, inflictor, attacker, ent)
						or TrueVisibleFilters(origin, ent:EyePos(), inflictor, attacker, ent)
						or TrueVisibleFilters(origin, ent:WorldSpaceCenter(), inflictor, attacker, ent)
				elseif ignored then visible = TrueVisibleFilters(origin, nearest, inflictor, ent, ignored)
				else visible = TrueVisibleFilters(origin, nearest, inflictor, ent) end
				if visible then
					if collect then output[#output + 1] = ent
					else
						local amount = (1 - distance * inverse) * damage
						ent:TakeSpecialDamage(amount, kind, attacker, inflictor, nearest)
						if output then output[ent] = amount end
					end
					count = count + 1
				end
			end
		end
	end
	return output or count
end

function util.BlastDamageEx(inflictor, attacker, origin, radius, damage, kind)
	return Blast(inflictor, attacker, origin, radius, damage, kind)
end

function util.BlastDamage2(inflictor, attacker, origin, radius, damage, ignored)
	return Blast(inflictor, attacker, origin, radius, damage, DMG_BLAST, nil, ignored)
end

function util.BlastDamageNoAttacker(inflictor, attacker, origin, radius, damage)
	return Blast(inflictor, attacker, origin, radius, damage, DMG_BLAST, "exclude")
end

function util.BlastDamageExAlloc(inflictor, attacker, origin, radius, damage, kind)
	return Blast(inflictor, attacker, origin, radius, damage, kind, "allocate")
end

function util.BlastAlloc(inflictor, attacker, origin, radius)
	return Blast(inflictor, attacker, origin, radius, nil, nil, "collect")
end

function util.BlastBulletDamage(info, attacker, origin, radius, fallback)
	if not SERVER or not IsValid(attacker) or not attacker:IsPlayer() then return 0 end
	local source = info:GetInflictor()
	if not IsValid(source) or not source:IsWeapon() or source:GetOwner() ~= attacker then return 0 end
	local amount = source.ExplosionDamage or fallback
	if not Finite(amount) or amount <= 0 or not Finite(radius) or radius <= 0 or not isvector(origin)
		or not Finite(origin.x) or not Finite(origin.y) or not Finite(origin.z) then return 0 end
	local damage, base, bonus, custom = info:GetDamage(), info:GetBaseDamage(), info:GetDamageBonus(), info:GetDamageCustom()
	local kind, ammo, maximum = info:GetDamageType(), info:GetAmmoType(), info:GetMaxDamage()
	local force, position, reported = info:GetDamageForce(), info:GetDamagePosition(), info:GetReportedPosition()
	local originalAttacker, weapon = info:GetAttacker(), info:GetWeapon()
	local ok, count = pcall(Blast, source, attacker, origin, radius, amount, DMG_BLAST)
	DamageInfo()
	info:SetDamage(damage); info:SetBaseDamage(base); info:SetDamageBonus(bonus); info:SetDamageCustom(custom)
	info:SetDamageType(kind); info:SetAmmoType(ammo); info:SetMaxDamage(maximum)
	info:SetDamageForce(force); info:SetDamagePosition(position); info:SetReportedPosition(reported)
	info:SetAttacker(IsValid(originalAttacker) and originalAttacker or game.GetWorld())
	info:SetInflictor(IsValid(source) and source or game.GetWorld())
	if IsValid(weapon) then info:SetWeapon(weapon) end
	if not ok then ErrorNoHalt("ZS explosive bullet: " .. tostring(count) .. "\n"); return 0 end
	return count
end
