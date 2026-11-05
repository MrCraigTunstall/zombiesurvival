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

local function LocalizeItem(item, name, description)
	item.NameTranslation, item.DescriptionTranslation = name, description
	item.TranslatedName, item.TranslatedDescription = item.Name, item.Description
	return item
end

function GM:AddLocalizedStartingItem(signature, name, description, ...)
	return LocalizeItem(self:AddStartingItem(signature, translate.Get(name), description and translate.Get(description), ...), name, description)
end

function GM:AddLocalizedPointShopItem(signature, name, description, ...)
	return LocalizeItem(self:AddPointShopItem(signature, translate.Get(name), description and translate.Get(description), ...), name, description)
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
				local key = sweptab.DescriptionTranslation
				tab.Description = key and translate.Get(key) or sweptab.Description
				tab.DescriptionTranslation = key
				tab.TranslatedDescription = tab.Description
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

GM:AddLocalizedStartingItem("pshtr", "worth_peashooter", nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_peashooter")
GM:AddLocalizedStartingItem("btlax", "worth_battleaxe", nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_battleaxe")
GM:AddLocalizedStartingItem("owens", "worth_owens", nil, ITEMCAT_WORTHGUNS, 15, "weapon_zs_owens")
GM:AddLocalizedStartingItem("z9000", "worth_z9000", nil, ITEMCAT_WORTHGUNS, 20, "weapon_zs_z9000")

GM:AddLocalizedStartingItem("blstr", "worth_blaster", nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_blaster")

GM:AddLocalizedStartingItem("tossr", "worth_tosser", nil, ITEMCAT_WORTHGUNS, 20, "weapon_zs_tosser")

GM:AddLocalizedStartingItem("stbbr", "worth_stubber", nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_stubber")

GM:AddLocalizedStartingItem("crklr", "worth_crackler", nil, ITEMCAT_WORTHGUNS, 25, "weapon_zs_crackler")

GM:AddLocalizedStartingItem("2pcp", "worth_3pistol", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pistol"] or 12) * 3, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddLocalizedStartingItem("2sgcp", "worth_3shotgun", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["buckshot"] or 8) * 3, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddLocalizedStartingItem("2smgcp", "worth_3smg", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["smg1"] or 30) * 3, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddLocalizedStartingItem("2arcp", "worth_3assaultrifle", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["ar2"] or 30) * 3, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddLocalizedStartingItem("2rcp", "worth_3rifle", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["357"] or 6) * 3, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddLocalizedStartingItem("2pls", "worth_3pulse", nil, ITEMCAT_AMMO, 7, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pulse"] or 30) * 3, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")
GM:AddLocalizedStartingItem("3pcp", "worth_5pistol", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pistol"] or 12) * 5, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddLocalizedStartingItem("3sgcp", "worth_5shotgun", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["buckshot"] or 8) * 5, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddLocalizedStartingItem("3smgcp", "worth_5smg", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["smg1"] or 30) * 5, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddLocalizedStartingItem("3arcp", "worth_5assaultrifle", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["ar2"] or 30) * 5, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddLocalizedStartingItem("3rcp", "worth_5rifle", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["357"] or 6) * 5, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddLocalizedStartingItem("3pls", "worth_5pulse", nil, ITEMCAT_AMMO, 10, nil, function(pl) pl:GiveAmmo((GAMEMODE.AmmoCache["pulse"] or 30) * 5, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")

GM:AddLocalizedStartingItem("zpfryp", "worth_fryingpan", nil, ITEMCAT_MELEE, 5, "weapon_zs_fryingpan")
GM:AddLocalizedStartingItem("zpcpot", "worth_cookingpot", nil, ITEMCAT_MELEE, 5, "weapon_zs_pot")
GM:AddLocalizedStartingItem("csknf", "worth_knife", nil, ITEMCAT_MELEE, 5, "weapon_zs_swissarmyknife")
GM:AddLocalizedStartingItem("zpaxe", "worth_axe", nil, ITEMCAT_MELEE, 10, "weapon_zs_axe")
GM:AddLocalizedStartingItem("crwbar", "worth_crowbar", nil, ITEMCAT_MELEE, 15, "weapon_zs_crowbar")
GM:AddLocalizedStartingItem("hook", "worth_meathook", nil, ITEMCAT_MELEE, 15, "weapon_zs_hook")
GM:AddLocalizedStartingItem("stnbtn", "worth_stun", nil, ITEMCAT_MELEE, 20, "weapon_zs_stunbaton")
GM:AddLocalizedStartingItem("zpplnk", "worth_plank", nil, ITEMCAT_MELEE, 20, "weapon_zs_plank")
GM:AddLocalizedStartingItem("pipe", "worth_leadpipe", nil, ITEMCAT_MELEE, 25, "weapon_zs_pipe")

GM:AddLocalizedStartingItem("msgbeacon", "worth_beacon", nil, ITEMCAT_TOOLS, 1, "weapon_zs_messagebeacon").Countables = "prop_messagebeacon"
GM:AddLocalizedStartingItem("spotlamp", "worth_spotlamp", nil, ITEMCAT_TOOLS, 5, "weapon_zs_spotlamp").Countables = "prop_spotlamp"
GM:AddLocalizedStartingItem("6nails", "worth_6nails", "worth_6nails2", ITEMCAT_TOOLS, 12, nil, function(pl) pl:GiveAmmo(12, "GaussEnergy", true) end, "models/Items/BoxMRounds.mdl")
GM:AddLocalizedStartingItem("wrench", "worth_wrench", nil, ITEMCAT_TOOLS, 15, "weapon_zs_wrench").NoClassicMode = true
GM:AddLocalizedStartingItem("crphmr", "worth_hammer", nil, ITEMCAT_TOOLS, 15, "weapon_zs_hammer").NoClassicMode = true
GM:AddLocalizedStartingItem("arscrate", "worth_arsenalcrate", nil, ITEMCAT_TOOLS, 15, "weapon_zs_arsenalcrate").Countables = "prop_arsenalcrate"
GM:AddLocalizedStartingItem("150mkit", "worth_150meds", "worth_150meds2", ITEMCAT_TOOLS, 15, nil, function(pl) pl:GiveAmmo(150, "Battery", true) end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("medkit", "worth_medkit", nil, ITEMCAT_TOOLS, 20, "weapon_zs_medicalkit")
GM:AddLocalizedStartingItem("junkpack", "worth_junkpack", nil, ITEMCAT_TOOLS, 20, "weapon_zs_boardpack")
GM:AddLocalizedStartingItem("medgun", "worth_medgun", nil, ITEMCAT_TOOLS, 25, "weapon_zs_medicgun")
local item = GM:AddLocalizedStartingItem("manhack", "worth_manhack", nil, ITEMCAT_TOOLS, 20, "weapon_zs_manhack")
item.Countables = "prop_manhack"
GM:AddLocalizedStartingItem("resupplybox", "worth_resupplybox", nil, ITEMCAT_TOOLS, 30, "weapon_zs_resupplybox").Countables = "prop_resupplybox"
GM:AddLocalizedStartingItem("ffemitter", "worth_fieldemiter", nil, ITEMCAT_TOOLS, 50, "weapon_zs_ffemitter").Countables = "prop_ffemitter"
local handRepair = GM:AddLocalizedStartingItem("repairfield", "weapon_repairfield", "weapon_repairfield_desc", ITEMCAT_TOOLS, 50, "weapon_zs_repairfield")
handRepair.NoClassicMode = true
local repairEmitter = GM:AddLocalizedStartingItem("repairemitter", "worth_repairemitter", "worth_repairemitter_desc", ITEMCAT_TOOLS, 50, "weapon_zs_repairemitter")
repairEmitter.Countables = "prop_repairemitter"
repairEmitter.NoClassicMode = true
local item = GM:AddLocalizedStartingItem("infturret", "worth_turret", "worth_turret2",
	ITEMCAT_TOOLS, 65, nil, function(pl)
	pl:GiveEmptyWeapon("weapon_zs_gunturret")
	pl:GiveAmmo(1, "thumper")
	pl:GiveAmmo(250, "smg1")
end, "models/combine_turrets/floor_turret.mdl")
item.Countables = {"weapon_zs_gunturret", "prop_gunturret"}
item.NoClassicMode = true
item.WorthGrant = {Weapon = "weapon_zs_gunturret", Empty = true, Ammo = {{Type = "thumper", Amount = 1}, {Type = "smg1", Amount = 250}}}
item.WorthGrantCallback = item.Callback

GM:AddLocalizedStartingItem("stone", "worth_stone", nil, ITEMCAT_OTHER, 0, "weapon_zs_stone")
GM:AddLocalizedStartingItem("oxtank", "worth_oxygentank", "worth_oxygentank2", ITEMCAT_OTHER, 1, "weapon_zs_oxygentank")
GM:AddLocalizedStartingItem("medxcbomb", "ars_mednade", "ars_mednade_desc", ITEMCAT_OTHER, 10, "weapon_zs_mediccloudbomb")

GM:AddLocalizedStartingItem("10hp", "worth_fit", "worth_fit2", ITEMCAT_TRAITS, 10, nil, function(pl) pl:SetMaxHealth(pl:GetMaxHealth() + 10) pl:SetHealth(pl:Health() + 10) end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("25hp", "worth_tough", "worth_tough2", ITEMCAT_TRAITS, 20, nil, function(pl) pl:SetMaxHealth(pl:GetMaxHealth() + 25) pl:SetHealth(pl:Health() + 25) end, "models/items/healthkit.mdl")
local item = GM:AddLocalizedStartingItem("5spd", "worth_quick", "worth_quick2", ITEMCAT_TRAITS, 10, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) + 7 pl:ResetSpeed() end, "models/props_lab/jar01a.mdl")
item.NoClassicMode = true
item.NoZombieEscape = true
local item = GM:AddLocalizedStartingItem("10spd", "worth_surged", "worth_surged2", ITEMCAT_TRAITS, 20, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) + 14 pl:ResetSpeed() end, "models/props_lab/jar01a.mdl")
item.NoClassicMode = true
item.NoZombieEscape = true
GM:AddLocalizedStartingItem("bfsurgeon", "worth_surgeon", "worth_surgeon2", ITEMCAT_TRAITS, 10, nil, function(pl) pl.HumanHealMultiplier = (pl.HumanHealMultiplier or 1) + 0.3 end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bfmedicine", "worth_medicine", "worth_medicine2", ITEMCAT_TRAITS, 20, nil, function(pl) pl.HumanHealMultiplier = (pl.HumanHealMultiplier or 1) + 1.0 end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bfresist", "worth_resistant", "worth_resistant2", ITEMCAT_TRAITS, 15, nil, function(pl) pl.BuffResistant = true end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bfregen", "worth_regen", "worth_regen2", ITEMCAT_TRAITS, 20, nil, function(pl) pl.BuffRegenerative = true end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bfhandy", "worth_handy", "worth_handy2", ITEMCAT_TRAITS, 25, nil, function(pl) pl.HumanRepairMultiplier = (pl.HumanRepairMultiplier or 1) + 0.25 end, "models/props_c17/tools_wrench01a.mdl")
GM:AddLocalizedStartingItem("bfengineer", "worth_engi", "worth_engi2", ITEMCAT_TRAITS, 35, nil, function(pl) pl.HumanRepairMultiplier = (pl.HumanRepairMultiplier or 1) + 0.50 end, "models/props_c17/tools_wrench01a.mdl")
GM:AddLocalizedStartingItem("bfmusc", "worth_muscular","worth_muscular2", ITEMCAT_TRAITS, 25, nil, function(pl) pl.BuffMuscular = true pl:DoMuscularBones() end, "models/props_wasteland/kitchen_shelf001a.mdl")
GM:AddLocalizedStartingItem("bfcarpenter", "worth_carpenter", "worth_carpenter2", ITEMCAT_TRAITS, 35, nil, function(pl) pl.Carpenter = true end, "models/weapons/w_hammer.mdl")
GM:AddLocalizedStartingItem("bfcannibal", "worth_cannibal", "worth_cannibal2", ITEMCAT_TRAITS, 30, nil, function(pl) pl.Cannibal = true end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("bfghostmode", "worth_ghostmode", "worth_ghostmode2", ITEMCAT_TRAITS, 15, nil, function(pl) GAMEMODE:SetBarricadeGhostPolicy(pl, pl.NoGhosting, true) end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bffastresupply", "worth_fastresupply", "worth_fastresupply2", ITEMCAT_TRAITS, 20, nil, function(pl) pl.FastResupply = true end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bffastteleport", "worth_fastteleport", "worth_fastteleport2", ITEMCAT_TRAITS, 20, nil, function(pl) pl.FastTeleport = true end, "models/healthvial.mdl")
GM:AddLocalizedStartingItem("bfcrateshare", "worth_crateshare", "worth_crateshare2", ITEMCAT_TRAITS, 25, nil, function(pl) pl.CrateShare = true end, "models/healthvial.mdl")

GM:AddLocalizedStartingItem("dbfallergic", "worth_allergic", "worth_allergic2", ITEMCAT_RETURNS, -30, nil, function(pl) pl.Allergic = true end, "models/gibs/hgibs_spine.mdl")
GM:AddLocalizedStartingItem("dbfpalsy", "worth_palasy", "worth_palasy2", ITEMCAT_RETURNS, -10, nil, function(pl) pl:SetPalsy(true) end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfnopickup", "worth_noodlearms", "worth_noodlearms2", ITEMCAT_RETURNS, -15, nil, function(pl) pl.NoObjectPickup = true pl:DoNoodleArmBones() end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfhemo", "worth_hemo", "worth_hemo2", ITEMCAT_RETURNS, -15, nil, function(pl) pl:SetHemophilia(true) end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfweak", "worth_weak", "worth_weak2", ITEMCAT_RETURNS, -20, nil, function(pl) pl:SetMaxHealth(math.max(1, pl:GetMaxHealth() - 30)) pl:SetHealth(pl:GetMaxHealth()) pl.IsWeak = true end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfnoghosting", "worth_wideload", "worth_wideload2", ITEMCAT_RETURNS, -25, nil, function(pl) GAMEMODE:SetBarricadeGhostPolicy(pl, true, pl.GhostCade) end, "models/gibs/HGIBS.mdl").NoClassicMode = true
GM:AddLocalizedStartingItem("dbfslow", "worth_slow", "worth_slow2", ITEMCAT_RETURNS, -30, nil, function(pl) pl.HumanSpeedAdder = (pl.HumanSpeedAdder or 0) - 20 pl:ResetSpeed() pl.IsSlow = true end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfclumsy", "worth_clumsy", "worth_clumsy2", ITEMCAT_RETURNS, -30, nil, function(pl) pl.Clumsy = true end, "models/gibs/HGIBS.mdl")
GM:AddLocalizedStartingItem("dbfunluc", "worth_banlive", "worth_banlive2", ITEMCAT_RETURNS, -40, nil, function(pl) pl:SetUnlucky(true) end, "models/gibs/HGIBS.mdl")

GM:AddLocalizedPointShopItem("deagle", "ars_deagle", nil, ITEMCAT_HANDGUNS, 30, "weapon_zs_deagle")
GM:AddLocalizedPointShopItem("glock3", "ars_glock", nil, ITEMCAT_HANDGUNS, 30, "weapon_zs_glock3")
GM:AddLocalizedPointShopItem("magnum", "ars_magnum", nil, ITEMCAT_HANDGUNS, 35, "weapon_zs_magnum")
GM:AddLocalizedPointShopItem("eraser", "ars_tacticalpistol", nil, ITEMCAT_HANDGUNS, 35, "weapon_zs_eraser")
GM:AddLocalizedPointShopItem("python", "weapon_python", nil, ITEMCAT_HANDGUNS, 95, "weapon_zs_python")

GM:AddLocalizedPointShopItem("ender", "ars_autoen", nil, ITEMCAT_SHOTGUNS, 85, "weapon_zs_ender")
GM:AddLocalizedPointShopItem("sweeper", "ars_sweeper", nil, ITEMCAT_SHOTGUNS, 170, "weapon_zs_sweepershotgun")
GM:AddLocalizedPointShopItem("boomstick", "ars_boomstick", nil, ITEMCAT_SHOTGUNS, 250, "weapon_zs_boomstick")

GM:AddLocalizedPointShopItem("uzi", "ars_uzi", nil, ITEMCAT_SMG, 70, "weapon_zs_uzi")
GM:AddLocalizedPointShopItem("shredder", "ars_shredder", nil, ITEMCAT_SMG, 70, "weapon_zs_smg")
GM:AddLocalizedPointShopItem("bulletstorm", "ars_bulletstorm", nil, ITEMCAT_SMG, 70, "weapon_zs_bulletstorm")
GM:AddLocalizedPointShopItem("reaper", "ars_reaperump", nil, ITEMCAT_SMG, 80, "weapon_zs_reaper")
GM:AddLocalizedPointShopItem("silencer", "ars_silencer", nil, ITEMCAT_SMG, 100, "weapon_zs_silencer")
GM:AddLocalizedPointShopItem("m249", "ars_punisher", nil, ITEMCAT_SMG, 230, "weapon_zs_m249")

GM:AddLocalizedPointShopItem("hunter", "ars_hunter", nil, ITEMCAT_RIFLES, 70, "weapon_zs_hunter")
GM:AddLocalizedPointShopItem("annabelle", "ars_annabele", nil, ITEMCAT_RIFLES, 100, "weapon_zs_annabelle")
GM:AddLocalizedPointShopItem("g3sg1", "ars_infiltrator", nil, ITEMCAT_RIFLES, 110, "weapon_zs_g3sg1")
GM:AddLocalizedPointShopItem("slugrifle", "ars_tiny", nil, ITEMCAT_RIFLES, 200, "weapon_zs_slugrifle")
GM:AddLocalizedPointShopItem("pulserifle", "ars_adonis", nil, ITEMCAT_RIFLES, 230, "weapon_zs_pulserifle")
GM:AddLocalizedPointShopItem("sg550", "ars_killer", nil, ITEMCAT_RIFLES, 240, "weapon_zs_sg550")

GM:AddLocalizedPointShopItem("akbar", "ars_akbar", nil, ITEMCAT_ASSAULTS, 85, "weapon_zs_akbar")
GM:AddLocalizedPointShopItem("galil", "ars_galil", nil, ITEMCAT_ASSAULTS, 90, "weapon_zs_galil")
GM:AddLocalizedPointShopItem("stalker", "ars_stalker", nil, ITEMCAT_ASSAULTS, 120, "weapon_zs_m4")
GM:AddLocalizedPointShopItem("inferno", "ars_inferno", nil, ITEMCAT_ASSAULTS, 125, "weapon_zs_inferno")
GM:AddLocalizedPointShopItem("crossbow", "ars_crossbow", nil, ITEMCAT_ASSAULTS, 140, "weapon_zs_crossbow")
GM:AddLocalizedPointShopItem("sg552", "ars_eliminator", nil, ITEMCAT_ASSAULTS, 150, "weapon_zs_sg552")

GM:AddLocalizedPointShopItem("pistolammo", "ars_pistol_ammo", nil, ITEMCAT_AMMO, 3, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["pistol"] or 12, "pistol", true) end, "models/Items/BoxSRounds.mdl")
GM:AddLocalizedPointShopItem("shotgunammo", "ars_shotgun_ammo", nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["buckshot"] or 8, "buckshot", true) end, "models/Items/BoxBuckshot.mdl")
GM:AddLocalizedPointShopItem("smgammo", "ars_smg_ammo", nil, ITEMCAT_AMMO, 3, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["smg1"] or 30, "smg1", true) end, "models/Items/BoxMRounds.mdl")
GM:AddLocalizedPointShopItem("assaultrifleammo", "ars_assaultrifle_ammo", nil, ITEMCAT_AMMO, 5, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["ar2"] or 30, "ar2", true) end, "models/Items/357ammobox.mdl")
GM:AddLocalizedPointShopItem("rifleammo", "ars_rifle_ammo", nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["357"] or 6, "357", true) end, "models/Items/BoxSniperRounds.mdl")
GM:AddLocalizedPointShopItem("crossbowammo", "ars_bolt", nil, ITEMCAT_AMMO, 2, nil, 0, true, nil, function(pl) pl:GiveAmmo(1, "XBowBolt", true) end, "models/Items/CrossbowRounds.mdl")
GM:AddLocalizedPointShopItem("pulseammo", "ars_pulse_ammo", nil, ITEMCAT_AMMO, 4, nil, 0, true, nil, function(pl) pl:GiveAmmo(GAMEMODE.AmmoCache["pulse"] or 30, "pulse", true) end, "models/Items/combine_rifle_ammo01.mdl")

