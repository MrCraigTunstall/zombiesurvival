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
include("shared/sh_players.lua")
include("shared/sh_entityregistry.lua")
include("shared/sh_mapoverrides.lua")
include("shared/sh_collisions.lua")
include("shared/sh_notifications.lua")
include("shared/sh_keybinds.lua")
include("shared/sh_propcreator.lua")
include("shared/sh_progression.lua")
include("shared/sh_crafts.lua")
include("shared/sh_util.lua")
include("shared/sigilmaps.lua")
include("shared/sh_options.lua")
include("shared/sh_returns.lua")
include("shared/sh_traits.lua")
include("shared/sh_parkour.lua")
include("shared/sh_useentity.lua")
include("shared/sh_blastdamage.lua")
include("shared/sh_arsenalshop.lua")
include("shared/sh_worthshop.lua")
include("shared/sh_trader.lua")
include("shared/sh_quests.lua")
include("shared/sh_guilds.lua")
include("shared/sh_cosmetics.lua")
include("shared/sh_lasthumanmusic.lua")
include("shared/sh_mutationshop.lua")
include("shared/sh_cataloguetranslations.lua")
include("shared/sh_mutationcatalogue.lua")
include("shared/sh_fastzombieanimations.lua")
include("shared/sh_zombieclasses.lua")
include("shared/sh_bosses.lua")
include("shared/sh_animations.lua")
include("shared/sh_sigils.lua")
include("shared/sh_channel.lua")
include("shared/sh_bullets.lua")
include("shared/sh_scoreboardtags.lua")
include("shared/sh_weaponquality.lua")
include("shared/sh_weaponforge.lua")

include("misc/noxapi/noxapi.lua")

include("meta/obj_vector_extend.lua")
include("shared/sh_barricadeghosting.lua")
include("meta/obj_entity_extend.lua")
include("shared/sh_luabullets.lua")
include("shared/sh_ricochet.lua")
include("meta/obj_player_extend.lua")
include("shared/sh_playertraces.lua")
include("shared/sh_playercamera.lua")
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
	game.AddAmmoType({name = "repairemitter"})

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

function GM:FixWeaponBase()
end

function GM:IsWeaponUnlocked(tab)
	if type(tab) ~= "table" then return false end
	if self.WeaponTiersEnabled and not self:WeaponTiersEnabled() then return true end
	local wave = self:GetWave()
	if wave <= -1 then return true end
	local waves = self:GetNumberOfWaves()
	if waves <= -1 then return true end
	if type(tab) ~= "table" then return false end
	if tab.Unlocked then return tab.Unlocked end
	local required = tab.Wave
	return type(required) == "number" and required == required and required > -math.huge and required < math.huge and wave >= math.floor(required * waves)
end

include("shared/sh_barricades.lua")

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
	if self.TimeLimit == 0 or self.RoundLimit == 0 then return false end

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
	local positions

	for _, pl in pairs(allplayers) do
		if pl:Team() == TEAM_UNDEAD or pl:GetInfo("zs_alwaysvolunteer") == "1" then
			pl._ZombieSpawnDistance = -1
		elseif CLIENT or pl:IsBot() or pl.LastNotAFK and curtime <= pl.LastNotAFK + 60 then
			local plpos = pl:GetPos()
			if not positions then
				positions = {}
				for _, ent in pairs(zspawns) do
					if IsValid(ent) and not ent:IsMarkedForDeletion() then positions[#positions + 1] = ent:GetPos() end
				end
			end
			local closest = math.huge
			for _, position in ipairs(positions) do
				local dist = position:DistToSqr(plpos)
				if dist < closest then
					closest = dist
				end
			end
			pl._ZombieSpawnDistance = closest
		else
			pl._ZombieSpawnDistance = math.huge
		end
	end

	table.sort(allplayers, self.ZombieSpawnDistanceSort)
end

function GM:ValidMenuLockOnTarget(pl, ent)
	if IsValid(pl) and IsValid(ent) and ent:IsPlayer() and ent:Team() ~= TEAM_UNDEAD and ent:Alive() then
		local startpos = pl:EyePos()
		local endpos = ent:NearestPoint(startpos)
		if startpos:DistToSqr(endpos) <= 2304 and TrueVisible(startpos, endpos) then
			return true
		end
	end

	return false
end

function GM:GetHandsModel(pl)
	return player_manager.TranslatePlayerHands(pl:GetInfo("cl_playermodel"))
end

include("shared/sh_dynamicspawns.lua")

function GM:GetDesiredStartingZombies()
	local numplayers = player.GetCount()
	if numplayers <= 1 then return 0 end
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


function GM:Move(pl, move)

	if pl:Team() ~= TEAM_UNDEAD then
		if self:MoveTraitParkour(pl, move) then return true end
		local ghostspeed = self:GetBarricadeGhostSpeed(pl)
		if ghostspeed then
			move:SetMaxSpeed(ghostspeed)
			move:SetMaxClientSpeed(ghostspeed)
		else
			local forward = move:GetForwardSpeed()
			if forward < 0 then
				move:SetMaxSpeed(move:GetMaxSpeed() * 0.5)
				move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.5)
			elseif forward == 0 then
				move:SetMaxSpeed(move:GetMaxSpeed() * 0.85)
				move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.85)
			end
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
	local class

	if isundead then
		class = pl:GetZombieClassTable()
		if class.NoFallDamage then return true end
	elseif SERVER then
		pl:PreventSkyCade()
	end

	if isundead then
		speed = math.max(0, speed - 200)
	end
	if speed <= 525 then return true end

	local damage = (0.1 * (speed - 525)) ^ 1.45
	if hitfloater then damage = damage / 2 end

	if math.floor(damage) > 0 then
		if damage >= 5 and (not isundead or not class.NoFallSlowdown) then
			pl:RawCapLegDamage(CurTime() + math.min(2, damage * 0.038))
		end

		if SERVER then
			if damage >= 30 and damage < pl:Health() then
				pl:KnockDown(damage * 0.05)
			end
			local world = game.GetWorld()
			pl:TakeSpecialDamage(damage, DMG_FALL, world, world, pl:GetPos())
			pl:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and 3 or 1)..".wav")
		end
	end

	return true
