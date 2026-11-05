GM.SpawnSigilProps = true
local bounds = {}
local up = Vector(0, 0, 256)
local down = Vector(0, 0, 512)

local function Place(prop, origin, slot, mins, maxs)
	for attempt = 1, 12 do
		local angle = (slot - 1) * math.pi / 4 + (attempt - 1) * 2.3999632297287
		local radius = 80 + math.floor((attempt - 1) / 4) * 40
		local candidate = origin + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		local floor = util.TraceLine({start = candidate + up, endpos = candidate - down, mask = MASK_SOLID_BRUSHONLY})
		if floor.Hit and not floor.StartSolid and not floor.AllSolid and not floor.HitSky and floor.HitNormal.z >= 0.65 then
			local pos = floor.HitPos + Vector(0, 0, 2 - mins.z)
			if util.IsInWorld(pos + mins) and util.IsInWorld(pos + maxs) then
				local trace = util.TraceHull({start = pos, endpos = pos, mins = mins, maxs = maxs, filter = prop, mask = MASK_SOLID})
				if not trace.Hit and not trace.StartSolid and not trace.AllSolid then return pos end
			end
		end
	end
end

function GM:SpawnRandomSigilProps(origin)
	local models = self.RandomProps
	local spawned = {}
	if not models or #models == 0 then return spawned end
	for slot = 1, 8 do
		local model = models[math.random(#models)]
		if type(model) == "string" and util.IsValidProp(model) then
			local prop = ents.Create("prop_physics")
			if IsValid(prop) then
				local ok, placed = pcall(function()
					prop:SetModel(model)
					local box = bounds[model]
					if not box then
						local mins, maxs = prop:GetModelBounds()
						box = {mins = mins, maxs = maxs}
						bounds[model] = box
					end
					local pos = Place(prop, origin, slot, box.mins, box.maxs)
					if not pos then return false end
					prop:SetPos(pos)
					prop:Spawn()
					if not IsValid(prop) then return false end
					local phys = prop:GetPhysicsObject()
					if not IsValid(phys) then return false end
					phys:Wake()
					return true
				end)
				if ok and placed then spawned[#spawned + 1] = prop
				else
					if IsValid(prop) then prop:Remove() end
					if not ok then ErrorNoHalt("ZS sigil prop placement: " .. tostring(placed) .. "\n") end
				end
			end
		end
	end
	return spawned
end
