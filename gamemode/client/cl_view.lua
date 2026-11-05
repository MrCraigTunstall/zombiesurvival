local math = math
local CurTime = CurTime
local FrameTime = FrameTime
local IsValid = IsValid
local Vector = Vector
local roll = 0
local observerTarget, observerUntil, hasObserverPosition
local observerPosition, observerStart = Vector(), Vector()
local tauntTrace = {endpos = Vector(), mins = Vector(-2, -2, -2), maxs = Vector(2, 2, 2), mask = bit.bor(MASK_OPAQUE, MASK_SOLID), output = {}}

local function ApplyObserverView(origin, target)
	if not IsValid(target) then
		observerTarget, observerUntil, hasObserverPosition = nil, nil, false
		return
	end
	local now
	if target ~= observerTarget then
		if IsValid(observerTarget) and hasObserverPosition then
			now = CurTime()
			observerStart:Set(observerPosition)
			observerUntil = now + 0.3333
		else
			observerUntil = nil
		end
		observerTarget = target
	end
	if observerUntil then
		now = now or CurTime()
		local delta = math.Clamp((observerUntil - now) / 0.3333, 0, 1) ^ 0.5
		local fraction = 1 - delta
		origin:SetUnpacked(observerStart.x * delta + origin.x * fraction, observerStart.y * delta + origin.y * fraction, observerStart.z * delta + origin.z * fraction)
		if now >= observerUntil then observerUntil = nil end
	end
	observerPosition:Set(origin)
	hasObserverPosition = true
end

function GM:_ShouldDrawLocalPlayer(pl)
	return pl:Team() ~= TEAM_SPECTATOR and (self.ZombieThirdPerson or pl:CallZombieFunction("ShouldDrawLocalPlayer")) or pl:IsPlayingTaunt()
end

function GM:_CalcView(pl, origin, angles, fov, znear, zfar)
	self:UpdateHumanFlashlight()

	if pl.Confusion and pl.Confusion:IsValid() then
		pl.Confusion:CalcView(pl, origin, angles, fov, znear, zfar)
	end

	if pl.Revive and pl.Revive:IsValid() and pl.Revive.GetRagdollEyes then
		local rpos, rang = pl.Revive:GetRagdollEyes(pl)
		if rpos then origin, angles = rpos, rang end
	elseif pl.KnockedDown and pl.KnockedDown:IsValid() then
		local rpos, rang = self:GetRagdollEyes(pl)
		if rpos then origin, angles = rpos, rang end
	elseif pl:ShouldDrawLocalPlayer() and pl:OldAlive() then
		origin = pl:GetThirdPersonCameraPos(origin, angles)
	end

	local corpseOrigin, corpseAngles = self:GetHeadcrabDeathView(pl)
	if corpseOrigin then origin, angles = corpseOrigin, corpseAngles end

	local targetroll = 0
	if self.MovementViewRoll then
		local velocity = pl:GetVelocity()
		local factor = velocity:LengthSqr() > 9000000 and 30 / velocity:Length() or 0.01
		targetroll = velocity:Dot(angles:Right()) * factor
	end

	if pl:WaterLevel() >= 3 then targetroll = targetroll + math.sin(CurTime()) * 7 end
	roll = math.Approach(roll, targetroll, math.max(0.25, math.sqrt(math.abs(roll))) * 30 * FrameTime())
	angles.roll = angles.roll + roll

	if pl:IsPlayingTaunt() then self:CalcViewTaunt(pl, origin, angles, fov, znear, zfar) end
	ApplyObserverView(origin, pl:GetObserverTarget())

	self:ApplyTraitDrunkView(pl, angles)
	pl:CallZombieFunction("CalcView", origin, angles)
	return self.BaseClass.CalcView(self, pl, origin, angles, fov, znear, zfar)
end

function GM:CalcViewTaunt(pl, origin, angles, fov, znear, zfar)
	local forward = angles:Forward()
	tauntTrace.start, tauntTrace.filter = origin, pl
	tauntTrace.endpos:SetUnpacked(origin.x - forward.x * 72, origin.y - forward.y * 72, origin.z - forward.z * 72)
	util.TraceHull(tauntTrace)
	local tr = tauntTrace.output
	tauntTrace.start, tauntTrace.filter = nil, nil
	origin:SetUnpacked(tr.HitPos.x + tr.HitNormal.x * 2, tr.HitPos.y + tr.HitNormal.y * 2, tr.HitPos.z + tr.HitNormal.z * 2)
	tr.Entity = nil
end
