if GM and IsValid(GM.m_PlayerModels) then GM.m_PlayerModels:Remove() GM.m_PlayerModels = nil end
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local width, height = math.min(U(940), screenWidth - 32), math.min(U(600), screenHeight - 64)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth == width and frame.LayoutHeight == height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth, frame.LayoutHeight = width, height
 frame:SetSize(width, height) frame:Center() frame:InvalidateLayout(true)
end
local whitelist = {["0000000000"]=true, ["1111111111"]=true, ["222222222222"]=true}

local function Text(control, value)
	if control.ModelText ~= value then control.ModelText = value control:SetText(value) end
end

local function Fit(text, width)
	surface.SetFont("ZSMenuScaledSmall")
	if surface.GetTextSize(text) <= width then return text end
	local clipped = ""
	for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		local candidate = clipped .. character
		if surface.GetTextSize(candidate .. "…") > width then break end
		clipped = candidate
	end
	return clipped .. "…"
end

local function LayoutCard(card, width)
	local scale = GAMEMODE.MenuScale
	if card.LabelWidth == width and card.LabelScale == scale and card.LabelName == card.RawName and card.LabelStatus == card.RawStatus then return end
	card.LabelWidth, card.LabelScale, card.LabelName, card.LabelStatus = width, scale, card.RawName, card.RawStatus
	card.Icon:SetSize(U(64), U(64)) card.Icon:SetPos((width - U(64)) * 0.5, U(4))
	card.Name:SetPos(U(4), U(68)) card.Name:SetSize(width - U(8), U(14))
	card.Status:SetPos(U(4), U(82)) card.Status:SetSize(width - U(8), U(14))
	Text(card.Name, Fit(card.RawName or "", math.max(1, width - U(8))))
	Text(card.Status, Fit(card.RawStatus or "", math.max(1, width - U(8))))
end

local function Enable(control, value)
	if control:IsEnabled() ~= value then control:SetEnabled(value) end
end

function GM:BuildPlayerModelCatalogue(models, player)
	local owners, restricted, entries = {}, {}, {}
	local steamid, donator = player:SteamID64(), player.IsDonator and player:IsDonator()
	for _, model in ipairs(self.RestrictedModels) do restricted[string.lower(model)] = true end
	for _, entry in pairs(self.SteamIDAndModels) do
		local model = string.lower(entry[2])
		owners[model] = owners[model] or {}
		owners[model][entry[1]] = true
	end
	for name, model in pairs(models) do
		local lower = string.lower(model)
		local reason
		if restricted[lower] then
			reason = "mm_model_unavailable"
		elseif self.DonatorModels[lower] and not donator then
			reason = "mm_model_donator"
		elseif not self.DonatorModels[lower] and owners[lower] and not owners[lower][steamid] and not whitelist[steamid] then
			reason = "mm_model_private"
		end
		entries[#entries+1] = {name=name, model=model, search=string.lower(name).." "..lower, reason=reason,
			exclusive=self.DonatorModels[lower] or owners[lower] ~= nil}
	end
	table.sort(entries, function(a, b)
		local left, right = string.lower(a.name), string.lower(b.name)
		return left == right and a.name < b.name or left < right
	end)
	return entries
end

