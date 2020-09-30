GM.Name		=	"Zombie Survival"
GM.Author	=	"William \"JetBoom\" Moodhe"
GM.Email	=	"williammoodhe@gmail.com"
GM.Website	=	"http://www.noxiousnet.com"
GM.Version = 8 -- don't touch.
GM.SubVersion = "Zombie Survival Redemption" -- don't touch here too.

-- No, adding a gun doesn't make your name worth being here.
GM.Credits = {
	{"William \"JetBoom\" Moodhe", "williammoodhe@gmail.com (www.noxiousnet.com)", "Creator / Programmer"},
	{"11k", "tjd113@gmail.com", "Zombie view models"},
	{"Eisiger", "k2deseve@gmail.com", "Zombie kill icons"},
	{"Austin \"Little Nemo\" Killey", "austin_odyssey@yahoo.com", "Ambient music"},
	{"Zombie Panic: Source", "http://www.zombiepanic.org/", "Melee weapon sounds"},
	{"Samuel", "samuel_games@hotmail.com", "Board Kit models"},
	{"Typhon", "lukas-tinel@hotmail.com", "Fear-o-meter textures"},
	{"Benjy, The Darker One, Raox, Scott", "", "Code contributions"},

	{"Mr. Darkness", "", "Russian translation"},
	{"honsal", "", "Korean translation"},
	{"rui_troia", "", "Portuguese translation"},
	{"Shinyshark", "", "Dutch translation"},
	{"Kradar", "", "Italian translation"},
	{"Raptor", "", "German translation"},
	{"The Special Duckling", "", "Danish translation"},
	{"ptown, Dr. Broly", "", "Spanish translation"},

	{"Anyone else on GitHub or who I've forgotten", "", "Various contributions"},
}

GM.Credits2 = {
	{"MrCraigTunstall", "https://steamcommunity.com/profiles/76561198059515155", "Project Leader"},
	{"Mka0207", "https://fwkzt.com", "Simple PvP Zombie and Zombine Classes"},
	{"Flairieve", "https://steamcommunity.com/profiles/76561198055782802", "Programmer / Contributor"},
	{"Dadido3", "https://steamcommunity.com/profiles/76561198005024048", "Assistant Programmer / German Translation"},
	{"Berry", "https://steamcommunity.com/profiles/76561198158864042", "Issue Tracker / Russian Translation"},
	{"ForrestMarkX", "https://steamcommunity.com/profiles/76561197997881512", "Spectate System"},
	{"Sulfito", "https://steamcommunity.com/profiles/76561198026081830", "Spanish Translation"},
	{"Sandball", "http://steamcommunity.com/profiles/76561198261601032", "Korean Translation"},
	{"Raox", "http://steamcommunity.com/profiles/76561197998357643", "Gluon Gun / Various Contributions"}
}


include("misc/nixthelag.lua")
include("misc/buffthefps.lua")

function GM:GetNumberOfWaves()
	local default = GetGlobalBool("classicmode") and 10 or self.NumberOfWaves
	local num = GetGlobalInt("numwaves", default) -- This is controlled by logic_waves.
	return num == -2 and default or num
end

function GM:GetWaveOneLength()
	return GetGlobalBool("classicmode") and self.WaveOneLengthClassic or self.WaveOneLength
end

include("sh_translate.lua")
include("shared/sh_colors.lua")
include("sh_serialization.lua")

include("shared/sh_globals.lua")
include("shared/sh_crafts.lua")
include("shared/sh_util.lua")
include("shared/sigilmaps.lua")
include("shared/sh_options.lua")
include("shared/sh_zombieclasses.lua")
include("shared/sh_animations.lua")
include("shared/sh_sigils.lua")
include("shared/sh_channel.lua")
include("shared/sh_bullets.lua")
include("shared/sh_scoreboardtags.lua")
include("shared/sh_weaponquality.lua")

include("misc/noxapi/noxapi.lua")

include("meta/obj_vector_extend.lua")
include("meta/obj_entity_extend.lua")
include("meta/obj_player_extend.lua")
include("meta/obj_weapon_extend.lua")

include("misc/workshopfix.lua")

----------------------

GM.EndRound = false
GM.StartingWorth = 100
GM.ZombieVolunteers = {}

