local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(GM.ZSTraderFrame)then GM.ZSTraderFrame:Remove();GM.ZSTraderFrame=nil end
local nextRequest=0
local panel
local function Text(label, value)
 if label.TraderText ~= value then label.TraderText = value label:SetText(value) end
end
local function Enable(control, value)
 if control:IsEnabled() ~= value then control:SetEnabled(value) end
end
local function RefreshState(frame)
 if not frame:IsVisible() then return end
 local gm, pl, trader = GAMEMODE, MySelf, frame.Trader
 if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or gm:GetNearbyTrader(pl) ~= trader then frame:Close() return end
 local now = CurTime()
 if frame.Pending and now >= frame.Pending then frame.Pending = nil frame.Feedback = translate.Get('trader_timeout') end
 local points, classic = pl:GetPoints(), gm:IsClassicMode()
 Text(frame.Balance, translate.Format('trader_points', points))
 Text(frame.Status, frame.Feedback or translate.Get('trader_hint'))
 for _, row in ipairs(frame.Rows) do
  local entry = row.Entry
  if entry and row:IsVisible() then
   local item, price = entry.item, gm:GetTraderPrice(entry.item)
   local finite = price == price and price >= 0 and price < math.huge
   local owned = item.SWEP and pl:HasWeapon(item.SWEP) or false
   local eligible = finite and gm:IsWeaponUnlocked(item) and not (item.NoClassicMode and classic) and not item.NoodleArm and not owned
   Enable(row, not frame.Pending and eligible and points >= price)
   Text(row.Price, finite and translate.Format('trader_price', price) or translate.Get('trader_unavailable'))
   local reason = owned and translate.Get('trader_owned') or not eligible and translate.Get('trader_unavailable') or finite and points < price and translate.Get('trader_no_points') or nil
   Text(row.Description, reason or entry.description)
   if row.Reason ~= reason or row.TooltipBase ~= entry.tooltip then
    row.Reason, row.TooltipBase = reason, entry.tooltip
    row:SetTooltip(entry.tooltip .. (reason and '\n' .. reason or ''))
   end
  end
 end
end
local function Buy(row)
 local frame, entry = row.Owner, row.Entry
 if not entry or not row:IsEnabled() or frame.Pending then return end
 RefreshState(frame)
 if not frame:IsVisible() or not row:IsEnabled() then return end
 nextRequest=(nextRequest%65535)+1;frame.PendingRequest=nextRequest
 frame.Pending = CurTime() + 3 frame.Feedback = translate.Format('trader_purchasing', entry.name)
 RefreshState(frame)
 net.Start('zs_trader_buy') net.WriteEntity(frame.Trader) net.WriteString(entry.item.Signature) net.WriteUInt(frame.PendingRequest,16) net.SendToServer()
