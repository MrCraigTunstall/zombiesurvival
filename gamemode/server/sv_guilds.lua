local function LocalizedText(pl, key, ...)
	if IsValid(pl) and pl:IsPlayer() then return translate.ClientFormat(pl, key, ...) end
	return translate.Format(key, ...)
end
GM.GuildEnabled = CreateConVar("zs_guilds", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Enable persistent human guilds", 0, 1)
GM.GuildCreateCost = CreateConVar("zs_guild_create_cost", "100", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Human points required to create a guild", 0, 100000)
GM.GuildCreateCooldown = CreateConVar("zs_guild_create_cooldown", "300", FCVAR_ARCHIVE, "Account cooldown between guild creations", 0, 86400)
GM.GuildMaxMembers = CreateConVar("zs_guild_max_members", "10", FCVAR_ARCHIVE, "Maximum members per guild", 1, 64)
GM.GuildInviteCooldown = CreateConVar("zs_guild_invite_cooldown", "10", FCVAR_ARCHIVE, "Delay between guild invitations", 1, 300)
GM.GuildAdminCreate = CreateConVar("zs_guild_admin_create", "0", FCVAR_ARCHIVE, "Restrict guild creation to admins", 0, 1)
GM.ZSGuildState = GM.ZSGuildState or {guilds = {}, names = {}, memberships = {}, online = {}, count = 0}
local state = GM.ZSGuildState
local function Query(statement)
	local result = sql.Query(statement)
	if result == false then ErrorNoHalt("ZS guild database: " .. sql.LastError() .. "\n") end
	return result
end
local function Transaction(fn)
	if Query("BEGIN") == false then return false end
	local ok, result = pcall(fn)
	if not ok or result == false then Query("ROLLBACK"); return false end
	if Query("COMMIT") == false then Query("ROLLBACK"); return false end
	return true, result
end
local function Key(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return end
	local key = pl:SteamID64()
	if type(key) == "string" and #key == 17 and key:match("^%d+$") then return key end
	if game.SinglePlayer() then return "singleplayer" end
end
local function ValidKey(key)
	return type(key) == "string" and (key == "singleplayer" or #key == 17 and key:match("^%d+$"))
end
local function Eligible(pl)
	return Key(pl) and pl:IsConnected() and pl:Team() == TEAM_HUMAN and GAMEMODE.GuildEnabled:GetBool() and state.ready
end
local function Changed(pl, id)
	if IsValid(pl) and not pl:IsBot() and pl:GetNW2Int("zs_guild", 0) ~= id then pl:SetNW2Int("zs_guild", id) end
end
local function Notice(pl, message)
	if IsValid(pl) and not pl:IsBot() then pl:CenterNotify(COLOR_CYAN, message) end
end
local function GuildFor(pl)
	local key = Key(pl)
	return key and state.guilds[state.memberships[key]], key
end

function GM:LoadGuilds()
	for _, statement in ipairs({
		"CREATE TABLE IF NOT EXISTS zs_guilds (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, name_key TEXT NOT NULL UNIQUE, owner TEXT NOT NULL, created INTEGER NOT NULL)",
		"CREATE TABLE IF NOT EXISTS zs_guild_members (steamid TEXT PRIMARY KEY, guildid INTEGER NOT NULL)",
		"CREATE INDEX IF NOT EXISTS zs_guild_members_guild ON zs_guild_members (guildid)",
		"CREATE TABLE IF NOT EXISTS zs_guild_cooldowns (steamid TEXT PRIMARY KEY, nextcreate INTEGER NOT NULL)"
	}) do if Query(statement) == false then state.ready = false; return false end end
	local rows = Query("SELECT id, name, owner, created FROM zs_guilds ORDER BY id LIMIT 129")
	local members = Query("SELECT steamid, guildid FROM zs_guild_members LIMIT 8193")
	if rows == false or members == false or #(rows or {}) > 128 or #(members or {}) > 8192 then state.ready = false; return false end
	local guilds, names, memberships, count = {}, {}, {}, 0
	for _, row in ipairs(rows or {}) do
		local name, namekey = self:NormalizeGuildName(row.name)
		local id = tonumber(row.id)
		if not name or not id or id < 1 or id > 2147483647 or id % 1 ~= 0 or not ValidKey(row.owner) or names[namekey] then state.ready = false; return false end
		guilds[id] = {id = id, name = name, owner = row.owner, created = tonumber(row.created) or 0, members = {}, count = 0, requests = {}}
		names[namekey] = id; count = count + 1
	end
	for _, row in ipairs(members or {}) do
		local guild = guilds[tonumber(row.guildid)]
		if not guild or not ValidKey(row.steamid) or memberships[row.steamid] or guild.count >= 64 then state.ready = false; return false end
		guild.members[row.steamid] = true; guild.count = guild.count + 1; memberships[row.steamid] = guild.id
	end
	for _, guild in pairs(guilds) do if not guild.members[guild.owner] then state.ready = false; return false end end
	state.guilds, state.names, state.memberships, state.count = guilds, names, memberships, count
	state.ready, state.list, state.online = true, nil, {}
	for _, pl in player.Iterator() do self:LoadGuildPlayer(pl, true) end
	return true
end

function GM:LoadGuildPlayer(pl, force)
	local key = Key(pl)
	if not key or not state.ready then return false end
	if not force and pl.ZSGuildKey == key then return true end
	local cooldown = sql.QueryValue("SELECT nextcreate FROM zs_guild_cooldowns WHERE steamid = " .. sql.SQLStr(key))
	if cooldown == false or cooldown ~= nil and not tonumber(cooldown) then return false end
	cooldown = tonumber(cooldown) or 0
	if cooldown ~= cooldown or cooldown < 0 or cooldown == math.huge or cooldown % 1 ~= 0 then return false end
	if pl.ZSGuildKey and state.online[pl.ZSGuildKey] == pl then state.online[pl.ZSGuildKey] = nil end
	pl.ZSGuildKey, pl.ZSNextGuildCreate = key, cooldown
	state.online[key] = pl
	Changed(pl, self.GuildEnabled:GetBool() and state.memberships[key] or 0)
	return true
end

function GM:GetPlayerGuild(pl)
	local guild = GuildFor(pl)
	return guild and guild.name
end

function GM:GetGuildMembers(name)
	local _, namekey = self:NormalizeGuildName(name)
	local guild = namekey and state.guilds[state.names[namekey]]
	local online = {}
	if guild then for key in pairs(guild.members) do local pl = state.online[key]; if IsValid(pl) and not pl:IsBot() then online[#online + 1] = pl end end end
	return online
end

function GM:CreateGuild(pl, name)
	if not Eligible(pl) or not pl:Alive() or self.RoundEnded then return false, LocalizedText(pl, "guild_create_humans_only") end
	if not self:LoadGuildPlayer(pl) then return false, LocalizedText(pl, "guild_profile_failed") end
	local key = Key(pl)
	local display, namekey = self:NormalizeGuildName(name)
	if not display then return false, LocalizedText(pl, "guild_name_rules") end
	if state.memberships[key] then return false, LocalizedText(pl, "guild_leave_first") end
	if state.names[namekey] then return false, LocalizedText(pl, "guild_name_taken") end
	if state.count >= 128 then return false, LocalizedText(pl, "guild_server_limit") end
	if self.GuildAdminCreate:GetBool() and not pl:IsAdmin() then return false, LocalizedText(pl, "guild_admin_create") end
	local epoch = os.time()
	if epoch < (pl.ZSNextGuildCreate or 0) then return false, LocalizedText(pl, "guild_create_wait", math.ceil(pl.ZSNextGuildCreate - epoch)) end
	local cost, points = self.GuildCreateCost:GetInt(), pl:GetPoints()
	if type(points) ~= "number" or points ~= points or math.abs(points) == math.huge or points < cost then return false, LocalizedText(pl, "guild_need_points", cost) end
	if pl.ZSGuildBusy then return false, LocalizedText(pl, "guild_action_busy") end
	pl.ZSGuildBusy = true
	local spent = pcall(pl.SetPoints, pl, points - cost)
	if not spent or pl:GetPoints() ~= points - cost then
		pl.ZSGuildBusy = nil
		pcall(pl.SetPoints, pl, points)
		return false, LocalizedText(pl, "guild_charge_failed")
	end
	local untilTime = epoch + self.GuildCreateCooldown:GetInt()
	local ok, id = Transaction(function()
		if Query("INSERT INTO zs_guilds (name, name_key, owner, created) VALUES (" .. sql.SQLStr(display) .. ", " .. sql.SQLStr(namekey) .. ", " .. sql.SQLStr(key) .. ", " .. epoch .. ")") == false then return false end
		local index = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
		if not index or index > 2147483647 or Query("INSERT INTO zs_guild_members (steamid, guildid) VALUES (" .. sql.SQLStr(key) .. ", " .. index .. ")") == false then return false end
		if Query("INSERT OR REPLACE INTO zs_guild_cooldowns (steamid, nextcreate) VALUES (" .. sql.SQLStr(key) .. ", " .. untilTime .. ")") == false then return false end
		return index
	end)
	pl.ZSGuildBusy = nil
	if not ok then pl:SetPoints(pl:GetPoints() + cost); return false, LocalizedText(pl, "guild_create_failed") end
	state.guilds[id] = {id = id, name = display, owner = key, created = epoch, members = {[key] = true}, count = 1, requests = {}}
	state.names[namekey], state.memberships[key], state.count, state.list = id, id, state.count + 1, nil
	pl.ZSNextGuildCreate = untilTime; Changed(pl, id)
	return true, LocalizedText(pl, "guild_created", display, cost)
end

function GM:InviteToGuild(pl, target)
	if not Eligible(pl) or not Eligible(target) or pl == target then return false, LocalizedText(pl, "guild_invite_human") end
	local guild, key = GuildFor(pl)
	local targetKey = Key(target)
	if not guild or guild.owner ~= key then return false, LocalizedText(pl, "guild_owner_invite") end
	if state.memberships[targetKey] then return false, LocalizedText(pl, "guild_target_member") end
	if guild.count >= self.GuildMaxMembers:GetInt() then return false, LocalizedText(pl, "guild_own_full") end
	local now = CurTime()
	if now < (pl.ZSNextGuildInvite or 0) then return false, LocalizedText(pl, "guild_invite_wait") end
	pl.ZSNextGuildInvite = now + self.GuildInviteCooldown:GetInt()
	target.ZSGuildInvite = {id = guild.id, owner = key, expires = now + 60}
	guild.requests[targetKey] = nil
	Notice(target, LocalizedText(target, "guild_invite_received", pl:Nick(), guild.name))
	return true, LocalizedText(pl, "guild_invite_sent", target:Nick())
end

function GM:JoinGuild(pl, name)
	if not Eligible(pl) then return false, LocalizedText(pl, "guild_join_humans_only") end
	if not self:LoadGuildPlayer(pl) then return false, LocalizedText(pl, "guild_profile_failed") end
	local key = Key(pl)
	if state.memberships[key] then return false, LocalizedText(pl, "guild_already_member") end
	local invite = pl.ZSGuildInvite
	local _, namekey = self:NormalizeGuildName(name or "")
	if name and string.Trim(name) ~= "" and not namekey then return false, LocalizedText(pl, "guild_invalid_name") end
	local guild = namekey and state.guilds[state.names[namekey]] or invite and state.guilds[invite.id]
	if not guild then return false, LocalizedText(pl, "guild_join_help") end
	if guild.count >= self.GuildMaxMembers:GetInt() then return false, LocalizedText(pl, "guild_target_full") end
	if not invite or invite.id ~= guild.id or invite.owner ~= guild.owner or CurTime() >= invite.expires then
		local owner = state.online[guild.owner]
		if not Eligible(owner) then return false, LocalizedText(pl, "guild_owner_offline") end
		local count, now = 0, CurTime()
		for applicant, expires in pairs(guild.requests) do if expires <= now then guild.requests[applicant] = nil else count = count + 1 end end
		if guild.requests[key] then return false, LocalizedText(pl, "guild_request_pending") end
		if count >= 32 then return false, LocalizedText(pl, "guild_requests_full") end
		guild.requests[key] = now + 60
		Notice(owner, LocalizedText(owner, "guild_join_request_received", pl:Nick(), guild.name, pl:UserID()))
		return true, LocalizedText(pl, "guild_membership_requested")
	end
	if Query("INSERT INTO zs_guild_members (steamid, guildid) VALUES (" .. sql.SQLStr(key) .. ", " .. guild.id .. ")") == false then return false, LocalizedText(pl, "guild_membership_failed") end
	guild.members[key], guild.count, state.memberships[key], state.list = true, guild.count + 1, guild.id, nil
	guild.requests[key], pl.ZSGuildInvite = nil, nil
	Changed(pl, guild.id)
	return true, LocalizedText(pl, "guild_joined", guild.name)
end

function GM:LeaveGuild(pl)
	local guild, key = GuildFor(pl)
	if not self.GuildEnabled:GetBool() or not state.ready or not guild then return false, LocalizedText(pl, "guild_not_member") end
	local owner = guild.owner
	if key == owner then
		owner = nil
		for member in pairs(guild.members) do if member ~= key and (not owner or member < owner) then owner = member end end
	end
	local ok = Transaction(function()
		if Query("DELETE FROM zs_guild_members WHERE steamid = " .. sql.SQLStr(key)) == false then return false end
		if guild.count == 1 then return Query("DELETE FROM zs_guilds WHERE id = " .. guild.id) end
		if owner ~= guild.owner then return Query("UPDATE zs_guilds SET owner = " .. sql.SQLStr(owner) .. " WHERE id = " .. guild.id) end
		return true
	end)
	if not ok then return false, LocalizedText(pl, "guild_membership_failed") end
	guild.members[key], guild.requests[key], state.memberships[key], state.list = nil, nil, nil, nil
	guild.count = guild.count - 1
	if guild.count == 0 then state.guilds[guild.id] = nil; state.names[string.lower(guild.name)] = nil; state.count = state.count - 1 else guild.owner = owner end
	pl.ZSGuildInvite = nil; Changed(pl, 0)
	return true, LocalizedText(pl, "guild_left", guild.name)
end

function GM:SendGuildChat(pl, message)
	if not Eligible(pl) then return false, LocalizedText(pl, "guild_chat_humans_only") end
	local guild = GuildFor(pl)
	if not guild then return false, LocalizedText(pl, "guild_chat_join_first") end
	if type(message) ~= "string" or #message > 240 then return false, LocalizedText(pl, "guild_chat_length") end
	message = string.Trim(message:gsub("%c", ""))
	if message == "" then return false, LocalizedText(pl, "guild_chat_help") end
	local now = CurTime()
	if now < (pl.ZSNextGuildChat or 0) then return false, LocalizedText(pl, "guild_chat_wait") end
	pl.ZSNextGuildChat = now + 1
	local recipients = {}
	for key in pairs(guild.members) do local member = state.online[key]; if Eligible(member) then recipients[#recipients + 1] = member end end
	if #recipients == 0 then return false, LocalizedText(pl, "guild_chat_none") end
	net.Start("zs_guild_chat"); net.WriteString(guild.name); net.WriteString(pl:Nick():gsub("%c", ""):sub(1, 64)); net.WriteString(message); net.Send(recipients)
	return true
end

function GM:ListGuilds()
	if state.list then return state.list end
	local list = {}
	for _, guild in pairs(state.guilds) do list[#list + 1] = guild end
	table.sort(list, function(a, b) local first, second = string.lower(a.name), string.lower(b.name); return first == second and a.id < b.id or first < second end)
	state.list = list
	return list
end

for _, name in ipairs({"zs_guild_list", "zs_guild_action", "zs_guild_result", "zs_guild_chat"}) do util.AddNetworkString(name) end

function GM:SendGuildList(pl, force)
	local key = Key(pl)
	if not key or not self.GuildEnabled:GetBool() or not state.ready then return false end
	local now = SysTime()
	if not force and now < (pl.ZSNextGuildList or 0) then return false end
	pl.ZSNextGuildList = now + 2
	local list = self:ListGuilds()
	net.Start("zs_guild_list"); net.WriteUInt(#list, 8); net.WriteUInt(self.GuildMaxMembers:GetInt(), 7)
	net.WriteUInt(self.GuildCreateCost:GetInt(), 17); net.WriteBool(self.GuildAdminCreate:GetBool())
	for _, guild in ipairs(list) do net.WriteUInt(guild.id, 31); net.WriteString(guild.name); net.WriteUInt(guild.count, 7); net.WriteBool(guild.owner == key) end
	net.Send(pl)
	return true
end

function GM:FindGuildInviteTarget(text, recipient)
	if type(text) ~= "string" or #text > 64 then return end
	text = string.lower(string.Trim(text))
	local candidate
	for _, pl in player.Iterator() do
		if Eligible(pl) and (tostring(pl:UserID()) == text or Key(pl) == text or string.lower(pl:Nick()) == text) then
			if candidate then return nil, LocalizedText(recipient, "guild_target_ambiguous") end
			candidate = pl
		end
	end
	return candidate, LocalizedText(recipient, "guild_target_missing")
end

function GM:HandleGuildAction(pl, action, text)
	if not Key(pl) then return false end
	local now = SysTime()
	if now < (pl.ZSNextGuildAction or 0) then return false end
	pl.ZSNextGuildAction = now + 0.5
	local ok, message
	if not self.GuildEnabled:GetBool() then ok, message = false, LocalizedText(pl, "guild_disabled")
	elseif not state.ready then ok, message = false, LocalizedText(pl, "guild_storage_failed")
	elseif action == "guilds" then
		if self:SendGuildList(pl) then return true end
		ok, message = false, LocalizedText(pl, "guild_refresh_wait")
	elseif action == "gcreate" then ok, message = self:CreateGuild(pl, text)
	elseif action == "gjoin" then ok, message = self:JoinGuild(pl, text)
	elseif action == "gleave" then ok, message = self:LeaveGuild(pl)
	elseif action == "ginvite" then
		local target, reason = self:FindGuildInviteTarget(text, pl)
		if target then ok, message = self:InviteToGuild(pl, target) else ok, message = false, reason end
	elseif action == "g" then ok, message = self:SendGuildChat(pl, text)
	else return false end
	if message then
		Notice(pl, message)
		net.Start("zs_guild_result"); net.WriteBool(ok); net.WriteString(message); net.Send(pl)
	end
	if ok and action ~= "g" then self:SendGuildList(pl, true) end
	return ok
end

local aliases = {g = "g", guild = "g", gcreate = "gcreate", gc = "gcreate", gjoin = "gjoin", gj = "gjoin", ginvite = "ginvite", gi = "ginvite", guilds = "guilds", gleave = "gleave", gl = "gleave"}
hook.Add("PlayerSay", "ZSGuildCommands", function(pl, text)
	if type(text) ~= "string" then return end
	local prefix, name, arguments = string.Trim(text):match("^([!/])([%w_]+)%s*(.*)$")
	local action = name and aliases[string.lower(name)]
	if prefix and action then GAMEMODE:HandleGuildAction(pl, action, arguments); return "" end
end)
for alias, action in pairs(aliases) do
	concommand.Add(alias, function(pl, _, args) GAMEMODE:HandleGuildAction(pl, action, table.concat(args, " ")) end)
end
local networkActions = {[0] = "guilds", "gcreate", "gjoin", "ginvite", "gleave"}
net.Receive("zs_guild_action", function(len, pl)
	if len > 560 or not Key(pl) then return end
	local action, text = networkActions[net.ReadUInt(3)], net.ReadString()
	if action and #text <= 64 then GAMEMODE:HandleGuildAction(pl, action, text) end
end)
hook.Add("PlayerInitialSpawn", "ZSGuildLoad", function(pl) GAMEMODE:LoadGuildPlayer(pl) end)
hook.Add("PlayerAuthed", "ZSGuildLoad", function(pl) GAMEMODE:LoadGuildPlayer(pl) end)
hook.Add("PlayerDisconnected", "ZSGuildCleanup", function(pl)
	local key = pl.ZSGuildKey
	if key and state.online[key] == pl then state.online[key] = nil end
	pl.ZSGuildInvite = nil
	if key then for _, guild in pairs(state.guilds) do guild.requests[key] = nil end end
end)
cvars.AddChangeCallback("zs_guilds", function()
	for _, pl in player.Iterator() do if not pl:IsBot() then Changed(pl, GAMEMODE.GuildEnabled:GetBool() and state.memberships[Key(pl)] or 0) end end
end, "ZSGuildEnabled")
if not state.ready then GM:LoadGuilds() else for _, pl in player.Iterator() do GM:LoadGuildPlayer(pl, true) end end
