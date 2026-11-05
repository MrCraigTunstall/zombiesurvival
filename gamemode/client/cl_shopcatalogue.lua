function GM:BuildShopCategoryIndex(shop)
	local categories = {}
	local traderOnly = shop == "WorthShop" and self:IsTraderOnlyRound()
	for index, item in ipairs(self.Items) do
		local category = item.Category
		if item[shop] and self.ItemCategories[category] and not (traderOnly and item.SWEP == "weapon_zs_arsenalcrate") then
			local items = categories[category]
			if not items then items = {} categories[category] = items end
			items[#items + 1] = index
		end
	end
	return categories
end

local function PopulateShopTab(tab)
	local build = tab.ZSShopBuilder
	if not build then return end
	build()
	tab.ZSShopBuilder = nil
end

function GM:AddLazyShopSheet(sheet, name, panel, icon, build)
	if not sheet.ZSShopLazy then
		sheet.ZSShopLazy = true
		local changed = sheet.OnActiveTabChanged
		sheet.OnActiveTabChanged = function(self, old, new)
			if changed then changed(self, old, new) end
			PopulateShopTab(new)
		end
	end
	local item = sheet:AddSheet(name, panel, icon, false, false)
	item.Tab.ZSShopBuilder = build
	if sheet:GetActiveTab() == item.Tab then PopulateShopTab(item.Tab) end
	return item
end
