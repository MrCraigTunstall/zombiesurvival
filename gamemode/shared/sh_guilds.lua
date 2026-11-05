function GM:GetGuildID(pl)
	return IsValid(pl) and pl:GetNW2Int("zs_guild", 0) or 0
end

function GM:ArePlayersInSameGuild(first, second)
	local id = self:GetGuildID(first)
	return id > 0 and id == self:GetGuildID(second)
end

function GM:NormalizeGuildName(name)
	if type(name) ~= "string" then return end
	name = string.Trim(name)
	if #name < 3 or #name > 32 or name:find("%c") then return end
	return name, string.lower(name)
end
