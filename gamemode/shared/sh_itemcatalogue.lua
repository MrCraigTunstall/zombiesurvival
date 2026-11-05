GM.Items = {}
GM.ItemsBySignature = {}
GM.WeaponTierItems = {}
function GM:AddItem(signature, name, desc, category, worth, swep, callback, model, worthshop, pointshop, wave, unlocked, infliction)
	local tab = {Signature = signature, Name = name, Description = desc, Category = category, Worth = worth or 0, SWEP = swep, Callback = callback, Model = model, WorthShop = worthshop, PointShop = pointshop, Wave = wave or 0, Unlocked = unlocked, Infliction = infliction}
	self.Items[#self.Items + 1] = tab
	self.ItemsBySignature[signature] = self.ItemsBySignature[signature] or tab

	if type(swep) == "string" and (pointshop or not self.WeaponTierItems[swep]) then self.WeaponTierItems[swep] = tab end
	return tab
end

function GM:AddStartingItem(signature, name, desc, category, points, worth, callback, model)
	return self:AddItem(signature, name, desc, category, points, worth, callback, model, true, false, 0, true, nil)
end

function GM:AddPointShopItem(signature, name, desc, category, points, worth, wave, unlocked, infliction, callback, model)
	return self:AddItem("ps_"..signature, name, desc, category, points, worth, callback, model, false, true, wave, unlocked, infliction)
end

timer.Simple(0, function()
	local gm = GAMEMODE
	if not gm or type(gm.Items) ~= "table" then return end
	local stored = {}
	for _, tab in pairs(gm.Items) do
		if not tab.Description and tab.SWEP then
			local sweptab = stored[tab.SWEP]
			if sweptab == nil then
				sweptab = weapons.GetStored(tab.SWEP) or false
				stored[tab.SWEP] = sweptab
			end
			if sweptab then
				tab.Description = sweptab.Description
			end
		end
	end
end)

GM.AmmoCache = {}
GM.AmmoCache["ar2"] = 30
GM.AmmoCache["alyxgun"] = 24
GM.AmmoCache["pistol"] = 12
GM.AmmoCache["smg1"] = 30
GM.AmmoCache["357"] = 6
GM.AmmoCache["xbowbolt"] = 4
GM.AmmoCache["buckshot"] = 8
GM.AmmoCache["ar2altfire"] = 1
GM.AmmoCache["slam"] = 1
GM.AmmoCache["rpg_round"] = 1
GM.AmmoCache["smg1_grenade"] = 1
GM.AmmoCache["sniperround"] = 1
GM.AmmoCache["sniperpenetratedround"] = 1
GM.AmmoCache["grenade"] = 1
GM.AmmoCache["thumper"] = 1
GM.AmmoCache["gravity"] = 1
GM.AmmoCache["battery"] = 30
GM.AmmoCache["gaussenergy"] = 1
GM.AmmoCache["combinecannon"] = 1
GM.AmmoCache["airboatgun"] = 1
GM.AmmoCache["striderminigun"] = 1
GM.AmmoCache["helicoptergun"] = 1
GM.AmmoCache["spotlamp"] = 1
GM.AmmoCache["manhack"] = 1
GM.AmmoCache["pulse"] = 30

GM.AmmoResupply = {}
GM.AmmoResupply["ar2"] = 20
GM.AmmoResupply["alyxgun"] = GM.AmmoCache["alyxgun"]
GM.AmmoResupply["pistol"] = GM.AmmoCache["pistol"]
GM.AmmoResupply["smg1"] = 20
GM.AmmoResupply["357"] = GM.AmmoCache["357"]
GM.AmmoResupply["xbowbolt"] = GM.AmmoCache["xbowbolt"]
GM.AmmoResupply["buckshot"] = GM.AmmoCache["buckshot"]
GM.AmmoResupply["battery"] = 20
GM.AmmoResupply["pulse"] = GM.AmmoCache["pulse"]

GM:AddStartingItem("pshtr", ""..translate.Get("worth_peashooter"), nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_peashooter")
GM:AddStartingItem("btlax", ""..translate.Get("worth_battleaxe"), nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_battleaxe")
GM:AddStartingItem("owens", ""..translate.Get("worth_owens"), nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_owens")
GM:AddStartingItem("z9000", ""..translate.Get("worth_z9000"), nil, ITEMCAT_WORTHGUNS, 20, "weapon_zs_z9000")

GM:AddStartingItem("blstr", ""..translate.Get("worth_blaster"), nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_blaster")

GM:AddStartingItem("tossr", ""..translate.Get("worth_tosser"), nil, ITEMCAT_WORTHGUNS, 20, "weapon_zs_tosser")

GM:AddStartingItem("stbbr", ""..translate.Get("worth_stubber"), nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_stubber")

GM:AddStartingItem("crklr", ""..translate.Get("worth_crackler"), nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_crackler")

GM:AddStartingItem("2pcp", ""..translate.Get("worth_3pistol"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pistol"] or 12) * 3, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddStartingItem("2sgcp", ""..translate.Get("worth_3shotgun"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["buckshot"] or 8) * 3, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddStartingItem("2smgcp", ""..translate.Get("worth_3smg"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["smg1"] or 30) * 3, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddStartingItem("2arcp", ""..translate.Get("worth_3assaultrifle"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["ar2"] or 30) * 3, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddStartingItem("2rcp", ""..translate.Get("worth_3rifle"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["357"] or 6) * 3, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddStartingItem("2pls", ""..translate.Get("worth_3pulse"), nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pulse"] or 30) * 3, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")
GM:AddStartingItem("3pcp", ""..translate.Get("worth_5pistol"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pistol"] or 12) * 5, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddStartingItem("3sgcp", ""..translate.Get("worth_5shotgun"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["buckshot"] or 8) * 5, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddStartingItem("3smgcp", ""..translate.Get("worth_5smg"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["smg1"] or 30) * 5, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddStartingItem("3arcp", ""..translate.Get("worth_5assaultrifle"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["ar2"] or 30) * 5, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddStartingItem("3rcp", ""..translate.Get("worth_5rifle"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["357"] or 6) * 5, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddStartingItem("3pls", ""..translate.Get("worth_5pulse"), nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pulse"] or 30) * 5, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")

GM:AddStartingItem("zpfryp", ""..translate.Get("worth_fryingpan"), nil, ITEMCAT_MELEE, 5, "weapon_zs_fryingpan")
GM:AddStartingItem("zpcpot", ""..translate.Get("worth_cookingpot"), nil, ITEMCAT_MELEE, 5, "weapon_zs_pot")
GM:AddStartingItem("csknf", ""..translate.Get("worth_knife"), nil, ITEMCAT_MELEE, 5, "weapon_zs_swissarmyknife")
GM:AddStartingItem("zpaxe", ""..translate.Get("worth_axe"), nil, ITEMCAT_MELEE, 10, "weapon_zs_axe")
GM:AddStartingItem("crwbar", ""..translate.Get("worth_crowbar"), nil, ITEMCAT_MELEE, 15, "weapon_zs_crowbar")
GM:AddStartingItem("hook", ""..translate.Get("worth_meathook"), nil, ITEMCAT_MELEE, 15, "weapon_zs_hook")
GM:AddStartingItem("stnbtn", ""..translate.Get("worth_stun"), nil, ITEMCAT_MELEE, 20, "weapon_zs_stunbaton")
GM:AddStartingItem("zpplnk", ""..translate.Get("worth_plank"), nil, ITEMCAT_MELEE, 20, "weapon_zs_plank")
GM:AddStartingItem("pipe", ""..translate.Get("worth_leadpipe"), nil, ITEMCAT_MELEE, 25, "weapon_zs_pipe")

GM:AddStartingItem("msgbeacon", ""..translate.Get("worth_beacon"), nil, ITEMCAT_TOOLS, 1, "weapon_zs_messagebeacon").Countables = "prop_messagebeacon"
GM:AddStartingItem("spotlamp", ""..translate.Get("worth_spotlamp"), nil, ITEMCAT_TOOLS, 5, "weapon_zs_spotlamp").Countables = "prop_spotlamp"
GM:AddStartingItem("6nails", ""..translate.Get("worth_6nails"), ""..translate.Get("worth_6nails2"), ITEMCAT_TOOLS, 12, nil, function(pl) pl:GiveAmmo(12, "GaussEnergy", true) end, "models/Items/BoxMRounds.mdl")
GM:AddStartingItem("wrench", ""..translate.Get("worth_wrench"), nil, ITEMCAT_TOOLS, 15, "weapon_zs_wrench").NoClassicMode = true
GM:AddStartingItem("crphmr", ""..translate.Get("worth_hammer"), nil, ITEMCAT_TOOLS, 15, "weapon_zs_hammer").NoClassicMode = true
GM:AddStartingItem("arscrate", ""..translate.Get("worth_arsenalcrate"), nil, ITEMCAT_TOOLS, 15, "weapon_zs_arsenalcrate").Countables = "prop_arsenalcrate"
GM:AddStartingItem("150mkit", ""..translate.Get("worth_150meds"), ""..translate.Get("worth_150meds2"), ITEMCAT_TOOLS, 15, nil, function(pl) pl:GiveAmmo(150, "Battery", true) end, "models/healthvial.mdl")
GM:AddStartingItem("medkit", ""..translate.Get("worth_medkit"), nil, ITEMCAT_TOOLS, 20, "weapon_zs_medicalkit")
GM:AddStartingItem("junkpack", ""..translate.Get("worth_junkpack"), nil, ITEMCAT_TOOLS, 20, "weapon_zs_boardpack")
GM:AddStartingItem("medgun", ""..translate.Get("worth_medgun"), nil, ITEMCAT_TOOLS, 25, "weapon_zs_medicgun")
local item = GM:AddStartingItem("manhack", ""..translate.Get("worth_manhack"), nil, ITEMCAT_TOOLS, 20, "weapon_zs_manhack")
item.Countables = "prop_manhack"
GM:AddStartingItem("resupplybox", ""..translate.Get("worth_resupplybox"), nil, ITEMCAT_TOOLS, 30, "weapon_zs_resupplybox").Countables = "prop_resupplybox"
GM:AddStartingItem("ffemitter", ""..translate.Get("worth_fieldemiter"), nil, ITEMCAT_TOOLS, 50, "weapon_zs_ffemitter").Countables = "prop_ffemitter"
local handRepair = GM:AddStartingItem("repairfield", translate.Get("weapon_repairfield"), translate.Get("weapon_repairfield_desc"), ITEMCAT_TOOLS, 50, "weapon_zs_repairfield")
handRepair.NoClassicMode = true
local repairEmitter = GM:AddStartingItem("repairemitter", translate.Get("worth_repairemitter"), translate.Get("worth_repairemitter_desc"), ITEMCAT_TOOLS, 50, "weapon_zs_repairemitter")
repairEmitter.Countables = "prop_repairemitter"
repairEmitter.NoClassicMode = true
local item = GM:AddStartingItem("infturret", ""..translate.Get("worth_turret"), ""..translate.Get("worth_turret2"),
	ITEMCAT_TOOLS, 65, nil, function(pl)
	pl:GiveEmptyWeapon("weapon_zs_gunturret")
	pl:GiveAmmo(1, "thumper")
	pl:GiveAmmo(250, "smg1")
end, "models/combine_turrets/floor_turret.mdl")
item.Countables = {"weapon_zs_gunturret", "prop_gunturret"}
item.NoClassicMode = true
item.WorthGrant = {Weapon = "weapon_zs_gunturret", Empty = true, Ammo = {{Type = "thumper", Amount = 1}, {Type = "smg1", Amount = 250}}}
item.WorthGrantCallback = item.Callback

GM:AddStartingItem("stone", ""..translate.Get("worth_stone"), nil, ITEMCAT_OTHER, 0, "weapon_zs_stone")
GM:AddStartingItem("oxtank", ""..translate.Get("worth_oxygentank"), ""..translate.Get("worth_oxygentank2"), ITEMCAT_OTHER, 1, "weapon_zs_oxygentank")
GM:AddStartingItem("medxcbomb", ""..translate.Get("ars_mednade"), ""..translate.Get("ars_mednade_desc"), ITEMCAT_OTHER, 10, "weapon_zs_mediccloudbomb")

GM:AddStartingItem("10hp", ""..translate.Get("worth_fit"), ""..translate.Get("worth_fit2"), ITEMCAT_TRAITS, 10, nil, function(pl) pl:SetMaxHealth(pl:GetMaxHealth() + 10) pl:SetHealth(pl:Health() + 10) end, "models/healthvial.mdl")
GM:AddStartingItem("25hp", ""..translate.Get("worth_tough"), ""..translate.Get("worth_tough2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl:SetMaxHealth(pl:GetMaxHealth() + 25) pl:SetHealth(pl:Health() + 25) end, "models/items/healthkit.mdl")
local item = GM:AddStartingItem("5spd", ""..translate.Get("worth_quick"), ""..translate.Get("worth_quick2"), ITEMCAT_TRAITS, 10, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) + 7 pl:ResetSpeed() end, "models/props_lab/jar01a.mdl")
item.NoClassicMode = true
item.NoZombieEscape = true
local item = GM:AddStartingItem("10spd", ""..translate.Get("worth_surged"), ""..translate.Get("worth_surged2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) + 14 pl:ResetSpeed() end, "models/props_lab/jar01a.mdl")
item.NoClassicMode = true
item.NoZombieEscape = true
GM:AddStartingItem("bfsurgeon", ""..translate.Get("worth_surgeon"), ""..translate.Get("worth_surgeon2"), ITEMCAT_TRAITS, 10, nil, function(pl) pl.HumanHealMultiplier = (pl.HumanHealMultiplier or 1) + 0.3 end, "models/healthvial.mdl")
GM:AddStartingItem("bfmedicine", ""..translate.Get("worth_medicine"), ""..translate.Get("worth_medicine2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl.HumanHealMultiplier = (pl.HumanHealMultiplier or 1) + 1.0 end, "models/healthvial.mdl")
GM:AddStartingItem("bfresist", ""..translate.Get("worth_resistant"), ""..translate.Get("worth_resistant2"), ITEMCAT_TRAITS, 15, nil, function(pl) pl.BuffResistant = true end, "models/healthvial.mdl")
GM:AddStartingItem("bfregen", ""..translate.Get("worth_regen"), ""..translate.Get("worth_regen2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl.BuffRegenerative = true end, "models/healthvial.mdl")
GM:AddStartingItem("bfhandy", ""..translate.Get("worth_handy"), ""..translate.Get("worth_handy2"), ITEMCAT_TRAITS, 25, nil, function(pl) pl.HumanRepairMultiplier = (pl.HumanRepairMultiplier or 1) + 0.25 end, "models/props_c17/tools_wrench01a.mdl")
GM:AddStartingItem("bfengineer", ""..translate.Get("worth_engi"), ""..translate.Get("worth_engi2"), ITEMCAT_TRAITS, 35, nil, function(pl) pl.HumanRepairMultiplier = (pl.HumanRepairMultiplier or 1) + 0.50 end, "models/props_c17/tools_wrench01a.mdl")
GM:AddStartingItem("bfmusc", ""..translate.Get("worth_muscular"),""..translate.Get("worth_muscular2"), ITEMCAT_TRAITS, 25, nil, function(pl) pl.BuffMuscular = true pl:DoMuscularBones() end, "models/props_wasteland/kitchen_shelf001a.mdl")
GM:AddStartingItem("bfcarpenter", ""..translate.Get("worth_carpenter"), ""..translate.Get("worth_carpenter2"), ITEMCAT_TRAITS, 35, nil, function(pl) pl.Carpenter = true end, "models/weapons/w_hammer.mdl")
GM:AddStartingItem("bfcannibal", ""..translate.Get("worth_cannibal"), ""..translate.Get("worth_cannibal2"), ITEMCAT_TRAITS, 30, nil, function(pl) pl.Cannibal = true end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("bfghostmode", ""..translate.Get("worth_ghostmode"), ""..translate.Get("worth_ghostmode2"), ITEMCAT_TRAITS, 15, nil, function(pl) GAMEMODE:SetBarricadeGhostPolicy(pl, pl.NoGhosting, true) end, "models/healthvial.mdl")
GM:AddStartingItem("bffastresupply", ""..translate.Get("worth_fastresupply"), ""..translate.Get("worth_fastresupply2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl.FastResupply = true end, "models/healthvial.mdl")
GM:AddStartingItem("bffastteleport", ""..translate.Get("worth_fastteleport"), ""..translate.Get("worth_fastteleport2"), ITEMCAT_TRAITS, 20, nil, function(pl) pl.FastTeleport = true end, "models/healthvial.mdl")
GM:AddStartingItem("bfcrateshare", ""..translate.Get("worth_crateshare"), ""..translate.Get("worth_crateshare2"), ITEMCAT_TRAITS, 25, nil, function(pl) pl.CrateShare = true end, "models/healthvial.mdl")

GM:AddStartingItem("dbfallergic", ""..translate.Get("worth_allergic"), ""..translate.Get("worth_allergic2"), ITEMCAT_RETURNS, -30, nil, function(pl) pl.Allergic = true end, "models/gibs/hgibs_spine.mdl")
GM:AddStartingItem("dbfpalsy", ""..translate.Get("worth_palasy"), ""..translate.Get("worth_palasy2"), ITEMCAT_RETURNS, -10, nil, function(pl) pl:SetPalsy(true) end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfnopickup", ""..translate.Get("worth_noodlearms"), ""..translate.Get("worth_noodlearms2"), ITEMCAT_RETURNS, -15, nil, function(pl) pl.NoObjectPickup = true pl:DoNoodleArmBones() end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfhemo", ""..translate.Get("worth_hemo"), ""..translate.Get("worth_hemo2"), ITEMCAT_RETURNS, -15, nil, function(pl) pl:SetHemophilia(true) end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfweak", ""..translate.Get("worth_weak"), ""..translate.Get("worth_weak2"), ITEMCAT_RETURNS, -20, nil, function(pl) pl:SetMaxHealth(math.max(1, pl:GetMaxHealth() - 30)) pl:SetHealth(pl:GetMaxHealth()) pl.IsWeak = true end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfnoghosting", ""..translate.Get("worth_wideload"), ""..translate.Get("worth_wideload2"), ITEMCAT_RETURNS, -25, nil, function(pl) GAMEMODE:SetBarricadeGhostPolicy(pl, true, pl.GhostCade) end, "models/gibs/HGIBS.mdl").NoClassicMode = true
GM:AddStartingItem("dbfslow", ""..translate.Get("worth_slow"), ""..translate.Get("worth_slow2"), ITEMCAT_RETURNS, -30, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) - 20 pl:ResetSpeed() pl.IsSlow = true end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfclumsy", ""..translate.Get("worth_clumsy"), ""..translate.Get("worth_clumsy2"), ITEMCAT_RETURNS, -30, nil, function(pl) pl.Clumsy = true end, "models/gibs/HGIBS.mdl")
GM:AddStartingItem("dbfunluc", ""..translate.Get("worth_banlive"), ""..translate.Get("worth_banlive2"), ITEMCAT_RETURNS, -40, nil, function(pl) pl:SetUnlucky(true) end, "models/gibs/HGIBS.mdl")

GM:AddPointShopItem("deagle", ""..translate.Get("ars_deagle"), nil, ITEMCAT_HANDGUNS, 30, "weapon_zs_deagle")
GM:AddPointShopItem("glock3", ""..translate.Get("ars_glock"), nil, ITEMCAT_HANDGUNS, 30, "weapon_zs_glock3")
GM:AddPointShopItem("magnum", ""..translate.Get("ars_magnum"), nil, ITEMCAT_HANDGUNS, 35, "weapon_zs_magnum")
GM:AddPointShopItem("eraser", ""..translate.Get("ars_tacticalpistol"), nil, ITEMCAT_HANDGUNS, 35, "weapon_zs_eraser")
GM:AddPointShopItem("python", ""..translate.Get("weapon_python"), nil, ITEMCAT_HANDGUNS, 95, "weapon_zs_python")

GM:AddPointShopItem("ender", ""..translate.Get("ars_autoen"), nil, ITEMCAT_SHOTGUNS, 85, "weapon_zs_ender")
GM:AddPointShopItem("sweeper", ""..translate.Get("ars_sweeper"), nil, ITEMCAT_SHOTGUNS, 170, "weapon_zs_sweepershotgun")
GM:AddPointShopItem("boomstick", ""..translate.Get("ars_boomstick"), nil, ITEMCAT_SHOTGUNS, 250, "weapon_zs_boomstick")

GM:AddPointShopItem("uzi", ""..translate.Get("ars_uzi"), nil, ITEMCAT_SMG, 70, "weapon_zs_uzi")
GM:AddPointShopItem("shredder", ""..translate.Get("ars_shredder"), nil, ITEMCAT_SMG, 70, "weapon_zs_smg")
GM:AddPointShopItem("bulletstorm", ""..translate.Get("ars_bulletstorm"), nil, ITEMCAT_SMG, 70, "weapon_zs_bulletstorm")
GM:AddPointShopItem("reaper", ""..translate.Get("ars_reaperump"), nil, ITEMCAT_SMG, 80, "weapon_zs_reaper")
GM:AddPointShopItem("silencer", ""..translate.Get("ars_silencer"), nil, ITEMCAT_SMG, 100, "weapon_zs_silencer")
GM:AddPointShopItem("m249", ""..translate.Get("ars_punisher"), nil, ITEMCAT_SMG, 230, "weapon_zs_m249")

GM:AddPointShopItem("hunter", ""..translate.Get("ars_hunter"), nil, ITEMCAT_RIFLES, 70, "weapon_zs_hunter")
GM:AddPointShopItem("annabelle", ""..translate.Get("ars_annabele"), nil, ITEMCAT_RIFLES, 100, "weapon_zs_annabelle")
GM:AddPointShopItem("g3sg1", ""..translate.Get("ars_infiltrator"), nil, ITEMCAT_RIFLES, 110, "weapon_zs_g3sg1")
GM:AddPointShopItem("slugrifle", ""..translate.Get("ars_tiny"), nil, ITEMCAT_RIFLES, 200, "weapon_zs_slugrifle")
GM:AddPointShopItem("pulserifle", ""..translate.Get("ars_adonis"), nil, ITEMCAT_RIFLES, 230, "weapon_zs_pulserifle")
GM:AddPointShopItem("sg550", ""..translate.Get("ars_killer"), nil, ITEMCAT_RIFLES, 240, "weapon_zs_sg550")

GM:AddPointShopItem("akbar", ""..translate.Get("ars_akbar"), nil, ITEMCAT_ASSAULTS, 85, "weapon_zs_akbar")
GM:AddPointShopItem("galil", ""..translate.Get("ars_galil"), nil, ITEMCAT_ASSAULTS, 90, "weapon_zs_galil")
GM:AddPointShopItem("stalker", ""..translate.Get("ars_stalker"), nil, ITEMCAT_ASSAULTS, 120, "weapon_zs_m4")
GM:AddPointShopItem("inferno", ""..translate.Get("ars_inferno"), nil, ITEMCAT_ASSAULTS, 125, "weapon_zs_inferno")
GM:AddPointShopItem("crossbow", ""..translate.Get("ars_crossbow"), nil, ITEMCAT_ASSAULTS, 140, "weapon_zs_crossbow")
GM:AddPointShopItem("sg552", ""..translate.Get("ars_eliminator"), nil, ITEMCAT_ASSAULTS, 150, "weapon_zs_sg552")

GM:AddPointShopItem("pistolammo", ""..translate.Get("ars_pistol_ammo"), nil, ITEMCAT_AMMO, 3, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["pistol"] or 12, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddPointShopItem("shotgunammo", ""..translate.Get("ars_shotgun_ammo"), nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["buckshot"] or 8, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddPointShopItem("smgammo", ""..translate.Get("ars_smg_ammo"), nil, ITEMCAT_AMMO, 3, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["smg1"] or 30, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddPointShopItem("assaultrifleammo", ""..translate.Get("ars_assaultrifle_ammo"), nil, ITEMCAT_AMMO, 5, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["ar2"] or 30, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddPointShopItem("rifleammo", ""..translate.Get("ars_rifle_ammo"), nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["357"] or 6, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddPointShopItem("crossbowammo", ""..translate.Get("ars_bolt"), nil, ITEMCAT_AMMO, 2, nil, 0, true, nil, function(pl) pl:GiveAmmo(1, "XBowBolt", true) end, "models/Items/CrossbowRounds.mdl")
GM:AddPointShopItem("pulseammo", ""..translate.Get("ars_pulse_ammo"), nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["pulse"] or 30, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")

GM:AddPointShopItem("zpfryp", ""..translate.Get("worth_fryingpan"), nil, ITEMCAT_MELEE, 5, "weapon_zs_fryingpan")
GM:AddPointShopItem("zpcpot", ""..translate.Get("worth_cookingpot"), nil, ITEMCAT_MELEE, 5, "weapon_zs_pot")
GM:AddPointShopItem("knife", ""..translate.Get("worth_knife"), nil, ITEMCAT_MELEE, 5, "weapon_zs_swissarmyknife")
GM:AddPointShopItem("axe", ""..translate.Get("worth_axe"), nil, ITEMCAT_MELEE, 10, "weapon_zs_axe")
GM:AddPointShopItem("hook", ""..translate.Get("worth_meathook"), nil, ITEMCAT_MELEE, 15, "weapon_zs_hook")
GM:AddPointShopItem("crowbar", ""..translate.Get("worth_crowbar"), nil, ITEMCAT_MELEE, 15, "weapon_zs_crowbar")
GM:AddPointShopItem("stunbaton", ""..translate.Get("worth_stun"), nil, ITEMCAT_MELEE, 20, "weapon_zs_stunbaton")
GM:AddPointShopItem("shovel", ""..translate.Get("ars_shovel"), nil, ITEMCAT_MELEE, 20, "weapon_zs_shovel")
GM:AddPointShopItem("zpplnk", ""..translate.Get("worth_plank"), nil, ITEMCAT_MELEE, 20, "weapon_zs_plank")
GM:AddPointShopItem("pipe", ""..translate.Get("worth_leadpipe"), nil, ITEMCAT_MELEE, 25, "weapon_zs_pipe")
GM:AddPointShopItem("sledgehammer", ""..translate.Get("ars_sledge"), nil, ITEMCAT_MELEE, 30, "weapon_zs_sledgehammer")
GM:AddPointShopItem("katana", ""..translate.Get("weapon_katana"), nil, ITEMCAT_MELEE, 50, "weapon_zs_katana")

GM:AddPointShopItem("nail", ""..translate.Get("ars_nail"), ""..translate.Get("ars_nail2"), ITEMCAT_TOOLS, 1, nil, 0, true, nil, function(pl) pl:GiveAmmo(1, "GaussEnergy", true) end, "models/crossbow_bolt.mdl").NoClassicMode = true
GM:AddPointShopItem("msgbeacon", ""..translate.Get("worth_beacon"), nil, ITEMCAT_TOOLS, 1, "weapon_zs_messagebeacon").Countables = "prop_messagebeacon"
GM:AddPointShopItem("spotlamp", ""..translate.Get("worth_spotlamp"), nil, ITEMCAT_TOOLS, 5, "weapon_zs_spotlamp").Countables = "prop_spotlamp"
GM:AddPointShopItem("wrench", ""..translate.Get("worth_wrench"), nil, ITEMCAT_TOOLS, 15, "weapon_zs_wrench").NoClassicMode = true
GM:AddPointShopItem("crphmr", ""..translate.Get("worth_hammer"), nil, ITEMCAT_TOOLS, 20, "weapon_zs_hammer").NoClassicMode = true
GM:AddPointShopItem("arsenalcrate", ""..translate.Get("worth_arsenalcrate"), nil, ITEMCAT_TOOLS, 30, "weapon_zs_arsenalcrate")
GM:AddPointShopItem("resupplybox", ""..translate.Get("worth_resupplybox"), nil, ITEMCAT_TOOLS, 35, "weapon_zs_resupplybox")
GM:AddPointShopItem("50mkit", ""..translate.Get("ars_50meds"), ""..translate.Get("ars_50meds2"), ITEMCAT_TOOLS, 25, nil, 0, true, nil, function(pl) pl:GiveAmmo(50, "Battery", true) end, "models/healthvial.mdl")
GM:AddPointShopItem("manhack", ""..translate.Get("worth_manhack"), nil, ITEMCAT_TOOLS, 30, "weapon_zs_manhack")
GM:AddPointShopItem("medkit", ""..translate.Get("worth_medkit"), nil, ITEMCAT_TOOLS, 35, "weapon_zs_medicalkit")
GM:AddPointShopItem("ffemitter", ""..translate.Get("worth_fieldemiter"), nil, ITEMCAT_TOOLS, 50, "weapon_zs_ffemitter").Countables = "prop_ffemitter"
local propCreator = GM:AddPointShopItem("propcreator", translate.Get("propcreator_name"), translate.Get("propcreator_description"), ITEMCAT_TOOLS, 10, "weapon_zs_propcreator")
propCreator.CanPurchase = function(pl)
	local used = SERVER and GAMEMODE:GetPropCreatorUses(pl) or pl:GetNW2Int("zs_propcreator_used", 0)
	return pl:Team() == TEAM_HUMAN and used < 2
end
propCreator.CantPurchaseMessage = "propcreator_limit"
propCreator.ClientCanPurchase = propCreator.CanPurchase
local handRepair = GM:AddPointShopItem("repairfield", translate.Get("weapon_repairfield"), translate.Get("weapon_repairfield_desc"), ITEMCAT_TOOLS, 75, "weapon_zs_repairfield")
handRepair.NoClassicMode = true
local repairEmitter = GM:AddPointShopItem("repairemitter", translate.Get("worth_repairemitter"), translate.Get("worth_repairemitter_desc"), ITEMCAT_TOOLS, 60, "weapon_zs_repairemitter")
repairEmitter.Countables = "prop_repairemitter"
repairEmitter.NoClassicMode = true
local item = GM:AddPointShopItem("infturret", ""..translate.Get("worth_turret"), nil, ITEMCAT_TOOLS, 65, nil, 0, true, nil, function(pl)
	pl:GiveEmptyWeapon("weapon_zs_gunturret")
	pl:GiveAmmo(1, "thumper")
	pl:GiveAmmo(250, "smg1")
end, "models/combine_turrets/floor_turret.mdl")
item.Countables = {"weapon_zs_gunturret", "prop_gunturret"}
item.NoClassicMode = true
GM:AddPointShopItem("barricadekit", ""..translate.Get("ars_aegis"), nil, ITEMCAT_TOOLS, 70, "weapon_zs_barricadekit")

GM:AddPointShopItem("pstone", ""..translate.Get("worth_stone"), nil, ITEMCAT_OTHER, 3, "weapon_zs_stone")
GM:AddPointShopItem("poxtank", ""..translate.Get("worth_oxygentank"), ""..translate.Get("worth_oxygentank2"), ITEMCAT_OTHER, 5, "weapon_zs_oxygentank")
GM:AddPointShopItem("medxcbomb", ""..translate.Get("ars_mednade"), ""..translate.Get("ars_mednade_desc"), ITEMCAT_OTHER, 5, "weapon_zs_mediccloudbomb")
GM:AddPointShopItem("grenade", ""..translate.Get("ars_grenade"), nil, ITEMCAT_OTHER, 12, "weapon_zs_grenade")
GM:AddPointShopItem("molotov", ""..translate.Get("ars_molotov"), nil, ITEMCAT_OTHER, 20, "weapon_zs_molotov")
GM:AddPointShopItem("detpck", ""..translate.Get("ars_detpack"), nil, ITEMCAT_OTHER, 30, "weapon_zs_detpack")
GM:AddPointShopItem("spinfusor", ""..translate.Get("ars_spinfusor"), nil, ITEMCAT_OTHER, 175, "weapon_zs_spinfusor")
GM:AddPointShopItem("gluongun", ""..translate.Get("ars_helios"), nil, ITEMCAT_OTHER, 200, "weapon_zs_helios")
GM:AddPointShopItem("empower", ""..translate.Get("craft_empower"), nil, ITEMCAT_OTHER, 230, "weapon_zs_empower")

local startingAmmo = {
	["2pcp"] = {Type = "pistol", Multiplier = 3, Default = 12}, ["3pcp"] = {Type = "pistol", Multiplier = 5, Default = 12},
	["2sgcp"] = {Type = "buckshot", Multiplier = 3, Default = 8}, ["3sgcp"] = {Type = "buckshot", Multiplier = 5, Default = 8},
	["2smgcp"] = {Type = "smg1", Multiplier = 3, Default = 30}, ["3smgcp"] = {Type = "smg1", Multiplier = 5, Default = 30},
	["2arcp"] = {Type = "ar2", Multiplier = 3, Default = 30}, ["3arcp"] = {Type = "ar2", Multiplier = 5, Default = 30},
	["2rcp"] = {Type = "357", Multiplier = 3, Default = 6}, ["3rcp"] = {Type = "357", Multiplier = 5, Default = 6},
	["2pls"] = {Type = "pulse", Multiplier = 3, Default = 30}, ["3pls"] = {Type = "pulse", Multiplier = 5, Default = 30},
	["6nails"] = {Type = "GaussEnergy", Amount = 12}, ["150mkit"] = {Type = "Battery", Amount = 150}
}
for signature, grant in pairs(startingAmmo) do
	local item = GM.ItemsBySignature[signature]
	item.WorthAmmo, item.WorthGrantCallback = grant, item.Callback
end
