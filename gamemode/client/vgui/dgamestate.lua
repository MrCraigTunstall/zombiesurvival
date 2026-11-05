surface.CreateFont("ZSRoundHUDTitle", {font = "Roboto", size = 18, weight = 700, antialias = true, extended = true})
surface.CreateFont("ZSRoundHUDText", {font = "Roboto", size = 14, weight = 500, antialias = true, extended = true})
surface.CreateFont("ZSRoundHUDCounter", {font = "Roboto", size = 18, weight = 700, antialias = true, extended = true})
local style = ZSHUDStyle
local muted, accent, hostile = style.Muted, style.Accent, style.Danger
local humanFace = Material("zombiesurvival/kleinerface2.png", "smooth")
local zombieFace = Material("zombiesurvival/zombiehead", "smooth")
local PANEL = {}

local function PaintCaption(self, width, height)
 if not self.Caption or self.Caption == "" then return true end
 local color = self.CaptionColor or muted
 if self.Urgent then
  color = self.WarningColor
  color.a = 210 + math.sin(RealTime() * 5) * 45
 end
 draw.SimpleText(self.FittedCaption or self.Caption, self.Font, 0, height * 0.5, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
 return true
end

local function Caption(label, text, color, urgent)
 text = text or ""
 local width = label:GetWide()
 if label.Caption ~= text or label.FittedWidth ~= width or label.FittedFont ~= label.Font then
  label.Caption, label.FittedWidth, label.FittedFont = text, width, label.Font
  label.FittedCaption = style.Fit(text, label.Font, math.max(0, width))
 end
 label.CaptionColor = color
 label.Urgent = urgent
end

function PANEL:Init()
 self:SetMouseInputEnabled(false)
 self:SetKeyboardInputEnabled(false)
 self.m_HumanCount = vgui.Create("DTeamCounter", self)
 self.m_HumanCount:SetTeam(TEAM_HUMAN)
 self.m_HumanCount:SetImage("zombiesurvival/kleinerface2.png")
 self.m_ZombieCount = vgui.Create("DTeamCounter", self)
 self.m_ZombieCount:SetTeam(TEAM_UNDEAD)
 self.m_ZombieCount:SetImage("zombiesurvival/zombiehead")
 self.m_HumanCount:SetVisible(false)
 self.m_ZombieCount:SetVisible(false)
 self.m_Text1 = vgui.Create("DLabel", self)
 self.m_Text2 = vgui.Create("DLabel", self)
 self.m_Text3 = vgui.Create("DLabel", self)
 for _, label in ipairs({self.m_Text1, self.m_Text2, self.m_Text3}) do
  label:SetText("") label.Paint = PaintCaption
 end
 self.m_Text2.WarningColor = Color(245, 112, 115)
 self.NextRefresh = 0
 self:SetTextFont("ZSRoundHUDText")
end

function PANEL:SetTextFont(font)
 local title = font == "ZSRoundHUDText" and "ZSHUDTitle" or font
 font = font == "ZSRoundHUDText" and "ZSHUDSmall" or font
 for i, label in ipairs({self.m_Text1, self.m_Text2, self.m_Text3}) do
  label.Font = i == 1 and title or font
  label:SetFont(label.Font)
 end
 self:InvalidateLayout()
end

function PANEL:PerformLayout()
 local scale = style.Scale()
 self.Scale = scale
 local width, padding = math.min(340 * scale, ScrW() * 0.48), 16 * scale
 local compact = not self.HasTimer and not self.HasScore
 self:SetSize(width, (compact and 112 or 132) * scale)
 local margin = math.floor(16 * scale)
 self:SetPos(margin, margin)
 self.m_Text1:SetSize(width - padding * 2, 24 * scale)
 self.m_Text1:SetPos(padding, 12 * scale)
 local detailX = self.HasTimer and 132 * scale or padding
 self.m_Text2:SetSize(width - detailX - padding, 20 * scale)
 self.m_Text2:SetPos(detailX, 40 * scale)
 self.m_Text3:SetSize(width - detailX - padding, 20 * scale)
 self.m_Text3:SetPos(detailX, 62 * scale)
 self.FaceY = (compact and 66 or 86) * scale
 self.RosterWidth = nil
 for _, label in ipairs({self.m_Text1, self.m_Text2, self.m_Text3}) do
  label.FittedWidth = nil
  Caption(label, label.Caption, label.CaptionColor, label.Urgent)
 end
end

function PANEL:RefreshText()
 local gm, pl = GAMEMODE, MySelf
 local valid = IsValid(pl)
 local wave, active = gm:GetWave(), gm:GetWaveActive()
 local override = valid and GetGlobalString("hudoverride" .. pl:Team(), "")
 local title
 if gm.RoundEnded then title = translate.Get(ROUNDWINNER == TEAM_HUMAN and "end_human_victory" or ROUNDWINNER == TEAM_UNDEAD and "end_undead_victory" or "end_round_over")
 elseif override and #override > 0 then title = override
 elseif gm:IsEscapeSequence() then title = translate.Get(valid and pl:Team() == TEAM_UNDEAD and "prop_obj_exit_z" or "prop_obj_exit_h")
 elseif wave <= 0 then title = translate.Get("prepare_yourself")
 elseif gm.ZombieEscape then title = translate.Get("zombie_escape")
 else
  local maximum = gm:GetNumberOfWaves()
  if maximum ~= -1 then
   title = translate.Format("wave_x_of_y", wave, maximum)
   if not active then title = translate.Get("intermission") .. " - " .. title end
  elseif not active then title = translate.Get("intermission")
  else title = translate.Get("wave") .. " " .. wave end
 end
 Caption(self.m_Text1, title, color_white)
 local timerKey, timeleft
 if gm.RoundEnded then
  timeleft = math.max(0, (gm.EndTime or CurTime()) + gm.EndGameTime - CurTime())
  timerKey = timeleft > 0 and "hud_next_round" or "loading"
 elseif wave <= 0 then
  timeleft = math.max(0, gm:GetWaveStart() - CurTime())
  timerKey = "hud_invasion_begins"
 else
  local deadline = active and gm:GetWaveEnd() or gm:GetWaveStart()
  if deadline ~= -1 then
   timeleft = math.max(0, deadline - CurTime())
   timerKey = active and "hud_wave_ends" or "hud_next_wave"
  else
   timerKey = gm.ZombieEscape and "hud_escape_objective" or "hud_wave_objective"
  end
 end
 self.TimeRemaining = timeleft
 self.TimerText = timeleft and util.ToMinutesSeconds(timeleft) or nil
 self.TimerColor = timeleft and timeleft <= 10 and hostile or style.Text
 local now = RealTime()
 if now >= (self.NextRosterRefresh or 0) then
  self.NextRosterRefresh = now + 1
  self.HumanCount, self.ZombieCount = team.NumPlayers(TEAM_HUMAN), team.NumPlayers(TEAM_UNDEAD)
 end
 local score, color
 if valid and not gm.ZombieEscape then
  if pl:Team() == TEAM_UNDEAD then
   local redeem = gm:GetRedeemBrains()
   score = translate.Format("brains_eaten_x", redeem > 0 and pl:Frags() .. " / " .. redeem or pl:Frags())
   color = hostile
  elseif pl:Team() == TEAM_HUMAN then
   score = translate.Format("points_x", pl:GetPoints())
   color = accent
  end
 end
 local hasTimer, hasScore = timeleft ~= nil, score ~= nil
 if self.HasTimer ~= hasTimer or self.HasScore ~= hasScore then
  self.HasTimer, self.HasScore = hasTimer, hasScore
  self:InvalidateLayout(true)
 end
 local scale, width = self.Scale or style.Scale(), self:GetWide()
 local revision = translate.GetRevision()
 if self.RosterWidth ~= width or self.RosterRevision ~= revision or self.PreviousHumans ~= self.HumanCount or self.PreviousZombies ~= self.ZombieCount then
  self.RosterWidth, self.RosterRevision = width, revision
  self.PreviousHumans, self.PreviousZombies = self.HumanCount, self.ZombieCount
  local tileWidth = (width - 40 * scale) * 0.5
  surface.SetFont("ZSHUDTitle")
  local humanWidth = surface.GetTextSize(self.HumanCount or 0)
  local zombieWidth = surface.GetTextSize(self.ZombieCount or 0)
  self.HumanTitle = style.Fit(translate.Get("team_humans"), "ZSHUDSmall", math.max(0, tileWidth - 56 * scale - humanWidth))
  self.ZombieTitle = style.Fit(translate.Get("team_zombie"), "ZSHUDSmall", math.max(0, tileWidth - 56 * scale - zombieWidth))
 end
 Caption(self.m_Text2, translate.Get(timerKey), muted, timeleft ~= nil and (wave <= 0 and timeleft < 10 or wave > 0 and timeleft <= 10))
 Caption(self.m_Text3, score, color)
end

function PANEL:Think()
 if not self:IsVisible() then return end
 local now = RealTime()
 if now < self.NextRefresh then return end
 self.NextRefresh = now + 0.25
 self:RefreshText()
end

function PANEL:Paint(width, height)
 local scale = self.Scale or style.Scale()
 local inset, gap = 16 * scale, 8 * scale
 style.Card(0, 0, width, height, accent, true)
 if self.TimerText then
  draw.SimpleText(self.TimerText, "ZSHUDNumber", inset - scale, 58 * scale, self.TimerColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
 end
 local tileWidth, y = (width - inset * 2 - gap) * 0.5, self.FaceY or 86 * scale
 for index = 1, 2 do
  local x = inset + (index - 1) * (tileWidth + gap)
  local color = index == 1 and accent or hostile
  draw.RoundedBox(5 * scale, x, y, tileWidth, 32 * scale, style.GlassSurface)
  surface.SetDrawColor(color_white)
  surface.SetMaterial(index == 1 and humanFace or zombieFace)
  surface.DrawTexturedRect(x + 4 * scale, y + 2 * scale, 28 * scale, 28 * scale)
  draw.SimpleText((index == 1 and self.HumanTitle or self.ZombieTitle) or "", "ZSHUDSmall", x + 40 * scale, y + 16 * scale, muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  draw.SimpleText((index == 1 and self.HumanCount or self.ZombieCount) or 0, "ZSHUDTitle", x + tileWidth - 10 * scale, y + 16 * scale, color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
 end
 return true
end

vgui.Register("DGameState", PANEL, "DPanel")
hook.Add("OnScreenSizeChanged", "ZSGameStateLayout", function()
 if GAMEMODE and IsValid(GAMEMODE.GameStatePanel) then GAMEMODE.GameStatePanel:InvalidateLayout(true) end
end)
