local meta = FindMetaTable("Player")
if not meta then return end

local MASK_SOLID, MASK_SOLID_BRUSHONLY = MASK_SOLID, MASK_SOLID_BRUSHONLY
local teamPlayers, playerIterator = team.GetPlayers, player.Iterator
local pooledFilter = type(teamPlayers) == "function" and type(playerIterator) == "function"
	and debug.getinfo(teamPlayers, "S").source == "@lua/includes/modules/team.lua"
	and debug.getinfo(playerIterator, "S").source == "@lua/includes/extensions/entity_iter.lua"

function meta:TraceLine(distance, mask, filter, start)
	start = start or self:GetShootPos()
	local endpos = self:GetAimVector() * distance
	endpos:Add(start)
	return util.TraceLine({start = start, endpos = endpos, filter = filter or self, mask = mask})
end

function meta:TraceHull(distance, mask, size, filter, start)
	start = start or self:GetShootPos()
	return util.TraceHull({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask, mins = Vector(-size, -size, -size), maxs = Vector(size, size, size)})
end

function meta:DoubleTrace(distance, mask, size, mask2, filter)
	local tr1 = self:TraceLine(distance, mask, filter)
	if tr1.Hit then return tr1 end
	if mask2 then
		local tr2 = self:TraceLine(distance, mask2, filter)
		if tr2.Hit then return tr2 end
	end
	local tr3 = self:TraceHull(distance, mask, size, filter)
	if tr3.Hit then return tr3 end
	if mask2 then
		local tr4 = self:TraceHull(distance, mask2, size, filter)
		if tr4.Hit then return tr4 end
	end
	return tr1
end

function meta:GetMeleeFilter()
	return GAMEMODE.RoundEnded and {self} or team.GetPlayers(self:Team())
end
meta.GetTraceFilter = meta.GetMeleeFilter

function meta:MeleeTrace(distance, size, filter, start)
	return self:TraceHull(distance, MASK_SOLID, size, filter, start)
end

local function DynamicTraceFilter(ent)
	if ent:IsPlayer() or ent.IgnoreTraces then return false end
	return true
end

function meta:GetDynamicTraceFilter()
	return DynamicTraceFilter
end

local defaultMeleeFilter = meta.GetMeleeFilter
local frames, depth = {}, 0

local function PenetratingTrace(self, frame, distance, size, prehit, start, dir)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()
	local filter
	if pooledFilter and self.GetMeleeFilter == defaultMeleeFilter and team.GetPlayers == teamPlayers and player.Iterator == playerIterator then
		filter = frame.filter
		if GAMEMODE.RoundEnded then filter[1] = self
		else
			local teamid = self:Team()
			for _, pl in playerIterator() do if pl:Team() == teamid then filter[#filter + 1] = pl end end
		end
	else filter = self:GetMeleeFilter() end
	frame.endpos:Set(dir) frame.endpos:Mul(distance) frame.endpos:Add(start)
	frame.mins:SetUnpacked(-size, -size, -size) frame.maxs:SetUnpacked(size, size, size)
	local trace = frame.trace
	trace.start, trace.endpos, trace.filter, trace.mask, trace.mins, trace.maxs = start, frame.endpos, filter, MASK_SOLID, frame.mins, frame.maxs
	local result, onlyhitworld = {}, nil
	for i = 1, 50 do
		local tr = util.TraceHull(trace)
		if not tr.Hit then break end
		if tr.HitWorld then result[#result + 1] = tr break end
		if onlyhitworld then break end
		local ent = tr.Entity
		if ent and ent:IsValid() then
			if not ent:IsPlayer() then trace.mask, onlyhitworld = MASK_SOLID_BRUSHONLY, true end
			result[#result + 1] = tr filter[#filter + 1] = ent
		end
	end
	if prehit and (#result == 1 and not result[1].HitNonWorld and prehit.HitNonWorld or #result == 0 and prehit.HitNonWorld) then result[1] = prehit end
	return result
end

function meta:PenetratingMeleeTrace(distance, size, prehit, start, dir)
	depth = depth + 1
	local frame = frames[depth]
	if not frame then frame = {trace = {}, filter = {}, endpos = Vector(), mins = Vector(), maxs = Vector()} frames[depth] = frame end
	local ok, result = pcall(PenetratingTrace, self, frame, distance, size, prehit, start, dir)
	for key in pairs(frame.trace) do frame.trace[key] = nil end
	for key in pairs(frame.filter) do frame.filter[key] = nil end
	depth = depth - 1
	if not ok then error(result, 0) end
	return result
end
