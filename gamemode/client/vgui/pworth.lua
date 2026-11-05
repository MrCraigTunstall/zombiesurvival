local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
hook.Add("SetWave", "CloseWorthOnWave1", function(wave)
	if wave > 0 then
		if pWorth and pWorth:IsValid() then
			pWorth:Close()
		end

		hook.Remove("SetWave", "CloseWorthOnWave1")
	end
end)

local cvarDefaultCart = CreateClientConVar("zs_defaultcart", "", true, false)
if IsValid(pWorth) then pWorth:Remove() pWorth = nil end

local worthFields = {"Signature", "Category", "WorthShop", "Worth", "Name", "Description", "Model", "SWEP", "Countables"}
local function WorthModel(item)
	return item.Model or (item.SWEP and weapons.GetStored(item.SWEP) or item).WorldModel
end

local function KeepModelStill() end

local function WorthState(gm)
	local state = {Maximum = gm.StartingWorth, Trader = gm:IsTraderOnlyRound(), Width = ScrW(), Height = ScrH(), Title = translate.Get("worth_title"), LanguageRevision = translate.GetRevision and translate.GetRevision(), Default = cvarDefaultCart:GetString(), Items = {}, Categories = {}, Carts = {}}
	for index, item in ipairs(gm.Items) do
		local record = {Item = item}
		for _, field in ipairs(worthFields) do record[field] = item[field] end
		if item.WorthShop then record.VisualModel = WorthModel(item) end
		state.Items[index] = record
	end
	for index, name in ipairs(gm.ItemCategories) do state.Categories[index] = {name, gm.ItemCategoryIcons[index]} end
	for index, cart in ipairs(gm.SavedCarts) do
		local record = {cart[1], {}}
		for i, id in ipairs(cart[2]) do record[2][i] = id end
		state.Carts[index] = record
	end
	return state
end

local function WorthStateChanged(frame)
	local gm, state = GAMEMODE, frame.WorthState
	if state and state.LanguageRevision ~= (translate.GetRevision and translate.GetRevision()) then return true end
	if not state or state.Maximum ~= gm.StartingWorth or state.Trader ~= gm:IsTraderOnlyRound() or state.Width ~= ScrW() or state.Height ~= ScrH() or state.Title ~= translate.Get("worth_title") or state.Default ~= cvarDefaultCart:GetString() then return true end
	if #state.Items ~= #gm.Items or #state.Categories ~= #gm.ItemCategories or #state.Carts ~= #gm.SavedCarts then return true end
	for index, item in ipairs(gm.Items) do
		local record = state.Items[index]
		if record.Item ~= item then return true end
		for _, field in ipairs(worthFields) do if record[field] ~= item[field] then return true end end
		if item.WorthShop and record.VisualModel ~= WorthModel(item) then return true end
	end
	for index, name in ipairs(gm.ItemCategories) do
		local record = state.Categories[index]
		if record[1] ~= name or record[2] ~= gm.ItemCategoryIcons[index] then return true end
	end
	for index, cart in ipairs(gm.SavedCarts) do
		local record = state.Carts[index]
		if record[1] ~= cart[1] or #record[2] ~= #cart[2] then return true end
		for i, id in ipairs(cart[2]) do if record[2][i] ~= id then return true end end
	end
	return false
end

local function DefaultDoClick(btn)
	if string.lower(cvarDefaultCart:GetString()) == string.lower(btn.Name) then
		cvarDefaultCart:SetString("")
		surface.PlaySound("buttons/button11.wav")
	else
		cvarDefaultCart:SetString(btn.Name)
		surface.PlaySound("buttons/button14.wav")
	end

	if IsValid(pWorth) and pWorth:IsVisible() then MakepWorth() end
end

local WorthCart
local WorthButtons = {}
local WorthGrant = {serial = 0, status = 0, token = 0, scope = 0}
local RefreshWorthGrant
local function WorthLocked() return WorthGrant.waiting or WorthGrant.status == 2 or WorthGrant.status == 3 end
local function RefreshWorthAvailability(frame)
	if not frame:IsVisible() then return end
	local now = RealTime()
	if now < (frame.NextWorthAvailability or 0) then return end
	frame.NextWorthAvailability = now + 0.25
	local sheet = frame.m_CategorySheet
	local active = IsValid(sheet) and sheet:GetActiveTab()
	local panel = frame.ActivePanel or (IsValid(active) and active:GetPanel())
	if not IsValid(panel) or not panel.m_WorthCategory then return end
	for _, row in ipairs(panel:GetItems()) do
		if IsValid(row) then row:RefreshAvailability() end
	end