team.SetUp(TEAM_ZOMBIE, ""..translate.Get("team_zombie"), Color(255, 0, 0, 255))
team.SetUp(TEAM_SURVIVORS, ""..translate.Get("team_humans"), Color(0, 160, 255, 255))
team.SetUp(TEAM_REDEEMERS, "Redeemers", Color(255, 154, 0, 255))

CVars = {}

local validmodels = player_manager.AllValidModels()
validmodels["tf01"] = nil
validmodels["tf02"] = nil

vector_tiny = Vector(0.001, 0.001, 0.001)

-- ogg/mp3 still doesn't work with SoundDuration() function
GM.SoundDuration = {
	["zombiesurvival/music_win.ogg"] = 33.149,
	["zombiesurvival/music_lose.ogg"] = 45.714,
	["zombiesurvival/lasthuman.ogg"] = 120.503,

	["zombiesurvival/beats/defaulthuman/1.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/2.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/3.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/4.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/5.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/6.ogg"] = 14.222,
	["zombiesurvival/beats/defaulthuman/7.ogg"] = 14.222,
	["zombiesurvival/beats/defaulthuman/8.ogg"] = 7.111,
	["zombiesurvival/beats/defaulthuman/9.ogg"] = 14.222,

	["zombiesurvival/beats/defaultzombiev2/1.ogg"] = 8,
	["zombiesurvival/beats/defaultzombiev2/2.ogg"] = 8,
	["zombiesurvival/beats/defaultzombiev2/3.ogg"] = 8,
	["zombiesurvival/beats/defaultzombiev2/4.ogg"] = 8,
	["zombiesurvival/beats/defaultzombiev2/5.ogg"] = 8,
	["zombiesurvival/beats/defaultzombiev2/6.ogg"] = 6.038,
	["zombiesurvival/beats/defaultzombiev2/7.ogg"] = 6.038,
	["zombiesurvival/beats/defaultzombiev2/8.ogg"] = 6.038,
	["zombiesurvival/beats/defaultzombiev2/9.ogg"] = 6.038,
	["zombiesurvival/beats/defaultzombiev2/10.ogg"] = 6.038
}

function GM:AddCustomAmmo()
	game.AddAmmoType({name = "pulse"})
	game.AddAmmoType({name = "stone"})

	game.AddAmmoType({name = "spotlamp"})
	game.AddAmmoType({name = "manhack"})
	game.AddAmmoType({name = "manhack_saw"})
	game.AddAmmoType({name = "drone"})

	game.AddAmmoType({name = "dummy"})
end

function GM:RefreshMapIsObjective()
	local mapname = string.lower(game.GetMap())
	if string.find(mapname, "_obj_", 1, true) or string.find(mapname, "objective", 1, true) then
		self.ObjectiveMap = true
	else
		self.ObjectiveMap = false
	end
end

-- Utility function to setup a weapon's DefaultClip.
function GM:SetupDefaultClip(tab)
	tab.DefaultClip = math.ceil(tab.ClipSize * self.SurvivalClips * (tab.ClipMultiplier or 1))
end

-- Some weapons are derived from weapon_base and try to make use of .Owner
function GM:FixWeaponBase()
	local base = weapons.GetStored("weapon_base")

	base.TranslateActivity = function(me, act)
		if me.ActivityTranslate[act] ~= nil then
			return me.ActivityTranslate[act]
		end

		return -1
	end

	base.TakePrimaryAmmo = function(me, num)
		if me.Weapon:Clip1() <= 0 then
			if me:Ammo1() <= 0 then return end

			me:GetOwner():RemoveAmmo(num, me.Weapon:GetPrimaryAmmoType())

			return
		end

		me.Weapon:SetClip1(me.Weapon:Clip1() - num)
	end

	base.Ammo1 = function(me)
		return me:GetOwner():GetAmmoCount(me.Weapon:GetPrimaryAmmoType())
	end
end

function GM:IsWeaponUnlocked(tab)
	if self:GetWave() <= -1 or self:GetNumberOfWaves() <= -1 then return true end
	return tab.Unlocked or self:GetWave() >= math.floor(tab.Wave * self:GetNumberOfWaves())
end

function GM:CanRemoveOthersNail(pl, nailowner, ent)
	local plpoints = pl:Frags()
	local ownerpoints = nailowner:Frags()
	if plpoints >= 75 or ownerpoints < 75 then return true end

	pl:PrintTranslatedMessage(HUD_PRINTCENTER, "cant_remove_nails_of_superior_player")

	return false
