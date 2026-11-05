function GM:RepairBarricadesInField(source, owner, position, now, aim)
	source.FieldRepairWork = 0
	if not IsValid(owner) or not owner:IsPlayer() or owner:Team() ~= TEAM_HUMAN then return 0 end
	position = position or source:WorldSpaceCenter()
	local nearby = ents.FindInSphere(position, source.RepairRadius)
	local count = #nearby
	if count == 0 then source.RepairCursor = 0 return 0 end
	local cursor = (source.RepairCursor or 0) % count
	local budget, repaired, healedTotal, traces = source.RepairRate, 0, 0, 0
	local trace = source.RepairTrace or {mask = MASK_SOLID_BRUSHONLY}
	source.RepairTrace = trace
	trace.start = position
	local radiusSquared = source.RepairRadius * source.RepairRadius
	for i = 1, math.min(count, source.MaxCandidates) do
		cursor = cursor % count + 1
		local ent = nearby[cursor]
		if IsValid(ent) and ent:IsNailed() and (ent.ZSNextFieldRepair or 0) <= now then
			local health, maximum, capacity = ent:GetBarricadeHealth(), ent:GetMaxBarricadeHealth(), ent:GetBarricadeRepairs()
			local heal = math.min(source.RepairPerTarget, budget, maximum - health, capacity)
			if health > 0 and heal > 0 then
				trace.endpos = ent:NearestPoint(position)
				local distance = position:DistToSqr(trace.endpos)
				local facing = not aim or (trace.endpos - position):Dot(aim) >= math.sqrt(distance) * source.RepairAimDot
				if distance <= radiusSquared and facing then
					traces = traces + 1
					if not util.TraceLine(trace).Hit then
						ent:SetBarricadeHealth(health + heal)
						ent:SetBarricadeRepairs(capacity - heal)
						ent.ZSNextFieldRepair = now + source.RepairInterval
						budget = budget - heal
						healedTotal = healedTotal + heal
						source.FieldRepairWork = healedTotal
						repaired = repaired + 1
						gamemode.Call("PlayerRepairedObject", owner, ent, heal, source)
						if budget <= 0 or repaired >= source.MaxRepairTargets then break end
					end
					if source.MaxRepairTraces and traces >= source.MaxRepairTraces then break end
				end
			end
		end
	end
	source.RepairCursor = cursor
	return healedTotal
end
