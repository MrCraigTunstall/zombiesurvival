-- Code references:
-- GM Zombie Escape gamemode
-- https://github.com/samuelmaddock/zombie-escape
-- Breakpoint servers CS:S gamemode
-- https://bitbucket.org/blackops7799/breakpoint/src/bb3393586a30b99e399feca8e0d6d9e5a6fda2fc/gamemodes/css/gamemode/sh_bullets.lua

local playerMeta = FindMetaTable("Player")
if not playerMeta then return end

local damageState = util.ZSBulletDamageState or {}
util.ZSBulletDamageState = damageState
function damageState.Capture(info, saved)
 saved.damage=info:GetDamage();saved.base=info:GetBaseDamage();saved.bonus=info:GetDamageBonus();saved.maximum=info:GetMaxDamage()
 saved.kind=info:GetDamageType();saved.custom=info:GetDamageCustom();saved.ammo=info:GetAmmoType()
 saved.attacker=info:GetAttacker();saved.inflictor=info:GetInflictor();saved.weapon=info:GetWeapon()
 saved.force=info:GetDamageForce();saved.position=info:GetDamagePosition();saved.reported=info:GetReportedPosition()
end
function damageState.Restore(info, saved)
 DamageInfo()
 info:SetDamage(saved.damage);info:SetBaseDamage(saved.base);info:SetDamageBonus(saved.bonus);info:SetMaxDamage(saved.maximum)
 info:SetDamageType(saved.kind);info:SetDamageCustom(saved.custom);info:SetAmmoType(saved.ammo)
 if IsValid(saved.attacker) then info:SetAttacker(saved.attacker)end
 if IsValid(saved.inflictor) then info:SetInflictor(saved.inflictor)end
 if IsValid(saved.weapon) then info:SetWeapon(saved.weapon)end
 info:SetDamageForce(saved.force);info:SetDamagePosition(saved.position);info:SetReportedPosition(saved.reported)
end

function util.ImpactTrace( ply, tr, iDamageType, pCustomImpactName, effect )
	if tr.HitSky then
		return
	end

	if tr.Fraction == 1.0 then
		return
	end

	if tr.HitNoDraw then
		return
	end

	if !effect then          
		effect = EffectData()
		effect:SetOrigin( tr.HitPos )
		effect:SetStart( tr.StartPos )
		effect:SetSurfaceProp( tr.SurfaceProps )
		effect:SetDamageType( iDamageType )
		effect:SetHitBox( tr.HitBox )
	end

	if CLIENT then
	    effect:SetEntity( tr.Entity )
	else
	    effect:SetEntIndex( tr.Entity:EntIndex() )
	end

	if pCustomImpactName then
		util.Effect( pCustomImpactName, effect )
	else
		util.Effect( "Impact", effect )
	end
end

function util.Tracer( vecStart, vecEnd, iEntIndex, iAttachment, flVelocity, pCustomTracerName )

	local data = EffectData()
	data:SetStart( vecStart )
	data:SetOrigin( vecEnd )
	data:SetEntity( ents.GetByIndex( iEntIndex ) )
	data:SetScale( flVelocity )
	data:SetRadius( 0.1 )

	if ( iAttachment ) then
		data:SetAttachment( iAttachment )
	end

	if ( pCustomTracerName ) then
		util.Effect( pCustomTracerName, data )
	else
		util.Effect( "Tracer", data )
	end

end

