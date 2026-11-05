local damageState = util.ZSBulletDamageState
local CaptureDamage, RestoreDamage = damageState.Capture, damageState.Restore
local meta = FindMetaTable("Entity")
if not meta then return end
local util_TraceLine, util_TraceHull, util_SharedRandom = util.TraceLine, util.TraceHull, util.SharedRandom
local MASK_SHOT = MASK_SHOT
local CONTENTS_LIQUID = bit.bor(CONTENTS_WATER, CONTENTS_SLIME)
local MASK_SHOT_HIT_WATER = bit.bor(MASK_SHOT, CONTENTS_LIQUID)
local contexts, active, depth = {}, nil, 0
local bulletForceUp = Vector(0, 0, 1)
local function BaseBulletFilter(ctx, ent)
	if ent == ctx.shooter or ent == ctx.attacker or ent.NeverAlive or ent.SpawnProtection or ent.IgnoreBullets or ent:IsPlayer() and ent:Team() == ctx.ignoreTeam then
		return false
	end

	if ent.AlwaysImpactBullets then
		return true
	end
	return true
end

local function HandleShotImpactingWater(ctx, damage)
	local bullet_trace, bullet_water_tr, bullet_tr = ctx.trace, ctx.water, ctx.result
	bullet_trace.mask = MASK_SHOT_HIT_WATER
	bullet_trace.output = bullet_water_tr
	util_TraceLine(bullet_trace)
	bullet_trace.output = bullet_tr
	bullet_trace.mask = MASK_SHOT

	if bullet_water_tr.AllSolid then return false end

	local contents = util.PointContents(bullet_water_tr.HitPos - bullet_water_tr.HitNormal * 0.1)
	if bit.band(contents, CONTENTS_LIQUID) == 0 then return false end

	if IsFirstTimePredicted() then
		local effectdata = EffectData()
		effectdata:SetOrigin(bullet_water_tr.HitPos)
		effectdata:SetNormal(bullet_water_tr.HitNormal)
		effectdata:SetScale(math.Clamp(damage * 0.25, 5, 30))
		effectdata:SetFlags(bit.band(contents, CONTENTS_SLIME) ~= 0 and 1 or 0)
		util.Effect("gunshotsplash", effectdata)
	end

	return true
end


local wspawn = Entity(0)
local function CheckFHB(tr)
	local ent = tr.Entity
	if ent == wspawn then
		return
	end

	if ent.FHB and ent:IsValid() then
		tr.Entity = ent:GetParent()
	end
end


