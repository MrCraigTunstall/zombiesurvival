ENT.Type = "anim"
ENT.Base = "status_ghost_base"
ENT.GhostWeapon = "weapon_zs_arsenalcrate"

ENT.Model = Model("models/Items/item_item_crate.mdl")

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMaterial("models/wireframe")
	self:SetModel(self.Model)

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
 local rotation = self:GetRotation()
 local angles = owner:EyeAngles()
 local origin = owner:GetShootPos()
 local tr = util.TraceLine({start = origin, endpos = origin + owner:GetAimVector() * 48, mask = MASK_SOLID, filter = owner})
 local surface = tr.HitWorld and not tr.HitSky and tr.HitNormal.z >= 0.75
 if surface then angles = tr.HitNormal:Angle()angles:RotateAroundAxis(angles:Right(), 270) end
 angles:RotateAroundAxis(angles:Up(), rotation + (tr.HitNormal.z >= 0.75 and owner:GetAngles().yaw or 0))
 self:SetPos(tr.HitPos)
 self:SetAngles(angles)
 local valid = surface and not self:IsInsideProp() and not GAMEMODE:HasZSClassInSphere("prop_arsenalcrate", tr.HitPos, 128)
 if valid and SERVER and GAMEMODE:EntityWouldBlockSpawn(self) then valid = false end
 self:SetValidPlacement(valid)
 return tr.HitPos, angles
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
