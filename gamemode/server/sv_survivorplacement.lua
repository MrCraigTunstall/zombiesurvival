local mins, maxs = Vector(-17, -17, 0), Vector(17, 17, 74)

function GM:FindSurvivorPosition()
	local origins = {}
	for _, class in ipairs({"info_player_human", "info_player_start", "info_player_counterterrorist"}) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			if IsValid(ent) and not ent.Disabled then origins[#origins + 1] = ent:GetPos() end
			if #origins >= 8 then break end
		end
		if #origins >= 8 then break end
	end
	if #origins == 0 then
		for _, ent in ipairs(self:GetZSClassEntities("prop_obj_sigil")) do
			if IsValid(ent) then origins[#origins + 1] = ent:GetPos() end
			if #origins >= 8 then break end
		end
	end
	local start = #origins > 0 and math.random(#origins) or 1
	for slot = 1, #origins do
		local origin = origins[(start + slot - 2) % #origins + 1]
		for attempt = 1, 12 do
			local angle = attempt * 2.3999632297287 + self:GetWave()
			local candidate = origin + Vector(math.cos(angle) * (80 + attempt * 12), math.sin(angle) * (80 + attempt * 12), 0)
			local floor = util.TraceLine({start = candidate + Vector(0, 0, 128), endpos = candidate - Vector(0, 0, 256), mask = MASK_SOLID_BRUSHONLY})
			if floor.Hit and not floor.StartSolid and not floor.AllSolid and not floor.HitSky and floor.HitNormal.z >= 0.65 then
				local pos = floor.HitPos + Vector(0, 0, 2)
				if util.IsInWorld(pos + mins) and util.IsInWorld(pos + maxs) and WorldVisible(origin + Vector(0, 0, 64), pos + Vector(0, 0, 64)) then
					local hull = util.TraceHull({start = pos, endpos = pos, mins = mins, maxs = maxs, mask = MASK_SOLID})
					if not hull.Hit and not hull.StartSolid and not hull.AllSolid then return pos end
				end
			end
		end
	end
end

function GM:FindTraderPosition()
	return self:FindSurvivorPosition()
end
