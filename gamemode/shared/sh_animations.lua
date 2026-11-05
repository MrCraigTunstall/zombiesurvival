local TEAM_UNDEAD = TEAM_UNDEAD
local TEAM_HUMAN = TEAM_HUMAN
local ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE

local function ValidGestureActivity(activity)
	return type(activity) == "number" and activity >= 0 and activity <= 2147483647 and activity % 1 == 0
end

local playerMeta = FindMetaTable("Player")
function playerMeta:RestartGesture(activity)
	if not IsValid(self) or not ValidGestureActivity(activity) or CLIENT and not IsFirstTimePredicted() then return end
	self:DoAnimationEvent(activity)
end

local sequenceStates = setmetatable({}, {__mode = "k"})

function GM:GetAnimationSequence(ent, name)
	local model, count = ent:GetModel(), ent:GetSequenceCount()
	if not count or count <= 0 then return ent:LookupSequence(name) end
	local lookup = ent.LookupSequence
	local state = sequenceStates[ent]
	if not state or state.model ~= model or state.count ~= count or state.lookup ~= lookup then
		state = {model = model, count = count, lookup = lookup, names = {}}
		sequenceStates[ent] = state
	end
	local item = state.names[name]
	if not item then
		local sequence, duration = lookup(ent, name)
		item = {sequence, duration}
		state.names[name] = item
	end
	return item[1], item[2]
end

local atan2, deg, normalize = math.atan2, math.deg, math.NormalizeAngle

function GM:GetAnimationMoveYaw(velocity, eyeYaw)
	local x, y = velocity.x, velocity.y
	local yaw = x == 0 and y == 0 and 0 or deg(atan2(y, x))
	return normalize(yaw - eyeYaw)
end

function GM:ResetZombieAnimation(pl)
	if pl.PlayingFZSwing then pl:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD) end
	pl.PlayingFZSwing = nil
	pl.ZSSwingAnimationWeapon = nil
	pl.m_PrevFrameCycle = nil
end

function GM:UpdateZombieSwing(pl, weapon)
	if weapon:GetSwinging() then
		if not pl.PlayingFZSwing or pl.ZSSwingAnimationWeapon ~= weapon then
			pl.PlayingFZSwing = true
			pl.ZSSwingAnimationWeapon = weapon
			pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_FRENZY)
		end
	elseif pl.PlayingFZSwing then
		pl.PlayingFZSwing = nil
		pl.ZSSwingAnimationWeapon = nil
		pl:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
	end
end

hook.Add("OnPlayerChangedTeam", "ZSAnimationState", function(pl, oldTeam, newTeam)
	if oldTeam ~= newTeam then GAMEMODE:ResetZombieAnimation(pl) end
end)

function GM:PlayerShouldTaunt(pl, actid)
	local team = pl:Team()
	if team == TEAM_UNDEAD then
		local class = pl:GetZombieClassTable()
		if not class or not class.CanTaunt then return false end
	elseif team ~= TEAM_HUMAN then
		return false
	end
	return not IsValid(pl.Revive) and not IsValid(pl.FeignDeath)
end

function GM:CalcMainActivity(pl, velocity)
	pl.CalcIdeal = ACT_MP_STAND_IDLE
	pl.CalcSeqOverride = -1

	--[[if pl:CallZombieFunction("CalcMainActivity", velocity) then
		return pl.CalcIdeal, pl.CalcSeqOverride
	end]]
	if pl:Team() == TEAM_UNDEAD then
		local tab = pl:GetZombieClassTable()
		local calculate = tab and tab.CalcMainActivity
		if calculate and calculate(tab, pl, velocity) then
			return pl.CalcIdeal, pl.CalcSeqOverride
		end
	end

	return self.BaseClass.CalcMainActivity(self, pl, velocity)
end

function GM:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local wep = pl:GetActiveWeapon()
	local update = wep:IsValid() and wep.UpdateAnimation
	if update and update(wep, pl, velocity, maxseqgroundspeed) or pl:CallZombieFunction("UpdateAnimation", velocity, maxseqgroundspeed) then
		--[[if CLIENT then
			GAMEMODE:GrabEarAnimation(pl)
			GAMEMODE:MouthMoveAnimation(pl)
		end]]

		return
	end

	return self.BaseClass.UpdateAnimation(self, pl, velocity, maxseqgroundspeed)
end

function GM:DoAnimationEvent(pl, event, data)
	local result = pl:CallZombieFunction("DoAnimationEvent", event, data)
	if result then return result end
	if event == PLAYERANIMEVENT_CUSTOM_GESTURE then
		if ValidGestureActivity(data) then pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, data, true) end
		return ACT_INVALID
	end
	local fallback = self.BaseClass:DoAnimationEvent(pl, event, data)
	return fallback
end

local CarryingActivityTranslate = {}
CarryingActivityTranslate[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SLAM
CarryingActivityTranslate[ACT_MP_WALK] = ACT_HL2MP_IDLE_SLAM + 1
CarryingActivityTranslate[ACT_MP_RUN] = ACT_HL2MP_IDLE_SLAM + 2
CarryingActivityTranslate[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_SLAM + 3
CarryingActivityTranslate[ACT_MP_CROUCHWALK] = ACT_HL2MP_IDLE_SLAM + 4
CarryingActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = ACT_HL2MP_IDLE_SLAM + 5
CarryingActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = ACT_HL2MP_IDLE_SLAM + 5
CarryingActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_IDLE_SLAM + 6
CarryingActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_IDLE_SLAM + 6
CarryingActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_IDLE_SLAM + 7
CarryingActivityTranslate[ACT_RANGE_ATTACK1] = ACT_HL2MP_IDLE_SLAM + 8

function GM:TranslateActivity(pl, act)
	if pl:IsCarrying() then
		return CarryingActivityTranslate[act] or act
	end

	return self.BaseClass:TranslateActivity(pl, act)
end
