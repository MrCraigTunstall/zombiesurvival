local actions = {
	function() GAMEMODE:ShowHelp() end,
	function() GAMEMODE:OpenZombieEscapeWeapons() end,
	function() GAMEMODE:OpenPointsShop() end,
	function() MakepWorth() end,
	function() GAMEMODE:OpenClassSelect() end,
	function() MakepWeapons() end,
	function() MakepOptions() end
}

net.Receive("zs_menuaction", function(length)
	if length < 3 then return end
	local action = actions[net.ReadUInt(3)]
	if action then action() end
end)
