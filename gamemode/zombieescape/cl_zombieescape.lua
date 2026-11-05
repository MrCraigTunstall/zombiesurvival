include("sh_zombieescape.lua")

if not GM.ZombieEscape then return end

local freezeText, freezeLength, textRevision
function GM:DrawZombieEscapeFreezeNotice()
	if self.RoundEnded or self.FilmMode or not IsValid(MySelf) then return end
	if self:GetWave() ~= 0 or self:GetWaveActive() then return end
	local team = MySelf:Team()
	if team ~= TEAM_UNDEAD and (team ~= TEAM_HUMAN or CurTime() >= self:GetWaveStart() - self.ZE_FreezeTime) then return end
	local revision = translate.GetRevision()
	if freezeLength ~= self.ZE_FreezeTime or textRevision ~= revision then
		freezeLength, textRevision = self.ZE_FreezeTime, revision
		freezeText = translate.Format("ze_humans_are_frozen_until_x", freezeLength)
	end
	draw.SimpleTextBlur(freezeText, "ZSHUDFontSmall", ScrW() / 2, ScrH() / 2, COLOR_DARKRED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
hook.Add("HUDPaint", "zombieescape", function() GAMEMODE:DrawZombieEscapeFreezeNotice() end)

include("cl_bosses.lua")