end

function GM:SetRedeemBrains(amount)
	SetGlobalInt("redeembrains", amount)
end

function GM:GetRedeemBrains()
	return GetGlobalInt("redeembrains", self.DefaultRedeem)
end

function GM:PlayerIsAdmin(pl)
	return pl:IsAdmin()
end

function GM:GetFallDamage(pl, fallspeed)
	return 0
end

function GM:ShouldRestartRound()
	if self.TimeLimit == -1 or self.RoundLimit == -1 then return true end

	local roundlimit = self.RoundLimit
	if self.ZombieEscape and roundlimit > 0 then
		roundlimit = math.ceil(roundlimit * 1.5)
	end

	local timelimit = self.TimeLimit
	if self.ZombieEscape and timelimit > 0 then
		timelimit = timelimit * 1.5
	end

	if timelimit > 0 and CurTime() >= timelimit or roundlimit > 0 and self.CurrentRound >= roundlimit then return false end

	return true
end

function GM:ZombieSpawnDistanceSort(other)
	return self._ZombieSpawnDistance < other._ZombieSpawnDistance
end

function GM:SortZombieSpawnDistances(allplayers)
	local curtime = CurTime()

	local zspawns = ents.FindByClass("zombiegasses")
	if #zspawns == 0 then
		zspawns = team.GetValidSpawnPoint(TEAM_UNDEAD)
	end

	for _, pl in pairs(allplayers) do
		if pl:Team() == TEAM_UNDEAD or pl:GetInfo("zs_alwaysvolunteer") == "1" then
			pl._ZombieSpawnDistance = -1
		elseif CLIENT or pl.LastNotAFK and CurTime() <= pl.LastNotAFK + 60 then
			local plpos = pl:GetPos()
			local closest = 9999999
			for _, ent in pairs(zspawns) do
				local dist = ent:GetPos():Distance(plpos)
				if dist < closest then
					closest = dist
				end
			end
			pl._ZombieSpawnDistance = closest
		else
			pl._ZombieSpawnDistance = 9999999
		end
	end

	table.sort(allplayers, self.ZombieSpawnDistanceSort)
end

function GM:ValidMenuLockOnTarget(pl, ent)
	if ent and ent:IsValid() and ent:IsPlayer() and ent:Team() ~= TEAM_UNDEAD and ent:Alive() then
		local startpos = pl:EyePos()
		local endpos = ent:NearestPoint(startpos)
		if startpos:Distance(endpos) <= 48 and TrueVisible(startpos, endpos) then
			return true
		end
	end

	return false
end

function GM:GetHandsModel(pl)
	return player_manager.TranslatePlayerHands(pl:GetInfo("cl_playermodel"))
end

local playerheight = Vector(0, 0, 72)
local playermins = Vector(-17, -17, 0)
local playermaxs = Vector(17, 17, 4)
local SkewedDistance = util.SkewedDistance

GM.DynamicSpawnDistVisOld = 2048
GM.DynamicSpawnDistOld = 640
function GM:DynamicSpawnIsValidOld(zombie, humans, allplayers)
	-- I didn't make this check where trigger_hurt entities are. Rather I made it check the time since the last time you were hit with a trigger_hurt.
	-- I'm not sure if it's possible to check if a trigger_hurt is enabled or disabled through the Lua bindings.
	if SERVER and zombie.LastHitWithTriggerHurt and CurTime() < zombie.LastHitWithTriggerHurt + 2 then
		return false
	end

	-- Optional caching for these.
	if not humans then humans = team.GetPlayers(TEAM_HUMAN) end
	if not allplayers then allplayers = player.GetAll() end

	local pos = zombie:GetPos() + Vector(0, 0, 1)
	if zombie:Alive() and zombie:GetMoveType() == MOVETYPE_WALK and zombie:OnGround()
	and not util.TraceHull({start = pos, endpos = pos + playerheight, mins = playermins, maxs = playermaxs, mask = MASK_SOLID, filter = allplayers}).Hit then
		local vtr = util.TraceHull({start = pos, endpos = pos - playerheight, mins = playermins, maxs = playermaxs, mask = MASK_SOLID_BRUSHONLY})
		if not vtr.HitSky and not vtr.HitNoDraw then
			local valid = true

			for _, human in pairs(humans) do
				local hpos = human:GetPos()
				local nearest = zombie:NearestPoint(hpos)
				local dist = SkewedDistance(hpos, nearest, 2.75) -- We make it so that the Z distance between a human and a zombie is skewed if the zombie is below the human.
				if dist <= self.DynamicSpawnDistOld or dist <= self.DynamicSpawnDistVisOld and WorldVisible(hpos, nearest) then -- Zombies can't be in radius of any humans. Zombies can't be clearly visible by any humans.
					valid = false
					break
				end
			end

			return valid
		end
	end

	return false
