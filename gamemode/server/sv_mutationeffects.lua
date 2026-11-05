function GM:ApplyMutationDamage(ent, info)
	if not ent or not (ent.m_Zombie_Armor or ent.m_Zombie_Tough) or not IsValid(ent)
		or not ent:IsPlayer() or not ent:Alive() or ent:Team() ~= TEAM_UNDEAD or self.RoundEnded then return end
	local damage = info:GetDamage()
	if damage <= 0 or damage ~= damage or damage == math.huge then return end
	local multiplier = ent.m_Zombie_Armor and 0.85 or 1
	if ent.m_Zombie_Tough then multiplier = multiplier * 0.75 end
	info:ScaleDamage(multiplier)
end

hook.Add("EntityTakeDamage", "ZSMutationEffects", function(ent, info)
	GAMEMODE:ApplyMutationDamage(ent, info)
end)

function GM:StopMutationSprintOnDamage(ent, info, taken)
	if not taken or not ent or not ent.m_Zombie_Moan or ent.m_Zombie_MoanGuard
		or not IsValid(ent) or not ent:IsPlayer() or not ent:Alive()
		or ent:Team() ~= TEAM_UNDEAD or self.RoundEnded then return end
	local damage = info:GetDamage()
	if damage <= 0 or damage ~= damage or damage == math.huge then return end
	local weapon = ent:GetActiveWeapon()
	if not IsValid(weapon) or not weapon.IsMoaning or not weapon.StopMoaning
		or not weapon.SetNextSecondaryFire or not weapon:IsMoaning() then return end
	weapon:SetNextSecondaryFire(CurTime() + 1)
	weapon:StopMoaning(true)
end

hook.Add("PostEntityTakeDamage", "ZSMutationSprint", function(ent, info, taken)
	GAMEMODE:StopMutationSprintOnDamage(ent, info, taken)
end)
