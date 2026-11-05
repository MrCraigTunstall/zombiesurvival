local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local catalog, counts, menu = {}, {}, nil
local versions = {}
local transfer
local nextRequest, awaitingFirst, loadFailure = 0, false, nil
local currentVote, loaded = "", false
local cachedSearch, matches

local function Text(control, value)
	if control.MapVoteText ~= value then control.MapVoteText = value control:SetText(value) end
end

local function CanVote(row, now)
	return loaded and not menu.Disabled and IsValid(row) and row:IsVisible() and row.MapName ~= currentVote and now >= (menu.VoteReadyAt or 0)
end

local function UpdateVote()
	local selected = menu.List:GetSelectedLine()
	local row = selected and menu.List:GetLine(selected)
	local enabled = CanVote(row, RealTime()) or false
	if menu.Vote:IsEnabled() ~= enabled then menu.Vote:SetEnabled(enabled) end
end

local function RefreshLanguage()
	local revision = translate.GetRevision()
	if menu.LanguageRevision == revision then return false end
	menu.LanguageRevision = revision
	for _, pair in ipairs({{menu.Title, "mapvote_title"}, {menu.Subtitle, "mm_mapvote_description"}, {menu.Vote, "mapvote_vote"},
		{menu.BackButton, "mm_back"}, {menu.CloseButton, "mm_close"},
		{menu.ColumnHeaders[1], "mapvote_map"}, {menu.ColumnHeaders[2], "mapvote_count"}}) do Text(pair[1], translate.Get(pair[2])) end
	menu.Search:SetPlaceholderText(translate.Get("mapvote_search"))
	return true
end

local function Newer(a, b)
	local delta = (a - b) % 4294967296
	return delta > 0 and delta < 2147483648
end