end

function GM:GetBestDynamicSpawnOld(pl, pos)
	local spawns = self:GetDynamicSpawnsOld(pl)
	if #spawns == 0 then return end

	return self:GetClosestSpawnPoint(spawns, pos or self:GetTeamEpicentre(TEAM_HUMAN)) or table.Random(spawns)
end

function GM:GetDynamicSpawnsOld(pl)
	local tab = {}

	local allplayers = player.GetAll()
	local humans = team.GetPlayers(TEAM_HUMAN)
	for _, zombie in pairs(team.GetPlayers(TEAM_UNDEAD)) do
		if zombie ~= pl and self:DynamicSpawnIsValidOld(zombie, humans, allplayers) then
			table.insert(tab, zombie)
		end
	end

	return tab
end

GM.DynamicSpawnDist = 400
GM.DynamicSpawnDistBuild = 650
function GM:DynamicSpawnIsValid(nest, humans, allplayers)
	if self:ShouldUseAlternateDynamicSpawn() then
		return self:DynamicSpawnIsValidOld(nest, humans, allplayers)
	end

	-- Optional caching for these.
	if not humans then humans = team.GetPlayers(TEAM_HUMAN) end
	--if not allplayers then allplayers = player.GetAll() end

	local pos = nest:GetPos() + Vector(0, 0, 1)
	if nest.GetNestBuilt and nest:GetNestBuilt() and not util.TraceHull({start = pos, endpos = pos + playerheight, mins = playermins, maxs = playermaxs, mask = MASK_SOLID_BRUSHONLY}).Hit then
		local vtr = util.TraceHull({start = pos, endpos = pos - playerheight, mins = playermins, maxs = playermaxs, mask = MASK_SOLID_BRUSHONLY})
		if not vtr.HitSky and not vtr.HitNoDraw then
			local valid = true
			local nearest = nest:GetPos()

			for _, human in pairs(humans) do
				local hpos = human:GetPos()
				local dist = SkewedDistance(hpos, nearest, 2.75) -- We make it so that the Z distance between a human and a nest is skewed if the nest is below the human.
				if dist <= self.DynamicSpawnDist then
					valid = false
					break
				end
			end

			return valid
		end
	end

	return false
end

function GM:GetBestDynamicSpawn(pl, pos)
	if self:ShouldUseAlternateDynamicSpawn() then
		return self:GetBestDynamicSpawnOld(pl, pos)
	end

	local spawns = self:GetDynamicSpawns(pl)
	if #spawns == 0 then return end

	return self:GetClosestSpawnPoint(spawns, pos or self:GetTeamEpicentre(TEAM_HUMAN)) or table.Random(spawns)
end

function GM:GetDynamicSpawns(pl)
	if self:ShouldUseAlternateDynamicSpawn() then
		return self:GetDynamicSpawnsOld(pl)
	end

	local tab = {}

	--local allplayers = player.GetAll()
	local humans = team.GetPlayers(TEAM_HUMAN)
	for _, nest in pairs(ents.FindByClass("prop_creepernest")) do
		if self:DynamicSpawnIsValid(nest, humans--[[, allplayers]]) then
			table.insert(tab, nest)
		end
	end

	return tab
end

function GM:GetDesiredStartingZombies()
	local numplayers = #player.GetAll()
	return math.min(math.max(1, math.ceil(numplayers * self.WaveOneZombies)), numplayers - 1)
end

function GM:GetEndRound()
	return self.RoundEnded
end

function GM:PrecacheResources()
	util.PrecacheSound("physics/body/body_medium_break2.wav")
	util.PrecacheSound("physics/body/body_medium_break3.wav")
	util.PrecacheSound("physics/body/body_medium_break4.wav")
	for name, mdl in pairs(player_manager.AllValidModels()) do
		util.PrecacheModel(mdl)
	end
