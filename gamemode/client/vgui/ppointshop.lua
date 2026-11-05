local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if GM and IsValid(GM.m_PointsShop)then GM.m_PointsShop:Remove();GM.m_PointsShop=nil end
local pointFields = {"Signature", "Category", "PointShop", "Worth", "Name", "Description", "Model", "SWEP", "ClientCanPurchase", "CantPurchaseMessage"}
local function PointVisuals(item)
	local weapon = weapons.GetStored(item.SWEP) or item
	return item.Model or weapon.WorldModel, weapon.Primary and weapon.Primary.Ammo
end

local function PointCatalogue(gm)
	local state = {Source = gm.Items, Items = {}, Categories = {}}
	for index, item in ipairs(gm.Items) do
		if item.PointShop then
			local record = {Item = item, Countables = item.Countables}
			for _, field in ipairs(pointFields) do record[field] = item[field] end
			record.VisualModel, record.Ammo = PointVisuals(item)
			if type(item.Countables) == "table" then
				record.CountableValues = {}
				for key, value in pairs(item.Countables) do record.CountableValues[key] = value end
			end
			state.Items[index] = record
		else state.Items[index] = false end
	end
	for index, name in ipairs(gm.ItemCategories) do state.Categories[index] = {name, gm.ItemCategoryIcons[index], gm.SellableCategories[index]} end
	return state
end

local function PointCatalogueChanged(frame)
	local gm, state = GAMEMODE, frame.m_PointCatalogue
	if not state or state.Source ~= gm.Items or #state.Items ~= #gm.Items or #state.Categories ~= #gm.ItemCategories then return true end
	for index, item in ipairs(gm.Items) do
		local record = state.Items[index]
		if not not item.PointShop ~= not not record then return true end
		if record then
			if record.Item ~= item or record.Countables ~= item.Countables then return true end
			for _, field in ipairs(pointFields) do if record[field] ~= item[field] then return true end end
			local model, ammo = PointVisuals(item)
			if record.VisualModel ~= model or record.Ammo ~= ammo then return true end
			if record.CountableValues then
				for key, value in pairs(record.CountableValues) do if item.Countables[key] ~= value then return true end end
				for key, value in pairs(item.Countables) do if record.CountableValues[key] ~= value then return true end end
			end
		end
	end
	for index, name in ipairs(gm.ItemCategories) do
		local record = state.Categories[index]
		if record[1] ~= name or record[2] ~= gm.ItemCategoryIcons[index] or record[3] ~= gm.SellableCategories[index] then return true end
	end
	return false
end

local function CanUsePointsShop()
	return IsValid(MySelf) and MySelf:Alive() and MySelf:Team() == TEAM_HUMAN
end

local function pointslabelThink(self)
	local shop = self.m_ShopFrame
	if not IsValid(shop) or not shop:IsVisible() then return end
	local points = shop.m_PointsBalance
	if points == nil then return end
	if self.m_LastPoints ~= points then
		self.m_LastPoints = points

		self:SetText(translate.Format("pts_tospend", points))
		self:SizeToContents()
	end
end

hook.Add("Think", "PointsShopThink", function()
	local pan = GAMEMODE.m_PointsShop
	if pan and pan:Valid() and pan:IsVisible() then
		if not CanUsePointsShop() then pan:Close() return end
		local now = CurTime()
		if now >= (pan.m_NextPriceUpdate or 0) then
			pan.m_NextPriceUpdate = now + 0.25
			local crate = GAMEMODE:GetNearbyArsenalCrate(MySelf)
			local scale = GAMEMODE:GetArsenalPriceScale(MySelf, crate)
			pan.m_ArsenalPriceScale = scale or 1
			pan.m_Demolitionist = GAMEMODE:HasPlayerTrait(MySelf, "demolitionist")
			pan.m_PointsBalance = MySelf:GetPoints()
			pan.m_ClassicMode = GAMEMODE:IsClassicMode()
			pan.m_ZombieEscape = GAMEMODE.ZombieEscape
			pan.m_PriceRevision = (pan.m_PriceRevision or 0) + 1
			local discount = math.max(0, math.floor((1 - pan.m_ArsenalPriceScale) * 100 + 0.5))
			if discount ~= pan.m_LastDiscount then
				pan.m_LastDiscount = discount
				pan.m_DiscountLabel:SetText(discount > 0 and translate.Format("ars_discount", discount) or translate.Get("all_sales"))
				pan.m_DiscountLabel:SetTextColor(discount > 0 and COLOR_GREEN or COLOR_GRAY)
				pan.m_DiscountLabel:SizeToContents(); pan.m_DiscountLabel:AlignRight(U(8))
			end
		end
		if not GAMEMODE:GetWaveActive() and GAMEMODE:GetWaveStart() - now < 10 then
			pan.m_SaleFlashAlpha = math.floor(math.min(255, math.sin(RealTime() * 8) * 200 + 255))
		else
			pan.m_SaleFlashAlpha = 255
		end
	end
end)

