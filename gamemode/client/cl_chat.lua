local state=GM.ZSChatState or {messages={},bytes=0,sent={}}
GM.ZSChatState=state
local native=CreateClientConVar("zs_native_chat","0",true,false)
local filters={joinleave=1,namechange=2,chat=4,servermsg=8,teamchange=16}
local white=Color(240,246,247)
local inputBackground=Color(12,22,28,230)
local selection=Color(65,130,150,180)
local function Enabled()return not native:GetBool()end
local function Clip(text,limit)
 if #text<=limit then return text end
 local out,size={},0
 for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*")do
  if size+#character>limit then break end
  size=size+#character out[#out+1]=character
 end
 return table.concat(out)
end
local function Clean(text,limit)
 return Clip(tostring(text):gsub("[%z\1-\8\11\12\14-\31]",""),limit)
end
local function Link(self,url)
 if isstring(url)and (url:match("^https?://")or url:match("^steam://"))then gui.OpenURL(url)end
end
local function Append(panel,row)
 for _,part in ipairs(row.parts)do
  panel:InsertColorChange(part.r,part.g,part.b,255)
  panel:AppendTextWithURLs(part.text)
 end
 panel:AppendText("\n")
end
function state:Hide()
 if IsValid(self.panel)then self.panel:SetVisible(false)self.panel.Think=nil end
end
function state:Layout()
 if not IsValid(self.panel)then return end
 local scale=math.Clamp(ScrH()/1080,.8,2.5)
 local font=math.floor(18*scale+.5)
 if self.fontSize~=font then
  self.fontSize=font
  surface.CreateFont("ZSChatText",{font="Roboto",size=font,weight=500,antialias=true,extended=true,shadow=true})
  surface.CreateFont("ZSChatLink",{font="Roboto",size=font,weight=500,antialias=true,extended=true,shadow=true,underline=true})
  self.body:SetFontInternal("ZSChatText")self.body:SetUnderlineFont("ZSChatLink")self.entry:SetFont("ZSChatText")
 end
 local margin=math.floor(16*scale)
 local right=self.opened and ScrW()or (GAMEMODE.GetHUDRightEdge and GAMEMODE:GetHUDRightEdge()or ScrW())
 local width=math.max(120,math.min(640*scale,right-margin*2))
 local health=GAMEMODE.HealthHUD
 local bottom=IsValid(health)and health:IsVisible()and health:GetY()-margin or ScrH()-margin
 local height=math.min((self.opened and 360 or 180)*scale,math.max(80,bottom-margin))
 local x,y=margin,math.max(margin,bottom-height)
 if self.x~=x or self.y~=y or self.width~=width or self.height~=height or self.layoutOpen~=self.opened then
  self.x,self.y,self.width,self.height,self.layoutOpen=x,y,width,height,self.opened
  self.panel:SetPos(x,y)self.panel:SetSize(width,height)
  local pad=12*scale local top=self.opened and 38*scale or 0 local input=self.opened and 48*scale or 0
  self.body:SetPos(pad,top)self.body:SetSize(width-pad*2,math.max(1,height-top-input-pad))
  self.body:SetVerticalScrollbarEnabled(self.opened==true)
  self.entry:SetPos(pad,height-42*scale)self.entry:SetSize(width-pad*2,32*scale)
  self.entry:SetVisible(self.opened==true)
  self.close:SetPos(width-30*scale,6*scale)self.close:SetSize(24*scale,24*scale)self.close:SetVisible(self.opened==true)
 end
 if not self.opened then
  local remaining=(self.untilTime or 0)-CurTime()
  if remaining<=0 or not Enabled()then self:Hide()return end
  local alpha=math.floor(math.Clamp(remaining/.35,0,1)*255)
  if self.alpha~=alpha then self.alpha=alpha self.panel:SetAlpha(alpha)end
 end
