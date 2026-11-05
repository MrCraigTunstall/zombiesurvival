local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local background = Color(15, 20, 26)
if GM then
	if IsValid(GM.m_ScoreBoard) then GM.m_ScoreBoard:Remove() end
	GM.m_ScoreBoard = nil
end
local ScoreBoard

local function Layout(board)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local width, height = ScrW(), ScrH()
	board.LayoutDirty = nil
	if board.LayoutWidth == width and board.LayoutHeight == height then return end
	board.LayoutWidth, board.LayoutHeight = width, height
	board:SetSize(math.min(U(1100), width - U(32)), height - U(64))
	board:AlignTop(U(32))
	board:CenterHorizontal()
	board:InvalidateLayout(true)
end

function GM:ScoreboardShow()
	if IsValid(ScoreBoard) and ScoreBoard:IsVisible() then return end
	gui.EnableScreenClicker(true)
	PlayMenuOpenSound()

	if not IsValid(ScoreBoard) then
		ScoreBoard = vgui.Create("ZSScoreBoard")
		self.m_ScoreBoard = ScoreBoard
	end

	Layout(ScoreBoard)
	ScoreBoard:Stop()
	ScoreBoard:SetAlpha(0)
	ScoreBoard:AlphaTo(255, 0.15, 0)
	ScoreBoard:SetVisible(true)
	ScoreBoard:RefreshScoreboard()
end

function GM:ScoreboardRebuild()
	self:ScoreboardHide()
	if IsValid(ScoreBoard) then ScoreBoard:Remove() end
	ScoreBoard = nil
end

function GM:ScoreboardHide()
	gui.EnableScreenClicker(false)

	if IsValid(ScoreBoard) then
		PlayMenuCloseSound()
		ScoreBoard:SetVisible(false)
	end
end

local PANEL = {}

PANEL.RefreshTime = 1
PANEL.NextRefresh = 0
PANEL.m_MaximumScroll = 0

