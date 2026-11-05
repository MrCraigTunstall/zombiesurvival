local function GetMostKey(key, top)
	top = top or 0
	local toppl
	for _, pl in player.Iterator() do
		if pl[key] and pl[key] > top then
			top = pl[key]
			toppl = pl
		end
	end

	if toppl and top > 0 then
		return toppl, top
	end
end

local function GetMostFunc(func, top)
	top = top or 0
	local toppl
	for _, pl in player.Iterator() do
		local amount = pl[func](pl)
		if amount > top then
			top = amount
			toppl = pl
		end
	end

	if toppl and top > 0 then
		return toppl, top
	end
end

GM.HonorableMentions[HM_MOSTZOMBIESKILLED].GetPlayer = function(self)
	return GetMostKey("ZombiesKilled")
end

GM.HonorableMentions[HM_MOSTBRAINSEATEN].GetPlayer = function(self)
	return GetMostKey("BrainsEaten")
end

GM.HonorableMentions[HM_SCARECROW].GetPlayer = function(self)
	return GetMostKey("CrowKills")
end

GM.HonorableMentions[HM_CROWFIGHTER].GetPlayer = function(self)
	return GetMostKey("CrowVsCrowKills")
end

GM.HonorableMentions[HM_CROWBARRICADEDAMAGE].GetPlayer = function(self)
	return GetMostKey("CrowBarricadeDamage")
end

GM.HonorableMentions[HM_BARRICADEDESTROYER].GetPlayer = function(self)
	return GetMostKey("BarricadeDamage")
end

GM.HonorableMentions[HM_SPAWNPOINT].GetPlayer = function(self)
	return GetMostKey("DynamicSpawnedOn")
end

GM.HonorableMentions[HM_HANDYMAN].GetPlayer = function(self)
	local pl, amount = GetMostKey("RepairedThisRound")
	if pl and amount then
		return pl, math.ceil(amount)
	end
end

GM.HonorableMentions[HM_LASTHUMAN].GetPlayer = function(self)
	if self.TheLastHuman and self.TheLastHuman:IsValid() then return self.TheLastHuman end
end

GM.HonorableMentions[HM_MOSTHELPFUL].GetPlayer = function(self)
	return GetMostKey("ZombiesKilledAssists")
end

GM.HonorableMentions[HM_GOODDOCTOR].GetPlayer = function(self)
	return GetMostKey("HealedThisRound")
end

GM.HonorableMentions[HM_MOSTDAMAGETOUNDEAD].GetPlayer = function(self)
	local top = 0
	local toppl
	for _, pl in player.Iterator() do
		if pl.DamageDealt and pl.DamageDealt[TEAM_HUMAN] > top then
			top = pl.DamageDealt[TEAM_HUMAN]
			toppl = pl
		end
	end

	if toppl and top >= 1 then
		return toppl, math.ceil(top)
	end
end

GM.HonorableMentions[HM_MOSTDAMAGETOHUMANS].GetPlayer = function(self)
	local top = 0
	local toppl
	for _, pl in player.Iterator() do
		if pl.DamageDealt and pl.DamageDealt[TEAM_UNDEAD] > top then
			top = pl.DamageDealt[TEAM_UNDEAD]
			toppl = pl
		end
	end

	if toppl and top >= 1 then
		return toppl, math.ceil(top)
	end
end

GM.HonorableMentions[HM_LASTBITE].GetPlayer = function(self)
	if LAST_BITE and LAST_BITE:IsValid() then
		return LAST_BITE
	end
end

GM.HonorableMentions[HM_USEFULTOOPPOSITE].GetPlayer = function(self)
	local pl, mag = GetMostFunc("Deaths")
	if mag and mag >= 30 then
		return pl, mag
	end
end

GM.HonorableMentions[HM_PACIFIST].GetPlayer = function(self)
	if WINNER == TEAM_HUMAN then
		for _, pl in player.Iterator() do
			if pl.ZombiesKilled == 0 and pl:Team() == TEAM_HUMAN then return pl end
		end
	end
end

GM.HonorableMentions[HM_STUPID].GetPlayer = function(self)
	local dist = 99999
	local finalpl
	for _, pl in player.Iterator() do
		if pl.ZombieSpawnDeathDistance and pl.ZombieSpawnDeathDistance < dist then
			finalpl = pl
			dist = pl.ZombieSpawnDeathDistance
		end
	end

	if finalpl and dist <= 1000 then
		return finalpl, math.ceil(dist / 12)
	end
end

GM.HonorableMentions[HM_OUTLANDER].GetPlayer = function(self)
	local dist = 0
	local finalpl
	for _, pl in player.Iterator() do
		if pl.ZombieSpawnDeathDistance and dist < pl.ZombieSpawnDeathDistance then
			finalpl = pl
			dist = pl.ZombieSpawnDeathDistance
		end
	end

	if finalpl and 8000 <= dist then
		return finalpl, math.ceil(dist / 12)
	end
end

GM.HonorableMentions[HM_SALESMAN].GetPlayer = function(self)
	return GetMostKey("PointsCommission")
end

