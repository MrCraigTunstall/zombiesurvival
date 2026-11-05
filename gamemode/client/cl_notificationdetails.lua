local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(GM.ZSNotificationDetailsFrame) then GM.ZSNotificationDetailsFrame:Remove() end
GM.ZSNotificationDetailsFrame = nil

local function LayoutDetails(frame)
 GAMEMODE:RefreshMenuScale()
 local width = math.min(U(640), ScrW() - 32)
 frame:SetWide(width)
 frame.Scroll:SetWide(width - U(40))
 frame.Text:SetWide(width - U(58))
 if frame.TextScale~=GAMEMODE.MenuScale then
  frame.TextScale=GAMEMODE.MenuScale
  local text=frame.Text.PlainText or ""
  frame.Text.Parts,frame.Text.PlainText={},nil
  frame.Text:AddLabel(text,nil,"ZSMenuScaledBody")
 end
 frame.Text:UpdateCard()
 frame:SetTall(math.Clamp(frame.Text:GetTall() + U(152), U(220), math.min(U(520), ScrH() - 32)))
 frame:InvalidateLayout(true)
 frame:Center()
 frame.LayoutWidth, frame.LayoutHeight = ScrW(), ScrH()
 frame.LayoutDirty = nil
end

hook.Add("OnScreenSizeChanged", "ZSNotificationDetailsLayout", function()
 local frame = GAMEMODE.ZSNotificationDetailsFrame
 if not IsValid(frame) then return end
 if frame:IsVisible() then LayoutDetails(frame) else frame.LayoutDirty = true end
end)

function GM:OpenNotificationDetails()
 self:RefreshMenuScale()
 local text = self.NotificationDetailsText or translate.Get("notification_details_empty")
 local frame = self.ZSNotificationDetailsFrame
 if not IsValid(frame) then
  frame = vgui.Create("DFrame")
  frame:SetVisible(false)
  self.ZSNotificationDetailsFrame = frame
  frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
  self:StyleShopFrame(frame)
  local background, colors = Color(15, 20, 26), self.ShopColors
  frame.Paint = function(_, width, height)
   draw.RoundedBox(8, 0, 0, width, height, background)
   draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
   surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
  end
  local nativeThink = frame.Think
  frame.Think = function(panel)
   if not panel:IsVisible() then return end
   return nativeThink(panel)
  end
  frame.Heading = EasyLabel(frame, "", "ZSMenuScaledTitle", color_white)
  frame.Subtitle = EasyLabel(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
  frame.Scroll = vgui.Create("DScrollPanel", frame)
  frame.Scroll.Paint = function(_, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
  local bar = frame.Scroll:GetVBar()
  bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, background) end
  for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
   button.Paint = function(panel, width, height) draw.RoundedBox(4, 0, 0, width, height, panel.Hovered and colors.hover or colors.row) end
  end
  frame.Text = vgui.Create("DEXNotification", frame.Scroll)
  frame.Text.DetailMode = true
  frame.Text.Paint = function() return true end
  frame.Text:SetMouseInputEnabled(false)
  frame.BackButton = vgui.Create("DButton", frame)
  self:StyleShopButton(frame.BackButton, false, true)
  frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
  frame.CloseButton = vgui.Create("DButton", frame)
  self:StyleShopButton(frame.CloseButton, false, true)
  frame.CloseButton.DoClick = function() frame:Close() end
  frame.LocalizedLabels = {{frame.Heading, "notification_details_title"}, {frame.Subtitle, "notification_details_description"}, {frame.BackButton, "mm_back"}, {frame.CloseButton, "mm_close"}}
  frame.PerformLayout = function(panel, width, height)
   panel.Heading:SetPos(U(20), U(12)) panel.Heading:SetSize(width - U(40), U(28))
   panel.Subtitle:SetPos(U(20), U(44)) panel.Subtitle:SetSize(width - U(40), U(20))
   panel.Scroll:GetVBar():SetWide(U(16))
   panel.Scroll:SetPos(U(20), U(88)) panel.Scroll:SetSize(width - U(40), height - U(152))
   panel.Text:SetWide(width - U(58)) panel.Text:UpdateCard()
   panel.BackButton:SetPos(U(20), height - U(48)) panel.BackButton:SetSize(U(100), U(32))
   panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
  end
  frame.OnRemove = function(panel)
   panel.Text, panel.Scroll, panel.LocalizedLabels = nil, nil, nil
   if GAMEMODE.ZSNotificationDetailsFrame == panel then GAMEMODE.ZSNotificationDetailsFrame = nil end
  end
 end
 for _, entry in ipairs(frame.LocalizedLabels) do
  local value = translate.Get(entry[2])
  if entry[1].ZSDetailsText ~= value then entry[1].ZSDetailsText = value entry[1]:SetText(value) end
 end
 local changed = frame.Text.PlainText ~= text
 if changed then
  frame.Text.Parts, frame.Text.PlainText = {}, nil
  frame.Text:AddLabel(text,nil,"ZSMenuScaledBody")
 end
 if changed or frame.LayoutDirty or frame.LayoutWidth ~= ScrW() or frame.LayoutHeight ~= ScrH() then LayoutDetails(frame) end
 if changed then frame.Scroll:GetVBar():SetScroll(0) end
 if frame:IsVisible() then return frame end
 frame:SetVisible(true) frame:MakePopup()
 return frame
end
