if GM and IsValid(GM.m_SpectatorBrowser) then GM.m_SpectatorBrowser:Remove() GM.m_SpectatorBrowser = nil end
local function RefreshSpectators(frame)
	local revision = translate.GetRevision()
	local languageChanged = frame.LanguageRevision ~= revision
	if languageChanged then
		frame.LanguageRevision = revision
		frame.Title:SetText(translate.Get("mm_spectators"))
		frame.Empty:SetText(translate.Get("mm_no_spectators"))
		frame.CloseButton:SetText(translate.Get("mm_close"))
		frame.BackButton:SetText(translate.Get("mm_back"))
	end
	local rows = frame.PlayerPanels
	for pl, row in pairs(rows) do
		if not IsValid(pl) or pl:Team() ~= TEAM_SPECTATOR or not IsValid(row) then
			rows[pl] = nil
			if IsValid(row) then row:Remove() end
		end
	end
	local count = 0
	for _, pl in player.Iterator() do
		if pl:Team() == TEAM_SPECTATOR then
			count = count + 1
			if not IsValid(rows[pl]) then
				local row = vgui.Create("ZSPlayerPanel", frame.List)
				row.ScoreBoard = frame
				row.ManagedRefresh = true
				row.SpectatorOnly = true
				row.m_ScoreLabel:SetVisible(false)
				row:SetPlayer(pl)
				row:SetZPos(pl:EntIndex())
				row:Dock(TOP)
				row:DockMargin(0, 2, 4, 2)
				rows[pl] = row
			else
				rows[pl]:RefreshPlayer()
			end
		end
	end
	if languageChanged or count ~= frame.LastCount then
		frame.LastCount = count
		frame.Subtitle:SetText(translate.Format("mm_spectator_count", count))
		frame.Empty:SetVisible(count == 0)
	end
end

function MakepSpectators()
	local frame = GAMEMODE.m_SpectatorBrowser
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		GAMEMODE.m_SpectatorBrowser = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		local paint = frame.Paint
		frame.Paint = function(panel, width, height)
			draw.RoundedBox(8, 0, 0, width, height, GAMEMODE.ShopColors.header)
			paint(panel, width, height)
		end
		frame.Title = EasyLabel(frame, translate.Get("mm_spectators"), "ZSMenuTitle", color_white)
		frame.Subtitle = EasyLabel(frame, "", "ZSMenuSmall", GAMEMODE.ShopColors.muted)
		frame.Empty = EasyLabel(frame, translate.Get("mm_no_spectators"), "ZSMenuBody", GAMEMODE.ShopColors.muted)
		frame.List = vgui.Create("DScrollPanel", frame)
		frame.PlayerPanels = {}
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SetPos(20, 12)
			panel.Title:SetWide(width - 40)
			panel.Subtitle:SetPos(20, 44)
			panel.Subtitle:SetWide(width - 40)
			panel.Empty:SetPos(20, 88)
			panel.Empty:SetWide(width - 40)
			panel.List:SetPos(20, 88)
			panel.List:SetSize(width - 40, height - 152)
			panel.BackButton:SetSize(100, 32)
			panel.BackButton:SetPos(20, height - 48)
			panel.CloseButton:SetSize(100, 32)
			panel.CloseButton:SetPos(width - 120, height - 48)
		end
		frame.RefreshSpectators = RefreshSpectators
		frame.Think = function(panel)
			if not panel:IsVisible() or RealTime() < (panel.NextRefresh or 0) then return end
			panel.NextRefresh = RealTime() + 1
			panel:RefreshSpectators()
		end
		frame.OnRemove = function(panel)
			panel.PlayerPanels = nil
			if GAMEMODE.m_SpectatorBrowser == panel then GAMEMODE.m_SpectatorBrowser = nil end
		end
	end
	PlayMenuOpenSound()
	frame:SetSize(math.min(700, ScrW() - 32), math.min(550, ScrH() - 64))
	frame:Center()
	frame:InvalidateLayout(true)
	frame:SetVisible(true)
	frame:RefreshSpectators()
	frame:MakePopup()
	return frame
end