end
local function RebuildRows(frame)
 local pages = math.max(1, math.ceil(#frame.Filtered / 32))
 frame.Page = math.Clamp(frame.Page, 1, pages)
 Text(frame.PageLabel, translate.Format('trader_page', frame.Page, pages, #frame.Filtered))
 Enable(frame.Previous, frame.Page > 1) Enable(frame.NextPage, frame.Page < pages)
 local start = (frame.Page - 1) * 32
 for index = 1, math.min(32, #frame.Filtered - start) do
  local row = frame.Rows[index]
  if not IsValid(row) then
   row = vgui.Create('DButton', frame.List:GetCanvas()) frame.Rows[index] = row
   row.Owner = frame row:SetText('') row:Dock(TOP) row:DockMargin(0, 0, 0, U(6)) row:SetTall(U(64))
   GAMEMODE:StyleShopButton(row, false, true)
   row.Name = EasyLabel(row, '', 'ZSMenuScaledBody', color_white)
   row.Description = EasyLabel(row, '', 'ZSMenuScaledSmall', GAMEMODE.ShopColors.muted)
   row.Price = EasyLabel(row, '', 'ZSMenuScaledSmall', GAMEMODE.ShopColors.accent)
   for _, label in ipairs({row.Name, row.Description, row.Price}) do label:SetMouseInputEnabled(false) end
   row.Price:SetContentAlignment(6)
   row.PerformLayout = function(self, width)
    self.Name:SetPos(U(12), U(10)) self.Name:SetSize(width - U(132), U(22))
    self.Description:SetPos(U(12), U(34)) self.Description:SetSize(width - U(132), U(20))
    self.Price:SetPos(width - U(116), U(16)) self.Price:SetSize(U(104), U(28))
   end
   row.DoClick = Buy
  end
  row.Entry = frame.Filtered[start + index] row.Item = row.Entry.item
  row:SetZPos(index) if not row:IsVisible()then row:SetVisible(true)end Text(row.Name, row.Entry.name)
 end
 for index = math.min(32, #frame.Filtered - start) + 1, #frame.Rows do if frame.Rows[index]:IsVisible()then frame.Rows[index]:SetVisible(false)end frame.Rows[index].Entry, frame.Rows[index].Item = nil, nil end
 if frame.Empty:IsVisible()~=(#frame.Filtered==0)then frame.Empty:SetVisible(#frame.Filtered==0)end
 frame.List:InvalidateLayout() frame.NextUpdate = 0 RefreshState(frame)
end
local function Filter(frame,reset)
 local query = string.Trim(string.lower(frame.Search:GetValue()))
 local count = 0
 for _, entry in ipairs(frame.Entries) do
  if query == '' or string.find(entry.search, query, 1, true) then count = count + 1 frame.Filtered[count] = entry end
 end
 for index = #frame.Filtered, count + 1, -1 do frame.Filtered[index] = nil end
 frame.SearchDue=nil;if reset~=false then frame.Page=1 end;RebuildRows(frame)
end
local function Catalogue(frame)
 local gm,count,changed=GAMEMODE,0,false
 local revision=translate.GetRevision()
 local languageChanged=frame.LanguageRevision~=revision
 if languageChanged then
  changed=true
  for _,entry in ipairs(frame.LocalizedLabels)do Text(entry[1],translate.Get(entry[2]))end
  frame.Search:SetPlaceholderText(translate.Get('trader_search'))
 end
 for _,item in ipairs(gm.Items)do
  if count>=512 then break end
  if gm:IsTraderItem(item)then
   count=count+1
   local entry=frame.Entries[count]
   if not entry then entry={};frame.Entries[count]=entry end
   if languageChanged or entry.item~=item or entry.InputName~=item.Name or entry.InputDescription~=item.Description or entry.Signature~=item.Signature or entry.Worth~=item.Worth then
    changed=true
    entry.item,entry.InputName,entry.InputDescription,entry.Signature,entry.Worth=item,item.Name,item.Description,item.Signature,item.Worth
    entry.name,entry.description=gm:GetTraderItemText(item.Name),gm:GetTraderItemText(item.Description)
    entry.search=string.lower(entry.name..' '..entry.description..' '..(item.Signature or ''))
    entry.tooltip=entry.name..(entry.description~=''and '\n'..entry.description or '')
   end
  end
 end
 for index=#frame.Entries,count+1,-1 do frame.Entries[index]=nil;changed=true end
 frame.ItemsSource,frame.ItemCount,frame.LanguageRevision=gm.Items,#gm.Items,revision
 if changed then Filter(frame,false)end
 return changed
end
local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local width,height=math.min(U(780),screenWidth-32),math.min(U(680),screenHeight-32)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth==width and frame.LayoutHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth,frame.LayoutHeight=width,height
 frame:SetSize(width,height)frame:Center()frame:InvalidateLayout(true)
end
hook.Add("OnScreenSizeChanged","ZSTraderMenuLayout",function()if IsValid(panel)then Layout(panel)end end)
function GM:OpenTraderShop(trader)
 self:RefreshMenuScale()
 if not IsValid(trader) then return end
 if not IsValid(panel) then
  panel = vgui.Create('DFrame') self.ZSTraderFrame = panel
  panel:SetVisible(false)
  local frame = panel
  frame:SetTitle('') frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
  self:StyleShopFrame(frame)
  local background,colors=Color(14,22,34),self.ShopColors
  frame.Paint=function(_,width,height)
   draw.RoundedBox(8,0,0,width,height,background)
   draw.RoundedBox(U(8),0,0,width,U(72),colors.header)
   surface.SetDrawColor(colors.accent);surface.DrawRect(U(20),U(70),width-U(40),U(2))
  end
  if IsValid(frame.btnMinim)then frame.btnMinim:SetVisible(false)end
  if IsValid(frame.btnMaxim)then frame.btnMaxim:SetVisible(false)end
  frame.Title = EasyLabel(frame, translate.Get('trader_title'), 'ZSMenuScaledTitle', color_white)
  frame.Subtitle = EasyLabel(frame, translate.Get('trader_subtitle'), 'ZSMenuScaledSmall', self.ShopColors.muted)
  frame.Balance = EasyLabel(frame, '', 'ZSMenuScaledBody', self.ShopColors.accent)
  frame.Status = EasyLabel(frame, '', 'ZSMenuScaledSmall', self.ShopColors.muted) frame.Status:SetWrap(true)
  frame.Search = vgui.Create('DTextEntry', frame) frame.Search:SetFont('ZSMenuScaledBody') frame.Search:SetPlaceholderText(translate.Get('trader_search'))
  self:StyleShopSearch(frame.Search, true)
  frame.Search.OnChange = function() frame.SearchDue = CurTime() + 0.15 end
  frame.Search.OnEnter = function() Filter(frame) end
  frame.List = vgui.Create('DScrollPanel', frame)
  local bar=frame.List:GetVBar()
  bar.Paint=function(_,width,height)draw.RoundedBox(4,0,0,width,height,colors.row)end
  for _,button in ipairs({bar.btnUp,bar.btnDown,bar.btnGrip})do
   button.Paint=function(self,width,height)draw.RoundedBox(4,0,0,width,height,self:IsHovered()and colors.accent or colors.muted)end
  end
  frame.List.Paint = function(_, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
  frame.Empty = EasyLabel(frame.List, translate.Get('trader_empty'), 'ZSMenuScaledBody', self.ShopColors.muted)
  frame.Previous, frame.NextPage = vgui.Create('DButton', frame), vgui.Create('DButton', frame)
  frame.Previous:SetText(translate.Get('mm_model_previous')) frame.NextPage:SetText(translate.Get('mm_model_next'))
  self:StyleShopButton(frame.Previous, false, true) self:StyleShopButton(frame.NextPage, false, true)
  frame.Previous.DoClick = function() frame.Page = frame.Page - 1 RebuildRows(frame) end
  frame.NextPage.DoClick = function() frame.Page = frame.Page + 1 RebuildRows(frame) end
  frame.PageLabel = EasyLabel(frame, '', 'ZSMenuScaledSmall', self.ShopColors.muted) frame.PageLabel:SetContentAlignment(5)
  frame.CloseButton = vgui.Create('DButton', frame) frame.CloseButton:SetText(translate.Get('mm_close')) self:StyleShopButton(frame.CloseButton, false, true)
  frame.CloseButton.DoClick = function() frame:Close() end
  frame.LocalizedLabels = {{frame.Title, 'trader_title'}, {frame.Subtitle, 'trader_subtitle'}, {frame.Previous, 'mm_model_previous'}, {frame.NextPage, 'mm_model_next'}, {frame.CloseButton, 'mm_close'}, {frame.Empty, 'trader_empty'}}
  frame.Rows, frame.Entries, frame.Filtered, frame.Page = {}, {}, {}, 1
  frame.PerformLayout = function(self, width, height)
   self.List:GetVBar():SetWide(U(16))
   for _,row in ipairs(self.Rows)do row:SetTall(U(64))row:DockMargin(0,0,0,U(6))row:InvalidateLayout(true)end
   self.Title:SetPos(U(20), U(12)) self.Title:SetSize(width - U(40), U(28))
   self.Subtitle:SetPos(U(20), U(44)) self.Subtitle:SetSize(width - U(40), U(20))
   self.Balance:SetPos(U(20), U(80)) self.Balance:SetSize(width - U(40), U(22))
   self.Search:SetPos(U(20), U(112)) self.Search:SetSize(width - U(40), U(28))
   self.List:SetPos(U(20), U(152)) self.List:SetSize(width - U(40), height - U(288))
   self.Empty:SetPos(U(12), U(12)) self.Empty:SetSize(width - U(82), U(44))
   self.Status:SetPos(U(20), height - U(126)) self.Status:SetSize(width - U(40), U(36))
   self.Previous:SetPos(U(20), height - U(84)) self.Previous:SetSize(U(100), U(28))
   self.NextPage:SetPos(width - U(120), height - U(84)) self.NextPage:SetSize(U(100), U(28))
   self.PageLabel:SetPos(U(128), height - U(84)) self.PageLabel:SetSize(width - U(256), U(28))
   self.CloseButton:SetPos(width - U(120), height - U(48)) self.CloseButton:SetSize(U(100), U(32))
  end
  frame.Think = function(self)
   if not self:IsVisible() then return end
   local now = CurTime()
   if self.SearchDue and now >= self.SearchDue then Filter(self) end
   if now < (self.NextUpdate or 0) then return end
   self.NextUpdate = now + 0.2
   if self.ItemsSource ~= GAMEMODE.Items or self.ItemCount ~= #GAMEMODE.Items or self.LanguageRevision ~= translate.GetRevision() then Catalogue(self) end
   RefreshState(self)
  end
  frame.OnRemove = function(self)
   if GAMEMODE.ZSTraderFrame == self then GAMEMODE.ZSTraderFrame = nil end
   if panel == self then panel = nil end
   self.Trader,self.Rows,self.Entries,self.Filtered,self.PendingRequest,self.LocalizedLabels=nil,nil,nil,nil,nil,nil
  end
 end
 local changedTrader=panel.Trader~=trader
 if changedTrader then panel.Pending,panel.PendingRequest,panel.Feedback=nil,nil,nil end
 panel.Trader=trader
 Layout(panel)
 local changedCatalogue=Catalogue(panel)
 if panel:IsVisible()then
  if changedTrader and not changedCatalogue then RefreshState(panel)end
  return panel
 end
 panel.NextUpdate=0;panel:SetVisible(true);RefreshState(panel);if panel:IsVisible()then panel:MakePopup()end
 return panel
end
net.Receive('zs_trader_open', function()
 local trader, worth = net.ReadEntity(), net.ReadBool()
 if not IsValid(trader) then return end
 if worth then MakepWorth() else GAMEMODE:OpenTraderShop(trader) end
end)
net.Receive('zs_trader_result', function()
 local trader,request=net.ReadEntity(),net.ReadUInt(16)
 local ok,message=net.ReadBool(),net.ReadString()
 if not IsValid(panel)or panel.Trader~=trader or panel.PendingRequest~=request then return end
 panel.Pending,panel.PendingRequest,panel.NextUpdate,panel.Feedback=nil,nil,0,message
 if panel:IsVisible()then Text(panel.Status,message)end
 surface.PlaySound(ok and 'ambient/levels/labs/coinslot1.wav'or 'buttons/button10.wav')
end)