local BulletTypeParameters = {
	-- CS
	ammo_50ae = {
		fPenetrationPower 		= 30,
		flPenetrationDistance 	= 1000,
	},
	ammo_762mm = {
		fPenetrationPower 		= 39,
		flPenetrationDistance 	= 5000,
	},
	ammo_556mm = {
		fPenetrationPower 		= 35,
		flPenetrationDistance 	= 4000,
	},
	ammo_556mm_box = {
		fPenetrationPower 		= 35,
		flPenetrationDistance 	= 4000,
	},
	ammo_338mag = {
		fPenetrationPower 		= 45,
		flPenetrationDistance 	= 8000,
	},
	ammo_9mm = {
		fPenetrationPower 		= 21,
		flPenetrationDistance 	= 800,
	},
	ammo_buckshot = {
		fPenetrationPower 		= 0,
		flPenetrationDistance 	= 0,
	},
	ammo_45acp = {
		fPenetrationPower 		= 15,
		flPenetrationDistance 	= 500,
	},
	ammo_357sig = {
		fPenetrationPower 		= 25,
		flPenetrationDistance 	= 800,
	},
	ammo_57mm = {
		fPenetrationPower 		= 30,
		flPenetrationDistance 	= 2000,
	},

	-- GMod
	ar2 = {
		fPenetrationPower 		= 20,
		flPenetrationDistance 	= 800,
	},
	sniperround = {
		fPenetrationPower 		= 39,
		flPenetrationDistance 	= 5000,
	},
	["357"] = {
		fPenetrationPower 		= 25,
		flPenetrationDistance 	= 800,
	},
	pistol = {
		fPenetrationPower 		= 21,
		flPenetrationDistance 	= 800,
	},
	smg1 = {
		fPenetrationPower 		= 30,
		flPenetrationDistance 	= 2000,
	},

	default = {
		fPenetrationPower 		= 0,
		flPenetrationDistance 	= 0,
	}
}

local function GetBulletTypeParameters( iBulletType )
	local params = BulletTypeParameters[iBulletType]
	if not params and type(iBulletType) == "string" then params = BulletTypeParameters[string.lower(iBulletType)] end
	params = params or BulletTypeParameters.default
	return params.fPenetrationPower, params.flPenetrationDistance
end

local MaterialParameters = {
	[MAT_METAL] = {
		flPenetrationModifier 	= 0.5,
		flDamageModifier 		= 0.3,
	},
	[MAT_DIRT] = {
		flPenetrationModifier 	= 0.5,
		flDamageModifier 		= 0.3,
	},
	[MAT_CONCRETE] = {
		flPenetrationModifier 	= 0.4,
		flDamageModifier 		= 0.25,
	},
	[MAT_GRATE] = {
		flPenetrationModifier 	= 1.0,
		flDamageModifier 		= 0.99,
	},
	[MAT_VENT] = {
		flPenetrationModifier 	= 0.5,
		flDamageModifier 		= 0.45,
	},
	[MAT_TILE] = {
		flPenetrationModifier 	= 0.65,
		flDamageModifier 		= 0.3,
	},
	[MAT_COMPUTER] = {
		flPenetrationModifier 	= 0.4,
		flDamageModifier 		= 0.45,
	},
	[MAT_WOOD] = {
		flPenetrationModifier 	= 1.0,
		flDamageModifier 		= 0.6,
	},
	default = {
		flPenetrationModifier 	= 1.0,
		flDamageModifier 		= 0.5,
	}
}

local function GetMaterialParameters( mat )
	local params = MaterialParameters[mat] or MaterialParameters.default
	return params.flPenetrationModifier, params.flDamageModifier
end

local function TraceToExit(vecStart, dir, flStepSize, flMaxDistance)
	local flDistance = 0
	local vecEnd

	while flDistance < flMaxDistance do
		flDistance = math.min(flDistance + flStepSize, flMaxDistance)
		vecEnd = vecStart + flDistance * dir

		if bit.band(util.PointContents(vecEnd), MASK_SOLID) == 0 then
			return vecEnd
		end
	end

	return false
end

function playerMeta:MakeTracer( vecStart, vecEnd, tracerName, tracerCount )
	tracerCount = tracerCount or 4
	if tracerCount <= 0 then return end

	-- Only show every 4 bullets
	if self.BulletCount and self.BulletCount < tracerCount then
		self.BulletCount = self.BulletCount + 1
		return
	else
		self.BulletCount = 1
	end

	if CLIENT then

		local vm = self:GetViewModel()
		if IsValid(vm) then
			local attachId = vm:LookupAttachment("1") -- css weapon are stupid
			local attach = vm:GetAttachment( attachId )
			if attach then
				vecStart = attach.Pos
			else
				vecStart = vm:GetPos()
			end
		end

	end
	
	local data = EffectData()
	data:SetOrigin( vecEnd )
	data:SetStart( vecStart )
	data:SetScale( 5000 )
	data:SetRadius( 0.1 )
	-- data:SetEntity( 0.1 )

	util.Effect( tracerName or "Tracer", data )

