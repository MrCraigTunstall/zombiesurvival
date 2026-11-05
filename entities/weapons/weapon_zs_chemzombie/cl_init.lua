SWEP.PrintNameTranslation = "wn_chem"
include("shared.lua")

SWEP.PrintName = translate.Get("wn_chem")

SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.DrawCrosshair = false

function SWEP:Think()
end

function SWEP:DrawHUD()
	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end
