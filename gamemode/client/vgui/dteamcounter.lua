local PANEL = {}
PANEL.m_Team = 0
PANEL.NextRefresh = 0

function PANEL:Init()
 self:SetMouseInputEnabled(false)
 self:SetKeyboardInputEnabled(false)
 self.m_Image = vgui.Create("DImage", self)
 self.m_Image:SetImage("icon16/check_off.png")
 self.m_Counter = vgui.Create("DLabel", self)
 self.m_Counter:SetFont("ZSRoundHUDCounter")
 self:Refresh()
end

function PANEL:Paint() return true end

function PANEL:Think()
 local parent = self:GetParent()
 if not self:IsVisible() or IsValid(parent) and not parent:IsVisible() then return end
 local now = RealTime()
 if now >= self.NextRefresh then
  self.NextRefresh = now + 1
  self:Refresh()
 end
end

function PANEL:SetTeam(teamid)
 self.m_Counter:Stop()
 self.m_Team = teamid
 self.m_PrevPlayers = nil
 self.m_Counter:SetTextColor(team.GetColor(teamid))
 self:Refresh()
end

function PANEL:SetImage(mat)
 self.m_Image:SetImage(mat)
 self:InvalidateLayout()
end

function PANEL:PerformLayout()
 local size = math.min(self:GetTall(), 28)
 self.m_Image:SetSize(size, size)
 self.m_Image:SetPos(0, (self:GetTall() - size) * 0.5)
 self.m_Counter:SetPos(size + 8, (self:GetTall() - self.m_Counter:GetTall()) * 0.5)
end

function PANEL:Refresh()
 local count = team.NumPlayers(self.m_Team)
 local previous = self.m_PrevPlayers
 if previous == count then return end
 self.m_PrevPlayers = count
 self.m_Counter:SetText(count)
 self.m_Counter:SizeToContents()
 if previous ~= nil then
  self.m_Counter:Stop()
  self.m_Counter:SetColor(count > previous and color_white or COLOR_RED)
  self.m_Counter:ColorTo(team.GetColor(self.m_Team), 2)
 end
 self:InvalidateLayout()
end

vgui.Register("DTeamCounter", PANEL, "DPanel")
