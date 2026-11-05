ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.CanPackUp = true
ENT.PackUpTime = 5
ENT.m_NoNailUnfreeze = true
ENT.NoNails = true
ENT.IsBarricadeObject = true
ENT.AlwaysGhostable = true
ENT.RepairRadius = 160
ENT.RepairRate = 60
ENT.RepairPerTarget = 20
ENT.RepairInterval = 1
ENT.MaxRepairTargets = 8
ENT.MaxCandidates = 64
ENT.MaxRepairTraces = 8

function ENT:SetObjectOwner(owner)
	self:SetDTEntity(0, owner)
end

function ENT:GetObjectOwner()
	return self:GetDTEntity(0)
end

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, math.Clamp(health, 0, self:GetMaxObjectHealth()))
end

function ENT:GetObjectHealth()
	return self:GetDTFloat(0)
end

function ENT:GetMaxObjectHealth()
	return 250
end