local function PointsShopCenterMouse(self)
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	gui.SetMousePos(x + w * 0.5, y + h * 0.5)
end

local ammonames = {
	["pistol"] = "pistolammo",
	["buckshot"] = "shotgunammo",
	["smg1"] = "smgammo",
	["ar2"] = "assaultrifleammo",
	["357"] = "rifleammo",
	["XBowBolt"] = "crossbowammo",
	["pulse"] = "pulseammo"
}

local warnedaboutammo = CreateClientConVar("_zs_warnedaboutammo", "0", true, false)
local function PurchaseDoClick(self)
	if not CanUsePointsShop() or not self:IsEnabled() then return end
	if not warnedaboutammo:GetBool() then
		local itemtab = FindItem(self.ID)
		if itemtab and itemtab.SWEP then
			local weptab = weapons.GetStored(itemtab.SWEP)
			if weptab and weptab.EmptyWhenPurchased and weptab.Primary and weptab.Primary.Ammo and ammonames[weptab.Primary.Ammo] then
				RunConsoleCommand("_zs_warnedaboutammo", "1")
				GAMEMODE:ShowShopMessage(translate.Get("arsenal_ammo_warning"), translate.Get("warning"), translate.Get("worth_ok"))
			end
		end
	end

	RunConsoleCommand("zs_pointsshopbuy", self.ID)
end

local function SellDoClick(self)		
	if not CanUsePointsShop() then return end
	RunConsoleCommand("zs_pointsshopsell", self.ID)		
end

local function BuyAmmoDoClick(self)
	if not CanUsePointsShop() then return end
	RunConsoleCommand("zs_pointsshopbuy", "ps_"..self.AmmoType)
end

local function worthmenuDoClick()
	MakepWorth()
	GAMEMODE.m_PointsShop:Close()
end

