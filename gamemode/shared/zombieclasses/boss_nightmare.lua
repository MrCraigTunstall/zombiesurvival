CLASS.Name = "Nightmare"
CLASS.TranslationName = "class_nightmare"
CLASS.Description = "description_nightmare"
CLASS.Help = "controls_nightmare"

CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true

CLASS.Health = 2000
CLASS.Speed = 140

CLASS.CanTaunt = true

CLASS.FearPerInstance = 1

CLASS.Points = 30

CLASS.SWEP = "weapon_zs_nightmare"

CLASS.Model = Model("models/player/skeleton.mdl")

CLASS.VoicePitch = 0.65

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE

local mathrandom = math.random
local StepSounds = {
	"npc/zombie/foot1.wav",
	"npc/zombie/foot2.wav",
	"npc/zombie/foot3.wav"
}
function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	pl:EmitSound(StepSounds[mathrandom(#StepSounds)], 70)

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	if pl:WaterLevel() >= 3 then
		pl.CalcIdeal = ACT_HL2MP_SWIM_PISTOL
	elseif pl:Crouching() then
		if velocity:Length2D() <= 0.5 then
			pl.CalcIdeal = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
		else
			pl.CalcIdeal = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 - 1 + math.ceil((CurTime() / 4 + pl:EntIndex()) % 3)
		end
	else
		pl.CalcIdeal = ACT_HL2MP_RUN_ZOMBIE
	end

	return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local len2d = velocity:Length2D()
	if len2d > 0.5 then
		pl:SetPlaybackRate(math.min(len2d / maxseqgroundspeed, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true)
		return ACT_INVALID
	end
end

if SERVER then
	function CLASS:OnSpawned(pl)
		pl:CreateAmbience("nightmareambience")
	end
end

if not CLIENT then return end

local boneStates = setmetatable({}, {__mode = "k"})
local function CreateBoneOffsets(pl, state, now)
	pl.m_NightmareBoneOffsetsNext = now + math.Rand(0.02, 0.1)
	local offsets, angs = state.offsets, state.angles
	table.Empty(offsets)
	table.Empty(angs)
	for i = 1, state.count - 1 do
		if math.random(3) == 3 then
			local offset = VectorRand()
			offset:Normalize()
			offset:Mul(math.Rand(0.5, 3))
			offsets[i] = offset
		end
		if math.random(5) == 5 then
			local angle = state.anglePool[i]
			if not angle then
				angle = Angle(0, 0, 0)
				state.anglePool[i] = angle
			end
			angle.p, angle.y, angle.r = math.Rand(-5, 5), math.Rand(-15, 15), math.Rand(-5, 5)
			angs[i] = angle
		end
	end
	pl.m_NightmareBoneOffsets, pl.m_NightmareBoneAngles = offsets, angs
end

local function BoneState(pl)
	local count = pl:GetBoneCount()
	if not count or count <= 0 then return end
	local model, now = pl:GetModel(), CurTime()
	local state = boneStates[pl]
	if not state or state.model ~= model or state.count ~= count then
		state = {model = model, count = count, offsets = {}, angles = {}, anglePool = {}}
		boneStates[pl] = state
		pl.m_NightmareBoneOffsetsNext = 0
	end
	if pl.m_NightmareBoneOffsets ~= state.offsets or pl.m_NightmareBoneAngles ~= state.angles or now >= (pl.m_NightmareBoneOffsetsNext or 0) then
		CreateBoneOffsets(pl, state, now)
	end
	return state, count
end

function CLASS:BuildBonePositions(pl)
	local state, count = BoneState(pl)
	if not state then return end
	local offsets, angs = state.offsets, state.angles
	for i = 1, count - 1 do
		if offsets[i] then pl:ManipulateBonePosition(i, offsets[i]) end
		if angs[i] then pl:ManipulateBoneAngles(i, angs[i]) end
	end
end

CLASS.ResetBoneBuildSource = CLASS.BuildBonePositions
function CLASS:ResetAndBuildBonePositions(pl)
	local unit, zeroAngle = Vector(1, 1, 1), Angle(0, 0, 0)
	local state, count = BoneState(pl)
	if not state then return end
	local offsets, angs = state.offsets, state.angles
	for bone = 0, count - 1 do
		pl:ManipulateBoneScale(bone, unit)
		pl:ManipulateBoneAngles(bone, bone > 0 and angs[bone] or zeroAngle)
		pl:ManipulateBonePosition(bone, bone > 0 and offsets[bone] or vector_origin)
	end
end

function CLASS:PrePlayerDraw(pl)
	render.SetColorModulation(0.1, 0.1, 0.1)
end

function CLASS:PostPlayerDraw(pl)
	render.SetColorModulation(1, 1, 1)
end

CLASS.Icon = "zombiesurvival/killicons/nightmare_hd_2"
