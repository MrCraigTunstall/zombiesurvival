local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(GM.ZSBeaconFrame) then GM.ZSBeaconFrame:Remove() end
GM.ZSBeaconFrame = nil

local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local width, height = math.min(U(560), screenWidth - 32), math.min(U(600), screenHeight - 32)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth ~= width or frame.LayoutHeight ~= height then
  frame.LayoutWidth, frame.LayoutHeight = width, height
  frame:SetSize(width, height) frame:Center() frame:InvalidateLayout(true)
 elseif screenChanged then frame:Center()
 end
 frame.LayoutDirty = nil
end

hook.Add("OnScreenSizeChanged", "ZSBeaconMenuLayout", function()
 local frame = GAMEMODE.ZSBeaconFrame
 if not IsValid(frame) then return end
 if frame:IsVisible() then Layout(frame) else frame.LayoutDirty = true end
end)

function GM:OpenBeaconMenu(weapon)
 self:RefreshMenuScale()
 local player = LocalPlayer()
 if not IsValid(player) or not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_messagebeacon" or weapon:GetOwner() ~= player or player:GetActiveWeapon() ~= weapon then return end
 local frame = self.ZSBeaconFrame
 local alreadyVisible = IsValid(frame) and frame:IsVisible() and frame.Weapon == weapon
 if not IsValid(frame) then
  frame = vgui.Create("DFrame")
  frame:SetVisible(false)
  self.ZSBeaconFrame = frame
  frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
  self:StyleShopFrame(frame)
  frame.Paint = function(_, width, height)
   draw.RoundedBox(U(8), 0, 0, width, height, GAMEMODE.ShopColors.background)
   draw.RoundedBox(U(8), 0, 0, width, U(72), GAMEMODE.ShopColors.header)
   surface.SetDrawColor(GAMEMODE.ShopColors.accent)
   surface.DrawRect(U(16), U(70), width - U(32), U(2))
  end
  frame.Heading = EasyLabel(frame, "", "ZSMenuScaledTitle", color_white)
  frame.Description = EasyLabel(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
  frame.Description:SetWrap(true)
  frame.Scroll = vgui.Create("DScrollPanel", frame)
  local bar = frame.Scroll:GetVBar()
  bar:SetWide(U(8)) bar:SetHideButtons(true)
  bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, GAMEMODE.ShopColors.row) end
  bar.btnGrip.Paint = function(panel, width, height) draw.RoundedBox(4, 0, 0, width, height, panel.Hovered and GAMEMODE.ShopColors.accent or GAMEMODE.ShopColors.muted) end
  frame.Rows = {}
  frame.Empty = EasyLabel(frame, "", "ZSMenuScaledBody", self.ShopColors.muted)
  frame.Empty:SetContentAlignment(5)
  frame.ApplyButton = vgui.Create("DButton", frame)
  self:StyleShopButton(frame.ApplyButton, true, true)
  frame.ApplyButton.DoClick = function()
   if not frame:IsVisible() then return end
   local player, weapon = LocalPlayer(), frame.Weapon
   if not IsValid(player) or not IsValid(weapon) or weapon:GetOwner() ~= player or player:GetActiveWeapon() ~= weapon or not GAMEMODE.ValidBeaconMessages[frame.Choice] then frame:Close() return end
   RunConsoleCommand("setmessagebeaconmessage", tostring(frame.Choice))
   frame:Close()
  end
  frame.CloseButton = vgui.Create("DButton", frame)
  self:StyleShopButton(frame.CloseButton, false, true)
  frame.CloseButton.DoClick = function() frame:Close() end
  frame.LocalizedLabels = {{frame.Heading, "beacon_menu_title"}, {frame.Description, "beacon_menu_description"}, {frame.Empty, "beacon_menu_empty"}, {frame.ApplyButton, "beacon_menu_apply"}, {frame.CloseButton, "mm_close"}}
  frame.PerformLayout = function(panel, width, height)
   panel.Scroll:GetVBar():SetWide(U(8))
   for _, row in ipairs(panel.Rows) do
    row:SetTextInset(U(12), 0) row:SetTall(U(34)) row:DockMargin(0, 0, 0, U(4))
   end
   panel.Heading:SetPos(U(20), U(12)) panel.Heading:SetSize(width - U(40), U(28))
   panel.Description:SetPos(U(20), U(82)) panel.Description:SetSize(width - U(40), U(36))
   panel.Scroll:SetPos(U(20), U(130)) panel.Scroll:SetSize(width - U(40), height - U(198))
   panel.Empty:SetPos(U(20), U(130)) panel.Empty:SetSize(width - U(40), height - U(198))
   panel.CloseButton:SetPos(U(20), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
   panel.ApplyButton:SetPos(width - U(180), height - U(48)) panel.ApplyButton:SetSize(U(160), U(32))
  end
  frame.Think = function(panel)
   if not panel:IsVisible() or CurTime() < (panel.NextCheck or 0) then return end
   panel.NextCheck = CurTime() + 0.2
   local player, weapon = LocalPlayer(), panel.Weapon
   if not IsValid(player) or not player:Alive() or not IsValid(weapon) or weapon:GetOwner() ~= player or player:GetActiveWeapon() ~= weapon then panel:Close() end
  end
  frame.OnClose = function(panel) panel.Weapon = nil end
  frame.OnRemove = function(panel)
   panel.Weapon, panel.Rows = nil, nil
   if GAMEMODE.ZSBeaconFrame == panel then GAMEMODE.ZSBeaconFrame = nil end
  end
 end
 frame.Weapon = weapon
 local messages = self.ValidBeaconMessages
 frame.Choice = math.Clamp(alreadyVisible and frame.Choice or weapon:GetSelectedMessageID(), 1, math.max(1, #messages))
 for _, entry in ipairs(frame.LocalizedLabels) do
  local text = translate.Get(entry[2])
  if entry[1].ZSBeaconText ~= text then entry[1].ZSBeaconText = text entry[1]:SetText(text) end
 end
 for index, key in ipairs(messages) do
  local row = frame.Rows[index]
  if not IsValid(row) then
   row = vgui.Create("DButton", frame.Scroll)
   frame.Rows[index] = row
   self:StyleShopButton(row, false, true) row:SetFont("ZSMenuScaledBody") row:SetContentAlignment(4)
   row:SetTextInset(U(12), 0) row:SetTall(U(34)) row:Dock(TOP) row:DockMargin(0, 0, 0, U(4))
   row.Index = index
   row.Paint = function(panel, width, height) GAMEMODE.PaintShopItem(panel, width, height) end
   row.DoClick = function(panel)
    frame.Choice = panel.Index
    for _, other in ipairs(frame.Rows) do other.On = other.Index == panel.Index end
   end
  end
  local text = translate.Get(key)
  if row.ZSBeaconText ~= text then row.ZSBeaconText = text row:SetText(text) row:SetTooltip(text) end
  row:SetVisible(true) row.On = index == frame.Choice
 end
 for index = #messages + 1, #frame.Rows do frame.Rows[index]:SetVisible(false) end
 frame.Empty:SetVisible(#messages == 0) frame.ApplyButton:SetEnabled(#messages > 0)
 if frame.LayoutDirty or frame.ScreenWidth ~= ScrW() or frame.ScreenHeight ~= ScrH() then
  frame.ScreenWidth, frame.ScreenHeight = ScrW(), ScrH() Layout(frame)
 end
 if alreadyVisible then return frame end
 frame.Scroll:GetVBar():SetScroll(0)
 frame.NextCheck = 0
 frame:SetVisible(true) frame:MakePopup()
 return frame
end

net.Receive("zs_beaconmenu", function() GAMEMODE:OpenBeaconMenu(net.ReadEntity()) end)
