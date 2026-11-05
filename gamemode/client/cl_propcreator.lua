if IsValid(GM.ZSPropCreatorMenu)then GM.ZSPropCreatorMenu:Remove();GM.ZSPropCreatorMenu=nil end
local menu
local background=Color(14,22,34)
local warning=Color(245,125,130)
local function Idle()end
local function Layout(frame,gm)
 local scale=gm:RefreshMenuScale()
 local function U(n)return math.floor(n*scale+.5)end
 local width,height=math.min(U(620),ScrW()-24),math.min(U(324),ScrH()-24)
 if frame.LayoutWidth==width and frame.LayoutHeight==height and frame.Scale==scale then return end
 frame.LayoutWidth,frame.LayoutHeight,frame.Scale=width,height,scale
 frame:SetSize(width,height);frame:Center()
 local pad,gap=U(16),U(12)
 local header=math.min(U(64),math.floor(height*.24))
 local description=math.min(U(48),math.floor(height*.23))
 local top=header+gap+description+gap
 local cardWidth=math.floor((width-pad*2-gap*2)/3)
 local cardHeight=height-top-pad
 frame.HeaderHeight,frame.Padding=header,pad
 frame.ShowQuota=width>=U(450)
 frame.Description:SetPos(pad,header+gap);frame.Description:SetSize(width-pad*2,description)
 frame.CloseButton:SetSize(U(68),U(28));frame.CloseButton:SetPos(width-pad-U(68),math.floor((header-U(28))*.5))
 local font=cardWidth>=U(130)and "ZSMenuScaledBody"or "ZSMenuScaledSmall"
 for index,button in ipairs(frame.Buttons)do
  button:SetPos(pad+(index-1)*(cardWidth+gap),top);button:SetSize(cardWidth,cardHeight)
  button.Font=font;button.LabelY=cardHeight>=U(96)and cardHeight-U(24)or cardHeight*.5
  button.DisplayLabel=ZSHUDStyle and ZSHUDStyle.Fit(button.FullLabel,font,cardWidth-U(16))or button.FullLabel
  local icon=frame.ModelIcons[index]
  local shown=cardHeight>=U(96)
  icon:SetVisible(shown)
  if shown then
   local size=math.max(U(32),math.min(U(112),cardWidth-U(32),cardHeight-U(56)))
   icon:SetSize(size,size);icon:SetPos(math.floor((cardWidth-size)*.5),U(12))
  end
 end
 local titleWidth=width-pad*2-U(84)-(frame.ShowQuota and U(100)or 0)
 frame.DisplayTitle=ZSHUDStyle and ZSHUDStyle.Fit(frame.Title,"ZSMenuScaledTitle",titleWidth)or frame.Title
end
local function ChoicesCurrent(frame,choices,revision)
 if frame.LanguageRevision~=revision or #frame.Choices~=#choices then return false end
 for index,choice in ipairs(choices)do
  local old=frame.Choices[index]
  if old.label~=choice.label or old.model~=choice.model then return false end
 end
 return true
