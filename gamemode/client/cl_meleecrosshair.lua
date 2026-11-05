local style = CreateClientConVar("zs_melee_crosshair", "1", true, false, "Melee crosshair: 0 off, 1 cross, 2 dot, 3 open cross", 0, 3)
local size = CreateClientConVar("zs_melee_crosshair_size", "8", true, false, "Melee crosshair size", 2, 32)
local crosshair = GetConVar("crosshair")

function GM:DrawMeleeCrosshair()
	if not crosshair:GetBool() or self.RoundEnded or self.FilmMode then return end
	local mode = style:GetInt()
	if mode <= 0 then return end
	local x, y = math.floor(ScrW() * 0.5), math.floor(ScrH() * 0.5)
	local scale = BetterScreenScale()
	local length = math.max(2, math.floor(size:GetInt() * scale))
	local thickness = math.max(1, math.floor(2 * scale))
	surface.SetDrawColor(self.CrosshairColor)
	if mode == 2 then
		local radius = math.max(1, math.floor(length / 4))
		surface.DrawRect(x - radius, y - radius, radius * 2, radius * 2)
	elseif mode == 3 then
		local gap = math.max(2, math.floor(3 * scale))
		surface.DrawRect(x - gap - length, y, length, thickness)
		surface.DrawRect(x + gap, y, length, thickness)
		surface.DrawRect(x, y - gap - length, thickness, length)
		surface.DrawRect(x, y + gap, thickness, length)
	else
		surface.DrawRect(x - length, y, length * 2 + thickness, thickness)
		surface.DrawRect(x, y - length, thickness, length * 2 + thickness)
	end
end

function GM:AddMeleeCrosshairOptions(list, parent)
	local dropdown = vgui.Create("DComboBox", parent)
	for i, key in ipairs({"crosshair_off", "crosshair_cross", "crosshair_dot", "crosshair_open_cross"}) do
		dropdown:AddChoice(translate.Get(key), i - 1, style:GetInt() == i - 1)
	end
	dropdown.OnSelect = function(_, _, _, value) RunConsoleCommand("zs_melee_crosshair", tostring(value)) end
	list:AddItem(EasyLabel(parent, translate.Get("options_melee_crosshair")))
	list:AddItem(dropdown)
	local slider = vgui.Create("DNumSlider", parent)
	slider:SetText(translate.Get("options_melee_crosshair_size"))
	slider:SetMinMax(2, 32)
	slider:SetDecimals(0)
	slider:SetConVar("zs_melee_crosshair_size")
	slider:SetTall(36)
	list:AddItem(slider)
end
