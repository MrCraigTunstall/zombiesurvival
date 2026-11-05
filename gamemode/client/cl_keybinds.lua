local directory = "zombiesurvival/keyprofiles"
local selectionFile = "zombiesurvival/keyprofiles_selection.json"
local previousState = GM.ZSKeyBindingState
if hook.GetTable and hook.Remove then
	local registered = hook.GetTable()
	for _, entry in ipairs({{"Initialize", "ZS_LoadKeyBindsFallback"}, {"InitPostEntity", "ZS_LoadKeyBinds"}, {"InitPostEntity", "ZS_KeyBindsInit"}, {"Initialize", "ZS_KeyBindsSPInitFallback"}, {"PlayerButtonDown", "ZS_CustomKeyBinds"}, {"PlayerButtonUp", "ZS_CustomKeyBindsRelease"}}) do
		local callback = registered[entry[1]] and registered[entry[1]][entry[2]]
		if type(callback) == "function" and string.match(debug.getinfo(callback, "S").source, "/client/cl_keybinds%.lua$") then hook.Remove(entry[1], entry[2]) end
	end
end
local bindings, active, down, selected = {}, {}, {}, "default"
local convars, nativeActions = {}, {undo = "zoom"}
for _, action in ipairs(GM.ZSKeyActions) do
	convars[action.id] = CreateClientConVar("zs_key_" .. action.id, tostring(action.default), false, not action.clientOnly)
	bindings[action.id] = action.default
	if action.command then nativeActions[action.command] = action.id end
end

local function ServerKey()
	if game.SinglePlayer() then return "singleplayer" end
	local address = game.GetIPAddress()
	return address and address ~= "" and address or "local"
end

local function ReadJSON(path)
	local data = file.Read(path, "DATA")
	if not data or #data > 65536 then return nil, data end
	local result = util.JSONToTable(data)
	return type(result) == "table" and result or nil, data
end

local function RestoreFile(path, data)
	if file.Read(path, "DATA") == data then return end
	if data then file.Write(path, data) else file.Delete(path) end
end

local function WriteJSON(path, value)
	local data = util.TableToJSON(value, true)
	if not data or #data > 65536 then return false end
	local previous = file.Read(path, "DATA")
	file.CreateDir(directory)
	file.Write(path, data)
	if file.Read(path, "DATA") == data then return true end
	RestoreFile(path, previous)
	return false
end

local function WriteProfile(path, value, selections)
	local profile = file.Read(path, "DATA")
	if WriteJSON(path, value) and WriteJSON(selectionFile, selections) then return true end
	RestoreFile(path, profile)
	return false
end

function GM:GetZSKeyBinding(id)
	return bindings[id]
end

function GM:GetEffectiveZSKey(id, values)
	local action = self.ZSKeyActionByID[id]
	if not action then return -1 end
	local value = (values or bindings)[id]
	if value ~= 0 then return value end
	local key = action.command and input.LookupBinding(action.command, true)
	return key and input.GetKeyCode(key) or -1
end

local function EngineKeyAllowed(action, code, values)
	if not input.GetKeyName(code) then return false end
	local command = input.LookupKeyBinding(code)
	if not command or command == "" or command == action.command then return true end
	local owner = nativeActions[command]
	return owner ~= nil and values[owner] ~= 0
end

function GM:CheckZSKeyBindings(values)
	local valid = self:ValidateKeyProfile(values)
	if not valid then return nil, "keys_invalid" end
	local used = {}
	for _, action in ipairs(self.ZSKeyActions) do
		local code = self:GetEffectiveZSKey(action.id, valid)
		if code and code > 0 then
			if used[code] then return nil, "keys_conflict", used[code] end
			used[code] = action.label
			if valid[action.id] > 0 and not EngineKeyAllowed(action, code, valid) then return nil, "keys_engine_conflict" end
		end
	end
	return valid
end

local function ApplyBindings(self, valid)
	bindings, active, down = valid, {}, {}
	for _, action in ipairs(self.ZSKeyActions) do
		local code = bindings[action.id]
		local convar = convars[action.id]
		if convar:GetInt() ~= code then convar:SetInt(code) end
		if code > 0 then active[code] = action.id; down[code] = input.IsButtonDown(code) end
	end
	local state = self.ZSKeyBindingState
	if type(state) ~= "table" then state = {} end
	state.bindings, state.selected, state.server = valid, selected, ServerKey()
	self.ZSKeyBindingState = state
	return true
end

function GM:ApplyZSKeyBindings(values)
	local valid, reason, conflict = self:CheckZSKeyBindings(values)
	if not valid then return false, reason, conflict end
	return ApplyBindings(self, valid)
end

