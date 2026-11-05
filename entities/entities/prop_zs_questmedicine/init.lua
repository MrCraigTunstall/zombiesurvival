AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/items/healthkit.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(Vector(-10, -10, 0), Vector(10, 10, 16))
	self:SetUseType(SIMPLE_USE)
end

function ENT:Use(pl)
	GAMEMODE:CollectQuestMedicine(pl, self)
end