GM:AddLocalizedPointShopItem("zpfryp", "worth_fryingpan", nil, ITEMCAT_MELEE, 5, "weapon_zs_fryingpan")
GM:AddLocalizedPointShopItem("zpcpot", "worth_cookingpot", nil, ITEMCAT_MELEE, 5, "weapon_zs_pot")
GM:AddLocalizedPointShopItem("knife", "worth_knife", nil, ITEMCAT_MELEE, 5, "weapon_zs_swissarmyknife")
GM:AddLocalizedPointShopItem("axe", "worth_axe", nil, ITEMCAT_MELEE, 10, "weapon_zs_axe")
GM:AddLocalizedPointShopItem("hook", "worth_meathook", nil, ITEMCAT_MELEE, 15, "weapon_zs_hook")
GM:AddLocalizedPointShopItem("crowbar", "worth_crowbar", nil, ITEMCAT_MELEE, 15, "weapon_zs_crowbar")
GM:AddLocalizedPointShopItem("stunbaton", "worth_stun", nil, ITEMCAT_MELEE, 20, "weapon_zs_stunbaton")
GM:AddLocalizedPointShopItem("shovel", "ars_shovel", nil, ITEMCAT_MELEE, 20, "weapon_zs_shovel")
GM:AddLocalizedPointShopItem("zpplnk", "worth_plank", nil, ITEMCAT_MELEE, 20, "weapon_zs_plank")
GM:AddLocalizedPointShopItem("pipe", "worth_leadpipe", nil, ITEMCAT_MELEE, 25, "weapon_zs_pipe")
GM:AddLocalizedPointShopItem("sledgehammer", "ars_sledge", nil, ITEMCAT_MELEE, 30, "weapon_zs_sledgehammer")
GM:AddLocalizedPointShopItem("katana", "weapon_katana", nil, ITEMCAT_MELEE, 50, "weapon_zs_katana")

