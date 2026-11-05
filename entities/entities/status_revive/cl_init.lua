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
	if endtime <= 0 then return end

	local ct = CurTime()
	local owner = self.ReviveOwner
	if IsValid(owner) then
		local rag = owner:GetRagdollEntity()
		if rag and rag:IsValid() then
			if endtime - 1 <= ct then
				local delta = math.max(0.01, endtime - ct)
				local frameTime = FrameTime()
				local control = self.RiseControl
				if not control then
				 control = {maxangular = 1000, maxangulardamp = 10000, maxspeed = 5000, maxspeeddamp = 1000, dampfactor = 0.85, teleportdistance = 100}
				 self.RiseControl = control
				end
				control.secondstoarrive, control.deltatime = delta, frameTime
				for i = 0, rag:GetPhysicsObjectCount() - 1 do
					local translate = owner:TranslatePhysBoneToBone(i)
					if translate and 0 < translate then
						local pos, ang = owner:GetBonePosition(translate)
						if pos and ang then
							local phys = rag:GetPhysicsObjectNum(i)
							if phys and phys:IsValid() then
								phys:Wake()
								control.pos, control.angle = pos, ang
								phys:ComputeShadowControl(control)
							end
						end
					end
				end
			else
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
	end

	self:NextThink(ct)
	return true
end

function ENT:Draw()
end
