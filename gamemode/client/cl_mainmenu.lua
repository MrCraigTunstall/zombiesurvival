local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if GM and IsValid(GM.HelpMenu) then GM.HelpMenu:Remove() GM.HelpMenu = nil end

local function Layout(menu)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local width, height = ScrW(), ScrH()
	menu.LayoutDirty = nil
	if menu.LayoutWidth == width and menu.LayoutHeight == height then return end
	menu.LayoutWidth, menu.LayoutHeight = width, height
	menu:SetSize(math.min(U(940), width - U(32)), math.min(U(600), height - U(64)))
	menu:Center()
	menu.Scroll:GetVBar():SetWide(U(12))
	menu:InvalidateLayout(true)
end

local childLimits = {{"m_PlayerModels", 940, 600}, {"m_PlayerColors", 940, 600}, {"m_SpectatorBrowser", 700, 550}}
local function LayoutChildren()
	local width, height = ScrW(), ScrH()
	for _, limit in ipairs(childLimits) do
		local frame = GAMEMODE[limit[1]]
		if IsValid(frame) and frame:IsVisible() then
			local targetWidth, targetHeight = math.min(limit[2], width - 32), math.min(limit[3], height - 64)
			local x, y = frame:GetPos()
			if frame:GetWide() ~= targetWidth or frame:GetTall() ~= targetHeight or x ~= math.floor((width - targetWidth) / 2) or y ~= math.floor((height - targetHeight) / 2) then
				frame:SetSize(targetWidth, targetHeight)
				frame:Center()
				frame:InvalidateLayout(true)
			end
		end
	end
end

local function UpdateSpectateButton(menu, revision, getter)
	if not IsValid(MySelf) then return end
	local teamid = MySelf:Team()
	if menu.LastTeam == teamid and menu.SpectateRevision == revision and menu.SpectateGetter == getter then return end
	menu.LastTeam = teamid
	menu.SpectateRevision, menu.SpectateGetter = revision, getter
	local text = translate.Get(teamid == TEAM_SPECTATOR and "mm_unsp" or "mm_sp")
	if menu.SpectateButton.Title:GetText() ~= text then menu.SpectateButton.Title:SetText(text) end
end

local function UpdateLabels(menu)
	local revision, getter = translate.GetRevision(), translate.Get
	if menu.LanguageRevision ~= revision or menu.LanguageGetter ~= getter then
		menu.LanguageRevision, menu.LanguageGetter = revision, getter
		for _, entry in ipairs(menu.LocalizedLabels) do
			local text = getter(entry[2])
			if entry[1]:GetText() ~= text then entry[1]:SetText(text) end
		end
	end
	UpdateSpectateButton(menu, revision, getter)
end

