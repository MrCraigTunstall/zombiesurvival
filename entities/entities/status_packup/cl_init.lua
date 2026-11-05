include("shared.lua")

function ENT:BindPackOwner()
 local owner = self:GetOwner()
 if not IsValid(owner) then return end
 self.PackOwner = owner
 self.Owner = owner
 local data = owner:GetTable()
 data.PackUp = self
 data.status_packup = self
end

function ENT:Initialize()
 self:DrawShadow(false)
 self:SetRenderBounds(Vector(-40, -40, -18), Vector(40, 40, 80))
 self:BindPackOwner()
end

function ENT:OnRemove()
 local owner = self.PackOwner or self:GetOwner()
 self.PackOwner = nil
 if not IsValid(owner) then return end
 local data = owner:GetTable()
 if data.PackUp == self then data.PackUp = nil end
 if data.status_packup == self then data.status_packup = nil end
end

function ENT:Think()
 if not IsValid(self.PackOwner) then self:BindPackOwner() end
end

function ENT:Draw()
end
