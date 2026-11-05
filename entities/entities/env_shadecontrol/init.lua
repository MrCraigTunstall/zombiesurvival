AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local interval = 1 / 30
function ENT:Initialize()
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetModelScale(1.03, 0)
end

function ENT:AttachTo(obj, weapon)
	local owner = self:GetOwner()
	if not GAMEMODE:IsShadeControllerOwner(owner, weapon) or not GAMEMODE:CanShadeHoldObject(obj) then self:Remove() return false end
	self:SetControllerWeapon(weapon)
	self:SetModel(obj:GetModel())
	self:SetSkin(obj:GetSkin() or 0)
	self:SetPos(obj:GetPos())
	self:SetAngles(obj:GetAngles())
	self:SetAlpha(obj:GetAlpha())
	self:SetParent(obj)
	if not GAMEMODE:RegisterShadeControl(self, owner, obj, weapon) then self:Remove() return false end
	self.HoldDistance = math.Clamp(owner:EyePos():Distance(obj:WorldSpaceCenter()), 80, 260)
	self.ShadowParams = {secondstoarrive = 0.12, maxangular = 120, maxangulardamp = 180, maxspeed = 600, maxspeeddamp = 1000, dampfactor = 0.8, teleportdistance = 0, pos = Vector(), angle = obj:GetAngles()}
	local radius = math.Clamp(obj:BoundingRadius(), 4, 48)
	self.HoldTrace = {mask = MASK_SOLID, filter = {owner, obj, self}, mins = Vector(-radius, -radius, -radius), maxs = Vector(radius, radius, radius), output = {}}
	self.LastThink = CurTime()
	self.NextAttribution = 0
	self:NextThink(self.LastThink + interval)
	return true
end

function ENT:Think()
	local owner, obj, weapon = self:GetOwner(), self:GetParent(), self:GetControllerWeapon()
	if not self.ShadowParams or not GAMEMODE:IsShadeControllerOwner(owner, weapon) or not GAMEMODE:CanShadeHoldObject(obj)
		or GAMEMODE:GetShadeControl(owner) ~= self or GAMEMODE:GetShadeObjectControl(obj) ~= self then self:Remove() return end
	local eye = owner:EyePos()
	if eye:DistToSqr(obj:NearestPoint(eye)) > 160000 then self:Remove() return end
	local now = CurTime()
	local trace = self.HoldTrace
	trace.start = eye
	trace.endpos = eye + owner:GetAimVector() * self.HoldDistance
	util.TraceHull(trace)
	if trace.output.StartSolid then self:Remove() return end
	local params = self.ShadowParams
	params.pos:Set(trace.output.HitPos)
	params.pos:Add(obj:GetPos())
	params.pos:Sub(obj:WorldSpaceCenter())
	params.deltatime = math.Clamp(now - self.LastThink, 0.001, 0.1)
	self.LastThink = now
	local phys = obj:GetPhysicsObject()
	phys:Wake()
	phys:ComputeShadowControl(params)
	if now >= self.NextAttribution then obj:SetPhysicsAttacker(owner, 8) self.NextAttribution = now + 1 end
	self:NextThink(now + interval)
	return true
end

function ENT:OnRemove()
	GAMEMODE:UnregisterShadeControl(self)
end
