function GM:SendWeaponUnlocks(indices, recipient)
	if recipient and (not IsValid(recipient) or not recipient:IsPlayer() or recipient:IsBot()) then return false end
	if type(indices) ~= "table" or #indices == 0 then return false end
	for position = 1, #indices do
		local index = indices[position]
		if type(index) ~= "number" or index < 1 or index > 65535 or index % 1 ~= 0 or not self.Items[index] then return false end
	end
	for first = 1, #indices, 256 do
		local count = math.min(256, #indices - first + 1)
		net.Start("zs_weapontiers")
		net.WriteUInt(count, 9)
		for index = first, first + count - 1 do net.WriteUInt(indices[index], 16) end
		if recipient then net.Send(recipient) else net.Broadcast() end
	end
	return true
end

function GM:SyncWeaponUnlocks(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return false end
	local indices
	for index, item in ipairs(self.Items) do
		if item.Infliction and item.Unlocked then
			indices = indices or {}
			indices[#indices + 1] = index
		end
	end
	return indices and self:SendWeaponUnlocks(indices, pl) or false
end

local function Grant(pl, item)
	if item.Callback then return item.Callback(pl) ~= false end
	local class = item.SWEP
	if type(class) ~= "string" or not weapons.GetStored(class) then return false end
	if pl:HasWeapon(class) then
		local stored = weapons.GetStored(class)
		if stored.AmmoIfHas then pl:GiveAmmo(stored.Primary.DefaultClip, stored.Primary.Ammo); return true end
		local dropped = ents.Create("prop_weapon")
		if not IsValid(dropped) then return false end
		local ok, failure = pcall(function()
			dropped:SetPos(pl:GetShootPos()); dropped:SetAngles(pl:GetAngles())
			dropped:SetWeaponType(class); dropped:SetShouldRemoveAmmo(true); dropped:Spawn()
		end)
		if not ok or not IsValid(dropped) then if IsValid(dropped) then dropped:Remove() end; if not ok then error(failure) end; return false end
		return true
	end
	local weapon = pl:Give(class)
	if not IsValid(weapon) then return false end
	if weapon.EmptyWhenPurchased and IsValid(weapon:GetOwner()) then
		if weapon.Primary then
			local ammo = weapon:ValidPrimaryAmmo()
			if ammo then pl:RemoveAmmo(math.max(0, weapon.Primary.DefaultClip - weapon.Primary.ClipSize), ammo) end
		end
		if weapon.Secondary then
			local ammo = weapon:ValidSecondaryAmmo()
			if ammo then pl:RemoveAmmo(math.max(0, weapon.Secondary.DefaultClip - weapon.Secondary.ClipSize), ammo) end
		end
	end
	return true
end

local function Commission(pl, owner, crate, price)
	if not IsValid(owner) or owner == pl or owner:Team() ~= TEAM_HUMAN or GAMEMODE:GetArsenalOwner(crate) ~= owner then return end
	local hundredths = price * 7 + math.floor((owner.CarryOverCommision or 0) * 100 + 0.5)
	local whole = math.floor(hundredths / 100)
	owner.CarryOverCommision = (hundredths % 100) / 100
	owner.PointsCommission = (owner.PointsCommission or 0) + price
	if whole <= 0 then return end
	owner:AddPoints(whole)
	if not owner:IsBot() then
		net.Start("zs_commission"); net.WriteEntity(crate); net.WriteEntity(pl); net.WriteUInt(math.min(whole, 65535), 16); net.Send(owner)
	end
end

function GM:PurchaseArsenalItem(pl, signature)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() or pl:Team() ~= TEAM_HUMAN or not pl:Alive() then return false, "cant_purchase_right_now" end
	if pl.ZSArsenalBusy then return false, "cant_purchase_right_now" end
	if type(signature) ~= "string" or #signature == 0 or #signature > 64 then return false, "cant_purchase_right_now" end
	local now = CurTime()
	if now < (pl.ZSNextArsenalBuy or 0) then return false, "cant_purchase_right_now" end
	pl.ZSNextArsenalBuy = now + 0.1
	if pl:GetUnlucky() then return false, "banned_for_life_warning" end
	local crate = self:GetNearbyArsenalCrate(pl)
	if not crate then return false, "need_to_be_near_arsenal_crate" end
	if not gamemode.Call("PlayerCanPurchase", pl, crate) then return false, "cant_purchase_right_now" end
	local item = FindItem(signature)
	if not item or not item.PointShop or not (item.Callback or item.SWEP) then return false, "cant_purchase_right_now" end
	if item.NoClassicMode and self:IsClassicMode() then return false, "cant_use_x_in_classic", item.Name end
	if item.NoZombieEscape and self.ZombieEscape then return false, "cant_use_x_in_zombie_escape", item.Name end
	if item.NoodleArm then return false, "cant_use_x_noodlearm", item.Name end
	if not self:IsWeaponUnlocked(item) then return false, "not_unlocked_yet_unlocked_on_x", self.ObjectiveMap and 2 or math.floor((item.Wave or 0) * self:GetNumberOfWaves()) end
	if item.CanPurchase then
		local ok, allowed = pcall(item.CanPurchase, pl)
		if not ok or not allowed then return false, item.CantPurchaseMessage or "cant_purchase_right_now" end
	end
	local price, owner = self:GetArsenalPrice(pl, item, crate)
	local points = pl:GetPoints()
	if not price or type(points) ~= "number" or points ~= points or points == math.huge or points < price then return false, "dont_have_enough_points" end
	pl.ZSArsenalBusy = true; pl:TakePoints(price)
	local ok, granted = pcall(Grant, pl, item)
	pl.ZSArsenalBusy = nil
	if not ok or not granted then
		if IsValid(pl) then pl:AddPoints(price) end
		if not ok then ErrorNoHalt("ZS arsenal purchase: " .. tostring(granted) .. "\n") end
		return false, "cant_purchase_right_now"
	end
	Commission(pl, owner, crate, price)
	if not pl:IsBot() then
		pl:PrintTranslatedMessage(HUD_PRINTTALK, "purchased_x_for_y_points", item.Name, price)
		pl:SendLua("surface.PlaySound(\"ambient/levels/labs/coinslot1.wav\")")
	end
	return true, price
end

concommand.Add("zs_pointsshopbuy", function(sender, _, arguments)
	if not IsValid(sender) or not sender:IsPlayer() or type(arguments) ~= "table" or #arguments ~= 1 then return end
	if GAMEMODE:IsTraderOnlyRound() then
		local ok, message = GAMEMODE:PurchaseTraderItem(sender, GAMEMODE:GetNearbyTrader(sender), arguments[1])
		if not sender:IsBot() then sender:CenterNotify(ok and COLOR_GREEN or COLOR_RED, message) end
		return
	end
	local ok, reason, detail = GAMEMODE:PurchaseArsenalItem(sender, arguments[1])
	if not ok and not sender:IsBot() then
		sender:CenterNotify(COLOR_RED, detail and translate.ClientFormat(sender, reason, detail) or translate.ClientGet(sender, reason))
	end
end)

function GM:SellArsenalItem(pl, signature)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() or pl:Team() ~= TEAM_HUMAN or not pl:Alive() or pl.ZSArsenalBusy then return false, "cant_purchase_right_now" end
	if type(signature) ~= "string" or #signature == 0 or #signature > 64 then return false end
	local now = CurTime()
	if now < (pl.ZSNextArsenalSell or 0) then return false end
	pl.ZSNextArsenalSell = now + 0.1
	if pl:GetUnlucky() then return false, "banned_for_life_warning" end
	if not pl:NearArsenalCrate() then return false, "need_to_be_near_arsenal_crate" end
	local item = FindItem(signature)
	if not item or not item.PointShop or type(item.SWEP) ~= "string" or not self.SellableCategories[item.Category] then return false end
	local worth, points = item.Worth, pl:GetPoints()
	if type(worth) ~= "number" or worth ~= worth or worth < 0 or worth == math.huge or type(points) ~= "number" or points ~= points or points == math.huge or points == -math.huge then return false end
	if not pl:HasWeapon(item.SWEP) then return false, "dont_have_weapon_x", item.Name end
	local refund = math.floor(worth / 4)
	pl.ZSArsenalBusy = true
	local ok, failure = pcall(pl.StripWeapon, pl, item.SWEP)
	pl.ZSArsenalBusy = nil
	if not ok then ErrorNoHalt("ZS arsenal sale: " .. tostring(failure) .. "\n") return false, "cant_purchase_right_now" end
	if not IsValid(pl) or pl:HasWeapon(item.SWEP) then return false, "cant_purchase_right_now" end
	pl:AddPoints(refund)
	if not pl:IsBot() then
		pl:PrintTranslatedMessage(HUD_PRINTTALK, "sold_x_for_y_points", item.Name, refund)
		pl:SendLua("surface.PlaySound(\"ambient/levels/labs/coinslot1.wav\")")
	end
	return true, refund
end

concommand.Add("zs_pointsshopsell", function(sender, _, arguments)
	if not IsValid(sender) or not sender:IsPlayer() or type(arguments) ~= "table" or #arguments ~= 1 then return end
	local ok, reason, detail = GAMEMODE:SellArsenalItem(sender, arguments[1])
	if not ok and reason and not sender:IsBot() then
		sender:CenterNotify(COLOR_RED, detail and translate.ClientFormat(sender, reason, detail) or translate.ClientGet(sender, reason))
		sender:SendLua("surface.PlaySound(\"buttons/button10.wav\")")
	end
end)
