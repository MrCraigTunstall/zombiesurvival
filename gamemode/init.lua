--[[
Zombie Survival
by William "JetBoom" Moodhe
williammoodhe@gmail.com -or- jetboom@noxiousnet.com
http://www.noxiousnet.com/
Further credits displayed by pressing F1 in-game.
This was my first ever gamemode. A lot of stuff is from years ago and some stuff is very recent.
]]--

-- TODO: player introduced to a "main menu" sort of thing. auto joins as spectator. Requires recoding of a lot of logic because right now we assume only two possible teams and no spectator for humans.

--[[
////////// Main Files //////////
]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("client/cl_fonts.lua")
AddCSLuaFile("client/cl_hudstyle.lua")
AddCSLuaFile("client/cl_chat.lua")
AddCSLuaFile("client/cl_hudlayout.lua")
AddCSLuaFile("client/cl_targetplacement.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("client/cl_traitcorpses.lua")
AddCSLuaFile("client/cl_traitdrunk.lua")
AddCSLuaFile("client/cl_traitdrone.lua")
AddCSLuaFile("client/cl_traitsnarks.lua")
AddCSLuaFile("client/cl_traitbarnaclerender.lua")
AddCSLuaFile("shared/sh_ricochet.lua")
AddCSLuaFile("client/cl_weaponanimation.lua")
AddCSLuaFile("client/cl_playeranimation.lua")
AddCSLuaFile("client/cl_flashlight.lua")
AddCSLuaFile("client/cl_view.lua")
AddCSLuaFile("client/cl_propinput.lua")
AddCSLuaFile("client/cl_barricadeghosting.lua")
AddCSLuaFile("client/cl_playervoice.lua")

--[[
////////// Shared Files //////////
]]--

AddCSLuaFile("sh_translate.lua")
AddCSLuaFile("shared/sh_colors.lua")
AddCSLuaFile("sh_serialization.lua")
AddCSLuaFile("shared/sh_globals.lua")
AddCSLuaFile("shared/sh_players.lua")
AddCSLuaFile("shared/sh_playertraces.lua")
AddCSLuaFile("shared/sh_playercamera.lua")
AddCSLuaFile("shared/sh_footsteps.lua")
AddCSLuaFile("shared/sh_fear.lua")
AddCSLuaFile("shared/sh_dynamicspawns.lua")
AddCSLuaFile("shared/sh_entityregistry.lua")
AddCSLuaFile("shared/sh_mapoverrides.lua")
AddCSLuaFile("shared/sh_collisions.lua")
AddCSLuaFile("shared/sh_barricadeghosting.lua")
AddCSLuaFile("shared/sh_barricades.lua")
AddCSLuaFile("shared/sh_notifications.lua")
AddCSLuaFile("shared/sh_keybinds.lua")
AddCSLuaFile("shared/sh_propcreator.lua")
AddCSLuaFile("shared/sh_progression.lua")
AddCSLuaFile("shared/sh_crafts.lua")
AddCSLuaFile("shared/sh_util.lua")
AddCSLuaFile("shared/sh_mutationshop.lua")
AddCSLuaFile("shared/sh_mutationcatalogue.lua")
AddCSLuaFile("shared/sh_options.lua")
AddCSLuaFile("shared/sh_itemcatalogue.lua")
AddCSLuaFile("shared/sh_returns.lua")
AddCSLuaFile("shared/sh_traits.lua")
AddCSLuaFile("shared/sh_parkour.lua")
AddCSLuaFile("shared/sh_useentity.lua")
AddCSLuaFile("shared/sh_luabullets.lua")
AddCSLuaFile("shared/sh_blastdamage.lua")
AddCSLuaFile("shared/sh_arsenalshop.lua")
AddCSLuaFile("shared/sh_worthshop.lua")
AddCSLuaFile("client/cl_returns.lua")
AddCSLuaFile("shared/sh_trader.lua")
AddCSLuaFile("shared/sh_quests.lua")
AddCSLuaFile("shared/sh_guilds.lua")
AddCSLuaFile("shared/sh_cosmetics.lua")
AddCSLuaFile("client/cl_cosmetics.lua")
AddCSLuaFile("client/vgui/pcosmeticshop.lua")
AddCSLuaFile("client/cl_guilds.lua")
AddCSLuaFile("client/cl_quests.lua")
AddCSLuaFile("shared/sh_lasthumanmusic.lua")
AddCSLuaFile("client/cl_beats.lua")
AddCSLuaFile("client/cl_trader.lua")
AddCSLuaFile("shared/sh_zombieclasses.lua")
AddCSLuaFile("shared/sh_bosses.lua")
AddCSLuaFile("shared/sh_fastzombieanimations.lua")
AddCSLuaFile("shared/sh_animations.lua")
AddCSLuaFile("shared/sh_sigils.lua")
AddCSLuaFile("shared/sh_channel.lua")
AddCSLuaFile("shared/sh_bullets.lua")
AddCSLuaFile("shared/sh_scoreboardtags.lua")
AddCSLuaFile("shared/sigilmaps.lua")
AddCSLuaFile("shared/sh_weaponquality.lua")
AddCSLuaFile("shared/sh_weaponforge.lua")

--[[
////////// Client Files //////////
]]--

AddCSLuaFile("client/cl_draw.lua")
AddCSLuaFile("client/cl_util.lua")
AddCSLuaFile("client/cl_options.lua")
AddCSLuaFile("client/cl_scoreboard.lua")
AddCSLuaFile("client/cl_targetid.lua")
AddCSLuaFile("client/cl_postprocess.lua")
AddCSLuaFile("client/cl_deathnotice.lua")
AddCSLuaFile("client/cl_floatingscore.lua")
AddCSLuaFile("client/cl_dermaskin.lua")
AddCSLuaFile("client/cl_hint.lua")
AddCSLuaFile("client/cl_extras.lua")
AddCSLuaFile("client/cl_network.lua")

--[[
////////// VGUI Files //////////
]]--

AddCSLuaFile("client/vgui/dgamestate.lua")
AddCSLuaFile("client/vgui/dteamcounter.lua")
AddCSLuaFile("client/vgui/dmodelpanelex.lua")
AddCSLuaFile("client/vgui/dammocounter.lua")
AddCSLuaFile("client/vgui/dpingmeter.lua")
AddCSLuaFile("client/vgui/dteamheading.lua")
AddCSLuaFile("client/vgui/dsidemenu.lua")
AddCSLuaFile("client/cl_humanmenu.lua")
AddCSLuaFile("client/vgui/dmodelkillicon.lua")
AddCSLuaFile("client/vgui/dexroundedpanel.lua")
AddCSLuaFile("client/vgui/dexroundedframe.lua")
AddCSLuaFile("client/vgui/dexrotatedimage.lua")
AddCSLuaFile("client/vgui/dexnotificationslist.lua")
AddCSLuaFile("client/vgui/dexchanginglabel.lua")
AddCSLuaFile("client/vgui/mainmenu.lua")
AddCSLuaFile("client/vgui/optionscolormixer.lua")
AddCSLuaFile("client/vgui/poptions.lua")
AddCSLuaFile("client/vgui/pclassselect.lua")
AddCSLuaFile("client/vgui/pweapons.lua")
AddCSLuaFile("client/vgui/pendboard.lua")
AddCSLuaFile("client/cl_shopcatalogue.lua")
AddCSLuaFile("client/cl_classselect.lua")
AddCSLuaFile("client/cl_shopui.lua")
AddCSLuaFile("client/cl_notificationdetails.lua")
AddCSLuaFile("client/cl_voice.lua")
AddCSLuaFile("client/cl_weaponselect.lua")
AddCSLuaFile("client/cl_taunt.lua")
AddCSLuaFile("client/cl_tauntactivities.lua")
AddCSLuaFile("client/cl_weaponinventory.lua")
AddCSLuaFile("client/cl_hudstriplayout.lua")
AddCSLuaFile("client/cl_voice_registry.lua")
AddCSLuaFile("client/vgui/dshoptooltip.lua")
AddCSLuaFile("client/cl_mainmenu.lua")
AddCSLuaFile("client/cl_spectators.lua")
AddCSLuaFile("client/cl_playercolors.lua")
AddCSLuaFile("client/cl_playermodels.lua")
AddCSLuaFile("client/cl_help.lua")
AddCSLuaFile("client/cl_credits.lua")
AddCSLuaFile("client/cl_worthcart.lua")
AddCSLuaFile("client/cl_worthloadouts.lua")
AddCSLuaFile("client/vgui/dequipmentcounter.lua")
AddCSLuaFile("client/vgui/pworth.lua")
AddCSLuaFile("client/vgui/ppointshop.lua")
AddCSLuaFile("client/vgui/pmutationshop.lua")
AddCSLuaFile("client/cl_mutationshop.lua")
AddCSLuaFile("client/cl_redeemmenu.lua")
AddCSLuaFile("client/cl_beaconmenu.lua")
AddCSLuaFile("client/vgui/zshealtharea.lua")
AddCSLuaFile("client/cl_shadehud.lua")
AddCSLuaFile("client/cl_healthhud.lua")
AddCSLuaFile("client/cl_fearhud.lua")
AddCSLuaFile("client/cl_medicalaura.lua")
AddCSLuaFile("client/cl_roundendhud.lua")
AddCSLuaFile("shared/sh_cataloguetranslations.lua")
AddCSLuaFile("client/cl_packuphud.lua")
AddCSLuaFile("client/cl_teleporthud.lua")
AddCSLuaFile("client/cl_breathhud.lua")
AddCSLuaFile("client/cl_preparationhud.lua")
AddCSLuaFile("client/cl_respawnhud.lua")
AddCSLuaFile("client/cl_purchasehud.lua")
AddCSLuaFile("client/cl_meleecrosshair.lua")
AddCSLuaFile("client/cl_mapvote.lua")
AddCSLuaFile("client/cl_keybinds.lua")
AddCSLuaFile("client/cl_propcreator.lua")
AddCSLuaFile("client/cl_menuactions.lua")
AddCSLuaFile("client/cl_weaponforge.lua")
AddCSLuaFile("client/vgui/pkeybinds.lua")
AddCSLuaFile("zombieescape/cl_weaponselect.lua")

--[[
////////// Meta Files //////////
]]--

AddCSLuaFile("meta/obj_vector_extend.lua")
AddCSLuaFile("meta/obj_player_extend.lua")
AddCSLuaFile("meta/obj_player_extend_cl.lua")
AddCSLuaFile("meta/obj_weapon_extend_cl.lua")
AddCSLuaFile("meta/obj_weapon_extend.lua")
AddCSLuaFile("meta/obj_entity_extend_cl.lua")
AddCSLuaFile("meta/obj_entity_extend.lua")

--[[
////////// Include Files //////////
]]--

include("server/sv_hitboxtraces.lua")
include("shared.lua")
include("server/sv_flashlight.lua")
include("server/sv_shadecontrol.lua")
include("server/sv_options.lua")
include("server/sv_spectators.lua")
include("server/sv_barricades.lua")
include("server/sv_fieldrepair.lua")
include("server/sv_weaponforge.lua")
include("server/sv_mutationshop.lua")
include("server/sv_mutationeffects.lua")
include("server/sv_crafts.lua")
include("server/sv_molotov.lua")
include("meta/obj_entity_extend_sv.lua")
include("server/sv_mapoutputs.lua")
include("server/sv_droppeditems.lua")
include("meta/obj_player_extend_sv.lua")
include("misc/mapeditor.lua")
include("server/sv_playerspawnentities.lua")
include("server/sv_profiling.lua")
include("server/sv_sigilprops.lua")
include("server/sv_sigils.lua")
include("server/sv_mathcounter.lua")
include("server/sv_zombievariants.lua")
include("server/sv_zombieskins.lua")
include("zombieescape/sv_zombieescape.lua")
include("zombieescape/sv_weaponselect.lua")
include("server/sv_downloads.lua")
include("server/sv_redeem.lua")
include("server/sv_combatpoints.lua")
include("server/sv_roundthink.lua")
include("server/sv_barricadeghosting.lua")
include("server/sv_infliction.lua")
include("server/sv_progression.lua")
include("server/sv_worthshop.lua")
include("server/sv_inventorycommands.lua")
include("server/sv_weapontransfer.lua")
include("server/sv_propinput.lua")
include("server/sv_humanpickup.lua")
include("server/sv_survivorplacement.lua")
include("server/sv_trader.lua")
include("server/sv_quests.lua")
include("server/sv_guilds.lua")
include("server/sv_cosmeticshop.lua")
include("server/sv_returns.lua")
include("server/sv_traits.lua")
include("server/sv_traitauras.lua")
include("server/sv_traitprops.lua")
include("server/sv_traitcorpses.lua")
include("server/sv_traitsniper.lua")
include("server/sv_traitdrunk.lua")
include("server/sv_traitdrone.lua")
include("server/sv_npctargetaccess.lua")
include("server/sv_traitbarnacle.lua")
include("server/sv_traitsnarks.lua")
include("server/sv_traitexplosivetouch.lua")
include("server/sv_traitloot.lua")
include("server/sv_arsenalshop.lua")
include("server/sv_roundrestart.lua")
include("server/sv_variantrandomizer.lua")
include("server/sv_bosses.lua")
include("server/sv_spawns.lua")
include("server/sv_notifications.lua")
include("server/sv_nailwarnings.lua")
include("server/sv_mapvote.lua")
include("server/sv_keybinds.lua")
include("server/sv_propcreator.lua")
include("server/sv_catbomb.lua")
--include("server/sv_crashrecover.lua")
include("server/sv_extras.lua")

local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team
local E_meta = FindMetaTable("Entity")
local E_IsValid = E_meta.IsValid

local mapScript = "misc/maps/" .. GM:GetMapScriptName()
if file.Exists(GM.FolderName .. "/gamemode/" .. mapScript .. ".lua", "LUA") then include(mapScript .. ".lua") end
if file.Exists(GM.FolderName .. "/gamemode/" .. mapScript .. "_cl.lua", "LUA") then AddCSLuaFile(mapScript .. "_cl.lua") end

function BroadcastLua(code)
	for _, pl in player.Iterator() do
		if not pl:IsBot() then pl:SendLua(code) end
	end
end

player.GetByUniqueID = player.GetByUniqueID or function(uid)
	for _, pl in player.Iterator() do
		if pl:UniqueID() == uid then return pl end
	end
end

function GM:WorldHint(hint, pos, ent, lifetime, filter)
	net.Start("zs_worldhint")
		net.WriteString(hint)
		net.WriteVector(pos or ent and ent:IsValid() and ent:GetPos() or vector_origin)
		net.WriteEntity(ent or NULL)
		net.WriteFloat(lifetime or 8)
	if filter then
		net.Send(filter)
	else
		net.Broadcast()
	end
end

function GM:CreateGibs(pos, headoffset)
	headoffset = headoffset or 0

	local headpos = Vector(pos.x, pos.y, pos.z + headoffset)
	for i = 1, 2 do
		local ent = ents.CreateLimited("prop_playergib")
		if ent:IsValid() then
			ent:SetPos(headpos + VectorRand() * 5)
			ent:SetAngles(VectorRand():Angle())
			ent:SetGibType(i)
			ent:Spawn()
		end
	end

	for i=1, 4 do
		local ent = ents.CreateLimited("prop_playergib")
		if ent:IsValid() then
			ent:SetPos(pos + VectorRand() * 12)
			ent:SetAngles(VectorRand():Angle())
			ent:SetGibType(math.random(3, #GAMEMODE.HumanGibs))
			ent:Spawn()
		end
	end
end

function GM:Initialize()
	self:RegisterPlayerSpawnEntities()
	self:AddResources()
	self:PrecacheResources()
	self:AddCustomAmmo()
	self:AddNetworkStrings()
	self:LoadProfiler()

	self:SetPantsMode(self.PantsMode, true)
	self:SetClassicMode(self:IsClassicMode(), true)
	self:SetBabyMode(self:IsBabyMode(), true)
	self:SetRedeemBrains(self.DefaultRedeem)

	self:RefreshMapIsObjective()

	game.ConsoleCommand("fire_dmgscale 1\n")
	game.ConsoleCommand("sv_gravity 600\n")
end

include("server/sv_networkstrings.lua")

function GM:IsClassicMode()
	return self.ClassicMode
end

function GM:IsRedeemMode()
	return self.RedeemMode
end

function GM:IsBabyMode()
	return self.BabyMode
end

function GM:CenterNotifyAll(...)
	self:BroadcastNotification("zs_centernotify", {...})
end
GM.CenterNotify = GM.CenterNotifyAll

function GM:TopNotifyAll(...)
	self:BroadcastNotification("zs_topnotify", {...})
end
GM.TopNotify = GM.TopNotifyAll

include("server/sv_menuactions.lua")

function GM:PlayerPointsAdded(pl, amount)
end

function GM:PlayerPointsRemoved(pl, amount)
end

include("server/sv_mapsetup.lua")

function GM:SendZombieVolunteers(pl, nonemptyonly)
	if pl and pl:IsBot() then return end
	if nonemptyonly and #self.ZombieVolunteers == 0 then return end

	net.Start("zs_zvols")
		net.WriteUInt(#self.ZombieVolunteers, 8)
		for _, p in ipairs(self.ZombieVolunteers) do
			net.WriteEntity(p)
		end
	if pl then
		net.Send(pl)
	else
		net.Broadcast()
	end
end

--[[net.Receive("zs_update_playermodel", function(len, pl) -- planned
	local mdl = net.ReadString()
	local ent = pl
	
	if IsValid(ent) and ent:IsPlayer() and ent:Alive() and ent:Team() == TEAM_HUMAN then
		if ent:IsHolding() or ent:GetBarricadeGhosting() then return end
		
		if table.HasValue(GAMEMODE.RestrictedModels, string.lower(mdl)) then return end
		if table.HasValue(GAMEMODE.DonatorModels, string.lower(mdl)) then return end
		
		local model_argument = mdl
		local model_string = player_manager.TranslatePlayerModel(model_argument)

		ent:SetModel(model_string)
		ent:SetupHands()
	end
end)]]--


-- We calculate the volunteers. If the list changed then broadcast the new list.
function GM:CalculateZombieVolunteers()
	local volunteers = {}
	local allplayers = player.GetAllActive()

	self:SortZombieSpawnDistances(allplayers)
	for i = 1, self:GetDesiredStartingZombies() do
		volunteers[i] = allplayers[i]
	end

	local mismatch = false
	if #volunteers ~= #self.ZombieVolunteers then
		mismatch = true
	else
		for i=1, #volunteers do
			if volunteers[i] ~= self.ZombieVolunteers[i] then
				mismatch = true
				break
			end
		end
	end
	if mismatch then
		self.ZombieVolunteers = volunteers
		self:SendZombieVolunteers()
	end
end

function GM:LastBite(victim, attacker)
	LAST_BITE = attacker
end


function GM:OnNPCKilled(ent, attacker, inflictor)
end

function GM:LastHuman(pl)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	if not LASTHUMAN then
		net.Start("zs_lasthuman")
			net.WriteEntity(pl or NULL)
			net.WriteString(self:SelectLastHumanMusic())
		net.Broadcast()

		for _, ent in pairs(self:GetZSClassEntities("logic_infliction")) do
			ent:Input("onlasthuman", pl, pl, pl and pl:IsValid() and pl:EntIndex() or -1)
		end

		if player.GetCount() <= 20 then
		 for k, v in pairs(self.LastHumanWeapons) do
        pl:Give(v)
		end
	end

		if player.GetCount() >= 21 then
		for k, v in pairs(self.LastHumanWeapons2) do
        pl:Give(v)
		end
	end

		LASTHUMAN = true

	end

	self.TheLastHuman = pl
	if self.LastHumanHearAll then
	hook.Add("PlayerCanHearPlayersVoice", "LastHumanCanHearPlayersVoice", function() return true, false end)
	end
end

function GM:ObjectPackedUp(pack, packer, owner)
end

include("server/sv_honorablementions.lua")

include("server/sv_roundlifecycle.lua")

function GM:PlayerReady(pl)
	gamemode.Call("PlayerReadyRound", pl)
end

hook.Add("PlayerReady", "post_discord_link", function(pl)
	if pl:GetInfo("zs_nodiscord") ~= "1" then
	pl:PrintTranslatedMessage(HUD_PRINTTALK, "post_discord_init_text")
	pl:PrintTranslatedMessage(HUD_PRINTTALK, "post_discord_init_text2") 
	end 
end)

function GM:PlayerReadyRound(pl)
	if not pl:IsValid() then return end
	local isbot = pl:IsBot()

	self:FullGameUpdate(pl)
	pl:UpdateAllZombieClasses()

	local classid = pl:GetZombieClass()
	pl:SetZombieClass(classid, true, pl)

	if self.OverrideStartingWorth and not isbot then
		pl:SendLua("GAMEMODE.StartingWorth="..tostring(self.StartingWorth))
	end

	if pl:Team() == TEAM_UNDEAD then
		-- This is just so they get updated on what class they are and have their hulls set up right.
		pl:DoHulls(classid, TEAM_UNDEAD)
	elseif pl:Team() == TEAM_HUMAN then
		if self:GetWave() <= 0 and self.StartingWorth > 0 and not self.StartingLoadout and not self.ZombieEscape and not isbot then
			pl:SendLua("MakepWorth()")
		else
			gamemode.Call("GiveDefaultOrRandomEquipment", pl)
		end
	end

	if self.RoundEnded then
		if not isbot then pl:SendLua("gamemode.Call(\"EndRound\", "..tostring(ROUNDWINNER)..", \""..game.GetMapNext().."\")") end
		gamemode.Call("DoHonorableMentions", pl)
	end

	if pl:GetInfo("zs_noredeem") == "1" then
		pl.NoRedeeming = true
	end

	if self:GetWave() == 0 then
		self:SendZombieVolunteers(pl, true)
	end

	if not isbot and self:IsClassicMode() then
		pl:SendLua("SetGlobalBool(\"classicmode\", true)")
	elseif not isbot and self:IsBabyMode() then
		pl:SendLua("SetGlobalBool(\"babymode\", true)")
	end
end

function GM:FullGameUpdate(pl)
	if pl and pl:IsBot() then return end
	net.Start("zs_gamestate")
		net.WriteInt(self:GetWave(), 16)
		net.WriteFloat(self:GetWaveStart())
		net.WriteFloat(self:GetWaveEnd())
	if pl then
		net.Send(pl)
		self:SyncWeaponUnlocks(pl)
		if self.SyncZombieEscapeBosses then self:SyncZombieEscapeBosses(pl) end
	else
		net.Broadcast()
	end
end

concommand.Add("initpostentity", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	if not sender.DidInitPostEntity then
		sender.DidInitPostEntity = true

		gamemode.Call("PlayerReady", sender)
	end
end)

function GM:PlayerInitialSpawn(pl)
	if pl.ZSInitialSpawnComplete then return end
	pl.ZSInitialSpawnComplete = true
	gamemode.Call("PlayerInitialSpawnRound", pl)
	self.LastAnnouncedBossClass = nil
end

function GM:PlayerInitialSpawnRound(pl)
	self:ResetPlayerReturns(pl)
	self:ResetPlayerTraits(pl)
	pl:SprintDisable()
	if pl:KeyDown(IN_WALK) then
		pl:ConCommand("-walk")
	end

	pl:SetCanWalk(false)
	pl:SetCanZoom(false)
	pl:SetNoCollideWithTeammates(false)
	pl:SetCustomCollisionCheck(true)

	pl.ZombiesKilled = 0
	pl.ZombiesKilledAssists = 0
	pl.BrainsEaten = 0

	pl.ResupplyBoxUsedByOthers = 0

	pl.WaveJoined = self:GetWave()

	pl.CrowKills = 0
	pl.CrowVsCrowKills = 0
	pl.CrowBarricadeDamage = 0

	pl.BarricadeDamage = 0
	pl.DynamicSpawnedOn = 0

	pl.NextPainSound = 0

	pl.BonusDamageCheck = 0

	pl.LegDamage = 0

	pl.DamageDealt = {}
	pl.DamageDealt[TEAM_UNDEAD] = 0
	pl.DamageDealt[TEAM_HUMAN] = 0
	pl.DamageDealt[TEAM_REDEEMER] = 0

	pl.LifeBarricadeDamage = 0
	pl.LifeHumanDamage = 0
	pl.LifeBrainsEaten = 0
	
	pl.WaveBarricadeDamage = 0
	pl.WaveHumanDamage = 0

	pl.m_PointQueue = 0
	pl.m_LastDamageDealt = 0

	pl.HealedThisRound = 0
	pl.CarryOverHealth = 0
	pl.RepairedThisRound = 0
	pl.CarryOverRepair = 0
	pl.PointsCommission = 0
	pl.CarryOverCommision = 0
	pl.NextRegenerate = 0
	pl.NestsDestroyed = 0
	pl.NestSpawns = 0

	local nosend = not pl.DidInitPostEntity
	pl.HumanSpeedAdder = nil
	pl.HumanRepairMultiplier = nil
	pl.HumanHealMultiplier = nil
	pl.BuffResistant = nil
	pl.BuffRegenerative = nil
	pl.BuffMuscular = nil
	pl.IsWeak = nil
	pl:SetPalsy(false, nosend)
	pl:SetHemophilia(false, nosend)
	pl:SetUnlucky(false)
	pl.Clumsy = nil
	self:SetBarricadeGhostPolicy(pl, false, false)
	pl.NoObjectPickup = nil
	pl.DamageVulnerability = nil
	pl.Carpenter = nil
	pl.Cannibal = nil
	pl.Allergic = nil
	pl.FastResupply = nil
	pl.FastTeleport = nil
	pl.CrateShare = nil
	
	self:ResetMutationEffects(pl)

	local uniqueid = pl:UniqueID()


	if not self:RestoreSpectatorState(pl) then
		if self.PreviouslyDied[uniqueid] then
			pl:ChangeTeam(TEAM_UNDEAD)
		elseif LASTHUMAN then
			pl.SpawnedTime = CurTime()
			pl:ChangeTeam(TEAM_UNDEAD)
		elseif self:GetWave() <= 0 then
			pl.SpawnedTime = CurTime()
			pl:ChangeTeam(TEAM_HUMAN)
		elseif self:GetNumberOfWaves() == -1 or self.NoNewHumansWave <= self:GetWave() or team.NumPlayers(TEAM_UNDEAD) == 0 and 1 <= team.NumPlayers(TEAM_HUMAN) then
			pl:ChangeTeam(TEAM_UNDEAD)
			self.PreviouslyDied[uniqueid] = CurTime()
		else
			pl.SpawnedTime = CurTime()
			pl:ChangeTeam(TEAM_HUMAN)
			if self.DynamicSpawning then
				timer.Simple(0, function() GAMEMODE:AttemptHumanDynamicSpawn(pl) end)
			end
		end
	end

	if pl:Team() == TEAM_UNDEAD and not self:GetWaveActive() and self.ZombieClasses["Crow"] then
		pl:SetZombieClass(self.ZombieClasses["Crow"].Index)
		pl.DeathClass = self.DefaultZombieClass
	else
		pl:SetZombieClass(self.DefaultZombieClass)
	end

	if pl:Team() == TEAM_UNDEAD and self.StoredUndeadFrags[uniqueid] then
		pl:SetFrags(self.StoredUndeadFrags[uniqueid])
		self.StoredUndeadFrags[uniqueid] = nil
	end
	if not pl:IsBot() then
		for k, v in ipairs(self.ZombieClasses) do
			if v.Infliction and v.Unlocked == true then
				net.Start("unlockClass")
				net.WriteString(v.Name)
				net.Send(pl)
			end
		end
	end
end

function GM:GetDynamicSpawning()
	return self.DynamicSpawning
end

function GM:PlayerDisconnected(pl)
	pl.Disconnecting = true

	local uid = pl:UniqueID()

	self.PreviouslyDied[uid] = CurTime()

	if pl:Team() ~= TEAM_UNDEAD then
		pl:DropAll()
	elseif pl:Team() == TEAM_UNDEAD then
		self.StoredUndeadFrags[uid] = pl:Frags()
	end

	if pl:Health() > 0 and not pl:IsSpectator() then
		local lastattacker = pl:GetLastAttacker()
		if IsValid(lastattacker) then
			pl:TakeDamage(1000, lastattacker, lastattacker)

			PrintTranslatedMessage(HUD_PRINTCONSOLE, "disconnect_killed", pl:Name(), lastattacker:Name())
		end
	end

	gamemode.Call("CalculateInfliction")
end


function GM:PlayerDeathThink(pl)
	if self.RoundEnded or pl.Revive or self:GetWave() == 0 then return end

	if pl:GetObserverMode() == OBS_MODE_CHASE then
		local target = pl:GetObserverTarget()
		if not target or not target:IsValid() or target:IsPlayer() and (not target:Alive() or target:Team() ~= pl:Team()) then
			pl:StripWeapons()
			pl:Spectate(OBS_MODE_ROAMING)
			pl:SpectateEntity(NULL)
		end
	end

	if pl:Team() ~= TEAM_UNDEAD then
		pl.StartCrowing = nil
		pl.StartSpectating = nil
		return
	end

	if pl.NextSpawnTime and pl.NextSpawnTime <= CurTime() then -- Force spawn.
		pl.NextSpawnTime = nil

		pl:RefreshDynamicSpawnPoint()
		pl:UnSpectateAndSpawn()
	elseif pl:GetObserverMode() == OBS_MODE_NONE then -- Not in spectator yet.
		if self:GetWaveActive() then -- During wave.
			if not pl.StartSpectating or CurTime() >= pl.StartSpectating then
				pl.StartSpectating = nil

				pl:StripWeapons()
				local best = self:GetBestDynamicSpawn(pl)
				if best then
					pl:Spectate(OBS_MODE_CHASE)
					pl:SpectateEntity(best)
				else
					pl:Spectate(OBS_MODE_ROAMING)
					pl:SpectateEntity(NULL)
				end
			end
		elseif not pl.StartCrowing or CurTime() >= pl.StartCrowing then -- Not during wave. Turn in to a crow. If we die as a crow then we get turned to spectator anyway.
			pl:ChangeToCrow()
		end
	else -- In spectator.
		if pl:KeyDown(IN_RELOAD) then
			if self:GetWaveActive() then
				pl.ForceDynamicSpawn = nil
				local prev = self.DynamicSpawning
				self.DynamicSpawning = false
				pl:UnSpectateAndSpawn()
				self.DynamicSpawning = prev
			else
				pl:ChangeToCrow()
			end
		elseif pl:KeyDown(IN_WALK) then
			pl:TrySpawnAsGoreChild()
		elseif pl:KeyDown(IN_ATTACK) then
			if self:GetWaveActive() then
				pl:RefreshDynamicSpawnPoint()
				pl:UnSpectateAndSpawn()
			else
				pl:ChangeToCrow()
			end
		elseif pl:KeyPressed(IN_ATTACK2) then
			pl.SpectatedPlayerKey = (pl.SpectatedPlayerKey or 0) + 1

			local livingzombies = {}
			for _, v in pairs(self:GetZSClassEntities("prop_creepernest")) do
				if IsValid(v) and v:GetNestBuilt() then table.insert(livingzombies, v) end
			end
			for _, v in pairs(team.GetPlayers(TEAM_ZOMBIE)) do
				if v:Alive() then table.insert(livingzombies, v) end
			end
			--[[for _, v in pairs(team.GetSpawnPointGrouped(TEAM_UNDEAD)) do
				table.insert(livingzombies, v)
			end]]

			pl:StripWeapons()

			if pl.SpectatedPlayerKey > #livingzombies then
				pl.SpectatedPlayerKey = 1
			end

			local specplayer = livingzombies[pl.SpectatedPlayerKey]
			if specplayer then
				pl:Spectate(OBS_MODE_CHASE)
				pl:SpectateEntity(specplayer)
			end
		elseif pl:KeyPressed(IN_JUMP) then
			pl:Spectate(OBS_MODE_ROAMING)
			pl:SpectateEntity(NULL)
			pl.SpectatedPlayerKey = nil
		end
	end
end

include("server/sv_damage.lua")

function GM:SetRandomToZombie()
	local plays = team.GetPlayers(TEAM_HUMAN)
	if #plays == 0 then return end
	local pl = plays[math.random(#plays)]

	if not pl then return end

	pl:ChangeTeam(TEAM_UNDEAD)
	pl:SetFrags(0)
	pl:SetDeaths(0)

	self.StartingZombie[pl:UniqueID()] = true
	self.PreviouslyDied[pl:UniqueID()] = CurTime()
	pl:UnSpectateAndSpawn()

	return pl
end

function GM:OnPlayerChangedTeam(pl, oldteam, newteam)
	if newteam == TEAM_UNDEAD then
		pl:SetPoints(0)
		pl.DamagedBy = {}
		pl:SetBarricadeGhosting(false)
		self.CheckedOut[pl:UniqueID()] = true
	elseif newteam == TEAM_HUMAN then
		self.PreviouslyDied[pl:UniqueID()] = nil
	elseif newteam == TEAM_SPECTATOR then
		if oldteam == TEAM_HUMAN and self:GetWave() == 0 and not self:GetWaveActive() then
			pl.ChangedToSpecDuringWave0 = true
			pl.DiedDuringWave0 = false
		end
		
		if pl:OldAlive() then
			pl:KillSilent()
		end
		
		pl:RemoveAllStatus(false, true)
		pl.NoCollideAll = true
		pl:CollisionRulesChanged()
		
		--pl:CreateAmbience("ambience_spec")
		
		pl:SetHull(Vector(-0.1, -0.1, 0), Vector(0.1, 0.1, 18.1))
		pl:SetHullDuck(Vector(-0.1, -0.1, 0), Vector(0.1, 0.1, 18.1))
		
		pl:SetFrags(0)
		pl:StripWeapons()
		pl:Spectate(OBS_MODE_ROAMING)
	end

	pl:SetLastAttacker(nil)
	for _, p in player.Iterator() do
		if p.LastAttacker == pl then
			p.LastAttacker = nil
		end
	end

	pl.m_PointQueue = 0

	self:QueueInflictionRefresh()
end

function GM:SetPantsMode(mode)
	if self.ZombieEscape then return end

	self.PantsMode = mode and self.ZombieClasses["Zombie Legs"] ~= nil and not self:IsClassicMode() and not self:IsBabyMode()

	if self.PantsMode then
		local index = self.ZombieClasses["Zombie Legs"].Index

		self.PreOverrideDefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass
		self.DefaultZombieClass = index

		for _, pl in player.Iterator() do
			local classname = pl:GetZombieClassTable().Name
			if classname ~= "Zombie Legs" and classname ~= "Crow" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(index)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(index)
				end
			end
			pl.DeathClass = index
		end
	else
		self.DefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass

		for _, pl in player.Iterator() do
			if pl:GetZombieClassTable().Name == "Zombie Legs" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(self.DefaultZombieClass or 1)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(self.DefaultZombieClass or 1)
				end
			end
		end
	end
end

function GM:SetClassicMode(mode)
	if self.ZombieEscape then return end

	self.ClassicMode = mode and self.ZombieClasses["Classic Zombie"] ~= nil and not self.PantsMode and not self:IsBabyMode()

	SetGlobalBool("classicmode", self.ClassicMode)

	if self:IsClassicMode() then
		util.RemoveAll("prop_nail")

		local index = self.ZombieClasses["Classic Zombie"].Index

		self.PreOverrideDefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass
		self.DefaultZombieClass = index

		for _, pl in player.Iterator() do
			local classname = pl:GetZombieClassTable().Name
			if classname ~= "Classic Zombie" and classname ~= "Crow" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(index)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(index)
				end
			end
			pl.DeathClass = index
		end
	else
		self.DefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass

		for _, pl in player.Iterator() do
			if pl:GetZombieClassTable().Name == "Classic Zombie" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(self.DefaultZombieClass or 1)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(self.DefaultZombieClass or 1)
				end
			end
		end
	end
end

function GM:SetBabyMode(mode)
	if self.ZombieEscape then return end

	self.BabyMode = mode and self.ZombieClasses["Gore Child"] ~= nil and not self.PantsMode and not self:IsClassicMode()

	SetGlobalBool("babymode", self.BabyMode)

	if self:IsBabyMode() then
		local index = self.ZombieClasses["Gore Child"].Index

		self.PreOverrideDefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass
		self.DefaultZombieClass = index

		for _, pl in player.Iterator() do
			local classname = pl:GetZombieClassTable().Name
			if classname ~= "Gore Child" and classname ~= "Giga Gore Child" and classname ~= "Crow" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(index)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(index)
				end
			end
			pl.DeathClass = index
		end
	else
		self.DefaultZombieClass = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass

		for _, pl in player.Iterator() do
			if pl:GetZombieClassTable().Name == "Gore Child" then
				if pl:Team() == TEAM_UNDEAD then
					pl:KillSilent()
					pl:SetZombieClass(self.DefaultZombieClass or 1)
					pl:UnSpectateAndSpawn()
				else
					pl:SetZombieClass(self.DefaultZombieClass or 1)
				end
			end
		end
	end
end

function GM:SetClosestsToZombie()
	local allplayers = player.GetAllActive()
	local numplayers = #allplayers
	if numplayers <= 1 then return end

	local desiredzombies = self:GetDesiredStartingZombies()

	self:SortZombieSpawnDistances(allplayers)

	local zombies = {}
	for _, pl in pairs(allplayers) do
		if pl:Team() ~= TEAM_HUMAN or not pl:Alive() then
			table.insert(zombies, pl)
		end
	end

	-- Need to place some people back on the human team.
	if #zombies > desiredzombies then
		local toswap = #zombies - desiredzombies
		for _, pl in pairs(zombies) do
			if pl.DiedDuringWave0 and pl:GetInfo("zs_alwaysvolunteer") ~= "1" then
				pl:SetTeam(TEAM_HUMAN)
				pl:UnSpectateAndSpawn()
				toswap = toswap - 1
				if toswap <= 0 then
					break
				end
			end
		end
	end

	for i = 1, desiredzombies do
		local pl = allplayers[i]
		if pl:Team() ~= TEAM_UNDEAD then
			pl:ChangeTeam(TEAM_UNDEAD)
			self.PreviouslyDied[pl:UniqueID()] = CurTime()
		end
		pl:SetFrags(0)
		pl:SetDeaths(0)
		self.StartingZombie[pl:UniqueID()] = true
		pl:UnSpectateAndSpawn()
	end

	for _, pl in pairs(allplayers) do
		if pl:Team() == TEAM_HUMAN and pl._ZombieSpawnDistance <= 128 * 128 then
			pl:SetPos(self:PlayerSelectSpawn(pl):GetPos())
		end
	end
end

function GM:AllowPlayerPickup(pl, ent)
	return false
end

-- Don't change speed instantly to stop people from shooting and then running away with a faster weapon.
function GM:WeaponDeployed(pl, wep)
	local timername = tostring(pl).."speedchange"
	timer.Destroy(timername)

	local speed = pl:ResetSpeed(true) -- Determine what speed we SHOULD get without actually setting it.
	if speed < pl:GetMaxSpeed() then
		pl:SetSpeed(speed)
	elseif pl:GetMaxSpeed() < speed then
		timer.CreateEx(timername, 0.333, 1, ValidFunction, pl, "SetHumanSpeed")
	end
end

function GM:KeyPress(pl, key)
	if key == IN_USE then
		if pl:Team() ~= TEAM_UNDEAD and pl:Alive() then
			if pl:IsCarrying() then
				local holding = pl.status_human_holding
				pl.NextHold = math.max(pl.NextHold or 0, CurTime() + 0.25)
				holding:OnRemove()
				if IsValid(holding) then holding:RemoveNextFrame() end
			else
				if not self:TryTraitHeadcrabUse(pl) then self:TryHumanPickup(pl, pl:TraceLine(64).Entity) end
			end
		end
	elseif key == IN_SPEED then
		if pl:Alive() then
			if pl:Team() == TEAM_HUMAN then
				pl:DispatchAltUse()
			elseif pl:Team() == TEAM_UNDEAD then
				pl:CallZombieFunction("AltUse")
		end
	end
	end
end

function GM:GetNearestSpawn(pos, teamid)
	local nearest = NULL

	local nearestdist = math.huge
	for _, ent in pairs(team.GetValidSpawnPoint(teamid)) do
		if ent.Disabled then continue end

		local dist = ent:GetPos():DistToSqr(pos)
		if dist < nearestdist then
			nearestdist = dist
			nearest = ent
		end
	end

	return nearest
end

function GM:EntityWouldBlockSpawn(ent)
	local spawnpoint = self:GetNearestSpawn(ent:GetPos(), TEAM_UNDEAD)

	if spawnpoint:IsValid() then
		local spawnpos = spawnpoint:GetPos()
		if spawnpos:DistToSqr(ent:NearestPoint(spawnpos)) <= 1600 then return true end
	end

	return false
end

function GM:GetNearestSpawnDistance(pos, teamid)
	local nearest = self:GetNearestSpawn(pos, teamid)
	if nearest:IsValid() then
		return nearest:GetPos():Distance(pos)
	end

	return -1
end

function GM:PlayerUse(pl, ent)
	if not pl:Alive() or pl:Team() == TEAM_UNDEAD and pl:GetZombieClassTable().NoUse or pl:GetBarricadeGhosting() then return false end

	if pl:IsHolding() and pl:GetHolding() ~= ent then return false end
	if pl:KeyPressed(IN_USE) and (self:TryTraitFood(pl, ent) or self:TryTraitJunk(pl, ent) or self:TryTraitHeadcrab(pl, ent) or self:TryTraitBottle(pl, ent)) then return false end

	local entclass = ent:GetClass()
	if entclass == "prop_door_rotating" then
		if CurTime() < (ent.m_AntiDoorSpam or 0) then -- Prop doors can be glitched shut by mashing the use button.
			return false
		end
		ent.m_AntiDoorSpam = CurTime() + 0.85
	elseif entclass == "item_healthcharger" then
		if pl:Team() == TEAM_UNDEAD then return false end
	elseif pl:Team() ~= TEAM_UNDEAD and not pl:IsCarrying() and pl:KeyPressed(IN_USE) then
		self:TryHumanPickup(pl, ent)
	end

	return true
end

include("server/sv_playerdeath.lua")

function GM:PlayerCanPickupWeapon(pl, ent)
	if pl:IsSpectator() then return false end

	if pl:Team() == TEAM_UNDEAD then return ent:GetClass() == pl:GetZombieClassTable().SWEP end

	return not ent.ZombieOnly and ent:GetClass() ~= "weapon_stunstick"
end

function GM:OnZEWeaponPickup(pl, wep)
end

include("server/sv_playerspawn.lua")

include("server/sv_waveevents.lua")

include("shared/sh_footsteps.lua")

concommand.Add("zs_class", function(sender, command, arguments)
	if sender:Team() ~= TEAM_UNDEAD or sender.Revive or GAMEMODE.PantsMode or GAMEMODE:IsClassicMode() or GAMEMODE:IsBabyMode() or GAMEMODE.ZombieEscape then return end

	local classname = arguments[1]
	local suicide = arguments[2] == "1"
	local classtab = GAMEMODE.ZombieClasses[classname]
	if not classtab or classtab.Hidden and not (classtab.CanUse and classtab:CanUse(sender)) then return end

	if not gamemode.Call("IsClassUnlocked", classname) then
		sender:CenterNotify(COLOR_RED, translate.ClientFormat(sender, "class_not_unlocked_will_be_unlocked_x", classtab.Wave))
	elseif sender:GetZombieClassTable().Name == classname and not sender.DeathClass then
		sender:CenterNotify(COLOR_RED, translate.ClientFormat(sender, "you_are_already_a_x", translate.ClientGet(sender, classtab.TranslationName)))
	else
		sender.DeathClass = classtab.Index
		sender:CenterNotify(translate.ClientFormat(sender, "you_will_spawn_as_a_x", translate.ClientGet(sender, classtab.TranslationName)))

		if suicide and sender:Alive() and not sender:GetZombieClassTable().Boss and gamemode.Call("CanPlayerSuicide", sender) then
			sender:Kill()
		end
	end
end)

hook.Add("PlayerSpray", "DisablePlayerSpray", function(ply)
	return !ply:IsAdmin()
end)
