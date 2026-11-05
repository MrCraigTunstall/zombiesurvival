GM.REVISION = 4352

function GM:OpenMainMenu()
	local menu = self.HelpMenu
	if IsValid(menu) and menu:IsVisible() then return menu end
	return self:ShowHelp()
end

local PANEL = {}

function PANEL:Init()
	self:SetContentAlignment(4)
	self:SetFont("ZSHUDFontSmall")
end

function PANEL:Paint()
end

vgui.Register("ZSMenuButton", PANEL, "Button")
