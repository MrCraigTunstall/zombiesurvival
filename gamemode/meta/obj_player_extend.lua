local meta = FindMetaTable("Player")
if not meta then return end

local util_SharedRandom = util.SharedRandom
local PLAYERANIMEVENT_FLINCH_HEAD = PLAYERANIMEVENT_FLINCH_HEAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local GESTURE_SLOT_FLINCH = GESTURE_SLOT_FLINCH
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local HITGROUP_HEAD = HITGROUP_HEAD
local HITGROUP_CHEST = HITGROUP_CHEST
local HITGROUP_STOMACH = HITGROUP_STOMACH
local HITGROUP_LEFTLEG = HITGROUP_LEFTLEG
local HITGROUP_RIGHTLEG = HITGROUP_RIGHTLEG
local HITGROUP_LEFTARM = HITGROUP_LEFTARM
local HITGROUP_RIGHTARM = HITGROUP_RIGHTARM
local TEAM_UNDEAD = TEAM_UNDEAD
local TEAM_SPECTATOR = TEAM_SPECTATOR
local TEAM_HUMAN = TEAM_HUMAN
local IN_ZOOM = IN_ZOOM
local MASK_SOLID = MASK_SOLID

local getmetatable = getmetatable

local M_Entity = FindMetaTable("Entity")

local P_Team = meta.Team

local E_IsValid = M_Entity.IsValid
local E_GetDTBool = M_Entity.GetDTBool
local E_GetTable = M_Entity.GetTable

function meta:GetMaxHealthEx()
	if self:Team() == TEAM_UNDEAD then
		return self:GetMaxZombieHealth()
	end

	return self:GetMaxHealth()
end

function meta:Dismember(dismembermenttype)
	local effectdata = EffectData()
		effectdata:SetOrigin(self:EyePos())
		effectdata:SetEntity(self)
		effectdata:SetScale(dismembermenttype)
	util.Effect("dismemberment", effectdata, true, true)
end

function meta:HasWon()
	if self:Team() ~= TEAM_UNDEAD and self:GetObserverMode() == OBS_MODE_ROAMING then
		if SERVER then
			local target = self:GetObserverTarget()
			return target and target:IsValid() and target:GetClass() == "prop_obj_exit"
		end

		return true
	end

	return false
end

local TEAM_SPECTATOR = TEAM_SPECTATOR
function meta:IsSpectator()
	return self:Team() == TEAM_SPECTATOR
end

function meta:GetBossZombieIndex()
	if SERVER then return GAMEMODE:GetBossClassForPlayer(self) end
	return GAMEMODE:GetPreferredBossClass(self)
end

function meta:GetAuraRange()
	local wep = self:GetActiveWeapon()
	return wep:IsValid() and wep.GetAuraRange and wep:GetAuraRange() or 2048
end

function meta:GetCoupledHeadcrab()
	local status = self.m_Couple
	return status and status:IsValid() and status:GetPartner() or NULL
end

function meta:GetPoisonDamage()
	return self.PoisonRecovery and self.PoisonRecovery:IsValid() and self.PoisonRecovery:GetDamage() or 0
end

function meta:GetBleedDamage()
	return self.Bleed and self.Bleed:IsValid() and self.Bleed:GetDamage() or 0
end

function meta:CallWeaponFunction(funcname, ...)
	local wep = self:GetActiveWeapon()
	if wep:IsValid() and wep[funcname] then
		return wep[funcname](wep, self, ...)
	end
end

function meta:ClippedName()
	local name = self:Name()
	if #name > 16 then
		name = string.sub(name, 1, 14)..".."
	end

	return name
end

function meta:DispatchAltUse()
	local tr = self:TraceLine(64, MASK_SOLID, self:GetMeleeFilter())
	local ent = tr.Entity
	if ent and ent:IsValid() then
		if ent.AltUse then
			return ent:AltUse(self, tr)
		end
	end
end

function meta:MeleeViewPunch(damage)
	local maxpunch = (damage + 25) * 0.5
	local minpunch = -maxpunch
	self:ViewPunch(Angle(math.Rand(minpunch, maxpunch), math.Rand(minpunch, maxpunch), math.Rand(minpunch, maxpunch)))
end

function meta:NearArsenalCrate()
	if GAMEMODE:IsTraderOnlyRound() then return GAMEMODE:GetNearbyTrader(self) ~= nil end
	return GAMEMODE:HasNearbyArsenalCrate(self)
