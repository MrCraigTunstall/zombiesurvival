util.PrecacheModel("models/props_phx/construct/metal_dome360.mdl")

EFFECT.LifeTime = 0.35

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local angles = data:GetAngles()

	self.Offset = data:GetStart()
	self.Ent = data:GetEntity()

	sound.Play("weapons/fx/rics/ric"..math.random(5)..".wav", pos, 68, math.Rand(120, 130))

	self.Entity:SetModel("models/props_phx/construct/metal_dome360.mdl")
	self.Entity:SetMoveType(MOVETYPE_NONE)
	self.Entity:SetModelScale(0.5, 0)
	self.Entity:SetAngles(angles)

	self.DieTime = CurTime() + self.LifeTime
end

function EFFECT:Think()
	return IsValid(self.Ent) and CurTime() < self.DieTime
end

local matRefract = Material("models/spawn_effect")
function EFFECT:Render()
	local ent = self.Ent
	if not IsValid(ent) or ent:IsDormant() then return end
	self:SetPos(ent:LocalToWorld(self.Offset))

	render.UpdateRefractTexture()
	matRefract:SetFloat("$refractamount", math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1) ^ 2 * 0.05)

	render.ModelMaterialOverride(matRefract)

	self.Entity:DrawModel()

	render.ModelMaterialOverride(0)
end