end
function state:Ensure()
 if IsValid(self.panel)then return end
 local frame=vgui.Create("EditablePanel")frame:ParentToHUD()frame:SetVisible(false)
 frame:SetKeyboardInputEnabled(false)frame:SetMouseInputEnabled(false)
 frame.Paint=function(_,w,h)
  if not state.opened then return end
  draw.RoundedBox(8,0,0,w,h,ZSHUDStyle.Background)
  draw.SimpleText(state.team and "Team chat"or "Chat","ZSHUDTitle",12*state.scale,18*state.scale,white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
 end
 self.panel=frame
 self.body=vgui.Create("RichText",frame)
 self.body:SetBGColor(Color(0,0,0,0))self.body.OnTextClicked=Link
 self.body.PerformLayout=function(panel)panel:SetFontInternal("ZSChatText")panel:SetUnderlineFont("ZSChatLink")end
 self.entry=vgui.Create("DTextEntry",frame)self.entry:SetUpdateOnType(true)
 self.entry.Paint=function(entry,w,h)
  draw.RoundedBox(4,0,0,w,h,inputBackground)entry:DrawTextEntryText(white,selection,white)
 end
 self.entry.OnValueChange=function(_,text)if state.opened then hook.Run("ChatTextChanged",text)end end
 self.entry.OnEnter=function(entry)
  local text=Clean(entry:GetText():gsub("[\r\n]"," "),126):Trim()
  if text~=""then
   RunConsoleCommand(state.team and "say_team"or "say",text)
   state.sent[#state.sent+1]=text if #state.sent>32 then table.remove(state.sent,1)end
  end
  state:Close(true)
 end
 local key=self.entry.OnKeyCodeTyped
 self.entry.OnKeyCodeTyped=function(entry,code)
  if code==KEY_ESCAPE then state:Close(true)gui.HideGameUI()return end
  if code==KEY_TAB then
   local text=hook.Run("OnChatTab",entry:GetText())
   if isstring(text)then entry:SetText(text)entry:SetCaretPos(#text)end
   return
  end
  if code==KEY_UP or code==KEY_DOWN then
   state.sentIndex=math.Clamp((state.sentIndex or #state.sent+1)+(code==KEY_UP and -1 or 1),1,#state.sent+1)
   local text=state.sent[state.sentIndex]or ""entry:SetText(text)entry:SetCaretPos(#text)return
  end
  if key then return key(entry,code)end
 end
 self.close=vgui.Create("DButton",frame)self.close:SetText("×")self.close.DoClick=function()state:Close(true)end
 self.fontSize=nil self.dirty=true
end
function state:Refresh()
 self.flushQueued=false
 if not Enabled()then self:Hide()return end
 self:Ensure()self.scale=math.Clamp(ScrH()/1080,.8,2.5)
 self.panel:SetVisible(true)self.panel.Think=function()state:Layout()end
 self:Layout()
 self.body:SetText("")
 local first=self.opened and 1 or math.max(1,#self.messages-5)
 for index=first,#self.messages do Append(self.body,self.messages[index])end
 self.body:GotoTextEnd()
end
function state:Queue()
 if self.flushQueued then return end
 self.flushQueued=true
 timer.Simple(0,function()if GAMEMODE and GAMEMODE.ZSChatState==state then state:Refresh()end end)
end
function state:Add(...)
 local row={parts={},time=CurTime()}local color=white local size=0
 for index=1,select('#',...)do
  local value=select(index,...)
  if IsColor(value)then color=value
  else
   local text,tint
   if type(value)=="Player"and IsValid(value)then text=value:Nick()tint=GAMEMODE:GetTeamColor(value)else text=tostring(value)tint=color end
   text=Clean(text,math.max(0,4096-size))size=size+#text
   if text~=""then row.parts[#row.parts+1]={text=text,r=math.Clamp(tonumber(tint.r)or 255,0,255),g=math.Clamp(tonumber(tint.g)or 255,0,255),b=math.Clamp(tonumber(tint.b)or 255,0,255)}end
   if size>=4096 then break end
  end
 end
 if #row.parts==0 then return end
 if #self.messages>=128 or self.bytes+size>65536 then
  while #self.messages>64 or self.bytes+size>32768 do
   local old=table.remove(self.messages,1)if not old then break end self.bytes=self.bytes-old.bytes
  end
 end
 self.revision=(self.revision or 0)+1
 row.bytes=size self.bytes=self.bytes+size self.messages[#self.messages+1]=row
 local duration=GetConVar("hud_saytext_time")self.untilTime=CurTime()+math.Clamp(duration and duration:GetFloat()or 10,0,120)
 self:Queue()
end
function state:Open(team)
 if not Enabled()then return end
 if not self.opened then self.previousFocus=vgui.GetKeyboardFocus()end
 self.opened=true self.team=team==true self.sentIndex=#self.sent+1 self.alpha=255
 self:Refresh()self.panel:SetParent(vgui.GetWorldPanel())self.panel:SetAlpha(255)self.panel:MakePopup()self.entry:SetText("")
 self.body:SetMouseInputEnabled(true)self.entry:SetKeyboardInputEnabled(true)self.entry:RequestFocus()
 timer.Simple(0,function()if state.opened and IsValid(state.entry)then state.entry:RequestFocus()end end)
end
function state:Close(closeNative)
 if not self.opened then return end
 self.opened=false
 if IsValid(self.panel)then self.panel:SetKeyboardInputEnabled(false)self.panel:SetMouseInputEnabled(false)end
 if IsValid(self.entry)then self.entry:SetKeyboardInputEnabled(false)self.entry:KillFocus()self.entry:SetText("")end
 self:Refresh()hook.Run("ChatTextChanged","")
 if closeNative then chat.Close()end
 if IsValid(self.panel)then self.panel:ParentToHUD()end
 local previous=self.previousFocus self.previousFocus=nil
 if IsValid(previous)and previous~=self.entry and previous:IsVisible()and previous:IsKeyboardInputEnabled()then previous:RequestFocus()end
end
if not state.originals then
 state.originals=true state.nativeAdd=chat.AddText state.previousStart=GM.StartChat state.previousText=GM.ChatText state.previousOptions=GM.AddExtraOptions
 state.wrapper=function(...)state:Add(...)return state.nativeAdd(...)end
 chat.AddText=state.wrapper
end
function GM:StartChat(team)
 if not Enabled()then if state.previousStart then return state.previousStart(self,team)end return end
 state:Open(team)return true
end
function GM:ChatText(index,name,text,kind)
 local revision=state.revision
 local answer=state.previousText and state.previousText(self,index,name,text,kind)
 local setting=GetConVar("cl_chatfilters")local mask=filters[kind]
 if answer~=true and state.revision==revision and (not setting or not mask or bit.band(setting:GetInt(),mask)~=0)then state:Add(white,text)end
 return answer
end
function GM:AddExtraOptions(list,window)
 if state.previousOptions then state.previousOptions(self,list,window)end
 local check=vgui.Create("DCheckBoxLabel",window)check:SetText("Use original chat")check:SetConVar("zs_native_chat")check:SetFont("ZSHUDSmall")check:SizeToContents()list:AddItem(check)
end
hook.Add("FinishChat","ZSChat",function()state:Close(false)end)
hook.Add("HUDShouldDraw","ZSChat",function(name)if name=="CHudChat"and Enabled()then return false end end)
hook.Add("OnScreenSizeChanged","ZSChat",function()state.fontSize=nil if IsValid(state.panel)then state:Refresh()end end)
cvars.AddChangeCallback("zs_native_chat",function()
 if state.opened then state:Close(true)end
 if Enabled()then state:Queue()else state:Hide()end
end,"ZSChat")
hook.Add("ShutDown","ZSChat",function()
 state:Close(true)
 if chat.AddText==state.wrapper then chat.AddText=state.nativeAdd end
end)