local function UpdateStatus()
	if not IsValid(menu) or not menu:IsVisible() then return end
	local progress = transfer and (transfer.offset - 1) / transfer.total
	menu.TransferProgress = not menu.Disabled and progress or nil
	local color = (menu.Disabled or loadFailure and loadFailure ~= "mapvote_refresh_wait") and COLOR_RED or GAMEMODE.ShopColors.muted
	if menu.StatusColor ~= color then menu.StatusColor = color menu.Status:SetTextColor(color) end
	if not menu.Disabled and transfer then
		local percent, revision = math.floor(progress * 100), translate.GetRevision()
		if menu.StatusProgress ~= percent or menu.StatusProgressRevision ~= revision then
			menu.StatusProgress, menu.StatusProgressRevision = percent, revision
			Text(menu.Status, translate.Format("mapvote_loading_progress", percent))
		end
		return
	end
	menu.StatusProgress, menu.StatusProgressRevision = nil, nil
	if menu.Disabled then
		Text(menu.Status, translate.Get("mapvote_disabled"))
	elseif loadFailure then
		Text(menu.Status, translate.Get(loadFailure))
	elseif awaitingFirst or not loaded then
		Text(menu.Status, translate.Get("mapvote_loading"))
	elseif not matches or #matches == 0 then
		Text(menu.Status, translate.Get(#catalog == 0 and "mapvote_empty" or "mapvote_no_matches"))
	else
		Text(menu.Status, currentVote ~= "" and translate.Format("mapvote_selected", currentVote) or translate.Get("mapvote_choose"))
	end
end

local function UpdateRefresh(now)
	if not IsValid(menu) or not menu:IsVisible() then return end
	local seconds, revision = math.max(0, math.ceil(nextRequest - now)), translate.GetRevision()
	if menu.RefreshSeconds ~= seconds or menu.RefreshRevision ~= revision then
		menu.RefreshSeconds, menu.RefreshRevision = seconds, revision
		Text(menu.Refresh, seconds > 0 and translate.Format("mapvote_refresh_countdown", seconds) or translate.Get("mapvote_refresh"))
	end
	local enabled = seconds == 0
	if menu.Refresh:IsEnabled() ~= enabled then menu.Refresh:SetEnabled(enabled) end
end

local function RequestCatalog(refresh)
	local now = RealTime()
	if now < nextRequest or not refresh and transfer then return false end
	nextRequest, awaitingFirst, transfer, loadFailure = now + 5, true, nil, nil
	UpdateStatus()
	UpdateRefresh(now)
	if refresh then RunConsoleCommand("zs_mapvote_catalog", "refresh") else RunConsoleCommand("zs_mapvote_catalog") end
	return true
end

local function FailTransfer()
	transfer, awaitingFirst, loadFailure = nil, false, "mapvote_load_failed"
	UpdateStatus()
end

local function Populate()
	if not IsValid(menu) then return end
	if not menu:IsVisible() then menu.CatalogDirty = true return end
	menu.CatalogDirty, menu.SearchDue = nil, nil
	RefreshLanguage()
	local search = string.Trim(string.lower(menu.Search:GetValue()))
	if cachedSearch ~= search then
		cachedSearch, matches = search, {}
		for _, name in ipairs(catalog) do if string.find(name, search, 1, true) then matches[#matches + 1] = name end end
	end
	local pages = math.max(1, math.ceil(#matches / 64))
	menu.Page = math.Clamp(menu.Page or 1, 1, pages)
	menu.List:ClearSelection()
	menu.VisibleRows = {}
	menu.Vote:SetEnabled(false)
	local first, visible = (menu.Page - 1) * 64, math.min(64, #matches - (menu.Page - 1) * 64)
	for index = 1, visible do
		local name = matches[first + index]
		local count = counts[name] or 0
		local row = menu.Rows[index]
		if not IsValid(row) then
			row = menu.List:AddLine(name, count)
			row.MapName, row.VoteCount = name, count
			row.Paint = function(self, width, height)
				draw.RoundedBox(3, 0, 0, width, height, self:IsSelected() and GAMEMODE.ShopColors.selected
					or self:IsHovered() and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
			end
			for _, label in ipairs(row.Columns) do label:SetFont("ZSMenuScaledBody") label:SetTextColor(color_white) end
			menu.Rows[index] = row
		else
			if row.MapName ~= name then row:SetColumnText(1, name) row.MapName = name end
			if row.VoteCount ~= count then row:SetColumnText(2, count) row.VoteCount = count end
		end
		row:SetVisible(true)
		menu.List.Sorted[index] = row
		menu.VisibleRows[name] = row
		if name == menu.Selected then menu.List:SelectItem(row) end
	end
	for index = visible + 1, #menu.Rows do menu.Rows[index]:SetVisible(false) menu.List.Sorted[index] = menu.Rows[index] end
	menu.List:SetDirty(true)
	menu.List:InvalidateLayout()
	menu.Previous:SetEnabled(menu.Page > 1)
	menu.NextPage:SetEnabled(menu.Page < pages)
	Text(menu.Pages, menu.Page .. " / " .. pages)
	UpdateStatus()
	UpdateRefresh(RealTime())
	UpdateVote()
end

local function RemoveMenu(frame)
 for _, key in ipairs({"Rows", "VisibleRows", "ColumnHeaders", "CountColumn", "Title", "Subtitle", "Search", "List", "Vote", "Previous", "NextPage", "Pages", "Refresh", "Status", "BackButton", "CloseButton"}) do frame[key] = nil end
 if GAMEMODE.m_MapVote == frame then GAMEMODE.m_MapVote = nil end
 if menu == frame then menu = nil end
end

local function Layout(frame)
 GAMEMODE:RefreshMenuScale()
 local width,height=math.min(U(940),ScrW()-32),math.min(U(600),ScrH()-64)
 local screenChanged=frame.ScreenWidth~=ScrW()or frame.ScreenHeight~=ScrH()
 frame.ScreenWidth,frame.ScreenHeight=ScrW(),ScrH()
 if frame.MenuWidth==width and frame.MenuHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.MenuWidth,frame.MenuHeight=width,height
 frame:SetSize(width,height)frame:Center()frame:InvalidateLayout(true)
end
hook.Add("OnScreenSizeChanged","ZSMapVoteMenuLayout",function()if IsValid(menu)then Layout(menu)end end)
function GM:OpenMapVote()
 self:RefreshMenuScale()
	if not IsValid(menu) then
		menu = vgui.Create("DFrame")
		local menu = menu
		menu:SetVisible(false)
		self.m_MapVote = menu
		menu:SetTitle("")
		menu:ShowCloseButton(false)
		menu:SetDraggable(false)
		menu:SetDeleteOnClose(false)
		self:StyleShopFrame(menu)
  menu.Paint = function(frame,width,height)
   draw.RoundedBox(U(8),0,0,width,height,GAMEMODE.ShopColors.background)
   draw.RoundedBox(U(8),0,0,width,U(72),GAMEMODE.ShopColors.header)
   surface.SetDrawColor(GAMEMODE.ShopColors.accent)surface.DrawRect(U(16),U(70),width-U(32),U(2))
   if frame.TransferProgress then
    draw.RoundedBox(U(2),U(20),height-U(91),width-U(40),U(3),GAMEMODE.ShopColors.row)
    draw.RoundedBox(U(2),U(20),height-U(91),(width-U(40))*frame.TransferProgress,U(3),GAMEMODE.ShopColors.accent)
   end
  end
		menu.Title = EasyLabel(menu, translate.Get("mapvote_title"), "ZSMenuScaledTitle", color_white)
		menu.Subtitle = EasyLabel(menu, translate.Get("mm_mapvote_description"), "ZSMenuScaledSmall", self.ShopColors.muted)
		menu.Search = vgui.Create("DTextEntry", menu)
		menu.Search:SetPlaceholderText(translate.Get("mapvote_search"))
		self:StyleShopSearch(menu.Search,true)
		local colors = self.ShopColors
		menu.Search.OnChange = function() if not IsValid(menu) then return end menu.Page = 1 menu.SearchDue = RealTime() + 0.15 end
		menu.Search.OnEnter = function() if IsValid(menu) then Populate() end end
		menu.List = vgui.Create("DListView", menu)
		menu.Rows, menu.VisibleRows = {}, {}
		menu.List:SetMultiSelect(false)
		menu.List:SetDataHeight(U(28))
		menu.List:SetHeaderHeight(U(28))
		local bar = menu.List.VBar
		if IsValid(bar) then
			bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, colors.row) end
			for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
				button.Paint = function(control, width, height)
					draw.RoundedBox(4, 0, 0, width, height, control:IsHovered() and colors.accent or colors.muted)
				end
			end
		end
		menu.List.Paint = function(self, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
		menu.List.OnRowSelected = function(_, _, row)
			if not IsValid(menu) then return end
			menu.Selected = row:GetColumnText(1)
			UpdateVote()
		end
		menu.ColumnHeaders = {}
		for _, entry in ipairs({{"mapvote_map"}, {"mapvote_count", 80}}) do
			local column = menu.List:AddColumn(translate.Get(entry[1]))
			if entry[2] then column:SetFixedWidth(U(entry[2]))menu.CountColumn=column end
			GAMEMODE:StyleShopButton(column.Header, false, true)
			menu.ColumnHeaders[#menu.ColumnHeaders + 1] = column.Header
		end
		menu.Vote = vgui.Create("DButton", menu)
		menu.Vote:SetText(translate.Get("mapvote_vote"))
		self:StyleShopButton(menu.Vote, true, true)
		menu.Vote.DoClick = function()
			if not IsValid(menu) then return end
			local selected = menu.List:GetSelectedLine()
			local row = selected and menu.List:GetLine(selected)
			local now = RealTime()
			if not CanVote(row, now) then return end
			menu.VoteReadyAt = now + 0.5
			menu.Vote:SetEnabled(false)
			Text(menu.Status, translate.Get("mapvote_wait"))
			RunConsoleCommand("zs_votemap", row.MapName)
		end
		menu.Previous = vgui.Create("DButton", menu)
		menu.Previous:SetText("<") self:StyleShopButton(menu.Previous, false, true)
		menu.Previous.DoClick = function() if not IsValid(menu) then return end menu.Page = math.max(1, (menu.Page or 1) - 1) Populate() end
		menu.NextPage = vgui.Create("DButton", menu)
		menu.NextPage:SetText(">") self:StyleShopButton(menu.NextPage, false, true)
		menu.NextPage.DoClick = function() if not IsValid(menu) then return end menu.Page = (menu.Page or 1) + 1 Populate() end
		menu.Pages = EasyLabel(menu, "", "ZSMenuScaledSmall", self.ShopColors.muted)
		menu.Pages:SetContentAlignment(5)
		menu.Refresh = vgui.Create("DButton", menu)
		menu.Refresh:SetText(translate.Get("mapvote_refresh")) self:StyleShopButton(menu.Refresh, false, true)
		menu.Refresh.DoClick = function() if IsValid(menu) then RequestCatalog(true) end end
		menu.Status = EasyLabel(menu, "", "ZSMenuScaledSmall", self.ShopColors.muted)
		menu.BackButton = vgui.Create("DButton", menu)
		menu.BackButton:SetText(translate.Get("mm_back")) self:StyleShopButton(menu.BackButton, false, true)
		menu.BackButton.DoClick = function() if not IsValid(menu) then return end menu:Close() GAMEMODE:ShowHelp() end
		menu.CloseButton = vgui.Create("DButton", menu)
		menu.CloseButton:SetText(translate.Get("mm_close")) self:StyleShopButton(menu.CloseButton, false, true)
		menu.CloseButton.DoClick = function() if IsValid(menu) then menu:Close() end end
		local think = menu.Think
		menu.Think = function(frame)
			if not frame:IsVisible() then return end
			if think then think(frame) end
			local now = RealTime()
			if frame.SearchDue and now >= frame.SearchDue then Populate() end
			if now < (frame.NextStateRefresh or 0) then return end
			frame.NextStateRefresh = now + 0.2
			if RefreshLanguage() then Populate() else UpdateVote() end
			UpdateRefresh(now)
		end
		menu.PerformLayout = function(frame, width, height)
   frame.List:SetDataHeight(U(28))frame.List:SetHeaderHeight(U(28))
   frame.CountColumn:SetFixedWidth(U(80))
   if IsValid(frame.List.VBar)then frame.List.VBar:SetWide(U(16))end
			frame.Title:SetPos(U(20), U(12)) frame.Title:SetSize(width-U(40),U(32))
			frame.Subtitle:SetPos(U(20), U(44)) frame.Subtitle:SetSize(width-U(40),U(24))
			frame.Search:SetPos(U(20), U(88)) frame.Search:SetSize(width - U(40), U(28))
			frame.List:SetPos(U(20), U(124)) frame.List:SetSize(width - U(40), height - U(246))
			frame.Status:SetPos(U(20), height - U(116)) frame.Status:SetSize(width - U(40), U(28))
			frame.Previous:SetPos(U(20), height - U(84)) frame.Previous:SetSize(U(30), U(28))
			frame.NextPage:SetPos(U(56), height - U(84)) frame.NextPage:SetSize(U(30), U(28))
			frame.Refresh:SetPos(U(92), height - U(84)) frame.Refresh:SetSize(U(80), U(28))
			frame.Pages:SetPos(U(180), height - U(84)) frame.Pages:SetSize(width - U(370), U(28))
			frame.Vote:SetPos(width - U(180), height - U(84)) frame.Vote:SetSize(U(160), U(28))
			frame.BackButton:SetPos(U(20), height - U(48)) frame.BackButton:SetSize(U(100), U(32))
			frame.CloseButton:SetPos(width - U(120), height - U(48)) frame.CloseButton:SetSize(U(100), U(32))
		end
		menu.OnRemove = RemoveMenu
	end
 Layout(menu)
	if menu:IsVisible() then return menu end
	menu:SetVisible(true)
	menu.NextStateRefresh = 0
	Populate()
	menu:MakePopup()
	RequestCatalog(false)
	return menu
end

concommand.Add("zs_mapvote", function() GAMEMODE:OpenMapVote() end)
net.Receive("zs_mapvote_open", function() GAMEMODE:OpenMapVote() end)
net.Receive("zs_mapvote_catalog", function()
	local total, offset, size = net.ReadUInt(23), net.ReadUInt(23), net.ReadUInt(15)
	local revision = net.ReadUInt(32)
	if total > 4194304 or offset < 1 or size < 1 or offset + size - 1 > total then return FailTransfer() end
	local data = net.ReadData(size)
	if awaitingFirst and offset ~= 1 then return end
	if offset == 1 then
		transfer = {total = total, offset = 1, chunks = {}, revision = revision}
		awaitingFirst, loadFailure = false, nil
		nextRequest = math.max(nextRequest, RealTime() + 5)
		UpdateRefresh(RealTime())
	end
	if not transfer or transfer.total ~= total or transfer.offset ~= offset or transfer.revision ~= revision or not data or #data ~= size then return FailTransfer() end
	transfer.chunks[#transfer.chunks + 1] = data
	transfer.offset = offset + size
	if transfer.offset <= total then UpdateStatus() return end
	local snapshotRevision = revision
	local unpacked = util.Decompress(table.concat(transfer.chunks), 8388608)
	transfer = nil
	local rows = unpacked and util.JSONToTable(unpacked)
	if type(rows) ~= "table" then return FailTransfer() end
	local nextCatalog, nextCounts, nextVersions, seen = {}, {}, {}, {}
	for _, row in ipairs(rows) do
		if type(row) == "table" and type(row[1]) == "string" and #row[1] <= 64 and string.match(row[1], "^[a-z0-9_%-]+$") and not seen[row[1]] then
			local name = row[1]
			seen[name] = true
			nextCatalog[#nextCatalog + 1] = name
			if not versions[name] or Newer(snapshotRevision, versions[name]) then
				local count = tonumber(row[2]) or 0
				nextCounts[name] = count == count and math.Clamp(math.floor(count), 0, 65535) or 0
				nextVersions[name] = snapshotRevision
			else
				nextCounts[name], nextVersions[name] = counts[name], versions[name]
			end
		end
	end
	catalog, counts, versions = nextCatalog, nextCounts, nextVersions
	cachedSearch, loaded, loadFailure = nil, true, nil
	Populate()
end)
net.Receive("zs_mapvote_count", function()
	local name, count = net.ReadString(), net.ReadUInt(16)
	local revision = net.ReadUInt(32)
	if #name > 64 or not string.match(name, "^[a-z0-9_%-]+$") or versions[name] and not Newer(revision, versions[name]) then return end
	counts[name], versions[name] = count, revision
	if not IsValid(menu) then return end
	if not menu:IsVisible() then menu.CatalogDirty = true return end
	local row = menu.VisibleRows[name]
	if IsValid(row) and row.VoteCount ~= count then row:SetColumnText(2, count) row.VoteCount = count end
end)

net.Receive("zs_mapvote_result", function()
	local accepted, name, reason = net.ReadBool(), net.ReadString(), net.ReadString()
	currentVote = name
	if accepted and reason == "" then nextRequest = math.max(nextRequest, RealTime() + 5) end
	if reason == "mapvote_load_failed" or reason == "mapvote_refresh_wait" or reason == "mapvote_disabled" then
		transfer, awaitingFirst, loadFailure = nil, false, reason
	elseif accepted and reason ~= "" then loadFailure = nil end
	local message = reason == "mapvote_selected" and translate.Format(reason, name) or translate.Get(reason)
	if reason ~= "" then GAMEMODE:CenterNotify(accepted and COLOR_LIMEGREEN or COLOR_RED, message) end
	if IsValid(menu) then
		if reason == "mapvote_disabled" then
			menu.Disabled = true UpdateStatus() menu.Vote:SetEnabled(false)
		else
			if accepted then menu.Disabled = false end
			Populate()
		end
	end
end)
