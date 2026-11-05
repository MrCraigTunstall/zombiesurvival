GM.ProgressionMaxXP = 980100
GM.ProgressionXPScale = 100

function GM:GetProgressionLevel(experience)
	experience = tonumber(experience) or 0
	if experience ~= experience then experience = 0 end
	return math.floor(math.sqrt(math.Clamp(experience, 0, self.ProgressionMaxXP) / self.ProgressionXPScale)) + 1
end

local meta = FindMetaTable("Player")
function meta:GetZSLevel()
	return self:GetNW2Int("zs_level", 1)
end

if SERVER then
	CreateConVar("zs_barricade_expert_level", "5", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Minimum level for protection from lower-level nail removal. 0 disables protection.", 0, 100)
end
