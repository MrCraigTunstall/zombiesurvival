local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local rowColor = Color(29, 37, 46)
local background = Color(15, 20, 26)
local selectedColor = Color(32, 77, 58)
local muted = Color(165, 178, 191)
local accent = Color(95, 220, 145)
local nextCheckout = 0
if IsValid(pMutation) then pMutation:Remove() pMutation = nil end

local function CatalogueChanged(frame)
	if frame.MenuScale ~= (GAMEMODE.MenuScale or 1) then return true end
	if GAMEMODE.RefreshCatalogueTranslations then GAMEMODE:RefreshCatalogueTranslations() end
	local items = GAMEMODE.Mutations
	if frame.LanguageRevision ~= (translate.GetRevision and translate.GetRevision()) then return true end
	if frame.PurchaseLimit ~= GAMEMODE.MaxMutationPurchaseItems or frame.CategoryCount ~= #GAMEMODE.ItemCategories then return true end
	for index, name in ipairs(GAMEMODE.ItemCategories) do
		local old = frame.CatalogueCategories[index]
		if old.Name ~= name or old.Icon ~= GAMEMODE.ItemCategoryIcons[index] then return true end
	end
	if frame.Catalogue ~= items or frame.CatalogueCount ~= #items or frame.MenuTitle ~= translate.Get("mutations_selection") then return true end
	for index, item in ipairs(items) do
		local old = frame.CatalogueRecords[index]
		if old.Item ~= item or old.Signature ~= item.Signature or old.Category ~= item.Category or old.Shop ~= item.MutationShop or old.Worth ~= item.Worth or old.Name ~= item.Name or old.Description ~= item.Description or old.Requires ~= item.Requires then return true end
	end
	return false
end

local function ShowShop(frame)
	local now = RealTime()
	if frame.Pending and now >= frame.Pending then frame.Pending = nil end
	local screenWidth, screenHeight = ScrW(), ScrH()
	if frame.ScreenWidth ~= screenWidth or frame.ScreenHeight ~= screenHeight then
		frame.ScreenWidth, frame.ScreenHeight = screenWidth, screenHeight
		local width, height = math.min(screenWidth - U(24), U(800)), math.min(screenHeight - U(24), U(620))
		if frame.MenuWidth ~= width or frame.MenuHeight ~= height then
			frame.MenuWidth, frame.MenuHeight = width, height
			frame:SetSize(width, height)
		end
		frame:Center()
	end
	if frame:IsVisible() then return end
	frame.NextRefresh = 0
	frame:SetVisible(true)
	frame:MakePopup()
end