local function ItemPanelThink(self)
	local shop = self.m_ShopFrame
	if not self:IsVisible() or not shop or not shop:Valid() or not shop:IsVisible() then return end
	if shop.ActivePanel ~= self.m_CategoryPanel then return end
	local revision = shop.m_PriceRevision or 0
	local tiersEnabled = GAMEMODE:WeaponTiersEnabled()
	if self.m_LastPriceRevision ~= revision or self.m_LastTiersEnabled ~= tiersEnabled then
		self.m_LastTiersEnabled = tiersEnabled
		self.m_LastPriceRevision = revision
		local itemtab = FindItem(self.ID)
		if not itemtab then return end
		local clientAllowed = true
		if itemtab.ClientCanPurchase then
			local ok, allowed = pcall(itemtab.ClientCanPurchase, MySelf)
			clientAllowed = ok and not not allowed
		end
		local tier = GAMEMODE:GetWeaponTier(itemtab)
		local tierText = tier and translate.Format("weapon_tier_label", tier)
		self.m_NameLabel:SetText(tierText and tierText .. " · " .. (itemtab.Name or "") or itemtab.Name or "")
		local tooltip = itemtab.Description or ""
		if not clientAllowed then tooltip = tooltip .. "\n" .. translate.Get(itemtab.CantPurchaseMessage or "cant_purchase_right_now") end
		if tierText then tooltip = tierText .. "\n" .. tooltip end
		self:SetTooltip(tooltip)
		local scale = shop.m_ArsenalPriceScale or GAMEMODE:GetArsenalPriceScale(MySelf, nil) or 1
		local price = GAMEMODE:RoundArsenalPrice(itemtab.Worth * scale * GAMEMODE:GetTraitArsenalItemScale(MySelf, itemtab, shop.m_Demolitionist)) or math.huge
		local points = shop.m_PointsBalance or MySelf:GetPoints()
		local newstate = not not (clientAllowed and points >= price and not (itemtab.NoClassicMode and shop.m_ClassicMode) and not (itemtab.NoZombieEscape and shop.m_ZombieEscape) and not itemtab.NoodleArm and gamemode.Call("IsWeaponUnlocked", itemtab))
		if newstate ~= self.m_LastAbleToBuy then
			self.m_LastAbleToBuy = newstate
			self.m_BuyButton:SetEnabled(newstate)
			if newstate then
				self.m_NameLabel:SetTextColor(COLOR_WHITE)
				self.m_NameLabel:InvalidateLayout()
				self.m_BuyButton:SetImage("icon16/accept.png")
			else
				self.m_NameLabel:SetTextColor(COLOR_GRAY)
				self.m_NameLabel:InvalidateLayout()
				self.m_BuyButton:SetImage("icon16/exclamation.png")
			end
			
			self.m_BuyButton:SizeToContents() self.m_BuyButton:SetSize(U(16), U(16))
		end

		if price ~= self.m_LastPrice then
			self.m_LastPrice = price
			local discounted = price < math.ceil(itemtab.Worth)
			self.m_Discounted = discounted
			self.m_SalePriceLabel:SetText(tostring(price)); self.m_SalePriceLabel:SizeToContents()
			self.m_SalePriceLabel:SetPos(self:GetWide() - U(24) - self.m_PriceLabel:GetWide() - self.m_SalePriceLabel:GetWide(), U(4))
			self.m_SalePriceLabel:SetAlpha(255); self.m_PriceStrikethroughLabel:SetAlpha(255)
			self.m_SalePriceLabel:SetVisible(discounted); self.m_PriceStrikethroughLabel:SetVisible(discounted)
		end

	end
	local alpha = self.m_Discounted and shop.m_SaleFlashAlpha or 255
	alpha = alpha or 255
	if self.m_SalePriceLabel:GetAlpha() ~= alpha then
		self.m_SalePriceLabel:SetAlpha(alpha); self.m_PriceStrikethroughLabel:SetAlpha(alpha)
	end
end

local function CreatePointRow(frame)
	local row = vgui.Create("DPanel", frame)
	row:SetTall(U(52)) row:SetTooltipPanelOverride("ZSShopTooltip")
	row.Paint, row.Think, row.m_ShopFrame = GAMEMODE.PaintShopItem, ItemPanelThink, frame
	row.m_NameLabel = EasyLabel(row, "", "ZSMenuScaledBody", COLOR_WHITE)
	row.m_NameLabel:SetPos(U(42), U(16))
	row.m_PriceLabel = EasyLabel(row, "", "ZSMenuScaledSmall", COLOR_GRAY)
	row.m_SalePriceLabel = EasyLabel(row, "", "ZSMenuScaledSmall", COLOR_YELLOW)
	row.m_PriceStrikethroughLabel = EasyLabel(row, "", "ZSMenuScaledSmall", COLOR_YELLOW)
	for _, spec in ipairs({{"m_SellButton", "icon16/information.png", SellDoClick}, {"m_BuyButton", "icon16/lorry_add.png", PurchaseDoClick}, {"m_AmmoButton", "icon16/add.png", BuyAmmoDoClick}}) do
		local button = vgui.Create("DImageButton", row)
		if spec[1] == "m_BuyButton" then button:SetEnabled(false) end
		button:SetTooltipPanelOverride("ZSShopTooltip") button:SetImage(spec[2]) button:SizeToContents() button:SetSize(U(16), U(16))
		button.DoClick = spec[3] row[spec[1]] = button
	end
	row.PerformLayout = function(self, width)
		local price = self.m_PriceLabel
		price:SetPos(width - U(20) - price:GetWide(), U(4))
		self.m_PriceStrikethroughLabel:CopyPos(price)
		self.m_SalePriceLabel:SetPos(width - U(24) - price:GetWide() - self.m_SalePriceLabel:GetWide(), U(4))
		local x = width - U(36)
		for _, button in ipairs({self.m_SellButton, self.m_BuyButton, self.m_AmmoButton}) do
			if button:IsVisible() then button:SetPos(x, U(32)) x = x - U(20) end
		end
		self.m_NameLabel:SetWide(math.max(0, x - U(46))) self.m_NameLabel:SetTall(U(22))
	end
	return row
