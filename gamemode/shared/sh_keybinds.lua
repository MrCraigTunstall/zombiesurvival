GM.ZSKeyActions = {
	{id = "help", label = "keys_help", command = "gm_showhelp", default = 0},
	{id = "shop", label = "keys_shop", command = "gm_showteam", default = 0},
	{id = "class", label = "keys_class", command = "gm_showspare1", default = 0},
	{id = "options", label = "keys_options", command = "gm_showspare2", default = 0},
	{id = "thirdperson", label = "keys_thirdperson", command = "+menu_context", default = 0},
	{id = "vision", label = "keys_vision", command = "impulse 100", default = 0},
	{id = "zoom", label = "keys_zoom", command = "gmod_undo", default = 0},
	{id = "mapvote", label = "keys_mapvote", default = -1},
	{id = "dropweapon", label = "keys_dropweapon", default = -1, clientOnly = true, legacy = "zs_dropweapon"},
	{id = "dropammo", label = "keys_dropammo", default = -1, clientOnly = true, legacy = "zs_dropammo"},
	{id = "quickbuy", label = "keys_quickbuy", default = -1, clientOnly = true, legacy = "zs_quickbuy"},
	{id = "altmenu", label = "keys_altmenu", default = -1, clientOnly = true, legacy = "zs_altmenu"},
	{id = "taunt", label = "keys_taunt", default = -1, clientOnly = true, legacy = "zs_taunt"},
	{id = "suicide", label = "keys_suicide", default = -1, clientOnly = true, legacy = "zs_suicide"},
	{id = "weapons", label = "keys_weapons", default = -1, clientOnly = true, legacy = "zs_weapondatabase"},
	{id = "keys", label = "keys_keys", default = -1, clientOnly = true, legacy = "zs_keybinds"},
	{id = "camera_cycle", label = "keys_camera_cycle", default = -1, clientOnly = true, legacy = "zs_thirdperson_rotate"}
}
for mode = 1, 8 do
	GM.ZSKeyActions[#GM.ZSKeyActions + 1] = {id = "camera_" .. mode, label = "keys_camera_" .. mode, default = -1, clientOnly = true, legacy = "zs_thirdperson_view_" .. mode, camera = mode}
end
GM.ZSKeyActionByID = {}
GM.ZSKeyCommandActions = {}
for _, action in ipairs(GM.ZSKeyActions) do
	GM.ZSKeyActionByID[action.id] = action
	if action.command then GM.ZSKeyCommandActions[action.command] = action.id end
end

function GM:ValidateKeyProfileName(name)
	if type(name) ~= "string" then return end
	name = string.Trim(name)
	if #name < 1 or #name > 48 or not string.match(name, "^[a-zA-Z0-9 _%-]+$") then return end
	return string.lower((string.gsub(name, " +", "_"))), name
end

function GM:ValidateKeyProfile(bindings)
	if type(bindings) ~= "table" then return end
	local result = {}
	local assigned = {}
	for _, action in ipairs(self.ZSKeyActions) do
		local value = bindings[action.id]
		if value == nil then value = action.default end
		if type(value) ~= "number" or value ~= math.floor(value) or value < -1 or value > MOUSE_5 then return end
		if value > 0 then
			if assigned[value] or value == KEY_ESCAPE or value == KEY_BACKQUOTE then return end
			assigned[value] = true
		end
		result[action.id] = value
	end
	return result
end
