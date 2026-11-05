SWEP.PrintNameTranslation = "medkitgod"
AddCSLuaFile()

SWEP.Base = "weapon_zs_medicalkit"

SWEP.DefaultHealMultiplier = 1.10
SWEP.EmptyChargeDelay = 0.5

SWEP.Primary.Delay = 3
SWEP.Primary.Heal = 35
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 150
SWEP.Primary.Ammo = "Battery"

SWEP.Secondary.Delay = 3.5
SWEP.Secondary.Heal = 30
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = "none"

if CLIENT then
 SWEP.PrintName = translate.Get("medkitgod")
 SWEP.TranslatedPrintName = SWEP.PrintName
 SWEP.MedicalHUDLabel = "medkitgod"
 SWEP.MedicalHUDColor = Color(255, 215, 0)
end