local function RefreshCart(frame)
	if not IsValid(frame) then return end
	if not frame:IsVisible() then frame.CartDirty = true return end
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	frame.Eligible = not not gamemode.Call("ZombieCanPurchase", lp)
	if frame.OwnershipDirty or frame.OwnershipSource ~= UsedMutations then
		frame.OwnershipDirty, frame.OwnershipSource, frame.OwnedSignatures = nil, UsedMutations, {}
		for _, signature in ipairs(UsedMutations or {}) do frame.OwnedSignatures[signature] = true end
	end
	frame.CartDirty = nil
	local used, spent, count = frame.OwnedSignatures, 0, 0
	local tokens = lp:GetTokens()
	for _, entry in ipairs(frame.Entries) do
		local item = entry.Item
		entry.Owned = used[item.Signature] or false
		if entry.Owned then frame.Cart[item.Signature] = nil end
		if frame.Cart[item.Signature] then
			if count < GAMEMODE.MaxMutationPurchaseItems and spent + item.Worth <= tokens then spent = spent + item.Worth
			else frame.Cart[item.Signature] = nil end
		end
		entry.Selected = frame.Cart[item.Signature] or false
		if entry.Selected then count = count + 1 end
	end
	for _, entry in ipairs(frame.Entries) do
		if entry.Selected and not GAMEMODE:MutationRequirementMet(entry.Item, used, frame.Cart) then
			frame.Cart[entry.Item.Signature], entry.Selected = nil, false
			spent, count = spent - entry.Item.Worth, count - 1
		end
	end
	frame.Tokens, frame.Remaining = tokens, tokens - spent
	for _, row in ipairs(frame.Rows) do
		local item, entry = row.Item, row.Entry
		if entry then
		if row.PriceWorth ~= item.Worth then row.PriceWorth, row.PriceText = item.Worth, translate.Format("mutationstokens", tostring(item.Worth)) end
		row.Owned, row.Selected = entry.Owned, entry.Selected
		local requirementMet = GAMEMODE:MutationRequirementMet(item, used, frame.Cart)
		local requirementText
		if not row.Owned and not requirementMet then
			local required = item.Requires and FindMutation(item.Requires)
			local name = required and required.Name or tostring(item.Requires)
			if row.RequirementName ~= name then
				row.RequirementName, row.RequirementCaption = name, translate.Format("mutation_requires", name)
			end
			requirementText = row.RequirementCaption
		end
		if row.RequirementText ~= requirementText then row.RequirementText = requirementText row:InvalidateLayout() end
		local enabled = requirementMet and frame.Eligible and not frame.Pending and not row.Owned and (row.Selected or count < GAMEMODE.MaxMutationPurchaseItems and row.Item.Worth <= frame.Remaining)
		if row:IsEnabled() ~= enabled then row:SetEnabled(enabled) end
		end
	end
	if frame.LastRemaining ~= frame.Remaining then
		frame.LastRemaining = frame.Remaining
		frame.WorthLab:SetText(translate.Format("mutationsdamagetokens", tostring(frame.Remaining)))
		frame.WorthLab:SizeToContents()
	end
	local feedback = frame.Pending and translate.Get("mutation_pending")
		or frame.FailureReason and translate.Get(frame.FailureReason)
		or not frame.Eligible and translate.Get("cant_buy_mutations")
		or count > 0 and translate.Format("mutation_cart_summary", count, spent)
		or translate.Get("mutation_choose")
	if frame.FeedbackText ~= feedback then frame.FeedbackText = feedback frame.Feedback:SetText(feedback) end
	frame.CheckoutCooling = RealTime() < nextCheckout
	local enabled = frame.Eligible and not frame.Pending and not frame.CheckoutCooling and count > 0
	if frame.Checkout:IsEnabled() ~= enabled then frame.Checkout:SetEnabled(enabled) end
	local canClear = not frame.Pending and count > 0
	if frame.ClearButton:IsEnabled() ~= canClear then frame.ClearButton:SetEnabled(canClear) end
end

