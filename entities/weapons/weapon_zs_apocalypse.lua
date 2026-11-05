AddCSLuaFile()
SWEP.Base = "weapon_zs_superboss"
SWEP.PrintName = "Apocalypse Claws"
SWEP.MeleeDamage = 65
SWEP.MeleeReach = 85
SWEP.MeleeSize = 1.5
SWEP.MeleeDelay = 0.3
SWEP.Primary.Delay = 0.5
SWEP.MeleeForceScale = 2.5
SWEP.SpitCount = 3
function SWEP:SecondaryAttack() return self:BossSpit() end
function SWEP:Reload() return self:BossLeap() end
