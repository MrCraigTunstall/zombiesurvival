local enabled = CreateConVar("zs_trader_variant", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Spawn a ghost trader before and between waves", 0, 1)
util.AddNetworkString("zs_trader_open")
util.AddNetworkString("zs_trader_buy")
util.AddNetworkString("zs_trader_result")
function GM:RemoveTraders()
	for _, ent in ipairs(self:GetZSClassEntities("npc_zs_trader")) do if IsValid(ent) then ent:Remove() end end
end


function GM:SpawnTraderVariant()
	if self.SelectedVariant and self.SelectedVariant ~= "trader" or not enabled:GetBool() or self.ZombieEscape or self.RoundEnded or self:GetWaveActive() then return end
	for _, ent in ipairs(self:GetZSClassEntities("npc_zs_trader")) do if IsValid(ent) then return ent end end
	local pos = self:FindTraderPosition()
	if not pos then return end
	local ent = ents.Create("npc_zs_trader")
	if not IsValid(ent) then return end
	ent:SetPos(pos)
	ent:SetAngles(Angle(0, math.random(0, 359), 0))
	ent:Spawn()
	return IsValid(ent) and ent or nil
end

function GM:OpenTrader(pl, trader)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or trader ~= self:GetNearbyTrader(pl) then return false end
	local now = CurTime()
	if now < (pl.ZSNextTraderOpen or 0) then return false end
	pl.ZSNextTraderOpen = now + 0.5
	net.Start("zs_trader_open")
	net.WriteEntity(trader)
	net.WriteBool(self:GetWave() == 0)
	net.Send(pl)
	return true
end

function GM:PurchaseTraderItem(pl, trader, signature)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self:GetWave() < 1
		or not IsValid(trader) or trader ~= self:GetNearbyTrader(pl) or pl:GetUnlucky() then return false, "Trader unavailable. Move within reach between waves." end
	if pl.ZSTraderBusy then return false, "Finish your current purchase first." end
	local now = CurTime()
	if now < (pl.ZSNextTraderBuy or 0) then return false, "Please wait before buying again." end
	pl.ZSNextTraderBuy = now + 0.25
	local item = type(signature) == "string" and #signature <= 64 and FindItem(signature)
	if not self:IsTraderItem(item) or item.NoClassicMode and self:IsClassicMode() or item.NoodleArm or not self:IsWeaponUnlocked(item) then return false, "This item is unavailable." end
	if item.CanPurchase and not item.CanPurchase(pl) then return false, "This item cannot be purchased right now." end
	local price, points = self:GetTraderPrice(item), pl:GetPoints()
	if price ~= price or price < 0 or price == math.huge then return false, "This item is unavailable." end
	if type(points) ~= "number" or points ~= points or points == math.huge or points < price then return false, "Not enough points." end
	if item.SWEP and (not weapons.GetStored(item.SWEP) or pl:HasWeapon(item.SWEP)) then return false, "You already own this weapon, or it is unavailable." end
	pl.ZSTraderBusy = true
	pl:SetPoints(points - price)
	local ok, granted = pcall(function()
		if item.Callback then return item.Callback(pl) ~= false end
		local weapon = pl:Give(item.SWEP)
		if not IsValid(weapon) then return false end
		if weapon.EmptyWhenPurchased then
			for _, ammo in ipairs({weapon.Primary, weapon.Secondary}) do
				if ammo and ammo.Ammo and ammo.DefaultClip and ammo.ClipSize then pl:RemoveAmmo(math.max(0, ammo.DefaultClip - ammo.ClipSize), ammo.Ammo) end
			end
		end
		return true
	end)
	pl.ZSTraderBusy = nil
	if not ok or not granted then
		pl:SetPoints(pl:GetPoints() + price)
		if not ok then ErrorNoHalt("ZS trader purchase: " .. tostring(granted) .. "\n") end
		return false, "The purchase could not be completed. Your points were refunded."
	end
	return true, "Purchased " .. self:GetTraderItemText(item.Name) .. " for " .. price .. " points."
end

net.Receive("zs_trader_buy", function(len, pl)
	if len > 600 or not IsValid(pl) or pl:IsBot() then return end
	local trader,signature,request=net.ReadEntity(),net.ReadString(),net.ReadUInt(16)
	local now = CurTime()
	if now < (pl.ZSNextTraderRequest or 0) then return end
	pl.ZSNextTraderRequest = now + 0.25
	local ok, message = GAMEMODE:PurchaseTraderItem(pl, trader, signature)
	net.Start("zs_trader_result")
 net.WriteEntity(trader);net.WriteUInt(request,16)
	net.WriteBool(ok)
	net.WriteString(message)
	net.Send(pl)
end)

local function Schedule()
	timer.Create("ZSTraderSpawn", 0.2, 1, function() GAMEMODE:SpawnTraderVariant() end)
end
hook.Add("InitPostEntity", "ZSTrader", Schedule)
hook.Add("PostCleanupMap", "ZSTrader", Schedule)
hook.Add("WaveStateChanged", "ZSTrader", function(active)
	if active then timer.Remove("ZSTraderSpawn"); GAMEMODE:RemoveTraders() else Schedule() end
end)
hook.Add("OnWaveStateChanged", "ZSTrader", function()
	if GAMEMODE:GetWaveActive() or GAMEMODE.RoundEnded then GAMEMODE:RemoveTraders() else Schedule() end
end)
hook.Add("PostEndRound", "ZSTrader", function() timer.Remove("ZSTraderSpawn"); GAMEMODE:RemoveTraders() end)
cvars.AddChangeCallback("zs_trader_variant", function()
	if enabled:GetBool() then Schedule() else timer.Remove("ZSTraderSpawn"); GAMEMODE:RemoveTraders() end
end, "ZSTrader")