end
meta.IsNearArsenalCrate = meta.NearArsenalCrate

function meta:NearestArsenalCrateOwnedByOther()
	local pos = self:EyePos()
	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_arsenalcrate")) do
		if IsValid(ent) then
			local owner = ent:GetObjectOwner()
			if owner ~= self and IsValid(owner) and owner:IsPlayer() and owner:Team() == TEAM_HUMAN then
				local nearest = ent:NearestPoint(pos)
				if pos:DistToSqr(nearest) <= 80 * 80 and (WorldVisible(pos, nearest) or self:TraceLine(80).Entity == ent) then return ent end
			end
		end
	end
end

function meta:NearSigil()
	local pos = self:EyePos()

	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_obj_sigil")) do
		local nearest = ent:NearestPoint(pos)
		if pos:DistToSqr(nearest) <= 90 * 90 and (WorldVisible(pos, nearest) or self:TraceLine(90).Entity == ent) then
			return true
		end
	end

	return false
end
meta.IsNearSigil = meta.NearSigil

function meta:SetZombieClassName(classname)
	if GAMEMODE.ZombieClasses[classname] then
		self:SetZombieClass(GAMEMODE.ZombieClasses[classname].Index)
	end
end

function meta:SetPoints(points)
	self:SetDTInt(1, points)
end

function meta:GetPoints()
	return self:GetDTInt(1)
end

function meta:SetTokens(pts)
	self:SetNWInt('btokens', pts)	
end	

function meta:GetTokens()
	return self:GetNWInt('btokens', 0)
end

local function SendPlayerCondition(pl, hemophilia, value, nosend, field)
	if not SERVER or nosend or pl:IsBot() then return end
	local state = value == nil and 0 or value and 2 or 1
	if pl[field] == state then return end
	net.Start("zs_playercondition")
	net.WriteBool(hemophilia)
	net.WriteUInt(state, 2)
	net.Send(pl)
	pl[field] = state
end

function meta:SetPalsy(onoff, nosend)
	self.m_Palsy = onoff
	SendPlayerCondition(self, false, onoff, nosend, "ZSPalsySent")
end

function meta:GetPalsy()
	return self.m_Palsy
end

function meta:SetHemophilia(onoff, nosend)
	self.m_Hemophilia = onoff
	SendPlayerCondition(self, true, onoff, nosend, "ZSHemophiliaSent")
end

function meta:GetHemophilia()
	return self.m_Hemophilia
end

function meta:SetUnlucky(onoff)
	self.m_Unlucky = onoff
end

function meta:GetUnlucky()
	return self.m_Unlucky
end

function meta:AddLegDamage(damage)
	self:SetLegDamage(self:GetLegDamage() + damage)
end

function meta:SetLegDamage(damage)
	self.LegDamage = CurTime() + math.min(GAMEMODE.MaxLegDamage, damage * 0.125)
	if SERVER then
		self:UpdateLegDamage()
	end
end

function meta:RawSetLegDamage(time)
	self.LegDamage = math.min(CurTime() + GAMEMODE.MaxLegDamage, time)
	if SERVER then
		self:UpdateLegDamage()
	end
end

function meta:RawCapLegDamage(time)
	self:RawSetLegDamage(math.max(self.LegDamage or 0, time))
end

function meta:GetLegDamage()
	return math.max(0, (self.LegDamage or 0) - CurTime())
end

function meta:WouldDieFrom(damage, hitpos)
	return self:Health() <= damage * GAMEMODE:GetZombieDamageScale(hitpos, self)
end

local BLEED_DAMAGE_TYPES = bit.bor(DMG_SLASH, DMG_CLUB, DMG_BULLET, DMG_BUCKSHOT, DMG_CRUSH)

