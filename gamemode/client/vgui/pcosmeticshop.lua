local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local background = Color(15, 20, 26)

local function RefreshActions(frame)
	local balance = GAMEMODE:GetCosmeticBalance(MySelf)
	local team = MySelf:Team()
	local text = (frame.Feedback or "").."\n"..translate.Format(team == TEAM_UNDEAD and "cosmetic_balance_tokens" or "cosmetic_balance_points", math.floor(balance))
	if frame.LastStatus ~= text then frame.Status:SetText(text) frame.LastStatus = text end
	local alive = MySelf:Alive()
	for _, button in ipairs(frame.Buttons) do
		local item = button.Cosmetic
		local owned = frame.Owned[item.ID]
		local equipped = frame.Equipped[item.Category] == item.ID
		local caption = owned and translate.Get(equipped and "cosmetic_unequip" or "cosmetic_equip") or translate.Format("cosmetic_buy", item.Cost)
		if button.LastText ~= caption then button:SetText(caption) button.LastText = caption end
		local enabled = not frame.Pending and alive and (owned or balance >= item.Cost)
		if button.LastEnabled ~= enabled then button:SetEnabled(enabled) button.LastEnabled = enabled end
	end
end

local function RefreshLanguage(frame)
	frame.Title:SetText(translate.Get("mm_cosmetics"))
	frame.Subtitle:SetText(translate.Get("mm_cosmetics_description"))
	frame.Search:SetPlaceholderText(translate.Get("cosmetic_search"))
	frame.Empty:SetText(translate.Get("cosmetic_empty"))
	frame.Previous:SetText(translate.Get("mm_model_previous"))
	frame.NextPage:SetText(translate.Get("mm_model_next"))
	frame.BackButton:SetText(translate.Get("mm_back"))
	frame.CloseButton:SetText(translate.Get("mm_close"))
end

local function Layout(frame)
 GAMEMODE:RefreshMenuScale()
 local width,height=math.min(U(940),ScrW()-32),math.min(U(600),ScrH()-64)
 local screenChanged=frame.ScreenWidth~=ScrW()or frame.ScreenHeight~=ScrH()
 frame.ScreenWidth,frame.ScreenHeight=ScrW(),ScrH()
 if frame.LayoutWidth==width and frame.LayoutHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth,frame.LayoutHeight=width,height
 frame:SetSize(width,height)frame:Center()frame:InvalidateLayout(true)
