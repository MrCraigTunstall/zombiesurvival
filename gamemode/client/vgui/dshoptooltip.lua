local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local PANEL = {}
local colors = GM.ShopColors

function PANEL:Init()
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	self.BaseClass.Init(self)
	self.Body = vgui.Create("DLabel", self)
	self.Body:SetFont("ZSMenuScaledBody")
	self.Body:SetTextColor(color_white)
	self.Body:SetWide(math.min(U(420), ScrW() - U(24)) - U(24))
	self.Body:SetWrap(true)
	self.Body:SetContentAlignment(7)
	self.Body:SetMouseInputEnabled(false)
	self.Body:SetPos(U(12), U(10))
	self.Body:SetText(self.ShopTooltipText or "")
	self.Body.PaintOver = function() self:FinishLayout() end
	self:SetMouseInputEnabled(false)
end

function PANEL:SetText(text)
	text = text or ""
	if self.ShopTooltipText == text then return end
	self.ShopTooltipText = text
	self.ShopTooltipLayoutText = nil
	if IsValid(self.Body) then self.Body:SetText(text) end
end

function PANEL:GetText()
	return self.ShopTooltipText or ""
end

function PANEL:UpdateColours()
	if IsValid(self.Body) then self.Body:SetTextColor(color_white) end
end

function PANEL:PerformLayout()
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	if not IsValid(self.Body) then return end
	local width, height = ScrW(), ScrH()
	local text = self:GetText()
	if self.ShopTooltipLayoutText == text and self.ShopTooltipScreenWidth == width and self.ShopTooltipScreenHeight == height then return end
	self.ShopTooltipLayoutText, self.ShopTooltipScreenWidth, self.ShopTooltipScreenHeight = text, width, height
	local wide = math.min(U(420), width - U(24))
	self.Body:SetWide(wide - U(24))
	self.Body:SetPos(U(12), U(10))
	self.Body:InvalidateLayout(true)
	self.ShopTooltipNeedsMeasure = true
	self:SetSize(wide, math.min(U(52), height - U(24)))
end

function PANEL:FinishLayout()
	if not self.ShopTooltipNeedsMeasure or not IsValid(self.Body) then return end
	self.ShopTooltipNeedsMeasure = nil
	self.Body:SizeToContentsY()
	self:SetTall(math.min(self.Body:GetTall() + U(20), ScrH() - U(24)))
end

function PANEL:PositionTooltip()
	local target = self.TargetPanel
	if not IsValid(target) then self:Close() return false end
	local parent = target
	while IsValid(parent) do
		if not parent:IsVisible() then self:Close() return false end
		parent = parent:GetParent()
	end
	local hovered = vgui.GetHoveredPanel()
	local _, _, owner = FindTooltip(hovered)
	if owner ~= target then self:Close() return false end
	local text = target:GetTooltip()
	if not text or text == "" then self:Close() return false end
	self:SetText(text)
	self:PerformLayout()
	local x = input.GetCursorPos()
	local _, targetY = target:LocalToScreen(0, 0)
	local wide, tall = self:GetSize()
	local screenWidth, screenHeight = ScrW(), ScrH()
	local y = targetY + target:GetTall() + U(10)
	if y + tall > screenHeight - U(12) then y = targetY - tall - U(10) end
	x, y = math.Clamp(x - wide * 0.5, U(12), screenWidth - wide - U(12)), math.Clamp(y, U(12), screenHeight - tall - U(12))
	local oldX, oldY = self:GetPos()
	if oldX ~= x or oldY ~= y then self:SetPos(x, y) end
	return true
end

function PANEL:OpenForPanel(panel)
	self.TargetPanel = panel
	local delay = panel:GetTooltipDelay()
	if not isnumber(delay) then delay = GetConVar("tooltip_delay"):GetFloat() end
	self:SetVisible(delay <= 0)
	if not self:PositionTooltip() then return end
	if delay > 0 then
		timer.Simple(delay, function()
			if IsValid(self) and self:PositionTooltip() then self:SetVisible(true) end
		end)
	end
end

function PANEL:Think()
	if self:IsVisible() then self:PositionTooltip() end
end

function PANEL:Paint(wide, tall)
	if not self:PositionTooltip() then return end
	draw.RoundedBox(U(6), 0, 0, wide, tall, colors.accent)
	draw.RoundedBox(U(5), 1, 1, wide - 2, tall - 2, colors.header)
end

vgui.Register("ZSShopTooltip", PANEL, "DTooltip")