GM:AddLocalizedPointShopItem("nail", "ars_nail", "ars_nail2", ITEMCAT_TOOLS, 1, nil, 0, true, nil, function(pl) pl:GiveAmmo(1, "GaussEnergy", true) end, "models/crossbow_bolt.mdl").NoClassicMode = true
GM:AddLocalizedPointShopItem("msgbeacon", "worth_beacon", nil, ITEMCAT_TOOLS, 1, "weapon_zs_messagebeacon").Countables = "prop_messagebeacon"
GM:AddLocalizedPointShopItem("spotlamp", "worth_spotlamp", nil, ITEMCAT_TOOLS, 5, "weapon_zs_spotlamp").Countables = "prop_spotlamp"
GM:AddLocalizedPointShopItem("wrench", "worth_wrench", nil, ITEMCAT_TOOLS, 15, "weapon_zs_wrench").NoClassicMode = true
GM:AddLocalizedPointShopItem("crphmr", "worth_hammer", nil, ITEMCAT_TOOLS, 20, "weapon_zs_hammer").NoClassicMode = true
GM:AddLocalizedPointShopItem("arsenalcrate", "worth_arsenalcrate", nil, ITEMCAT_TOOLS, 30, "weapon_zs_arsenalcrate")
GM:AddLocalizedPointShopItem("resupplybox", "worth_resupplybox", nil, ITEMCAT_TOOLS, 35, "weapon_zs_resupplybox")
GM:AddLocalizedPointShopItem("50mkit", "ars_50meds", "ars_50meds2", ITEMCAT_TOOLS, 25, nil, 0, true, nil, function(pl) pl:GiveAmmo(50, "Battery", true) end, "models/healthvial.mdl")
GM:AddLocalizedPointShopItem("manhack", "worth_manhack", nil, ITEMCAT_TOOLS, 30, "weapon_zs_manhack")
GM:AddLocalizedPointShopItem("medkit", "worth_medkit", nil, ITEMCAT_TOOLS, 35, "weapon_zs_medicalkit")
GM:AddLocalizedPointShopItem("ffemitter", "worth_fieldemiter", nil, ITEMCAT_TOOLS, 50, "weapon_zs_ffemitter").Countables = "prop_ffemitter"
local propCreator = GM:AddLocalizedPointShopItem("propcreator", "propcreator_name", "propcreator_description", ITEMCAT_TOOLS, 10, "weapon_zs_propcreator")
propCreator.CanPurchase = function(pl)
	local used = SERVER and GAMEMODE:GetPropCreatorUses(pl) or pl:GetNW2Int("zs_propcreator_used", 0)
	return pl:Team() == TEAM_HUMAN and used < 2
