if SERVER then
	function GM:PlayerStepSoundTime(pl, iType, bWalking)
		return 350
	end

	function GM:PlayerFootstep(pl, vPos, iFoot, strSoundName, fVolume, pFilter)
	end

	return
end

function GM:PlayerStepSoundTime(pl, iType, bWalking)
	local time = pl:CallZombieFunction("PlayerStepSoundTime", iType, bWalking)
	if time then
		return time
	end

	if iType == STEPSOUNDTIME_NORMAL or iType == STEPSOUNDTIME_WATER_FOOT then
		return 520 - pl:GetVelocity():Length()
	end

	if iType == STEPSOUNDTIME_ON_LADDER then
		return 500
	end

	if iType == STEPSOUNDTIME_WATER_KNEE then
		return 650
	end

	return 350
end

function GM:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume)
	return pl:CallZombieFunction("PlayerFootstep", vFootPos, iFoot, strSoundName, fVolume)
end
