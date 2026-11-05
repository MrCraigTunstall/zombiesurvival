AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self.Heal = self.Heal or 25
	self:DrawShadow(false)
	self:Fire("attack", "", 1.5)

	if self:GetRadius() == 0 then self:SetRadius(400) end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "radius" then
		self:SetRadius(tonumber(value))
	elseif key == "heal" then
		self.Heal = tonumber(value) or self.Heal
	end
end

function ENT:AcceptInput(name, activator, caller, arg)
	if name ~= "attack" then return end
	self:Fire("attack", "", 1.5)

	if GAMEMODE:GetWave() <= 0 or GAMEMODE.ZombieEscape then return end

	local vPos = self:GetPos()
	local radius = self:GetRadius()
	local iterator, entities, index
	local spatial = radius <= 64
	if spatial then iterator, entities, index = ipairs(ents.FindInSphere(vPos, radius))
	else iterator, entities, index = player.Iterator() end
	for _, ent in iterator, entities, index do
		if ent and ent:IsValid() and ent:IsPlayer() and ent:Alive() and (spatial or GAMEMODE:IsPlayerWithinSphere(ent, vPos, radius)) and WorldVisible(vPos, ent:NearestPoint(vPos)) then
			if ent:Team() == TEAM_UNDEAD then
				if ent:Health() < ent:GetMaxHealth() and not ent:GetZombieClassTable().Boss then
					ent:SetHealth(math.min(ent:GetMaxZombieHealth(), ent:Health() + self.Heal))
					ent.m_LastGasHeal = CurTime()
				end
				ent:GiveStatus("zombiespawnbuff", 3)
			elseif 1 < ent:Health() then
				--ent:PoisonDamage(math.min(10, ent:Health() - 1), self, self)
				ent:PoisonDamage(math.min(5, ent:Health() - 1), self, self)
			end
		end
	end

	return true
end

function ENT:UpdateTransmitState()
	return GAMEMODE:GetWave() == 0 and TRANSMIT_ALWAYS or TRANSMIT_PVS
end