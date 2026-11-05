function GM:FastZombieCalcMainActivity(pl, velocity)
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or not wep.GetClimbing then return end

	if wep:GetClimbing() then
		pl.CalcIdeal = ACT_ZOMBIE_CLIMB_UP
		return true
	elseif wep:GetPounceTime() > 0 then
		pl.CalcIdeal = ACT_ZOMBIE_LEAP_START
		return true
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl.CalcIdeal = ACT_ZOMBIE_LEAPING
		return true
	end
	local speed = velocity:Length2D()
	if speed <= 0.5 and wep:IsRoaring() then
		pl.CalcSeqOverride = GAMEMODE:GetAnimationSequence(pl, "menu_zombie_01")
	elseif speed > 16 and wep:GetSwinging() then
		pl.CalcIdeal = ACT_HL2MP_RUN_ZOMBIE
	else
		pl.CalcIdeal = ACT_HL2MP_RUN_ZOMBIE_FAST
	end

	return true
end

function GM:FastZombieUpdateAnimation(pl, velocity, maxseqgroundspeed)
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or not wep.GetClimbing then
		GAMEMODE:ResetZombieAnimation(pl)
		return
	end

	GAMEMODE:UpdateZombieSwing(pl, wep)

	if wep:GetClimbing() then
		local vel = pl:GetVelocity()
		local speed = vel:Length()
		if speed > 8 then
			pl:SetPlaybackRate(math.Clamp(speed / 160, 0, 1) * (vel.z < 0 and -1 or 1))
		else
			pl:SetPlaybackRate(0)
		end

		return true
	end

	if wep:GetPounceTime() > 0 then
		pl:SetPlaybackRate(0.25)

		if not pl.m_PrevFrameCycle then
			pl.m_PrevFrameCycle = true
			pl:SetCycle(0)
		end

		return true
	elseif pl.m_PrevFrameCycle then
		pl.m_PrevFrameCycle = nil
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl:SetPlaybackRate(1)

		local cycle = pl:GetCycle()
		if cycle >= 1 then
			pl:SetCycle(cycle - 1)
		end

		return true
	end
	local speed = velocity:Length2D()
	if speed <= 0.5 and wep:IsRoaring() then
		pl:SetPlaybackRate(0)
		pl:SetCycle(math.Clamp(1 - (wep:GetRoarEndTime() - CurTime()) / wep.RoarTime, 0, 1) * 0.9)

		return true
	end
end

