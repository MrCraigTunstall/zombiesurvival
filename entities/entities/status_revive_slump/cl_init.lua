include("shared.lua")

local liftOffset = Vector(0, 0, 16)

function ENT:BindReviveOwner()
 local owner = self:GetOwner()
 if not IsValid(owner) or not owner:IsPlayer() then return end
 self.ReviveOwner = owner
 self.Owner = owner
 local data = owner:GetTable()
 data.Revive = self
 data[self:GetClass()] = self
 owner:CallWeaponFunction("KnockedDown", self, false)
 owner:CallZombieFunction("KnockedDown", self, false)
end

function ENT:Initialize()
 self:DrawShadow(false)
 self:SetRenderBounds(Vector(-40, -40, -18), Vector(40, 40, 80))
 self:BindReviveOwner()
end

function ENT:OnRemove()
 local owner = self.ReviveOwner or self:GetOwner()
 self.ReviveOwner, self.LiftControl, self.RiseControl = nil, nil, nil
 if not IsValid(owner) then return end
 local data = owner:GetTable()
 if data.Revive == self then data.Revive = nil end
 if data[self:GetClass()] == self then data[self:GetClass()] = nil end
end

function ENT:Think()
 if not IsValid(self.ReviveOwner) then self:BindReviveOwner() end
	local endtime = self:GetReviveTime()
	if endtime == 0 then return end

	local owner = self.ReviveOwner
	if IsValid(owner) then
		local rag = owner:GetRagdollEntity()
		if rag and rag:IsValid() then
			local phys = rag:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				local control = self.LiftControl
				if not control then
					control = {secondstoarrive = 0.05, maxangular = 2000, maxangulardamp = 10000, maxspeed = 5000, maxspeeddamp = 1000, dampfactor = 0.85, teleportdistance = 200}
					self.LiftControl = control
				end
				control.pos, control.angle, control.deltatime = owner:GetPos() + liftOffset, phys:GetAngles(), FrameTime()
				phys:ComputeShadowControl(control)
			end
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Draw()
end
