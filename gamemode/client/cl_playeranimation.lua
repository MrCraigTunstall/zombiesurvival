local entityMeta = FindMetaTable("Entity")
local standardResets = setmetatable({}, {__mode = "k"})
local resetSource = "/gamemode/meta/obj_entity_extend.lua"

local function StandardReset(reset)
	if type(reset) ~= "function" then return false end
	local standard = standardResets[reset]
	if standard == nil then
		local info = debug.getinfo(reset, "S")
		standard = info and info.what == "Lua" and info.source:sub(-#resetSource) == resetSource or false
		standardResets[reset] = standard
	end
	return standard
end

function GM:UpdatePlayerBoneAnimations()
	for _, pl in player.Iterator() do
		if not pl:IsDormant() then
			if pl:Team() == TEAM_UNDEAD then
				local tab = pl:GetZombieClassTable()
				local build = tab and tab.BuildBonePositions
				if build then
					pl.WasBuildingBonePositions = true
					local combined = tab.ResetAndBuildBonePositions
					local reset = pl.ResetBones
					if combined and tab.ResetBoneBuildSource == build and reset == entityMeta.ResetBones and StandardReset(reset) then
						combined(tab, pl)
					else
						reset(pl)
						build(tab, pl)
					end
				elseif pl.WasBuildingBonePositions then
					pl.WasBuildingBonePositions = nil
					pl:ResetBones()
				end
			elseif pl.WasBuildingBonePositions then
				pl.WasBuildingBonePositions = nil
				pl:ResetBones()
			end
		end
	end
end
