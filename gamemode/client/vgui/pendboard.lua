local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local colors = GM.ShopColors
if IsValid(pEndBoard) then pEndBoard:Remove() pEndBoard = nil end

local function Layout(frame)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local screenWidth, screenHeight = ScrW(), ScrH()
	frame.LayoutDirty = nil
	local contentHeight = 0
	for _, row in pairs(frame.RowsByMention) do if IsValid(row) then contentHeight = contentHeight + row:GetTall() + U(8) end end
	local width = math.min(screenWidth - U(32), U(760))
	local height = math.min(screenHeight - U(32), U(620), math.max(U(242), U(166) + contentHeight))
	local scale = GAMEMODE.MenuScale or 1
	if frame.ScreenWidth == screenWidth and frame.ScreenHeight == screenHeight and frame.LayoutScale == scale and frame.LayoutHeight == height then return end
	frame.ScreenWidth, frame.ScreenHeight, frame.LayoutScale, frame.LayoutHeight = screenWidth, screenHeight, scale, height
	frame:SetSize(width, height) frame:Center()
	frame.List:GetVBar():SetWide(U(12))
	frame.Heading:SetPos(U(20), U(14)) frame.Heading:SetSize(width - U(80), U(28))
	frame.Subheading:SetPos(U(20), U(44)) frame.Subheading:SetSize(width - U(40), U(22))
	frame.CloseButton:SetPos(width - U(50), U(16)) frame.CloseButton:SetSize(U(30), U(30))
	frame.MentionsTitle:SetPos(U(20), U(88)) frame.MentionsTitle:SetSize(width - U(40), U(26))
	frame.List:SetPos(U(20), U(126)) frame.List:SetSize(width - U(40), height - U(166))
	frame.Empty:SetPos(U(20), U(142)) frame.Empty:SetSize(width - U(40), U(60))
	frame.Footer:SetPos(U(20), height - U(30)) frame.Footer:SetSize(width - U(40), U(20))
end

local function Label(parent, text, font, color)
	local label = parent:Add("DLabel") label:SetFont(font) label:SetTextColor(color) label:SetText(text)
	return label
end

function GM:ClickedEndBoardPlayerButton(pl)
	if IsValid(pl) and pl:IsPlayer() and not pl:IsBot() then pl:ShowProfile() end
end

function MakepEndBoard(winner)
	if IsValid(pEndBoard) then pEndBoard:Remove() end
	local humanWin, undeadWin = winner == TEAM_HUMAN, winner == TEAM_UNDEAD
	local frame = vgui.Create("DFrame") pEndBoard = frame
	frame:SetVisible(false)
	frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDeleteOnClose(false) frame:SetDraggable(false)
	GAMEMODE:StyleShopFrame(frame)
	local background = Color(15, 20, 26)
	frame.Paint = function(_, width, height)
		draw.RoundedBox(U(8), 0, 0, width, height, background)
		draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
		surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), 2)
	end
	local nativeThink = frame.Think
	frame.Think = function(panel)
		if not panel:IsVisible() then return end
		if panel.LayoutDirty then Layout(panel) end
		if nativeThink then return nativeThink(panel) end
	end
	frame.Winner, frame.RowsByMention, frame.RowCount = winner, {}, 0
	frame.Heading = Label(frame, translate.Get(humanWin and "end_human_victory" or undeadWin and "end_undead_victory" or "end_round_over"), "ZSMenuScaledTitle", humanWin and colors.accent or color_white)
	frame.Subheading = Label(frame, translate.Get(humanWin and "humans_win" or undeadWin and "zombies_win" or "end_results_help"), "ZSMenuScaledSmall", colors.muted)
	frame.CloseButton = frame:Add("DButton") frame.CloseButton:SetText("X") GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
	frame.CloseButton:SetTooltip(translate.Get("close")) frame.CloseButton.DoClick = function() if IsValid(frame) then frame:Close() end end
	frame.MentionsTitle = Label(frame, translate.Get("mentions"), "ZSMenuScaledBody", color_white)
	frame.List = frame:Add("DScrollPanel")
	local bar = frame.List:GetVBar()
	bar:SetWide(U(12))
	bar.Paint = function(_, width, height) draw.RoundedBox(U(4), 0, 0, width, height, colors.row) end
	for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
		button.Paint = function(panel, width, height) draw.RoundedBox(U(4), 0, 0, width, height, panel.Hovered and colors.accent or colors.muted) end
	end
	frame.Empty = Label(frame, translate.Get("end_mentions_pending"), "ZSMenuScaledBody", colors.muted) frame.Empty:SetWrap(true)
	frame.Footer = Label(frame, translate.Format("end_mentions_count", 0), "ZSMenuScaledSmall", colors.muted)
	frame.OnRemove = function(self)
		self.RowsByMention, self.List, self.Heading, self.Subheading = nil, nil, nil, nil
		self.CloseButton, self.MentionsTitle, self.Empty, self.Footer = nil, nil, nil, nil
		if pEndBoard == self then pEndBoard = nil end
	end
	Layout(frame) frame:SetVisible(true) frame:MakePopup() frame:SetKeyboardInputEnabled(false)
	local pl = LocalPlayer()
	if humanWin and IsValid(pl) and pl:Team() == TEAM_HUMAN then surface.PlaySound("beams/beamstart5.wav")
	else surface.PlaySound("ambient/levels/citadel/strange_talk" .. math.random(3, 11) .. ".wav") end
	return frame
