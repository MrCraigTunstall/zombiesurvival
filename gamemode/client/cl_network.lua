local util = util
local math = math
local gamemode = gamemode
local hook = hook
local CurTime = CurTime
local ScrW = ScrW
local ScrH = ScrH
local TEAM_UNDEAD = TEAM_UNDEAD
local translate = translate
local COLOR_RED = COLOR_RED
local COLOR_GREEN = COLOR_GREEN
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_PlaySound = surface.PlaySound

net.Receive("zs_worthdefault", function()
	GAMEMODE:RequestedDefaultCart()
end)

local DamageFloaters = CreateClientConVar("zs_damagefloaters", "1", true, false):GetBool()
cvars.AddChangeCallback("zs_damagefloaters", function(cvar, oldvalue, newvalue)
	DamageFloaters = newvalue ~= "0"
end)

concommand.Add("spectate", function()
	net.Start("zs_spectate")
	net.SendToServer()
end)

net.Receive("zs_legdamage", function(length)
	LocalPlayer().LegDamage = net.ReadFloat()
end)

net.Receive("zs_nextboss", function(length)
	GAMEMODE.NextBossZombie = net.ReadEntity()
	GAMEMODE.NextBossZombieClass = net.ReadString()
end)

net.Receive("zs_zvols", function(length)
	local volunteers = {}
	local count = net.ReadUInt(8)
	for i=1, count do
		volunteers[i] = net.ReadEntity()
	end

	GAMEMODE.ZombieVolunteers = volunteers
end)

net.Receive("zs_dmg", function(length)
	local damage = net.ReadUInt(16)
	local pos = net.ReadVector()

	if DamageFloaters then
		local effectdata = EffectData()
			effectdata:SetOrigin(pos)
			effectdata:SetMagnitude(damage)
			effectdata:SetScale(0)
		util.Effect("damagenumber", effectdata)
	end
end)

net.Receive("zs_dmg_prop", function(length)
	local damage = net.ReadUInt(16)
	local pos = net.ReadVector()

	if DamageFloaters then
		local effectdata = EffectData()
			effectdata:SetOrigin(pos)
			effectdata:SetMagnitude(damage)
			effectdata:SetScale(1)
		util.Effect("damagenumber", effectdata)
	end
end)

net.Receive("zs_lifestats", function(length)
	local barricadedamage = net.ReadUInt(24)
	local humandamage = net.ReadUInt(24)
	local brainseaten = net.ReadUInt(16)

	GAMEMODE.LifeStatsEndTime = CurTime() + GAMEMODE.LifeStatsLifeTime
	GAMEMODE.LifeStatsBarricadeDamage = barricadedamage
	GAMEMODE.LifeStatsHumanDamage = humandamage
	GAMEMODE.LifeStatsBrainsEaten = brainseaten
end)

net.Receive("zs_lifestatsbd", function(length)
	local barricadedamage = net.ReadUInt(24)

	GAMEMODE.LifeStatsEndTime = CurTime() + GAMEMODE.LifeStatsLifeTime
	GAMEMODE.LifeStatsBarricadeDamage = barricadedamage
end)

net.Receive("zs_lifestatshd", function(length)
	local humandamage = net.ReadUInt(24)

	GAMEMODE.LifeStatsEndTime = CurTime() + GAMEMODE.LifeStatsLifeTime
	GAMEMODE.LifeStatsHumanDamage = humandamage
end)

net.Receive("zs_lifestatsbe", function(length)
	local brainseaten = net.ReadUInt(16)

	GAMEMODE.LifeStatsEndTime = CurTime() + GAMEMODE.LifeStatsLifeTime
	GAMEMODE.LifeStatsBrainsEaten = brainseaten
end)

net.Receive("zs_honmention", function(length)
	local count = net.ReadUInt(8)
	for index = 1, count do
		local pl = net.ReadEntity()
		local mentionid = net.ReadUInt(8)
		local etc = net.ReadInt(32)
		if IsValid(pl) then gamemode.Call("AddHonorableMention", pl, mentionid, etc) end
	end
	gamemode.Call("FinishHonorableMentions")
end)