function meta:ProcessDamage(dmginfo)
	if SERVER and self.ZSReturns then GAMEMODE:ApplyReturnDamage(self, dmginfo) end
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	if SERVER and (self.ZSTraits or IsValid(attacker) and attacker.ZSTraits) and GAMEMODE:ApplyTraitDamage(self, dmginfo) then return true end

	if self.DamageVulnerability then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.DamageVulnerability)
	end

	if self:Team() == TEAM_UNDEAD then
		if self ~= attacker then
			dmginfo:SetDamage(dmginfo:GetDamage() * GAMEMODE:GetZombieDamageScale(dmginfo:GetDamagePosition(), self))
		end

		return self:CallZombieFunction("ProcessDamage", dmginfo)
	elseif attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD and inflictor:IsValid() and inflictor == attacker:GetActiveWeapon() then
		local damage = dmginfo:GetDamage()

		local scale = inflictor.SlowDownScale or 1
		if damage >= 40 or scale > 1 then
			local dolegdamage = true
			if inflictor.SlowDownImmunityTime then
				local curtime = CurTime()
				if curtime < (self.SlowDownImmunityTime or 0) then
					dolegdamage = false
				else
					self.SlowDownImmunityTime = curtime + inflictor.SlowDownImmunityTime
				end
			end
			if dolegdamage then
				self:RawCapLegDamage(self:GetLegDamage() + CurTime() + damage * 0.04 * scale)
			end
		end

		if self:GetHemophilia() and damage >= 5 then
			local dmgtype = dmginfo:GetDamageType()
			if dmgtype == 0 or bit.band(dmgtype, BLEED_DAMAGE_TYPES) ~= 0 then
				local bleed = self:GiveStatus("bleed")
				if bleed and bleed:IsValid() then
					bleed:AddDamage(damage * 0.2)
					if attacker:IsValid() and attacker:IsPlayer() then
						bleed.Damager = attacker
					end
				end
			end
		end
	end
end

function meta:KnockDown(time)
	if self:Team() == TEAM_HUMAN and not GAMEMODE:HasPlayerTrait(self, "strongfeet") then
		self:GiveStatus("knockdown", time or 3)
	end
end

function meta:GetZombieClass()
	return self.Class or GAMEMODE.DefaultZombieClass
end

function meta:GetZombieClassTable()
	local classes = GAMEMODE.ZombieClasses
	return classes[self:GetZombieClass()] or classes[GAMEMODE.DefaultZombieClass]
end

function meta:CallZombieFunction0(funcname)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self)
		end
	end
end

function meta:CallZombieFunction1(funcname, a1)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self, a1)
		end
	end
end

function meta:CallZombieFunction2(funcname, a1, a2)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self, a1, a2)
		end
	end
end

function meta:CallZombieFunction3(funcname, a1, a2, a3)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self, a1, a2, a3)
		end
	end
end

function meta:CallZombieFunction4(funcname, a1, a2, a3, a4)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self, a1, a2, a3, a4)
		end
	end
end
meta.CallZombieFunction = meta.CallZombieFunction4 -- 4 should be enough for legacy.

function meta:CallZombieFunction5(funcname, a1, a2, a3, a4, a5)
	if P_Team(self) == TEAM_UNDEAD then
		local classes = GAMEMODE.ZombieClasses
		local zctab = classes[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass] or classes[GAMEMODE.DefaultZombieClass]
		local zcfunc = zctab and zctab[funcname]
		if zcfunc then
			return zcfunc(zctab, self, a1, a2, a3, a4, a5)
		end
	end
end

function meta:SetSpeed(speed)
	if not speed then speed = 200 end

	self:SetWalkSpeed(speed)
	self:SetRunSpeed(speed)
	self:SetMaxSpeed(speed)
end

function meta:SetHumanSpeed(speed)
	if self:Team() ~= TEAM_UNDEAD then self:SetSpeed(speed or self:ResetSpeed(true)) end
end

function meta:ResetSpeed(noset, health)
	if not self:IsValid() then return end

	if self:Team() == TEAM_UNDEAD then
		local speed = self:GetZombieClassTable().Speed * GAMEMODE.ZombieSpeedMultiplier * self:GetNW2Float("zs_zombie_variant_speed", 1) * GAMEMODE:GetTraitSpeedScale(self)
		self:SetSpeed(speed)
		return speed
	end

	local wep = self:GetActiveWeapon()
	local speed

	if wep:IsValid() and wep.GetWalkSpeed then
		speed = wep:GetWalkSpeed()
	end

	if not speed then
		speed = wep.WalkSpeed or SPEED_NORMAL
	end

	if self.HumanSpeedAdder and self:Team() == TEAM_HUMAN and 32 < speed then
		speed = speed + self.HumanSpeedAdder
	end

	--[[if self:IsHolding() then
		local status = self.status_human_holding
		if status and status:IsValid() and status:GetObject():IsValid() and status:GetObject():GetPhysicsObject():IsValid() then
			speed = math.min(speed, math.max(CARRY_SPEEDLOSS_MINSPEED, speed - status:GetObject():GetPhysicsObject():GetMass() * CARRY_SPEEDLOSS_PERKG))
		end
	end]]

	if 32 < speed and not GAMEMODE.ZombieEscape then
		if not health then health = self:Health() end
		if health < 60 then
			speed = math.max(88, speed - speed * 0.4 * (1 - health / 60))
		end
	end

	speed = speed * GAMEMODE:GetReturnSpeedScale(self) * GAMEMODE:GetTraitSpeedScale(self)
	if not noset then
		self:SetSpeed(speed)
	end

	return speed
