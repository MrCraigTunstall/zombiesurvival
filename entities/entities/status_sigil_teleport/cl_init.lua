include("shared.lua")

function ENT:BindTeleportOwner()
 local owner = self:GetOwner()
 if not IsValid(owner) then return end
 self.TeleportOwner = owner
 self.Owner = owner
 local data = owner:GetTable()
 data.Teleport = self
 data.status_sigil_teleport = self
end

function ENT:Initialize()
 self:DrawShadow(false)
 self:SetRenderBounds(Vector(-40, -40, -18), Vector(40, 40, 80))
 self:BindTeleportOwner()
end

function ENT:OnRemove()
 local owner = self.TeleportOwner or self:GetOwner()
 self.TeleportOwner = nil
 if not IsValid(owner) then return end
 local data = owner:GetTable()
 if data.Teleport == self then data.Teleport = nil end
 if data.status_sigil_teleport == self then data.status_sigil_teleport = nil end
end

function ENT:Think()
 if not IsValid(self.TeleportOwner) then self:BindTeleportOwner() end
end

function ENT:Draw()
end
