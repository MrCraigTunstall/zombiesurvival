local PANEL = {}

PANEL.NextRefresh = 0
PANEL.RefreshTime = 1

local foreground = Color(236, 244, 245)
local muted = Color(151, 169, 179)
local background = Color(24, 36, 44, 195)
local badge = Color(48, 89, 78, 200)
local emptyBadge = Color(37, 49, 57, 170)
local hovered = Color(63, 105, 95, 220)
local buttonColor = Color(37, 54, 61, 190)

local function PaintButton(self, width, height)
 local enabled = self:IsEnabled()
 draw.RoundedBox(4 * BetterScreenScale(), 0, 0, width, height, enabled and self:IsHovered() and hovered or buttonColor)
 surface.SetDrawColor(enabled and foreground or muted)
 local x, y = width * 0.5, height * 0.5
 local arm = width * 0.18
 if self.GiveAmmo then
  surface.DrawLine(x - arm, y, x + arm, y)
  surface.DrawLine(x, y - arm, x + arm, y)
  surface.DrawLine(x, y + arm, x + arm, y)
 else
  surface.DrawLine(x, y - arm, x, y + arm)
  surface.DrawLine(x - arm, y, x, y + arm)
  surface.DrawLine(x + arm, y, x, y + arm)
 end
 return true
end

local function GetTargetEntIndex()
	return GAMEMODE.HumanMenuLockOn and GAMEMODE.HumanMenuLockOn:IsValid() and GAMEMODE.HumanMenuLockOn:EntIndex() or 0
end

local function DropDoClick(self)
	RunConsoleCommand("zsdropammo", self:GetParent():GetAmmoType())
end

local function GiveDoClick(self)
	RunConsoleCommand("zsgiveammo", self:GetParent():GetAmmoType(), GetTargetEntIndex())
end

function PANEL:Init()
	self.m_LanguageRevision = false
	self.m_AmmoCountLabel = EasyLabel(self, "0", "ZSHUDFontTinyNS", foreground)

	self.m_AmmoTypeLabel = EasyLabel(self, " ", "ZSAmmoName", foreground)

	self.m_DropButton = vgui.Create("DImageButton", self)
	self.m_DropButton.Paint = PaintButton
	self.m_DropButton.DoClick = DropDoClick

	self.m_GiveButton = vgui.Create("DImageButton", self)
	self.m_GiveButton.Paint = PaintButton
	self.m_GiveButton.GiveAmmo = true
	self.m_GiveButton.DoClick = GiveDoClick

	self:SetAmmoType("pistol")
end

function PANEL:Paint()
 local tall, scale = self:GetTall(), BetterScreenScale()
 draw.RoundedBox(5 * scale, 0, 0, self:GetWide(), tall, background)
 draw.RoundedBox(4 * scale, 6 * scale, 4 * scale, 44 * scale, tall - 8 * scale, (self.m_LastAmmoCount or 0) > 0 and badge or emptyBadge)
 return true
end

function PANEL:Think()
	local now = RealTime()
	if now >= self.NextRefresh then
		self.NextRefresh = now + self.RefreshTime
		local parent = IsValid(self.SideMenu) and self.SideMenu or self:GetParent()
		if self:IsVisible() and (not IsValid(parent) or parent:IsVisible()) then self:Refresh() end
	end
end

function PANEL:Refresh()
	local ammotype = self:GetAmmoType()
	local name = GAMEMODE.AmmoNames[ammotype] or ammotype
	local count = IsValid(MySelf) and MySelf:GetAmmoCount(ammotype) or 0
	local changed = false
	if self.m_LastAmmoName ~= name then
		self.m_LastAmmoName = name
		self.m_AmmoTypeLabel:SetText(name)
		self.m_AmmoTypeLabel:SizeToContents()
		changed = true
	end
	if self.m_LastAmmoCount ~= count then
		self.m_LastAmmoCount = count
		self.m_DropButton:SetEnabled(count > 0)
		self.m_GiveButton:SetEnabled(count > 0)
		self.m_AmmoCountLabel:SetText(count)
		self.m_AmmoCountLabel:SizeToContents()
		changed = true
	end
	local revision = translate.GetRevision and translate.GetRevision()
	if self.m_LanguageRevision ~= revision then
		self.m_LanguageRevision = revision
		self.m_DropButton:SetTooltip(translate.Get("alt_drop"))
		self.m_GiveButton:SetTooltip(translate.Get("alt_give"))
	end
	if changed then self:InvalidateLayout() end
end

function PANEL:PerformLayout()
 local scale = BetterScreenScale()
 if self.AmmoLayoutScale ~= scale then
  self.AmmoLayoutScale = scale
  self.m_AmmoCountLabel:SizeToContents()
  self.m_AmmoTypeLabel:SizeToContents()
 end
 local width, height = self:GetWide(), self:GetTall()
 local name = self.m_LastAmmoName or ""
 local revision = GAMEMODE.LegacyFontRevision
 if self.FitAmmoName ~= name or self.FitAmmoWidth ~= width or self.FitAmmoScale ~= scale or self.FitAmmoRevision ~= revision then
  self.FitAmmoName, self.FitAmmoWidth, self.FitAmmoScale, self.FitAmmoRevision = name, width, scale, revision
  self.FittedAmmoName = ZSHUDStyle.Fit(name, "ZSAmmoName", math.max(0, width - 130*scale))
 end
 local fitted = self.FittedAmmoName
 if self.m_AmmoTypeLabel:GetText() ~= fitted then self.m_AmmoTypeLabel:SetText(fitted) self.m_AmmoTypeLabel:SizeToContents() end
 self.m_AmmoTypeLabel:SetTooltip(fitted ~= name and name or nil)
 self.m_AmmoTypeLabel:SetPos(56*scale, 0)
 self.m_AmmoTypeLabel:CenterVertical()
 local count = tostring(self.m_LastAmmoCount or 0)
 if self.FitAmmoCount ~= count or self.FitCountScale ~= scale or self.FitCountRevision ~= revision then
  self.FitAmmoCount, self.FitCountScale, self.FitCountRevision = count, scale, revision
  self.FittedAmmoCount = ZSHUDStyle.Fit(count, "ZSHUDFontTinyNS", 40*scale)
 end
 local fittedCount = self.FittedAmmoCount
 if tostring(self.m_AmmoCountLabel:GetText()) ~= fittedCount then self.m_AmmoCountLabel:SetText(fittedCount) self.m_AmmoCountLabel:SizeToContents() end
 self.m_AmmoCountLabel:SetTooltip(fittedCount ~= count and count or nil)
 self.m_DropButton:SetSize(28*scale,28*scale)
 self.m_GiveButton:SetSize(28*scale,28*scale)
 self.m_DropButton:SetPos(width-68*scale,(height-28*scale)*0.5)
 self.m_GiveButton:SetPos(width-34*scale,(height-28*scale)*0.5)
 self.m_AmmoCountLabel:SetPos(28*scale-self.m_AmmoCountLabel:GetWide()*0.5,0)
 self.m_AmmoCountLabel:CenterVertical()
end

function PANEL:SetAmmoType(ammotype)
	self.m_AmmoType = ammotype

	self:Refresh()
end

function PANEL:GetAmmoType()
	return self.m_AmmoType
end

vgui.Register("DAmmoCounter", PANEL, "DPanel")
