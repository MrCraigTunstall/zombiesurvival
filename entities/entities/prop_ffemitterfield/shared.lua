ENT.Type = "anim"

ENT.CanPackUp = true
ENT.PackUpTime = 3

ENT.m_NoNailUnfreeze = true
ENT.NoNails = true
ENT.IgnoreBullets = true
ENT.IgnoreMelee = true
ENT.IgnoreTraces = true

function ENT:ShouldNotCollide(ent)
	return not ent:IsPlayer() and not ent:IsProjectile()
end
