local PANEL = {}
local menus = setmetatable({}, {__mode = "k"})
local background = Color(14, 21, 28, 222)
local track = Color(24, 33, 44, 200)
local grip = Color(107, 229, 177, 180)
local border = Color(158, 180, 190, 45)
local action = Color(28, 42, 49, 215)
local hovered = Color(40, 65, 67, 235)

local function PaintAction(self, width, height)
 local scale = BetterScreenScale()
 draw.RoundedBox(5 * scale, 0, 0, width, height, self:IsHovered() and hovered or action)
 return false
end

local function U(value, scale) return math.floor(value * scale + 0.5) end

PANEL.Spacing = 4
PANEL.SlideTime = 0

function PANEL:Init()
 menus[self] = true
 self.Items = {}
 self.Scroll = vgui.Create("DScrollPanel", self)
 self.Scroll.Paint = function() end
 local bar = self.Scroll:GetVBar()
 bar:SetHideButtons(true)
 bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, track) end
 bar.btnGrip.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, grip) end
 self:RefreshSize()
 self:SetPos(ScrW() - 1, 0)
end

function PANEL:Think()
 if self.CloseTime and RealTime() >= self.CloseTime then
  self.CloseTime = nil
  self:SetVisible(false)
 elseif self.StartChecking and RealTime() >= self.StartChecking and (not IsValid(MySelf) or not GAMEMODE:IsHumanMenuKeyDown(MySelf)) then
  self:CloseMenu()
 end
end

function PANEL:RefreshSize()
 local scale, width, height = BetterScreenScale(), ScrW(), ScrH()
 if self.LayoutScale == scale and self.LayoutWidth == width and self.LayoutHeight == height and not self.LayoutItemsDirty then return end
 if self.ContentHeight and self.Scroll:GetTall() > 0 and self.ContentHeight > self.Scroll:GetTall() then
  self.ScrollFraction = math.Clamp(self.Scroll:GetVBar():GetScroll() / (self.ContentHeight - self.Scroll:GetTall()), 0, 1)
 end
 self.PendingScrollFraction = self.ScrollFraction
 self.LayoutScale, self.LayoutWidth, self.LayoutHeight = scale, width, height
 self.LayoutItemsDirty = nil
 self:SetSize(U(320, scale), height)
 self.Spacing = U(4, scale)
 for _, item in ipairs(self.Items) do
  if IsValid(item) then
   if item.GetAmmoType then
    item:SetTall(U(36, scale))
   elseif item.SetFont then
    item:SetFont("ZSHUDFontTinyNS")
    item:SetTall(U(32, scale))
    item:SetTextColor(ZSHUDStyle.Text)
    item:SetContentAlignment(4)
    item:SetTextInset(U(12, scale), 0)
    item.Paint = PaintAction
   end
   item:InvalidateLayout(true)
  end
 end
 if self:IsVisible() then self:SetPos(width - self:GetWide(), 0) end
 self:InvalidateLayout(true)
end

function PANEL:OpenMenu()
 if self.StartChecking and RealTime() < self.StartChecking then return end
 self.CloseTime = nil
 self:RefreshSize()
 if self:IsVisible() and self.StartChecking then return end
 self:SetPos(ScrW() - self:GetWide(), 0)
 self:SetVisible(true)
 self:MakePopup()
 self.StartChecking = RealTime() + 0.1
 timer.Simple(0, function()
  if IsValid(self) and self:IsVisible() then gui.SetMousePos(ScrW() - self:GetWide() * 0.5, ScrH() * 0.5) end
 end)
end

function PANEL:CloseMenu()
 if self.CloseTime then return end
 self.StartChecking = nil
 self.CloseTime = RealTime() + self.SlideTime
end

function PANEL:Paint(width, height)
 local scale = self.LayoutScale or BetterScreenScale()
 local inset = U(16, scale)
 draw.RoundedBox(8 * scale, U(8, scale), U(8, scale), width - U(16, scale), height - U(16, scale), background)
 surface.SetDrawColor(border)
 surface.DrawRect(inset, U(58, scale), width - inset * 2, 1)
 draw.SimpleText(self.TitleText or "", "ZSHUDTitle", inset, U(12, scale), ZSHUDStyle.Text)
 draw.SimpleText(self.HintText or "", "ZSHUDFontTinyNS", inset, U(40, scale), ZSHUDStyle.Muted)
 draw.SimpleText(self.AmmoText or "", "ZSHUDFontTinyNS", inset, U(64, scale), ZSHUDStyle.Accent)
 local bar = self.Scroll:GetVBar()
 local right = width - inset - (bar.Enabled and bar:GetWide() or 0)
 draw.SimpleText(self.DropText or "", "ZSHUDFontTinyNS", right - U(54, scale), U(64, scale), ZSHUDStyle.Muted, TEXT_ALIGN_CENTER)
 draw.SimpleText(self.GiveText or "", "ZSHUDFontTinyNS", right - U(20, scale), U(64, scale), ZSHUDStyle.Muted, TEXT_ALIGN_CENTER)
 draw.SimpleText(self.ActionsText or "", "ZSHUDFontTinyNS", inset, self.ActionsTop - U(24, scale), ZSHUDStyle.Accent)