end

local function BindPointRow(row, entry, list)
	local item, index = entry.Item, entry.Index
	row:SetParent(list) row:SetWide(list:GetWide() - U(20)) row:SetVisible(true)
	row.ID, row.m_CategoryPanel = item.Signature or index, list
	row.m_LastPriceRevision, row.m_LastAbleToBuy, row.m_LastPrice = nil, nil, nil
	row.m_BuyButton:SetEnabled(false)
	row.m_NameLabel:SetText(item.Name or "")
	row:SetTooltip(item.Description or "")
	row.m_PriceLabel:SetText(translate.Format("ars_pts", tostring(item.Worth))) row.m_PriceLabel:SizeToContents()
	row.m_PriceStrikethroughLabel:SetText(string.rep("-", #tostring(item.Worth))) row.m_PriceStrikethroughLabel:SizeToContents()
	row.m_SalePriceLabel:SetVisible(false) row.m_PriceStrikethroughLabel:SetVisible(false)
	local sell = row.m_SellButton
	sell.ID = row.ID sell:SetVisible(not not GAMEMODE.SellableCategories[item.Category])
	sell:SetTooltip("Sell " .. (item.Name or "") .. " for " .. math.floor(item.Worth / 4) .. " points")
	row.m_BuyButton.ID = row.ID row.m_BuyButton:SetTooltip(translate.Get("ars_purchase") .. " " .. (item.Name or ""))
	local model, ammo = PointVisuals(item)
	row.m_AmmoButton.AmmoType = ammonames[ammo]
	row.m_AmmoButton:SetVisible(row.m_AmmoButton.AmmoType ~= nil)
	row.m_AmmoButton:SetTooltip(translate.Get("ars_purchaseammo"))
	if model then
		if not IsValid(row.m_ModelPanel) then
			row.m_ModelPanel = vgui.Create("DModelPanel", row)
			row.m_ModelPanel:SetSize(U(32), U(32)) row.m_ModelPanel:SetPos(U(4), U(4))
		end
		local panel = row.m_ModelPanel
		if row.m_Model ~= model then
			panel:SetModel(model) row.m_Model = model
			if IsValid(panel.Entity) then
				local mins, maxs = panel.Entity:GetRenderBounds()
				panel:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5)) panel:SetLookAt((mins + maxs) / 2)
			end
		end
		panel:SetVisible(IsValid(panel.Entity))
	elseif IsValid(row.m_ModelPanel) then row.m_ModelPanel:SetVisible(false) end
	if item.SWEP or item.Countables then
		if not IsValid(row.m_EquipmentCounter) then row.m_EquipmentCounter = vgui.Create("ItemAmountCounter", row) end
		row.m_EquipmentCounter:SetItemID(index) row.m_EquipmentCounter:SetVisible(true)
	elseif IsValid(row.m_EquipmentCounter) then row.m_EquipmentCounter:SetVisible(false) end
	row:InvalidateLayout() list:AddItem(row)
end