end

function GM:FinishHonorableMentions()
	local frame = pEndBoard
	if not IsValid(frame) then frame = MakepEndBoard(ROUNDWINNER) end
	frame.MentionsComplete = true
	if frame.RowCount == 0 then frame.Empty:SetText(translate.Get("end_no_mentions")) end
end

function GM:AddHonorableMention(pl, mentionid, ...)
	local mention = self.HonorableMentions[mentionid]
	if not mention or not IsValid(pl) or not pl:IsPlayer() then return end
	local text
	if not mention.String or mention.String == "" then text = tostring(mention.Callback(pl, ...) or "")
	else text = string.format(mention.String, mention.Callback(pl, ...)) end
	local frame = pEndBoard
	if not IsValid(frame) then frame = MakepEndBoard(ROUNDWINNER) end
	local row = frame.RowsByMention[mentionid]
	if not IsValid(row) then
		row = frame.List:Add("DEndBoardPlayerPanel") row:Dock(TOP) row:DockMargin(0, 0, 0, U(8))
		if frame.RowsByMention[mentionid] == nil then frame.RowCount = frame.RowCount + 1 end
		row:SetZPos(type(mentionid) == "number" and mentionid >= 1 and mentionid <= 255 and mentionid or 256 + frame.RowCount)
		frame.RowsByMention[mentionid] = row
		row.EndBoard = frame frame.LayoutDirty = true
		if frame.Empty:IsVisible() then frame.Empty:SetVisible(false) end
		local footer = translate.Format("end_mentions_count", frame.RowCount)
		if frame.Footer:GetText() ~= footer then frame.Footer:SetText(footer) end
	end
	row:SetPlayer(pl, mention.Color, text, colors.muted, mention.Name)
	return row
end

local PANEL = {}

function PANEL:Init()
	self:SetTooltipPanelOverride("ZSShopTooltip")
	self:SetTall(U(82))
	self.NameLabel = Label(self, "", "ZSMenuScaledBody", color_white) self.NameLabel:SetWrap(true)
	self.MiscLabel = Label(self, "", "ZSMenuScaledSmall", colors.muted) self.MiscLabel:SetWrap(true)
	self.NameLabel:SetMouseInputEnabled(false) self.MiscLabel:SetMouseInputEnabled(false)
	self.BotLabel = Label(self, "BOT", "ZSMenuScaledSmall", colors.muted)
	self.BotLabel:SetContentAlignment(5) self.BotLabel:SetMouseInputEnabled(false) self.BotLabel:SetVisible(false)
	self.MiscLabel.PaintOver = function()
		if not self.NeedsMeasure then return end self.NeedsMeasure = nil
		self.NameLabel:SizeToContentsY() self.MiscLabel:SizeToContentsY()
		self.NameHeight, self.MiscHeight = self.NameLabel:GetTall(), self.MiscLabel:GetTall()
		local height = math.max(U(76), self.NameHeight + self.MiscHeight + U(34))
		if self:GetTall() ~= height then
			self:SetTall(height)
			if IsValid(self.EndBoard) then self.EndBoard.LayoutDirty = true end
		end
		self:InvalidateLayout(true)
	end
