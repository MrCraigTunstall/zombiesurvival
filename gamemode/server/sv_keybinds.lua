local actions = {shop = "ShowTeam", class = "ShowSpare1"}
concommand.Add("zs_keyaction", function(pl, _, args)
	if not IsValid(pl) or pl:IsBot() or (pl.ZSNextKeyAction or 0) > CurTime() then return end
	local method = actions[args[1]]
	if not method then return end
	pl.ZSNextKeyAction = CurTime() + 0.2
	GAMEMODE[method](GAMEMODE, pl, true)
end)
