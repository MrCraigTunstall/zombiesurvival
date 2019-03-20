CLASS.Name = "Wraith"
CLASS.TranslationName = "class_wraith"
CLASS.Description = "description_wraith"
CLASS.Help = "controls_wraith"

CLASS.Wave = 1 / 3
CLASS.Health = 100
CLASS.SWEP = "weapon_zs_wraith"
CLASS.Model = Model("models/wraith_zsv1.mdl")
CLASS.Speed = 190

CLASS.Points = 4

CLASS.VoicePitch = 0.65

CLASS.PainSounds = {Sound("npc/barnacle/barnacle_pull1.wav"), Sound("npc/barnacle/barnacle_pull2.wav"), Sound("npc/barnacle/barnacle_pull3.wav"), Sound("npc/barnacle/barnacle_pull4.wav")}
CLASS.DeathSounds = {Sound("zombiesurvival/wraithdeath1.ogg"), Sound("zombiesurvival/wraithdeath2.ogg"), Sound("zombiesurvival/wraithdeath3.ogg"), Sound("zombiesurvival/wraithdeath4.ogg")}

CLASS.NoShadow = true

function CLASS:Move(pl, move)


	if pl:KeyDown(IN_SPEED) then
		move:SetMaxSpeed(50)
		move:SetMaxClientSpeed(50)
	end
end

function CLASS:CalcMainActivity(pl, velocity)
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsAttacking and wep:IsAttacking() then
		pl.CalcSeqOverride = 10
	elseif velocity:Length2D() > 0.5 then
		pl.CalcSeqOverride = 3
	else
		pl.CalcSeqOverride = 1
	end

	return true
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	return true
end

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	-- The Wraith model doesn't have hitboxes.
	return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:FixModelAngles(velocity)

	local seq = pl:GetSequence()
	if seq == 10 then
		if not pl.m_PrevFrameCycle then
			pl.m_PrevFrameCycle = true
			pl:SetCycle(0)
		end
	elseif pl.m_PrevFrameCycle then
		pl.m_PrevFrameCycle = nil
	end
end

function CLASS:GetAlpha(pl)
	local wep = pl:GetActiveWeapon()
	if not wep.IsAttacking then wep = NULL end

	if wep:IsValid() and wep:IsAttacking() then
		return 0.7
	elseif MySelf:IsValid() and MySelf:Team() == TEAM_UNDEAD then
		local eyepos = EyePos()
		return math.Clamp(pl:GetVelocity():Length() - pl:NearestPoint(eyepos):Distance(eyepos) * 0.5, 35, 180) / 255
	else
		local eyepos = EyePos()
		return math.Clamp(pl:GetVelocity():Length() - pl:NearestPoint(eyepos):Distance(eyepos) * 0.5, 0, 180) / 255
	end
end

function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo, assister)
	if SERVER then
		local effectdata = EffectData()
			effectdata:SetOrigin(pl:GetPos())
			effectdata:SetNormal(pl:GetForward())
			effectdata:SetEntity(pl)
		util.Effect("wraithdeath", effectdata, nil, true)
	end

	return true
end

if not CLIENT then return end

function CLASS:PrePlayerDraw(pl)
	pl:RemoveAllDecals()

		local alpha = self:GetAlpha(pl)
		if alpha == 0 then return true end

		render.SetBlend(alpha)
		render.SetColorModulation(0.3, 0.3, 0.3)
end

function CLASS:PostPlayerDraw(pl)
	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
end

CLASS.Icon = "zombiesurvival/killicons/wraith_hd"