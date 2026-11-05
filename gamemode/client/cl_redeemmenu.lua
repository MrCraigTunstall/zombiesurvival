local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
timer.Remove("ZSRedeemMenuReady")
if IsValid(GM.ZSRedeemFrame) then GM.ZSRedeemFrame:Remove() end
GM.ZSRedeemFrame = nil

local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local width, height = math.min(U(640), screenWidth - 32), math.min(U(360), screenHeight - 32)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth ~= width or frame.LayoutHeight ~= height then
  frame.LayoutWidth, frame.LayoutHeight = width, height
  frame:SetSize(width, height) frame:Center() frame:InvalidateLayout(true)
 elseif screenChanged then frame:Center()
 end
 frame.LayoutDirty = nil
end

hook.Add("OnScreenSizeChanged", "ZSRedeemMenuLayout", function()
 local frame = GAMEMODE.ZSRedeemFrame
 if not IsValid(frame) then return end
 if frame:IsVisible() then Layout(frame) else frame.LayoutDirty = true end
end)

function GM:OpenRedeemMenu()
 self:RefreshMenuScale()
 local frame = self.ZSRedeemFrame
 if not IsValid(frame) then
  frame = vgui.Create("DFrame")
  frame:SetVisible(false)
  self.ZSRedeemFrame = frame
  frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
  self:StyleShopFrame(frame)
  frame.Paint = function(_, width, height)
   draw.RoundedBox(U(8), 0, 0, width, height, GAMEMODE.ShopColors.background)
   draw.RoundedBox(U(8), 0, 0, width, U(72), GAMEMODE.ShopColors.header)
   surface.SetDrawColor(GAMEMODE.ShopColors.accent)
   surface.DrawRect(U(16), U(70), width - U(32), U(2))
  end
  frame.Heading = EasyLabel(frame, "", "ZSMenuScaledTitle", color_white)
  frame.Subtitle = EasyLabel(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
  frame.Subtitle:SetWrap(true)
  frame.LocalizedLabels = {{frame.Heading, "redeem_menu_title"}, {frame.Subtitle, "redeem_menu_description"}}
  local function Choice(title, description, primary)
   local button = vgui.Create("DButton", frame)
   self:StyleShopButton(button, primary, true) button:SetText("")
   button.Heading = EasyLabel(button, "", "ZSMenuScaledBody", primary and self.ShopColors.background or color_white)
   button.Description = EasyLabel(button, "", "ZSMenuScaledSmall", primary and self.ShopColors.background or self.ShopColors.muted)
   button.Heading:SetMouseInputEnabled(false) button.Description:SetMouseInputEnabled(false)
   button.Description:SetWrap(true)
   button.PerformLayout = function(panel, width)
    panel.Heading:SetPos(U(16), U(10)) panel.Heading:SetSize(width - U(32), U(24))
    panel.Description:SetPos(U(16), U(40)) panel.Description:SetSize(width - U(32), U(44))
   end
   frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {button.Heading, title}
   frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {button.Description, description}
   return button
  end
  frame.HumanButton = Choice("redeem_menu_human", "redeem_menu_human_description", true)
  frame.HumanButton.DoClick = function()
   if not frame:IsVisible() then return end
   local player = LocalPlayer()
   if not IsValid(player) or player:Team() ~= TEAM_REDEEMER then frame:Close() return end
   frame:Close()
   RunConsoleCommand("zs_bandit")
  end
  frame.BanditButton = Choice("redeem_menu_bandit", "redeem_menu_bandit_description")
  frame.BanditButton.DoClick = function() frame:Close() end
  frame.CloseButton = vgui.Create("DButton", frame)
  self:StyleShopButton(frame.CloseButton, false, true)
  frame.CloseButton.DoClick = function() frame:Close() end
  frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {frame.CloseButton, "redeem_menu_later"}
  frame.PerformLayout = function(panel, width, height)
   panel.Heading:SetPos(U(20), U(12)) panel.Heading:SetSize(width - U(40), U(28))
   panel.Subtitle:SetPos(U(20), U(46)) panel.Subtitle:SetSize(width - U(40), U(24))
   panel.HumanButton:SetPos(U(20), U(88)) panel.HumanButton:SetSize(width - U(40), U(96))
   panel.BanditButton:SetPos(U(20), U(196)) panel.BanditButton:SetSize(width - U(40), U(96))
   panel.CloseButton:SetPos(width - U(160), height - U(48)) panel.CloseButton:SetSize(U(140), U(32))
  end
  frame.Think = function(panel)
   if not panel:IsVisible() or CurTime() < (panel.NextCheck or 0) then return end
   panel.NextCheck = CurTime() + 0.2
   local player = LocalPlayer()
   if not IsValid(player) or player:Team() ~= TEAM_REDEEMER or not player:Alive() then panel:Close() end
  end
  frame.OnRemove = function(panel) if GAMEMODE.ZSRedeemFrame == panel then GAMEMODE.ZSRedeemFrame = nil end end
 end
 for _, entry in ipairs(frame.LocalizedLabels) do
  local value = translate.Get(entry[2])
  if entry[1].ZSRedeemText ~= value then entry[1].ZSRedeemText = value entry[1]:SetText(value) end
 end
 if frame.LayoutDirty or frame.ScreenWidth ~= ScrW() or frame.ScreenHeight ~= ScrH() then
  frame.ScreenWidth, frame.ScreenHeight = ScrW(), ScrH()
  Layout(frame)
 end
 frame.NextCheck = 0
 if frame:IsVisible() then return frame end
 frame:SetVisible(true) frame:MakePopup()
 return frame
end

function MakepRedeemMenu()
 return GAMEMODE:OpenRedeemMenu()
end

net.Receive("zs_redeemmenu", function()
 local function OpenWhenReady()
  local player = LocalPlayer()
  if not IsValid(player) or player:Team() ~= TEAM_REDEEMER or not player:Alive() then return end
  timer.Remove("ZSRedeemMenuReady")
  GAMEMODE:OpenRedeemMenu()
  return true
 end
 timer.Remove("ZSRedeemMenuReady")
 if not OpenWhenReady() then timer.Create("ZSRedeemMenuReady", 0.05, 20, OpenWhenReady) end
end)
