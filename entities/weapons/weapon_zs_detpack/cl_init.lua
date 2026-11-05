SWEP.PrintNameTranslation = "wn_detpack"
SWEP.DescriptionTranslation = "detpack_desk"
include("shared.lua")

SWEP.PrintName = translate.Get("wn_detpack")

SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.Description = translate.Get("detpack_desk")
SWEP.TranslatedDescription = SWEP.Description
SWEP.DrawCrosshair = false

SWEP.Slot = 4
SWEP.SlotPos = 0

function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	return true
end

function SWEP:DrawHUD()
	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end

function SWEP:PrimaryAttack()
end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end
