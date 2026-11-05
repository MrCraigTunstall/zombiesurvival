include("shared.lua")
local background, accent = Color(14, 22, 34, 235), Color(130, 210, 255)
local complete = Color(110, 235, 155)
local states = {[0] = "quest_world_accept", [1] = "quest_world_active", [2] = "quest_world_complete", [3] = "quest_world_retry"}

function ENT:Initialize()
	GAMEMODE:RegisterZSClassEntity(self)
end

function ENT:Draw()
	self:DrawModel()
	if not IsValid(MySelf) or MySelf:EyePos():DistToSqr(self:GetPos()) > 600^2 then return end
	local definition = GAMEMODE.QuestDefinitions[self:GetQuestKind()]
	if not definition then return end
	cam.Start3D2D(self:GetPos() + Vector(0, 0, 84), Angle(0, MySelf:EyeAngles().y - 90, 90), 0.1)
		draw.RoundedBox(8, -180, -28, 360, 64, background)
		draw.SimpleText(definition.title, "ZSHUDFontSmall", 0, -22, accent, TEXT_ALIGN_CENTER)
		draw.SimpleText(translate.Get(states[self:GetQuestState()] or "quest_world_accept"), "ZSHUDFontTiny", 0, 12, self:GetQuestState() == 2 and complete or color_white, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
