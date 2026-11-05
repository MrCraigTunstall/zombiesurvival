AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	local mins, maxs = Vector(-56, -8, -1), Vector(8, 8, 115)

	self:SetModel("models/props_doors/door01_dynamic.mdl")
	self:PhysicsInitBox(mins, maxs)
	self:SetCollisionBounds(mins, maxs)
	self:SetUseType(SIMPLE_USE)

	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
		phys:Wake()
	end

	self:SetCreationTime(CurTime())

	--self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

	self.ExitHints = {}
	local function hint(teamid, text)
		local ent = ents.Create("point_worldhint")
		if not IsValid(ent) then return end
		ent:SetPos(self:LocalToWorld(Vector(-24, 0, 2)))
		ent:SetParent(self)
		ent:Spawn()
		ent:SetViewable(teamid)
		ent:SetRange(0)
		ent:SetTranslated(true)
		ent:SetHint(text)
		self.ExitHints[#self.ExitHints + 1] = ent
	end
	hint(TEAM_HUMAN, "prop_obj_exit_h")
	hint(TEAM_REDEEMER, "prop_obj_exit_h")
	hint(TEAM_UNDEAD, "prop_obj_exit_z")

	--[[ent = ents.Create("env_projectedtexture")
	if ent:IsValid() then
		ent:SetPos(self:GetPos() + self:GetUp() * 8)
		ent:SetAngles(self:GetRight():Angle())
		ent:SetKeyValue("enableshadows", 0)
		ent:SetKeyValue("farz", 600)
		ent:SetKeyValue("nearz", 2)
		ent:SetKeyValue("lightfov", 70)
		ent:SetKeyValue("lightcolor", "220 240 255 255")
		ent:SetKeyValue("appearance", 5)
		ent:SetParent(self)
		ent:Spawn()
		ent:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")
		self.SpotLight = ent
	end]]
end

local function CanEscape(pl)
	if not pl:IsPlayer() or not pl:Alive() then return false end
	local teamid = pl:Team()
	return teamid == TEAM_HUMAN or teamid == TEAM_REDEEMER
end

function ENT:Use(activator)
	if CanEscape(activator) and self:GetOpenStartTime() == 0 and self:GetRise() == 1 then
		self:SetOpenStartTime(CurTime())
	end
end

function ENT:Touch(ent)
	if CanEscape(ent) and ent:GetObserverMode() == OBS_MODE_NONE and self:IsOpened() then
		local pos = ent:EyePos()

		ent:Spectate(OBS_MODE_ROAMING)
		ent:SpectateEntity(self)
		ent:StripWeapons()
		ent:GodEnable()

		ent:SetPos(pos)

		ent:PrintMessage(3, translate.ClientGet(ent, "sigil_yousurvived"))
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
function ENT:OnRemove()
	for _, hint in ipairs(self.ExitHints or {}) do
		if IsValid(hint) then hint:Remove() end
	end
	self.ExitHints = nil
end