end

function meta:ResetJumpPower(noset)
	local power = DEFAULT_JUMP_POWER * GAMEMODE:GetTraitJumpScale(self)

	if self:Team() == TEAM_UNDEAD then
		power = self:CallZombieFunction("GetJumpPower") or power

		local classtab = self:GetZombieClassTable()
		if classtab and classtab.JumpPower then
			power = classtab.JumpPower
		end
	else
		if self:GetBarricadeGhosting() then
			power = power * 0.25
			if not noset then
				self:SetJumpPower(power)
			end

			return power
		end
	end

	local wep = self:GetActiveWeapon()
	if wep and wep.ResetJumpPower then
		power = wep:ResetJumpPower(power) or power
	end

	if not noset then
		self:SetJumpPower(power)
	end

	return power
end

function meta:SetBarricadeGhosting(b, fullspeed)
 return GAMEMODE:SetPlayerBarricadeGhosting(self, b, fullspeed)
end

function meta:GetBarricadeGhosting()
 return GAMEMODE:GetBarricadeGhostMode(self) ~= 0
end
meta.IsBarricadeGhosting = meta.GetBarricadeGhosting

function meta:ShouldBarricadeGhostWith(ent)
 return ent:IsBarricadeProp()
end

function meta:BarricadeGhostingThink()
 if GAMEMODE:UpdatePlayerBarricadeGhosting(self, self:KeyDown(IN_ZOOM)) then self:SetLocalVelocity(vector_origin) end
end
GM.ZSBarricadeGhostThink = meta.BarricadeGhostingThink

function meta:ShouldNotCollide(ent)
	if E_IsValid(ent) then
		if getmetatable(ent) == meta then
			if P_Team(self) == P_Team(ent) or E_GetTable(self).NoCollideAll or E_GetTable(ent).NoCollideAll then
				return true
			end

			return false
		end

		return GAMEMODE:GetBarricadeGhostCollisionFlag(self, 0) and ent:IsBarricadeProp()
	end

	return false
end

if GM.BindPlayerCollisionRule then
	GM:BindPlayerCollisionRule(meta.ShouldNotCollide, meta, P_Team, E_IsValid, E_GetTable, function(pl, slot) return GAMEMODE:GetBarricadeGhostCollisionFlag(pl, slot) end)
end

function meta:TemporaryNoCollide(force)
	if self:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER and not force then return end
	if GAMEMODE:HasTemporaryCollisionOverlap(self, false) then
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		GAMEMODE:TrackTemporaryCollision(self, false)
	else
		GAMEMODE:StopTemporaryCollision(self, false)
		if self:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER then self:SetCollisionGroup(COLLISION_GROUP_PLAYER) end
	end
end

meta.OldSetHealth = FindMetaTable("Entity").SetHealth
function meta:SetHealth(health)
	self:OldSetHealth(health)
	if self:Team() ~= TEAM_UNDEAD and 1 <= health then
		self:ResetSpeed(nil, health)
	end
end

function meta:IsHeadcrab()
	if self:Team() ~= TEAM_UNDEAD then return false end
	local class = self:GetZombieClassTable()
	return class and class.IsHeadcrab
end

function meta:AirBrake()
	local vel = self:GetVelocity()

	vel.x = vel.x * 0.15
	vel.y = vel.y * 0.15
	if vel.z > 0 then
		vel.z = vel.z * 0.15
	end

	self:SetLocalVelocity(vel)
end

function meta:ActiveBarricadeGhosting(override)
 return GAMEMODE:IsPlayerInsideBarricade(self, override)
end

function meta:IsHolding()
	return self:GetHolding():IsValid()
end
meta.IsCarrying = meta.IsHolding

