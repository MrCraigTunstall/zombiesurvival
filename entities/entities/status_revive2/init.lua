AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:PlayerSet(pPlayer, bExists)
	pPlayer:GetTable().Revive = self
end

function ENT:Think()
	local owner = self:GetOwner()
	if owner:IsValid() and (owner:Alive() or self:GetReviveTime() <= CurTime()) then
		self:Remove()
	end
end

function ENT:OnRemove()
	local parent = self:GetParent()
	if IsValid(parent) then
		local data = parent:GetTable()
		if data[self:GetClass()] == self then data[self:GetClass()] = nil end
		if data.Revive ~= self then return end
		data.Revive = nil
		if not parent:Alive() then
			parent:SecondWind()
		end
	end
end
