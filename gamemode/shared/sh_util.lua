local previousGetAllActive = player.GetAllActive
if previousGetAllActive == nil or debug.getinfo(previousGetAllActive, "S").source:find("sh_util.lua", 1, true) then
	function player.GetAllActive()
		local t = {}

		for _, pl in player.Iterator() do
			if not pl:IsSpectator() then
				t[#t + 1] = pl
			end
		end

		return t
	end
end

function player.GetAllSpectators()
	local t = {}

	for _, pl in player.Iterator() do
		if pl:IsSpectator() then
			t[#t + 1] = pl
		end
	end

	return t
end

-- Takes a table of false/trues with numbers as the keys, compresses to array of chars (8 bits), in other words a string, for storage in files.
-- The net library already uses the smallest number of bits needed so this is only for storing data.
function util.CompressBitTable(t)
	local buf = {}
	local maxvalue = 0

	t = table.ToAssoc(t)

	for k in pairs(t) do
		if k > maxvalue then maxvalue = k end
	end
	local num_bytes = math.ceil(maxvalue / 8)

	for on_byte = 1, num_bytes do
		local byte = 0

		for bit_slot = 1, 8 do
			if t[bit_slot + 8 * (on_byte - 1)] then
				byte = bit.bor(byte, 2 ^ (bit_slot - 1))
			end
		end

		buf[on_byte] = string.char(byte)
	end

	return table.concat(buf)
end

function util.DecompressBitTable(str, associative)
	local t = {}

	for on_byte = 1, #str do
		local byte = str:byte(on_byte)
		for bit_slot = 1, 8 do
			if bit.band(byte, 1) == 1 then
				local v = bit_slot + 8 * (on_byte - 1)
				if associative then
					t[v] = true
				else
					t[#t + 1] = v
				end
			end
			byte = bit.arshift(byte, 1)
		end
	end

	return t
end

function table.IsAssoc(t)
	for _, v in pairs(t) do
		if type(v) == "boolean" then
			return true
		end

		return false
	end
end

function table.ToAssoc(t)
	if not table.IsAssoc(t) then
		local t2 = {}

		for k, v in pairs(t) do
			t2[v] = true
		end

		return t2
	end

	return t
end

function table.ToKeyValues(t)
	if table.IsAssoc(t) then
		local t2 = {}

		for k, v in pairs(t) do
			if v then
				t2[#t2 + 1] = k
			end
		end

		return t2
	end

	return t
end

function FindStartingItem(id)
	local t = FindItem(id)
	if t and t.WorthShop then return t end
end

function FindItem(id)
	if type(id) ~= "string" and type(id) ~= "number" then return end
	local num = tonumber(id)
	if num then
		if num % 1 ~= 0 then return end
		return GAMEMODE.Items[num]
	end
	return GAMEMODE.ItemsBySignature[id]
end

MASK_SHOT_OPAQUE = bit.bor(MASK_SHOT, CONTENTS_OPAQUE)
-- Literally if photon particles can reach point b from point a.
function LightVisible(posa, posb, ...)
	local filter = {}
	for i = 1, select("#", ...) do
		local ent = select(i, ...)
		if ent ~= nil then filter[#filter + 1] = ent end
	end

	return not util.TraceLine({start = posa, endpos = posb, mask = MASK_SHOT_OPAQUE, filter = filter}).Hit
end

function WorldVisible(posa, posb)
	return not util.TraceLine({start = posa, endpos = posb, mask = MASK_SOLID_BRUSHONLY}).Hit
end

function ValidFunction(ent, funcname, ...)
	if ent and ent:IsValid() and ent[funcname] then
		return ent[funcname](ent, ...)
	end
end

function CosineInterpolation(y1, y2, mu)
	local mu2 = (1 - math.cos(mu * math.pi)) / 2
	return y1 * (1 - mu2) + y2 * mu2
end

function string.AndSeparate(list)
	local length = #list
	if length <= 0 then return "" end
	if length == 1 then return list[1] end
	if length == 2 then return list[1].." "..translate.Get("classes_and").." "..list[2] end

	return table.concat(list, ", ", 1, length - 1)..", "..translate.Get("classes_and").." "..list[length]
end

function util.IncreaseLetter(letter)
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	local index = alphabet:find(letter, 1, true)
	if index then
		index = (index % #alphabet) + 1
		return alphabet:sub(index, index)
	end
end

function util.SkewedDistance(a, b, skew)
	if a.z > b.z then
		return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + ((a.z - b.z) * skew) ^ 2)
	end

	return a:Distance(b)
end

function util.Blood(pos, amount, dir, force, noprediction)
	local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		effectdata:SetMagnitude(amount)
		effectdata:SetNormal(dir)
		effectdata:SetScale(math.max(128, force))
	util.Effect("bloodstream", effectdata, nil, noprediction)
end

-- I had to make this since the default function checks visibility vs. the entitiy's center and not the nearest position.
function util.FindValidInSphere(pos, radius)
	local ret = {}

	local find = type(util.FindInSphere) == "function" and util.FindInSphere or ents.FindInSphere
	for _, ent in pairs(find(pos, radius)) do
		if ent and ent:IsValid() then
			ret[#ret + 1] = ent
		end
	end

	return ret
end

local function FiniteBlastNumber(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function util.PoisonBlastDamage(inflictor, attacker, epicenter, radius, damage, noreduce)
	if not isvector(epicenter) or not FiniteBlastNumber(epicenter.x) or not FiniteBlastNumber(epicenter.y)
		or not FiniteBlastNumber(epicenter.z) or not FiniteBlastNumber(radius) or radius <= 0 or not FiniteBlastNumber(damage) then return end
	for _, ent in pairs(ents.FindInSphere(epicenter, radius)) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() then
			local nearest = ent:NearestPoint(epicenter)
			local distance = nearest:Distance(epicenter)
			if distance <= radius and TrueVisibleFilters(epicenter, nearest, inflictor, ent)
				and IsValid(ent) and not ent:IsMarkedForDeletion() then
				ent:PoisonDamage(((radius - distance) / radius) * damage, attacker, inflictor, nil, noreduce)
			end
		end
	end
end

function util.ToMinutesSeconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

    return string.format("%02d:%02d", minutes, math.floor(seconds))
end

function util.ToMinutesSecondsMilliseconds(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60

	local milliseconds = math.floor(seconds % 1 * 100)

    return string.format("%02d:%02d.%02d", minutes, math.floor(seconds), milliseconds)
end

function util.RemoveAll(class)
	for _, ent in pairs(ents.FindByClass(class)) do
		ent:Remove()
	end
end

local function SpawnPointLive(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end

function team.GetSpawnPointGrouped(teamid, distance)
	distance = distance or 200
	local grouped, positions = {}, {}
	for _, spawn in pairs(team.GetSpawnPoint(teamid) or {}) do
		if SpawnPointLive(spawn) then
			local position, near = spawn:GetPos(), false
			for _, other in ipairs(positions) do
				if other:Distance(position) <= distance then near = true break end
			end
			if not near then grouped[#grouped + 1], positions[#positions + 1] = spawn, position end
		end
	end
	return grouped
end

function AccessorFuncDT(tab, membername, type, id)
	local emeta = FindMetaTable("Entity")
	local setter = emeta["SetDT"..type]
	local getter = emeta["GetDT"..type]

	tab["Set"..membername] = function(me, val)
		setter(me, id, val)
	end

	tab["Get"..membername] = function(me)
		return getter(me, id)
	end
end

function team.GetValidSpawnPoint(teamid)
	local t = {}

	local spawns = team.GetSpawnPoint(teamid)
	if spawns then
		for _, ent in pairs(spawns) do
			if SpawnPointLive(ent) then
				t[#t + 1] = ent
			end
		end
	end

	return t
end

function timer.SimpleEx(delay, action, ...)
	local count = select("#", ...)
	if count == 0 then
		timer.Simple(delay, action)
	else
		local args = {...}
		timer.Simple(delay, function() action(unpack(args, 1, count)) end)
	end
end

function timer.CreateEx(timername, delay, repeats, action, ...)
	local count = select("#", ...)
	if count == 0 then
		timer.Create(timername, delay, repeats, action)
	else
		local args = {...}
		timer.Create(timername, delay, repeats, function() action(unpack(args, 1, count)) end)
	end
end

function ents.CreateLimited(class, limit)
	if #ents.FindByClass(class) >= (limit or 200) then return NULL end

	return ents.Create(class)
end

function tonumbersafe(a)
	local n = tonumber(a)

	if n then
		if n == 0 or n < 0 or n > 0 then
			return n
		end

		-- NaN!
		return 0
	end

	return nil
end

local function TraceVisible(posa, posb, excluded, count)
	return not util.TraceLine({start = posa, endpos = posb, mask = MASK_SHOT, filter = function(ent)
		if ent:IsPlayer() or string.sub(ent:GetClass(), 1, 11) == "projectile_"
			or SERVER and (ent.IgnoreTraces or ent.NoBlockExplosions) then return false end
		for i = 1, count do
			if ent == excluded[i] then return false end
		end
		return true
	end}).Hit
end

function TrueVisible(posa, posb, filter)
	return TraceVisible(posa, posb, {filter}, filter and 1 or 0)
end

function TrueVisibleFilters(posa, posb, ...)
	return TraceVisible(posa, posb, {...}, select("#", ...))
end

-- Useful macros for the 3 file system
function INC_SERVER()
	AddCSLuaFile("shared.lua")
	AddCSLuaFile("cl_init.lua")
	include("shared.lua")
end

function INC_CLIENT()
	include("shared.lua")
end
INC_CLIENT_NO_SHARED = INC_CLIENT

function INC_SERVER_NO_SHARED()
	AddCSLuaFile("cl_init.lua")
end

function INC_SERVER_NO_CLIENT()
	AddCSLuaFile("shared.lua")
end

-- Just in case you add this by mistake because it does nothing
function INC_SHARED()
end
