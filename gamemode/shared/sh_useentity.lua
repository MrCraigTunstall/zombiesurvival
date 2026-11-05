local misses = setmetatable({}, {__mode = "k"})

function GM:FindUseEntity(pl, ent)
	if ent:IsValid() then misses[pl] = nil return ent end
	if not SERVER or not pl:IsBot() then
		local found = pl:TraceLine(90, MASK_SOLID, pl:GetDynamicTraceFilter()).Entity
		return found:IsValid() and found or ent
	end
	local now, origin = CurTime(), pl:GetShootPos()
	local state = misses[pl]
	if not pl:KeyPressed(IN_USE) and state and now >= state.Time and now < state.Until then
		local x, y, z = origin.x - state.X, origin.y - state.Y, origin.z - state.Z
		if x * x + y * y + z * z <= 64 then return ent end
	end
	local found = pl:TraceLine(90, MASK_SOLID, pl:GetDynamicTraceFilter(), origin).Entity
	if found:IsValid() then misses[pl] = nil return found end
	if not state then state = {} misses[pl] = state end
	state.Time, state.Until = now, now + 0.1
	state.X, state.Y, state.Z = origin.x, origin.y, origin.z
	return ent
end
