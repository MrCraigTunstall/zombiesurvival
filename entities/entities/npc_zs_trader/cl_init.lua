include("shared.lua")
local background, accent = Color(14, 22, 34, 230), Color(145, 210, 255)

function ENT:Initialize()
	GAMEMODE:RegisterZSClassEntity(self)
end

function ENT:DrawTranslucent()
	self:DrawModel()
	if not IsValid(MySelf) or MySelf:EyePos():DistToSqr(self:GetPos()) > 600 * 600 then return end
	local angle = Angle(0, MySelf:EyeAngles().y - 90, 90)
	cam.Start3D2D(self:GetPos() + Vector(0, 0, 84), angle, 0.1)
		draw.RoundedBox(8, -145, -26, 290, 58, background)
		draw.SimpleText("GHOST TRADER", "ZSHUDFontSmall", 0, -20, accent, TEXT_ALIGN_CENTER)
		draw.SimpleText("USE to trade between waves", "ZSHUDFontTiny", 0, 10, color_white, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