end

function GM:ShouldCollide(enta, entb)
	if enta.ShouldNotCollide and enta:ShouldNotCollide(entb) or entb.ShouldNotCollide and entb:ShouldNotCollide(enta) then
		return false
	end

	return true
end

function GM:Move(pl, move)
local M_Entity = FindMetaTable("Entity")
local E_GetDTBool = M_Entity.GetDTBool
	if pl:Team() ~= TEAM_UNDEAD then
		if pl:GetBarricadeGhosting() and not E_GetDTBool(pl, 1) then
			move:SetMaxSpeed(36)
			move:SetMaxClientSpeed(36)
		elseif move:GetForwardSpeed() < 0 then
			move:SetMaxSpeed(move:GetMaxSpeed() * 0.5)
			move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.5)
		elseif move:GetForwardSpeed() == 0 then
			move:SetMaxSpeed(move:GetMaxSpeed() * 0.85)
			move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.85)
		end
	elseif pl:CallZombieFunction("Move", move) then
		return
	end
	
	if pl:Team() ~= TEAM_UNDEAD then
		if pl:GetBarricadeGhosting() and pl.GhostCade and not E_GetDTBool(pl, 1) then
			move:SetMaxSpeed(80)
			move:SetMaxClientSpeed(80)
		elseif move:GetForwardSpeed() < 0 then
			move:SetMaxSpeed(move:GetMaxSpeed() * 0.5)
			move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.5)
		elseif move:GetForwardSpeed() == 0 then
			move:SetMaxSpeed(move:GetMaxSpeed() * 0.85)
			move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.85)
		end
	elseif pl:CallZombieFunction("Move", move) then
		return
	end

	local legdamage = pl:GetLegDamage()
	if legdamage > 0 then
		local scale = 1 - math.min(1, legdamage * 0.33)
		move:SetMaxSpeed(move:GetMaxSpeed() * scale)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * scale)
	end
end


function GM:OnPlayerHitGround(pl, inwater, hitfloater, speed)
	if GAMEMODE.ZombieEscape then return true end
	if inwater then return true end

	local isundead = pl:Team() == TEAM_UNDEAD

	if isundead then
		if pl:GetZombieClassTable().NoFallDamage then return true end
	elseif SERVER then
		pl:PreventSkyCade()
	end

	if isundead then
		speed = math.max(0, speed - 200)
	end

	local damage = (0.1 * (speed - 525)) ^ 1.45
	if hitfloater then damage = damage / 2 end

	if math.floor(damage) > 0 then
		if damage >= 5 and (not isundead or not pl:GetZombieClassTable().NoFallSlowdown) then
			pl:RawCapLegDamage(CurTime() + math.min(2, damage * 0.038))
		end

		if SERVER then
			if damage >= 30 and damage < pl:Health() then
				pl:KnockDown(damage * 0.05)
			end
			pl:TakeSpecialDamage(damage, DMG_FALL, game.GetWorld(), game.GetWorld(), pl:GetPos())
			pl:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and 3 or 1)..".wav")
		end
	end

	return true
end

function GM:PlayerCanBeHealed(pl)
	local maxhp = pl:GetMaxHealth()

	return pl:Health() < maxhp or pl:GetPoisonDamage() > 0 or pl:GetBleedDamage() > 0
end

function GM:PlayerCanPurchase(pl)
	return pl:Team() ~= TEAM_UNDEAD and self:GetWave() > 0 and pl:Alive() and pl:NearArsenalCrate()
end

function GM:ZombieCanPurchase(pl)
	return pl:Team() == TEAM_UNDEAD and self:GetWave() > 0
end

local TEAM_SPECTATOR = TEAM_SPECTATOR
function GM:PlayerCanHearPlayersVoice(listener, talker)
	return listener:IsValid() and talker:IsValid() and listener:Team() == talker:Team() or listener:Team() == TEAM_SPECTATOR
	--[[if self:GetEndRound() then return true, false end

	if listener:Team() == talker:Team() then
		return true, listener:GetPos():DistanceZSkew(talker:GetPos(), 2) <= 128
	end

	return false]]
end

function GM:PlayerTraceAttack(pl, dmginfo, dir, trace)
end