end
propCreator.CantPurchaseMessage = "propcreator_limit"
propCreator.ClientCanPurchase = propCreator.CanPurchase
local handRepair = GM:AddLocalizedPointShopItem("repairfield", "weapon_repairfield", "weapon_repairfield_desc", ITEMCAT_TOOLS, 75, "weapon_zs_repairfield")
handRepair.NoClassicMode = true
local repairEmitter = GM:AddLocalizedPointShopItem("repairemitter", "worth_repairemitter", "worth_repairemitter_desc", ITEMCAT_TOOLS, 60, "weapon_zs_repairemitter")
repairEmitter.Countables = "prop_repairemitter"
repairEmitter.NoClassicMode = true
local item = GM:AddLocalizedPointShopItem("infturret", "worth_turret", nil, ITEMCAT_TOOLS, 65, nil, 0, true, nil, function(pl)
	pl:GiveEmptyWeapon("weapon_zs_gunturret")
	pl:GiveAmmo(1, "thumper")
	pl:GiveAmmo(250, "smg1")
end, "models/combine_turrets/floor_turret.mdl")
item.Countables = {"weapon_zs_gunturret", "prop_gunturret"}
item.NoClassicMode = true
GM:AddLocalizedPointShopItem("barricadekit", "ars_aegis", nil, ITEMCAT_TOOLS, 70, "weapon_zs_barricadekit")

