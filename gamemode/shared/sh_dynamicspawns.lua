local playerheight = Vector(0, 0, 72)
local playermins = Vector(-17, -17, 0)
local playermaxs = Vector(17, 17, 4)
local up = Vector(0, 0, 1)
local SkewedDistance = util.SkewedDistance

local function Live(ent)
	return IsValid(ent) and not ent:IsMarkedForDeletion()
end

local function ClearHull(pos, mask, filter)
	local trace = {start = pos, endpos = pos + playerheight, mins = playermins, maxs = playermaxs, mask = mask, filter = filter}
	if util.TraceHull(trace).Hit then return false end
	trace.endpos = pos - playerheight
	trace.mask = MASK_SOLID_BRUSHONLY
	trace.filter = nil
	local ground = util.TraceHull(trace)
	return not ground.HitSky and not ground.HitNoDraw
end

GM.DynamicSpawnDistVisOld = 2048
GM.DynamicSpawnDistOld = 640

function GM:DynamicSpawnIsValidOld(zombie, humans, allplayers)
	if not Live(zombie) or not zombie:IsPlayer() then return false end
	if SERVER and zombie.LastHitWithTriggerHurt and CurTime() < zombie.LastHitWithTriggerHurt + 2 then return false end
	if not zombie:Alive() or zombie:GetMoveType() ~= MOVETYPE_WALK or not zombie:OnGround() then return false end
	allplayers = allplayers or player.GetAll()
	local pos = zombie:GetPos() + up
	if not ClearHull(pos, MASK_SOLID, allplayers) then return false end
	humans = humans or team.GetPlayers(TEAM_HUMAN)
	for _, human in pairs(humans) do
		if Live(human) then
			local hpos = human:GetPos()
			local nearest = zombie:NearestPoint(hpos)
			local dist = SkewedDistance(hpos, nearest, 2.75)
			if dist <= self.DynamicSpawnDistOld or dist <= self.DynamicSpawnDistVisOld and WorldVisible(hpos, nearest) then return false end
		end
	end
	return true
end

function GM:GetBestDynamicSpawnOld(pl, pos)
	local spawns = self:GetDynamicSpawnsOld(pl)
	if #spawns == 0 then return end
	return self:GetClosestSpawnPoint(spawns, pos or self:GetTeamEpicentre(TEAM_HUMAN)) or table.Random(spawns)
end

function GM:GetDynamicSpawnsOld(pl)
	local tab = {}
	local allplayers = player.GetAll()
	local humans = team.GetPlayers(TEAM_HUMAN)
	for _, zombie in pairs(team.GetPlayers(TEAM_UNDEAD)) do
		if zombie ~= pl and Live(zombie) and self:DynamicSpawnIsValidOld(zombie, humans, allplayers) then tab[#tab + 1] = zombie end
	end
	return tab
end

GM.DynamicSpawnDist = 400
GM.DynamicSpawnDistBuild = 650

function GM:DynamicSpawnIsValid(nest, humans, allplayers)
	if self:ShouldUseAlternateDynamicSpawn() then return self:DynamicSpawnIsValidOld(nest, humans, allplayers) end
	if not Live(nest) or not nest.GetNestBuilt or not nest:GetNestBuilt() then return false end
	local nearest = nest:GetPos()
	if not ClearHull(nearest + up, MASK_SOLID_BRUSHONLY) then return false end
	humans = humans or team.GetPlayers(TEAM_HUMAN)
	for _, human in pairs(humans) do
		if Live(human) and SkewedDistance(human:GetPos(), nearest, 2.75) <= self.DynamicSpawnDist then return false end
	end
	return true
end

function GM:GetBestDynamicSpawn(pl, pos)
	if self:ShouldUseAlternateDynamicSpawn() then return self:GetBestDynamicSpawnOld(pl, pos) end
	local spawns = self:GetDynamicSpawns(pl)
	if #spawns == 0 then return end
	return self:GetClosestSpawnPoint(spawns, pos or self:GetTeamEpicentre(TEAM_HUMAN)) or table.Random(spawns)
end

function GM:GetDynamicSpawns(pl)
	if self:ShouldUseAlternateDynamicSpawn() then return self:GetDynamicSpawnsOld(pl) end
	local tab = {}
	local humans = team.GetPlayers(TEAM_HUMAN)
	for _, nest in pairs(self:GetZSClassEntities("prop_creepernest")) do
		if Live(nest) and self:DynamicSpawnIsValid(nest, humans) then tab[#tab + 1] = nest end
	end
	return tab
end
