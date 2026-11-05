local FEAR_RANGE = 768
local FEAR_RANGE_SQR = FEAR_RANGE * FEAR_RANGE
local FEAR_PERINSTANCE = 0.075
local RALLYPOINT_THRESHOLD = 0.3

local function GetEpicenter(tab)
	local vec = Vector(0, 0, 0)
	if #tab == 0 then return vec end

	for k, v in pairs(tab) do
		vec:Add(v:GetPos())
	end

	return vec / #tab
end

function GM:GetTeamRallyGroups(teamid)
	local groups, ingroup, players, positions = {}, {}, {}, {}
	for _, pl in player.Iterator() do
		if pl:Team() == teamid and pl:Alive() then
			players[#players + 1] = pl
			positions[#players] = pl:GetPos()
		end
	end
	for index, pl in ipairs(players) do
		if not ingroup[index] then
			local members = {index}
			for otherindex, other in ipairs(players) do
				if otherindex ~= index and not ingroup[otherindex] and positions[otherindex]:DistToSqr(positions[index]) <= FEAR_RANGE_SQR then members[#members + 1] = otherindex end
			end
			if #members * FEAR_PERINSTANCE >= RALLYPOINT_THRESHOLD then
				local group = {}
				for _, member in ipairs(members) do ingroup[member] = true;group[#group + 1] = players[member] end
				groups[#groups + 1] = group
			end
		end
	end
	return groups
end

function GM:GetTeamRallyPoints(teamid)
	local points = {}

	for _, group in pairs(self:GetTeamRallyGroups(teamid)) do
		points[#points + 1] = {GetEpicenter(group), math.min(1, (#group * FEAR_PERINSTANCE - RALLYPOINT_THRESHOLD) / (1 - RALLYPOINT_THRESHOLD))}
	end

	return points
end

local CachedEpicentreTimes = {}
local CachedEpicentres = {}
function GM:GetTeamEpicentre(teamid, nocache)
	if not nocache and CachedEpicentres[teamid] and CurTime() < CachedEpicentreTimes[teamid] then
		return CachedEpicentres[teamid]
	end

	local count = 0
	local vVec = Vector(0, 0, 0)
	for _, pl in player.Iterator() do
		if pl:Team() == teamid and pl:Alive() then
			vVec:Add(pl:GetPos())
			count = count + 1
		end
	end

	local epicentre = count > 0 and vVec / count or vVec
	if not nocache then
		CachedEpicentreTimes[teamid] = CurTime() + 0.5
		CachedEpicentres[teamid] = epicentre
	end

	return epicentre
end
GM.GetTeamEpicenter = GM.GetTeamEpicentre

function GM:GetFearMeterPower(pos, teamid, ignore)
	if LASTHUMAN then return 1 end

	local power = 0

	for _, pl in player.Iterator() do
		if pl ~= ignore and pl:Team() == teamid and pl:Alive() and not pl:CallZombieFunction("DoesntGiveFear") then
			local distsqr = pl:NearestPoint(pos):DistToSqr(pos)
			if distsqr <= FEAR_RANGE_SQR then
				local dist = math.sqrt(distsqr)
				power = power + ((FEAR_RANGE - dist) / FEAR_RANGE) * (pl:GetZombieClassTable().FearPerInstance or FEAR_PERINSTANCE)
			end
		end
	end

	return math.min(1, power)
end

