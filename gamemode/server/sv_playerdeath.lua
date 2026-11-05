function GM:PlayerDeath(pl, inflictor, attacker)
end

function GM:PlayerDeathSound()
	return true
end

function GM:CanPlayerSuicide(pl)
	if self.RoundEnded or pl:HasWon() then return false end

	if pl:Team() == TEAM_HUMAN then
		if self:GetWave() <= self.NoSuicideWave then
			pl:PrintTranslatedMessage(HUD_PRINTCENTER, "give_time_before_suicide")
			return false
		end

		
		if not IsValid(pl:GetLastAttacker()) then
			local plpos = pl:EyePos()
			local closest, bestdistance
			for _, zom in ipairs(team.GetPlayers(TEAM_UNDEAD)) do
				if zom:Alive() then
					local distance = zom:GetPos():DistToSqr(plpos)
					if distance <= 512 * 512 and (not bestdistance or distance < bestdistance) then
						closest, bestdistance = zom, distance
					end
				end
			end

			if closest then
				pl:SetLastAttacker(closest)
			end
		end
	elseif pl:Team() == TEAM_UNDEAD then
		local ret = pl:CallZombieFunction("CanPlayerSuicide")
		if ret == false then return false end
	end

	return pl:GetObserverMode() == OBS_MODE_NONE and pl:Alive() and (not pl.SpawnNoSuicide or pl.SpawnNoSuicide < CurTime())
end

function GM:DefaultRevive(pl)
	local status = pl:GiveStatus("revive")
	if status and status:IsValid() then
		status:SetReviveTime(CurTime() + 2)
	end
end

function GM:HumanKilledZombie(pl, attacker, inflictor, dmginfo, headshot, suicide)
	if (pl:GetZombieClassTable().Points or 0) == 0 or self.RoundEnded then return end

	

	local totaldamage = 0
	local mostassistdamage = 0
	local mostdamager
	for otherpl, dmg in pairs(pl.DamagedBy) do
		if otherpl:IsValid() and otherpl:Team() ~= TEAM_UNDEAD then
			totaldamage = totaldamage + dmg
			if otherpl ~= attacker and dmg > mostassistdamage then
				mostassistdamage = dmg
				mostdamager = otherpl
			end
		end
	end

	if not (mostassistdamage >= totaldamage / 2) then
		mostassistdamage = 0
		mostdamager = nil
	end

	attacker.ZombiesKilled = attacker.ZombiesKilled + 1

	if mostdamager then
		attacker:PointCashOut(pl, FM_LOCALKILLOTHERASSIST)
		mostdamager:PointCashOut(pl, FM_LOCALASSISTOTHERKILL)

		mostdamager.ZombiesKilledAssists = mostdamager.ZombiesKilledAssists + 1
	else
		attacker:PointCashOut(pl, FM_NONE)
	end

	gamemode.Call("PostHumanKilledZombie", pl, attacker, inflictor, dmginfo, mostdamager, mostassistdamage, headshot)

	return mostdamager
end

function GM:PostHumanKilledZombie(pl, attacker, inflictor, dmginfo, assistpl, assistamount, headshot)
end

function GM:ZombieKilledHuman(pl, attacker, inflictor, dmginfo, headshot, suicide)
	if self.RoundEnded then return end

	local plpos = pl:GetPos()
	local dist = 99999
	for _, ent in pairs(team.GetValidSpawnPoint(TEAM_UNDEAD)) do
		dist = math.min(math.ceil(ent:GetPos():Distance(plpos)), dist)
	end
	pl.ZombieSpawnDeathDistance = dist

	if not suicide then self:AddProgressionXP(attacker, 10) end
	attacker:AddBrains(1)
	attacker:AddLifeBrainsEaten(1)

	if not pl.Gibbed and not suicide and not headshot then
		local status = pl:GiveStatus("revive_slump_human")
		if status then
			status:SetReviveTime(CurTime() + 4)
			status:SetZombieInitializeTime(CurTime() + 2)
		end

		local classtab = self.ZombieEscape and self.ZombieClasses["Super Zombie"] or self:IsClassicMode() and self.ZombieClasses["Classic Zombie"] or self:IsBabyMode() and GAMEMODE.ZombieClasses["Gore Child"] or GAMEMODE.ZombieClasses["Fresh Dead"]
		if classtab then
			pl:SetZombieClass(classtab.Index)
		end
	end

	gamemode.Call("PostZombieKilledHuman", pl, attacker, inflictor, dmginfo, headshot, suicide)

	return attacker:Frags()
end

function GM:PostZombieKilledHuman(pl, attacker, inflictor, dmginfo, headshot, suicide)
end

local function DelayedChangeToZombie(pl)
	if pl:IsValid() and pl:Team() ~= TEAM_SPECTATOR then
		if pl.ChangeTeamFrags then
			pl:SetFrags(pl.ChangeTeamFrags)
			pl.ChangeTeamFrags = 0
		end

		pl:ChangeTeam(TEAM_UNDEAD)
	end
end

