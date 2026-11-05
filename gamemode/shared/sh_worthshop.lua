function GM:GetWorthItemUnavailableReason(item)
	if not item then return "cant_use_worth_anymore" end
	if item.NoClassicMode and self:IsClassicMode() then return "cant_use_x_in_classic_mode", item.Name end
	if item.NoZombieEscape and self.ZombieEscape then return "cant_use_x_in_zombie_escape", item.Name end
	if item.RequiresSigils and not self:GetUseSigils() then return "cant_use_x_without_sigils", item.Name end
	if item.NoodleArm then return "cant_use_x_noodlearm", item.Name end
	if self:IsTraderOnlyRound() and item.SWEP == "weapon_zs_arsenalcrate" then return "cant_use_worth_anymore" end
end
