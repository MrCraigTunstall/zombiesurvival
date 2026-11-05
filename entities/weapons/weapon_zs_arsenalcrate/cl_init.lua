SWEP.PrintNameTranslation = "worth_arsenalcrate"
SWEP.DescriptionTranslation = "ars_desk"
include("shared.lua")

SWEP.PrintName = translate.Get("worth_arsenalcrate")

SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.Description = translate.Get("ars_desk")
SWEP.TranslatedDescription = SWEP.Description
SWEP.DrawCrosshair = false

SWEP.Slot = 4
SWEP.SlotPos = 0

function SWEP:DrawHUD()
	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end

function SWEP:PrimaryAttack()
end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end

SWEP.GhostRotationInput = true

function SWEP:Think()
end

function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	return true
end

local nextclick = 0
function SWEP:RotateGhost(amount)
	if nextclick <= RealTime() then
		surface.PlaySound("npc/headcrab_poison/ph_step4.wav")
		nextclick = RealTime() + 0.3
	end

	RunConsoleCommand("_zs_ghostrotation", math.NormalizeAngle(GetConVarNumber("_zs_ghostrotation") + amount))
end
