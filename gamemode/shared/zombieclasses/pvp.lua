CLASS.Name = "PVP"
CLASS.TranslationName = "class_pvp"
CLASS.Description = "description_pvp"
CLASS.Help = "controls_pvp"

CLASS.Unlocked = true
CLASS.Hidden = true

CLASS.Health = 100
CLASS.Speed = 215
CLASS.Revives = false

CLASS.CanTaunt = true

CLASS.Points = 50

CLASS.SWEP = "weapon_zs_infinityboomstick"

CLASS.Model = Model("models/player/riot.mdl")

CLASS.VoicePitch = 0.65

CLASS.CanFeignDeath = false

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	return false
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	return false
end

function CLASS:CalcMainActivity(pl, velocity)
	return false
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	return false
end

function CLASS:DoAnimationEvent(pl, event, data)

end

function CLASS:DoesntGiveFear(pl)

end

if CLIENT then
	CLASS.Icon = "zombiesurvival/killicons/zombie"
end
