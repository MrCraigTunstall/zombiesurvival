function GM:CanRemoveOthersNail(pl, nailowner, ent)
	local required = GetConVar("zs_barricade_expert_level"):GetInt()
	local ownerLevel = nailowner:GetZSLevel()
	if required > 0 and ownerLevel >= required then
		if pl:GetZSLevel() >= ownerLevel then return true end
		pl:NotifyNailRemovalDenied("cant_remove_barricade_expert_nail")
		return false
	end
	local plpoints = pl:Frags()
	local ownerpoints = nailowner:Frags()
	if plpoints >= 75 or ownerpoints < 75 then return true end

	pl:NotifyNailRemovalDenied("cant_remove_nails_of_superior_player")

	return false
end

function GM:CanDamageNail(ent, attacker, inflictor, damage, dmginfo)
	return not attacker:IsPlayer() or attacker:Team() == TEAM_UNDEAD
end

function GM:CanPlaceNail(pl, tr)
	return true
end

function GM:CanRemoveNail(pl, nail)
	if nail.m_NailUnremovable then
		return false
	else
		return true
	end
end
