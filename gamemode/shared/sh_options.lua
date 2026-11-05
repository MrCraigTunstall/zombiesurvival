--[[version 1.4
You must be running the latest version of ZS:R (being Version 8 - Mutation System)
for this file to be working. 
Also you need version at least 1.4 of this file for the current ZS:R version
listed or the client can not buy certain items such as ammo types.]]--

GM.ZombieEscapeWeapons = {
	"weapon_zs_zeakbar",
	"weapon_zs_zesweeper",
	"weapon_zs_zesmg",
	"weapon_zs_zestubber",
	"weapon_zs_zebulletstorm"
}

GM.ZombieEscapeWeapons2 = {
	"weapon_zs_zedeagle"
}

-- Change this if you plan to alter the cost of items or you severely change how Worth works.
-- Having separate cart files allows people to have separate loadouts for different servers.
GM.CartFile = "zsrmct.txt"

ITEMCAT_WORTHGUNS = 1
ITEMCAT_HANDGUNS = 2
ITEMCAT_SHOTGUNS = 3
ITEMCAT_SMG = 4
ITEMCAT_ASSAULTS = 5
ITEMCAT_RIFLES = 6
ITEMCAT_AMMO = 7
ITEMCAT_MELEE = 8
ITEMCAT_TOOLS = 9
ITEMCAT_OTHER = 10
ITEMCAT_TRAITS = 11
ITEMCAT_RETURNS = 12
ITEMCAT_MUTATIONS = 13
ITEMCAT_MUTATIONS_BOSS = 14

GM.ItemCategories = {
	[ITEMCAT_WORTHGUNS]			= ""..translate.Get("title_worthguns"),
	[ITEMCAT_HANDGUNS]			= ""..translate.Get("title_guns"),
	[ITEMCAT_SHOTGUNS]			= ""..translate.Get("title_shotguns"),
	[ITEMCAT_SMG]				= ""..translate.Get("title_smg"),
	[ITEMCAT_ASSAULTS]			= ""..translate.Get("title_assault"),
	[ITEMCAT_RIFLES]			= ""..translate.Get("title_rifles"),
	[ITEMCAT_AMMO]				= ""..translate.Get("title_ammo"),
	[ITEMCAT_MELEE]				= ""..translate.Get("title_melee"),
	[ITEMCAT_TOOLS]				= ""..translate.Get("title_tools"),
	[ITEMCAT_OTHER]				= ""..translate.Get("title_other"),
	[ITEMCAT_TRAITS]			= ""..translate.Get("title_traits"),
	[ITEMCAT_RETURNS]			= ""..translate.Get("title_returns"),
	[ITEMCAT_MUTATIONS]			= ""..translate.Get("title_classm"),
	[ITEMCAT_MUTATIONS_BOSS]	= ""..translate.Get("title_bossm")
}

GM.SellableCategories = {
	[ITEMCAT_HANDGUNS]	= true,
	[ITEMCAT_SHOTGUNS]	= true,
	[ITEMCAT_SMG]		= true,
	[ITEMCAT_ASSAULTS]	= true,
	[ITEMCAT_RIFLES]	= true,
	[ITEMCAT_MELEE]		= true
}

--[[
Humans select what weapons (or other things) they want to start with and can even save favorites. Each object has a number of 'Worth' points.
Signature is a unique signature to give in case the item is renamed or reordered. Don't use a number or a string number!
A human can only use 100 points (default) when they join. Redeeming or joining late starts you out with a random loadout from above.
SWEP is a swep given when the player spawns with that perk chosen.
Callback is a function called. Model is a display model. If model isn't defined then the SWEP model will try to be used.
swep, callback, and model can all be nil or empty
]]
include("sh_itemcatalogue.lua")

-- These are the honorable mentions that come at the end of the round.

