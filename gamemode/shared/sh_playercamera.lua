local meta = FindMetaTable("Player")
if not meta then return end

local presets = {
	{30, 90, 5}, {2, 90, 20}, {-30, 90, 5}, {25, 100, 30},
	{0, 100, 35}, {35, 85, -5}, {0, 85, 0}, {0, 120, 10}
}
local minimum, maximum = Vector(-8, -8, -8), Vector(8, 8, 8)
local mode, preference = 0, nil
local function ValidMode(value)
	value = tonumber(value)
	if not value or value ~= math.floor(value) or value < 0 or value > #presets then return end
	return value
end

function GM:GetZSCameraViewMode()
	return mode > 0 and mode or ValidMode(self.ThirdPersoned) or 1
end

function GM:SetZSCameraViewMode(value)
	value = ValidMode(value)
	if value == nil then return false end
	mode = value
	if preference and preference:GetInt() ~= value then preference:SetInt(value) end
	return true
end

if CLIENT then
	preference = CreateClientConVar("zs_thirdperson_viewmode", "0", true, false)
	mode = ValidMode(preference:GetInt()) or 0
	cvars.AddChangeCallback("zs_thirdperson_viewmode", function(_, _, value) mode = ValidMode(value) or 0 end, "ZSPlayerCameraPreset")
end

function meta:GetThirdPersonCameraPos(origin, angles)
	local _, players = player.Iterator()
	local legacy = GAMEMODE.ThirdPersoned
	local preset = mode > 0 and presets[mode]
	local trace = not preset and tr or nil
	if preset or legacy == 1 or legacy == 2 or legacy == 3 or not trace then
		local horizontal, distance, vertical = 30, 90, 5
		if preset then horizontal, distance, vertical = preset[1], preset[2], preset[3]
		elseif legacy == 2 then horizontal, vertical = 2, 20
		elseif legacy == 3 then horizontal = -30 end
		trace = util.TraceHull({start = origin, endpos = origin + angles:Up() * vertical + angles:Right() * horizontal + angles:Forward() * -math.max(distance, self:Team() == TEAM_UNDEAD and self:GetZombieClassTable().CameraDistance or self:BoundingRadius()), mask = MASK_SOLID_BRUSHONLY, filter = players, mins = minimum, maxs = maximum})
	end
	return trace.HitPos + trace.HitNormal * 3
end
