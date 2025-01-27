ENT.Type = "anim"

ENT.MaxHealth = 1000
ENT.HealthRegen = 10
ENT.RegenDelay = 10

ENT.ModelScale = 1

ENT.m_NoNailUnfreeze = true
ENT.NoNails = true
ENT.IsBarricadeObject = true
ENT.IgnoreBullets = true
ENT.IgnoreMelee = true
ENT.IgnoreTraces = true

AccessorFuncDT(ENT, "SigilHealthBase", "Float", 0)
AccessorFuncDT(ENT, "SigilHealthRegen", "Float", 1)
AccessorFuncDT(ENT, "SigilLastDamaged", "Float", 2)

function ENT:GetSigilLetter()
	return self:GetNWString("SigilLetter")
end

function ENT:SetSigilLetter(letter)
	self:SetNWString("SigilLetter", letter)
end

function ENT:SetSigilHealth(health)
	self:SetSigilHealthBase(health)

	self:SetSigilLastDamaged(math.max(self:GetSigilLastDamaged(), self:GetSigilHealthRegen() - self.RegenDelay))
end

function ENT:GetSigilHealth()
	local base = self:GetSigilHealthBase()
	if base == 0 then return 0 end

	return math.Clamp(base + self:GetSigilHealthRegen() * math.max(0, CurTime() - (self:GetSigilLastDamaged() + self.RegenDelay)), 0, self.MaxHealth)
end

function ENT:GetSigilMaxHealth()
	return self.MaxHealth
end
