ENT.Type = "anim"
ENT.Base = "status__base"

ENT.GhostModel = Model("models/Combine_turrets/Floor_turret.mdl")
ENT.GhostRotation = Angle(270, 0, 0)
ENT.GhostEntity = "prop_gunturret"
ENT.GhostWeapon = "weapon_zs_gunturret"
ENT.GhostDistance = 64
ENT.GhostFlatGround = true
ENT.GhostRotateFunction = "Up"

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMaterial("models/wireframe") --self:SetMaterial("models/debug/debugwhite")
	self:SetModel(self.GhostModel)

	self:RecalculateValidity()
end

function ENT:IsInsideProp()
	for _, ent in pairs(ents.FindInBox(self:WorldSpaceAABB())) do
		if ent and ent ~= self and ent:IsValid() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetSolid() > 0 and not (ent.IgnoreTraces and ent:GetCollisionGroup() == COLLISION_GROUP_DEBRIS_TRIGGER) then return true end
	end

	return false
end

function ENT:RecalculateValidity()
 local owner = self:GetOwner()
 if not IsValid(owner) or not owner:Alive() or owner:GetBarricadeGhosting() or owner:IsHolding() then self:SetValidPlacement(false)return end
 if SERVER or MySelf == owner then self:SetRotation(math.NormalizeAngle(owner:GetInfoNum("_zs_ghostrotation", 0))) end
 local rotation = self.GhostNoRotation and 0 or self:GetRotation()
 local angles = owner:EyeAngles()
 local origin = owner:GetShootPos()
 local tr = util.TraceLine({start = origin, endpos = origin + owner:GetAimVector() * (self.GhostTraceDistance or 48), mask = MASK_SOLID, filter = owner})
 local surface = tr.HitWorld and not tr.HitSky or tr.HitNonWorld and self.GhostPlaceOnEntities
 if surface then
  if self.GhostHitNormalOffset then tr.HitPos = tr.HitPos + tr.HitNormal * self.GhostHitNormalOffset end
  angles = tr.HitNormal:Angle()
  local rot = self.GhostRotation
  angles:RotateAroundAxis(angles:Right(), rot.pitch)
  angles:RotateAroundAxis(angles:Up(), rot.yaw)
  angles:RotateAroundAxis(angles:Forward(), rot.roll)
 end
 angles:RotateAroundAxis(angles[self.GhostRotateFunction](angles), rotation + (tr.HitNormal.z >= 0.75 and owner:GetAngles().yaw or 0))
 self:SetPos(tr.HitPos)
 self:SetAngles(angles)
 local valid = false
 if surface then
  valid = not (self.GhostLimitedNormal and tr.HitNormal.z < self.GhostLimitedNormal) and not self:IsInsideProp()
  if valid and self.GhostDistance then valid = not GAMEMODE:HasZSClassInSphere(self.GhostEntity, tr.HitPos, self.GhostDistance) end
  if valid and self.GhostFlatGround and math.abs(tr.HitNormal.z) < 0.75 then
   local start = tr.HitPos + tr.HitNormal
   valid = util.TraceLine({start = start, endpos = start + Vector(0, 0, -128), mask = MASK_SOLID_BRUSHONLY}).Hit
  end
  if valid and SERVER and GAMEMODE:EntityWouldBlockSpawn(self) then valid = false end
  if valid then valid = self:CustomValidate(tr) end
 end
 self:SetValidPlacement(valid)
 local entity
 if surface then entity = tr.Entity end
 return tr.HitPos, angles, entity
end

function ENT:CustomValidate(tr)
	return true
end

function ENT:GetValidPlacement()
	return self:GetDTBool(0)
end

function ENT:SetValidPlacement(onoff)
	onoff = not not onoff
	if SERVER and self:GetDTBool(1) ~= onoff then self:SetDTBool(1, onoff) end
	if CLIENT then onoff = onoff and self:GetDTBool(1) end
	if self:GetDTBool(0) ~= onoff then self:SetDTBool(0, onoff) end
end

function ENT:GetRotation()
	return self:GetDTFloat(0)
end

function ENT:SetRotation(rotation)
	self:SetDTFloat(0, rotation)
end
