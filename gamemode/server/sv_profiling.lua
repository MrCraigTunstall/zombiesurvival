GM.ProfilerNodes = {}
GM.ProfilerIsPreMade = false
GM.ProfilerReadOnly = false
GM.ProfilerFolder = "zsprofiler"
GM.ProfilerFolderPreMade = "profiler_premade"
GM.ProfilerVersion = 0
GM.MaxProfilerNodes = 128

local function ValidNodes(nodes)
	if type(nodes) ~= "table" then return false end
	local count = 0
	for key, node in pairs(nodes) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or not isvector(node) then return false end
		if node.x ~= node.x or node.y ~= node.y or node.z ~= node.z or math.abs(node.x) == math.huge or math.abs(node.y) == math.huge or math.abs(node.z) == math.huge then return false end
		count = count + 1
	end
	return count == #nodes
end

local function WriteProfiler(path, value)
	local data, previous = Serialize(value), file.Read(path, "DATA")
	file.Write(path, data)
	if file.Read(path, "DATA") == data then return true end
	if previous then file.Write(path, previous) else file.Delete(path) end
	return false
end

hook.Add("Initialize", "ZSProfiler", function()
	file.CreateDir(GAMEMODE.ProfilerFolder)
	file.CreateDir(GAMEMODE.ProfilerFolderPreMade)
end)

local mapname = string.lower(game.GetMap())
if file.Exists(GM.ProfilerFolderPreMade.."/"..mapname..".txt", "DATA") then
	local nodes, failure = Deserialize(file.Read(GM.ProfilerFolderPreMade.."/"..mapname..".txt", "DATA"))
	if not failure and ValidNodes(nodes) then
		GM.ProfilerIsPreMade, GM.ProfilerNodes = true, nodes
	else
		GM.ProfilerReadOnly = true
	end
elseif file.Exists(GM.FolderName.."/gamemode/"..GM.ProfilerFolderPreMade.."/"..mapname..".lua", "LUA") then
	local previous = SRL
	SRL = nil
	local ok = pcall(include, GM.ProfilerFolderPreMade.."/"..mapname..".lua")
	local nodes = SRL
	SRL = previous
	if ok and ValidNodes(nodes) then
		GM.ProfilerIsPreMade, GM.ProfilerNodes = true, nodes
	else
		GM.ProfilerReadOnly = true
	end
end

function GM:ClearProfiler()
	if not self:ProfilerEnabled() then return false end
	return self:SaveProfiler()
end

function GM:SaveProfilerPreMade(nodes)
	if not ValidNodes(nodes) then return false end
	return WriteProfiler(self:GetProfilerFilePreMade(), nodes)
end

function GM:DeleteProfilerPreMade()
	local path = self:GetProfilerFilePreMade()
	file.Delete(path)
	return not file.Exists(path, "DATA")
end

function GM:SaveProfiler()
	if not self:ProfilerEnabled() or self.ProfilerIsPreMade or self.ProfilerReadOnly or not ValidNodes(self.ProfilerNodes) then return false end
	return WriteProfiler(self:GetProfilerFile(), {Nodes = self.ProfilerNodes, Version = self.ProfilerVersion})
end

function GM:LoadProfiler()
	if not self:ProfilerEnabled() or self.ProfilerIsPreMade then return false end
	local path = self:GetProfilerFile()
	if not file.Exists(path, "DATA") then self.ProfilerReadOnly = false return false end
	local data, failure = Deserialize(file.Read(path, "DATA"))
	local nodes
	if not failure then
		if data.Version == nil and self.ProfilerVersion == 0 then
			nodes = data
		elseif type(data.Version) == "number" and data.Version >= self.ProfilerVersion and data.Version < math.huge and data.Version % 1 == 0 then
			nodes = data.Nodes
		end
	end
	self.ProfilerReadOnly = not ValidNodes(nodes)
	if self.ProfilerReadOnly then return false end
	self.ProfilerNodes = nodes
	return true
end

function GM:GetProfilerFile()
	return self.ProfilerFolder.."/"..string.lower(game.GetMap())..".txt"
end

function GM:GetProfilerFilePreMade()
	return self.ProfilerFolderPreMade.."/"..string.lower(game.GetMap())..".txt"
end

function GM:ProfilerEnabled()
	return not self.ZombieEscape and not self.ObjectiveMap
end

function GM:NeedsProfiling()
	return #self.ProfilerNodes < self.MaxProfilerNodes and not self.ProfilerIsPreMade and not self.ProfilerReadOnly