end

function PANEL:GetPlayer() return self.m_Player or NULL end

function PANEL:SetPlayer(pl, col, misc, misccol, overridename)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	local name = overridename or pl:Name()
	col, misccol = col or color_white, misccol or colors.muted
	local nameColorChanged = self.NameColor ~= col or self.NameR ~= col.r or self.NameG ~= col.g or self.NameB ~= col.b or self.NameA ~= col.a
	local miscColorChanged = self.MiscColor ~= misccol or self.MiscR ~= misccol.r or self.MiscG ~= misccol.g or self.MiscB ~= misccol.b or self.MiscA ~= misccol.a
	if self.m_Player == pl and self.NameText == name and self.MiscText == misc and not nameColorChanged and not miscColorChanged then return end
	if self.NameText ~= name then self.NameText = name self.NameLabel:SetText(name) self.NeedsMeasure = true end
	if self.MiscText ~= misc then self.MiscText = misc self.MiscLabel:SetText(misc or "") self.NeedsMeasure = true end
	if nameColorChanged then
		self.NameColor, self.NameR, self.NameG, self.NameB, self.NameA = col, col.r, col.g, col.b, col.a
		self.NameLabel:SetTextColor(col)
	end
	if miscColorChanged then
		self.MiscColor, self.MiscR, self.MiscG, self.MiscB, self.MiscA = misccol, misccol.r, misccol.g, misccol.b, misccol.a
		self.MiscLabel:SetTextColor(misccol)
	end
	if self.m_Player ~= pl then
		self.m_Player = pl
		local bot = pl:IsBot()
		self.BotLabel:SetVisible(bot)
		if bot then
			if IsValid(self.Avatar) then self.Avatar:Remove() self.Avatar = nil end
		else
			if not IsValid(self.Avatar) then self.Avatar = self:Add("AvatarImage") self.Avatar:SetMouseInputEnabled(false) end
			self.Avatar:SetPlayer(pl, (GAMEMODE.MenuScale or 1) > 1 and 64 or 32)
		end
		self:SetTooltip(not bot and translate.Get("end_profile") or nil)
	end
	self:InvalidateLayout(true)
end

function PANEL:PerformLayout(width)
	self:DockMargin(0, 0, 0, U(8))
	local available = width - U(82)
	self.NameLabel:SetPos(U(62), U(12)) self.NameLabel:SetSize(available, self.NameHeight or U(24))
	self.MiscLabel:SetPos(U(62), U(20) + (self.NameHeight or U(24))) self.MiscLabel:SetSize(available, self.MiscHeight or U(26))
	self.BotLabel:SetPos(U(14), U(16)) self.BotLabel:SetSize(U(32), U(32))
	if IsValid(self.Avatar) then self.Avatar:SetPos(U(14), U(16)) self.Avatar:SetSize(U(32), U(32)) end
	if self.LayoutWidth ~= width then
		self.LayoutWidth = width self.NeedsMeasure = true
		self.NameLabel:InvalidateLayout(true) self.MiscLabel:InvalidateLayout(true)
	end
end

function PANEL:Paint(width, height)
	draw.RoundedBox(U(6), 0, 0, width, height, self:IsHovered() and colors.hover or colors.row)
end

function PANEL:OnMousePressed(button)
	if not IsValid(self) then return end
	local pl = self:GetPlayer()
	if button == MOUSE_LEFT and IsValid(pl) and not pl:IsBot() then gamemode.Call("ClickedEndBoardPlayerButton", pl, self) end
end
function PANEL:OnRemove()
	self.m_Player, self.Avatar, self.NameLabel, self.MiscLabel, self.BotLabel, self.EndBoard = nil, nil, nil, nil, nil, nil
end
vgui.Register("DEndBoardPlayerPanel", PANEL, "DPanel")

hook.Add("OnScreenSizeChanged", "ZSEndBoardLayout", function()
	if IsValid(pEndBoard) then
		if pEndBoard:IsVisible() then Layout(pEndBoard) else pEndBoard.LayoutDirty = true end
	end
end)