function PANEL:Init()
	self.NextRefresh = RealTime() + 0.1

	self.m_TitleLabel = EasyLabel(self, GAMEMODE.Name, "ZSMenuScaledTitle", color_white)
	self.m_ServerNameLabel = EasyLabel(self, GetHostName(), "ZSMenuScaledBody", GAMEMODE.ShopColors.muted)
	self.m_AuthorLabel = EasyLabel(self, "by "..GAMEMODE.Author, "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
	self.m_ContactLabel = EasyLabel(self, GAMEMODE.Website, "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)

	self.m_HumanHeading = vgui.Create("DTeamHeading", self)
	self.m_HumanHeading.ScoreBoard = self
	self.m_HumanHeading:SetTeam(TEAM_HUMAN)

	self.m_ZombieHeading = vgui.Create("DTeamHeading", self)
	self.m_ZombieHeading.ScoreBoard = self
	self.m_ZombieHeading:SetTeam(TEAM_UNDEAD)

	self.m_PointsLabel = EasyLabel(self, translate.Get("scoreboard_score"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)

	self.m_BrainsLabel = EasyLabel(self, translate.Get("scoreboard_brains"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)

	self.ZombieList = vgui.Create("DScrollPanel", self)
	self.ZombieList.Team = TEAM_UNDEAD

	self.HumanList = vgui.Create("DScrollPanel", self)
	self.HumanList.Team = TEAM_HUMAN
	self.ActiveTeam = IsValid(MySelf) and MySelf:Team() == TEAM_UNDEAD and TEAM_UNDEAD or TEAM_HUMAN
	self.EmptyLabel = EasyLabel(self, translate.Get("scoreboard_empty_team"), "ZSMenuScaledBody", GAMEMODE.ShopColors.muted)
	self.TeamButtons = {}
	for _, entry in ipairs({{TEAM_HUMAN, self.m_HumanHeading}, {TEAM_UNDEAD, self.m_ZombieHeading}}) do
		local teamid, heading = entry[1], entry[2]
		local button = vgui.Create("DButton", heading)
		self.TeamButtons[teamid] = button
		button:SetText("") button:Dock(FILL)
		button.DoClick = function() self:SetActiveTeam(teamid) end
		button.Paint = function(_, width, height)
			if self.ActiveTeam == teamid then
				surface.SetDrawColor(GAMEMODE.ShopColors.accent) surface.DrawRect(0, height - 2, width, 2)
			end
		end
	end
	for _, list in ipairs({self.HumanList, self.ZombieList}) do
		local bar = list.VBar
		bar.Paint = function(_, width, height) surface.SetDrawColor(GAMEMODE.ShopColors.row) surface.DrawRect(0, 0, width, height) end
		for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			button.Paint = function(control, width, height)
				draw.RoundedBox(U(4), 0, 0, width, height, control:IsHovered() and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.muted)
			end
		end
	end

	self:InvalidateLayout()
end

function PANEL:SetActiveTeam(teamid)
	teamid = teamid == TEAM_UNDEAD and TEAM_UNDEAD or TEAM_HUMAN
	if self.ActiveTeam ~= teamid then self.ActiveTeam = teamid self:InvalidateLayout(true) end
end

function PANEL:OnRemove()
	if ScoreBoard == self then ScoreBoard = nil gui.EnableScreenClicker(false) end
	if GAMEMODE.m_ScoreBoard == self then GAMEMODE.m_ScoreBoard = nil end
	self.PlayerPanels = nil
end

function PANEL:PerformLayout()
	for _, label in ipairs({self.m_TitleLabel, self.m_ServerNameLabel, self.m_AuthorLabel, self.m_ContactLabel}) do label:SizeToContents() end
	self.HumanList.VBar:SetWide(U(12)) self.ZombieList.VBar:SetWide(U(12))
	local width, height = self:GetSize()
	local column = (width - U(48)) / 2
	self.m_TitleLabel:SetPos(U(20), U(12))
	self.m_TitleLabel:SetWide(width - U(40))
	self.m_ServerNameLabel:SetPos(U(20), U(44))
	self.m_ServerNameLabel:SetWide(width - U(40))
	self.m_AuthorLabel:SetPos(U(20), height - U(24))
	self.m_ContactLabel:AlignRight(U(20))
	self.m_ContactLabel:SetY(height - U(24))
	self.m_HumanHeading:SetPos(U(16), U(84))
	self.m_HumanHeading:SetSize(column, U(36))
	self.m_ZombieHeading:SetPos(width / 2 + U(8), U(84))
	self.m_ZombieHeading:SetSize(column, U(36))
	self.m_PointsLabel:SetPos(U(16) + column - U(168), U(126))
	self.m_PointsLabel:SetSize(U(112), U(18)) self.m_PointsLabel:SetContentAlignment(5)
	self.m_BrainsLabel:SetPos(width / 2 + U(8) + column - U(168), U(126))
	self.m_BrainsLabel:SetSize(U(112), U(18)) self.m_BrainsLabel:SetContentAlignment(5)
	self.HumanList:SetPos(U(16), U(146))
	self.HumanList:SetSize(column, height - U(180))
	self.ZombieList:SetPos(width / 2 + U(8), U(146))
	self.ZombieList:SetSize(column, height - U(180))
	self.Compact = width < U(760)
	self.TeamButtons[TEAM_HUMAN]:SetVisible(self.Compact)
	self.TeamButtons[TEAM_UNDEAD]:SetVisible(self.Compact)
	self.HumanList:SetVisible(not self.Compact or self.ActiveTeam == TEAM_HUMAN)
	self.ZombieList:SetVisible(not self.Compact or self.ActiveTeam == TEAM_UNDEAD)
	self.m_PointsLabel:SetVisible(not self.Compact or self.ActiveTeam == TEAM_HUMAN)
	self.m_BrainsLabel:SetVisible(not self.Compact or self.ActiveTeam == TEAM_UNDEAD)
	if self.Compact then
		self.HumanList:SetSize(width - U(32), height - U(180))
		self.ZombieList:SetPos(U(16), U(146)) self.ZombieList:SetSize(width - U(32), height - U(180))
		self.m_PointsLabel:SetPos(width - U(204), U(126)) self.m_BrainsLabel:SetPos(width - U(204), U(126))
	end
	self.EmptyLabel:SetPos(U(16), U(166)) self.EmptyLabel:SetSize(width - U(32), U(36)) self.EmptyLabel:SetContentAlignment(5)
	self:RefreshEmptyTeam()
end

function PANEL:RefreshEmptyTeam()
	local count = self.ActiveTeam == TEAM_UNDEAD and self.m_ZombieHeading.RosterCount or self.m_HumanHeading.RosterCount
	local empty = self.Compact and count == 0 or not self.Compact and self.m_HumanHeading.RosterCount == 0 and self.m_ZombieHeading.RosterCount == 0
	if self.EmptyTeamVisible ~= empty then self.EmptyTeamVisible = empty self.EmptyLabel:SetVisible(empty) end
end

function PANEL:Think()
	if not self:IsVisible() then return end
	if self.LayoutDirty then Layout(self) end
	local now = RealTime()
	if now >= self.NextRefresh then self:RefreshScoreboard(now) end
end

function PANEL:Paint(width, height)
	local colors = GAMEMODE.ShopColors
	draw.RoundedBox(U(8), 0, 0, width, height, background)
	draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
	surface.SetDrawColor(colors.accent)
	surface.DrawRect(U(20), U(70), width - U(40), 2)
end

function PANEL:GetPlayerPanel(pl)
	local panel = self.PlayerPanels and self.PlayerPanels[pl]
	if IsValid(panel) then return panel end
end

function PANEL:CreatePlayerPanel(pl, viewerTeam, teamid)
	local curpan = self:GetPlayerPanel(pl)
	if curpan and curpan:IsValid() then return curpan end

	teamid = teamid or pl:Team()
	if teamid == TEAM_SPECTATOR then return end

	local panel = vgui.Create("ZSPlayerPanel", teamid == TEAM_UNDEAD and self.ZombieList or self.HumanList)
	panel.ScoreBoard = self
	panel.ManagedRefresh = true
	panel:SetPlayer(pl, viewerTeam, teamid)
	panel:Dock(TOP)
	panel:DockMargin(0, 2, U(4), 2)

	self.PlayerPanels[pl] = panel

	return panel
end

function PANEL:RefreshScoreboard(now)
	local revision = translate.GetRevision()
	if self.LanguageRevision ~= revision or self.LanguageGetter ~= translate.Get then
		self.LanguageRevision, self.LanguageGetter = revision, translate.Get
		self.m_PointsLabel:SetText(translate.Get("scoreboard_score"))
		self.m_BrainsLabel:SetText(translate.Get("scoreboard_brains"))
		self.EmptyLabel:SetText(translate.Get("scoreboard_empty_team"))
	end
	local hostname = GetHostName()
	if hostname ~= self._LastHostName then
		self._LastHostName = hostname
		self.m_ServerNameLabel:SetText(hostname)
		self.m_ServerNameLabel:SizeToContents()
		self:InvalidateLayout()
	end

	if self.PlayerPanels == nil then self.PlayerPanels = {} end

	for pl, panel in pairs(self.PlayerPanels) do
		if not IsValid(pl) or not IsValid(panel) then
			self.PlayerPanels[pl] = nil
			if IsValid(panel) then panel:Remove() end
		end
	end

	local leftCount, zombieCount, redeemerCount = 0, 0, 0
	local viewerTeam = IsValid(MySelf) and MySelf:Team() or false
	for _, pl in player.Iterator() do
		local row = self:GetPlayerPanel(pl)
		if pl:IsSpectator() then
			if row then self.PlayerPanels[pl] = nil row:Remove() end
		else
			local teamid = pl:Team()
			if row then row:RefreshPlayer(viewerTeam, teamid) else self:CreatePlayerPanel(pl, viewerTeam, teamid) end
			if teamid == TEAM_UNDEAD then
				zombieCount = zombieCount + 1
			else
				leftCount = leftCount + 1
				if teamid == TEAM_REDEEMER then redeemerCount = redeemerCount + 1 end
			end
		end
	end
	local leftName = team.GetName(TEAM_HUMAN)
	local compound = redeemerCount > 0 and leftCount > redeemerCount
	if redeemerCount > 0 then
		local name = team.GetName(TEAM_REDEEMER)
		leftName = compound and leftName.." / "..name or name
	end
	self.m_HumanHeading:SetRoster(leftName, leftCount, compound)
	self.m_ZombieHeading:SetRoster(team.GetName(TEAM_UNDEAD), zombieCount)
	self:RefreshEmptyTeam()
	self.NextRefresh = (now or RealTime()) + self.RefreshTime
end

function PANEL:RemovePlayerPanel(panel)
	if panel:IsValid() then
		self.PlayerPanels[panel:GetPlayer()] = nil
		panel:Remove()
	end
end

vgui.Register("ZSScoreBoard", PANEL, "Panel")

hook.Add("OnScreenSizeChanged", "ZSScoreboardLayout", function()
	if IsValid(ScoreBoard) then
		if ScoreBoard:IsVisible() then Layout(ScoreBoard) else ScoreBoard.LayoutDirty = true end
	end
end)

PANEL = {}

PANEL.RefreshTime = 1

PANEL.m_Player = NULL
PANEL.NextRefresh = 0

local function MuteDoClick(self)
	local row = self:GetParent()
	local pl = row:GetPlayer()
	if pl:IsValid() then
		pl:SetMuted(not pl:IsMuted())
		if row.ManagedRefresh then row:RefreshPlayer() else row.NextRefresh = RealTime() end
	end
end

local function AvatarDoClick(self)
	local pl = self.PlayerPanel:GetPlayer()
	if pl:IsValidPlayer() and not pl:IsBot() then
		pl:ShowProfile()
	end
end

local function empty() end

function PANEL:Init()
	local screenscale = math.max(0.95, BetterScreenScale())
	self:SetTall(U(40))
	self:SetTooltipPanelOverride("ZSShopTooltip")

	self.m_AvatarButton = self:Add("DButton", self)
	self.m_AvatarButton:SetText(" ")
	self.m_AvatarButton:SetSize(U(32) * screenscale, U(32) * screenscale)
	self.m_AvatarButton:Center()
	self.m_AvatarButton.DoClick = AvatarDoClick
	self.m_AvatarButton.Paint = empty
	self.m_AvatarButton.PlayerPanel = self


	self.m_SpecialImage = vgui.Create("DImage", self)
	self.m_SpecialImage:SetSize(U(20), U(20))
	self.m_SpecialImage:SetTooltipPanelOverride("ZSShopTooltip")
	self.m_SpecialImage:SetMouseInputEnabled(true)
	self.m_SpecialImage:SetVisible(false)

	self.m_ClassImage = vgui.Create("DImage", self)
	self.m_ClassImage:SetSize(U(22) * screenscale, U(22) * screenscale)
	self.m_ClassImage:SetMouseInputEnabled(false)
	self.m_ClassImage:SetVisible(false)

	self.m_PlayerLabel = EasyLabel(self, " ", "ZSMenuScaledSmall", COLOR_WHITE)
	self.m_ScoreLabel = EasyLabel(self, " ", "ZSMenuScaledBody", COLOR_WHITE)
	self.m_PlayerLabel:SetMouseInputEnabled(true)
	self.m_PlayerLabel:SetCursor("hand")
	self.m_PlayerLabel.PlayerPanel = self
	self.m_PlayerLabel.DoClick = AvatarDoClick
	self.m_PlayerLabel:SetAlpha(240)
	self.m_ScoreLabel:SetAlpha(240)

	self.m_PingMeter = vgui.Create("DPingMeter", self)
	self.m_PingMeter.PingBars = 5
	self.m_PingMeter.ManagedRefresh = true

	self.m_Mute = vgui.Create("DImageButton", self)
	self.m_Mute.DoClick = MuteDoClick
end

function PANEL:Paint(width, height)
	local colors = GAMEMODE.ShopColors
	draw.RoundedBox(U(5), 0, 0, width, height, self.Hovered and colors.hover or colors.row)
	local pl = self:GetPlayer()
	if pl:IsValid() then
		surface.SetDrawColor(team.GetColor(pl:Team()))
		surface.DrawRect(0, U(6), 3, height - U(12))
		if pl == MySelf or self.m_Flash then
			surface.SetDrawColor(colors.accent)
			surface.DrawOutlinedRect(0, 0, width, height)
		end
	end
	return true
end

function PANEL:DoClick()
	local pl = self:GetPlayer()
	if pl:IsValid() then
		gamemode.Call("ClickedPlayerButton", pl, self)
	end
end

function PANEL:PerformLayout()
	local width = self:GetWide()
	self.m_AvatarButton:SetSize(U(28), U(28))
	self:SetTall(U(40))
	if IsValid(self.m_Avatar) then
		self.m_Avatar:SetSize(U(28), U(28))
		local pixels = (GAMEMODE.MenuScale or 1) > 1 and 64 or 32
		if self.AvatarPixels ~= pixels then self.m_Avatar:SetPlayer(self:GetPlayer(), pixels) self.AvatarPixels = pixels end
	end
	self.m_AvatarButton:SetPos(U(8), U(6))
	self.m_PlayerLabel:SetPos(U(72), 0)
	self.m_PlayerLabel:SetSize(math.max(U(16), width - (self.SpectatorOnly and U(142) or U(214))), self:GetTall())
	self.m_ScoreLabel:SetSize(U(48), self:GetTall())
	self.m_ScoreLabel:SetContentAlignment(5)
	self.m_ScoreLabel:SetPos(width - U(136), 0)
	self.m_SpecialImage:SetSize(U(20), U(20))
	self.m_SpecialImage:SetPos(U(44), U(10))
	self.m_ClassImage:SetSize(U(22), U(22))
	self.m_ClassImage:SetPos(width - U(83), U(9))
	self.m_PingMeter:SetSize(U(28), U(28))
	self.m_PingMeter:SetPos(width - U(34), U(6))
	self.m_Mute:SetSize(U(16), U(16))
	self.m_Mute:SetPos(width - U(56), U(12))
end

function PANEL:RefreshPlayer(viewerTeam, teamid)
	local pl = self:GetPlayer()
	if not pl:IsValid() then
		self:Remove()
		return
	end

	teamid = teamid or pl:Team()
	if viewerTeam == nil then viewerTeam = IsValid(MySelf) and MySelf:Team() or false end
	if self.SpectatorOnly and teamid ~= TEAM_SPECTATOR then
		self:Remove()
		return
	end
	self.m_PingMeter:Refresh()
	local image = self.m_SpecialImage
	if image then
		image.ZSSpecialPersonFlash = nil
		local visible = gamemode.Call("IsSpecialPerson", pl, image) and true or false
		if image:IsVisible() ~= visible then image:SetVisible(visible) end
		if not visible and image:GetTooltip() ~= nil then image:SetTooltip() end
		local flash = image.ZSSpecialPersonFlash
		if flash == nil then flash = gamemode.Call("IsSpecialPerson", pl) end
		self.m_Flash = flash
	end
	local layoutChanged = false
	local name = pl:Name()
	if name ~= self._LastName then
		self._LastName = name
		self.m_PlayerLabel:SetText(name)
		self:SetTooltip(name)
		layoutChanged = true
	end

	local score = not self.SpectatorOnly and pl:Frags()
	if score and score ~= self._LastScore then
		self._LastScore = score
		self.m_ScoreLabel:SetText(score)
		self:SetZPos(-score)
		layoutChanged = true
	end

	local class = viewerTeam == TEAM_UNDEAD and teamid == TEAM_UNDEAD and pl:GetZombieClassTable()
	local icon = class and class.Icon or false
	if icon ~= self._LastIcon then
		self._LastIcon = icon
		self.m_ClassImage:SetVisible(icon ~= false)
		if icon then self.m_ClassImage:SetImage(icon) end
	end
	if icon then
		local color = class.IconColor or color_white
		if color.r ~= self._IconR or color.g ~= self._IconG or color.b ~= self._IconB or color.a ~= self._IconA then
			self._IconR, self._IconG, self._IconB, self._IconA = color.r, color.g, color.b, color.a
			self.m_ClassImage:SetImageColor(color)
		end
	end

	local canMute = pl ~= MySelf and not pl:IsBot()
	if canMute ~= self._CanMute then
		self._CanMute = canMute
		self.m_Mute:SetVisible(canMute)
	end
	if canMute then
		local muted = pl:IsMuted()
		if muted ~= self._LastMuted then
			self._LastMuted = muted
			self.m_Mute:SetImage(muted and "icon16/sound_mute.png" or "icon16/sound.png")
		end
	end

	if teamid ~= self._LastTeam then
		self._LastTeam = teamid
		if IsValid(self.ScoreBoard) and self.ScoreBoard.HumanList and self.ScoreBoard.ZombieList then
			self:SetParent(teamid == TEAM_UNDEAD and self.ScoreBoard.ZombieList or self.ScoreBoard.HumanList)
		end
		layoutChanged = true
	end

	if layoutChanged then self:InvalidateLayout() end
end

function PANEL:Think()
	if self.ManagedRefresh then return end
	if not IsValid(self.ScoreBoard) or not self.ScoreBoard:IsVisible() then return end
	if RealTime() >= self.NextRefresh then
		self.NextRefresh = RealTime() + self.RefreshTime
		self:RefreshPlayer()
	end
end

function PANEL:SetPlayer(pl, viewerTeam, teamid)
	self.m_Player = pl or NULL
	pl = self.m_Player

	if pl:IsValidPlayer() then
		local bot = pl:IsBot()
		if bot then
			if IsValid(self.m_Avatar) then self.m_Avatar:Remove() self.m_Avatar = nil end
			self.AvatarPlayer, self.AvatarPixels = nil, nil
		else
			if not IsValid(self.m_Avatar) then
				self.m_Avatar = vgui.Create("AvatarImage", self.m_AvatarButton)
				self.m_Avatar:SetMouseInputEnabled(false)
				self.m_Avatar:SetSize(U(28), U(28))
			end
			local pixels = (GAMEMODE.MenuScale or 1) > 1 and 64 or 32
			if self.AvatarPlayer ~= pl or self.AvatarPixels ~= pixels then
				self.m_Avatar:SetPlayer(pl, pixels) self.AvatarPlayer, self.AvatarPixels = pl, pixels
			end
			self.m_Avatar:SetVisible(true)
		end
		self.m_AvatarButton:SetText(bot and "BOT" or " ")
		self.m_AvatarButton:SetFont("ZSMenuScaledSmall")
	else
		if IsValid(self.m_Avatar) then self.m_Avatar:Remove() self.m_Avatar = nil end
		self.AvatarPlayer, self.AvatarPixels = nil, nil
		self.m_SpecialImage:SetVisible(false)
		self.m_Flash = false
	end

	self.m_PingMeter.ScoreBoard = self.ScoreBoard
	self.m_PingMeter:SetPlayer(pl)

	self:RefreshPlayer(viewerTeam, teamid)
end

function PANEL:GetPlayer()
	return self.m_Player
end

vgui.Register("ZSPlayerPanel", PANEL, "Button")