end
local function RefreshWorthDisplay()
	if not IsValid(pWorth) or not WorthCart then return end
	local label = pWorth.WorthLab
	if IsValid(label) then
		local remaining = WorthCart.Remaining
		if pWorth.LastWorthRemaining ~= remaining or pWorth.LastWorthMaximum ~= WorthCart.Maximum then
		pWorth.LastWorthRemaining, pWorth.LastWorthMaximum = remaining, WorthCart.Maximum
		label:SetText(translate.Format("worth_worth", remaining))
		label:SetTextColor(remaining <= 0 and COLOR_RED or remaining <= WorthCart.Maximum * 0.25 and COLOR_YELLOW or COLOR_LIMEGREEN)
		label:SizeToContents()
		end
	end
	for id, button in pairs(WorthButtons) do
		if IsValid(button) then button.On = WorthCart:IsSelected(id) end
	end
end
local function ShowWorthUnavailable(reason, detail)
	GAMEMODE:ShowShopMessage(detail and translate.Format(reason, detail) or translate.Get(reason), translate.Get("worth_title"), translate.Get("worth_ok"))
end

local function DispatchWorth(operation, values)
	if operation ~= 3 then WorthGrant.nextPurchase = RealTime() + 0.16 end
	net.Start("zs_worthcheckout")
	net.WriteUInt(operation, 2); net.WriteUInt(WorthGrant.request, 16); net.WriteUInt(WorthGrant.token, 32); net.WriteUInt(WorthGrant.scope, 32)
	if operation == 0 then
		net.WriteUInt(#values, 8)
		for _, id in ipairs(values) do net.WriteString(tostring(id)) end
	end
	net.SendToServer()
	WorthGrant.queued = nil
end

local function RequestWorth(operation, values)
	if WorthGrant.waiting then return end
	if operation ~= 3 and WorthGrant.scope == 0 then RequestWorth(3) return end
	local now = RealTime()
	if operation == 3 and now < (WorthGrant.nextQuery or 0) then return end
	if operation == 3 then WorthGrant.nextQuery = now + 0.2 end
	WorthGrant.serial = WorthGrant.serial % 65535 + 1
	WorthGrant.request, WorthGrant.waiting = WorthGrant.serial, true
	WorthGrant.started = operation ~= 3 and math.max(now, WorthGrant.nextPurchase or 0) or now
	WorthGrant.reason, WorthGrant.detail = "worth_grant_pending", nil
	if WorthGrant.started > now then
		local queued = {request = WorthGrant.request, token = WorthGrant.token, scope = WorthGrant.scope, frame = IsValid(pWorth) and pWorth or nil}
		WorthGrant.queued = queued
		timer.Simple(WorthGrant.started - now, function()
			if WorthGrant.queued ~= queued or WorthGrant.request ~= queued.request or WorthGrant.token ~= queued.token or WorthGrant.scope ~= queued.scope or not WorthGrant.waiting then return end
			if queued.frame and not IsValid(queued.frame) then WorthGrant.queued, WorthGrant.waiting, WorthGrant.request = nil, nil, nil return end
			DispatchWorth(operation, values)
		end)
	else DispatchWorth(operation, values) end
	if RefreshWorthGrant then RefreshWorthGrant() end
end

local function Checkout(tobuy)
	if WorthGrant.waiting or WorthGrant.status == 3 then return end
	if WorthGrant.status == 2 then RequestWorth(1) return end
	if tobuy and #tobuy > 0 then
		local prepared, reason, detail = GAMEMODE:PrepareWorthCheckout(tobuy)
		if not prepared then ShowWorthUnavailable(reason, detail) return end
		gamemode.Call("SuppressArsenalUpgrades", 1)

		RequestWorth(0, prepared)
	else
		surface.PlaySound("buttons/combine_button_locked.wav")
	end
end

local function CheckoutDoClick(self)
	Checkout(WorthCart and WorthCart:Export())
end

local function RandDoClick(self)
	if WorthLocked() then return end
	gamemode.Call("SuppressArsenalUpgrades", 1)

	RequestWorth(2)
end

local function ClearCartDoClick()
	if WorthLocked() then return end
	if WorthCart then WorthCart:Clear() RefreshWorthDisplay() end

	surface.PlaySound("buttons/button11.wav")
end

local function LoadCart(cartid, silent)
	if WorthLocked() then return end
	if GAMEMODE.SavedCarts[cartid] then
		MakepWorth()
		WorthCart:Load(GAMEMODE.SavedCarts[cartid][2])
		RefreshWorthDisplay()
		if not silent then
			surface.PlaySound("buttons/combine_button1.wav")
		end
	end
end

RefreshWorthGrant = function()
	if not IsValid(pWorth) then return end
	local frame = pWorth
	local locked = WorthLocked()
	if IsValid(frame.CheckoutButton) then
		frame.CheckoutButton:SetEnabled(not WorthGrant.waiting and WorthGrant.status ~= 3)
		frame.CheckoutButton:SetText(translate.Get(WorthGrant.status == 2 and "worth_grant_resume" or "worth_checkout"))
	end
	for _, key in ipairs({"RandomButton", "ClearCartButton"}) do if IsValid(frame[key]) then frame[key]:SetEnabled(not locked) end end
	for _, saved in pairs(frame.SavedCartRows or {}) do
		if IsValid(saved.Checkout) then saved.Checkout:SetEnabled(not locked) end
		if IsValid(saved.Load) then saved.Load:SetEnabled(not locked) end
	end
	if IsValid(frame.GrantStatus) then
		local reason, detail = WorthGrant.reason, WorthGrant.detail
		local message = reason and (detail and detail ~= "" and translate.Format(reason, detail) or translate.Get(reason)) or ""
		if frame.GrantStatusText ~= message then frame.GrantStatusText = message; frame.GrantStatus:SetText(message) end
		frame.GrantStatus:SetTextColor((WorthGrant.status == 3 or WorthGrant.status == 4) and COLOR_RED or GAMEMODE.ShopColors.muted)
	end
end

net.Receive("zs_worthreceipt", function(length)
	if length < 107 or length > 68459 then return end
	local request, token, scope, status = net.ReadUInt(16), net.ReadUInt(32), net.ReadUInt(32), net.ReadUInt(3)
	if request ~= WorthGrant.request and (request ~= 0 or WorthGrant.waiting) then return end
	local reason, detail, count = net.ReadString(), net.ReadString(), net.ReadUInt(8)
	if scope == 0 or status > 4 or #reason > 64 or #detail > 160 or count > 128 or status ~= 2 and count ~= 0 or status == 2 and (token == 0 or count == 0) then return end
	local values, expected = {}, 91 + (#reason + #detail + 2) * 8
	for index = 1, count do
		local id = net.ReadString()
		if #id == 0 or #id > 64 then return end
		values[index], expected = id, expected + (#id + 1) * 8
	end
	if length ~= expected then return end
	if request == 0 and (WorthGrant.scope == 0 or scope ~= WorthGrant.scope) then
		if IsValid(pWorth) and pWorth:IsVisible() then RequestWorth(3) end
		return
	end
	WorthGrant.waiting, WorthGrant.status, WorthGrant.token = nil, status, token
	WorthGrant.queued, WorthGrant.scope, WorthGrant.nextPurchase = nil, scope, RealTime() + 0.16
	WorthGrant.reason, WorthGrant.detail = reason ~= "" and reason or nil, detail
	if status == 2 and WorthCart then WorthCart:Load(values) RefreshWorthDisplay() end
	RefreshWorthGrant()
	if status == 1 and IsValid(pWorth) then pWorth:Close() end
end)

hook.Add("SetWave", "ZSWorthGrantReceipt", function(wave)
	if wave == 0 then
		WorthGrant.status, WorthGrant.token, WorthGrant.scope, WorthGrant.request, WorthGrant.waiting, WorthGrant.reason, WorthGrant.queued = 0, 0, 0, nil, nil, nil, nil
		RefreshWorthGrant()
	end
end)

hook.Add("LocalPlayerDied", "ZSWorthGrantReceipt", function()
	WorthGrant.queued, WorthGrant.waiting, WorthGrant.request, WorthGrant.token, WorthGrant.status, WorthGrant.scope = nil, nil, nil, 0, 0, 0
	if IsValid(pWorth) then pWorth:Close() end
end)

local function LoadDoClick(self)
	LoadCart(self.ID)
end

local function SaveCurrentCart(name)
	local ok, index = GAMEMODE:SaveWorthCart(name, WorthCart and WorthCart:Export() or {})
	if not ok then
		Derma_Message(translate.Get(index), translate.Get("worth_savecart"), translate.Get("worth_ok"))
		return
	end
	LoadCart(index, true)
end

local function SaveDoClick(self)
	Derma_StringRequest(translate.Get("worth_savecart").."", translate.Get("worth_entername").."", translate.Get("worth_name").."", 
	function(strTextOut) SaveCurrentCart(strTextOut) end,
	function(strTextOut) end,
	translate.Get("worth_ok").."", translate.Get("worth_cancel").."")
end

local function DeleteDoClick(self)
	local ok, reason = GAMEMODE:DeleteWorthCart(self.ID)
	if ok then
		surface.PlaySound("buttons/button19.wav")
		MakepWorth()
	elseif reason then
		Derma_Message(translate.Get(reason), translate.Get("worth_savecart"), translate.Get("worth_ok"))
	end
end

local function QuickCheckDoClick(self)
	if GAMEMODE.SavedCarts[self.ID] then
		Checkout(GAMEMODE.SavedCarts[self.ID][2])
	end
end

local function NewSavedRow(frame, canvas, index)
	local row = vgui.Create("DPanel", canvas)
	row:SetZPos(index) row:Dock(TOP) row:DockMargin(2, 2, 2, U(4)) row:SetTall(U(48))
	row.Paint = function(_, w, h) draw.RoundedBox(U(4), 0, 0, w, h, GAMEMODE.ShopColors.row) end
	local actions = vgui.Create("DPanel", row)
	actions:Dock(RIGHT) actions:SetWide(U(144)) actions.Paint = function() end
	local buttons = {}
	local definitions = {{"Checkout", "accept", "worth_favbuy", QuickCheckDoClick}, {"Load", "folder_go", "worth_favload", LoadDoClick}, {"Default", "heart", "worth_favdefault", DefaultDoClick}, {"Delete", "bin", "worth_favdelete", DeleteDoClick}}
	for _, definition in ipairs(definitions) do
		local button = vgui.Create("DImageButton", actions)
		button:SetTooltipPanelOverride("ZSShopTooltip") button:SetImage("icon16/" .. definition[2] .. ".png")
		button:SetSize(U(20), U(20)) button:Dock(RIGHT) button:DockMargin(U(7), U(12), U(7), U(12))
		button:SetTooltip(translate.Get(definition[3])) button.DoClick = definition[4]
		buttons[definition[1]] = button
	end
	local heart = vgui.Create("DImage", row)
	heart:SetImage("icon16/heart.png") heart:Dock(LEFT) heart:SetWide(U(16)) heart:DockMargin(U(8), U(16), 0, U(16))
	heart:SetMouseInputEnabled(true) heart:SetTooltipPanelOverride("ZSShopTooltip") heart:SetTooltip(translate.Get("worth_favtooltip"))
	local label = EasyLabel(row, "", "ZSMenuScaledBody", color_white)
	label:Dock(FILL) label:DockMargin(U(10), 0, U(4), 0) label:SetContentAlignment(4)
	label:SetMouseInputEnabled(true) label:SetTooltipPanelOverride("ZSShopTooltip")
	buttons.Panel, buttons.Label, buttons.Heart = row, label, heart
	frame.SavedRowPool[index] = buttons
	return buttons
end

local function RebuildWorthRows(frame)
	frame.SearchDue = nil
	local sheet = frame.m_CategorySheet
	local tab = sheet:GetActiveTab()
	local panel = frame.ActivePanel or (IsValid(tab) and tab:GetPanel())
	if not IsValid(panel) then return end
	local category = panel.m_WorthCategory or 0
	local query = string.Trim(string.lower(frame.Search:GetValue())):sub(1, 512)
	if frame.FilterQuery ~= query or frame.FilterCategory ~= category or not frame.Filtered then
		frame.FilterQuery, frame.FilterCategory, frame.Filtered = query, category, {}
		if category == 0 then
			for index, cart in ipairs(GAMEMODE.SavedCarts) do
				if query == "" or string.find(string.lower(cart[1]), query, 1, true) then frame.Filtered[#frame.Filtered + 1] = index end
			end
		else
			for _, id in ipairs(query ~= "" and frame.AllWorthIDs or frame.CategoryIDs[category]) do
				if query == "" or string.find(frame.SearchText[id], query, 1, true) then frame.Filtered[#frame.Filtered + 1] = id end
			end
		end
	end
	local limit = category == 0 and 16 or 24
	local pages = math.max(1, math.ceil(#frame.Filtered / limit))
	frame.Page = math.Clamp(frame.Page or 1, 1, pages)
	if frame.Previous:IsEnabled() ~= (frame.Page > 1) then frame.Previous:SetEnabled(frame.Page > 1) end
	if frame.NextPage:IsEnabled() ~= (frame.Page < pages) then frame.NextPage:SetEnabled(frame.Page < pages) end
	local caption = frame.Page .. " / " .. pages
	if frame.PageCaption ~= caption then frame.PageCaption = caption frame.PageLabel:SetText(caption) end
	local canvas = panel:GetCanvas()
	if frame.Empty:GetParent() ~= canvas then frame.Empty:SetParent(canvas) end
	if frame.Empty:IsVisible() ~= (#frame.Filtered == 0) then frame.Empty:SetVisible(#frame.Filtered == 0) end
	for id in pairs(WorthButtons) do WorthButtons[id] = nil end
	for id in pairs(frame.SavedCartRows) do frame.SavedCartRows[id] = nil end
	for index in pairs(frame.VisibleWorthRows) do frame.VisibleWorthRows[index] = nil end
	local first = (frame.Page - 1) * limit
	local visible = math.min(limit, #frame.Filtered - first)
	local defaultName = category == 0 and string.lower(cvarDefaultCart:GetString())
	for index = 1, visible do
		local id = frame.Filtered[first + index]
		if category == 0 then
			local saved = frame.SavedRowPool[index] or NewSavedRow(frame, canvas, index)
			if saved.Panel:GetParent() ~= canvas then saved.Panel:SetParent(canvas) end
			local name = GAMEMODE.SavedCarts[id][1]
			if saved.Name ~= name then saved.Name = name saved.Label:SetText(name) saved.Label:SetTooltip(name) end
			for _, key in ipairs({"Load", "Checkout", "Delete", "Default"}) do saved[key].ID = id end
			saved.Default.Name = name
			local isDefault = defaultName == string.lower(name)
			saved.Heart:SetVisible(isDefault)
			saved.Default:SetTooltip(translate.Get(isDefault and "worth_favremove" or "worth_favdefault"))
			saved.Panel:SetVisible(true)
			frame.SavedCartRows[id] = saved
		else
			local row = frame.WorthRowPool[index]
			if not IsValid(row) then
				row = vgui.Create("ZSWorthButton", canvas)
				row:SetZPos(index) row:Dock(TOP) row:DockMargin(2, 2, 2, U(4))
				frame.WorthRowPool[index] = row
			end
			if row:GetParent() ~= canvas then row:SetParent(canvas) end
			row.m_ShopFrame, row.m_CategoryPanel = frame, panel
			if row.ID ~= id then row:SetWorthID(id) end
			row.On = WorthCart:IsSelected(id) row:SetVisible(true)
			WorthButtons[id], frame.VisibleWorthRows[index] = row, row
		end
	end
	for index, row in ipairs(frame.WorthRowPool) do if category == 0 or index > visible then row:SetVisible(false) end end
	for index, saved in ipairs(frame.SavedRowPool) do if category ~= 0 or index > visible then saved.Panel:SetVisible(false) end end
	if IsValid(panel.VBar) then panel.VBar:SetScroll(0) end
	frame.NextWorthAvailability = 0
	RefreshWorthAvailability(frame) RefreshWorthDisplay() RefreshWorthGrant()
end

function MakepWorth()
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local selected, navigation
	if IsValid(pWorth) then
		if not WorthStateChanged(pWorth) then
			if pWorth:IsVisible() then return pWorth end
			pWorth:SetVisible(true) pWorth:Center() pWorth:MakePopup()
			pWorth.NextWorthAvailability = 0 RefreshWorthAvailability(pWorth) RefreshWorthDisplay()
			RequestWorth(3)
			return pWorth
		end
		selected = WorthCart and WorthCart:Export()
		navigation = {Query = pWorth.Search:GetValue(), Category = pWorth.FilterCategory, Page = pWorth.Page}
		pWorth:Remove() pWorth = nil
	end
	WorthCart = GAMEMODE:CreateWorthCart(GAMEMODE.StartingWorth)
	if selected then WorthCart:Load(selected) end
	WorthButtons = {}
	local wid, hei = math.min(ScrW() - U(24), U(1024)), math.min(ScrH() - U(24), U(720))
	local frame = vgui.Create("DFrame") pWorth = frame
	frame.WorthCart, frame.WorthState = WorthCart, WorthState(GAMEMODE)
	frame.SavedCartRows, frame.WorthRowPool, frame.SavedRowPool, frame.VisibleWorthRows = {}, {}, {}, {}
	frame.OnRemove = function(self)
		if WorthGrant.queued and WorthGrant.queued.frame == self then WorthGrant.queued, WorthGrant.waiting, WorthGrant.request = nil, nil, nil end
		self.WorthCart, self.WorthState, self.SavedCartRows, self.WorthRowPool, self.SavedRowPool, self.VisibleWorthRows = nil, nil, nil, nil, nil, nil
		self.CategoryIDs, self.AllWorthIDs, self.SearchText, self.Filtered, self.ActivePanel = nil, nil, nil, nil, nil
		if pWorth == self then pWorth, WorthCart, WorthButtons = nil, nil, {} end
	end
	frame:SetSize(wid, hei) GAMEMODE:StyleShopFrame(frame)
	local colors, background = GAMEMODE.ShopColors, Color(15, 20, 26)
	frame.Paint = function(_, width, height)
		draw.RoundedBox(U(8), 0, 0, width, height, background)
		draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
		surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), 2)
	end
	frame:SetDeleteOnClose(false) frame:SetTitle(" ") frame:SetDraggable(true)
	GAMEMODE:CreateScaledMenuCloseButton(frame, translate.Get("worth_close_hint"))
	if IsValid(frame.btnMinim) then frame.btnMinim:SetVisible(false) end
	if IsValid(frame.btnMaxim) then frame.btnMaxim:SetVisible(false) end
	local header = EasyLabel(frame, translate.Get("worth_title"), "ZSMenuScaledTitle", color_white)
	header:SetPos(U(20), U(16)) header:SetSize(wid - U(180), U(38))
	frame.WorthLab = EasyLabel(frame, "", "ZSMenuScaledBody", GAMEMODE.ShopColors.accent)
	frame.WorthLab:SetPos(wid - U(140), U(24))
	frame.Search = vgui.Create("DTextEntry", frame)
	frame.Search:SetPos(U(12), U(80)) frame.Search:SetSize(wid - U(24), U(30))
	frame.Search:SetPlaceholderText(translate.Get("worth_search"))
	GAMEMODE:StyleShopSearch(frame.Search, true)
	frame.RebuildRows = RebuildWorthRows
	frame.Search.OnChange = function() frame.Page = 1 frame.SearchDue = RealTime() + 0.15 end
	frame.Search.OnEnter = function() frame:RebuildRows() end
	local pager = vgui.Create("DPanel", frame)
	pager:SetPos(U(12), hei - U(164)) pager:SetSize(wid - U(24), U(30)) pager.Paint = function() end
	frame.Previous = vgui.Create("DButton", pager) frame.Previous:Dock(LEFT) frame.Previous:SetWide(U(100))
	frame.Previous:SetText(translate.Get("mm_model_previous")) GAMEMODE:StyleShopButton(frame.Previous, false, true)
	frame.Previous.DoClick = function() frame.Page = frame.Page - 1 frame:RebuildRows() end
	frame.NextPage = vgui.Create("DButton", pager) frame.NextPage:Dock(RIGHT) frame.NextPage:SetWide(U(100))
	frame.NextPage:SetText(translate.Get("mm_model_next")) GAMEMODE:StyleShopButton(frame.NextPage, false, true)
	frame.NextPage.DoClick = function() frame.Page = frame.Page + 1 frame:RebuildRows() end
	frame.PageLabel = EasyLabel(pager, "", "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
	frame.PageLabel:Dock(FILL) frame.PageLabel:SetContentAlignment(5)
	local sheet = vgui.Create("DPropertySheet", frame) frame.m_CategorySheet = sheet
	GAMEMODE:ScaleMenuSheet(sheet)
	sheet:SetFadeTime(0) sheet:StretchToParent(U(12), U(118), U(12), U(174)) sheet.Paint = function() end
	frame.CategoryIDs = GAMEMODE:BuildShopCategoryIndex("WorthShop")
	frame.AllWorthIDs, frame.SearchText = {}, {}
	for _, entry in ipairs(WorthCart.Entries) do
		local id, item = entry.Index, GAMEMODE.Items[entry.Index]
		frame.AllWorthIDs[#frame.AllWorthIDs + 1] = id
		frame.SearchText[id] = string.lower((item.Name or "") .. " " .. tostring(item.Signature or id) .. " " .. (item.Description or ""))
	end
	frame.Empty = EasyLabel(frame, translate.Get("worth_empty"), "ZSMenuScaledBody", GAMEMODE.ShopColors.muted)
	frame.Empty:Dock(TOP) frame.Empty:SetTall(U(40)) frame.Empty:SetContentAlignment(5)
	local tabs = {}
	local function AddCategory(category, name, icon)
		local list = vgui.Create("DScrollPanel", sheet) list.m_WorthCategory = category ~= 0 and category or nil
		list.GetItems = function(self) return frame.FilterCategory == category and frame.VisibleWorthRows or {} end
		local bar = list:GetVBar()
		bar:SetWide(U(12))
		bar.Paint = function(_, width, height) surface.SetDrawColor(colors.row) surface.DrawRect(0, 0, width, height) end
		for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			if IsValid(button) then button.Paint = function(control, width, height) draw.RoundedBox(U(4), 0, 0, width, height, control:IsHovered() and colors.hover or colors.muted) end end
		end
		local tab = sheet:AddSheet(name, list, icon).Tab
		tabs[category] = tab tab:SetFont("ZSMenuScaledSmall") tab:SetTextColor(color_white)
		tab.Paint = function(control, width, height)
			local selected = sheet:GetActiveTab() == control
			draw.RoundedBox(U(5), 0, 0, width, height, selected and colors.selected or control:IsHovered() and colors.hover or colors.row)
			if selected then surface.SetDrawColor(colors.accent) surface.DrawRect(U(4), height - 3, width - U(8), 2) end
		end
	end
	AddCategory(0, translate.Get("worth_favtab"), "icon16/heart.png")
	for category, name in ipairs(GAMEMODE.ItemCategories) do if frame.CategoryIDs[category] then AddCategory(category, name, GAMEMODE.ItemCategoryIcons[category]) end end
	local actions = {{"RandomButton", "worth_random", RandDoClick}, {"ClearCartButton", "worth_clear", ClearCartDoClick}, {"SaveCartButton", "worth_saveload", SaveDoClick}, {"CheckoutButton", "worth_checkout", CheckoutDoClick}}
	local width = math.min(U(168), (wid - U(56)) / 4) local start = (wid - width * 4 - U(24)) * 0.5
	for index, action in ipairs(actions) do
		local button = vgui.Create("DButton", frame) frame[action[1]] = button
		button:SetText(translate.Get(action[2])) button:SetSize(width, U(34)) button:SetPos(start + (index - 1) * (width + U(8)), hei - U(88))
		button.DoClick = action[3] GAMEMODE:StyleShopButton(button, action[1] == "CheckoutButton", true)
		local tooltip = ({worth_random = "worth_randomtooltip", worth_clear = "worth_cleartooltip", worth_saveload = "worth_saveloadtooltip", worth_checkout = "worth_checkouttooltip"})[action[2]]
		button:SetTooltip(translate.Get(tooltip))
	end
	frame.GrantStatus = EasyLabel(frame, "", "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
	frame.GrantStatus:SetPos(U(12), hei - U(128)) frame.GrantStatus:SetSize(wid - U(24), U(34)) frame.GrantStatus:SetWrap(true)
	for index, link in ipairs({{"worth_github", "https://github.com/MrCraigTunstall/zombiesurvival"}, {"worth_forum", "https://voidresonance.com"}, {"worth_steam", "http://steamcommunity.com/groups/voidresonance"}}) do
		local button = vgui.Create("DButton", frame) button:SetText(translate.Get(link[1])) button:SetSize(U(116), U(28))
		button:SetPos(wid * 0.5 - U(182) + (index - 1) * U(124), hei - U(44)) GAMEMODE:StyleShopButton(button, false, true)
		button.DoClick = function() gui.OpenURL(link[2]) end
		button:SetTooltip(translate.Get(link[1] .. "tooltip"))
	end
	sheet.OnActiveTabChanged = function(_, _, tab) frame.ActivePanel = tab:GetPanel() frame.Page = 1 frame:RebuildRows() end
	local active = sheet:GetActiveTab()
	frame.ActivePanel = IsValid(active) and active:GetPanel()
	local initial = navigation and tabs[navigation.Category] or (#GAMEMODE.SavedCarts == 0 and sheet.Items[math.min(2, #sheet.Items)].Tab or tabs[0])
	if initial then sheet:SetActiveTab(initial) end
	if navigation then frame.Search:SetValue(navigation.Query) frame.Page = navigation.Page end
	local nativeThink = frame.Think
	frame.Think = function(self)
		if not self:IsVisible() then return end
		if nativeThink then nativeThink(self) end
		local now = RealTime()
		if WorthGrant.waiting and now - WorthGrant.started >= 4 then
			WorthGrant.waiting, WorthGrant.reason, WorthGrant.detail, WorthGrant.queued = nil, "worth_grant_timeout", nil, nil
			RefreshWorthGrant()
		end
		if now >= (self.NextWorthStateCheck or 0) then
			self.NextWorthStateCheck = now + 1
			if WorthStateChanged(self) then MakepWorth() return end
		end
		if self.SearchDue and now >= self.SearchDue then self:RebuildRows() end
		RefreshWorthAvailability(self)
	end
	frame:Center() frame:MakePopup() frame:RebuildRows() RequestWorth(3)
	return frame
end

local PANEL = {}

function PANEL:Init()
	self:SetText("")
	self:SetTooltipPanelOverride("ZSShopTooltip")
	
	self:DockPadding(U(4), U(4), U(4), U(4))
	self:SetTall(U(56))

	local mdlframe = vgui.Create("DEXRoundedPanel", self)
	self.ModelFrame = mdlframe
	mdlframe:SetWide(self:GetTall())
	mdlframe:DockPadding(U(4), U(4), U(4), U(4))

	self.ModelPanel = vgui.Create("DModelPanel", mdlframe)
	self.ModelPanel.LayoutEntity = KeepModelStill
	self.ModelPanel:Dock(FILL)
	self.ModelPanel:DockPadding(0, 0, 0, 0)
	self.ModelPanel:DockMargin(0, 0, 0, 0)

	self.NameLabel = EasyLabel(self, "", "ZSMenuScaledBody")
	self.NameLabel:SetTextColor(COLOR_WHITE)
	self.NameLabel:SetContentAlignment(4)
	

	self.PriceLabel = EasyLabel(self, "", "ZSMenuScaledSmall")
	self.PriceLabel:SetWide(U(80))
	self.PriceLabel:SetContentAlignment(6)
	--self.PriceLabel:SetFont("ZSHUDFontSmall")

	self.ItemCounter = vgui.Create("ItemAmountCounter", self)

	self:SetWorthID(nil)
end

function PANEL:PerformLayout(width, height)
	local padding, gap, priceWidth = U(6), U(12), U(96)
	local edge = math.max(0, height - padding * 2)
	self.ModelFrame:SetPos(padding, padding)
	self.ModelFrame:SetSize(edge, edge)
	self.PriceLabel:SetPos(math.max(padding, width - padding - priceWidth), padding)
	self.PriceLabel:SetSize(priceWidth, edge)
	local counterWidth = self.ItemCounter:IsVisible() and math.max(U(12), self.ItemCounter:GetWide()) or 0
	self.ItemCounter:SetPos(math.max(padding, width - padding - priceWidth - gap - counterWidth), (height - self.ItemCounter:GetTall()) * 0.5)
	local left = padding + edge + gap
	self.NameLabel:SetPos(left, padding)
	self.NameLabel:SetSize(math.max(0, width - left - padding - priceWidth - gap - counterWidth - gap), edge)
end

function PANEL:SetWorthID(id)
	self.ID = id

	local tab = FindStartingItem(id)

	if not tab then
		self.ItemCounter:SetVisible(false)
		self.ModelPanel:SetVisible(false)
		self.NameLabel:SetText("")
		return
	end

	local mdl = WorthModel(tab)
	if mdl then
		if self.ModelPath ~= mdl or not IsValid(self.ModelPanel.Entity) then
		self.ModelPanel:SetModel(mdl)
		self.ModelPath = mdl
		if IsValid(self.ModelPanel.Entity) then
		local mins, maxs = self.ModelPanel.Entity:GetRenderBounds()
		self.ModelPanel:SetCamPos(mins:Distance(maxs) * Vector(0.50, 0.75, 0.6))
		self.ModelPanel:SetLookAt((mins + maxs) / 2)
		end
		end
		self.ModelPanel:SetVisible(IsValid(self.ModelPanel.Entity))
	else
		self.ModelPanel:SetVisible(false)
	end

	if tab.SWEP or tab.Countables then
		self.ItemCounter:SetItemID(id)
		self.ItemCounter:SetVisible(true)
	else
		self.ItemCounter:SetVisible(false)
	end

	if tab.Worth then
		self.PriceLabel:SetText(translate.Format("worth_worth_cost", tostring(tab.Worth)))
	else
		self.PriceLabel:SetText("")
	end

	self:RefreshAvailability()

	self.NameLabel:SetText(tab.Name or "")
end

function PANEL:RefreshAvailability()
	local item = FindStartingItem(self.ID)
	local reason, detail = GAMEMODE:GetWorthItemUnavailableReason(item)
	local alpha = reason and 120 or 255
	if self.WorthAvailabilityAlpha ~= alpha then
		self.WorthAvailabilityAlpha = alpha
		self:SetAlpha(alpha)
	end
	local description = item and item.Description
	if self.WorthAvailabilityReason ~= reason or self.WorthAvailabilityDetail ~= detail or self.WorthAvailabilityDescription ~= description or not self.WorthAvailabilityInitialized then
		self.WorthAvailabilityInitialized = true
		self.WorthAvailabilityReason, self.WorthAvailabilityDetail, self.WorthAvailabilityDescription = reason, detail, description
		local tooltip = description
		if reason then
			local unavailable = detail and translate.Format(reason, detail) or translate.Get(reason)
			tooltip = description and description ~= "" and unavailable .. "\n\n" .. description or unavailable
		end
		self:SetTooltip(tooltip)
	end
end

function PANEL:Paint(w, h)
	GAMEMODE.PaintShopItem(self, w, h)
end

function PANEL:DoClick(silent, force)
	if not WorthCart or WorthLocked() then return end
	if not force and not WorthCart:IsSelected(self.ID) then
		local reason, detail = GAMEMODE:GetWorthItemUnavailableReason(FindStartingItem(self.ID))
		if reason then if not silent then ShowWorthUnavailable(reason, detail) end return end
	end
	local changed, selected = WorthCart:Toggle(self.ID, force)
	if not changed then
		if not silent then
			surface.PlaySound("buttons/button8.wav")
			local item = FindStartingItem(self.ID)
			if item and WorthCart.Remaining and item.Worth > WorthCart.Remaining then ShowWorthUnavailable("worth_over_budget", math.ceil(item.Worth - WorthCart.Remaining)) end
		end
		return
	end
	self.On = selected
	if not silent then surface.PlaySound(selected and "buttons/button17.wav" or "buttons/button18.wav") end
	RefreshWorthDisplay()
end
vgui.Register("ZSWorthButton", PANEL, "DButton")

hook.Add("OnScreenSizeChanged", "ZSWorthShopScale", function() if IsValid(pWorth) and pWorth:IsVisible() then MakepWorth() end end)
