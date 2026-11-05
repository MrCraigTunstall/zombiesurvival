function GM:RestoreSpectatorState(pl)
	local deadline = self.PreviouslySpec[pl:SteamID()]
	if not deadline then return false end
	pl.SpecCoolDown = deadline
	pl:ChangeTeam(TEAM_SPECTATOR)
	return true
end

net.Receive("zs_spectate", function(length, pl)
	if length ~= 0 or not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return end
	local now = RealTime()
	if now < (pl.ZSNextSpectateRequest or 0) then return end
	pl.ZSNextSpectateRequest = now + 0.3
	local gm = GAMEMODE
	if gm.NoSpec then
		pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, "spectator_cantchange2"))
		return
	end
	if LASTHUMAN then
		pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, "spectator_cantchange3"))
		return
	end
	if pl.SpecCoolDown and now < pl.SpecCoolDown then
		pl:CenterNotify(COLOR_DARKRED, string.format(translate.ClientGet(pl, "spectator_cooldown"), string.NiceTime(pl.SpecCoolDown - now)))
		return
	end
	local oldteam = pl:Team()
	if oldteam == TEAM_SPECTATOR then
		if gm:GetWave() <= 0 then
			pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, "spectator_cantchange"))
			return
		end
		gm.PreviouslySpec[pl:SteamID()] = nil
		pl.SpecCoolDown = nil
		pl:ChangeTeam(TEAM_UNDEAD)
		return
	end
	gm.PreviouslyDied[pl:UniqueID()] = CurTime()
	if oldteam == TEAM_HUMAN then pl:DropAll() end
	if pl:OldAlive() then
		local damage = bit.bor(DMG_ENERGYBEAM, DMG_DISSOLVE)
		local class = oldteam == TEAM_UNDEAD and pl:GetZombieClassTable()
		if class and class.Revives then damage = bit.bor(damage, DMG_CRUSH) end
		local attacker = pl:GetLastAttacker()
		pl:TakeSpecialDamage(pl:Health(), damage, IsValid(attacker) and attacker or pl, nil)
	end
	pl:ChangeTeam(TEAM_SPECTATOR)
	pl:PrintMessage(HUD_PRINTTALK, translate.ClientGet(pl, "spectator_now"))
	if not gamemode.Call("PlayerIsAdmin", pl) then
		pl.SpecCoolDown = now + gm.SpectatorCoolDown
		gm.PreviouslySpec[pl:SteamID()] = pl.SpecCoolDown
	end
end)