GM:AddLocalizedPointShopItem("pstone", "worth_stone", nil, ITEMCAT_OTHER, 3, "weapon_zs_stone")
GM:AddLocalizedPointShopItem("poxtank", "worth_oxygentank", "worth_oxygentank2", ITEMCAT_OTHER, 5, "weapon_zs_oxygentank")
GM:AddLocalizedPointShopItem("medxcbomb", "ars_mednade", "ars_mednade_desc", ITEMCAT_OTHER, 5, "weapon_zs_mediccloudbomb")
GM:AddLocalizedPointShopItem("grenade", "ars_grenade", nil, ITEMCAT_OTHER, 12, "weapon_zs_grenade")
GM:AddLocalizedPointShopItem("molotov", "ars_molotov", nil, ITEMCAT_OTHER, 20, "weapon_zs_molotov")
GM:AddLocalizedPointShopItem("detpck", "ars_detpack", nil, ITEMCAT_OTHER, 30, "weapon_zs_detpack")
GM:AddLocalizedPointShopItem("spinfusor", "ars_spinfusor", nil, ITEMCAT_OTHER, 175, "weapon_zs_spinfusor")
GM:AddLocalizedPointShopItem("gluongun", "ars_helios", nil, ITEMCAT_OTHER, 200, "weapon_zs_helios")
GM:AddLocalizedPointShopItem("empower", "craft_empower", nil, ITEMCAT_OTHER, 230, "weapon_zs_empower")

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
