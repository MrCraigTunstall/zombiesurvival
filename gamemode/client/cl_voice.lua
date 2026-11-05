local createRegistry = include("cl_voice_registry.lua")
local function Visible(panel,visible)
 if panel:IsVisible()~=visible then panel:SetVisible(visible)end
end
local function Install()
local gm = GAMEMODE
if gm.ZSVoiceHUD then gm.ZSVoiceHUD:Destroy() end
local cv = CreateClientConVar("zs_custom_voice", "1", true, false, translate.Get("custom_voice_desc"))
local state = {rows = {}, nextUpdate = 0, baseStart = gm.PlayerStartVoice, baseEnd = gm.PlayerEndVoice, alive = true}
local maxPlayers = game.MaxPlayers()
state.registry = createRegistry(RealTime, function(index) return type(index) == "number" and index >= 1 and index <= maxPlayers and index % 1 == 0 end)
gm.ZSVoiceHUD = state
local background, muted = Color(22, 30, 39, 245), Color(175, 189, 202)
local accents = {[TEAM_HUMAN] = Color(80, 205, 135), [TEAM_UNDEAD] = Color(240, 112, 115), [TEAM_REDEEMER] = Color(225, 177, 85)}
local function Delegate(fn, self, pl, index)
 if not fn then return end
 local previous = state.delegating
 state.delegating = true
 local ok, a, b, c = pcall(fn, self, pl, index)
 state.delegating = previous
 if not ok then error(a) end
 return a, b, c
end
local function Index(pl, index)
 return index or IsValid(pl) and pl:EntIndex() or nil
