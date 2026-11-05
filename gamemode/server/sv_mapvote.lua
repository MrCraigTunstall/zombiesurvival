util.AddNetworkString("zs_mapvote_catalog")
util.AddNetworkString("zs_mapvote_count")
util.AddNetworkString("zs_mapvote_result")
util.AddNetworkString("zs_mapvote_open")
CreateConVar("zs_mapvote_enabled", "1", FCVAR_ARCHIVE, "Allow voting for the next map.")
GM.ZSMapVotes = GM.ZSMapVotes or {players = {}, counts = {}, catalog = {}, allowed = {}}
local state = GM.ZSMapVotes
state.revision = state.revision or 0

local function ValidMap(name)
	return type(name) == "string" and #name <= 64 and string.match(name, "^[a-z0-9_%-]+$") and file.Exists("maps/" .. name .. ".bsp", "GAME")
end

function GM:RefreshMapVoteCatalog()
	local catalog, allowed = {}, {}
	local path = GetConVar("mapcyclefile"):GetString()
	local cycle = file.Read(path, "GAME")
	if not cycle then cycle = file.Read("cfg/" .. path, "GAME") end
	if cycle then
		for line in string.gmatch(cycle, "[^\r\n]+") do
			local name = string.lower(string.Trim((string.gsub(line, "//.*$", ""))))
			if ValidMap(name) and not allowed[name] then catalog[#catalog + 1] = name allowed[name] = true end
		end
	end
	if not cycle then
		local paths = {}
		for _, pattern in ipairs({"maps/zs_*.bsp", "maps/ze_*.bsp", "maps/zm_*.bsp"}) do
			for _, path in ipairs(file.Find(pattern, "GAME")) do paths[#paths + 1] = path end
		end
		for _, path in ipairs(paths) do
			local name = string.lower(string.sub(path, 1, -5))
			if ValidMap(name) and not allowed[name] then catalog[#catalog + 1] = name allowed[name] = true end
		end
	end
	table.sort(catalog)
	state.catalog, state.allowed, state.initialized = catalog, allowed, true
	state.revision = (state.revision + 1) % 4294967296
	for pl, name in pairs(state.players) do if not allowed[name] then state.players[pl] = nil end end
	state.counts = {}
	for pl, name in pairs(state.players) do
		if IsValid(pl) and not pl:IsBot() then state.counts[name] = (state.counts[name] or 0) + 1 else state.players[pl] = nil end
	end
end

local function SendCount(name)
	local recipients = {}
	for _, pl in player.Iterator() do if not pl:IsBot() then recipients[#recipients + 1] = pl end end
	if #recipients == 0 then return end
	net.Start("zs_mapvote_count")
	net.WriteString(name)
	net.WriteUInt(state.counts[name] or 0, 16)
	net.WriteUInt(state.revision, 32)
	net.Send(recipients)
end

local function SendResult(pl, accepted, reason)
	if not IsValid(pl) or pl:IsBot() or (pl.ZSNextMapFeedback or 0) > CurTime() then return end
	pl.ZSNextMapFeedback = CurTime() + 0.25
	net.Start("zs_mapvote_result")
	net.WriteBool(accepted)
	net.WriteString(state.players[pl] or "")
	net.WriteString(reason or "")
	net.Send(pl)
end

function GM:VoteForMap(pl, name)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return false, "mapvote_invalid" end
	if not GetConVar("zs_mapvote_enabled"):GetBool() then return false, "mapvote_disabled" end
	if (pl.ZSNextMapVote or 0) > CurTime() then return false, "mapvote_wait" end
	pl.ZSNextMapVote = CurTime() + 0.5
	if type(name) ~= "string" or not state.allowed[name] or not ValidMap(name) then return false, "mapvote_invalid" end
	local previous = state.players[pl]
	if previous == name then return true, "mapvote_selected" end
	state.players[pl] = name
	state.revision = (state.revision + 1) % 4294967296
	if previous then
		state.counts[previous] = math.max(0, (state.counts[previous] or 0) - 1)
		SendCount(previous)
	end
	state.counts[name] = (state.counts[name] or 0) + 1
	SendCount(name)
	return true, "mapvote_selected"
end

function GM:GetVotedMap()
	if not GetConVar("zs_mapvote_enabled"):GetBool() then return end
	local selected, highest = nil, 0
	for _, name in ipairs(state.catalog) do
		local count = state.counts[name] or 0
		if count > highest and ValidMap(name) then selected, highest = name, count end
	end
	return selected
end

local pending, queue = {}, {}
local first, last = 1, 0
local function Enqueue(request)
	last = last + 1
	queue[last] = request
end
concommand.Add("zs_mapvote_catalog", function(pl, _, args)
	local refresh = type(args) == "table" and args[1] == "refresh"
	if not IsValid(pl) or pl:IsBot() or pending[pl] and not refresh then return end
	if (pl.ZSNextMapCatalog or 0) > CurTime() then return SendResult(pl, false, "mapvote_refresh_wait") end
	if not GetConVar("zs_mapvote_enabled"):GetBool() then SendResult(pl, false, "mapvote_disabled") return end
	local previous = pending[pl]
	if previous then previous.data, previous.player = nil, nil pending[pl] = nil end
	pl.ZSNextMapCatalog = CurTime() + 5
	if not state.initialized then GAMEMODE:RefreshMapVoteCatalog() end
	if state.cacheRevision ~= state.revision then
		local rows = {}
		for _, name in ipairs(state.catalog) do rows[#rows + 1] = {name, state.counts[name] or 0} end
		local data = util.Compress(util.TableToJSON(rows))
		if not data or #data > 4194304 then return SendResult(pl, false, "mapvote_load_failed") end
		state.cacheData, state.cacheRevision = data, state.revision
	end
	local request = {player = pl, data = state.cacheData, offset = 1, revision = state.revision}
	pending[pl] = request
	Enqueue(request)
	SendResult(pl, true)
end)
concommand.Add("zs_votemap", function(pl, _, args)
	local accepted, reason = GAMEMODE:VoteForMap(pl, args[1])
	SendResult(pl, accepted, reason)
end)
concommand.Add("zs_mapvote_refresh", function(pl)
	if IsValid(pl) and not pl:IsAdmin() then return end
	GAMEMODE:RefreshMapVoteCatalog()
end)

local nextSend = 0
hook.Add("Think", "ZSMapVoteCatalogSend", function()
	if CurTime() < nextSend or first > last then return end
	nextSend = CurTime() + 0.05
	local sent, remaining = 0, last - first + 1
	while remaining > 0 and sent < 2 do
		local request = queue[first]
		queue[first] = nil
		first, remaining = first + 1, remaining - 1
		local pl = request.player
		if pending[pl] == request then
			if not IsValid(pl) or pl:IsBot() then pending[pl] = nil else
				local chunk = string.sub(request.data, request.offset, request.offset + 16383)
				net.Start("zs_mapvote_catalog")
				net.WriteUInt(#request.data, 23)
				net.WriteUInt(request.offset, 23)
				net.WriteUInt(#chunk, 15)
				net.WriteUInt(request.revision, 32)
				net.WriteData(chunk, #chunk)
				net.Send(pl)
				request.offset = request.offset + #chunk
				if request.offset > #request.data then pending[pl] = nil else Enqueue(request) end
				sent = sent + 1
			end
		end
	end
	if first > last then first, last = 1, 0 end
end)
hook.Add("PlayerDisconnected", "ZSMapVoteDisconnect", function(pl)
	local request = pending[pl]
	if request then request.data, request.player = nil, nil end
	pending[pl] = nil
	local name = state.players[pl]
	if name then state.revision = (state.revision + 1) % 4294967296 state.players[pl] = nil state.counts[name] = math.max(0, (state.counts[name] or 0) - 1) SendCount(name) end
end)
hook.Add("InitPostEntity", "ZSMapVoteCatalogBuild", function()
 timer.Simple(0, function() GAMEMODE:RefreshMapVoteCatalog() end)
end)
cvars.AddChangeCallback("mapcyclefile", function(_, previous, value)
 if previous ~= value and state.initialized then GAMEMODE:RefreshMapVoteCatalog() end
end, "ZSMapVoteCatalogCycle")

hook.Add("PlayerSay", "ZSMapVoteChat", function(pl, text)
	if string.lower(string.Trim(text)) == "!votemap" and not pl:IsBot() and GetConVar("zs_mapvote_enabled"):GetBool() then
		net.Start("zs_mapvote_open")
		net.Send(pl)
		return ""
	end
end)
