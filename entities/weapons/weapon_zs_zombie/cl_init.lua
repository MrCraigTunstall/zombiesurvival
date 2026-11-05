SWEP.PrintNameTranslation = "wn_zombie"
include("shared.lua")

SWEP.PrintName = translate.Get("wn_zombie")

SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.ViewModelFOV = 70
SWEP.DrawCrosshair = false

function SWEP:Reload()
end

function SWEP:DrawWorldModel()
end
SWEP.DrawWorldModelTranslucent = SWEP.DrawWorldModel

function SWEP:DrawHUD()
	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end
