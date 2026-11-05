local attachmentFallbackMap = {forward = "eyes", grenade0 = "eyes", grenade1 = "eyes", grenade2 = "eyes", pistol = "eyes", primary = "eyes", defusekit = "eyes", eholster = "eyes", rfoot = "eyes", lfoot = "eyes", muzzle_flash = "eyes"}
local filters = GM.ZEMapFilters or setmetatable({}, {__mode = "k"})
GM.ZEMapFilters = filters
local neutralOutput = ",,,0,1"
local attachmentInputs = {setparentattachment = true, setparentattachmentmaintainoffset = true}

local function Live(ent)
 return IsValid(ent) and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())
end

hook.Add("EntityKeyValue", "zombieescape", function(ent, key, value)
 local class, lowerKey = ent:GetClass(), string.lower(key)
 if class == "filter_activator_team" and not ent.ZEFix and lowerKey == "filterteam" then
  if value == "2" then ent.ZEFix = tostring(TEAM_UNDEAD)
  elseif value == "3" then ent.ZEFix = tostring(TEAM_HUMAN) end
  if ent.ZEFix then filters[ent] = true; return ent.ZEFix end
 end
 if string.sub(lowerKey, 1, 2) ~= "on" then return end
 local separator = string.find(value, "\27", 1, true) and "\27" or ","
 local first = string.find(value, separator, 1, true)
 if not first then return end
 local second = string.find(value, separator, first + 1, true)
 if not second then return end
 local input = string.lower(string.Trim(string.sub(value, first + 1, second - 1)))
 local third = string.find(value, separator, second + 1, true) or #value + 1
 local parameter = string.sub(value, second + 1, third - 1)
 if (class == "trigger_multiple" or class == "trigger_once") and input == "addoutput" and string.sub(value, 1, 1) == "!" and string.lower(string.match(parameter, "^%s*(%S+)") or "") == "health" then
  return neutralOutput
 end
 if attachmentInputs[input] then
  local replacement = attachmentFallbackMap[string.lower(string.Trim(parameter))]
  if replacement then return string.sub(value, 1, second) .. replacement .. string.sub(value, third) end
 end
end)

function GM:InitializeZombieEscapeMap(fromze)
 for ent in pairs(filters) do
  if Live(ent) and ent.ZEFix then ent:SetKeyValue("filterteam", ent.ZEFix)
  else filters[ent] = nil end
 end
 self.DynamicSpawning = true
 if not fromze then
  self:SetRedeemBrains(0)
  self:SetWaveStart(CurTime() + (self.CurrentRound <= 1 and self.WaveZeroLength + 30 or self.ZE_FreezeTime + 5))
 end
end

hook.Add("InitPostEntityMap", "zombieescape", function(fromze) GAMEMODE:InitializeZombieEscapeMap(fromze) end)

local cleanup = {}
for _, class in ipairs(GM.CleanupFilter) do cleanup[class] = true end
for _, class in ipairs({"func_brush", "env_global", "info_player_terrorist", "info_player_counterterrorist"}) do
 if not cleanup[class] then GM.CleanupFilter[#GM.CleanupFilter + 1] = class; cleanup[class] = true end
end