function GM:GetZSKeyProfiles()
	local profiles = {"default"}
	for _, name in ipairs(file.Find(directory .. "/*.json", "DATA")) do
		local id = string.sub(name, 1, -6)
		if id ~= "default" and self:ValidateKeyProfileName(id) == id then profiles[#profiles + 1] = id end
		if #profiles >= 128 then break end
	end
	table.sort(profiles)
	return profiles, selected
end

function GM:SaveZSKeyProfile(name, values)
	local id, label = self:ValidateKeyProfileName(name)
	if not id then return false, "keys_name_invalid" end
	local valid, reason, conflict = self:CheckZSKeyBindings(values)
	if not valid then return false, reason, conflict end
	local selections = ReadJSON(selectionFile) or {}
	selections[ServerKey()] = id
	if not WriteProfile(directory .. "/" .. id .. ".json", {version = 1, name = label, bindings = valid}, selections) then return false, "keys_save_failed" end
	selected = id
	return ApplyBindings(self, valid)
end

function GM:LoadZSKeyProfile(name)
	local id = self:ValidateKeyProfileName(name)
	if not id then return false, "keys_name_invalid" end
	local data = ReadJSON(directory .. "/" .. id .. ".json")
	if id ~= "default" and not data then return false, "keys_load_failed" end
	if data and data.version ~= 1 then return false, "keys_load_failed" end
	local valid, reason, conflict = self:CheckZSKeyBindings(data and data.bindings or {})
	if not valid then return false, reason, conflict end
	local selections = ReadJSON(selectionFile) or {}
	selections[ServerKey()] = id
	if not WriteJSON(selectionFile, selections) then return false, "keys_save_failed" end
	selected = id
	return ApplyBindings(self, valid)
end

function GM:ImportLegacyZSKeyProfile()
	local address = game.GetIPAddress() or ""
	if #address > 128 then return false, "keys_legacy_missing" end
	local legacyID = address ~= "" and string.gsub(address, "[^%w]", "_") or "default"
	local path = "zombiesurvival/zs_keybinds_" .. legacyID .. ".txt"
	local data = ReadJSON(path)
	if not data and legacyID ~= "default" then path = "zombiesurvival/zs_keybinds_default.txt" data = ReadJSON(path) end
	if not data then return false, "keys_legacy_missing" end
	local id = self:ValidateKeyProfileName("legacy_" .. string.sub(string.gsub(ServerKey(), "[^%w_]", "_"), 1, 41))
	if not id then return false, "keys_name_invalid" end
	local profilePath = directory .. "/" .. id .. ".json"
	if file.Exists(profilePath, "DATA") then return false, "keys_name_exists" end
	local values = self:ValidateKeyProfile({})
	local report = {source = path, imported = 0, rejected = 0, recognized = 0}
	for _, action in ipairs(self.ZSKeyActions) do
		local code = action.legacy and data[action.legacy]
		if code ~= nil then
			report.recognized = report.recognized + 1
			if code == 0 or code == -1 then values[action.id] = -1
			elseif type(code) == "number" and code == math.floor(code) and code > 0 and code <= MOUSE_5 and code ~= KEY_ESCAPE and code ~= KEY_BACKQUOTE and input.GetKeyName(code) then
				local command = input.LookupKeyBinding(code)
				local owner = command and nativeActions[command]
				local previous = owner and values[owner]
				if owner and previous == 0 then values[owner] = -1 end
				values[action.id] = code
				if self:CheckZSKeyBindings(values) then report.imported = report.imported + 1
				else values[action.id] = -1 if owner then values[owner] = previous end report.rejected = report.rejected + 1 end
			else report.rejected = report.rejected + 1 end
		end
	end
	if report.recognized == 0 then return false, "keys_legacy_missing" end
	local valid, reason, conflict = self:CheckZSKeyBindings(values)
	if not valid then return false, reason, conflict end
	local selections = ReadJSON(selectionFile) or {}
	selections[ServerKey()] = id
	if not WriteProfile(profilePath, {version = 1, name = id, bindings = valid, legacy = report}, selections) then return false, "keys_save_failed" end
	selected = id
	local applied, applyReason, applyConflict = ApplyBindings(self, valid)
	if not applied then return false, applyReason, applyConflict end
	self.ZSLegacyKeyImport = report
	return true, nil, report
end

function GM:RenameZSKeyProfile(oldName, newName)
	local oldID = self:ValidateKeyProfileName(oldName)
	local newID, label = self:ValidateKeyProfileName(newName)
	if not oldID or not newID then return false, "keys_name_invalid" end
	if oldID == newID then return false, "keys_name_exists" end
	local oldPath, newPath = directory .. "/" .. oldID .. ".json", directory .. "/" .. newID .. ".json"
	if file.Exists(newPath, "DATA") then return false, "keys_name_exists" end
	local data = ReadJSON(oldPath)
	if not data or data.version ~= 1 or not self:ValidateKeyProfile(data.bindings) then return false, "keys_load_failed" end
	data.name = label
	local selections, previousSelection = ReadJSON(selectionFile)
	selections = selections or {}
	for server, id in pairs(selections) do if id == oldID then selections[server] = newID end end
	if not WriteProfile(newPath, data, selections) then return false, "keys_save_failed" end
	file.Delete(oldPath)
	if file.Exists(oldPath, "DATA") then
		RestoreFile(newPath, nil)
		RestoreFile(selectionFile, previousSelection)
		return false, "keys_save_failed"
	end
	if selected == oldID then
		selected = newID
		if self.ZSKeyBindingState then self.ZSKeyBindingState.selected = newID end
	end
	return true
end

function GM:RunZSKeyAction(id)
	local pl = LocalPlayer()
	if not IsValid(pl) then return end
	if id == "help" then self:ShowHelp()
	elseif id == "options" then MakepOptions()
	elseif id == "shop" or id == "class" then RunConsoleCommand("zs_keyaction", id)
	elseif id == "mapvote" then self:OpenMapVote()
	elseif id == "dropweapon" then RunConsoleCommand("zsdropweapon")
	elseif id == "dropammo" then RunConsoleCommand("zsdropammo")
	elseif id == "quickbuy" then
		if pl:Team() == TEAM_HUMAN and pl:Alive() and not self.ZombieEscape then self:OpenPointsShop() else RunConsoleCommand("zs_keyaction", "shop") end
	elseif id == "altmenu" then
		if pl:Team() ~= TEAM_UNDEAD and pl:Alive() and not pl:IsHolding() then self:HumanMenu() end
	elseif id == "taunt" then self:OpenTauntMenu()
	elseif id == "suicide" then if pl:Team() == TEAM_UNDEAD and pl:Alive() then RunConsoleCommand("kill") end
	elseif id == "weapons" then MakepWeapons()
	elseif id == "keys" then self:OpenKeySettings()
	elseif id == "camera_cycle" then self:SetZSCameraViewMode(self:GetZSCameraViewMode() % 8 + 1)
	elseif self.ZSKeyActionByID[id] and self.ZSKeyActionByID[id].camera then self:SetZSCameraViewMode(self.ZSKeyActionByID[id].camera)
	elseif id == "thirdperson" and pl:Team() ~= TEAM_SPECTATOR then self.ZombieThirdPerson = not self.ZombieThirdPerson
	elseif id == "vision" then
		if pl:Team() == TEAM_UNDEAD and pl:Alive() then self:ToggleZombieVision() else self:CreateFlashlightCheck() end
	elseif id == "zoom" then
		RunConsoleCommand("+zoom")
		timer.Create("ReleaseZoom", 1, 1, function() RunConsoleCommand("-zoom") end)
	end
end

function GM:IsZSKeyActionDown(id)
	local code = bindings[id]
	return code ~= nil and code > 0 and active[code] == id and input.IsButtonDown(code)
end

function GM:IsHumanMenuKeyDown(pl)
	return pl:KeyDown(self.MenuKey) or self:IsZSKeyActionDown("altmenu")
end

hook.Add("Think", "ZSKeyBindings", function()
	if next(active) == nil then return end
	local blocked = gui.IsGameUIVisible() or vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus()) or input.IsKeyTrapping()
	for code, id in pairs(active) do
		local pressed = input.IsButtonDown(code)
		if pressed and not down[code] and not blocked then
			local action = GAMEMODE.ZSKeyActionByID[id]
			if action and EngineKeyAllowed(action, code, bindings) then GAMEMODE:RunZSKeyAction(id) end
		end
		down[code] = pressed
	end
end)

local function LoadCurrentProfile()
	local selections = ReadJSON(selectionFile) or {}
	local ok = GAMEMODE:LoadZSKeyProfile(selections[ServerKey()] or "default")
	if not ok then selected = "default" GAMEMODE:ApplyZSKeyBindings({}) end
end

hook.Add("InitPostEntity", "ZSKeyProfileLoad", LoadCurrentProfile)

if previousState then
	if previousState.server == ServerKey() then
		selected = previousState.selected or "default"
		if not GM:ApplyZSKeyBindings(previousState.bindings) then selected = "default" GM:ApplyZSKeyBindings({}) end
	else
		LoadCurrentProfile()
	end
elseif IsValid(LocalPlayer()) then
	local values = {}
	for _, action in ipairs(GM.ZSKeyActions) do values[action.id] = convars[action.id]:GetInt() end
	local selections = ReadJSON(selectionFile) or {}
	selected = GM:ValidateKeyProfileName(selections[ServerKey()] or "default") or "default"
	if not GM:ApplyZSKeyBindings(values) then selected = "default" GM:ApplyZSKeyBindings({}) end
end