end

function PANEL:AddItem(item)
 item.SideMenu = self
 item:SetParent(item.GetAmmoType and self.Scroll:GetCanvas() or self)
 item:SetWide(self:GetWide() - U(16, BetterScreenScale()))
 self.Items[#self.Items + 1] = item
 self.LayoutItemsDirty = true
 self:InvalidateLayout()
end

function PANEL:RemoveItem(item)
 for index, current in ipairs(self.Items) do
  if current == item then
   item:Remove()
   table.remove(self.Items, index)
   self.LayoutItemsDirty = true
   self:InvalidateLayout()
   break
  end
 end
end

function PANEL:PerformLayout()
 if not IsValid(self.Scroll) then return end
 local scale = self.LayoutScale or BetterScreenScale()
 local total, count, actions = 0, 0, 0
 for _, item in ipairs(self.Items) do
  if IsValid(item) then
   if item.GetAmmoType then total = total + item:GetTall() count = count + 1
   else actions = actions + 1 end
  end
 end
 total = total + math.max(0, count - 1) * self.Spacing
 self.ContentHeight = total
 local inset, top = U(16, scale), U(86, scale)
 local actionHeight = actions * U(32, scale) + math.max(0, actions - 1) * U(6, scale)
 self.ActionsTop = self:GetTall() - inset - actionHeight
 local height = math.max(1, self.ActionsTop - U(38, scale) - top)
 self.Scroll:SetPos(inset, top)
 self.Scroll:SetSize(self:GetWide() - inset * 2, height)
 local bar = self.Scroll:GetVBar()
 bar:SetWide(U(12, scale))
 local width = self.Scroll:GetWide() - (total > height and bar:GetWide() or 0)
 local y, actionY = 0, self.ActionsTop
 for _, item in ipairs(self.Items) do
  if IsValid(item) then
   local itemWidth = item.GetAmmoType and width or self:GetWide() - inset * 2
   if item:GetWide() ~= itemWidth then item:SetWide(itemWidth) end
   item:SetPos(item.GetAmmoType and 0 or inset, item.GetAmmoType and y or actionY)
   if item.SourceText then
    local text = ZSHUDStyle.Fit(item.SourceText, "ZSHUDFontTinyNS", itemWidth - 24 * scale)
    if item:GetText() ~= text then item:SetText(text) end
    item:SetTooltip(text ~= item.SourceText and item.SourceText or nil)
   end
   if item.GetAmmoType then y = y + item:GetTall() + self.Spacing
   else actionY = actionY + item:GetTall() + U(6, scale) end
  end
 end
 if self.HeaderSource then
  local space = self:GetWide() - inset * 2
  self.TitleText = ZSHUDStyle.Fit(self.HeaderSource.title, "ZSHUDTitle", space)
  self.HintText = ZSHUDStyle.Fit(self.HeaderSource.hint, "ZSHUDFontTinyNS", space)
  self.AmmoText = ZSHUDStyle.Fit(self.HeaderSource.ammo, "ZSHUDFontTinyNS", math.max(0, width - U(84, scale)))
  self.DropText = ZSHUDStyle.Fit(self.HeaderSource.drop, "ZSHUDFontTinyNS", U(32, scale))
  self.GiveText = ZSHUDStyle.Fit(self.HeaderSource.give, "ZSHUDFontTinyNS", U(32, scale))
  self.ActionsText = ZSHUDStyle.Fit(self.HeaderSource.actions, "ZSHUDFontTinyNS", space)
 end
 self.Scroll:InvalidateLayout(true)
 if self.PendingScrollFraction then
  bar:SetScroll(math.max(0, total - height) * self.PendingScrollFraction)
  self.PendingScrollFraction = nil
 end
end

hook.Add("OnScreenSizeChanged", "ZSSideMenuSize", function()
 for menu in pairs(menus) do if IsValid(menu) then menu:RefreshSize() end end
end)

vgui.Register("DSideMenu", PANEL, "DPanel")
