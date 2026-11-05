local playerMeta = FindMetaTable('Player')
local nativeTeam, nativeGhost, nativeIndex = playerMeta.Team, playerMeta.GetBarricadeGhosting, playerMeta.__index
local nativePlayers, nativeIterator, nativeAll = team.GetPlayers, player.Iterator, player.GetAll
local nativeBase = player.ZSPlayerList and player.ZSPlayerList.NativeGetAll
local function Source(fn)
	return type(fn) == 'function' and debug.getinfo(fn, 'S').source or ''
end
local stock = Source(nativePlayers) == '@lua/includes/modules/team.lua'
	and Source(nativeIterator) == '@lua/includes/extensions/entity_iter.lua'
	and Source(nativeIndex) == '@lua/includes/extensions/player.lua'
	and Source(nativeGhost):find('/gamemode/meta/obj_player_extend.lua', 1, true) ~= nil
	and type(nativeBase) == 'function' and debug.getinfo(nativeBase, 'S').what == 'C'
local function CanShare()
	return stock and team.GetPlayers == nativePlayers and player.Iterator == nativeIterator and player.GetAll == nativeAll
		and rawget(playerMeta, 'Team') == nativeTeam and rawget(playerMeta, 'GetBarricadeGhosting') == nativeGhost and rawget(playerMeta, '__index') == nativeIndex
end
local function Clear(list)
	for index = 1, #list do list[index] = nil end
end
local function GetRosters(humans, redeemers)
	if not CanShare() then return team.GetPlayers(TEAM_HUMAN), nil, false end
	for _, pl in nativeIterator() do
		if getmetatable(pl) ~= playerMeta then return team.GetPlayers(TEAM_HUMAN), nil, false end
		local id = nativeTeam(pl)
		if id == TEAM_HUMAN then humans[#humans + 1] = pl
		elseif id == TEAM_REDEEMER then redeemers[#redeemers + 1] = pl end
	end
	return humans, redeemers, true
end
local humanPool, redeemerPool, busy = {}, {}, false

local NextTick = 0
local NextVolunteerUpdate = 0
local NextBossUpdate = 0
local function ProcessRound(self, humanBuffer, redeemerBuffer)
	local time = CurTime()
	local wave = self:GetWave()

	if not self.RoundEnded then
		if self:GetWaveActive() then
			local waveend = self:GetWaveEnd()
			if waveend <= time and waveend ~= -1 then
				gamemode.Call("SetWaveActive", false)
			end
		else
			local wavestart = self:GetWaveStart()
			if wavestart ~= -1 then
				if wavestart <= time then
					if not self.ZSRoundRestartSpawns or not self.ZSRoundRestartSpawns.players then
						gamemode.Call("SetWaveActive", true)
					end
				elseif self.BossZombies and not self.PantsMode and not self:IsClassicMode() and not self.ZombieEscape
				and self.LastBossZombieSpawned ~= wave and wave > 0 and not self.RoundEnded
				and (self.BossZombiePlayersRequired <= 0 or player.GetCount() >= self.BossZombiePlayersRequired) then
					if wavestart - 10 <= time then
						self:SpawnBossZombie()
					elseif time >= NextBossUpdate then
						NextBossUpdate = time + 1
						self:CalculateNextBoss()
					end
				end
			end
		end
	end

	local humans, redeemers, shared = GetRosters(humanBuffer, redeemerBuffer)
	if not self.ZSBarricadeGhostCommandController then
	for _, pl in pairs(humans) do
		if pl:GetBarricadeGhosting() then
			shared = false
			pl:BarricadeGhostingThink()
		end
	end
	if not shared or not CanShare() then redeemers = team.GetPlayers(TEAM_REDEEMER) end
	for _, pl in ipairs(redeemers) do
		if pl:GetBarricadeGhosting() then pl:BarricadeGhostingThink() end
	end
	end


	if wave == 0 and time >= NextVolunteerUpdate then
		NextVolunteerUpdate = time + 0.25
		self:CalculateZombieVolunteers()
	end

	if NextTick <= time then
		NextTick = time + 1

		for _, pl in ipairs(humans) do self:FlushCombatPoints(pl, time) end
		for _, pl in ipairs(redeemers) do self:FlushCombatPoints(pl, time) end

		local doafk = not self:GetWaveActive() and wave == 0
		local dopoison = self:GetEscapeStage() == ESCAPESTAGE_DEATH

		for _, pl in pairs(humans) do
			if pl:Alive() then
				if doafk then
					local plpos = pl:GetPos()
					if pl.LastAFKPosition and (pl.LastAFKPosition.x ~= plpos.x or pl.LastAFKPosition.y ~= plpos.y) then
						pl.LastNotAFK = CurTime()
					end
					pl.LastAFKPosition = plpos
				end

				if pl:WaterLevel() >= 3 and not (pl.status_drown and pl.status_drown:IsValid()) then
					pl:GiveStatus("drown")
				else
					pl:PreventSkyCade()
				end

				if self:GetWave() >= 1 and time >= pl.BonusDamageCheck + 60 then
					pl.BonusDamageCheck = time
					pl:AddPoints(2)
					pl:PrintTranslatedMessage(HUD_PRINTCONSOLE, "minute_points_added", 2)
				end

				if pl.BuffRegenerative and time >= pl.NextRegenerate and pl:Health() < pl:GetMaxHealth() / 2 then
					pl.NextRegenerate = time + 5
					pl:SetHealth(pl:Health() + 1)
				end

				if dopoison then
					pl:TakeSpecialDamage(5, DMG_POISON)
				end
			end
		end
	end
end

function GM:Think()
	local pooled = not busy
	local humans, redeemers = pooled and humanPool or {}, pooled and redeemerPool or {}
	if pooled then busy = true end
	local ok, failure = xpcall(ProcessRound, debug.traceback, self, humans, redeemers)
	Clear(humans) Clear(redeemers)
	if pooled then busy = false end
	if not ok then error(failure, 0) end
end
