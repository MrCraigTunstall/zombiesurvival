function GM:PurchaseWeaponForge(pl, weapon, expected)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded then return false, "unavailable" end
	if pl.ZSForgeBusy then return false, "busy" end
	local now = CurTime()
	if now < (pl.ZSNextForge or 0) then return false, "cooldown" end
	pl.ZSNextForge = now + 0.5
	if not IsValid(weapon) or weapon:GetOwner() ~= pl or pl:GetActiveWeapon() ~= weapon or not self:IsWeaponForgeEligible(weapon) then return false, "weapon" end
	if not pl:NearArsenalCrate() then return false, "arsenal" end
	if pl:GetBarricadeGhosting() or pl:IsHolding() or weapon.reloading or (weapon.WeaponForgeReload == "heat" and weapon:GetGunState() ~= 0) or weapon:GetNextPrimaryFire() > now or weapon:GetNextReload() > now then return false, "busy" end
	local level = self:GetWeaponForgeLevel(weapon)
	if expected ~= level then return false, "changed" end
	local price = self:GetWeaponForgePrice(level)
	if not price then return false, "maximum" end
	local points = pl:GetPoints()
	if type(points) ~= "number" or points ~= points or points == math.huge or points < price then return false, "points" end
	pl.ZSForgeBusy = true
	local ok, applied = pcall(self.ApplyWeaponForge, self, weapon, level + 1)
	if not ok or not applied then
		pl.ZSForgeBusy = nil
		return false, "failed"
	end
	pl:SetPoints(points - price)
	weapon:SetNWInt("ZSForgeLevel", level + 1)
	pl.ZSForgeBusy = nil
	return true, level + 1
end

concommand.Add("zs_weaponforge", function(pl, command, args)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return end
	local expected = tonumber(args[1])
	if not expected or expected ~= math.floor(expected) or expected < 0 or expected >= GAMEMODE.WeaponForgeMaxLevel then return end
	local weapon = pl:GetActiveWeapon()
	local index = tonumber(args[2])
	if not IsValid(weapon) or not index or index ~= weapon:EntIndex() then return end
	local ok, result = GAMEMODE:PurchaseWeaponForge(pl, weapon, expected)
	if result == "cooldown" then return end
	if ok then
		pl:CenterNotify(COLOR_GREEN, translate.ClientFormat(pl, "forge_tier_upgraded", result))
	else
		local messages = {unavailable = "forge_feedback_unavailable", busy = "forge_feedback_busy", weapon = "forge_feedback_weapon", arsenal = "forge_feedback_arsenal", changed = "forge_feedback_changed", maximum = "forge_feedback_maximum", points = "forge_feedback_points", failed = "forge_feedback_failed"}
		pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, messages[result] or messages.failed))
	end
end)
