function GM:QueueZombieDamagePoints(attacker, victim, damage, healthremaining)
	local attackerTeam = attacker:Team()
	if self.RoundEnded or (attackerTeam ~= TEAM_HUMAN and attackerTeam ~= TEAM_REDEEMER)
	or victim:Team() ~= TEAM_UNDEAD or damage <= 0 then return false end
	victim.DamagedBy = victim.DamagedBy or {}
	victim.DamagedBy[attacker] = (victim.DamagedBy[attacker] or 0) + damage
	local now = CurTime()
	if (not victim.m_LastWaveStartSpawn or now >= victim.m_LastWaveStartSpawn + 3)
	and (healthremaining <= 0 or not victim.m_LastGasHeal or now >= victim.m_LastGasHeal + 2) then
		local points = victim:GetZombieClassTable().Points or 0
		attacker.m_PointQueue = (attacker.m_PointQueue or 0) + damage / math.max(1, victim:GetMaxHealth()) * points
	end
	attacker.m_LastDamageDealtPosition = victim:GetPos()
	attacker.m_LastDamageDealt = now
	return true
end

function GM:FlushCombatPoints(pl, now)
	if (pl.m_PointQueue or 0) >= 1 and now >= (pl.m_LastDamageDealt or 0) + 3 then
		pl:PointCashOut(pl.m_LastDamageDealtPosition or pl:GetPos(), FM_NONE)
	end
end

function GM:PlayerHealedTeamMember(pl, other, health, wep)
	health = health - other:RemoveUselessDamage(health)
	if self:GetWave() == 0 or health <= 0 or pl == other then return end

	self:AddProgressionXP(pl, health / 25)
	pl.HealedThisRound = pl.HealedThisRound + health
	pl.CarryOverHealth = (pl.CarryOverHealth or 0) + health

	local hpperpoint = self.MedkitPointsPerHealth
	if hpperpoint <= 0 then return end

	local points = math.floor(pl.CarryOverHealth / hpperpoint)

	if 1 <= points then
		pl:AddPoints(points)

		pl.CarryOverHealth = pl.CarryOverHealth - points * hpperpoint

		if not pl:IsBot() then
			net.Start("zs_healother")
				net.WriteEntity(other)
				net.WriteUInt(points, 16)
			net.Send(pl)
		end
	end
end

function GM:PlayerRepairedObject(pl, other, health, wep)
	health = health - other:RemoveUselessDamage(health)
	if self:GetWave() == 0 or health <= 0 then return end

	self:AddProgressionXP(pl, health / 25)
	pl.RepairedThisRound = pl.RepairedThisRound + health
	pl.CarryOverRepair = (pl.CarryOverRepair or 0) + health

	local hpperpoint = self.RepairPointsPerHealth
	if hpperpoint <= 0 then return end

	local points = math.floor(pl.CarryOverRepair / hpperpoint)

	if 1 <= points then
		pl:AddPoints(points)

		pl.CarryOverRepair = pl.CarryOverRepair - points * hpperpoint

		if not pl:IsBot() then
			net.Start("zs_repairobject")
				net.WriteEntity(other)
				net.WriteUInt(points, 16)
			net.Send(pl)
		end
	end
end