end

function GM:DebugProfiler()
	local positions = {}
	for _, entity in ipairs(ents.FindByClass("prop_dynamic*")) do
		if entity.IsNode then positions[#positions + 1] = entity:GetPos() end
	end
	for _, node in ipairs(self.ProfilerNodes) do
		local spawned = false
		for _, position in ipairs(positions) do
			if position == node then spawned = true break end
		end
		if not spawned then
			local entity = ents.Create("prop_dynamic_override")
			if IsValid(entity) then
				entity:SetModel("models/player/breen.mdl")
				entity:SetKeyValue("solid", "0")
				entity:SetColor(Color(255, 0, 0))
				entity:SetPos(node)
				entity:Spawn()
				entity.IsNode = true
				positions[#positions + 1] = entity:GetPos()
			end
		end
	end
end

local playerheight = Vector(0, 0, 92)
local playermins = Vector(-24, -24, 0)
local playermaxs = Vector(24, 24, 4)
local vecsky = Vector(0, 0, 32000)
local playerlift = Vector(0, 0, 1)
local ceilingheight = Vector(0, 0, 640)
local floordepth = Vector(0, 0, -64)
local offsets = {}
for yaw = 0, 359, 15 do
	local direction = Angle(0, yaw, 0):Forward()
	for distance = 32, 92, 24 do offsets[#offsets + 1] = direction * distance end
end
local function IgnoreHumans(entity)
	return not entity:IsPlayer() or entity:Team() ~= TEAM_HUMAN
end
local function SkewedDistance(a, b, skew)
	if a.z > b.z then return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + ((a.z - b.z) * skew) ^ 2) end
	return a:Distance(b)
end

function GM:ProfilerPlayerValid(pl)
	if not IsValid(pl) or pl.NoProfiling then return false end
	if not (pl:Team() == TEAM_HUMAN and pl:Alive() and pl:GetMoveType() == MOVETYPE_WALK and not pl:Crouching()
	and pl:OnGround() and pl:IsOnGround() and pl:GetGroundEntity() == game.GetWorld()) then return false end
	local plpos = pl:GetPos()
	for _, node in ipairs(self.ProfilerNodes) do
		if SkewedDistance(node, plpos, 3) <= 128 then return false end
	end
	local pos = plpos + playerlift
	if util.TraceHull({start = pos, endpos = pos + playerheight, mins = playermins, maxs = playermaxs, mask = MASK_SOLID, filter = IgnoreHumans}).Hit then return false end
	local plcenter = pl:LocalToWorld(pl:OBBCenter())
	for _, entity in ipairs(ents.FindInSphere(plcenter, 256)) do
		if IsValid(entity) and entity:GetClass() == "trigger_hurt" then return false end
	end
	for _, entity in pairs(team.GetValidSpawnPoint(TEAM_UNDEAD)) do
		if entity:GetPos():Distance(plcenter) < 420 then return false end
	end
	local trace = {start = plcenter, endpos = plcenter + vecsky, mins = playermins, maxs = playermaxs, mask = MASK_SOLID_BRUSHONLY}
	local sky = util.TraceHull(trace)
	if sky.HitSky or sky.HitNoDraw then return false end
	for _, offset in ipairs(offsets) do
		trace.start = plcenter + offset
		trace.endpos = trace.start + ceilingheight
		local ceiling = util.TraceHull(trace)
		if not ceiling.Hit or ceiling.HitNormal.z > -0.65 then return false end
		trace.endpos = trace.start + floordepth
		local floor = util.TraceHull(trace)
		if not floor.Hit or floor.HitNormal.z < 0.65 then return false end
	end
	return true
end

function GM:ProfilerTick()
	if not self:ProfilerEnabled() or not self:NeedsProfiling() then return end
	local changed = false
	for _, pl in player.Iterator() do
		if not self:NeedsProfiling() then break end
		if self:ProfilerPlayerValid(pl) then
			self.ProfilerNodes[#self.ProfilerNodes + 1] = pl:GetPos()
			changed = true
		end
	end
	if changed then self:SaveProfiler() end
end
local function TickProfiler() GAMEMODE:ProfilerTick() end
timer.Create("ZSProfiler", 3, 0, TickProfiler)
hook.Add("OnWaveStateChanged", "ZSProfiler", function()
	if GAMEMODE:GetWave() > 0 then timer.Destroy("ZSProfiler")
	elseif not timer.Exists("ZSProfiler") then timer.Create("ZSProfiler", 3, 0, TickProfiler) end
end)