function GM:ScalePlayerDamage(pl, hitgroup, dmginfo)
	if hitgroup == HITGROUP_HEAD and dmginfo:IsBulletDamage() then
		pl.m_LastHeadShot = CurTime()
	end

	if not pl:CallZombieFunction("ScalePlayerDamage", hitgroup, dmginfo) then
		if hitgroup == HITGROUP_HEAD then
			dmginfo:SetDamage(dmginfo:GetDamage() * 2)
		elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_GEAR then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.25)
		elseif hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.75)
		end
	end

	if SERVER and (hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG) and self:PlayerShouldTakeDamage(pl, dmginfo:GetAttacker()) then
		pl:AddLegDamage(dmginfo:GetDamage())
	end
end

function GM:CanDamageNail(ent, attacker, inflictor, damage, dmginfo)
	return not attacker:IsPlayer() or attacker:Team() == TEAM_UNDEAD
end

function GM:CanPlaceNail(pl, tr)
	return true
end

function GM:CanRemoveNail(pl, nail)
	if nail.m_NailUnremovable then
		return false
	else
		return true
	end
end

function GM:GetDamageResistance(fearpower)
	return fearpower * 0.35
end

function GM:FindUseEntity(pl, ent)
	if not ent:IsValid() then
		local e = pl:TraceLine(90, MASK_SOLID, pl:GetDynamicTraceFilter()).Entity
		if e:IsValid() then return e end
	end

	return ent
end

function GM:ShouldUseAlternateDynamicSpawn()
	return self.ZombieEscape or self:IsClassicMode() or self.PantsMode or self:IsBabyMode()
end

function GM:GetZombieDamageScale(pos, ignore)
	if LASTHUMAN then return self.ZombieDamageMultiplier end

	return self.ZombieDamageMultiplier * (1 - self:GetDamageResistance(self:GetFearMeterPower(pos, TEAM_UNDEAD, ignore)))
end

local temppos
local function SortByDistance(a, b)
	return a:GetPos():DistToSqr(temppos) < b:GetPos():DistToSqr(temppos)
end

local function GetSortedSpawnPoints(teamid, pos)
	temppos = pos
	local spawnpoints
	if type(teamid) == "table" then
		spawnpoints = teamid
	else
		spawnpoints = team.GetValidSpawnPoint(teamid)
	end

	table.sort(spawnpoints, SortByDistance)
	return spawnpoints
end

function GM:GetClosestSpawnPoint(teamid, pos)
	return GetSortedSpawnPoints(teamid, pos)[1]
end