net.Receive("zs_wavestart", function(length)
	local wave = net.ReadInt(16)
	local time = net.ReadFloat()

	gamemode.Call("SetWave", wave)
	gamemode.Call("SetWaveEnd", time)

	if GAMEMODE.ZombieEscape then
		GAMEMODE:CenterNotify(COLOR_RED, {font = "ZSHUDFont"}, translate.Get("escape_from_the_zombies"))
	elseif wave == GAMEMODE:GetNumberOfWaves() then
		GAMEMODE:CenterNotify({killicon = "default"}, {font = "ZSHUDFont"}, " ", COLOR_RED, translate.Get("final_wave"), {killicon = "default"})
		GAMEMODE:CenterNotify(translate.Get("final_wave_sub"))
	else
		GAMEMODE:CenterNotify({killicon = "default"}, {font = "ZSHUDFont"}, " ", COLOR_RED, translate.Format("wave_x_has_begun", wave), {killicon = "default"})
	end

	if not GAMEMODE.ObjectiveMap and GAMEMODE:WeaponTiersEnabled() then
	if LocalPlayer():IsValid() and LocalPlayer():Team() ~= TEAM_UNDEAD then
			GAMEMODE:CenterNotify(COLOR_GREEN, translate.Format("weapon_tier_x", wave))
		end
	end
	
	surface_PlaySound("zombiesurvival/round_start.mp3")
end)

net.Receive("zs_classunlock", function(length)
	if GAMEMODE.ZombieEscape then return end
	GAMEMODE:CenterNotify(COLOR_GREEN, translate.Format("x_unlocked", net.ReadString()))
end)

net.Receive("zs_waveend", function(length)
	local wave = net.ReadInt(16)
	local time = net.ReadFloat()

	gamemode.Call("SetWaveStart", time)

	if wave < GAMEMODE:GetNumberOfWaves() and wave > 0 then
		GAMEMODE:CenterNotify(COLOR_RED, {font = "ZSHUDFont"}, translate.Format("wave_x_is_over", wave))
		GAMEMODE:CenterNotify(translate.Format("wave_x_is_over_sub", GAMEMODE.ArsenalCrateDiscountPercentage))

		surface_PlaySound("zombiesurvival/round_end.mp3")
	end
end)

net.Receive("zs_gamestate", function(length)
	local wave = net.ReadInt(16)
	local wavestart = net.ReadFloat()
	local waveend = net.ReadFloat()

	gamemode.Call("SetWave", wave)
	gamemode.Call("SetWaveStart", wavestart)
	gamemode.Call("SetWaveEnd", waveend)
end)

local matSkull = Material("zombiesurvival/horderally")
local bossspawnedend
local function BossSpawnedPaint()
	if CurTime() > bossspawnedend then
		hook.Remove("HUDPaint", "BossSpawnedPaint")
		return
	end

	local delta = math.Clamp(bossspawnedend - CurTime(), 0, 1)
	local size = (1 - delta) * math.max(ScrW(), ScrH())

	surface_SetMaterial(matSkull)
	surface_SetDrawColor(160, 0, 0, math.min(delta * 400, 180))
	surface_DrawTexturedRectRotated(ScrW() / 2, ScrH() / 2, size, size, delta * 25)