function GM:DoPlayerDeath(pl, attacker, dmginfo)
	pl:RemoveStatus("confusion", false, true)
	pl:RemoveStatus("ghoultouch", false, true)

	local inflictor = dmginfo:GetInflictor()
	local plteam = pl:Team()
	local ct = CurTime()
	local suicide = attacker == pl or attacker:IsWorld()

	pl:Freeze(false)

	local headshot = pl:LastHitGroup() == HITGROUP_HEAD and pl.m_LastHeadShot and CurTime() <= pl.m_LastHeadShot + 0.1

	if suicide then attacker = pl:GetLastAttacker() or attacker end
	pl:SetLastAttacker()

	if inflictor == NULL then inflictor = attacker end

	if inflictor == attacker and attacker:IsPlayer() then
		local wep = attacker:GetActiveWeapon()
		if wep:IsValid() then
			inflictor = wep
		end
	end

	if headshot then
		local effectdata = EffectData()
			effectdata:SetOrigin(dmginfo:GetDamagePosition())
			local force = dmginfo:GetDamageForce()
			effectdata:SetMagnitude(force:Length() * 3)
			effectdata:SetNormal(force:GetNormalized())
			effectdata:SetEntity(pl)
		util.Effect("headshot", effectdata, true, true)
	end

	if not pl:CallZombieFunction("OnKilled", attacker, inflictor, suicide, headshot, dmginfo) then
		if pl:Health() <= -70 and not pl.NoGibs and not self.ZombieEscape then
			pl:Gib(dmginfo)
		elseif not pl.KnockedDown then
			pl:CreateRagdoll()
		end
	end

	pl:RemoveStatus("overridemodel", false, true)

	local revive
	local assistpl
	if plteam == TEAM_UNDEAD then
		local classtable = pl:GetZombieClassTable()

		pl:PlayZombieDeathSound()

		if not classtable.NoDeaths then
			pl:AddDeaths(1)
		end

		if self:GetWaveActive() then
			pl.StartSpectating = ct + 2
		else
			pl.StartCrowing = ct + 3
		end

		if attacker:IsValid() and attacker:IsPlayer() and attacker ~= pl then
			if classtable.Revives and not pl.Gibbed and not headshot then
				if classtable.ReviveCallback then
					revive = classtable:ReviveCallback(pl, attacker, dmginfo)
				elseif math.random(1, 4) ~= 1 then
					self:DefaultRevive(pl)
					revive = true
				end
			end

			if not revive and attacker:Team() ~= TEAM_UNDEAD then
				assistpl = gamemode.Call("HumanKilledZombie", pl, attacker, inflictor, dmginfo, headshot, suicide)
			end
		end

		if not revive and not pl:IsBot() and (pl.LifeBarricadeDamage ~= 0 or pl.LifeHumanDamage ~= 0 or pl.LifeBrainsEaten ~= 0) then
			net.Start("zs_lifestats")
				net.WriteUInt(math.ceil(pl.LifeBarricadeDamage or 0), 24)
				net.WriteUInt(math.ceil(pl.LifeHumanDamage or 0), 24)
				net.WriteUInt(pl.LifeBrainsEaten or 0, 16)
			net.Send(pl)
		end

		pl:CallZombieFunction("PostOnKilled", attacker, inflictor, suicide, headshot, dmginfo)
	elseif plteam ~= TEAM_UNDEAD then
		pl.NextSpawnTime = ct + 4

		pl:PlayDeathSound()

		if attacker:IsPlayer() and attacker ~= pl then
			gamemode.Call("ZombieKilledHuman", pl, attacker, inflictor, dmginfo, headshot, suicide)
		end

		pl:DropAll()
		timer.Simple(0, function() DelayedChangeToZombie(pl) end) 
		self.PreviouslyDied[pl:UniqueID()] = CurTime()
		if self:GetWave() == 0 then
			pl.DiedDuringWave0 = true
		end

		local frags = pl:Frags()
		if frags < 0 then
			pl.ChangeTeamFrags = math.ceil(frags / 5)
		else
			pl.ChangeTeamFrags = 0
		end

		if pl.SpawnedTime then
			pl.SurvivalTime = math.max(ct - pl.SpawnedTime, pl.SurvivalTime or 0)
			pl.SpawnedTime = nil
		end

		if team.NumPlayers(TEAM_HUMAN) + team.NumPlayers(TEAM_REDEEMER) <= 1 then
			self.LastHumanPosition = pl:WorldSpaceCenter()

			net.Start("zs_lasthumanpos")
				net.WriteVector(self.LastHumanPosition)
			net.Broadcast()
		end

		local hands = pl:GetHands()
		if IsValid(hands) then
			hands:Remove()
		end
	end

	if revive or pl:CallZombieFunction("NoDeathMessage", attacker, dmginfo) or pl:IsSpectator() then return end

	if attacker == pl then
		net.Start("zs_pl_kill_self")
			net.WriteEntity(pl)
			net.WriteUInt(plteam, 16)
		net.Broadcast()
	elseif attacker:IsPlayer() then
		if assistpl then
			net.Start("zs_pls_kill_pl")
				net.WriteEntity(pl)
				net.WriteEntity(attacker)
				net.WriteEntity(assistpl)
				net.WriteString(inflictor:GetClass())
				net.WriteUInt(plteam, 16)
				net.WriteUInt(attacker:Team(), 16) 
				net.WriteBit(headshot)
			net.Broadcast()

			gamemode.Call("PlayerKilledByPlayer", pl, assistpl, inflictor, headshot, dmginfo, true)
		else
			net.Start("zs_pl_kill_pl")
				net.WriteEntity(pl)
				net.WriteEntity(attacker)
				net.WriteString(inflictor:GetClass())
				net.WriteUInt(plteam, 16)
				net.WriteUInt(attacker:Team(), 16)
				net.WriteBit(headshot)
			net.Broadcast()
		end

		gamemode.Call("PlayerKilledByPlayer", pl, attacker, inflictor, headshot, dmginfo)
	else
		net.Start("zs_death")
			net.WriteEntity(pl)
			net.WriteString(inflictor:GetClass())
			net.WriteString(attacker:GetClass())
			net.WriteUInt(plteam, 16)
		net.Broadcast()
	end
end

function GM:PlayerKilledByPlayer(pl, attacker, inflictor, headshot, dmginfo)
end
