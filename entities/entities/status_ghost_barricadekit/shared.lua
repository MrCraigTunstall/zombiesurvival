ENT.Type = "anim"
ENT.Base = "status_ghost_base"
ENT.GhostWeapon = "weapon_zs_barricadekit"

ENT.Model = Model("models/props_debris/wood_board05a.mdl")

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMaterial("models/wireframe")
	self:SetModel(self.Model)

	self:RecalculateValidity()
end

function ENT:RecalculateValidity()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:Alive() or owner:GetBarricadeGhosting() or owner:IsHolding() then
		self:SetValidPlacement(false)
		return
	end

	if SERVER or MySelf == owner then
		self:SetRotation(math.NormalizeAngle(owner:GetInfoNum("zs_barricadekityaw", 0)))
	end

	local rotation = self:GetRotation()
	local eyeangles = owner:EyeAngles()
	local shootpos = owner:GetShootPos()
	local tr = util.TraceLine({start = shootpos, endpos = shootpos + owner:GetAimVector() * 32, mask = MASK_SOLID, filter = owner})

	local valid = false
	if tr.HitWorld and not tr.HitSky then
		eyeangles = tr.HitNormal:Angle()
		eyeangles:RotateAroundAxis(eyeangles:Right(), 180)

		valid = true
	else
		local vRight = eyeangles:Right() * self:BoundingRadius()
		local trRight = util.TraceLine({start = tr.HitPos, endpos = tr.HitPos + vRight, mask = MASK_SOLID, filter = owner})
		local trLeft = util.TraceLine({start = tr.HitPos, endpos = tr.HitPos - vRight, mask = MASK_SOLID, filter = owner})

		valid = trLeft.HitWorld and trRight.HitWorld and not trLeft.HitSky and not trRight.HitSky
	end

	eyeangles:RotateAroundAxis(eyeangles:Forward(), rotation)

	local pos, ang = tr.HitPos + tr.HitNormal, eyeangles
	self:SetPos(pos)
	self:SetAngles(ang)

	if valid and SERVER and GAMEMODE:EntityWouldBlockSpawn(self) then
		valid = false
	end

	self:SetValidPlacement(valid)

	return pos, ang
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
