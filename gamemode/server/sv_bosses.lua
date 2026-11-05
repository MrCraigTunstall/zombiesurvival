GM.SuperBossWave6 = CreateConVar("zs_superboss_wave6", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Use a super boss for wave six", 0, 1)
GM.SuperBossUnbalanced = CreateConVar("zs_superboss_unbalanced", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Use super bosses when the human team greatly outnumbers zombies", 0, 1)
GM.SuperBossRatio = CreateConVar("zs_superboss_ratio", "10", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Human to zombie ratio required for a super boss", 1, 128)

function GM:ShouldUseSuperBoss()
	if self.ZombieEscape or self.ObjectiveMap or self.RoundEnded or self.PantsMode or self:IsClassicMode() or self:IsBabyMode() then return false end
	local _, supers = self:GetBossCatalog()
	if #supers == 0 then return false end
	local wave = self:GetWave() + (self:GetWaveActive() and 0 or 1)
	if self.SuperBossWave6:GetBool() and wave == 6 then return true end
	if not self.SuperBossUnbalanced:GetBool() then return false end
	local counts = self.ZSBossTeamCounts
	if not counts or CurTime() - counts.time >= 0.25 then
		local humans, zombies = 0, 0
		for _, pl in player.Iterator() do
			local team = pl:Team()
			if team == TEAM_HUMAN and pl:Alive() then humans = humans + 1
			elseif team == TEAM_UNDEAD then zombies = zombies + 1 end
		end
		counts = {humans = humans, zombies = zombies, time = CurTime()}
		self.ZSBossTeamCounts = counts
	end
	return counts.zombies > 0 and counts.humans >= counts.zombies * self.SuperBossRatio:GetFloat()
end

function GM:GetBossClassForPlayer(pl)
	if not self:ShouldUseSuperBoss() then pl.ZSSuperBossChoice = nil; return self:GetPreferredBossClass(pl) end
	local _, choices = self:GetBossCatalog()
	local wave = self:GetWave() + (self:GetWaveActive() and 0 or 1)
	local cached = pl.ZSSuperBossChoice
	if cached and cached.wave == wave then
		for _, index in ipairs(choices) do
			if index == cached.index then return index end
		end
	end
	local index = choices[math.random(#choices)]
	pl.ZSSuperBossChoice = {wave = wave, index = index}
	return index
end

local function Score(pl)
	local barricades, damage = tonumber(pl.WaveBarricadeDamage) or 0, tonumber(pl.WaveHumanDamage) or 0
	if barricades ~= barricades or math.abs(barricades) == math.huge then barricades = 0 end
	if damage ~= damage or math.abs(damage) == math.huge then damage = 0 end
	return barricades * 0.05 + damage
end

function GM:CalculateNextBoss()
	local living, selected, score, deaths, index = 0
	local humans, zombies = 0, 0
	for _, pl in player.Iterator() do
		local team = pl:Team()
		if team == TEAM_HUMAN and pl:Alive() then humans = humans + 1 end
		if team == TEAM_UNDEAD then
			zombies = zombies + 1
			local class = pl:GetZombieClassTable()
			if class and class.Boss and pl:Alive() then
				living = living + 1
				if living >= 3 then selected = nil; break end
			elseif class and (pl:IsBot() or pl:GetInfo("zs_nobosspick") == "0") then
				local value, count, id = Score(pl), pl:Deaths(), pl:EntIndex()
				if not selected or value > score or value == score and (count < deaths or count == deaths and id < index) then
					selected, score, deaths, index = pl, value, count, id
				end
			end
		end
	end
	if living < 3 then self.ZSBossTeamCounts = {humans = humans, zombies = zombies, time = CurTime()} end
	local name = ""
	if selected then
		local class = self.ZombieClasses[selected:GetBossZombieIndex()]
		if not class then return end
		name = class.Name
	end
	if self.LastAnnouncedBoss ~= selected or self.LastAnnouncedBossClass ~= name then
		self.LastAnnouncedBoss, self.LastAnnouncedBossClass = selected, name
		net.Start("zs_nextboss"); net.WriteEntity(selected or NULL); net.WriteString(name); net.Broadcast()
	end
	return selected
end

hook.Add("StartCommand", "ZSSuperBossAbilities", function(pl)
	if not pl.ZSSuperBoss or not pl:IsBot() or not pl:Alive() or CurTime() < (pl.ZSNextBossAbility or 0) then return end
	pl.ZSNextBossAbility = CurTime() + 0.2
	local memory = pl.D3bot_Mem
	local target = memory and memory.TgtOrNil
	local weapon = pl:GetActiveWeapon()
	if not IsValid(target) or not IsValid(weapon) or not weapon.BossSpit then return end
	local origin, goal = pl:GetShootPos(), target:WorldSpaceCenter()
	local distance = origin:DistToSqr(goal)
	if distance < 120 * 120 or distance > 900 * 900 or pl:GetAimVector():Dot((goal - origin):GetNormalized()) < 0.85 or not WorldVisible(origin, goal) then return end
	weapon:BossSpit()
	if distance > 250 * 250 and distance < 600 * 600 then weapon:BossLeap() end
end)

function GM:SpawnBossZombie(pl, silent)
	if not pl then pl = self:CalculateNextBoss() end
	if not IsValid(pl) or not pl:IsPlayer() or pl:Team() ~= TEAM_UNDEAD or self.RoundEnded then return false end
	self.ZSBossTeamCounts = nil
	local index = pl:GetBossZombieIndex()
	local class = self.ZombieClasses[index]
	if not class or not class.Boss then return false end
	local previous = pl.DeathClass or pl:GetZombieClass()
	pl:KillSilent(); pl:SetZombieClass(index); pl:DoHulls(index, TEAM_UNDEAD); pl.DeathClass = nil; pl:UnSpectateAndSpawn(); pl.DeathClass = previous
	if not pl:Alive() or pl:GetZombieClass() ~= index then return false end
	self.LastBossZombieSpawned = self:GetWave()
	if not silent then
		net.Start("zs_boss_spawned"); net.WriteEntity(pl); net.WriteUInt(index, 8); net.Broadcast()
	end
	return true
end

for _, event in ipairs({"PlayerSpawn", "PlayerDeath", "OnPlayerChangedTeam", "PlayerDisconnected"}) do
	hook.Add(event, "ZSBossTeamCounts", function() GAMEMODE.ZSBossTeamCounts = nil end)
end