function GM:FilterPlayerModels(entries, query)
	query = string.Trim(string.lower(query or ""))
	if query == "" then return entries end
	local filtered = {}
	for _, entry in ipairs(entries) do
		if string.find(entry.search, query, 1, true) then filtered[#filtered+1] = entry end
	end
	return filtered
end

local function SelectModel(card)
	local frame, entry = card.Owner, card.Entry
	if not entry or entry.reason or not IsValid(MySelf) or not MySelf:IsPlayer() then return end
	for _, current in ipairs(GAMEMODE:BuildPlayerModelCatalogue({[entry.name]=entry.model}, MySelf)) do
		if current.reason then frame:RefreshCatalogue() return end
	end
	RunConsoleCommand("cl_playermodel", entry.name)
	chat.AddText(COLOR_LIMEGREEN, translate.Format("mm_pm_messg", entry.name))
	surface.PlaySound("buttons/button14.wav")
	frame:Close()
end

local function RefreshPage(frame)
	local revision = translate.GetRevision()
	if frame.LanguageRevision ~= revision then
		frame.LanguageRevision = revision
		for _, pair in ipairs({{frame.Title, "mm_pm2"}, {frame.Subtitle, "mm_model_spawn_notice"}, {frame.Empty, "mm_model_no_results"},
			{frame.Previous, "mm_model_previous"}, {frame.Next, "mm_model_next"}, {frame.BackButton, "mm_back"}, {frame.CloseButton, "mm_close"}}) do
			Text(pair[1], translate.Get(pair[2]))
		end
		frame.Search:SetPlaceholderText(translate.Get("mm_model_search"))
	end
	local entries, size = frame.Filtered, frame.PageSize or 1
	local pages = math.max(1, math.ceil(#entries / size))
	frame.Page = math.Clamp(frame.Page or 1, 1, pages)
	local selected = GetConVarString("cl_playermodel")
	frame.SelectedModel = selected
	local first = (frame.Page - 1) * size
	for index = 1, size do
		local card = frame.Cards[index]
		if not IsValid(card) then
			card = vgui.Create("DPanel", frame.Grid)
			card.Owner = frame
			card.Paint = function(panel, width, height)
				draw.RoundedBox(5, 0, 0, width, height, panel.Selected and GAMEMODE.ShopColors.selected or GAMEMODE.ShopColors.row)
			end
			card.Icon = vgui.Create("SpawnIcon", card)
			card.Icon:SetSize(U(64), U(64))
			if card.Icon.SetTooltipPanelOverride then card.Icon:SetTooltipPanelOverride("ZSShopTooltip") end
			card.Icon.DoClick = function() SelectModel(card) end
			card.Icon.DoRightClick = function() end
			card.Name = EasyLabel(card, "", "ZSMenuScaledSmall", color_white)
			card.Name:SetContentAlignment(5)
			card.Name:SetMouseInputEnabled(false)
			card.Status = EasyLabel(card, "", "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
			card.Status:SetContentAlignment(5)
			card.Status:SetMouseInputEnabled(false)
			card.PerformLayout = LayoutCard
			frame.Cards[index] = card
		end
		local entry = entries[first + index]
		card:SetVisible(entry ~= nil)
		card.Entry = entry
		if entry then
			card.Selected = entry.name == selected
			if card.Model ~= entry.model then card.Icon:SetModel(entry.model) card.Model = entry.model end
			Enable(card.Icon, not entry.reason)
			local reason = entry.reason and translate.Get(entry.reason)
			local status = reason or entry.exclusive and translate.Get("mm_model_exclusive") or ""
			if card.RawName ~= entry.name or card.RawStatus ~= status then
				card.RawName, card.RawStatus = entry.name, status
				card:InvalidateLayout(true)
			end
			local tooltip = entry.name.."\n"..entry.model..(reason and "\n"..reason or "")
			if card.Tooltip ~= tooltip then card.Tooltip = tooltip card.Icon:SetTooltip(tooltip) end
		end
	end
	for index = size + 1, #frame.Cards do frame.Cards[index]:SetVisible(false) end
	Enable(frame.Previous, frame.Page > 1)
	Enable(frame.Next, frame.Page < pages)
	if frame.CaptionPage ~= frame.Page or frame.CaptionPages ~= pages or frame.CaptionCount ~= #entries or frame.CaptionRevision ~= revision then
		frame.CaptionPage, frame.CaptionPages, frame.CaptionCount, frame.CaptionRevision = frame.Page, pages, #entries, revision
		Text(frame.PageLabel, translate.Format("mm_model_page", frame.Page, pages, #entries))
	end
	frame.Empty:SetVisible(#entries == 0)
end

function MakepPlayerModel()
	GAMEMODE:RefreshMenuScale()
	if not IsValid(MySelf) or not MySelf:IsPlayer() then return end
	local frame = GAMEMODE.m_PlayerModels
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		frame:SetVisible(false)
		GAMEMODE.m_PlayerModels = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(8, 0, 0, width, height, GAMEMODE.ShopColors.background)
			draw.RoundedBox(8, 0, 0, width, U(72), GAMEMODE.ShopColors.header)
			surface.SetDrawColor(GAMEMODE.ShopColors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		frame.Title = EasyLabel(frame, translate.Get("mm_pm2"), "ZSMenuScaledTitle", color_white)
		frame.Subtitle = EasyLabel(frame, translate.Get("mm_model_spawn_notice"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
		frame.Subtitle:SetWrap(true)
		frame.Search = vgui.Create("DTextEntry", frame)
		GAMEMODE:StyleShopSearch(frame.Search, true)
		frame.Search:SetPlaceholderText(translate.Get("mm_model_search"))
		frame.Search.OnChange = function() frame.PendingSearch = RealTime() + 0.15 end
		frame.Search.OnEnter = function() frame:ApplySearch() end
		frame.Grid = vgui.Create("DPanel", frame)
		frame.Grid.Paint = function() end
		frame.Empty = EasyLabel(frame.Grid, translate.Get("mm_model_no_results"), "ZSMenuScaledBody", GAMEMODE.ShopColors.muted)
		frame.Empty:SetContentAlignment(5)
		frame.Cards = {}
		frame.Previous = vgui.Create("DButton", frame)
		frame.Previous:SetText(translate.Get("mm_model_previous"))
		GAMEMODE:StyleShopButton(frame.Previous, false, true)
		frame.Previous.DoClick = function() frame.Page = frame.Page - 1 RefreshPage(frame) end
		frame.Next = vgui.Create("DButton", frame)
		frame.Next:SetText(translate.Get("mm_model_next"))
		GAMEMODE:StyleShopButton(frame.Next, false, true)
		frame.Next.DoClick = function() frame.Page = frame.Page + 1 RefreshPage(frame) end
		frame.PageLabel = EasyLabel(frame, "", "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
		frame.PageLabel:SetContentAlignment(5)
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.ApplySearch = function(panel)
			panel.PendingSearch = nil
			panel.Filtered = GAMEMODE:FilterPlayerModels(panel.Entries, panel.Search:GetValue())
			panel.Page = 1
			RefreshPage(panel)
		end
		frame.RefreshCatalogue = function(panel)
			panel.Entries = GAMEMODE:BuildPlayerModelCatalogue(player_manager.AllValidModels(), MySelf)
			panel:ApplySearch()
		end
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if not IsValid(MySelf) or not MySelf:IsPlayer() then panel:Close() return end
			local now = RealTime()
			if panel.PendingSearch and now >= panel.PendingSearch then panel:ApplySearch() end
			if now < (panel.NextStateRefresh or 0) then return end
			panel.NextStateRefresh = now + 0.2
			if panel.LanguageRevision ~= translate.GetRevision() or panel.SelectedModel ~= GetConVarString("cl_playermodel") then RefreshPage(panel) end
		end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SetPos(U(20), U(12)) panel.Title:SetSize(width - U(40), U(32))
			panel.Subtitle:SetPos(U(20), U(44)) panel.Subtitle:SetSize(width - U(40), U(32))
			panel.Search:SetPos(U(20), U(88)) panel.Search:SetSize(width - U(40), U(28))
			local gridWidth, gridHeight = width - U(40), height - U(216)
			panel.Grid:SetPos(U(20), U(124)) panel.Grid:SetSize(gridWidth, gridHeight)
			panel.Empty:SetSize(gridWidth, gridHeight)
			local columns = math.max(1, math.floor(gridWidth / U(112)))
			local rows = math.max(1, math.floor((gridHeight + U(8)) / U(104)))
			local size = math.min(24, columns * rows)
			if panel.PageSize ~= size then local first = ((panel.Page or 1) - 1) * (panel.PageSize or size) panel.PageSize = size panel.Page = math.floor(first / size) + 1 if panel.Filtered then RefreshPage(panel) end end
			local cardWidth = (gridWidth - (columns - 1) * U(8)) / columns
			for index, card in ipairs(panel.Cards) do
				card:SetSize(cardWidth, U(96))
				card:SetPos((index - 1) % columns * (cardWidth + U(8)), math.floor((index - 1) / columns) * U(104))
				card:InvalidateLayout(true)
			end
			panel.Previous:SetPos(U(20), height - U(84)) panel.Previous:SetSize(U(90), U(28))
			panel.Next:SetPos(width - U(110), height - U(84)) panel.Next:SetSize(U(90), U(28))
			panel.PageLabel:SetPos(U(116), height - U(84)) panel.PageLabel:SetSize(width - U(232), U(28))
			panel.BackButton:SetPos(U(20), height - U(48)) panel.BackButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
		end
		frame.OnRemove = function(panel)
			panel.Cards, panel.Entries, panel.Filtered = nil, nil, nil
			if GAMEMODE.m_PlayerModels == panel then GAMEMODE.m_PlayerModels = nil end
		end
	end
	Layout(frame)
	if frame:IsVisible() then return frame end
	PlayMenuOpenSound()
	frame:RefreshCatalogue()
	frame:InvalidateLayout(true)
	frame:SetVisible(true)
	frame.NextStateRefresh = 0
	frame:MakePopup()
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSPlayerModelLayout", function()
 if IsValid(GAMEMODE.m_PlayerModels) then Layout(GAMEMODE.m_PlayerModels) end
end)