function meta:GetHolding()
	local status = self.status_human_holding
	if status and IsValid(status) and not status.Removing and not status:IsMarkedForDeletion()
		and status:GetOwner() == self and (not status.HeldOwner or status.HeldOwner == self) then
		local obj = status:GetObject()
		if IsValid(obj) and not obj:IsMarkedForDeletion() and (not status.HeldObject or status.HeldObject == obj) then return obj end
	end

	return NULL
end

function meta:GetMaxZombieHealth()
	local health = self:GetNW2Int("zs_zombie_variant_health", 0)
	if health > 0 then return health end
	health = self:GetDTInt(0)
	if health > 1 then return health end
	return self:GetZombieClassTable().Health
end

local oldmaxhealth = FindMetaTable("Entity").GetMaxHealth
function meta:GetMaxHealth()
	if self:Team() == TEAM_UNDEAD then
		return self:GetMaxZombieHealth()
	end

	return oldmaxhealth(self)
end

if not meta.OldAlive then
	meta.OldAlive = meta.Alive
	function meta:Alive()
		return self:GetObserverMode() == OBS_MODE_NONE and not self.NeverAlive and self:OldAlive()
	end
end

local VoiceSets = {}

VoiceSets[VOICESET_MALE] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("vo/npc/male01/ammo03.wav"),
		Sound("vo/npc/male01/ammo04.wav"),
		Sound("vo/npc/male01/ammo05.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("vo/npc/male01/ow01.wav"),
		Sound("vo/npc/male01/ow02.wav"),
		Sound("vo/npc/male01/pain01.wav"),
		Sound("vo/npc/male01/pain02.wav"),
		Sound("vo/npc/male01/pain03.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("vo/npc/male01/pain04.wav"),
		Sound("vo/npc/male01/pain05.wav"),
		Sound("vo/npc/male01/pain06.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav"),
		Sound("vo/npc/male01/pain09.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("vo/npc/male01/no02.wav"),
		Sound("ambient/voices/citizen_beaten1.wav"),
		Sound("ambient/voices/citizen_beaten3.wav"),
		Sound("ambient/voices/citizen_beaten4.wav"),
		Sound("ambient/voices/citizen_beaten5.wav"),
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("ambient/voices/m_scream1.wav")
	}
}

VoiceSets[VOICESET_BARNEY] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("items/ammo_pickup.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("vo/npc/Barney/ba_pain02.wav"),
		Sound("vo/npc/Barney/ba_pain07.wav"),
		Sound("vo/npc/Barney/ba_pain04.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("vo/npc/Barney/ba_pain01.wav"),
		Sound("vo/npc/Barney/ba_pain08.wav"),
		Sound("vo/npc/Barney/ba_pain10.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("vo/npc/Barney/ba_pain05.wav"),
		Sound("vo/npc/Barney/ba_pain06.wav"),
		Sound("vo/npc/Barney/ba_pain09.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("vo/npc/Barney/ba_ohshit03.wav"),
		Sound("vo/npc/Barney/ba_no01.wav"),
		Sound("vo/npc/Barney/ba_no02.wav"),
		Sound("vo/npc/Barney/ba_pain03.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("vo/k_lab/ba_thingaway02.wav")
	}
}

VoiceSets[VOICESET_FEMALE] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("vo/npc/female01/ammo03.wav"),
		Sound("vo/npc/female01/ammo04.wav"),
		Sound("vo/npc/female01/ammo05.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("vo/npc/female01/pain01.wav"),
		Sound("vo/npc/female01/pain02.wav"),
		Sound("vo/npc/female01/pain03.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("vo/npc/female01/pain04.wav"),
		Sound("vo/npc/female01/pain05.wav"),
		Sound("vo/npc/female01/pain06.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("vo/npc/female01/pain07.wav"),
		Sound("vo/npc/female01/pain08.wav"),
		Sound("vo/npc/female01/pain09.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("vo/npc/female01/no01.wav"),
		Sound("vo/npc/female01/ow01.wav"),
		Sound("vo/npc/female01/ow02.wav"),
		Sound("vo/npc/female01/goodgod.wav"),
		Sound("ambient/voices/citizen_beaten2.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("ambient/voices/f_scream1.wav")
	}
}

VoiceSets[VOICESET_ALYX] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("vo/npc/female01/ammo03.wav"),
		Sound("vo/npc/female01/ammo04.wav"),
		Sound("vo/npc/female01/ammo05.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("vo/npc/Alyx/gasp03.wav"),
		Sound("vo/npc/Alyx/hurt08.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("vo/npc/Alyx/hurt04.wav"),
		Sound("vo/npc/Alyx/hurt06.wav"),
		Sound("vo/Citadel/al_struggle07.wav"),
		Sound("vo/Citadel/al_struggle08.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("vo/npc/Alyx/hurt05.wav"),
		Sound("vo/npc/Alyx/hurt06.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("vo/npc/Alyx/no01.wav"),
		Sound("vo/npc/Alyx/no02.wav"),
		Sound("vo/npc/Alyx/no03.wav"),
		Sound("vo/Citadel/al_dadgordonno_c.wav"),
		Sound("vo/Streetwar/Alyx_gate/al_no.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("vo/npc/Alyx/uggh01.wav"),
		Sound("vo/npc/Alyx/uggh02.wav")
	}
}

VoiceSets[VOICESET_COMBINE] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("npc/combine_soldier/vo/hardenthatposition.wav"),
		Sound("npc/combine_soldier/vo/readyweapons.wav"),
		Sound("npc/combine_soldier/vo/weareinaninfestationzone.wav"),
		Sound("npc/metropolice/vo/dismountinghardpoint.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("npc/combine_soldier/pain1.wav"),
		Sound("npc/combine_soldier/pain2.wav"),
		Sound("npc/combine_soldier/pain3.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("npc/metropolice/pain1.wav"),
		Sound("npc/metropolice/pain2.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("npc/metropolice/pain3.wav"),
		Sound("npc/metropolice/pain4.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("npc/combine_soldier/die1.wav"),
		Sound("npc/combine_soldier/die2.wav"),
		Sound("npc/combine_soldier/die3.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("npc/combine_soldier/die1.wav"),
		Sound("npc/combine_soldier/die2.wav"),
		Sound("npc/metropolice/vo/shit.wav")
	}
}

VoiceSets[VOICESET_MONK] = {
	[VOICELINE_GIVEAMMO] = {
		Sound("vo/ravenholm/monk_giveammo01.wav")
	},
	[VOICELINE_PAIN_LIGHT] = {
		Sound("vo/ravenholm/monk_pain01.wav"),
		Sound("vo/ravenholm/monk_pain02.wav"),
		Sound("vo/ravenholm/monk_pain03.wav"),
		Sound("vo/ravenholm/monk_pain05.wav")
	},
	[VOICELINE_PAIN_MED] = {
		Sound("vo/ravenholm/monk_pain04.wav"),
		Sound("vo/ravenholm/monk_pain06.wav"),
		Sound("vo/ravenholm/monk_pain07.wav"),
		Sound("vo/ravenholm/monk_pain08.wav")
	},
	[VOICELINE_PAIN_HEAVY] = {
		Sound("vo/ravenholm/monk_pain09.wav"),
		Sound("vo/ravenholm/monk_pain10.wav"),
		Sound("vo/ravenholm/monk_pain12.wav")
	},
	[VOICELINE_DEATH] = {
		Sound("vo/ravenholm/monk_death07.wav")
	},
	[VOICELINE_EYEPAIN] = {
		Sound("vo/ravenholm/monk_death07.wav")
	}
}

function meta:GetVoiceLines(line_type)
	local voices = VoiceSets[self:GetDTInt(DT_PLAYER_INT_VOICESET)]
	return voices and voices[line_type]
end

if SERVER and net.Receivers then
	for _, name in ipairs({"voice_eyepain", "voice_giveammo", "voice_death", "voice_zombiedeath", "voice_pain", "voice_zombiepain"}) do net.Receivers[name] = nil end
end

-- updated by mka0207
-- Override these because they're different in 1st person and on the server.
function meta:SyncAngles()
	local ang = self:EyeAngles()
	ang.pitch = 0
	ang.roll = 0
	return ang
end
meta.GetAngles = meta.SyncAngles

function meta:GetForward()
	return self:SyncAngles():Forward()
end

function meta:GetUp()
	return self:SyncAngles():Up()
end

function meta:GetRight()
	return self:SyncAngles():Right()
end

function meta:GetPhantomHealth()
	return self:GetDTFloat(DT_PLAYER_FLOAT_PHANTOMHEALTH)
end