GM.HonorableMentions[HM_WAREHOUSE].GetPlayer = function(self)
	return GetMostKey("ResupplyBoxUsedByOthers")
end

GM.HonorableMentions[HM_NESTDESTROYER].GetPlayer = function(self)
	return GetMostKey("NestsDestroyed")
end

GM.HonorableMentions[HM_NESTMASTER].GetPlayer = function(self)
	return GetMostKey("NestSpawns")
end

local stock = {}
for id, mention in ipairs(GM.HonorableMentions) do stock[id] = mention.GetPlayer end
local native = FindMetaTable("Player")
local nativeDeaths, nativeTeam = native.Deaths, native.Team
local nativeMethods = debug.getinfo(nativeDeaths, "S").what == "C" and debug.getinfo(nativeTeam, "S").what == "C"
local keys = {
	{HM_MOSTZOMBIESKILLED, "ZombiesKilled"}, {HM_MOSTBRAINSEATEN, "BrainsEaten"},
	{HM_SCARECROW, "CrowKills"}, {HM_CROWFIGHTER, "CrowVsCrowKills"},
	{HM_CROWBARRICADEDAMAGE, "CrowBarricadeDamage"}, {HM_BARRICADEDESTROYER, "BarricadeDamage"},
	{HM_SPAWNPOINT, "DynamicSpawnedOn"}, {HM_HANDYMAN, "RepairedThisRound", true},
	{HM_MOSTHELPFUL, "ZombiesKilledAssists"}, {HM_GOODDOCTOR, "HealedThisRound"},
	{HM_SALESMAN, "PointsCommission"}, {HM_WAREHOUSE, "ResupplyBoxUsedByOthers"},
	{HM_NESTDESTROYER, "NestsDestroyed"}, {HM_NESTMASTER, "NestSpawns"}
}

function GM:BuildHonorableMentionLeaders()
	if not nativeMethods then return end
	for id = 1, #stock do
		local mention = self.HonorableMentions[id]
		if not mention or mention.GetPlayer ~= stock[id] then return end
	end
	for id, mention in ipairs(self.HonorableMentions) do
		if mention.GetPlayer ~= stock[id] then return end
	end
	local leaders, amounts = {}, {}
	local humanDamage, undeadDamage, deaths, nearest, furthest = 0, 0, 0, 99999, 0
	local humanLeader, undeadLeader, deathLeader, nearestLeader, furthestLeader, pacifist
	for _, pl in player.Iterator() do
		if pl.Deaths ~= nativeDeaths or pl.Team ~= nativeTeam then return end
		for index = 1, #keys do
			local spec = keys[index]
			local amount = pl[spec[2]]
			if amount and amount > (amounts[index] or 0) then leaders[spec[1]], amounts[index] = pl, amount end
		end
		local damage = pl.DamageDealt
		if damage then
			if damage[TEAM_HUMAN] > humanDamage then humanDamage, humanLeader = damage[TEAM_HUMAN], pl end
			if damage[TEAM_UNDEAD] > undeadDamage then undeadDamage, undeadLeader = damage[TEAM_UNDEAD], pl end
		end
		local count = nativeDeaths(pl)
		if count > deaths then deaths, deathLeader = count, pl end
		local distance = pl.ZombieSpawnDeathDistance
		if distance then
			if distance < nearest then nearest, nearestLeader = distance, pl end
			if distance > furthest then furthest, furthestLeader = distance, pl end
		end
		if not pacifist and WINNER == TEAM_HUMAN and pl.ZombiesKilled == 0 and nativeTeam(pl) == TEAM_HUMAN then pacifist = pl end
	end
	local result = {}
	for index = 1, #keys do
		local spec = keys[index]
		if leaders[spec[1]] then result[spec[1]] = {leaders[spec[1]], spec[1], spec[3] and math.ceil(amounts[index]) or amounts[index]} end
	end
	if humanLeader and humanDamage >= 1 then result[HM_MOSTDAMAGETOUNDEAD] = {humanLeader, HM_MOSTDAMAGETOUNDEAD, math.ceil(humanDamage)} end
	if undeadLeader and undeadDamage >= 1 then result[HM_MOSTDAMAGETOHUMANS] = {undeadLeader, HM_MOSTDAMAGETOHUMANS, math.ceil(undeadDamage)} end
	if deathLeader and deaths >= 30 then result[HM_USEFULTOOPPOSITE] = {deathLeader, HM_USEFULTOOPPOSITE, deaths} end
	if nearestLeader and nearest <= 1000 then result[HM_STUPID] = {nearestLeader, HM_STUPID, math.ceil(nearest / 12)} end
	if furthestLeader and furthest >= 8000 then result[HM_OUTLANDER] = {furthestLeader, HM_OUTLANDER, math.ceil(furthest / 12)} end
	if pacifist then result[HM_PACIFIST] = {pacifist, HM_PACIFIST, 0} end
	for _, id in ipairs({HM_LASTHUMAN, HM_LASTBITE}) do
		local mention = self.HonorableMentions[id]
		if mention then
			local pl, magnitude = mention.GetPlayer(self)
			if pl then result[id] = {pl, id, magnitude or 0} end
		end
	end
	return result
end

