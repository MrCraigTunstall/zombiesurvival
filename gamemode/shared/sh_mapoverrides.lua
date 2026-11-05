function GM:GetMapScriptName(map)
	map=string.lower(map or game.GetMap())
	if string.match(map,"^ze_ffvii_mako_reactor_v5_3_") then return "ze_ffvii_mako_reactor_v5_3" end
	return map
end