end

local debugBullets = CreateConVar("zs_debug_bullets", 0, FCVAR_CHEAT, "Draw Zombie Escape bullet debug overlays.")
local debugTracerBounds = Vector(2,2,2)
local debugTracerMins = Vector(-2,-2,-2)

local function DrawDebugTracer( tr )
	debugoverlay.Box(tr.HitPos, debugTracerMins, debugTracerBounds, 10, COLOR_RED)
	debugoverlay.Line(tr.StartPos, tr.HitPos, 10, COLOR_RED, false)
end

local phys_pushscale = GetConVar( "phys_pushscale" )
local waterContents = bit.bor( CONTENTS_WATER, CONTENTS_SLIME )
local bulletMask = bit.bor(CONTENTS_HITBOX, MASK_SOLID, CONTENTS_DEBRIS)
local bulletDamageType = bit.bor(DMG_BULLET, DMG_NEVERGIB)

local ammoMetadata = {}
local ammoDataProvider = game.GetAmmoData
local function GetAmmoMetadata(name)
	if type(name) ~= "string" or name == "" then return end
	local id = game.GetAmmoID(name)
	if type(id) ~= "number" or id < 0 then return end
	local provider = game.GetAmmoData
	local cached = provider == ammoDataProvider and ammoMetadata[id]
	if not cached then
		local data = provider(id)
		if type(data) ~= "table" then return end
		cached = {id = id, kind = bit.bor(data.dmgtype or DMG_BULLET, DMG_NEVERGIB), playerOverride = bit.band(data.flags or 0, 2) ~= 0, sniper = bit.band(data.dmgtype or 0, DMG_SNIPER) ~= 0}
		if provider == ammoDataProvider then ammoMetadata[id] = cached end
	end
	return cached
end
local function GetAmmoDamage(ammo, attacker, target, damage, scale)
	if not ammo then return damage end
	local playerDamage
	if ammo.playerOverride and IsValid(target) and target:IsPlayer() then
		playerDamage = game.GetAmmoPlayerDamage(ammo.id)
		if playerDamage ~= 0 then return playerDamage * scale end
	end
	if damage == 0 then
		local playerShot = IsValid(attacker) and attacker:IsPlayer()
		if playerShot and IsValid(target) and target:IsNPC() then
			local amount = game.GetAmmoPlayerDamage(ammo.id) * scale
			local skillScale = GetConVar("sk_dmg_inflict_scale"..game.GetSkillLevel())
			return skillScale and amount * skillScale:GetFloat() or amount
		end
		local playerDamageApplies = playerShot
		if ammo.sniper then playerDamageApplies = IsValid(target) and target:IsPlayer() end
		if playerDamageApplies then return (playerDamage or game.GetAmmoPlayerDamage(ammo.id)) * scale end
		return game.GetAmmoNPCDamage(ammo.id) * scale
	end
	return damage
end

local function GetSpreadSeed(self)
	local command
	if GetPredictionPlayer() == self then command = self:GetCurrentCommand() end
	local number = command and command:CommandNumber()
	if not number or number <= 0 then
		number = (self.ZSCSSSpreadSequence or 0) % 2147483647 + 1
		self.ZSCSSSpreadSequence = number
	end
	return bit.bxor(number, self:EntIndex() * 65537)
end