local function FireBullets(ctx, self, src, dir, spread, num, damage, attacker, force_mul, tracer, callback, hull_size, hit_own_team, max_distance, filter, inflictor)
	local bullet_trace, temp_angle, temp_vel_ents = ctx.trace, ctx.angle, ctx.velocities
	local bullet_tr = ctx.result
	local method_to_use, base_ang
	max_distance = max_distance or 56756
	attacker = attacker or self

	if not attacker:IsValid() then attacker = self end

	force_mul = force_mul or 1
	ctx.shooter, ctx.attacker = self, attacker
	local attacker_player = attacker:IsPlayer()
	local inflictor_weapon = inflictor and inflictor:IsWeapon()
	bullet_trace.start = src

	if filter then
		bullet_trace.filter = filter
	else
		bullet_trace.filter = ctx.filter

		if not hit_own_team and attacker_player then
			ctx.ignoreTeam = attacker:Team()
		else
			ctx.ignoreTeam = nil
		end
	end

	if hull_size then
		local half = hull_size * 0.5
		ctx.maxs.x, ctx.maxs.y, ctx.maxs.z = half, half, half
		ctx.mins.x, ctx.mins.y, ctx.mins.z = -half, -half, -half
		bullet_trace.maxs, bullet_trace.mins = ctx.maxs, ctx.mins
		method_to_use = util_TraceHull
	else
		method_to_use = util_TraceLine
	end

	local temp_has_spread = spread > 0
	if temp_has_spread then base_ang = dir:Angle() end

	for i=0, num - 1 do
		if temp_has_spread then
			temp_angle:Set(base_ang)
			temp_angle:RotateAroundAxis(temp_angle:Forward(), inflictor_weapon and util_SharedRandom("bulletrotate" .. i, 0, 360) or math.Rand(0, 360))
			temp_angle:RotateAroundAxis(temp_angle:Up(), inflictor_weapon and util_SharedRandom("bulletangle" .. i, -spread, spread) or math.Rand(-spread, spread))
			dir = temp_angle:Forward()
		end

		ctx.endpoint.x, ctx.endpoint.y, ctx.endpoint.z = src.x + dir.x * max_distance, src.y + dir.y * max_distance, src.z + dir.z * max_distance
		bullet_trace.endpos = ctx.endpoint
		bullet_tr = method_to_use(bullet_trace)
		CheckFHB(bullet_tr)

		local hitwater

		if bit.band(util.PointContents(bullet_tr.HitPos), CONTENTS_LIQUID) ~= 0 then
			hitwater = HandleShotImpactingWater(ctx, damage)
		end

		local traitshot = SERVER and inflictor_weapon and inflictor.TraitSniper and attacker_player and attacker.ZSTraits and attacker.ZSTraits.deathmark
			and GAMEMODE:BeginTraitSniperBullet(attacker, inflictor, bullet_tr.Entity)
		ctx.traitshot = traitshot
		local damageinfo = DamageInfo()
		ctx.damageinfo = damageinfo
		damageState.active = damageinfo
		damageinfo:SetDamageType(DMG_BULLET)
		damageinfo:SetDamage(damage)
		damageinfo:SetDamagePosition(bullet_tr.HitPos)
		damageinfo:SetAttacker(attacker)
		damageinfo:SetInflictor(inflictor or self)

		if force_mul > 0 then
			damageinfo:SetDamageForce(force_mul * damage * 70 * dir:GetNormalized())
		else
			damageinfo:SetDamageForce(bulletForceUp)
		end

		local use_tracer = true
		local use_impact = true
		local use_ragdoll_impact = true
		local use_damage = true

		if callback then
			local ret = callback(attacker, bullet_tr, damageinfo)

			if ret then
				if ret.donothing then
					if traitshot then GAMEMODE:FinishTraitSniperBullet(attacker, traitshot); ctx.traitshot = nil end
					continue
				end
				if ret.tracer ~= nil then use_tracer = ret.tracer end
				if ret.impact ~= nil then use_impact = ret.impact end
				if ret.ragdoll_impact ~= nil then use_ragdoll_impact = ret.ragdoll_impact end
				if ret.damage ~= nil then use_damage = ret.damage end
			end
		end

		local ent = bullet_tr.Entity
		if ent:IsValid() then
			if use_damage then
				if ent:IsPlayer() then
					temp_vel_ents[ent] = temp_vel_ents[ent] or ent:GetVelocity()

					if SERVER then
						ent:SetLastHitGroup(bullet_tr.HitGroup)
					end
				elseif attacker:IsValidPlayer() then
					local phys = ent:GetPhysicsObject()

					if ent:GetMoveType() == MOVETYPE_VPHYSICS and phys:IsValid() and phys:IsMoveable() then
						ent:SetPhysicsAttacker(attacker)
					end
				end
				ent:DispatchTraceAttack(damageinfo, bullet_tr, dir)
			end
		end


		if traitshot then GAMEMODE:FinishTraitSniperBullet(attacker, traitshot); ctx.traitshot = nil end
		if IsFirstTimePredicted() and (use_tracer or hitwater and use_ragdoll_impact or not hitwater and use_impact and not bullet_tr.HitSky and bullet_tr.Fraction < 1) then
			local effectdata = EffectData()

			effectdata:SetOrigin(bullet_tr.HitPos)
			effectdata:SetStart(src)
			effectdata:SetNormal(bullet_tr.HitNormal)

			if hitwater then
				if use_ragdoll_impact then
					util.Effect("RagdollImpact", effectdata)
				end

			elseif use_impact and not bullet_tr.HitSky and bullet_tr.Fraction < 1 then
				effectdata:SetSurfaceProp(bullet_tr.SurfaceProps)
				effectdata:SetDamageType(DMG_BULLET)
				effectdata:SetHitBox(bullet_tr.HitBox)
				effectdata:SetEntity(ent)
				util.Effect("Impact", effectdata)
			end

			if use_tracer then
				if self:IsPlayer() and self:GetActiveWeapon():IsValid() then

					effectdata:SetFlags( 0x0003 )
					effectdata:SetEntity(self:GetActiveWeapon())
					effectdata:SetAttachment(1)
				else
					effectdata:SetEntity(self)
					effectdata:SetFlags( 0x0001 )
				end
				effectdata:SetScale(5000)
				util.Effect(tracer or "Tracer", effectdata)
			end
		end
	end
end

function meta:FireBulletsLua(src, dir, spread, num, damage, attacker, force_mul, tracer, callback, hull_size, hit_own_team, max_distance, filter, inflictor)
 local previous=active
 local previousDamage=damageState.active
 depth=depth+1
 local ctx=contexts[depth]
 if not ctx then
  ctx={result={},water={},velocities={},angle=Angle(),mins=Vector(),maxs=Vector(),endpoint=Vector(),saved={}}
  ctx.trace={mask=MASK_SHOT,output=ctx.result}
  ctx.filter=function(ent)return BaseBulletFilter(ctx,ent)end
  if depth<=16 then contexts[depth]=ctx end
 end
 if previousDamage then CaptureDamage(previousDamage,ctx.saved)end
 damageState.active=nil
 active=ctx
 local ok,failure=pcall(FireBullets,ctx,self,src,dir,spread,num,damage,attacker,force_mul,tracer,callback,hull_size,hit_own_team,max_distance,filter,inflictor)
 if ctx.traitshot then GAMEMODE:FinishTraitSniperBullet(ctx.attacker,ctx.traitshot)end
 for ent,velocity in pairs(ctx.velocities)do if IsValid(ent)then ent:SetLocalVelocity(velocity)end end
 table.Empty(ctx.velocities)
 if previousDamage then RestoreDamage(previousDamage,ctx.saved)end
 damageState.active=previousDamage
 table.Empty(ctx.saved)
 ctx.damageinfo,ctx.traitshot,ctx.shooter,ctx.attacker,ctx.ignoreTeam=nil,nil,nil,nil,nil
 ctx.trace.start,ctx.trace.endpos,ctx.trace.filter=nil,nil,nil
 ctx.trace.output,ctx.trace.mask=ctx.result,MASK_SHOT
 table.Empty(ctx.result);table.Empty(ctx.water)
 active=previous;depth=depth-1
 if not ok then error(failure,0)end
end
