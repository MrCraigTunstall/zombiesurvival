local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local PANEL = {}
PANEL.m_Team = 0
PANEL.NextRefresh = 0
PANEL.RefreshTime = 2

function PANEL:Init()
	self.m_TeamNameLabel = EasyLabel(self, " ", "ZSMenuScaledBody", color_white)
	self.m_TeamCountLabel = EasyLabel(self, " ", "ZSMenuScaledBody", color_white)

	self.m_Icon = vgui.Create("DImage", self)
	self.m_Icon:SetVisible(false)
	self.m_Icon:NoClipping(true)

	self:InvalidateLayout()
end

function PANEL:Think()
	if self.RosterName then return end
	if self.ScoreBoard and (not IsValid(self.ScoreBoard) or not self.ScoreBoard:IsVisible()) then return end
	if RealTime() >= self.NextRefresh then
		self.NextRefresh = RealTime() + self.RefreshTime
		self:Refresh()
	end
end

function PANEL:PerformLayout()
	self.m_TeamCountLabel:SizeToContents()
	self.m_TeamNameLabel:SetPos(U(40), 0)
	self.m_TeamNameLabel:SetSize(math.max(U(16), self:GetWide() - U(100)), self:GetTall())
	self.m_TeamCountLabel:AlignRight(U(12))
	self.m_TeamCountLabel:CenterVertical()
	self.m_Icon:SetSize(U(26), U(26))
	self.m_Icon:SetPos(U(8), U(5))
end

function PANEL:Refresh()
	local teamid = self:GetTeam()

	local name, count = self.RosterName or team.GetName(teamid), self.RosterCount
	if count == nil then count = team.NumPlayers(teamid) end
	local changed = false
	if name ~= self._LastName then
		self._LastName = name
		self.m_TeamNameLabel:SetText(name)
		self.m_TeamNameLabel:SizeToContents()
		changed = true
	end
	if count ~= self._LastCount then
		self._LastCount = count
		self.m_TeamCountLabel:SetText(count)
		self.m_TeamCountLabel:SizeToContents()
		changed = true
	end
	if changed then self:InvalidateLayout() end
end

function PANEL:Paint(width, height)
	draw.RoundedBox(U(5), 0, 0, width, height, GAMEMODE.ShopColors.header)
	return true
end

function PANEL:SetRoster(name, count, compound)
	if name == self.RosterName and count == self.RosterCount and compound == self.RosterCompound then return end
	self.RosterName, self.RosterCount, self.RosterCompound = name, count, compound
	self.m_TeamNameLabel:SetFont(compound and "ZSMenuScaledSmall" or "ZSMenuScaledBody")
	self:Refresh()
end

function PANEL:SetTeam(teamid)
	self.m_Team = teamid
	self.RosterName, self.RosterCount, self.RosterCompound = nil, nil, nil

	if teamid == TEAM_HUMAN then
		self.m_Icon:SetVisible(true)
		self.m_Icon:SetImage("zombiesurvival/kleinerface2.png")
		self.m_Icon:SetSize(U(26), U(26))
		self:InvalidateLayout()
	elseif teamid == TEAM_UNDEAD then
		self.m_Icon:SetVisible(true)
		self.m_Icon:SetImage("zombiesurvival/zombiehead")
		self.m_Icon:SetSize(U(26), U(26))
		self:InvalidateLayout()
	else
		self.m_Icon:SetVisible(false)
	end
end
function PANEL:GetTeam() return self.m_Team end

vgui.Register("DTeamHeading", PANEL, "Panel")
