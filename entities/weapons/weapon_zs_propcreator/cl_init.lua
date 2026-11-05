include("shared.lua")
SWEP.Slot = 4
SWEP.DrawAmmo = false
SWEP.ViewModelFlip = false

function SWEP:DrawHUD()
	surface.SetDrawColor(255, 255, 255, 225)
	surface.DrawRect(ScrW() / 2 - 1, ScrH() / 2 - 1, 2, 2)
	local choice = GAMEMODE.PropCreatorChoices[self:GetSelectedProp()]
	local label = choice and choice.label or "propcreator_board"
	local remaining = self:GetRemainingProps()
	local revision = translate.GetRevision and translate.GetRevision()
	if self.ZSPropCreatorHUDLabel ~= label or self.ZSPropCreatorHUDRemaining ~= remaining or self.ZSPropCreatorHUDRevision ~= revision then
		self.ZSPropCreatorHUDLabel, self.ZSPropCreatorHUDRemaining, self.ZSPropCreatorHUDRevision = label, remaining, revision
		self.ZSPropCreatorHUDText = translate.Format("propcreator_hud", translate.Get(label), remaining)
	end
	draw.SimpleText(self.ZSPropCreatorHUDText, "ZSHUDFontSmallest", ScrW() / 2, ScrH() * 0.72, color_white, TEXT_ALIGN_CENTER)
end