local function genericcallback(pl, magnitude) return pl:Name(), magnitude end
GM.HonorableMentions = {}
GM.HonorableMentions[HM_MOSTZOMBIESKILLED] = {Name = ""..translate.Get("hm_most_zombies_killed"), String = ""..translate.Get("hm_most_zombies_killed2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_MOSTDAMAGETOUNDEAD] = {Name = ""..translate.Get("hm_most_dmg_undead"), String = ""..translate.Get("hm_most_dmg_undead2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_PACIFIST] = {Name = ""..translate.Get("hm_pacifist"), String = ""..translate.Get("hm_pacifist2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_MOSTHELPFUL] = {Name = ""..translate.Get("hm_most_helpful"), String = ""..translate.Get("hm_most_helpful2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_LASTHUMAN] = {Name = ""..translate.Get("hm_last_human"), String = ""..translate.Get("hm_last_human2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_OUTLANDER] = {Name = ""..translate.Get("hm_outlander"), String = ""..translate.Get("hm_outlander2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_GOODDOCTOR] = {Name = ""..translate.Get("hm_good_doctor"), String = ""..translate.Get("hm_good_doctor2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_HANDYMAN] = {Name = ""..translate.Get("hm_handy_man"), String = ""..translate.Get("hm_handy_man2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_SCARECROW] = {Name = ""..translate.Get("hm_scarecrow"), String = ""..translate.Get("hm_scarecrow2"), Callback = genericcallback, Color = COLOR_WHITE}
GM.HonorableMentions[HM_MOSTBRAINSEATEN] = {Name = ""..translate.Get("hm_most_brains_eaten"), String = ""..translate.Get("hm_most_brains_eaten2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_MOSTDAMAGETOHUMANS] = {Name = ""..translate.Get("hm_most_dmg_tohumans"), String = ""..translate.Get("hm_most_dmg_tohumans2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_LASTBITE] = {Name = ""..translate.Get("hm_last_bite"), String = ""..translate.Get("hm_last_bite2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_USEFULTOOPPOSITE] = {Name = ""..translate.Get("hm_most_useful"), String = ""..translate.Get("hm_most_useful2"), Callback = genericcallback, Color = COLOR_RED}
GM.HonorableMentions[HM_STUPID] = {Name = ""..translate.Get("hm_stupid"), String = ""..translate.Get("hm_stupid2"), Callback = genericcallback, Color = COLOR_RED}
GM.HonorableMentions[HM_SALESMAN] = {Name = ""..translate.Get("hm_salesman"), String = ""..translate.Get("hm_salesman2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_WAREHOUSE] = {Name = ""..translate.Get("hm_warehouse"), String = ""..translate.Get("hm_warehouse2"), Callback = genericcallback, Color = COLOR_CYAN}
GM.HonorableMentions[HM_SPAWNPOINT] = {Name = ""..translate.Get("hm_spawn_point"), String = ""..translate.Get("hm_spawn_point2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_CROWFIGHTER] = {Name = ""..translate.Get("hm_crow_fighter"), String = ""..translate.Get("hm_crow_fighter2"), Callback = genericcallback, Color = COLOR_WHITE}
GM.HonorableMentions[HM_CROWBARRICADEDAMAGE] = {Name = ""..translate.Get("hm_minor_annoyance"), String = ""..translate.Get("hm_minor_annoyance2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_BARRICADEDESTROYER] = {Name = ""..translate.Get("hm_barricade_destroyer"), String = ""..translate.Get("hm_barricade_destroyer2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_NESTDESTROYER] = {Name = ""..translate.Get("hm_nest_destroyer"), String = ""..translate.Get("hm_nest_destroyer2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}
GM.HonorableMentions[HM_NESTMASTER] = {Name = ""..translate.Get("hm_nest_master"), String = ""..translate.Get("hm_nest_master2"), Callback = genericcallback, Color = COLOR_LIMEGREEN}

-- Don't let humans use these models because they look like undead models. Must be lower case.
GM.RestrictedModels = {
	"models/player/zombie_classic.mdl",
	"models/player/zombie_classic_hbfix.mdl",
	"models/player/zombine.mdl",
	"models/player/zombie_soldier.mdl",
	"models/player/zombie_fast.mdl",
	"models/zombie/fast_v3.mdl",
	"models/player/corpse1.mdl",
	"models/player/charple.mdl",
	"models/zs_undertaker/undertaker.mdl",
	"models/player/skeleton.mdl"
}

GM.DonatorModels = { -- not yet supported

}

GM.SteamIDAndModels = { -- not yet supported

}

-- If a person has no player model then use one of these (auto-generated).
GM.RandomPlayerModels = {}
local restrictedModels = {}
for _, model in pairs(GM.RestrictedModels) do restrictedModels[model] = true end
for name, mdl in pairs(player_manager.AllValidModels()) do
	if not restrictedModels[string.lower(mdl)] then
		table.insert(GM.RandomPlayerModels, name)
	end
end

local function NumericOption(value, fallback, maximum, integer)
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then number = fallback end
	number = math.max(0, maximum and math.min(maximum, number) or number)
	if integer then return math.floor(number) end
	local scaled = 100 * number
	if scaled == math.huge then return fallback end
	local lower = math.floor(scaled)
	return (scaled - lower <= scaled * 2.220446049250313e-16 and lower or lower + 1) * 0.01
end

GM.DefaultRedeem = NumericOption(CreateConVar("zs_redeem", "4", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Kills required to redeem. Nonnegative whole number; 0 disables redemption."):GetString(), 4, 2147483647, true)
cvars.AddChangeCallback("zs_redeem", function(cvar, oldvalue, newvalue)
	GAMEMODE.DefaultRedeem = NumericOption(newvalue, 4, 2147483647, true)
end, "ZSNumericOptions")

GM.WaveOneZombies = NumericOption(CreateConVar("zs_waveonezombies", "0.1", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Fraction of players starting as zombies, from 0 to 1. Rounded up to the next hundredth."):GetString(), 0.1, 1)
cvars.AddChangeCallback("zs_waveonezombies", function(cvar, oldvalue, newvalue)
	GAMEMODE.WaveOneZombies = NumericOption(newvalue, 0.1, 1)
end, "ZSNumericOptions")

-- Game feeling too easy? Just change these values!
GM.ZombieSpeedMultiplier = NumericOption(CreateConVar("zs_zombiespeedmultiplier", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Nonnegative zombie running speed multiplier, rounded up to the next hundredth."):GetString(), 1)
cvars.AddChangeCallback("zs_zombiespeedmultiplier", function(cvar, oldvalue, newvalue)
	GAMEMODE.ZombieSpeedMultiplier = NumericOption(newvalue, 1)
end, "ZSNumericOptions")

-- This is a resistance, not for claw damage. 0.5 will make zombies take half damage, 0.25 makes them take 1/4, etc.
GM.ZombieDamageMultiplier = NumericOption(CreateConVar("zs_zombiedamagemultiplier", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Nonnegative multiplier for damage zombies take, rounded up to the next hundredth. Higher values make zombies easier to kill."):GetString(), 1)
cvars.AddChangeCallback("zs_zombiedamagemultiplier", function(cvar, oldvalue, newvalue)
	GAMEMODE.ZombieDamageMultiplier = NumericOption(newvalue, 1)
end, "ZSNumericOptions")

local function RotationLimit(value, fallback, minutes)
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then number = fallback end
	if number < 0 then return -1 end
	local limit = minutes and number * 60 or math.floor(number)
	return limit < math.huge and limit or fallback * (minutes and 60 or 1)
end

GM.TimeLimit = RotationLimit(CreateConVar("zs_timelimit", "15", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Map time limit in minutes, checked after a round ends. -1 disables the time limit; the round limit still applies. 0 switches maps after the current round."):GetString(), 15, true)
cvars.AddChangeCallback("zs_timelimit", function(cvar, oldvalue, newvalue)
	GAMEMODE.TimeLimit = RotationLimit(newvalue, 15, true)
end, "ZSRotationOptions")

GM.RoundLimit = RotationLimit(CreateConVar("zs_roundlimit", "3", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Rounds per map. -1 disables the round limit; the time limit still applies. 0 switches maps after the first round. Positive fractional values are rounded down."):GetString(), 3, false)
cvars.AddChangeCallback("zs_roundlimit", function(cvar, oldvalue, newvalue)
	GAMEMODE.RoundLimit = RotationLimit(newvalue, 3, false)
end, "ZSRotationOptions")

-- Static values that don't need convars...

-- Handled in shared/sigilmaps.lua.
GM.MaxSigils = GM:GetSigilsPerMap(game.GetMap()) or GM.SigilFallBack

-- Max number of waves per game.
GM.NumberOfWaves = 6

-- Second(s) for spectator change cooldown.
GM.SpectatorCoolDown = 10

-- Time resupply takes to recharge.
GM.ResupplyTime = 60

-- Time resupply takes to recharge with trait.
GM.ResupplyTimeTrait = 50

-- Time it takes to teleport from one sigil to another.
GM.SigilTeleportTime = 6

-- Time it takes to teleport from one sigil to another with trait.
GM.SigilTeleportTimeTrait = 1

-- Initial length for wave 1.
GM.WaveOneLength = 220

-- For Classic Mode
GM.WaveOneLengthClassic = 120

-- Add this many seconds for each additional wave.
GM.TimeAddedPerWave = 15

-- For Classic Mode
GM.TimeAddedPerWaveClassic = 10

-- New players are put on the zombie team if the current wave is this or higher. Do not put it lower than 1 or you'll break the game.
GM.NoNewHumansWave = 2

-- Humans can not commit suicide if the current wave is this or lower.
GM.NoSuicideWave = 1

-- How long 'wave 0' should last in seconds. This is the time you should give for new players to join and get ready.
GM.WaveZeroLength = 150

-- Time humans have between waves to do stuff without NEW zombies spawning. Any dead zombies will be in spectator (crow) view and any living ones will still be living.
GM.WaveIntermissionLength = 90

-- For Classic Mode
GM.WaveIntermissionLengthClassic = 20

-- Time in seconds between end round and next map.
GM.EndGameTime = 60

-- How many clips of ammo guns from the Worth menu start with. Some guns such as shotguns and sniper rifles have multipliers on this.
GM.SurvivalClips = 2

-- Put your unoriginal, 5MB Rob Zombie and Metallica music here.
GM.LastHumanSound = Sound("zombiesurvival/lasthuman.ogg")

-- Sound played when humans all die.
GM.AllLoseSound = Sound("zombiesurvival/music_lose.ogg")

-- Sound played when humans survive.
GM.HumanWinSound = Sound("zombiesurvival/music_win.ogg")

-- Sound played to a person when they die as a human.
GM.DeathSound = Sound("music/stingers/HL1_stinger_song28.mp3")