local function RebuildRows(frame)
	frame.SearchDue = nil
	local panel = frame.ActivePanel
	if not IsValid(panel) then
		frame.Page = 1
		frame.Empty:SetVisible(true)
		frame.Previous:SetEnabled(false) frame.NextPage:SetEnabled(false)
		if frame.PageCaption ~= "1 / 1" then frame.PageCaption = "1 / 1" frame.PageLabel:SetText(frame.PageCaption) end
		RefreshCart(frame)
		return
	end
	local query = string.Trim(string.lower(frame.Search:GetValue())):sub(1, 512)
	local category = panel.MutationCategory
	if frame.FilterQuery ~= query or frame.FilterCategory ~= category or not frame.Filtered then
		frame.FilterQuery, frame.FilterCategory, frame.Filtered = query, category, {}
		for _, entry in ipairs(query ~= "" and frame.Entries or frame.CategoryEntries[category]) do
			if query == "" or string.find(entry.SearchText, query, 1, true) then frame.Filtered[#frame.Filtered + 1] = entry end
		end
	end
	local pages = math.max(1, math.ceil(#frame.Filtered / 32))
	frame.Page = math.Clamp(frame.Page or 1, 1, pages)
	frame.Previous:SetEnabled(frame.Page > 1)
	frame.NextPage:SetEnabled(frame.Page < pages)
	local caption = frame.Page .. " / " .. pages
	if frame.PageCaption ~= caption then frame.PageCaption = caption frame.PageLabel:SetText(caption) end
	local canvas = panel:GetCanvas()
	frame.Empty:SetParent(canvas)
	frame.Empty:SetVisible(#frame.Filtered == 0)
	local first = (frame.Page - 1) * 32
	local visible = math.min(32, #frame.Filtered - first)
	for index = 1, visible do
		local entry = frame.Filtered[first + index]
		local row = frame.Rows[index]
		if not IsValid(row) then
			row = vgui.Create("ZSMutationButton", canvas)
			row:SetZPos(index)
			row:Dock(TOP) row:DockMargin(2, 2, 2, U(4))
			row:SetTooltipPanelOverride("ZSShopTooltip")
			frame.Rows[index] = row
		end
		if row:GetParent() ~= canvas then row:SetParent(canvas) end
		row.Item, row.Shop, row.Entry = entry.Item, frame, entry
		row:InvalidateLayout()
		if row.TooltipDescription ~= entry.Item.Description then row.TooltipDescription = entry.Item.Description row:SetTooltip(entry.Item.Description or "") end
		row:SetVisible(true)
	end
	for index = visible + 1, #frame.Rows do
		local row = frame.Rows[index]
		row.Entry, row.Item, row.Selected, row.Owned = nil, nil, false, false
		row:SetVisible(false)
	end
	if IsValid(panel.VBar) then panel.VBar:SetScroll(0) end
	RefreshCart(frame)
end

function MakepMutationShop(used)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local pl = LocalPlayer()
	if not IsValid(pl) or pl:Team() ~= TEAM_UNDEAD then
		if IsValid(pMutation) then pMutation:Close() end
		return
	end
	if type(used) == "table" then
		UsedMutations = used
		if IsValid(pMutation) then pMutation.OwnershipDirty = true end
	end
	local cart, pending, navigation
	if IsValid(pMutation) then
		if not CatalogueChanged(pMutation) then
			ShowShop(pMutation) RefreshCart(pMutation)
			return pMutation
		end
		cart, pending = pMutation.Cart, pMutation.Pending
		navigation = {Query = pMutation.Search:GetValue(), Category = pMutation.FilterCategory, Page = pMutation.Page}
		pMutation:Remove()
	end
	local frame = vgui.Create("DFrame")
	frame:SetVisible(false)
	pMutation = frame
	frame.MenuScale = GAMEMODE.MenuScale or 1
	frame.Cart, frame.Rows, frame.Entries, frame.Pending = cart or {}, {}, {}, pending
	frame.Catalogue, frame.CatalogueCount, frame.CatalogueRecords = GAMEMODE.Mutations, #GAMEMODE.Mutations, {}
	frame.PurchaseLimit, frame.CategoryCount, frame.CatalogueCategories = GAMEMODE.MaxMutationPurchaseItems, #GAMEMODE.ItemCategories, {}
	for index, name in ipairs(GAMEMODE.ItemCategories) do frame.CatalogueCategories[index] = {Name = name, Icon = GAMEMODE.ItemCategoryIcons[index]} end
	frame.MenuTitle = translate.Get("mutations_selection")
	frame.LanguageRevision = translate.GetRevision and translate.GetRevision()
	for index, item in ipairs(GAMEMODE.Mutations) do frame.CatalogueRecords[index] = {Item = item, Signature = item.Signature, Category = item.Category, Shop = item.MutationShop, Worth = item.Worth, Name = item.Name, Description = item.Description, Requires = item.Requires} end
	frame.OwnershipDirty = true
	frame.OnRemove = function(self)
		if pMutation == self then pMutation = nil end
		self.Cart, self.Rows, self.Entries, self.CatalogueRecords, self.OwnedSignatures, self.CatalogueCategories = nil, nil, nil, nil, nil, nil
	end
	frame:SetDeleteOnClose(false)
	frame:SetTitle(" ")
	frame:ShowCloseButton(false)
	frame:DockPadding(U(5), U(24), U(5), U(5))
	frame.CloseButton = vgui.Create("DButton", frame)
	frame.CloseButton:SetText("X") GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
	frame.CloseButton:SetTooltip(translate.Get("close"))
	frame.CloseButton.DoClick = function() frame:Close() end
	local nativeLayout = frame.PerformLayout
	frame.PerformLayout = function(self, width, height)
		if nativeLayout then nativeLayout(self, width, height) end
		self.CloseButton:SetSize(U(30), U(24)) self.CloseButton:SetPos(width - U(38), U(4))
	end
	GAMEMODE:StyleShopFrame(frame)
	frame.Paint = function(_, width, height)
		draw.RoundedBox(U(8), 0, 0, width, height, background)
		draw.RoundedBox(U(8), 0, 0, width, U(84), GAMEMODE.ShopColors.header)
		surface.SetDrawColor(accent) surface.DrawRect(U(16), U(82), width - U(32), 2)
	end
	if IsValid(frame.btnMinim) then frame.btnMinim:SetVisible(false) end
	if IsValid(frame.btnMaxim) then frame.btnMaxim:SetVisible(false) end
	local header = vgui.Create("DPanel", frame)
	header:Dock(TOP)
	header:SetTall(U(60))
	header.Paint = function() end
	frame.TitleLabel = EasyLabel(header, frame.MenuTitle, "ZSMenuScaledTitle", color_white)
	frame.TitleLabel:Dock(TOP) frame.TitleLabel:SetTall(U(30))
	frame.TitleLabel:DockMargin(U(12), 0, U(12), 0)
	frame.TitleLabel:SetContentAlignment(4)
	frame.Feedback = EasyLabel(header, "", "ZSMenuScaledSmall", muted)
	frame.Feedback:Dock(FILL) frame.Feedback:DockMargin(U(12), 0, U(12), U(6)) frame.Feedback:SetContentAlignment(4)
	local footer = vgui.Create("DPanel", frame)
	footer:Dock(BOTTOM)
	footer:SetTall(U(56))
	footer.Paint = function() end
	local checkout = vgui.Create("DButton", footer)
	frame.Checkout = checkout
	checkout:Dock(RIGHT)
	checkout:SetWide(U(150))
	checkout:DockMargin(U(8), U(8), U(8), U(8))
	checkout:SetText(translate.Get("worth_checkout"))
	GAMEMODE:StyleShopButton(checkout, true, true)
	local clear = vgui.Create("DButton", footer)
	frame.ClearButton = clear
	clear:Dock(RIGHT)
	clear:SetWide(U(120))
	clear:DockMargin(U(4), U(8), 0, U(8))
	clear:SetText(translate.Get("worth_clear"))
	GAMEMODE:StyleShopButton(clear, false, true)
	clear.DoClick = function()
		if frame.Pending then return end
		frame.FailureReason = nil frame.Cart = {} RefreshCart(frame)
	end
	frame.WorthLab = EasyLabel(footer, "", "ZSMenuScaledBody", accent)
	frame.WorthLab:Dock(LEFT)
	frame.WorthLab:DockMargin(U(8), U(8), 0, U(8))
	local pager = vgui.Create("DPanel", frame)
	pager:Dock(BOTTOM) pager:SetTall(U(32)) pager.Paint = function() end
	frame.Previous = vgui.Create("DButton", pager)
	frame.Previous:Dock(LEFT) frame.Previous:SetWide(U(100))
	frame.Previous:SetText(translate.Get("mm_model_previous")) GAMEMODE:StyleShopButton(frame.Previous, false, true)
	frame.NextPage = vgui.Create("DButton", pager)
	frame.NextPage:Dock(RIGHT) frame.NextPage:SetWide(U(100))
	frame.NextPage:SetText(translate.Get("mm_model_next")) GAMEMODE:StyleShopButton(frame.NextPage, false, true)
	frame.PageLabel = EasyLabel(pager, "", "ZSMenuScaledSmall", muted)
	frame.PageLabel:Dock(FILL) frame.PageLabel:SetContentAlignment(5)
	frame.Search = vgui.Create("DTextEntry", frame)
	frame.Search:Dock(TOP) frame.Search:SetTall(U(30)) frame.Search:DockMargin(U(8), 0, U(8), U(8))
	frame.Search:SetPlaceholderText(translate.Get("mutation_search"))
	GAMEMODE:StyleShopSearch(frame.Search, true)
	frame.Search.OnChange = function() frame.Page = 1 frame.SearchDue = RealTime() + 0.15 end
	frame.Search.OnEnter = function() frame:RebuildRows() end
	frame.RebuildRows = RebuildRows
	frame.Previous.DoClick = function() frame.Page = frame.Page - 1 frame:RebuildRows() end
	frame.NextPage.DoClick = function() frame.Page = frame.Page + 1 frame:RebuildRows() end
	local sheet = vgui.Create("DPropertySheet", frame)
	frame.Sheet = sheet
	GAMEMODE:ScaleMenuSheet(sheet)
	sheet:SetFadeTime(0)
	sheet:Dock(FILL)
	sheet.Paint = function() end
	local categories = {}
	for _, item in ipairs(GAMEMODE.Mutations) do
		if item.MutationShop then
			categories[item.Category] = categories[item.Category] or {}
			local items = categories[item.Category]
			items[#items + 1] = item
		end
	end
	for catid in ipairs(GAMEMODE.ItemCategories) do
		local items = categories[catid]
		if items then
			local entries = {}
			for _, item in ipairs(items) do
				local entry = {Item = item, SearchText = string.lower((item.Name or "") .. " " .. item.Signature .. " " .. (item.Description or ""))}
				entries[#entries + 1], frame.Entries[#frame.Entries + 1] = entry, entry
			end
			categories[catid] = entries
		end
	end
	frame.CategoryEntries = categories
	frame.Empty = EasyLabel(frame, translate.Get("mutation_empty"), "ZSMenuScaledBody", muted)
	frame.Empty:Dock(TOP) frame.Empty:SetTall(U(40)) frame.Empty:SetContentAlignment(5)
	for catid, catname in ipairs(GAMEMODE.ItemCategories) do
		local items = categories[catid]
		if items then
			local list = vgui.Create("DScrollPanel", sheet)
			list.MutationCategory = catid
			local tab = sheet:AddSheet(catname, list, GAMEMODE.ItemCategoryIcons[catid]).Tab
			GAMEMODE:StyleShopButton(tab, false, true)
			tab.Paint = function(control, width, height)
				draw.RoundedBox(U(5), 0, 0, width, height, control:IsActive() and selectedColor or control:IsHovered() and GAMEMODE.ShopColors.hover or rowColor)
			end
			if IsValid(list.VBar) then
				list.VBar.Paint = function(_, width, height) surface.SetDrawColor(rowColor) surface.DrawRect(0, 0, width, height) end
				for _, button in ipairs({list.VBar.btnUp, list.VBar.btnDown, list.VBar.btnGrip}) do
					if IsValid(button) then
						button.Paint = function(control, width, height)
							draw.RoundedBox(U(4), 0, 0, width, height, control:IsHovered() and GAMEMODE.ShopColors.hover or muted)
						end
					end
				end
			end
		end
	end
	sheet.OnActiveTabChanged = function(_, _, tab)
		frame.ActivePanel = tab:GetPanel() frame.Page = 1 frame:RebuildRows()
	end
	local active = sheet:GetActiveTab()
	frame.ActivePanel = IsValid(active) and active:GetPanel()
	if navigation then
		for _, item in ipairs(sheet.Items) do
			if item.Panel.MutationCategory == navigation.Category then sheet:SetActiveTab(item.Tab) break end
		end
		frame.Search:SetValue(navigation.Query) frame.Page = navigation.Page
	end
	local available = {}
	for _, entry in ipairs(frame.Entries) do available[entry.Item.Signature] = true end
	for signature in pairs(frame.Cart) do if not available[signature] then frame.Cart[signature] = nil end end
	checkout.DoClick = function()
		if not frame:IsVisible() or frame.Pending or RealTime() < nextCheckout then return end
		if CatalogueChanged(frame) then MakepMutationShop() return end
		RefreshCart(frame)
		if not IsValid(LocalPlayer()) or not frame.Eligible then return end
		local purchase = {}
		for _, entry in ipairs(frame.Entries) do
			if entry.Selected then purchase[#purchase + 1] = entry.Item.Signature end
		end
		if #purchase == 0 or #purchase > GAMEMODE.MaxMutationPurchaseItems then return end
		frame.FailureReason = nil
		frame.Pending = RealTime() + 5
		nextCheckout = RealTime() + 0.25
		RefreshCart(frame)
		RunConsoleCommand("zs_mutationshop_click", unpack(purchase))
	end
	local nativeThink = frame.Think
	frame.Think = function(self)
		if not frame:IsVisible() then return end
		if nativeThink then nativeThink(self) end
		local now = RealTime()
		if now >= (frame.NextCatalogueCheck or 0) then
			frame.NextCatalogueCheck = now + 1
			if CatalogueChanged(frame) then MakepMutationShop() return end
		end
		if frame.SearchDue and now >= frame.SearchDue then frame:RebuildRows() end
		if now < (frame.NextRefresh or 0) then return end
		frame.NextRefresh = now + 0.2
		local lp = LocalPlayer()
		if not IsValid(lp) or lp:Team() ~= TEAM_UNDEAD then frame:Close() return end
		if frame.Pending and now >= frame.Pending then
			frame.Pending = nil frame.FailureReason = "mutation_timeout"
			RefreshCart(frame)
		elseif frame.CartDirty or frame.CheckoutCooling and now >= nextCheckout then
			RefreshCart(frame)
		elseif IsValid(lp) and (frame.Tokens ~= lp:GetTokens() or frame.Eligible ~= not not gamemode.Call("ZombieCanPurchase", lp)) then
			RefreshCart(frame)
		end
	end
	ShowShop(frame)
	frame:RebuildRows()
	if not IsValid(frame.ActivePanel) then RefreshCart(frame) end
	return frame
end

local PANEL = {}
function PANEL:Init()
	self:SetText("")
	self:SetTall(U(86))
end
local function WrapRowText(text, width, font)
	local lines, line = {}, ""
	surface.SetFont(font)
	for word in text:gmatch("%S+") do
		local candidate = line == "" and word or line .. " " .. word
		if surface.GetTextSize(candidate) <= width then
			line = candidate
		else
			if line ~= "" then lines[#lines + 1] = line line = "" end
			for character in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
				if line ~= "" and surface.GetTextSize(line .. character) > width then lines[#lines + 1] = line line = "" end
				line = line .. character
			end
		end
	end
	if line ~= "" then lines[#lines + 1] = line end
	return lines
end
function PANEL:PerformLayout(w)
	local item = self.Item
	local name, text, requirement = item and item.Name or "", item and item.Description or "", self.RequirementText or ""
	local width = math.max(1, w - U(24))
	if self.DescriptionText == text and self.DescriptionWidth == width and self.TitleText == name and self.LayoutRequirement == requirement then return end
	self.DescriptionText, self.DescriptionWidth, self.TitleText, self.LayoutRequirement = text, width, name, requirement
	self.TitleLines = WrapRowText(name, math.max(1, width - U(28)), "ZSMenuScaledBody")
	self.DescriptionLines = WrapRowText(text, width, "ZSMenuScaledSmall")
	self.RequirementLines = WrapRowText(requirement, width, "ZSMenuScaledSmall")
	self.DescriptionY = U(14) + math.max(1, #self.TitleLines) * U(20)
	self.RequirementY = self.DescriptionY + #self.DescriptionLines * U(18) + U(4)
	self.PriceY = self.RequirementY + #self.RequirementLines * U(18) + (#self.RequirementLines > 0 and U(4) or 0)
	self:SetTall(math.max(U(68), self.PriceY + U(24)))
end
function PANEL:Paint(w, h)
	local item = self.Item
	if not item then return end
	draw.RoundedBox(U(4), 0, 0, w, h, self.Selected and selectedColor or rowColor)
	local color = self.Owned and muted or self:IsEnabled() and color_white or muted
	for index, text in ipairs(self.TitleLines or {}) do draw.SimpleText(text, "ZSMenuScaledBody", U(12), U(10) + (index - 1) * U(20), color) end
	for index, text in ipairs(self.DescriptionLines or {}) do draw.SimpleText(text, "ZSMenuScaledSmall", U(12), self.DescriptionY + (index - 1) * U(18), muted) end
	for index, text in ipairs(self.RequirementLines or {}) do draw.SimpleText(text, "ZSMenuScaledSmall", U(12), self.RequirementY + (index - 1) * U(18), muted) end
	draw.SimpleText(self.PriceText or "", "ZSMenuScaledSmall", w - U(12), h - U(24), self.Selected and accent or color, TEXT_ALIGN_RIGHT)
	if self.Owned or self.Selected then
		draw.SimpleText("✓", "ZSMenuScaledBody", w - U(12), U(9), accent, TEXT_ALIGN_RIGHT)
	end
end
function PANEL:DoClick()
	local frame = self.Shop
	if not IsValid(frame) or not frame:IsVisible() or frame.Pending or self.Owned or not self.Item then return end
	local lp = LocalPlayer()
	if not IsValid(lp) or not gamemode.Call("ZombieCanPurchase", lp) then return end
	if not GAMEMODE:MutationRequirementMet(self.Item, frame.OwnedSignatures, frame.Cart) then return end
	local signature = self.Item.Signature
	frame.FailureReason = nil
	frame.Cart[signature] = not frame.Cart[signature] or nil
	surface.PlaySound("buttons/button17.wav")
	RefreshCart(frame)
end
vgui.Register("ZSMutationButton", PANEL, "DButton")
hook.Add("OnScreenSizeChanged", "ZSMutationShopLayout", function()
	if IsValid(pMutation) and pMutation:IsVisible() then MakepMutationShop() end
end)
hook.Add("ZSMutationsUpdated", "ZSMutationShopRefresh", function()
	if IsValid(pMutation) then pMutation.OwnershipDirty = true RefreshCart(pMutation) end
end)
net.Receive("zs_mutations_result", function()
	local success = net.ReadBool()
	local reason = net.ReadString()
	nextCheckout = RealTime() + 0.25
	surface.PlaySound(success and "ambient/levels/labs/coinslot1.wav" or "buttons/button10.wav")
	if IsValid(pMutation) then
		pMutation.Pending = nil
		pMutation.FailureReason = not success and (reason ~= "" and reason or "cant_buy_mutations") or nil
		if success then pMutation.Cart = {} pMutation.CartDirty = true pMutation:Close() else RefreshCart(pMutation) end
	end
end)
