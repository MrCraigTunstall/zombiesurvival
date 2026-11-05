SWEP.PrintNameTranslation = "wn_manhacksawcontroll"
SWEP.DescriptionTranslation = "wn_manhacksawcontrolldes"
AddCSLuaFile()

SWEP.Base = "weapon_zs_manhackcontrol"

if CLIENT then
	SWEP.PrintName = translate.Get("wn_manhacksawcontroll")
	SWEP.TranslatedPrintName = SWEP.PrintName
	SWEP.Description = translate.Get("wn_manhacksawcontrolldes")
	SWEP.TranslatedDescription = SWEP.Description
end

SWEP.EntityClass = "prop_manhack_saw"