local function FireCSSBullet( self, bulletInfo, weap, spreadSeed )

	local vecSrc = bulletInfo.Src or vector_origin
	local shootAngles = bulletInfo.Dir or vector_origin
	local vecSpread = bulletInfo.Spread or vector_origin
	local flDistance = bulletInfo.Distance or 56756
	local iPenetration = 2
	local iDamage = bulletInfo.Damage or 1
	local bDoEffects = true -- TODO

	-- Get circular gaussian spread.
	spreadSeed = spreadSeed or (GetSpreadSeed(self) * 4096 + 1) % 2147483647
	local x = util.SharedRandom("zs_css_x1", -0.5, 0.5, spreadSeed) + util.SharedRandom("zs_css_x2", -0.5, 0.5, spreadSeed)
	local y = util.SharedRandom("zs_css_y1", -0.5, 0.5, spreadSeed) + util.SharedRandom("zs_css_y2", -0.5, 0.5, spreadSeed)

	local fCurrentDamage = iDamage
	local flCurrentDistance = 0.0
	local damageScale = 1

	shootAngles = shootAngles:Angle()

	local vecDirShooting = shootAngles:Forward()

	local iBulletType = bulletInfo.AmmoType or ""
	local ammo = GetAmmoMetadata(iBulletType)
	local damageType = ammo and ammo.kind or bulletDamageType

	local flDamageModifier = 0.5
	local flPenetrationModifier = 1.0

	local flPenetrationPower, flPenetrationDistance = GetBulletTypeParameters(iBulletType)

	local vecDir
	if vecSpread.x == 0 and vecSpread.y == 0 and vecSpread.z == 0 then
		vecDir = vecDirShooting:GetNormalized()
	else
		vecDir = (vecDirShooting + x * vecSpread * shootAngles:Right() + y * vecSpread * shootAngles:Up()):GetNormalized()
	end

	local callback = isfunction(bulletInfo.Callback) and bulletInfo.Callback

	local bulletFilter = team.GetPlayers(self:Team())
	if IsValid(bulletInfo.IgnoreEntity) then bulletFilter[#bulletFilter + 1] = bulletInfo.IgnoreEntity end
	local hullMins, hullMaxs
	local hullSize = bulletInfo.HullSize
	if type(hullSize) == "number" and hullSize > 0 and hullSize < math.huge then
		hullMins = Vector(-hullSize, -hullSize, -hullSize)
		hullMaxs = Vector(hullSize, hullSize, hullSize)
	end

	while fCurrentDamage >= 0 and flDistance > 0 do
		local vecEnd = vecSrc + vecDir * flDistance

		local traceData = {
			start = vecSrc,
			endpos = vecEnd,
			filter = bulletFilter,
			mask = bulletMask
		}
		local tr
		if hullMaxs then
			traceData.mins, traceData.maxs = hullMins, hullMaxs
			tr = util.TraceHull(traceData)
		else
			tr = util.TraceLine(traceData)
		end

		-- ClipTraceToPlayers?

		table.insert(bulletFilter, tr.Entity)

		if tr.Fraction == 1.0 then
			if callback then
				local info = DamageInfo()
				damageState.active = info
				local inflictor = bulletInfo.Inflictor or weap
				info:SetAttacker(bulletInfo.Attacker or self)
				info:SetInflictor(inflictor)
				info:SetDamage(fCurrentDamage)
				info:SetDamageType(damageType)
				if ammo then info:SetAmmoType(ammo.id) end
				if IsValid(inflictor) and inflictor:IsWeapon() then info:SetWeapon(inflictor) end
				info:SetDamagePosition(tr.HitPos)
				info:SetDamageForce(vecDir:GetNormal() * phys_pushscale:GetFloat() * (bulletInfo.Force or 1))
				callback(info:GetAttacker(), tr, info)
			end
			break
		end

		local iEnterMaterial = tr.MatType

		flPenetrationModifier, flDamageModifier = GetMaterialParameters(iEnterMaterial)

		local hitGrate = iEnterMaterial == MAT_GRATE

		if hitGrate then
			flPenetrationModifier = 1.0
			flDamageModifier = 0.99
		end

		local segmentDistance = tr.Fraction * flDistance
		flCurrentDistance = flCurrentDistance + segmentDistance

		if flCurrentDistance > flPenetrationDistance and iPenetration > 0 then
			iPenetration = 0
		end

		local iDamageType = damageType

		local dmginfo
		local useDamage = true
		local useEffects = true
		if SERVER or callback then
			dmginfo = DamageInfo()
			damageState.active = dmginfo
			local attacker = bulletInfo.Attacker or self
			local inflictor = bulletInfo.Inflictor or weap
			dmginfo:SetAttacker(attacker)
			dmginfo:SetInflictor(inflictor)
			dmginfo:SetDamage(GetAmmoDamage(ammo, attacker, tr.Entity, fCurrentDamage, damageScale))
			dmginfo:SetDamageType(iDamageType)
			if ammo then dmginfo:SetAmmoType(ammo.id) end
			if IsValid(inflictor) and inflictor:IsWeapon() then dmginfo:SetWeapon(inflictor) end
			dmginfo:SetDamagePosition(tr.HitPos)
			dmginfo:SetDamageForce(vecDir:GetNormal() * phys_pushscale:GetFloat() * (bulletInfo.Force or 1))
			if callback then
				local response = callback(dmginfo:GetAttacker(), tr, dmginfo)
				if type(response) == "table" then
					useDamage = response.damage ~= false
					useEffects = response.effects ~= false
				end
			end
		end

		if bDoEffects and useEffects then

			-- See if the bullet ended up underwater + started out of the water
			if bit.band( util.PointContents(tr.StartPos), waterContents ) == 0 and
				bit.band( util.PointContents(tr.HitPos), waterContents ) != 0 then

				local waterTrace = util.TraceLine({
					start = vecSrc,
					endpos = tr.HitPos,
					filter = self,
					mask = bit.bor( MASK_SHOT, waterContents )
				})

				if waterTrace.Hit then

					local data = EffectData()
					data:SetOrigin( waterTrace.HitPos )
					data:SetNormal( waterTrace.HitNormal )
					data:SetScale( math.Rand(8,12) )
					data:SetFlags( 0x0 )

					-- if waterTrace.MatType == MAT_SLOSH then
					-- 	print("water in slime")
					-- 	data:SetFlags( 0x1 ) -- FX_WATER_IN_SLIME
					-- end

					util.Effect( "gunshotsplash", data, true, true )

				end

			end

			-- Do regular hit effects
			if !tr.HitSky and !tr.HitNoDraw then
				local ent = tr.Entity
				if !(IsValid(ent) and ent:IsPlayer() and ent:Team() == self:Team()) then
					util.ImpactTrace(self, tr, iDamageType)
				end
			end

			local tracerCount = bulletInfo.Tracer or 1
			if tracerCount > 0 then self:MakeTracer(tr.StartPos, tr.HitPos, bulletInfo.TracerName, tracerCount) end

		end


		if SERVER and useDamage and IsValid(tr.Entity) then
			tr.Entity:DispatchTraceAttack(dmginfo, tr, vecDir)
		end

		if useEffects and debugBullets:GetBool() and (CLIENT or self:IsListenServerHost()) then
			DrawDebugTracer(tr)
		end

		if iPenetration == 0 and !hitGrate then
			break
		end

		if iPenetration < 0 then
			break;
		end

		local remainingDistance = flDistance - segmentDistance
		if remainingDistance <= 0 then break end
		local penetrationEnd = TraceToExit(tr.HitPos, vecDir, 24, math.min(128, remainingDistance))

		if !penetrationEnd then
			break
		end
		
		local exitTr = util.TraceLine({
			start = penetrationEnd,
			endpos = tr.HitPos,
			mask = bulletMask
		})

		if exitTr.Entity != tr.Entity and IsValid(exitTr.Entity) then
			exitTr = util.TraceLine({
				start = penetrationEnd,
				endpos = tr.HitPos,
				filter = exitTr.Entity,
				mask = bulletMask
			})
		end

		if exitTr.Fraction == 1 or exitTr.StartSolid or exitTr.AllSolid or exitTr.Entity ~= tr.Entity then break end

		local iExitMaterial = exitTr.MatType and exitTr.MatType or 0

		hitGrate = hitGrate and iExitMaterial == MAT_GRATE

		if iEnterMaterial == iExitMaterial then
			if iExitMaterial == MAT_WOOD or
				iExitMaterial == MAT_METAL then
				flPenetrationModifier = flPenetrationModifier * 2
			end
		end

		local flTraceDistance = (exitTr.HitPos - tr.HitPos):Length()

		if flTraceDistance > remainingDistance or flTraceDistance > ( flPenetrationPower * flPenetrationModifier ) then
			break
		end

		if bDoEffects and useEffects then
			util.ImpactTrace(self, exitTr, iDamageType)
		end

		flPenetrationPower = flPenetrationPower - flTraceDistance / flPenetrationModifier
		flCurrentDistance = flCurrentDistance + flTraceDistance

		vecSrc = exitTr.HitPos
		flDistance = (remainingDistance - flTraceDistance) * 0.5

		fCurrentDamage = fCurrentDamage * flDamageModifier
		damageScale = damageScale * flDamageModifier

		iPenetration = iPenetration - 1

	end

end

local suppressedHost
local damageFrames = {}
local damageDepth = 0
function playerMeta:FireCSSBullet(bulletInfo, suppressHostEvents, spreadSeed)
	local weap = self:GetActiveWeapon()
	if not IsValid(weap) then
		if bulletInfo.Damage ~= 0 or not isfunction(bulletInfo.Callback) then return end
		weap = self
	end
	local previousDamage = damageState.active
	if not SERVER and not previousDamage and not isfunction(bulletInfo.Callback) then
		FireCSSBullet(self, bulletInfo, weap, spreadSeed)
		return
	end
	damageDepth = damageDepth + 1
	local saved = damageFrames[damageDepth]
	if not saved then
		saved = {}
		if damageDepth <= 16 then damageFrames[damageDepth] = saved end
	end
	if previousDamage then damageState.Capture(previousDamage, saved) end
	damageState.active = nil
	local previous = suppressedHost
	local suppress = SERVER and suppressHostEvents
	if suppress then
		SuppressHostEvents(self)
		suppressedHost = self
	end
	local ok, failure = pcall(FireCSSBullet, self, bulletInfo, weap, spreadSeed)
	if suppress then
		suppressedHost = previous
		SuppressHostEvents(IsValid(previous) and previous or NULL)
	end
	if previousDamage then damageState.Restore(previousDamage, saved) end
	for key in pairs(saved) do saved[key] = nil end
	damageState.active = previousDamage
	damageDepth = damageDepth - 1
	if not ok then error(failure, 0) end
end

local function FireCSSBullets(self, bulletInfo, suppressHostEvents)
	local count = bulletInfo.Num or 1
	if type(count) ~= "number" or count ~= count or count == math.huge or count <= 0 then return end
	local seed = GetSpreadSeed(self)
	for i = 1, count do
		self:FireCSSBullet(bulletInfo, suppressHostEvents, (seed * 4096 + i) % 2147483647)
	end
end

local lagCompensating = false
playerMeta.OldFireBullets = FindMetaTable("Entity").FireBullets
function playerMeta:FireBullets(bulletInfo, suppressHostEvents)
	if not GAMEMODE.ZombieEscape then
		self:OldFireBullets(bulletInfo, suppressHostEvents)
		return
	end
	if not IsFirstTimePredicted() then return end
	local lagCompensation = SERVER and not self:IsListenServerHost() and not lagCompensating
	if not lagCompensation then
		FireCSSBullets(self, bulletInfo, suppressHostEvents)
		return
	end
	self:LagCompensation(true)
	lagCompensating = true
	local ok, failure = pcall(FireCSSBullets, self, bulletInfo, suppressHostEvents)
	lagCompensating = false
	self:LagCompensation(false)
	if not ok then error(failure, 0) end
end
