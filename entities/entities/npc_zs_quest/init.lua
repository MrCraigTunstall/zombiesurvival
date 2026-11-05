AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/Humans/Group01/male_01.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
	self:SetUseType(SIMPLE_USE)
	self:SetMaxHealth(500); self:SetHealth(500)
	local sequence = self:LookupSequence("idle_all_01")
	if sequence < 0 then sequence = self:LookupSequence("idle") end
	if sequence >= 0 then self:ResetSequence(sequence) end
	GAMEMODE:RegisterZSClassEntity(self)
end

function ENT:Use(pl)
	if self:GetQuestState() == 1 and self:GetQuestPlayer() == pl and self:GetQuestKind() ~= 1 then
		local _, message = GAMEMODE:DeliverQuest(pl, self)
		if IsValid(pl) and not pl:IsBot() then pl:CenterNotify(COLOR_WHITE, message) end
	else GAMEMODE:OpenQuest(pl, self) end
end

function ENT:OnTakeDamage(info)
	if self:GetQuestState() ~= 1 or self:GetQuestKind() ~= 1 then return end
	local attacker = info:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() or attacker:Team() ~= TEAM_UNDEAD then return end
	local damage = info:GetDamage()
	if damage ~= damage or damage <= 0 or damage == math.huge then return end
	self:SetHealth(math.max(0, self:Health() - damage))
	if self:Health() <= 0 then GAMEMODE:FailQuest(self, "The survivor was killed. Quest failed.") end
end
