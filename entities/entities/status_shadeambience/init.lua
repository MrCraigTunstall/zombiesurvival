AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local interval = 0.25
local function PlayerDirection(pl) return pl:GetAimVector() end
local function LampDirection(ent) return ent:GetSpotLightAngles():Forward() end

function ENT:Initialize()
	self:DrawShadow(false)
	self.LastEvaluation = CurTime()
	self.NextFlashlightCheck = self.LastEvaluation + interval
	self.LightTrace = {mask = MASK_SHOT_OPAQUE, filter = {}, output = {}}
	self.LightSources = {}
	self:NextThink(self.NextFlashlightCheck)
end

local function contribution(status, owner, source, position, direction, range, power)
	local nearest = owner:NearestPoint(position)
	local distance = position:DistToSqr(nearest)
	if distance >= range * range then return end
	local offset = nearest - position
	offset:Normalize()
	local dot = offset:Dot(direction(source))
	if dot < 0.85 then return end
	local trace = status.LightTrace
	trace.start, trace.endpos = position, nearest
	trace.filter[1], trace.filter[2] = owner, source
	util.TraceLine(trace)
	if trace.output.Hit then return end
	return (1 - math.sqrt(distance) / range) * dot * power
end

local function add(sources, count, total, source, exposure)
	if not exposure then return count, total end
	count = count + 1
	local item = sources[count]
	if not item then item = {} sources[count] = item end
	item.source, item.exposure = source, exposure
	return count, total + exposure
end

function ENT:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:Alive() or owner:Team() ~= TEAM_UNDEAD or owner:GetZombieClassTable().SWEP ~= "weapon_zs_shade" then self:Remove() return end
	if not self.LightTrace then self:Initialize() end
	local now = CurTime()
	if now < self.NextFlashlightCheck then self:NextThink(self.NextFlashlightCheck) return true end
	local elapsed = math.Clamp(now - self.LastEvaluation, 0, 0.5)
	self.LastEvaluation = now
	self.NextFlashlightCheck = now + interval
	self:NextThink(self.NextFlashlightCheck)
	local sources, count, total = self.LightSources, 0, 0

	if not GAMEMODE.RoundEnded then
		for pl in pairs(GAMEMODE.ZSHumanFlashlights) do
			if IsValid(pl) and pl:Alive() and pl:Team() == TEAM_HUMAN and pl:GetNW2Bool("zs_humanflashlight", false) then
				count, total = add(sources, count, total, pl, contribution(self, owner, pl, pl:GetShootPos(), PlayerDirection, 650, 7))
			end
		end
		for _, lamp in ipairs(GAMEMODE:GetZSEquipmentEntities("prop_spotlamp")) do
			if IsValid(lamp) and not lamp.Destroyed and lamp:GetObjectHealth() > 0 then
				local exposure = contribution(self, owner, lamp, lamp:GetSpotLightPos(), LampDirection, 500, 8)
				if exposure then
					local attacker = lamp:GetObjectOwner()
					if not IsValid(attacker) or not attacker:IsPlayer() or attacker:Team() ~= TEAM_HUMAN then attacker = lamp end
					count, total = add(sources, count, total, attacker, exposure)
				end
			end
		end
	end
	local exposure = math.min(total, 12)
	if self:GetLastDamage() ~= exposure then self:SetLastDamage(exposure) end
	if total > 0 then self:SetLastDamaged(now) end
	if exposure >= 12 then GAMEMODE:ReleaseShadeControl(owner) end
	for i = 1, count do
		local item = sources[i]
		if owner:Alive() then owner:TakeDamage(item.exposure * elapsed / 0.33, item.source, self) end
		item.source = nil
	end
	for i = count + 1, self.SourceCount or 0 do sources[i].source = nil end
	self.SourceCount = count
	return true
end

function ENT:OnRemove()
	local owner = self:GetOwner()
	if IsValid(owner) and owner.status_shadeambience == self then owner.status_shadeambience = nil end
end