end
net.Receive("zs_boss_spawned", function(length)
	local ent = net.ReadEntity()
	local classindex = net.ReadUInt(8)
	local class = GAMEMODE.ZombieClasses[classindex]
	if not class or not class.Boss then return end
	local color = class.SuperBoss and COLOR_CYAN or COLOR_RED
	if class.SuperBoss then GAMEMODE:CenterNotify(COLOR_CYAN, "SUPER BOSS") end

	if ent == MySelf and ent:IsValid() then
		GAMEMODE:CenterNotify({killicon = "default"}, " ", color, translate.Format("you_are_x", translate.Get(GAMEMODE.ZombieClasses[classindex].TranslationName)), {killicon = "default"})
	elseif ent:IsValid() then
		GAMEMODE:CenterNotify({killicon = "default"}, " ", color, (translate.Format("x_has_risen_as_y", ent:Name(), translate.Get(GAMEMODE.ZombieClasses[classindex].TranslationName))), {killicon = "default"})
	else
		GAMEMODE:CenterNotify({killicon = "default"}, " ", color, translate.Format("x_has_risen", translate.Get(GAMEMODE.ZombieClasses[classindex].TranslationName)), {killicon = "default"})
	end

	if MySelf:IsValid() then
		MySelf:EmitSound("npc/zombie_poison/pz_alert1.wav", 0)
	end

	bossspawnedend = CurTime() + (class.SuperBoss and 2 or 1)
	hook.Add("HUDPaint", "BossSpawnedPaint", BossSpawnedPaint)
end)

net.Receive("zs_centernotify", function(length)
	local tab = net.ReadTable()

	GAMEMODE:CenterNotify(unpack(tab))
end)

net.Receive("zs_topnotify", function(length)
	local tab = net.ReadTable()

	GAMEMODE:TopNotify(unpack(tab))
end)

net.Receive("zs_lasthuman", function(length)
	local pl = net.ReadEntity()
	GAMEMODE:SetLastHumanMusic(net.ReadString())

	gamemode.Call("LastHuman", pl)
end)

net.Receive("zs_weapontiers", function(length)
	if length < 9 then return end
	local count = net.ReadUInt(9)
	if count < 1 or count > 256 or length < 9 + count * 16 then return end
	for index = 1, count do
		local item = GAMEMODE.Items[net.ReadUInt(16)]
		if item then GAMEMODE:SetWeaponInflictionUnlocked(item) end
	end
end)

net.Receive("zs_gamemodecall", function(length)
	gamemode.Call(net.ReadString())
end)

net.Receive("zs_lasthumanpos", function(length)
	GAMEMODE.LastHumanPosition = net.ReadVector()
end)

net.Receive("zs_endround", function(length)
	local winner = net.ReadUInt(8)
	local nextmap = net.ReadString()

	gamemode.Call("EndRound", winner, nextmap)
end)

net.Receive("zs_ammogive", function(length)
	local amount = net.ReadUInt(16)
	local ammotype = net.ReadString()
	local ent = net.ReadEntity()

	if not ent:IsValidPlayer() then return end
	local ico = GAMEMODE.AmmoIcons[ammotype] or "weapon_zs_resupplybox"

	ammotype = GAMEMODE.AmmoNames[ammotype] or ammotype

	GAMEMODE:CenterNotify({killicon = ico}, " ", COLOR_GREEN, translate.Format("gave_x_y_ammo_to_z", amount, ammotype, ent:Name()))
end)

net.Receive("zs_ammogiven", function(length)
	local amount = net.ReadUInt(16)
	local ammotype = net.ReadString()
	local ent = net.ReadEntity()

	if not ent:IsValidPlayer() then return end
	local ico = GAMEMODE.AmmoIcons[ammotype] or "weapon_zs_resupplybox"

	ammotype = GAMEMODE.AmmoNames[ammotype] or ammotype

	GAMEMODE:CenterNotify({killicon = ico}, " ", COLOR_GREEN, translate.Format("obtained_x_y_ammo_from_z", amount, ammotype, ent:Name()))
end)

net.Receive("zs_updatealtselwep", function(length)
end)

net.Receive("zs_nailremoved", function(length)
	local ent = net.ReadEntity()
	if not ent:IsValidPlayer() then return end

	GAMEMODE:CenterNotify({killicon = "weapon_zs_hammer"}, " ", COLOR_RED, translate.Format("removed_your_nail", ent:Name()))
end)

