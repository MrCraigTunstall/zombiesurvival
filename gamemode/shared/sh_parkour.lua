local traces = setmetatable({}, {__mode = "k"})

local function Clear(weapon)
	if weapon:GetParkourActive() then weapon:SetParkourActive(false) end
	if SERVER and IsValid(weapon:GetParkourSurface()) then weapon:SetParkourSurface(NULL) end
end

function GM:MoveTraitParkour(pl, move)
	if not self:HasPlayerTrait(pl, "parkour") then return end
	local weapon = pl:GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_fists" or not weapon.GetParkourSpent then return end
	if pl:IsOnGround() and not weapon:GetParkourActive() and weapon:GetParkourSpent() then weapon:SetParkourSpent(false) end
	if self.RoundEnded or not pl:Alive() or pl:GetMoveType() ~= MOVETYPE_WALK or pl:WaterLevel() >= 2
		or pl:GetBarricadeGhosting() or pl:IsHolding() or IsValid(pl.status_knockdown) or IsValid(pl.FeignDeath)
		or not move:KeyDown(IN_RELOAD) or move:GetForwardSpeed() < 0 then Clear(weapon) return end
	local active = weapon:GetParkourActive()
	if not active and (pl:IsOnGround() or weapon:GetParkourSpent()) then return end
	local now = CurTime()
	if active and now >= weapon:GetParkourUntil() then Clear(weapon) return end
	local state = traces[weapon]
	if not state then
		state = {start = Vector(), finish = Vector(), target = Vector(), velocity = Vector(), wall = {output = {}}, body = {output = {}}}
		traces[weapon] = state
	end
	local origin, angles = move:GetOrigin(), move:GetMoveAngles()
	local yaw = math.rad(angles.y)
	local x, y = math.cos(yaw), math.sin(yaw)
	state.start.x, state.start.y, state.start.z = origin.x, origin.y, origin.z - 2
	state.finish.x, state.finish.y, state.finish.z = origin.x + x * 48, origin.y + y * 48, origin.z - 2
	local wall = state.wall
	wall.start, wall.endpos, wall.filter, wall.mask = state.start, state.finish, pl, MASK_PLAYERSOLID
	local hit = util.TraceLine(wall)
	if not hit.Hit or hit.StartSolid or hit.AllSolid or hit.HitSky or math.abs(hit.HitNormal.z) > 0.2 then Clear(weapon) return end
	if not hit.HitWorld then
		local surface = hit.Entity
		if not IsValid(surface) or surface:IsPlayer() or surface:IsNPC() then Clear(weapon) return end
		local movement = surface:GetMoveType()
		if movement == MOVETYPE_VPHYSICS then
			local physics = surface:GetPhysicsObject()
			if not IsValid(physics) then
				if not CLIENT or weapon:GetParkourSurface() ~= surface then Clear(weapon) return end
			elseif physics:IsMoveable() then Clear(weapon) return end
		elseif movement ~= MOVETYPE_NONE then Clear(weapon) return end
	end
	if SERVER then
		local surface = hit.HitWorld and NULL or hit.Entity
		if weapon:GetParkourSurface() ~= surface then weapon:SetParkourSurface(surface) end
	end
	if active and move:KeyPressed(IN_JUMP) then
		Clear(weapon)
		state.velocity.x, state.velocity.y, state.velocity.z = hit.HitNormal.x * 140, hit.HitNormal.y * 140, 180
		move:SetVelocity(state.velocity)
		move:SetForwardSpeed(0)
		move:SetSideSpeed(0)
		return
	end
	if not active then
		weapon:SetParkourBase(origin.z)
		weapon:SetParkourUntil(now + 3)
		weapon:SetParkourSpent(true)
		weapon:SetParkourActive(true)
	end
	local speed = move:GetForwardSpeed() > 0 and 70 * (1 - math.min(1, pl:GetLegDamage() * 0.33)) or 0
	local rise = math.min(speed * FrameTime(), math.max(0, weapon:GetParkourBase() + 96 - origin.z))
	local mins, maxs
	if pl:Crouching() then mins, maxs = pl:GetHullDuck() else mins, maxs = pl:GetHull() end
	local radius = math.abs(hit.HitNormal.x) * math.max(math.abs(mins.x), math.abs(maxs.x)) + math.abs(hit.HitNormal.y) * math.max(math.abs(mins.y), math.abs(maxs.y))
	local approach = math.min(math.max(0, hit.Fraction * 48 - radius - 1), 90 * FrameTime())
	state.target.x, state.target.y, state.target.z = origin.x - hit.HitNormal.x * approach, origin.y - hit.HitNormal.y * approach, origin.z + rise
	if rise > 0 or approach > 0 then
		local body = state.body
		body.start, body.endpos, body.filter, body.mask, body.collisiongroup = origin, state.target, pl, MASK_PLAYERSOLID, COLLISION_GROUP_PLAYER
		body.mins, body.maxs = mins, maxs
		local obstruction = util.TraceHull(body)
		if obstruction.StartSolid or obstruction.AllSolid then Clear(weapon) return end
		if obstruction.Hit then state.target:Set(obstruction.HitPos) end
	end
	state.velocity.x, state.velocity.y, state.velocity.z = 0, 0, 0
	move:SetVelocity(state.velocity)
	move:SetOrigin(state.target)
	return true
end