end
local function Build()
 if IsValid(state.panel) then return end
 local panel = vgui.Create("DPanel")
 state.panel = panel
 panel:ParentToHUD() panel:SetMouseInputEnabled(false) panel:SetKeyboardInputEnabled(false)
 panel:SetPaintBackground(false)
 panel.Paint = function(self, width, height)
  draw.RoundedBox(4, 0, 0, math.min(width, state.headerWidth), 22, background)
  draw.SimpleText(state.header, "ZSMenuSmall", 8, 4, color_white)
  if state.lastOverflow and state.lastOverflow > 0 then draw.RoundedBox(4, 0, height - 24, width, 24, background) end
 end
 for index = 1, 6 do
  local row = vgui.Create("DPanel", panel)
  state.rows[index] = row
  row:SetMouseInputEnabled(false) row:SetKeyboardInputEnabled(false)
  row.Avatar = vgui.Create("AvatarImage", row)
  row.Avatar:SetSize(32, 32) row.Avatar:SetPos(12, 7)
  row.Avatar:SetMouseInputEnabled(false)
  row.Name = vgui.Create("DLabel", row)
  row.Name:SetFont("ZSMenuBody") row.Name:SetTextColor(color_white)
  row.Name:SetPos(56, 6) row.Name:SetTall(24)
  row.Paint = function(self, width, height)
   local record = self.Record
   if not record then return end
   local accent = self.Accent or muted
   draw.RoundedBox(6, 0, 0, width, height, background)
   surface.SetDrawColor(accent) surface.DrawRect(0, 8, 3, height - 16)
   local _, volume = util.IsPlayerSpeaking(record.player)
   self.Level = math.Approach(self.Level or 0, math.Clamp(volume or 0, 0, 1), FrameTime() * 4)
   surface.SetDrawColor(45, 57, 69) surface.DrawRect(56, height - 11, width - 68, 3)
   surface.SetDrawColor(accent) surface.DrawRect(56, height - 11, (width - 68) * self.Level, 3)
   if not IsValid(self.Player) then draw.SimpleText("?", "ZSMenuBody", 28, 21, muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
  end
  row.Think=function(self)
   if not state.showing or not self:IsVisible()then return end
   local record=self.Record
   if not record then return end
   local alpha=record.ending and math.Clamp((record.ending-RealTime())/0.4,0,1)*255 or 255
   if self.VoiceAlpha~=alpha then self.VoiceAlpha=alpha;self:SetAlpha(alpha)end
  end
  row:SetVisible(false)
 end
 state.Overflow = vgui.Create("DLabel", panel)
 state.Overflow:SetFont("ZSMenuSmall") state.Overflow:SetTextColor(color_white)
end
function state:Update(force)
 if not self.alive or not force and RealTime() < self.nextUpdate then return end
 self.nextUpdate = RealTime() + 0.1
 local revision = translate.GetRevision()
 if self.languageRevision ~= revision then
  self.languageRevision = revision
  self.header = translate.Get("voice_chat")
  surface.SetFont("ZSMenuSmall")
  self.headerWidth = surface.GetTextSize(self.header) + 16
  self.lastOverflow = nil
 end
 local visible, overflow = self.registry:Tick(cv:GetBool() and 6 or 0)
 if #visible == 0 then
  self.showing=false
  if IsValid(self.panel)then
   Visible(self.panel,false)
   for _,row in ipairs(self.rows)do row.Record=nil end
  end
  return
 end
 Build()
 local width, height = math.min(292, ScrW() - 32), 28 + #visible * 52 + (overflow > 0 and 24 or 0)
 if self.width ~= width or self.height ~= height or self.screenWidth ~= ScrW() or self.screenHeight ~= ScrH() then
  self.width, self.height, self.screenWidth, self.screenHeight = width, height, ScrW(), ScrH()
  self.panel:SetSize(width, height)
  self.panel:SetPos(ScrW() - width - 16, math.min(math.floor(ScrH() * 0.22), ScrH() - height - 16))
  for index, row in ipairs(self.rows) do row:SetPos(0, 28 + (index - 1) * 52) row:SetSize(width, 46) row.Name:SetWide(width - 68) end
  self.Overflow:SetPos(4, 28 + #visible * 52) self.Overflow:SetSize(width - 8, 24)
 end
 for index, row in ipairs(self.rows) do
  local record = visible[index]
  row.Record = record
  Visible(row,record~=nil)
  if record then
   local pl = Entity(record.player)
   if row.Player ~= pl then row.Player = pl row.Level = 0 row.Avatar:SetPlayer(IsValid(pl) and pl or NULL, 32) end
   Visible(row.Avatar,IsValid(pl))
   local name = IsValid(pl) and pl:Nick() or translate.Format("voice_unknown_player", record.player)
   if row.LastName ~= name then row.LastName = name row.Name:SetText(name) end
   row.Accent = IsValid(pl) and accents[pl:Team()] or muted
  end
 end
 if self.lastOverflow ~= overflow then self.lastOverflow = overflow self.Overflow:SetText(translate.Format("voice_more_speaking", overflow)) end
 Visible(self.Overflow,overflow>0)
 self.showing=true;Visible(self.panel,true)
end
function state:ApplyMode()
 if IsValid(g_VoicePanelList) then
  if self.defaultVisible == nil then self.defaultVisible = g_VoicePanelList:IsVisible() end
  g_VoicePanelList:SetVisible(not cv:GetBool())
 end
 for _, record in ipairs(self.registry.order) do
  if not record.ending and not record.removed then
   local pl = Entity(record.player)
   Delegate(cv:GetBool() and self.baseEnd or self.baseStart, gm, pl, record.player)
  end
 end
 self:Update(true)
end
state.start = function(self, pl, index)
 index = Index(pl, index)
 if not state.alive or state.delegating then return Delegate(state.baseStart,self,pl,index)end
 if not state.registry:Start(index) then return Delegate(state.baseStart, self, pl, index) end
 if not cv:GetBool() then return Delegate(state.baseStart, self, pl, index) end
 state.nextUpdate = 0
end
state.finish = function(self, pl, index)
 index = Index(pl, index)
 if not state.alive or state.delegating then return state.baseEnd and state.baseEnd(self,pl,index)end
 state.registry:End(index)
 if not cv:GetBool() then return Delegate(state.baseEnd, self, pl, index) end
end
gm.PlayerStartVoice, gm.PlayerEndVoice = state.start, state.finish
hook.Add("Think", "ZSVoiceHUD", function() if state.registry.count > 0 then state:Update() end end)
hook.Add("EntityRemoved", "ZSVoiceHUD", function(ent) if getmetatable(ent) == FindMetaTable("Player") then state.registry:Remove(ent:EntIndex()) end end)
hook.Add("HUDShouldDraw", "ZSVoiceHUD", function(name) if cv:GetBool() and (name == "CHudVoiceStatus" or name == "CHudVoiceSelfStatus") then return false end end)
hook.Add("InitPostEntity", "ZSVoiceHUD", function() timer.Simple(0, function() if state.alive then state:ApplyMode() end end) end)
cvars.AddChangeCallback("zs_custom_voice", function() if state.alive then state:ApplyMode() end end, "ZSVoiceHUD")
function state:Destroy()
 if not self.alive then return end
 self.alive,self.showing=false,false
 for _, event in ipairs({"Think", "EntityRemoved", "HUDShouldDraw", "InitPostEntity"}) do hook.Remove(event, "ZSVoiceHUD") end
 cvars.RemoveChangeCallback("zs_custom_voice", "ZSVoiceHUD")
 if IsValid(self.panel) then self.panel:Remove() end
 for _,row in ipairs(self.rows)do row.Record,row.Player=nil,nil end
 self.rows,self.registry.records,self.registry.order,self.registry.visible={}, {}, {}, {}
 self.registry.count,self.registry.speakers=0,0
 self.panel,self.Overflow=nil,nil
 if IsValid(g_VoicePanelList) and self.defaultVisible ~= nil then g_VoicePanelList:SetVisible(self.defaultVisible) end
 if gm.PlayerStartVoice == self.start then gm.PlayerStartVoice = self.baseStart end
 if gm.PlayerEndVoice == self.finish then gm.PlayerEndVoice = self.baseEnd end
 if gm.ZSVoiceHUD == self then gm.ZSVoiceHUD = nil end
end
state:ApplyMode()
return state
end
if GM then timer.Simple(0, Install) else return Install() end
