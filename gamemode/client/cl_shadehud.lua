local background = Color(15, 20, 26, 235)
local track = Color(38, 46, 54)
local protected = Color(125, 185, 235)
local burning = Color(245, 190, 90)
local disrupted = Color(245, 100, 105)
local muted = Color(170, 183, 195)
local percentValue, percentText

function GM:DrawShadeHUD(pl, x, y, width, scale)
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_UNDEAD or pl:GetZombieClassTable().SWEP ~= "weapon_zs_shade" then return end
	local status = pl.status_shadeambience
	local known = IsValid(status) and status:GetOwner() == pl and type(status.GetLastDamage) == "function"
	local exposure = known and math.Clamp(status:GetLastDamage() / 12, 0, 1) or 0
	local percent = known and math.floor(exposure * 100 + 0.5) or -1
	if percent ~= percentValue then percentValue = percent percentText = percent < 0 and "--" or percent .. "%" end
	local state = not known and "shade_light_sync" or exposure >= 1 and "shade_light_exposed" or exposure > 0 and "shade_light_burning" or "shade_light_protected"
	local color = not known and muted or exposure >= 1 and disrupted or exposure > 0 and burning or protected
	local weapon = pl:GetActiveWeapon()
	local grip
	if not known then grip = "shade_grip_sync"
	elseif exposure >= 1 then grip = "shade_grip_disrupted"
	elseif not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_shade" then grip = "shade_grip_unavailable"
	elseif type(weapon.GetShadeControl) ~= "function" then grip = "shade_grip_sync"
	elseif IsValid(weapon:GetShadeControl()) then grip = "shade_grip_holding"
	elseif weapon:GetNextSecondaryFire() > CurTime() then grip = "shade_grip_recovering"
	else grip = "shade_grip_ready" end
	local inset, barwidth = 12 * scale, math.max(0, width - 24 * scale)
	draw.RoundedBox(6 * scale, x, y, width, 60 * scale, background)
	draw.SimpleText(translate.Get(state), "ZSHUDFontTinyNS", x + inset, y + 8 * scale, color)
	draw.SimpleText(percentText, "ZSHUDFontTinyNS", x + width - inset, y + 8 * scale, color, TEXT_ALIGN_RIGHT)
	surface.SetDrawColor(track)
	surface.DrawRect(x + inset, y + 27 * scale, barwidth, 6 * scale)
	surface.SetDrawColor(color)
	surface.DrawRect(x + inset, y + 27 * scale, barwidth * exposure, 6 * scale)
	draw.SimpleText(translate.Get(grip), "ZSHUDFontTinyNS", x + inset, y + 41 * scale, color)
end