end

function GM:PlayerCanBeHealed(pl)
	local maxhp = pl:GetMaxHealth()

	return pl:Health() < maxhp or pl:GetPoisonDamage() > 0 or pl:GetBleedDamage() > 0
end

function GM:PlayerCanPurchase(pl, crate)
	return pl:Team() == TEAM_HUMAN and self:GetWave() > 0 and pl:Alive() and (IsValid(crate) or pl:NearArsenalCrate())
end

local TEAM_SPECTATOR = TEAM_SPECTATOR
function GM:PlayerCanHearPlayersVoice(listener, talker)
	if not IsValid(listener) or not IsValid(talker) then return false end
	local team = listener:Team()
	return team == TEAM_SPECTATOR or team == talker:Team()
	--[[if self:GetEndRound() then return true, false end

	if listener:Team() == talker:Team() then
		return true, listener:GetPos():DistanceZSkew(talker:GetPos(), 2) <= 128
	end

	return false]]
end

function GM:PlayerTraceAttack(pl, dmginfo, dir, trace)
end

function GM:ScalePlayerDamage(pl, hitgroup, dmginfo)
	if SERVER then self:ApplyTraitHeadshot(pl, hitgroup, dmginfo) end
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




function GM:GetDamageResistance(fearpower)
	return fearpower * 0.35
end

function GM:ShouldUseAlternateDynamicSpawn()
	return self.ZombieEscape or self:IsClassicMode() or self.PantsMode or self:IsBabyMode()
end

function GM:GetZombieDamageScale(pos, ignore)
	if LASTHUMAN then return self.ZombieDamageMultiplier end

	return self.ZombieDamageMultiplier * (1 - self:GetDamageResistance(self:GetFearMeterPower(pos, TEAM_UNDEAD, ignore)))
end

local function FindSpawnPoint(teamid, pos, furthest)
	local spawnpoints = type(teamid) == "table" and teamid or team.GetValidSpawnPoint(teamid)
	local selected, bestdistance
	for _, spawn in ipairs(spawnpoints) do
		if IsValid(spawn) and not spawn:IsMarkedForDeletion() then
			local distance = spawn:GetPos():DistToSqr(pos)
			if not bestdistance or (furthest and distance > bestdistance) or (not furthest and distance < bestdistance) then
				selected, bestdistance = spawn, distance
			end
		end
	end
	return selected
end

function GM:GetClosestSpawnPoint(teamid, pos)
	return FindSpawnPoint(teamid, pos, false)
end

function GM:GetFurthestSpawnPoint(teamid, pos)
	return FindSpawnPoint(teamid, pos, true)
end

include("shared/sh_fear.lua")

local function CountEquipmentClass(gm, class)
	return gm:GetZSClassCount(class)
end

function GM:GetCurrentEquipmentCount(id)
	local count = 0

	local item = self.Items[id]
	if item then
		if item.Countables then
			if type(item.Countables) == "table" then
				for k, v in pairs(item.Countables) do
					count = count + CountEquipmentClass(self, v)
				end
			else
				count = count + CountEquipmentClass(self, item.Countables)
			end
		end

		if item.SWEP then
			count = count + CountEquipmentClass(self, item.SWEP)
		end
	end

	return count
end

function GM:GetRagdollEyes(pl)
	if not IsValid(pl) then return end
	local Ragdoll = pl:GetRagdollEntity()
	if not IsValid(Ragdoll) then return end

	local attachmentnum = Ragdoll:LookupAttachment("eyes")
	if not attachmentnum or attachmentnum <= 0 then return end
	
	local att = Ragdoll:GetAttachment(attachmentnum)
	if att then
		return att.Pos + att.Ang:Forward() * -2, att.Ang
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

function GM:VehicleMove()
end

function GM:PlayerEnteredVehicle(ply, veh, role)
end

function GM:CanPlayerEnterVehicle(player, vehicle, sRole)
end

function GM:CanExitVehicle(veh, ply)
end
