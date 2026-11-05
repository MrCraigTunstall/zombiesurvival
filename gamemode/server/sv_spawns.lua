GM.ZSLastSpawnPoints = GM.ZSLastSpawnPoints or {}
local last = GM.ZSLastSpawnPoints
local function Live(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end

function GM:SetupSpawnPoints()
	local queried = {}
	local function Class(class)
		local entities = queried[class]
		if not entities then entities = ents.FindByClass(class); queried[class] = entities end
		return entities
	end
	local function Append(target, seen, class)
		for _, entity in ipairs(Class(class)) do
			if Live(entity) and not seen[entity] then target[#target + 1], seen[entity] = entity, true end
		end
	end
	local zombies, humans, zombieSet, humanSet = {}, {}, {}, {}
	for _, class in ipairs({"info_player_undead", "info_player_zombie", "info_player_rebel"}) do Append(zombies, zombieSet, class) end
	for _, class in ipairs({"info_player_human", "info_player_combine"}) do Append(humans, humanSet, class) end
	local prefix = string.sub(string.lower(game.GetMap()), 1, 3)
	Append(zombies, zombieSet, (prefix == "cs_" or prefix == "zs_") and "info_player_counterterrorist" or "info_player_terrorist")
	Append(humans, humanSet, (prefix == "cs_" or prefix == "zs_") and "info_player_terrorist" or "info_player_counterterrorist")
	for _, entity in ipairs(Class("gmod_player_start")) do
		if Live(entity) then
			local target, seen = entity.BlueTeam and humans or zombies, entity.BlueTeam and humanSet or zombieSet
			if not seen[entity] then target[#target + 1], seen[entity] = entity, true end
		end
	end
	if #humans == 0 then
		Append(humans, humanSet, "info_player_start")
		Append(humans, humanSet, "info_player_deathmatch")
	end
	if #zombies == 0 then
		Append(zombies, zombieSet, "info_player_start")
		Append(zombies, zombieSet, "info_zombiespawn")
	end
	team.SetSpawnPoint(TEAM_UNDEAD, zombies)
	for _, teamid in ipairs({TEAM_HUMAN, TEAM_REDEEMER, TEAM_SPECTATOR}) do team.SetSpawnPoint(teamid, humans) end
	self.RedeemSpawnPoints, self.BossSpawnPoints = {}, {}
	Append(self.RedeemSpawnPoints, {}, "info_player_redeemed")
	local bosses = {}
	Append(self.BossSpawnPoints, bosses, "info_player_zombie_boss")
	Append(self.BossSpawnPoints, bosses, "info_player_undead_boss")
	for teamid in pairs(last) do last[teamid] = nil end
end

local standardMins, standardMaxs = Vector(-16, -16, 0), Vector(16, 16, 72)
local up = Vector(0, 0, 1)

function GM:GetSpawnHull(pl)
	if pl:Team() == TEAM_UNDEAD then
		local class = self:GetWaveActive() and pl.DeathClass and self.ZombieClasses[pl.DeathClass] or pl:GetZombieClassTable()
		if class and class.Hull then return class.Hull[1], class.Hull[2] end
	end
	return standardMins, standardMaxs
end

function GM:IsSpawnPositionClear(pl, position, overlap)
	local mins, maxs = self:GetSpawnHull(pl)
	local pos = position + up
	if not util.IsInWorld(pos + mins) or not util.IsInWorld(pos + maxs) then return false end
	if not pl.ZSSpawnTraceFilter then
		pl.ZSSpawnTraceFilter = function(ent)
			if ent == pl or not IsValid(ent) then return false end
			if ent:IsPlayer() then return not pl.ZSSpawnTraceOverlap and ent:Alive() end
			return not (ent.ShouldNotCollide and ent:ShouldNotCollide(pl))
		end
	end
	local previous = pl.ZSSpawnTraceOverlap
	pl.ZSSpawnTraceOverlap = overlap
	local trace = util.TraceHull({start = pos, endpos = pos, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = pl.ZSSpawnTraceFilter})
	pl.ZSSpawnTraceOverlap = previous
	return not trace.Hit and not trace.StartSolid and not trace.AllSolid
end

local function Valid(spawn)
	return Live(spawn) and not spawn.Disabled and spawn:IsInWorld()
end

local function HasSpawnPoint(points)
	if not points then return false end
	for _, spawn in ipairs(points) do if Valid(spawn) then return true end end
	return false
end

local function Record(pl, teamid, spawn, anchor, overlap)
	last[teamid] = anchor or spawn
	local source = anchor or spawn
	pl.SpawnedOnSpawnPoint = source:GetClass():sub(1, 11) == "info_player"
	pl.DidntSpawnOnSpawnPoint = pl.DidntSpawnOnSpawnPoint or not pl.SpawnedOnSpawnPoint
	pl.ZSSpawnPlayerOverlap = overlap or nil
	return spawn
end

function GM:GetSpawnOffset(pl, anchor, overlap)
	local origin = anchor:GetPos()
	for attempt = 1, 16 do
		local angle = (attempt - 1) * math.pi / 4 + (pl:EntIndex() % 8) * math.pi / 4
		local radius = attempt <= 8 and 48 or 96
		local candidate = origin + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		local ground = util.TraceLine({start = candidate + Vector(0, 0, 64), endpos = candidate - Vector(0, 0, 128), mask = MASK_PLAYERSOLID_BRUSHONLY})
		if ground.Hit and not ground.HitSky and not ground.StartSolid and not ground.AllSolid and ground.HitNormal.z >= 0.65 then
			local pos = ground.HitPos + Vector(0, 0, 2)
			if WorldVisible(origin + Vector(0, 0, 32), pos + Vector(0, 0, 32)) and self:IsSpawnPositionClear(pl, pos, overlap) then
				local proxy = pl.ZSSpawnProxy
				if not Live(proxy) then proxy = ents.Create("info_target"); pl.ZSSpawnProxy = proxy; if Live(proxy) then proxy:Spawn() end end
				if not Live(proxy) then return end
				proxy:SetPos(pos); proxy:SetAngles(anchor:GetAngles())
				return proxy
			end
		end
	end
end

function GM:PlayerSelectSpawn(pl)
	pl.ZSSpawnPlayerOverlap = nil
	pl.ZSSpawnPlacementFailed = nil
	local teamid, points, epicenter, overlap = pl:Team(), nil, nil, false
	local class = pl:GetZombieClassTable()
	if pl.m_PreRedeem and teamid == TEAM_HUMAN and HasSpawnPoint(self.RedeemSpawnPoints) then
		points = self.RedeemSpawnPoints
	elseif teamid == TEAM_UNDEAD then
		local pending = pl.DeathClass and self.ZombieClasses[pl.DeathClass]
		if class and class.Boss and (not pl.DeathClass or pending and pending.Boss) and HasSpawnPoint(self.BossSpawnPoints) then
			points = self.BossSpawnPoints
		elseif self.DynamicSpawning then
			if self:ShouldUseAlternateDynamicSpawn() then
				for _, human in player.Iterator() do
					if human:Team() == TEAM_HUMAN and human:GetPos():DistToSqr(pl:GetPos()) < 1048576 then epicenter = pl.KilledPos; break end
				end
				if not epicenter then
					local best = self:GetBestDynamicSpawn(pl)
					if Valid(best) and self:IsSpawnPositionClear(pl, best:GetPos(), true) then return Record(pl, teamid, best, nil, best:IsPlayer()) end
				end
			else
				local forced = pl.ForceDynamicSpawn
				pl.ForceDynamicSpawn = nil
				if Valid(forced) and self:DynamicSpawnIsValid(forced) and self:IsSpawnPositionClear(pl, forced:GetPos(), true) then
					if forced:GetClass() == "prop_creepernest" then
						local owner = forced:GetOwner()
						if IsValid(owner) and owner:Team() == TEAM_UNDEAD then owner.NestSpawns = (owner.NestSpawns or 0) + 1 end
					end
					return Record(pl, teamid, forced, nil, forced:IsPlayer())
				end
			end
			points = team.GetValidSpawnPoint(TEAM_UNDEAD) or {}
			local dynamic = self:GetDynamicSpawns(pl)
			for _, spawn in ipairs(dynamic) do points[#points + 1] = spawn end
			overlap = #dynamic > 0
		end
	end
	if not points or #points == 0 then points = team.GetValidSpawnPoint(teamid) or {} end
	local valid = {}
	for _, spawn in ipairs(points) do
		if Valid(spawn) and (spawn:IsPlayer() or spawn ~= last[teamid] or #points == 1)
			and self:IsSpawnPositionClear(pl, spawn:GetPos(), overlap) then valid[#valid + 1] = spawn end
	end
	if #valid > 0 then
		local chosen
		if teamid == TEAM_UNDEAD and (pl:KeyDown(IN_ATTACK2) or pl:KeyDown(IN_RELOAD) or math.random(2) == 1) then
			local centre = epicenter or self:GetTeamEpicentre(TEAM_HUMAN)
			chosen = not pl:KeyDown(IN_ATTACK2) and pl:KeyDown(IN_RELOAD) and self:GetFurthestSpawnPoint(valid, centre) or self:GetClosestSpawnPoint(valid, centre)
		else chosen = valid[math.random(#valid)] end
		if chosen then return Record(pl, teamid, chosen, nil, chosen:IsPlayer()) end
	end
	local checked = 0
	for _, anchor in ipairs(points) do
		if Valid(anchor) then
			checked = checked + 1
			local proxy = self:GetSpawnOffset(pl, anchor, false)
			if proxy then return Record(pl, teamid, proxy, anchor, false) end
			if checked >= 8 then break end
		end
	end
	for _, spawn in ipairs(points) do
		if Valid(spawn) and self:IsSpawnPositionClear(pl, spawn:GetPos(), true) then return Record(pl, teamid, spawn, nil, true) end
	end
	if Valid(last[teamid]) and self:IsSpawnPositionClear(pl, last[teamid]:GetPos(), true) then return Record(pl, teamid, last[teamid], nil, true) end
	pl.SpawnedOnSpawnPoint, pl.DidntSpawnOnSpawnPoint = false, true
	if not self:IsSpawnPositionClear(pl, pl:GetPos(), true) then pl.ZSSpawnPlacementFailed = true end
	return pl
end

hook.Add("PlayerDisconnected", "ZSSpawnProxy", function(pl) if Live(pl.ZSSpawnProxy) then pl.ZSSpawnProxy:Remove() end end)
hook.Add("PostCleanupMap", "ZSSpawnProxy", function()
	for teamid in pairs(last) do last[teamid] = nil end
end)

local playerheight = Vector(0, 0, 72)
local playermins = Vector(-17, -17, 0)
local playermaxs = Vector(17, 17, 4)
local function groupsort(a, b)
	return #a > #b
end
function GM:AttemptHumanDynamicSpawn(pl)
    if not pl:IsValid() or not pl:IsPlayer() or not pl:Alive() or pl:Team() == TEAM_UNDEAD or not self.DynamicSpawning then return false end
    local groups = self:GetTeamRallyGroups(TEAM_HUMAN)
    table.sort(groups, groupsort)
    if #groups == 0 then return false end
    local humans = team.GetPlayers(TEAM_HUMAN)
    local zombies
    local trace = {mins = playermins, maxs = playermaxs, mask = MASK_SOLID, filter = humans}
    for i = 1, #groups do
        local group = groups[i]
        for _, otherpl in pairs(group) do
            if otherpl ~= pl and otherpl:Alive() and otherpl:GetMoveType() == MOVETYPE_WALK then
                local pos = otherpl:GetPos() + Vector(0, 0, 1)
                trace.start, trace.endpos = pos, pos + playerheight
                if not util.TraceHull(trace).Hit then
                    if not zombies then zombies = team.GetPlayers(TEAM_UNDEAD) end
                    local nearzombie = false
                    for _, ent in pairs(zombies) do
                        if ent:Alive() and ent:GetPos():DistToSqr(pos) <= 65536 then
                            nearzombie = true
                            break
                        end
                    end
                    if not nearzombie then
                        pl:SetPos(otherpl:GetPos())
                        return true
                    end
                end
            end
        end
    end
    return false
end

