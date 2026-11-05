AddCSLuaFile("cl_zombieescape.lua")
AddCSLuaFile("cl_bosses.lua")
AddCSLuaFile("sh_zombieescape.lua")
AddCSLuaFile("sh_mapweapons.lua")

include("sh_zombieescape.lua")

if not GM.ZombieEscape then return end
include("sv_rounds.lua")
include("sv_mapcompat.lua")
include("sv_bosses.lua")
