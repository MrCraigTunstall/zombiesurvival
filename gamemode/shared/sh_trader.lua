function GM:GetNearbyTrader(pl)
	if not IsValid(pl) or self.ZombieEscape or self.RoundEnded or self:GetWaveActive() then return end
	local pos = pl:EyePos()
	for _, ent in ipairs(self:GetZSClassEntities("npc_zs_trader")) do
		if IsValid(ent) then
			local nearest = ent:NearestPoint(pos)
			if pos:DistToSqr(nearest) <= 150 * 150 and WorldVisible(pos, nearest) then return ent end
		end
	end
end

function GM:IsTraderOnlyRound()
	return GetGlobalBool("zs_trader_only", false)
end

function GM:IsTraderItem(item)
	return item and item.SWEP ~= "weapon_zs_arsenalcrate" and item.PointShop and item.Category ~= ITEMCAT_TRAITS and item.Category ~= ITEMCAT_RETURNS
		and type(item.Worth) == "number" and item.Worth == item.Worth and item.Worth >= 0 and item.Worth < math.huge
		and (type(item.Callback) == "function" or type(item.SWEP) == "string" and item.SWEP ~= "")
end

function GM:GetTraderPrice(item)
	return math.ceil(item.Worth * self.ArsenalCrateMultiplier)
end

function GM:GetTraderItemText(text)
 if type(text) ~= "string" then return "" end
 local translated = translate.Get(text)
 return translated == "@" .. text .. "@" and text or translated
end
