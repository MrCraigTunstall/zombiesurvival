GM.ZSProgressionState = GM.ZSProgressionState or {dirty = {}, pending = {}}
local state = GM.ZSProgressionState
local tableName = "zs_progression_v1"
sql.Query("CREATE TABLE IF NOT EXISTS " .. tableName .. " (steamid TEXT PRIMARY KEY, xp INTEGER NOT NULL DEFAULT 0)")

local function ProfileKey(pl)
	if pl:IsBot() then return end
	local key = pl:SteamID64()
	if type(key) == "string" and string.match(key, "^%d+$") and key ~= "0" then return key end
	if game.SinglePlayer() then return "singleplayer" end
end

function GM:LoadPlayerProgression(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return end
	local key = ProfileKey(pl)
	if not key or pl.ZSProgressionKey == key then return end
	local saved = state.pending[key]
	if saved == nil then
		local result = sql.QueryValue("SELECT xp FROM " .. tableName .. " WHERE steamid = " .. sql.SQLStr(key))
		if result == false then ErrorNoHalt("[ZS] Progression read failed: " .. sql.LastError() .. "\n") return end
		saved = tonumber(result) or 0
	end
	if saved ~= saved or saved == math.huge or saved == -math.huge then saved = 0 end
	pl.ZSProgressionKey = key
	pl.ZSProgressionXP = math.Clamp(math.floor(saved), 0, self.ProgressionMaxXP)
	pl:SetNW2Int("zs_level", self:GetProgressionLevel(pl.ZSProgressionXP))
end

function GM:AddProgressionXP(pl, amount)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() or self.RoundEnded or self:GetWave() <= 0
	or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then return false end
	self:LoadPlayerProgression(pl)
	if not pl.ZSProgressionKey then return false end
	local fraction = (pl.ZSProgressionFraction or 0) + amount
	local whole = math.floor(fraction)
	pl.ZSProgressionFraction = fraction - whole
	if whole == 0 then return true end
	local previous = pl.ZSProgressionXP or 0
	local experience = math.min(self.ProgressionMaxXP, previous + whole)
	if experience == previous then return true end
	pl.ZSProgressionXP = experience
	state.dirty[pl.ZSProgressionKey] = experience
	state.pending[pl.ZSProgressionKey] = experience
	local level = self:GetProgressionLevel(experience)
	if level ~= pl:GetZSLevel() then pl:SetNW2Int("zs_level", level) end
	return true
end

function GM:SaveProgressionProfile(key)
	local experience = state.dirty[key]
	if experience == nil then return true end
	local result = sql.Query("INSERT OR REPLACE INTO " .. tableName .. " (steamid, xp) VALUES (" .. sql.SQLStr(key) .. ", " .. experience .. ")")
	if result == false then ErrorNoHalt("[ZS] Progression save failed: " .. sql.LastError() .. "\n") return false end
	state.dirty[key] = nil
	state.pending[key] = nil
	return true
end

function GM:FlushProgression()
	if next(state.dirty) == nil then return end
	if sql.Query("BEGIN") == false then return end
	for key, experience in pairs(state.dirty) do
		if sql.Query("INSERT OR REPLACE INTO " .. tableName .. " (steamid, xp) VALUES (" .. sql.SQLStr(key) .. ", " .. experience .. ")") == false then
			ErrorNoHalt("[ZS] Progression batch failed: " .. sql.LastError() .. "\n")
			sql.Query("ROLLBACK")
			return
		end
	end
	if sql.Query("COMMIT") == false then sql.Query("ROLLBACK") return end
	for key in pairs(state.dirty) do state.dirty[key] = nil state.pending[key] = nil end
end

hook.Add("PlayerInitialSpawn", "ZSProgressionLoad", function(pl) GAMEMODE:LoadPlayerProgression(pl) end)
hook.Add("PlayerAuthed", "ZSProgressionAuth", function(pl) GAMEMODE:LoadPlayerProgression(pl) end)
hook.Add("PlayerDisconnected", "ZSProgressionSave", function(pl)
	local key = pl.ZSProgressionKey
	if key and GAMEMODE:SaveProgressionProfile(key) then state.pending[key] = nil end
end)
hook.Add("ShutDown", "ZSProgressionShutdown", function() GAMEMODE:FlushProgression() end)
hook.Add("PostHumanKilledZombie", "ZSProgressionAssist", function(_, attacker, _, _, assist)
	GAMEMODE:AddProgressionXP(attacker, 10)
	if IsValid(assist) and assist ~= attacker then GAMEMODE:AddProgressionXP(assist, 5) end
end)
timer.Create("ZSProgressionFlush", 30, 0, function() GAMEMODE:FlushProgression() end)
for _, pl in player.Iterator() do GM:LoadPlayerProgression(pl) end