end
function GM:OpenPropCreator()
 local pl=LocalPlayer()
 local weapon=IsValid(pl)and pl:GetActiveWeapon()
 if not IsValid(weapon)or weapon:GetClass()~="weapon_zs_propcreator"or not pl:Alive()or pl:Team()~=TEAM_HUMAN then
  if IsValid(menu)then menu:Close()end
  return
 end
 local revision=translate.GetRevision and translate.GetRevision()
 if IsValid(menu)and not ChoicesCurrent(menu,self.PropCreatorChoices,revision)then menu:Remove()end
 if not IsValid(menu)then
  local frame=vgui.Create("DFrame");menu=frame;self.ZSPropCreatorMenu=frame
  frame:SetVisible(false);frame:SetTitle("");frame:ShowCloseButton(false)
  frame:SetDeleteOnClose(false);frame:SetDraggable(false)
  if IsValid(frame.btnMinim)then frame.btnMinim:SetVisible(false)end
  if IsValid(frame.btnMaxim)then frame.btnMaxim:SetVisible(false)end
  local colors,title=self.ShopColors,translate.Get("propcreator_name")
  frame.Title=title
  frame.Paint=function(panel,width,height)
   local scale,pad=panel.Scale or 1,panel.Padding or 16
   local header=panel.HeaderHeight or 64
   draw.RoundedBox(8*scale,0,0,width,height,background)
   draw.RoundedBox(8*scale,0,0,width,header,colors.header)
   surface.SetDrawColor(colors.accent);surface.DrawRect(pad,header-2*scale,width-pad*2,2*scale)
   draw.SimpleText(panel.DisplayTitle or title,"ZSMenuScaledTitle",pad,header*.5,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
   if panel.ShowQuota then draw.SimpleText(panel.RemainingText or "2 / 2","ZSMenuScaledBody",width-108*scale,header*.5,panel.Remaining==0 and warning or colors.accent,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)end
  end
  frame.Description=frame:Add("DLabel")
  local description=frame.Description
  description:SetWrap(true)
  description:SetFont("ZSMenuScaledBody");description:SetTextColor(colors.muted)
  frame.Buttons,frame.Choices,frame.ModelIcons,frame.LanguageRevision={},{},{},revision
  for index,choice in ipairs(self.PropCreatorChoices)do
   frame.Choices[index]={label=choice.label,model=choice.model}
   local button=frame:Add("DButton");frame.Buttons[index]=button
   button.FullLabel=translate.Get(choice.label)
   button:SetText("");self:StyleShopButton(button,false,true);button:SetTooltip(button.FullLabel)
   button.Paint=function(card,width,height)
    local scale=frame.Scale or 1
    draw.RoundedBox(6*scale,0,0,width,height,card.On and colors.selected or card.Hovered and colors.hover or colors.row)
    if card.On then surface.SetDrawColor(colors.accent);surface.DrawRect(12*scale,0,width-24*scale,2*scale)end
    draw.SimpleText(card.DisplayLabel or card.FullLabel,card.Font or "ZSMenuScaledBody",width*.5,card.LabelY or height*.5,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
   end
   local icon=button:Add("SpawnIcon");frame.ModelIcons[index]=icon
   icon:SetMouseInputEnabled(false);icon:SetKeyboardInputEnabled(false)
   icon.Think,icon.PaintOver=Idle,Idle
   icon:SetModel(choice.model)
   button.DoClick=function()
    local owner=LocalPlayer()
    if not frame:IsVisible()or not IsValid(owner)or not IsValid(frame.Weapon)or owner:GetActiveWeapon()~=frame.Weapon then return end
    RunConsoleCommand("zs_propcreator_select",tostring(index));frame:Close()
   end
  end
  frame.CloseButton=frame:Add("DButton")
  frame.CloseButton:SetSize(62,30);frame.CloseButton:SetText(translate.Get("mm_close"))
  self:StyleShopButton(frame.CloseButton,false,true);frame.CloseButton.DoClick=function()frame:Close()end
  frame.Think=function(panel)
   if not panel:IsVisible()then return end
   local now=RealTime()
   if now<(panel.NextRefresh or 0)then return end
   panel.NextRefresh=now+0.1
   local owner,active=LocalPlayer(),panel.Weapon
   if not IsValid(owner)or not owner:Alive()or owner:Team()~=TEAM_HUMAN or not IsValid(active)or owner:GetActiveWeapon()~=active then panel:Close();return end
   local remaining=active:GetRemainingProps()
   if panel.Remaining~=remaining then
    panel.Remaining=remaining;panel.RemainingText=tostring(remaining).." / 2"
    panel.Description:SetText(translate.Format("propcreator_choose",remaining));panel.Description:SetTextColor(remaining==0 and warning or colors.muted)
   end
   local selected=active:GetSelectedProp()
   if panel.Selected~=selected then
    panel.Selected=selected
    for index,button in ipairs(panel.Buttons)do button.On=index==selected end
   end
  end
  frame.OnClose=function(panel)panel.Weapon=nil;panel.NextRefresh=nil end
  frame.OnRemove=function(panel)
   panel.Weapon,panel.Buttons,panel.Choices,panel.ModelIcons=nil,nil,nil,nil
   if menu==panel then menu=nil end
   if GAMEMODE.ZSPropCreatorMenu==panel then GAMEMODE.ZSPropCreatorMenu=nil end
  end
 end
 Layout(menu,self)
 if menu.Weapon~=weapon then menu.Weapon=weapon;menu.Remaining,menu.Selected,menu.NextRefresh=nil,nil,nil end
 if menu:IsVisible()then return menu end
 menu.NextRefresh=nil;menu:SetVisible(true);menu:Think();menu:MakePopup()
 return menu
end
net.Receive("zs_propcreator_open",function()GAMEMODE:OpenPropCreator()end)
hook.Add("OnScreenSizeChanged","ZSPropCreatorLayout",function()if IsValid(menu)and menu:IsVisible()then GAMEMODE:OpenPropCreator()end end)
