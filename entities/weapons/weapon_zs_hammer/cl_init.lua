SWEP.PrintNameTranslation = "worth_hammer"
SWEP.DescriptionTranslation = "carpenderhm_desk"
include("shared.lua")

SWEP.PrintName = translate.Get("worth_hammer")

SWEP.TranslatedPrintName = SWEP.PrintName
SWEP.Description = translate.Get("carpenderhm_desk")
SWEP.TranslatedDescription = SWEP.Description

SWEP.ViewModelFOV = 75

local hints = {{"+attack2", "hammer_place_nail"}, {"+reload", "hammer_remove_nail"}, {"+attack", "hammer_repair_strike"}}
local hintText, nextBindingCheck, hintRevision = {}, 0
local function UpdateHints()
	local revision = translate.GetRevision()
	local now = RealTime()
	if now < nextBindingCheck and revision == hintRevision then return end
	nextBindingCheck, hintRevision = now + 0.25, revision
	for index, hint in ipairs(hints) do
		local binding = input.LookupBinding(hint[1], true)
		hintText[index] = string.upper(binding or translate.Get("keys_unbound")).."  ·  "..translate.Get(hint[2])
	end
end

function SWEP:DrawHUD()
	if GetGlobalBool("classicmode") then return end

	UpdateHints()
	local scale = BetterScreenScale()
	local right = ScrW() - 24 * scale
	local height = draw.GetFontHeight("ZSHUDFontSmaller")
	local gap = 5 * scale
	local bottom = ScrH() - 24 * scale
	local nails = self:GetPrimaryAmmoCount()
	local format = translate.Get("nails_x")
	if self.NailHUDCount ~= nails or self.NailHUDFormat ~= format then
		self.NailHUDCount, self.NailHUDFormat = nails, format
		self.NailHUDText = string.format(format, nails)
	end
	for index = #hints, 1, -1 do
		draw.SimpleTextBlurry(hintText[index], "ZSHUDFontSmaller", right, bottom, COLOR_GRAY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		bottom = bottom - height - gap
	end
	draw.SimpleTextBlurry(self.NailHUDText, "ZSHUDFontSmall", right, bottom - 3 * scale, nails > 0 and COLOR_LIMEGREEN or COLOR_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end