end
hook.Add("OnScreenSizeChanged","ZSCosmeticMenuLayout",function()local frame=GAMEMODE.ZSCosmeticFrame if IsValid(frame)then Layout(frame)end end)
function GM:OpenCosmeticMenu(owned, equipped, message, show)
 self:RefreshMenuScale()
	self.ZSCosmeticClientState = {owned=owned, equipped=equipped, message=message}
	local frame = self.ZSCosmeticFrame
	if not IsValid(frame) and show == false then return end
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
  frame:SetVisible(false)
		self.ZSCosmeticFrame = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		self:StyleShopFrame(frame)
		frame.Paint = function(panel, width, height)
			draw.RoundedBox(8, 0, 0, width, height, background)
			draw.RoundedBoxEx(U(8), 0, 0, width, U(72), GAMEMODE.ShopColors.header, true, true, false, false)
			surface.SetDrawColor(GAMEMODE.ShopColors.accent)
			surface.DrawRect(0, U(70), width, U(2))
		end
		frame.Title = EasyLabel(frame, translate.Get("mm_cosmetics"), "ZSMenuScaledTitle", color_white)
		frame.Subtitle = EasyLabel(frame, translate.Get("mm_cosmetics_description"), "ZSMenuScaledSmall", self.ShopColors.muted)
		frame.Status = EasyLabel(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
		frame.Status:SetWrap(true)
		frame.Search = vgui.Create("DTextEntry", frame)
		self:StyleShopSearch(frame.Search,true)
		frame.Search:SetPlaceholderText(translate.Get("cosmetic_search"))
		frame.Search.OnChange = function() frame.Page = 1 frame.SearchDue = RealTime() + 0.15 end
		frame.Search.OnEnter = function() frame:RebuildRows() end
		frame.Rows = vgui.Create("DScrollPanel", frame)
		local bar = frame.Rows:GetVBar()
		bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, GAMEMODE.ShopColors.row) end
		for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			button.Paint = function(panel, width, height)
				draw.RoundedBox(4, 2, 0, width - 4, height, panel:IsHovered() and GAMEMODE.ShopColors.accent or GAMEMODE.ShopColors.hover)
			end
		end
		frame.Empty = EasyLabel(frame.Rows:GetCanvas(), translate.Get("cosmetic_empty"), "ZSMenuScaledBody", self.ShopColors.muted)
		frame.Empty:Dock(TOP)
		frame.Empty:SetTall(U(40))
		frame.Empty:SetContentAlignment(5)
		frame.Cards, frame.Buttons, frame.Page = {}, {}, 1
		frame.Previous = vgui.Create("DButton", frame)
		frame.Previous:SetText(translate.Get("mm_model_previous")) self:StyleShopButton(frame.Previous, false, true)
		frame.NextPage = vgui.Create("DButton", frame)
		frame.NextPage:SetText(translate.Get("mm_model_next")) self:StyleShopButton(frame.NextPage, false, true)
		frame.Pages = EasyLabel(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
		frame.Pages:SetContentAlignment(5)
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back")) self:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close")) self:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.SendAction = function(panel, action, id)
			if panel.Pending then return end
			panel.Pending = RealTime() + 3
			RefreshActions(panel)
			GAMEMODE:RequestCosmeticAction(action, id)
		end
		frame.RebuildRows = function(panel)
			panel.SearchDue = nil
			local team = IsValid(MySelf) and MySelf:Team() or 0
			local query = string.Trim(string.lower(panel.Search:GetValue()))
			if panel.Team ~= team or panel.Query ~= query or panel.Catalogue ~= GAMEMODE.Cosmetics or panel.CatalogueCount ~= #GAMEMODE.Cosmetics then
				panel.Team, panel.Query, panel.Catalogue, panel.CatalogueCount = team, query, GAMEMODE.Cosmetics, #GAMEMODE.Cosmetics
				panel.Filtered = {}
				for _, item in ipairs(GAMEMODE.Cosmetics) do
					if item.Team == team and string.find(string.lower(item.Name), query, 1, true) then panel.Filtered[#panel.Filtered+1] = item end
				end
			end
			local filtered = panel.Filtered
			local pages = math.max(1, math.ceil(#filtered / 32))
			panel.Page = math.Clamp(panel.Page, 1, pages)
			local previous, nextpage, empty = panel.Page > 1, panel.Page < pages, #filtered == 0
			if panel.LastPrevious ~= previous then panel.Previous:SetEnabled(previous) panel.LastPrevious = previous end
			if panel.LastNext ~= nextpage then panel.NextPage:SetEnabled(nextpage) panel.LastNext = nextpage end
			local caption = panel.Page.." / "..pages
			if panel.LastPageCaption ~= caption then panel.Pages:SetText(caption) panel.LastPageCaption = caption end
			if panel.LastEmpty ~= empty then panel.Empty:SetVisible(empty) panel.LastEmpty = empty end
			panel.Buttons = {}
			local first, visible = (panel.Page - 1) * 32, math.min(32, #filtered - (panel.Page - 1) * 32)
			for index = 1, visible do
				local item = filtered[first + index]
				local row = panel.Cards[index]
				if not IsValid(row) then
					row = vgui.Create("DPanel", panel.Rows)
					row:Dock(TOP) row:DockMargin(0, 0, 0, U(8)) row:SetTall(U(88))
					row.Paint = function(self, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
					row.Button = vgui.Create("DButton", row)
					GAMEMODE:StyleShopButton(row.Button, true, true)
					row.Button.DoClick = function(button)
						local current = button.Cosmetic
						if current and button:IsEnabled() then panel:SendAction(panel.Owned[current.ID] and 2 or 1, current.ID) end
					end
					row.Title = EasyLabel(row, "", "ZSMenuScaledBody", color_white)
					row.Description = EasyLabel(row, "", "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
					row.Description:SetWrap(true)
					row.Title:SetTooltipPanelOverride("ZSShopTooltip")
					row.Description:SetTooltipPanelOverride("ZSShopTooltip")
					row.PerformLayout = function(card, width)
						card.Button:SetPos(width - U(150), U(12)) card.Button:SetSize(U(138), U(64))
						card.Title:SetPos(U(12), U(10)) card.Title:SetSize(math.max(1, width - U(174)), U(24))
						card.Description:SetPos(U(12), U(36)) card.Description:SetSize(math.max(1, width - U(174)), U(42))
					end
					panel.Cards[index] = row
				end
				row:SetVisible(true)
				row.Button.Cosmetic = item
				if row.LastName ~= item.Name then row.Title:SetText(item.Name) row.Title:SetTooltip(item.Name) row.LastName = item.Name end
				if row.LastDescription ~= item.Description then row.Description:SetText(item.Description) row.Description:SetTooltip(item.Description) row.LastDescription = item.Description end
				panel.Buttons[#panel.Buttons+1] = row.Button
			end
			for index = visible + 1, #panel.Cards do panel.Cards[index]:SetVisible(false) end
			RefreshActions(panel)
		end
		frame.Previous.DoClick = function() frame.Page = frame.Page - 1 frame:RebuildRows() end
		frame.NextPage.DoClick = function() frame.Page = frame.Page + 1 frame:RebuildRows() end
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if not IsValid(MySelf) then panel:Close() return end
			local now = RealTime()
			if panel.SearchDue and now >= panel.SearchDue then panel:RebuildRows() end
			if now < (panel.NextRefresh or 0) then return end
			panel.NextRefresh = now + 0.25
			if panel.Pending and now >= panel.Pending then panel.Pending = nil panel.Feedback = translate.Get("cosmetic_timeout") end
			if panel.Team ~= MySelf:Team() or panel.Catalogue ~= GAMEMODE.Cosmetics or panel.CatalogueCount ~= #GAMEMODE.Cosmetics then panel.Page = 1 panel:RebuildRows() else RefreshActions(panel) end
		end
		frame.PerformLayout = function(panel, width, height)
   panel.Rows:GetVBar():SetWide(U(16))
   for _,card in ipairs(panel.Cards)do card:SetTall(U(88))card:DockMargin(0,0,0,U(8))card:InvalidateLayout(true)end
			panel.Title:SetPos(U(20), U(12)) panel.Title:SetSize(width - U(40),U(32))
			panel.Subtitle:SetPos(U(20), U(44)) panel.Subtitle:SetSize(width - U(40),U(24))
			panel.Status:SetPos(U(20), U(84)) panel.Status:SetSize(width - U(40), U(44))
			panel.Search:SetPos(U(20), U(136)) panel.Search:SetSize(width - U(40), U(28))
			panel.Rows:SetPos(U(20), U(172)) panel.Rows:SetSize(width - U(40), height - U(264))
			panel.Previous:SetPos(U(20), height - U(84)) panel.Previous:SetSize(U(90), U(28))
			panel.NextPage:SetPos(width - U(110), height - U(84)) panel.NextPage:SetSize(U(90), U(28))
			panel.Pages:SetPos(U(116), height - U(84)) panel.Pages:SetSize(width - U(232), U(28))
			panel.BackButton:SetPos(U(20), height - U(48)) panel.BackButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
		end
		frame.OnRemove = function(panel) if GAMEMODE.ZSCosmeticFrame == panel then GAMEMODE.ZSCosmeticFrame = nil end end
	end
	frame.Owned, frame.Equipped, frame.Feedback, frame.Pending = owned, equipped, message, nil
	RefreshLanguage(frame)
	frame.NextRefresh = 0
	if show ~= false then
		Layout(frame)
  if not frame:IsVisible()then frame:SetVisible(true)frame:MakePopup()end
	end
	if frame:IsVisible() then frame:RebuildRows() end
	return frame
end

hook.Add("ZSLanguageChanged", "ZSCosmeticMenuLanguage", function()
	local gm = GAMEMODE
	local frame = gm and gm.ZSCosmeticFrame
	if not IsValid(frame) or not frame:IsVisible() then return end
	gm:RefreshCatalogueTranslations()
	RefreshLanguage(frame)
	frame.Query = nil
	frame:RebuildRows()
end)