local function RebuildPointRows(frame)
	frame.SearchDue = nil
	local list = frame.ActivePanel
	if not IsValid(list) then return end
	local query = string.lower(string.Trim(string.sub(frame.Search:GetValue(), 1, 512)))
	local matches = {}
	local entries = query ~= "" and frame.Entries or frame.CategoryEntries[list.m_PointCategory]
	for _, entry in ipairs(entries or {}) do
		if query == "" or string.find(entry.SearchText, query, 1, true) then matches[#matches + 1] = entry end
	end
	local pages = math.max(1, math.ceil(#matches / 32))
	frame.Page = math.Clamp(frame.Page or 1, 1, pages)
	frame.MatchCount, frame.PageCount = #matches, pages
	for _, sheet in ipairs(frame.m_CategorySheet.Items) do sheet.Panel.Items = {} end
	for _, row in ipairs(frame.Rows) do row:SetVisible(false) row:SetParent(frame) end
	for index = 1, math.min(32, #matches - (frame.Page - 1) * 32) do
		local row = frame.Rows[index]
		if not IsValid(row) then row = CreatePointRow(frame) frame.Rows[index] = row end
		BindPointRow(row, matches[(frame.Page - 1) * 32 + index], list)
	end
	if frame.Previous:IsEnabled()~=(frame.Page>1)then frame.Previous:SetEnabled(frame.Page>1)end
 if frame.NextPage:IsEnabled()~=(frame.Page<pages)then frame.NextPage:SetEnabled(frame.Page<pages)end
	frame.PageLabel:SetText(frame.Page .. " / " .. pages .. " / " .. #matches)
	frame.Empty:SetParent(list) frame.Empty:SetPos(U(16), U(16)) frame.Empty:MoveToFront()
	if frame.Empty:IsVisible()~=(#matches==0)then frame.Empty:SetVisible(#matches==0)end
	if IsValid(list.VBar) then list.VBar:SetScroll(0) end
	list:InvalidateLayout(true)
end

local closeOnLeave = CreateClientConVar("zs_pointshop_autoclose", "1", true, false)
local leaveDelay = CreateClientConVar("zs_pointshop_close_delay", "0", true, false, "Point shop pointer leave delay in seconds", 0, 2)
local function CloseOnPointerLeave(frame)
 if not closeOnLeave:GetBool() then frame.m_PointerLeaveAt = nil return end
 local x, y = frame:LocalCursorPos()
 local inside = x >= 0 and y >= 0 and x < frame:GetWide() and y < frame:GetTall()
 if not inside then
  local hovered = vgui.GetHoveredPanel()
  while IsValid(hovered) do
   if hovered == frame then inside = true break end
   hovered = hovered:GetParent()
  end
 end
 if inside then frame.m_PointerEntered = true frame.m_PointerLeaveAt = nil return end
 if not frame.m_PointerEntered then return end
 local delay = math.Clamp(leaveDelay:GetFloat(), 0, 2)
 if delay > 0 then
  local now = RealTime()
  if not frame.m_PointerLeaveAt or frame.m_PointerLeaveDelay ~= delay then frame.m_PointerLeaveAt, frame.m_PointerLeaveDelay = now + delay, delay end
  if now < frame.m_PointerLeaveAt then return end
 end
 frame.m_PointerLeaveAt = nil
 frame:Close()
 return true
end

local function PointsShopThink(self)
	if not self:IsVisible() then return end
	if CloseOnPointerLeave(self) then return end
	if not CanUsePointsShop() then self:Close() return end
	if self.SearchDue and RealTime() >= self.SearchDue then self:RebuildRows() end
	local now = CurTime()
	if now >= (self.m_NextLayoutCheck or 0) then
		self.m_NextLayoutCheck = now + 1
		if self.m_LanguageRevision ~= (translate.GetRevision and translate.GetRevision()) or self.m_ScreenWidth ~= ScrW() or self.m_ScreenHeight ~= ScrH() or PointCatalogueChanged(self) then GAMEMODE:OpenPointsShop() return end
	end
	if GAMEMODE:GetWave() ~= self.m_LastWaveWarning and not GAMEMODE:GetWaveActive() and CurTime() >= GAMEMODE:GetWaveStart() - 10 and CurTime() > (self.m_LastWaveWarningTime or 0) + 11 then
		self.m_LastWaveWarning = GAMEMODE:GetWave()
		self.m_LastWaveWarningTime = CurTime()

		surface.PlaySound("ambient/alarms/klaxon1.wav")
		local function PlayWarning(sound)
			if IsValid(self) and self:IsVisible() and CanUsePointsShop() then surface.PlaySound(sound) end
		end
		timer.Simple(0.6, function() PlayWarning("ambient/alarms/klaxon1.wav") end)
		timer.Simple(1.2, function() PlayWarning("ambient/alarms/klaxon1.wav") end)
		timer.Simple(2, function() PlayWarning("vo/npc/Barney/ba_hurryup.wav") end)
	end
end

function GM:OpenPointsShop()
	if self.RefreshMenuScale then self:RefreshMenuScale() end
	if not CanUsePointsShop() then
		if IsValid(self.m_PointsShop) then self.m_PointsShop:Close() end
		return
	end
	local navigation, warning, warningTime
	if self.m_PointsShop and self.m_PointsShop:Valid() then
		local old = self.m_PointsShop
		if old.m_LanguageRevision == (translate.GetRevision and translate.GetRevision()) and old.m_ScreenWidth == ScrW() and old.m_ScreenHeight == ScrH() and not PointCatalogueChanged(old) then
			if old:IsVisible()then return old end
   old.m_PointerEntered=nil;old.m_PointerLeaveAt=nil;old:SetVisible(true);old:MakePopup();old:CenterMouse();old.m_NextPriceUpdate=0
			return old
		end
		local active = old.m_CategorySheet:GetActiveTab()
		local panel = IsValid(active) and active:GetPanel()
		if IsValid(panel) then navigation = {Category = panel.m_PointCategory, Scroll = IsValid(panel.VBar) and panel.VBar:GetScroll() or 0, Query = old.Search:GetValue(), Page = old.Page} end
		warning, warningTime = old.m_LastWaveWarning, old.m_LastWaveWarningTime
		old:Remove()
	end

	local wid, hei = math.min(ScrW() - U(32), U(900)), ScrH() * 0.82
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(wid, hei)
 self:StyleShopFrame(frame)
 local colors,background=self.ShopColors,Color(15,20,26)
 frame.Paint=function(_,width,height)
  draw.RoundedBox(U(8),0,0,width,height,background)
  draw.RoundedBox(U(8),0,0,width,U(72),colors.header)
  surface.SetDrawColor(colors.accent);surface.DrawRect(U(16),U(70),width-U(32),2)
 end
	frame:Center()
	frame:SetDeleteOnClose(false)
	frame:SetTitle(" ")
	frame:SetDraggable(false)
	self:CreateScaledMenuCloseButton(frame)
	if frame.btnMinim and frame.btnMinim:Valid() then frame.btnMinim:SetVisible(false) end
	if frame.btnMaxim and frame.btnMaxim:Valid() then frame.btnMaxim:SetVisible(false) end
	frame.CenterMouse = PointsShopCenterMouse
	frame.Think = PointsShopThink
	self.m_PointsShop = frame
	frame.m_LanguageRevision = translate.GetRevision and translate.GetRevision()
	frame.m_PointCatalogue = PointCatalogue(self)
	frame.m_ScreenWidth, frame.m_ScreenHeight = ScrW(), ScrH()
	frame.m_LastWaveWarning, frame.m_LastWaveWarningTime = warning, warningTime
	frame.OnRemove = function(panel) if self.m_PointsShop == panel then self.m_PointsShop = nil end panel.m_PointCatalogue,panel.Rows,panel.Entries,panel.CategoryEntries,panel.ActivePanel=nil,nil,nil,nil,nil end

	local topspace = vgui.Create("DPanel", frame)
	topspace:SetWide(wid - U(16))

	topspace:SetPaintBackground(false)
	local title = EasyLabel(topspace,(translate.Get("the_pointshop")), "ZSMenuScaledTitle", COLOR_WHITE)
	title:AlignLeft(U(40))
	local subtitle = EasyLabel(topspace, (translate.Get("for_allapocalypse")), "ZSMenuScaledSmall", COLOR_GRAY)
	subtitle:AlignLeft(U(40))
	subtitle:MoveBelow(title, U(4))

	local _, y = subtitle:GetPos()
	topspace:SetTall(math.max(U(54), y + subtitle:GetTall() + U(4)))
	topspace:AlignTop(U(16))
	topspace:CenterHorizontal()

	local tt = vgui.Create("DImage", topspace)
	tt:SetImage("gui/info")
	tt:SizeToContents()
	tt:SetPos(U(8), U(8))
	tt:SetMouseInputEnabled(true)
	tt:SetTooltip(translate.Get("ars_tooltip"))
	tt:SetTooltipPanelOverride("ZSShopTooltip")

	local wsb = EasyButton(topspace, translate.Get("ars_worth"), U(8), U(4))
	wsb:AlignRight(U(32))
	wsb:AlignTop(U(8))
	wsb.DoClick = worthmenuDoClick
	GAMEMODE:StyleShopButton(wsb, false, true)
	wsb:SizeToContents() wsb:SetSize(wsb:GetWide() + U(16), wsb:GetTall() + U(8)) wsb:AlignRight(U(32))


	local bottomspace = vgui.Create("DPanel", frame)
	bottomspace:SetWide(topspace:GetWide())
	bottomspace:SetPaintBackground(false)

	local pointslabel = EasyLabel(bottomspace, "Points to spend: 0", "ZSMenuScaledBody", COLOR_GREEN)
	pointslabel:AlignTop(U(4))
	pointslabel:AlignLeft(U(8))
	pointslabel.Think = pointslabelThink
	pointslabel.m_ShopFrame = frame
	frame.m_PointsLabel = pointslabel

	local lab = EasyLabel(bottomspace, " ", "ZSMenuScaledSmall")
	lab:AlignTop(U(4))
	lab:AlignRight(U(4))
	frame.m_DiscountLabel = lab

	local _, y = lab:GetPos()
	bottomspace:SetTall(y + lab:GetTall() + U(34))
	bottomspace:AlignBottom(U(8))
	bottomspace:CenterHorizontal()
	local forge = EasyButton(bottomspace, translate.Get("forge_title"), U(8), U(4))
	forge:SetPos(U(8), y + lab:GetTall() + U(8))
	forge.DoClick = function() frame:Close(); GAMEMODE:OpenWeaponForge() end
	GAMEMODE:StyleShopButton(forge, false, true)
	forge:SizeToContents() forge:SetSize(forge:GetWide() + U(16), forge:GetTall() + U(8))


	local _, topy = topspace:GetPos()
	local _, boty = bottomspace:GetPos()
	frame.Rows, frame.Entries, frame.CategoryEntries = {}, {}, {}
	frame.RebuildRows = RebuildPointRows
	frame.Search = vgui.Create("DTextEntry", frame)
	frame.Search:SetSize(wid - U(24), U(30)) frame.Search:SetPos(U(12), topy + topspace:GetTall() + U(4))
	frame.Search:SetPlaceholderText(translate.Get("points_search"))
 self:StyleShopSearch(frame.Search, true)
 frame.Search.OnChange = function() frame.Page = 1 frame.SearchDue = RealTime() + 0.15 end
	frame.Search.OnEnter = function() frame:RebuildRows() end
	local pager = vgui.Create("DPanel", frame)
	pager:SetSize(wid - U(24), U(28)) pager:SetPos(U(12), boty - U(32)) pager:SetPaintBackground(false)
	frame.Previous = vgui.Create("DButton", pager)
	frame.Previous:Dock(LEFT) frame.Previous:SetWide(U(100)) frame.Previous:SetText(translate.Get("mm_model_previous")) self:StyleShopButton(frame.Previous, false, true)
	frame.NextPage = vgui.Create("DButton", pager)
	frame.NextPage:Dock(RIGHT) frame.NextPage:SetWide(U(100)) frame.NextPage:SetText(translate.Get("mm_model_next")) self:StyleShopButton(frame.NextPage, false, true)
	frame.PageLabel = EasyLabel(pager, "", "ZSMenuScaledSmall", COLOR_GRAY)
	frame.PageLabel:Dock(FILL) frame.PageLabel:SetContentAlignment(5)
	frame.Previous.DoClick = function() frame.Page = frame.Page - 1 frame:RebuildRows() end
	frame.NextPage.DoClick = function() frame.Page = frame.Page + 1 frame:RebuildRows() end
	local propertysheet = vgui.Create("DPropertySheet", frame)
	self:ScaleMenuSheet(propertysheet)
	propertysheet:SetSize(wid - U(8), boty - topy - topspace:GetTall() - U(70))
	propertysheet:SetPos(U(4), topy + topspace:GetTall() + U(38)) propertysheet:SetFadeTime(0)
	propertysheet.Paint = function(self, w, h) draw.RoundedBox(U(5),0,0,w,h,background) end
	frame.m_CategorySheet = propertysheet
	frame.Empty = EasyLabel(propertysheet, translate.Get("points_empty"), "ZSMenuScaledBody", COLOR_GRAY)
	frame.Empty:SetPos(U(16), U(40))
	local categories = self:BuildShopCategoryIndex("PointShop")
	for catid, catname in ipairs(self.ItemCategories) do
		local items = categories[catid]
		if items then
			local entries = {}
			for _, index in ipairs(items) do
				local item = self.Items[index]
				local entry = {Item = item, Index = index, SearchText = string.lower((item.Name or "") .. " " .. tostring(item.Signature or index) .. " " .. (item.Description or ""))}
				entries[#entries + 1] = entry frame.Entries[#frame.Entries + 1] = entry
			end
			frame.CategoryEntries[catid] = entries
			local list = vgui.Create("DPanelList", propertysheet)
			list.m_PointCategory = catid list:SetPaintBackground(false) list:EnableVerticalScrollbar(true)
			list:SetWide(propertysheet:GetWide() - U(16)) list:SetSpacing(U(2)) list:SetPadding(U(2))
   local bar=list.VBar
   if IsValid(bar)then
    bar:SetWide(U(12))
    bar.Paint=function(_,width,height)draw.RoundedBox(U(4),0,0,width,height,colors.row)end
    for _,button in ipairs({bar.btnUp,bar.btnDown,bar.btnGrip})do
     if IsValid(button)then button.Paint=function(control,width,height)draw.RoundedBox(U(4),0,0,width,height,control:IsHovered()and colors.hover or colors.muted)end end
    end
   end
   local tab=propertysheet:AddSheet(catname,list,self.ItemCategoryIcons[catid]).Tab
   tab:SetFont("ZSMenuScaledSmall");tab:SetTextColor(color_white)
   tab.Paint=function(control,width,height)
    local active=propertysheet:GetActiveTab()==control
    draw.RoundedBox(U(5),0,0,width,height,active and colors.selected or control:IsHovered()and colors.hover or colors.row)
    if active then surface.SetDrawColor(colors.accent);surface.DrawRect(0,height-2,width,2)end
   end
		end
	end
	propertysheet.OnActiveTabChanged = function(_, _, tab)
		frame.ActivePanel = tab:GetPanel() frame.Page = 1 frame:RebuildRows()
	end
	local active = propertysheet:GetActiveTab()
	frame.ActivePanel = IsValid(active) and active:GetPanel()
	if navigation then frame.Search:SetValue(navigation.Query) frame.Page = navigation.Page end
	frame:RebuildRows()

	if navigation then
		for _, item in ipairs(propertysheet.Items) do
			if item.Panel.m_PointCategory == navigation.Category then
				propertysheet:SetActiveTab(item.Tab)
				frame.Page = navigation.Page frame:RebuildRows()
				local panel = item.Panel
				local layout = panel.PerformLayout
				panel.PerformLayout = function(self, ...)
					layout(self, ...)
					self.PerformLayout = layout
					if IsValid(self.VBar) then self.VBar:SetScroll(navigation.Scroll) end
				end
				panel:InvalidateLayout()
				break
			end
		end
	end
	frame:MakePopup()
	frame:CenterMouse()
	return frame
end
GM.OpenPointShop = GM.OpenPointsShop

hook.Add("OnScreenSizeChanged", "ZSPointsShopScale", function() if IsValid(GAMEMODE.m_PointsShop) and GAMEMODE.m_PointsShop:IsVisible() then GAMEMODE:OpenPointsShop() end end)
