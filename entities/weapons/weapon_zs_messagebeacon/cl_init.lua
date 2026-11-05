include("shared.lua")

SWEP.PrintName = ""..translate.Get("worth_beacon")
SWEP.Description = ""..translate.Get("msgbeacon_desk")
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

function SWEP:Think()
end

function SWEP:SecondaryAttack()
 if not IsFirstTimePredicted() then return end
 GAMEMODE:OpenBeaconMenu(self)
end