function GM:GetFurthestSpawnPoint(teamid, pos)
	local spawnpoints = GetSortedSpawnPoints(teamid, pos)
	return spawnpoints[#spawnpoints]
end

local FEAR_RANGE = 768
local FEAR_PERINSTANCE = 0.075
local RALLYPOINT_THRESHOLD = 0.3

local function GetEpicenter(tab)
	local vec = Vector(0, 0, 0)
	if #tab == 0 then return vec end

	for k, v in pairs(tab) do
		vec = vec + v:GetPos()
	end

	return vec / #tab
end

function GM:GetTeamRallyGroups(teamid)
	local groups = {}
	local ingroup = {}

	local plys = team.GetPlayers(teamid)

	for _, pl in pairs(plys) do
		if not ingroup[pl] and pl:Alive() then
			local plpos = pl:GetPos()
			local group = {pl}

			for __, otherpl in pairs(plys) do
				if otherpl ~= pl and not ingroup[otherpl] and otherpl:Alive() and otherpl:GetPos():Distance(plpos) <= FEAR_RANGE then
					group[#group + 1] = otherpl
				end
			end

			if #group * FEAR_PERINSTANCE >= RALLYPOINT_THRESHOLD then
				for k, v in pairs(group) do
					ingroup[v] = true
				end
				groups[#groups + 1] = group
			end
		end
	end

	return groups
end

function GM:GetTeamRallyPoints(teamid)
	local points = {}

	for _, group in pairs(self:GetTeamRallyGroups(teamid)) do
		points[#points + 1] = {GetEpicenter(group), math.min(1, (#group * FEAR_PERINSTANCE - RALLYPOINT_THRESHOLD) / (1 - RALLYPOINT_THRESHOLD))}
	end

	return points
end

local CachedEpicentreTimes = {}
local CachedEpicentres = {}
function GM:GetTeamEpicentre(teamid, nocache)
	if not nocache and CachedEpicentres[teamid] and CurTime() < CachedEpicentreTimes[teamid] then
		return CachedEpicentres[teamid]
	end

	local plys = team.GetPlayers(teamid)
	local vVec = Vector(0, 0, 0)
	for _, pl in pairs(plys) do
		if pl:Alive() then
			vVec = vVec + pl:GetPos()
		end
	end

	local epicentre = vVec / #plys
	if not nocache then
		CachedEpicentreTimes[teamid] = CurTime() + 0.5
		CachedEpicentres[teamid] = epicentre
	end

	return epicentre
end
GM.GetTeamEpicenter = GM.GetTeamEpicentre

function GM:GetCurrentEquipmentCount(id)
	local count = 0

	local item = self.Items[id]
	if item then
		if item.Countables then
			if type(item.Countables) == "table" then
				for k, v in pairs(item.Countables) do
					count = count + #ents.FindByClass(v)
				end
			else
				count = count + #ents.FindByClass(item.Countables)
			end
		end

		if item.SWEP then
			count = count + #ents.FindByClass(item.SWEP)
		end
	end

	return count
end

function GM:GetFearMeterPower(pos, teamid, ignore)
	if LASTHUMAN then return 1 end

	local power = 0

	for _, pl in pairs(player.GetAll()) do
		if pl ~= ignore and pl:Team() == teamid and not pl:CallZombieFunction("DoesntGiveFear") and pl:Alive() then
			local dist = pl:NearestPoint(pos):Distance(pos)
			if dist <= FEAR_RANGE then
				power = power + ((FEAR_RANGE - dist) / FEAR_RANGE) * (pl:GetZombieClassTable().FearPerInstance or FEAR_PERINSTANCE)
			end
		end
	end

	return math.min(1, power)
end

function GM:GetRagdollEyes(pl)
	local Ragdoll = pl:GetRagdollEntity()
	if not IsValid(Ragdoll) then return end

	local attachmentnum = Ragdoll:LookupAttachment("eyes")
	if attachmentnum == nil then return end
	
	local att = Ragdoll:GetAttachment(attachmentnum)
	if att then
		att.Pos = att.Pos + att.Ang:Forward() * -2
		att.Ang = att.Ang

		return att.Pos, att.Ang
	end
end

function GM:PlayerNoClip(pl, on)
	if pl:IsAdmin() then
		if SERVER then
			PrintMessage(HUD_PRINTCONSOLE, translate.Format(on and "x_turned_on_noclip" or "x_turned_off_noclip", pl:Name()))
		end

		if SERVER then
			pl:MarkAsBadProfile()
		end

		return true
	end

	return false
end

function GM:GetWaveEnd()
	return GetGlobalFloat("waveend", 0)
end

function GM:SetWaveEnd(wave)
	SetGlobalFloat("waveend", wave)
end

function GM:GetWaveStart()
	return GetGlobalFloat("wavestart", self.WaveZeroLength)
end

function GM:SetWaveStart(wave)
	SetGlobalFloat("wavestart", wave)
end

function GM:GetWave()
	return GetGlobalInt("wave", 0)
end

if GM:GetWave() == 0 then
	GM:SetWaveStart(GM.WaveZeroLength)
	GM:SetWaveEnd(GM.WaveZeroLength + GM:GetWaveOneLength())
end

function GM:GetWaveActive()
	return GetGlobalBool("waveactive", false)
end

function GM:SetWaveActive(active)
	if self.RoundEnded then return end

	if self:GetWaveActive() ~= active then
		SetGlobalBool("waveactive", active)

		if SERVER then
			gamemode.Call("WaveStateChanged", active)
		end
	end
end

if not FixedSoundDuration then
FixedSoundDuration = true
local OldSoundDuration = SoundDuration
function SoundDuration(snd)
	if snd then
		local ft = string.sub(snd, -4)
		if ft == ".mp3" then
			return OldSoundDuration(snd) * 2.25
		end
		if ft == ".ogg" then
			return OldSoundDuration(snd) * 3
		end
	end

	return OldSoundDuration(snd)
end
end

function GM:VehicleMove()
end

function GM:PlayerEnteredVehicle(ply, veh, role)
end

function GM:CanPlayerEnterVehicle(player, vehicle, sRole)
end

function GM:CanExitVehicle(veh, ply)
end