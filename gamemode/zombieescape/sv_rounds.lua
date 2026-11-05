local function LiveEntity(ent)
 return IsValid(ent) and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())
end

function GM:RegisterZombieEscapeWinTrigger(source, output)
 if not self.ZombieEscape or not LiveEntity(source) then return false end
 output = output or "OnStartTouch"
 if type(output) ~= "string" or not output:match("^On[%a%d_]+$") then return false end
 local relay = self.ZSEscapeWinRelay
 if not LiveEntity(relay) then
  relay = ents.Create("logic_winlose")
  if not LiveEntity(relay) then return false end
  relay:SetName("zs_escape_finish_" .. relay:GetCreationID())
  relay.ZSEscapeWinSources = {}
  relay:Spawn()
  self.ZSEscapeWinRelay = relay
 end
 for previous in pairs(relay.ZSEscapeWinSources) do
  if not LiveEntity(previous) then relay.ZSEscapeWinSources[previous] = nil end
 end
 if source.ZSEscapeWinRelay == relay then return true end
 relay.ZSEscapeWinSources[source] = true
 source.ZSEscapeWinRelay = relay
 source:Fire("AddOutput", output .. " " .. relay:GetName() .. ",Win,,0,-1")
 return true
end

function GM:CanZombieEscapeMapWin(relay, activator, caller)
 return self.ZombieEscape and not self.RoundEnded and self:GetWave() > 0 and self:GetWaveActive()
 and IsValid(caller) and relay.ZSEscapeWinSources and relay.ZSEscapeWinSources[caller] == true
 and IsValid(activator) and activator:IsPlayer() and activator:Alive() and activator:Team() == TEAM_HUMAN
end

hook.Add("PlayerSpawn", "zombieescape", function(pl)
	timer.Simple(0, function()
		if not pl:IsValid() then return end

		if GAMEMODE:GetWave() == 0 and not GAMEMODE:GetWaveActive() and (pl:Team() == TEAM_UNDEAD or pl:Team() == TEAM_HUMAN and CurTime() < GAMEMODE:GetWaveStart() - GAMEMODE.ZE_FreezeTime) then
			pl.ZEFreeze = true
			pl:Freeze(true)
			pl:GodEnable()
		end
	end)
end)






hook.Add("OnWaveStateChanged", "zombieescape", function()
	if GAMEMODE:GetWave() == 1 and GAMEMODE:GetWaveActive() then
		for _, pl in player.Iterator() do
			pl:Freeze(false)
			pl:GodDisable()
		end
	end
end)

local CheckTime
local FreezeTime = true
local NextDamage = 0
local NextWinCheck = 0
hook.Add("InitPostEntityMap", "ZombieEscapeRoundState", function(fromze)
 CheckTime, NextDamage, NextWinCheck = nil, 0, 0
 if not fromze then FreezeTime = true end
end)
hook.Add("Think", "zombieescape", function()
	if GAMEMODE.RoundEnded then CheckTime = nil return end
	local now = CurTime()
	if GAMEMODE:GetWave() == 0 then
		if FreezeTime and now >= GAMEMODE:GetWaveStart() - GAMEMODE.ZE_FreezeTime then
			FreezeTime = false

			game.CleanUpMap(false, GAMEMODE.CleanupFilter)
			hook.Run("InitPostEntityMap", true)

			for _, pl in pairs(team.GetPlayers(TEAM_HUMAN)) do
				pl.ZEFreeze = nil
				pl:Freeze(false)
				pl:GodDisable()
				local ent = GAMEMODE:PlayerSelectSpawn(pl)
				if IsValid(ent) then
					pl:SetPos(ent:GetPos())
				end
			end
		end

		CheckTime = nil
		return
	end

	FreezeTime = true
	if not GAMEMODE:GetWaveActive() then CheckTime = nil return end

	if now >= GAMEMODE:GetWaveStart() + GAMEMODE.ZE_TimeLimit and now >= NextDamage then
		NextDamage = now + 1

		for _, pl in pairs(team.GetPlayers(TEAM_HUMAN)) do
			pl:TakeDamage(5)
		end
	end

	if now < NextWinCheck then return end
	NextWinCheck = now + 0.25
	local livingHuman = false
	for _, pl in player.Iterator() do
		if pl:Team() == TEAM_HUMAN and pl:Alive() then livingHuman = true break end
	end
	if not livingHuman then CheckTime = nil return end
	local undead = team.GetPlayers(TEAM_UNDEAD)
	if #undead == 0 then CheckTime = nil return end

	for _, pl in pairs(undead) do
		if pl:Alive() or not pl.KilledByTriggerHurt or now > pl.KilledByTriggerHurt + 12 then
			CheckTime = nil
			return
		end
	end

	CheckTime = CheckTime or (now + 2.5)

	if CheckTime and now >= CheckTime then
		gamemode.Call("EndRound", TEAM_HUMAN)
	end
end)

hook.Add("DoPlayerDeath", "zombieescape", function(pl, attacker, dmginfo)
	pl.KilledPos = pl:GetPos()
	pl.KilledByTriggerHurt = nil

	if pl:Team() == TEAM_UNDEAD then
		if attacker:IsValid() and attacker:GetClass() == "trigger_hurt"  then
			pl.KilledByTriggerHurt = CurTime()
			pl.NextSpawnTime = CurTime() + 10
		elseif GAMEMODE.RoundEnded then
			pl.NextSpawnTime = CurTime() + 9999
		else
			pl.NextSpawnTime = CurTime() + 5
		end
	end
end)

