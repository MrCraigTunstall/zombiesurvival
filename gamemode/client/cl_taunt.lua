local gm = GM or GAMEMODE
if gm.ZSTauntMenu then gm.ZSTauntMenu:Destroy() end
local state = {nextTaunt = 0, actions = {}, byCommand = {}}
for _, action in ipairs({{"dance", ACT_GMOD_TAUNT_DANCE}, {"robot", ACT_GMOD_TAUNT_ROBOT}, {"muscle", ACT_GMOD_TAUNT_MUSCLE}, {"laugh", ACT_GMOD_TAUNT_LAUGH}, {"wave", ACT_GMOD_GESTURE_WAVE}, {"cheer", ACT_GMOD_TAUNT_CHEER}, {"zombie", ACT_GMOD_GESTURE_TAUNT_ZOMBIE}, {"salute", ACT_GMOD_TAUNT_SALUTE}, {"forward", ACT_SIGNAL_FORWARD}, {"becon", ACT_GMOD_GESTURE_BECON}, {"group", ACT_SIGNAL_GROUP}, {"disagree", ACT_GMOD_GESTURE_DISAGREE}, {"agree", ACT_GMOD_GESTURE_AGREE}}) do
 local record = {command = action[1], activity = action[2]}
 state.actions[#state.actions + 1], state.byCommand[record.command] = record, record
end
state.activityCache = include("cl_tauntactivities.lua")(state.actions, IsValid)
gm.ZSTauntMenu = state
function state:Allowed()
 local pl = LocalPlayer()
 if not IsValid(pl) or not pl:Alive() then return false, translate.Get("taunt_dead") end
 if not gm:PlayerShouldTaunt(pl, 0) then return false, translate.Get("taunt_unavailable") end
 if pl:IsPlayingTaunt() then return false, translate.Get("taunt_playing") end
 if CurTime() < self.nextTaunt then return false, translate.Get("taunt_cooldown") end
 return true, translate.Get("taunt_ready")
end
function state:Play(command)
 if self.destroyed or not self.byCommand[command] or not self:Allowed() then return false end
 self.activityCache:Refresh(LocalPlayer())
 if not self.activityCache.supported[command] then return false end
 self.nextTaunt = CurTime() + 2
 RunConsoleCommand("act", command)
 surface.PlaySound("buttons/button14.wav")
 if IsValid(self.frame) then self.frame:Close() end
 return true
end
function state:Update()
 if self.destroyed then return end
 local frame = self.frame
 if not IsValid(frame) or not frame:IsVisible() then return end
 local revision = translate.GetRevision()
 if frame.revision ~= revision then
  frame.revision = revision
  frame.title:SetText(translate.Get("taunt_title")) frame.subtitle:SetText(translate.Get("taunt_subtitle")) frame.close:SetText(translate.Get("mm_close"))
  for _,button in ipairs(frame.buttons) do button:SetText(translate.Get("taunt_" .. button.command)) end
  frame.activityRevision = nil
 end
 local enabled, status = self:Allowed()
 self.activityCache:Refresh(LocalPlayer())
 if frame.lastEnabled ~= enabled or frame.activityRevision ~= self.activityCache.revision then
  frame.lastEnabled, frame.activityRevision = enabled, self.activityCache.revision
  for _, button in ipairs(frame.buttons) do
   local supported = self.activityCache.supported[button.command]
   button:SetDisabled(not enabled or not supported)
   button:SetTooltip(supported and nil or translate.Get("taunt_model_unavailable"))
  end
 end
 if frame.lastStatus ~= status then frame.lastStatus = status frame.status:SetText(status) end
end
function state:Open()
 if self.destroyed then return end
 local frame = self.frame
 if not IsValid(frame) then
  frame = vgui.Create("DFrame") self.frame = frame
  frame:SetVisible(false)
  frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
  gm:StyleShopFrame(frame)
  local colors, background = gm.ShopColors, Color(15, 20, 26)
  frame.Paint = function(_, width, height)
   draw.RoundedBox(8, 0, 0, width, height, background)
   draw.RoundedBox(8, 0, 0, width, 72, colors.header)
   surface.SetDrawColor(colors.accent) surface.DrawRect(16, 70, width - 32, 2)
  end
  frame.title = EasyLabel(frame, translate.Get("taunt_title"), "ZSMenuTitle", color_white)
  frame.subtitle = EasyLabel(frame, translate.Get("taunt_subtitle"), "ZSMenuSmall", gm.ShopColors.muted)
  frame.status = EasyLabel(frame, "", "ZSMenuSmall", gm.ShopColors.muted) frame.status:SetWrap(true)
  frame.close = vgui.Create("DButton", frame) frame.close:SetText(translate.Get("mm_close")) gm:StyleShopButton(frame.close)
  frame.close.DoClick = function() frame:Close() end
  frame.scroll = vgui.Create("DScrollPanel", frame) frame.buttons = {}
  local bar = frame.scroll:GetVBar()
  bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, background) end
  for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
   button.Paint = function(panel, width, height) draw.RoundedBox(4, 0, 0, width, height, panel.Hovered and colors.hover or colors.row) end
  end
  for _, action in ipairs(self.actions) do
   local command = action.command
   local button = vgui.Create("DButton", frame.scroll:GetCanvas())
   button:SetText(translate.Get("taunt_" .. command)) button.command = command gm:StyleShopButton(button)
   button.DoClick = function() return self:Play(command) end
   frame.buttons[#frame.buttons + 1] = button
  end
  frame.PerformLayout = function(panel, width, height)
   panel.title:SetPos(20,12) panel.title:SetWide(width-40)
   panel.subtitle:SetPos(20,44) panel.subtitle:SetWide(width-40)
   panel.scroll:SetPos(20,88) panel.scroll:SetSize(width-40,height-160)
   panel.status:SetPos(20,height-64) panel.status:SetSize(width-160,48)
   panel.close:SetPos(width-120,height-48) panel.close:SetSize(100,32)
   local available = panel.scroll:GetWide()-18
   local columns = math.max(1,math.min(3,math.floor((available+8)/160)))
   local cardWidth = (available-(columns-1)*8)/columns
   for index,button in ipairs(panel.buttons) do button:SetSize(cardWidth,44) button:SetPos((index-1)%columns*(cardWidth+8),math.floor((index-1)/columns)*52) end
   panel.scroll:GetCanvas():SetTall(math.ceil(#panel.buttons/columns)*52-8)
  end
  frame.OnRemove = function(panel)
   panel.buttons, panel.scroll = nil, nil
   if self.frame == panel then self.frame = nil end
  end
  frame.Think = function(panel)
   if not panel:IsVisible() then return end
   local now = RealTime()
   if now < (panel.nextUpdate or 0) then return end
   panel.nextUpdate = now+0.2 self:Update()
  end
 end
 if frame.LayoutWidth ~= ScrW() or frame.LayoutHeight ~= ScrH() then
  frame.LayoutWidth, frame.LayoutHeight = ScrW(), ScrH()
  frame:SetSize(math.min(620,frame.LayoutWidth-32),math.min(420,frame.LayoutHeight-32)) frame:Center()
 end
 if frame:IsVisible() then return frame end
 frame:SetVisible(true) frame:MakePopup()
 self:Update()
 return frame
end
function state:Destroy()
 if self.destroyed then return end
 self.destroyed = true
 if IsValid(self.frame) then self.frame:Remove() end
 self.frame, self.actions, self.byCommand = nil, {}, {}
 self.activityCache.owner, self.activityCache.model, self.activityCache.count = nil, nil, nil
 self.activityCache.actions = {}
 for command in pairs(self.activityCache.supported) do self.activityCache.supported[command] = nil end
 if gm.ZSTauntMenu == self then gm.ZSTauntMenu = nil end
end
function gm:OpenTauntMenu() return state:Open() end
concommand.Add("zs_taunt_menu",function() state:Open() end)
concommand.Add("zs_taunt",function(_,_,args)
 local pl = LocalPlayer()
 local command = args[1] or (IsValid(pl) and pl:Team() == TEAM_UNDEAD and "zombie" or "wave")
 return state:Play(command)
end)
return state