function GM:ShowHelp()
	local menu = self.HelpMenu
	if IsValid(menu) and menu:IsVisible() then
		menu:Close()
		return
	end
	PlayMenuOpenSound()
	if not IsValid(menu) then
		menu = vgui.Create("DFrame")
		menu:SetVisible(false)
		self.HelpMenu = menu
		menu:SetTitle("")
		menu:ShowCloseButton(false)
		menu:SetDraggable(false)
		menu:SetDeleteOnClose(false)
		self:StyleShopFrame(menu)
		local colors, background = self.ShopColors, Color(15, 20, 26)
		menu.Paint = function(_, width, height)
			draw.RoundedBox(U(8), 0, 0, width, height, background)
			draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
			surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), 2)
		end
		menu.Title = EasyLabel(menu, translate.Get("mm_menu"), "ZSMenuScaledTitle", color_white)
		menu.Subtitle = EasyLabel(menu, translate.Get("mm_hub_description"), "ZSMenuScaledSmall", self.ShopColors.muted)
		menu.CloseButton = vgui.Create("DButton", menu)
		menu.CloseButton:SetText(translate.Get("mm_close"))
		self:StyleShopButton(menu.CloseButton, false, true)
		menu.CloseButton.DoClick = function() if IsValid(menu) then menu:Close() end end
		menu.Scroll = vgui.Create("DScrollPanel", menu)
		local bar = menu.Scroll:GetVBar()
		bar:SetWide(U(12))
		bar.Paint = function(_, width, height) draw.RoundedBox(U(4), 0, 0, width, height, colors.row) end
		for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			button.Paint = function(panel, width, height) draw.RoundedBox(U(4), 0, 0, width, height, panel.Hovered and colors.accent or colors.muted) end
		end
		menu.Cards = {}
		menu.LocalizedLabels = {{menu.Title, "mm_menu"}, {menu.Subtitle, "mm_hub_description"}, {menu.CloseButton, "mm_close"}}
		local actions = {
			{"help_help", "mm_help_description", "icon16/book_open.png", function() MakepHelp() end},
			{"mm_options", "mm_options_description", "icon16/cog.png", function() MakepOptions() end},
			{"taunt_title", "taunt_description", "icon16/emoticon_smile.png", function() GAMEMODE:OpenTauntMenu() end},
			{"mm_pm3", "mm_models_description", "icon16/user.png", function() MakepPlayerModel() end},
			{"mm_pc", "mm_color_description", "icon16/color_wheel.png", function() MakepPlayerColor() end},
			{"mm_cosmetics", "mm_cosmetics_description", "icon16/star.png", function() RunConsoleCommand("zs_cosmetics") end},
			{"mapvote_title", "mm_mapvote_description", "icon16/map.png", function() GAMEMODE:OpenMapVote() end},
			{"mm_spectators", "mm_spectators_description", "icon16/group.png", function() MakepSpectators() end},
			{"mm_sp", "mm_spectate_description", "icon16/eye.png", function() RunConsoleCommand("spectate") end},
			{"mm_credits", "mm_credits_description", "icon16/heart.png", function() MakepCredits() end},
			{"mm_credits2", "mm_credits_description", "icon16/heart.png", function() MakepCredits2() end},
			{"notification_details_title", "notification_details_description", "icon16/information.png", function() GAMEMODE:OpenNotificationDetails() end}
		}
		for _, action in ipairs(actions) do
			local callback = action[4]
			local card = vgui.Create("DButton", menu.Scroll:GetCanvas())
			card:SetText("")
			self:StyleShopButton(card, false, true)
			card.ActionID = action[1]
			card.DoClick = function() if IsValid(menu) then menu:Close() callback() end end
			card.Icon = vgui.Create("DImage", card)
			card.Icon:SetImage(action[3])
			card.Icon:SetMouseInputEnabled(false)
			card.Title = EasyLabel(card, translate.Get(action[1]), "ZSMenuScaledBody", color_white)
			card.Title:SetMouseInputEnabled(false)
			card.Description = EasyLabel(card, translate.Get(action[2]), "ZSMenuScaledSmall", self.ShopColors.muted)
			card.Description:SetWrap(true)
			card.Description:SetMouseInputEnabled(false)
			if action[1] ~= "mm_sp" then menu.LocalizedLabels[#menu.LocalizedLabels + 1] = {card.Title, action[1]} end
			menu.LocalizedLabels[#menu.LocalizedLabels + 1] = {card.Description, action[2]}
			card.PerformLayout = function(panel, width, height)
				panel.Icon:SetPos(U(14), U(18))
				panel.Icon:SetSize(U(16), U(16))
				panel.Title:SetPos(U(42), U(12))
				panel.Title:SetSize(width - U(54), U(22))
				panel.Description:SetPos(U(42), U(38))
				panel.Description:SetSize(width - U(54), height - U(46))
			end
			menu.Cards[#menu.Cards + 1] = card
			if action[1] == "mm_sp" then menu.SpectateButton = card end
		end
		menu.PerformLayout = function(panel, width, height)
			panel.Title:SetPos(U(20), U(12))
			panel.Title:SetWide(width - U(40))
			panel.Subtitle:SetPos(U(20), U(44))
			panel.Subtitle:SetWide(width - U(40))
			panel.CloseButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48))
			panel.Scroll:SetPos(U(20), U(88))
			panel.Scroll:SetSize(width - U(40), height - U(152))
			local available = panel.Scroll:GetWide() - U(18)
			local columns = math.max(1, math.min(3, math.floor((available + U(12)) / U(260))))
			local cardWidth = (available - (columns - 1) * U(12)) / columns
			for index, card in ipairs(panel.Cards) do
				card:SetSize(cardWidth, U(88))
				card:SetPos((index - 1) % columns * (cardWidth + U(12)), math.floor((index - 1) / columns) * U(100))
			end
			panel.Scroll:GetCanvas():SetTall(math.ceil(#panel.Cards / columns) * U(100) - U(12))
		end
		local nativeThink = menu.Think
		menu.Think = function(panel)
			if not panel:IsVisible() then return end
			if panel.LayoutDirty then Layout(panel) end
			if nativeThink then nativeThink(panel) end
			local now = RealTime()
			if now < (panel.NextStateRefresh or 0) then return end
			panel.NextStateRefresh = now + 0.25
			UpdateLabels(panel)
		end
		menu.OnRemove = function(panel)
			panel.Cards, panel.LocalizedLabels, panel.SpectateButton, panel.Scroll = nil, nil, nil, nil
			panel.Title, panel.Subtitle, panel.CloseButton = nil, nil, nil
			panel.LanguageGetter, panel.SpectateGetter = nil, nil
			if self.HelpMenu == panel then self.HelpMenu = nil end
		end
	end
	Layout(menu)
	UpdateLabels(menu)
	menu:SetVisible(true)
	menu:MakePopup()
	return menu
end

hook.Add("OnScreenSizeChanged", "ZSMainMenuLayout", function()
	local menu = GAMEMODE.HelpMenu
	if IsValid(menu) then
		if menu:IsVisible() then Layout(menu) else menu.LayoutDirty = true end
	end
	LayoutChildren()
end)
