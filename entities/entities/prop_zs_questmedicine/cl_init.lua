include("shared.lua")
local accent = Color(130, 210, 255)

function ENT:Draw()
	self:DrawModel()
	local npc = self:GetQuestNPC()
	if not IsValid(MySelf) or not IsValid(npc) or npc:GetQuestPlayer() ~= MySelf or MySelf:EyePos():DistToSqr(self:GetPos()) > 600^2 then return end
	cam.Start3D2D(self:GetPos() + Vector(0, 0, 24), Angle(0, MySelf:EyeAngles().y - 90, 90), 0.1)
		draw.SimpleText(translate.Get("quest_collect_medicine"), "ZSHUDFontTiny", 0, 0, accent, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
