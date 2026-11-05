local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if GM and IsValid(GM.m_Credits) then GM.m_Credits:Remove() GM.m_Credits = nil end

local function LayoutCreditLabel(label, width)
	surface.SetFont(label.CreditsFont)
	local _, lineHeight = surface.GetTextSize("Mg")
	local lines, line = {}, ""
	local function Append(word)
		local candidate = line == "" and word or line .. " " .. word
		if surface.GetTextSize(candidate) <= width then line = candidate return end
		if line ~= "" then lines[#lines + 1] = line line = "" end
		if surface.GetTextSize(word) <= width then line = word return end
		for character in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			candidate = line .. character
			if line ~= "" and surface.GetTextSize(candidate) > width then lines[#lines + 1] = line line = character else line = candidate end
		end
	end
	for paragraph in (label.CreditsText .. "\n"):gmatch("(.-)\n") do
		for word in paragraph:gmatch("%S+") do Append(word) end
		lines[#lines + 1] = line line = ""
	end
	label:SetText(table.concat(lines, "\n"))
	label:SetTall(#lines * lineHeight)
end

local function BuildCredits(list, entries)
	list.Cards = {}
	for _, entry in ipairs(entries) do
		local card = vgui.Create("DPanel", list)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, U(4))
		card:SetTall(U(100))
		card.Paint = function(self, width, height) draw.RoundedBox(U(5), 0, 0, width, height, GAMEMODE.ShopColors.row) end
		card.Labels = {}
		for index, text in ipairs({string.Replace(entry[1], "@", "(at)"), entry[3] or "", entry[2] or ""}) do
			local label = EasyLabel(card, text, index == 1 and "ZSMenuScaledBody" or "ZSMenuScaledSmall",
				index == 1 and color_white or GAMEMODE.ShopColors.muted)
			label.CreditsText, label.CreditsFont = text, index == 1 and "ZSMenuScaledBody" or "ZSMenuScaledSmall"
			label:SetWrap(false)
			label:SetContentAlignment(7)
			label:SetTooltip(text)
			card.Labels[#card.Labels+1] = label
		end
		card.PerformLayout = function(panel, width)
			if width < 32 or panel.ContentWidth == width then return end
			panel.ContentWidth = width
			for _, label in ipairs(panel.Labels) do label:SetWide(width - U(20)) end
			timer.Simple(0, function()
				if not IsValid(panel) or panel.ContentWidth ~= width then return end
				local y = U(8)
				for _, label in ipairs(panel.Labels) do
					LayoutCreditLabel(label, width - U(20))
					label:SetPos(U(10), y)
					if label.CreditsText ~= "" then y = y + label:GetTall() + U(1) end
				end
				panel:SetTall(y + U(5))
			end)
		end

		list.Cards[#list.Cards+1] = card
	end
end

local function Layout(frame)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local width, height = ScrW(), ScrH()
	frame.LayoutDirty = nil
	if frame.LayoutWidth == width and frame.LayoutHeight == height then return end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	frame:SetSize(math.min(U(940), width - U(32)), math.min(U(600), height - U(64)))
	frame:Center()
	frame:InvalidateLayout(true)
end

local function RefreshLabels(frame)
	local revision, getter = translate.GetRevision(), translate.Get
	if frame.LanguageRevision == revision and frame.LanguageGetter == getter then return end
	frame.LanguageRevision, frame.LanguageGetter = revision, getter
	for _, entry in ipairs(frame.LocalizedLabels) do
		local value = getter(entry[2])
		if entry[1].ZSCreditsText ~= value then entry[1].ZSCreditsText = value entry[1]:SetText(value) end
	end
	frame.Sheet:InvalidateLayout(true)
end

local function OpenCredits(index)
	local frame = GAMEMODE.m_Credits
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		frame:SetVisible(false)
		GAMEMODE.m_Credits = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		local colors, background = GAMEMODE.ShopColors, Color(15, 20, 26)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(U(8), 0, 0, width, height, background)
			draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
			surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		local nativeThink = frame.Think
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if panel.LayoutDirty then Layout(panel) end
			if nativeThink then return nativeThink(panel) end
		end
		frame.Title = EasyLabel(frame, translate.Get("credits_credits"), "ZSMenuScaledTitle", color_white)
		frame.Subtitle = EasyLabel(frame, translate.Get("mm_credits_description"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
		frame.Sheet = vgui.Create("DPropertySheet", frame)
		GAMEMODE:ScaleMenuSheet(frame.Sheet)
		frame.Sheet:SetPadding(U(8))
		frame.Sheet:SetFadeTime(0)
		frame.Sheet.Paint = function() end
		frame.Tabs = {}
		for _, entry in ipairs({{"mm_credits", GAMEMODE.Credits}, {"mm_credits2", GAMEMODE.Credits2}}) do
			local list = vgui.Create("DScrollPanel", frame.Sheet)
			if list.GetVBar then
				local bar = list:GetVBar()
				bar:SetWide(U(12))
				bar.Paint = function(_, width, height) draw.RoundedBox(U(4), 0, 0, width, height, background) end
				for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
					button.Paint = function(panel, width, height) draw.RoundedBox(U(4), 0, 0, width, height, panel.Hovered and colors.hover or colors.row) end
				end
			end
			local item = GAMEMODE:AddLazyShopSheet(frame.Sheet, translate.Get(entry[1]), list, "icon16/heart.png", function() BuildCredits(list, entry[2]) end)
			item.Tab:SetFont("ZSMenuScaledSmall")
			item.Tab:SetTextColor(color_white)
			item.Tab.Paint = function(tab, width, height)
				draw.RoundedBox(U(4), 0, 0, width, height, frame.Sheet:GetActiveTab() == tab and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
			end
			frame.Tabs[#frame.Tabs+1] = item.Tab
		end
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SizeToContents() panel.Subtitle:SizeToContents()
			panel.Title:SetPos(U(20), U(12)) panel.Title:SetWide(width - U(40))
			panel.Subtitle:SetPos(U(20), U(44)) panel.Subtitle:SetWide(width - U(40))
			panel.Sheet:SetPos(U(20), U(88)) panel.Sheet:SetSize(width - U(40), height - U(152))
			panel.BackButton:SetPos(U(20), height - U(48)) panel.BackButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
		end
		frame.LocalizedLabels = {{frame.Title, "credits_credits"}, {frame.Subtitle, "mm_credits_description"}, {frame.BackButton, "mm_back"}, {frame.CloseButton, "mm_close"}, {frame.Tabs[1], "mm_credits"}, {frame.Tabs[2], "mm_credits2"}}
		frame.OnRemove = function(panel)
			panel.Sheet, panel.Tabs, panel.LocalizedLabels = nil, nil, nil
			panel.LanguageGetter = nil
			if GAMEMODE.m_Credits == panel then GAMEMODE.m_Credits = nil end
		end
	end
	RefreshLabels(frame)
	Layout(frame)
	frame.Sheet:SetActiveTab(frame.Tabs[index])
	if frame:IsVisible() then return frame end
	PlayMenuOpenSound()
	frame:SetVisible(true)
	frame:MakePopup()
	return frame
end

function MakepCredits() return OpenCredits(1) end
function MakepCredits2() return OpenCredits(2) end

hook.Add("OnScreenSizeChanged", "ZSCreditsLayout", function()
	local frame = GAMEMODE.m_Credits
	if IsValid(frame) then
		if frame:IsVisible() then Layout(frame) else frame.LayoutDirty = true end
	end
end)
hook.Add("ZSLanguageChanged", "ZSCreditsLanguage", function()
	local frame = GAMEMODE.m_Credits
	if IsValid(frame) and frame:IsVisible() then RefreshLabels(frame) end
end)

