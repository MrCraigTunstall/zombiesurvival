AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/player/breen.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(145, 210, 255, 175))
	local sequence = self:LookupSequence("idle_all_01")
	if sequence < 0 then sequence = self:LookupSequence("idle") end
	if sequence >= 0 then self:ResetSequence(sequence) end
	GAMEMODE:RegisterZSClassEntity(self)
end

function ENT:Use(pl)
	GAMEMODE:OpenTrader(pl, self)
end

function ENT:OnTakeDamage()
	return false
end
