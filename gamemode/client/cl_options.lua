GM.BeatSetHumanDefault = "zsrhuman"
GM.BeatSetZombieDefault = "zsrzombie"

GM.ItemCategoryIcons = {
	[ITEMCAT_WORTHGUNS] = "icon16/gun.png",
	[ITEMCAT_HANDGUNS] = "icon16/gun.png",
	[ITEMCAT_SHOTGUNS] = "icon16/gun.png",
	[ITEMCAT_SMG] = "icon16/gun.png",
	[ITEMCAT_ASSAULTS] = "icon16/gun.png",
	[ITEMCAT_RIFLES] = "icon16/gun.png",
	[ITEMCAT_AMMO] = "icon16/box.png",
	[ITEMCAT_MELEE] = "icon16/cog.png",
	[ITEMCAT_TOOLS] = "icon16/wrench.png",
	[ITEMCAT_OTHER] = "icon16/world.png",
	[ITEMCAT_TRAITS] = "icon16/user_add.png",
	[ITEMCAT_RETURNS] = "icon16/user_delete.png",
	[ITEMCAT_MUTATIONS] = "icon16/pill.png",
	[ITEMCAT_MUTATIONS_BOSS] = "icon16/pill_add.png"
}
GM.LifeStatsLifeTime = 5

GM.RewardIcons = {}
GM.RewardIcons["weapon_zs_barricadekit"] = "models/props_debris/wood_board05a.mdl"

local function Number(default, minimum, maximum, integer, scale)
	return function(_, value)
		value = tonumber(value)
		if not value or value ~= value or value == math.huge or value == -math.huge then value = default end
		value = math.Clamp(value, minimum, maximum)
		if integer then value = math.floor(value) end
		return scale and value / scale or value
	end
end

local function Boolean(convar)
	return convar:GetBool()
end

local function Bind(name, default, field, read, changed, channel)
	local convar = CreateClientConVar(name, tostring(default), true, false)
	local function Apply(gm, value, initial)
		if channel then gm[field][channel] = value return end
		if gm[field] == value then return end
		gm[field] = value
		if changed and not initial then gm[changed](gm) end
	end
	Apply(GM, read(convar, convar:GetString(), GM), true)
	cvars.AddChangeCallback(name, function(_, _, value)
		Apply(GAMEMODE, read(convar, value, GAMEMODE))
	end, "ZSClientOption_" .. name)
end

GM.CrosshairColor, GM.CrosshairColor2 = Color(255, 255, 255, 220), Color(220, 0, 0, 220)
for _, entry in ipairs({
	{"zs_crosshair_colr", 255, "CrosshairColor", "r"},
	{"zs_crosshair_colg", 255, "CrosshairColor", "g"},
	{"zs_crosshair_colb", 255, "CrosshairColor", "b"},
	{"zs_crosshair_colr2", 220, "CrosshairColor2", "r"},
	{"zs_crosshair_colg2", 0, "CrosshairColor2", "g"},
	{"zs_crosshair_colb2", 0, "CrosshairColor2", "b"}
}) do
	Bind(entry[1], entry[2], entry[3], Number(entry[2], 0, 255, true), nil, entry[4])
end

Bind("zs_filmmode", 0, "FilmMode", Boolean, "EvaluateFilmMode")
Bind("zs_suicideonchange", 1, "SuicideOnChangeClass", Boolean)
Bind("zs_beats", 1, "BeatsEnabled", Boolean)
Bind("zs_alwaysshownails", 0, "AlwaysShowNails", Boolean)
Bind("zs_oldbaseoutlinedhud", 0, "OldBaseOutlinedHUD", Boolean)
Bind("zs_nocrosshairrotate", 0, "NoCrosshairRotate", Boolean)
Bind("zs_movementviewroll", 1, "MovementViewRoll", Boolean)
Bind("zs_drawpainflash", 1, "DrawPainFlash", Boolean)
Bind("zs_beatsvolume", 80, "BeatsVolume", Number(80, 0, 100, false, 100))
Bind("zs_transparencyradius", 140, "TransparencyRadius", Number(140, 0, 512))
Bind("zs_proprotationsnap", 0, "PropRotationSnap", Number(0, 0, 45))
Bind("zs_proprotationsens", 1, "PropRotationSensitivity", Number(1, 0.1, 4))
Bind("zs_weaponhudmode", 0, "WeaponHUDMode", function(_, value)
	value = tonumber(value)
	return value == 1 and 1 or value == 2 and 2 or 0
end)

for _, entry in ipairs({
	{"zs_noarscrate", "0", true},
	{"zs_nostatusarscrate", "0", true},
	{"zs_noresupply", "0", true},
	{"zs_noredeem", "0", true},
	{"zs_nobandit", "0", true},
	{"zs_alwaysvolunteer", "0", true},
	{"zs_nobosspick", "0", true},
	{"zs_intro", "1", true},
	{"zs_classichud", "0", false},
	{"zs_nodiscord", "0", true}
}) do
	CreateClientConVar(entry[1], entry[2], true, entry[3])
end

CreateConVar("cl_playercolor", "0.24 0.34 0.41", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "The value is a Vector - so between 0-1 - not between 0-255")
CreateConVar("cl_weaponcolor", "0.30 1.80 2.10", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "The value is a Vector - so between 0-1 - not between 0-255")

Bind("zs_beatset_human", "default", "BeatSetHuman", function(_, value, gm)
	return value == "default" and gm.BeatSetHumanDefault or tostring(value)
end)
Bind("zs_beatset_zombie", "default", "BeatSetZombie", function(_, value, gm)
	return value == "default" and gm.BeatSetZombieDefault or tostring(value)
end)
