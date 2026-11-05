local CART = {}

function GM:PrepareWorthCheckout(ids)
	if type(ids) ~= "table" or #ids == 0 or #ids > 128 then return nil, "worth_invalid_loadout" end
	local maximum = self.StartingWorth
	if type(maximum) ~= "number" or maximum ~= maximum or math.abs(maximum) == math.huge or maximum < 0 then return nil, "worth_invalid_loadout" end
	local out, seen, total = {}, {}, 0
	for _, id in ipairs(ids) do
		local item = FindStartingItem(id)
		local reason, detail = self:GetWorthItemUnavailableReason(item)
		if reason then return nil, reason, detail end
		if not item or type(item.Signature) ~= "string" or item.Signature == "" then return nil, "worth_invalid_loadout" end
		local price = item and item.Worth
		if type(price) ~= "number" or price ~= price or math.abs(price) == math.huge or price % 1 ~= 0 then return nil, "worth_invalid_loadout" end
		local key = item.Signature
		if not seen[key] then
			seen[key] = true total = total + price
			out[#out + 1] = item.Signature
		end
	end
	if #out == 0 or total ~= total or math.abs(total) == math.huge then return nil, "worth_invalid_loadout" end
	if total > maximum then return nil, "worth_over_budget", math.ceil(total - maximum) end
	return out, total
end

function CART:IsSelected(id)
	local entry = self.ByID[id]
	return entry and self.Selected[entry.Index] ~= nil or false
end

function CART:Toggle(id, force)
	local entry = self.ByID[id]
	if not entry then return false end
	local paid = self.Selected[entry.Index]
	if paid ~= nil then
		self.Selected[entry.Index] = nil
		self.Remaining = self.Remaining + paid
		return true, false
	end
	if not force and self.Remaining < entry.Price then return false end
	self.Selected[entry.Index] = entry.Price
	self.Remaining = self.Remaining - entry.Price
	return true, true
end

function CART:Clear()
	self.Selected = {}
	self.Remaining = self.Maximum
end

function CART:Load(ids)
	self:Clear()
	for _, id in pairs(ids or {}) do
		if not self:IsSelected(id) then self:Toggle(id, true) end
	end
end

function CART:Export()
	local ids = {}
	for _, entry in ipairs(self.Entries) do
		if self.Selected[entry.Index] ~= nil then ids[#ids + 1] = entry.ID end
	end
	return ids
end

function GM:CreateWorthCart(maximum)
	local cart = setmetatable({Maximum = maximum, Remaining = maximum, Entries = {}, ByID = {}, Selected = {}}, {__index = CART})
	local traderOnly = self:IsTraderOnlyRound()
	for index, item in ipairs(self.Items) do
		if item.WorthShop and self.ItemCategories[item.Category] and not (traderOnly and item.SWEP == "weapon_zs_arsenalcrate") then
			local entry = {Index = index, ID = item.Signature or index, Price = item.Worth or 0}
			cart.Entries[#cart.Entries + 1] = entry
			cart.ByID[index], cart.ByID[tostring(index)] = entry, entry
			if item.Signature then cart.ByID[item.Signature] = entry end
		end
	end
	return cart
end
