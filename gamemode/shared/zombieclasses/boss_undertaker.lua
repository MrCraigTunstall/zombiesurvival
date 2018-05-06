CLASS.Name = "Undertaker"
CLASS.TranslationName = "class_undertaker"
CLASS.Description = "description_undertaker"
CLASS.Help = "controls_undertaker"

CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true

CLASS.Health = 3500
CLASS.Speed = 90

CLASS.CanTaunt = true

CLASS.FearPerInstance = 1

CLASS.Points = 30

CLASS.SWEP = "weapon_zs_undertaker_shovel"

CLASS.Model = Model("models/zs_undertaker/undertaker.mdl")

CLASS.VoicePitch = 0.65

CLASS.PainSounds = {"npc/combine_soldier/pain1.wav", "npc/combine_soldier/pain2.wav", "npc/combine_soldier/pain3.wav"}
CLASS.DeathSounds = {"ambient/levels/prison/inside_battle_soldier1.wav", "ambient/levels/prison/inside_battle_soldier2.wav", "ambient/levels/prison/inside_battle_soldier3.wav"}

local ACT_HL2MP_SWIM_MELEE = ACT_HL2MP_SWIM_MELEE2
local ACT_HL2MP_IDLE_CROUCH_PASSIVE = ACT_HL2MP_IDLE_CROUCH_MELEE2
local ACT_HL2MP_WALK_CROUCH_PASSIVE = ACT_HL2MP_WALK_CROUCH_MELEE2
local ACT_HL2MP_IDLE_MELEE2 = ACT_HL2MP_IDLE_MELEE2
local ACT_HL2MP_WALK_PASSIVE = ACT_HL2MP_WALK_PASSIVE
local ACT_HL2MP_WALK_MELEE2 = ACT_HL2MP_WALK_MELEE2
local ACT_HL2MP_WALK_PASSIVE = ACT_HL2MP_WALK_PASSIVE
local ACT_GMOD_GESTURE_ITEM_THROW = ACT_GMOD_GESTURE_ITEM_THROW

local mathrandom = math.random
local StepLeftSounds = {
	"npc/fast_zombie/foot1.wav",
	"npc/fast_zombie/foot2.wav"
}
local StepRightSounds = {
	"npc/fast_zombie/foot3.wav",
	"npc/fast_zombie/foot4.wav"
}
function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound(StepLeftSounds[mathrandom(#StepLeftSounds)], 70)
	else
		pl:EmitSound(StepRightSounds[mathrandom(#StepRightSounds)], 70)
	end

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	if pl:WaterLevel() >= 3 then
		pl.CalcIdeal = ACT_HL2MP_SWIM_MELEE
		return true
	end

	local swinging = false
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and CurTime() < wep:GetNextPrimaryFire() then
		swinging = true
	end

	if pl:Crouching() then
		if velocity:Length2D() <= 0.5 then
			pl.CalcIdeal = ACT_HL2MP_IDLE_CROUCH_MELEE2
		else
			pl.CalcIdeal = ACT_HL2MP_WALK_CROUCH_MELEE2
		end
	elseif velocity:Length2D() <= 0.5 then
		if swinging then
			pl.CalcIdeal = ACT_HL2MP_IDLE_MELEE2
		else
			pl.CalcIdeal = ACT_HL2MP_WALK_PASSIVE
		end
	elseif swinging then
		pl.CalcIdeal = ACT_HL2MP_WALK_MELEE2
	else
		pl.CalcIdeal = ACT_HL2MP_WALK_PASSIVE
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
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2, true)
		return ACT_INVALID
	end
	if event == PLAYERANIMEVENT_ATTACK_SECONDARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_ITEM_THROW, true)
		return ACT_INVALID
	end
end

if SERVER then
	function CLASS:OnSpawned(pl)
		pl:CreateAmbience("butcherambience")
	end

	local function CreateUndertakerShovel(pos)
		local ent = ents.Create("prop_weapon")
		if ent:IsValid() then
			ent:SetPos(pos)
			ent:SetAngles(AngleRand())
			ent:SetWeaponType("weapon_zs_shovel")
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(VectorRand():GetNormalized() * math.Rand(24, 100))
				phys:AddAngleVelocity(VectorRand() * 200)
			end
		end
	end

	function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
		local pos = pl:LocalToWorld(pl:OBBCenter())
		timer.Simple(0, function()
			CreateUndertakerShovel(pos)
		end)
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/undertaker"

