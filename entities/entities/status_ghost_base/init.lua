AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Think()
	self:RecalculateValidity()

	local owner = self:GetOwner()
	if not owner:IsValid() then self:Remove() return end
	local weapon = owner:GetActiveWeapon()
	if not weapon:IsValid() or weapon:GetClass() ~= self.GhostWeapon then self:Remove() end
end
