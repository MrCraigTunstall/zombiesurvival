include("shared.lua")

function ENT:BindDrownOwner(owner)
 local previous = self.DrownOwner
 if IsValid(previous) and previous ~= owner then
  local data = previous:GetTable()
  if data.status_drown == self then data.status_drown = nil end
 end
 self.DrownOwner = IsValid(owner) and owner or nil
 if self.DrownOwner then self.DrownOwner:GetTable().status_drown = self end
end

function ENT:Initialize()
 self:DrawShadow(false)
 self:SetRenderBounds(Vector(-40, -40, -18), Vector(40, 40, 80))
 self:BindDrownOwner(self:GetOwner())
end

function ENT:Think()
 local owner = self:GetOwner()
 if owner ~= self.DrownOwner then self:BindDrownOwner(owner) end
end

function ENT:OnRemove()
 local owner = self.DrownOwner or self:GetOwner()
 self.DrownOwner = nil
 if not IsValid(owner) then return end
 local data = owner:GetTable()
 if data.status_drown == self then data.status_drown = nil end
end

function ENT:Draw()
end
