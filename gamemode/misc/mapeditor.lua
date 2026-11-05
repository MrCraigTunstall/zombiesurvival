GM.MapEditorPrefix = "zs"
GM.MapEditorEntities = GM.MapEditorEntities or {}
local maximumBytes, maximumEntities = 16777216, 4096
file.CreateDir(GM.MapEditorPrefix.."maps")

local function Finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function Live(entity)
	return IsValid(entity) and not entity:IsMarkedForDeletion()
end
local function Class(value)
	return type(value) == "string" and #value > 0 and #value <= 128 and string.match(value, "^[%w_]+$") and string.lower(value)
end
local function Position(value)
	return isvector(value) and Finite(value.x) and Finite(value.y) and Finite(value.z)
end
local function Angles(value)
	return isangle(value) and Finite(value.p) and Finite(value.y) and Finite(value.r)
end
local function Field(value)
	local kind = type(value)
	return kind == "boolean" or kind == "string" and #value <= 65536 or Finite(value) or Position(value) or Angles(value)
end
local function Metadata(values, engine)
	if values == nil then return {} end
	if type(values) ~= "table" then return end
	local out, count = {}, 0
	for key, value in pairs(values) do
		count = count + 1
		if count > 256 or type(key) ~= "string" or #key < 1 or #key > 128 or key:find("[%z\1-\31\127]") then return end
		if engine then
			if type(value) ~= "string" and type(value) ~= "boolean" and not Finite(value) then return end
			value = type(value) == "boolean" and (value and "1" or "0") or tostring(value)
			if #value > 65536 then return end
		elseif not Field(value) or key == "KeyValues" or key == "ZSMapEditorFields" or key == "ZSMapEditorEngineKeyValues" then
			return
		end
		out[key] = value
	end
	return out
end
local function Validate(values)
	if type(values) ~= "table" then return end
	local count, rows = 0, {}
	for index in pairs(values) do
		if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then return end
		count = count + 1
		if count > maximumEntities then return end
	end
	if count ~= #values then return end
	for _, row in ipairs(values) do
		if type(row) ~= "table" then return end
		local class = Class(row.Class)
		local fields, engine = Metadata(row.KeyValues), Metadata(row.EngineKeyValues, true)
		if not class or not Position(row.Position) or not Angles(row.Angles) or not fields or not engine then return end
		rows[#rows + 1] = {Class = class, Position = row.Position, Angles = row.Angles, KeyValues = fields, EngineKeyValues = engine}
	end
	return rows
end
local function Decode(text)
	local first = string.match(text, "^%s*(.)")
	if not first or first == "{" or string.match(text, "^%s*SRL") then
		local values, failure = Deserialize(text)
		return not failure and Validate(values) or nil
	end
	local rows = {}
	for _, record in ipairs(string.Explode(",", text)) do
		local tokens = {}
		for token in string.gmatch(record, "%S+") do tokens[#tokens + 1] = token end
		if #tokens < 4 then return end
		local x, y, z = tonumber(tokens[2]), tonumber(tokens[3]), tonumber(tokens[4])
		if not Finite(x) or not Finite(y) or not Finite(z) then return end
		local row = {Class = tokens[1], Position = Vector(x, y, z), Angles = Angle(), EngineKeyValues = {}}
		for index = 5, #tokens do
			local token = tokens[index]
			local split, finish = string.find(token, string.char(194, 167), 1, true)
			if not split then split, finish = string.find(token, string.char(167), 1, true) end
			if not split then return end
			row.EngineKeyValues[string.sub(token, 1, split - 1)] = string.sub(token, finish + 1)
		end
		rows[#rows + 1] = row
		if #rows > maximumEntities then return end
	end
	return Validate(rows)
end

function GM:LoadMapEditorFile(deferSpawnRefresh)
	local map = game.GetMap()
	local path, realm
	local folder = self.Folder or "gamemodes/"..self.FolderName
	for _, candidate in ipairs({{self.FolderName.."/gamemode/prepackagedmapprofiles/"..map..".lua", "LUA"}, {folder.."/gamemode/prepackagedmapprofiles/"..map..".lua", "GAME"}, {folder.."/gamemode/misc/prepackagedmapprofiles/"..map..".lua", "GAME"}}) do
		if file.Exists(candidate[1], candidate[2]) then path, realm = candidate[1], candidate[2] break end
	end
	if not path then path, realm = self.MapEditorPrefix.."maps/"..map..".txt", "DATA" end
	local rows = {}
	if file.Exists(path, realm) then
		if file.Size(path, realm) > maximumBytes then self.MapEditorReadOnly = true return false, "Map editor profile exceeds size limit" end
		local text = file.Read(path, realm)
		rows = type(text) == "string" and Decode(text) or nil
		if not rows then self.MapEditorReadOnly = true return false, "Invalid map editor profile" end
	end
	local created = {}
	local ok, failure = pcall(function()
		for _, row in ipairs(rows) do
			local entity = ents.Create(row.Class)
			if not Live(entity) then error("Cannot create map editor entity: "..row.Class, 0) end
			created[#created + 1] = entity
			entity:SetPos(row.Position)
			entity:SetAngles(row.Angles)
			for key, value in pairs(row.KeyValues) do
				if type(entity[key]) == "function" then error("Map editor field replaces an entity method", 0) end
				entity[key] = value
			end
			for key, value in pairs(row.EngineKeyValues) do entity:SetKeyValue(key, value) end
			entity:Spawn()
			if not Live(entity) then error("Map editor entity removed during spawn", 0) end
			entity.ZSMapEditorFields, entity.ZSMapEditorEngineKeyValues = row.KeyValues, row.EngineKeyValues
		end
	end)
	if not ok then
		for _, entity in ipairs(created) do if Live(entity) then entity:Remove() end end
		self.MapEditorReadOnly = true
		return false, failure
	end
	local previous = self.MapEditorEntities or {}
	self.MapEditorEntities, self.MapEditorReadOnly = created, false
	for _, entity in pairs(previous) do if Live(entity) then entity:Remove() end end
	if not deferSpawnRefresh and self == GAMEMODE and self.SetupSpawnPoints then self:SetupSpawnPoints() end
	return true
end

function GM:SaveMapEditorFile()
	if self.MapEditorReadOnly then return false, "Map editor profile is read-only" end
	local rows, entities, seen = {}, {}, {}
	for _, entity in ipairs(self.MapEditorEntities or {}) do
		if Live(entity) and not seen[entity] then
			seen[entity] = true
			local fields = {}
			for key in pairs(entity.ZSMapEditorFields or {}) do fields[key] = entity[key] end
			if type(entity.KeyValues) == "table" then
				for key, value in pairs(entity.KeyValues) do
					if type(key) == "number" and type(value) == "string" then fields[value] = entity[value]
					elseif type(key) == "string" then
						if entity[key] ~= nil then fields[key] = entity[key] else fields[key] = value end
					end
				end
			end
			rows[#rows + 1] = {Class = entity:GetClass(), Position = entity:GetPos(), Angles = entity:GetAngles(), KeyValues = fields, EngineKeyValues = entity.ZSMapEditorEngineKeyValues}
			entities[#entities + 1] = entity
		end
	end
	if not Validate(rows) then return false, "Invalid map editor entity data" end
	local data = Serialize(rows)
	if #data > maximumBytes then return false, "Map editor profile exceeds size limit" end
	local path = self.MapEditorPrefix.."maps/"..game.GetMap()..".txt"
	local previous = file.Read(path, "DATA")
	file.CreateDir(self.MapEditorPrefix.."maps")
	file.Write(path, data)
	if file.Read(path, "DATA") ~= data then
		if previous then file.Write(path, previous) else file.Delete(path) end
		return false, "Map editor save failed"
	end
	local tracked = self.MapEditorEntities or {}
	for index = 1, math.max(#tracked, #entities) do tracked[index] = entities[index] end
	self.MapEditorEntities = tracked
	return true
end

local function Admin(player)
	return IsValid(player) and player:IsPlayer() and player:IsSuperAdmin()
end
local function Editable(player)
	return Admin(player) and not GAMEMODE.MapEditorReadOnly
end
local function Target(player)
	local entity = player:GetEyeTrace().Entity
	if not Live(entity) then return end
	for index, tracked in ipairs(GAMEMODE.MapEditorEntities) do if tracked == entity then return entity, index end end
end
local function RefreshSpawns(class)
	if (string.sub(class, 1, 11) == "info_player" or class == "gmod_player_start" or class == "info_zombiespawn") and GAMEMODE.SetupSpawnPoints then GAMEMODE:SetupSpawnPoints() end
end
local function Add(player, arguments, onPlayer)
	if not Editable(player) or not Class(arguments[1]) then return end
	local trace = not onPlayer and player:GetEyeTrace()
	if trace and not trace.Hit then return end
	local entity = ents.Create(string.lower(arguments[1]))
	if not Live(entity) then return end
	local ok = pcall(function()
		entity:SetPos(onPlayer and player:EyePos() or trace.HitPos)
		if onPlayer then entity:SetAngles(player:GetAngles()) end
		entity:Spawn()
	end)
	if not ok or not Live(entity) then if Live(entity) then entity:Remove() end return end
	GAMEMODE.MapEditorEntities[#GAMEMODE.MapEditorEntities + 1] = entity
	RefreshSpawns(entity:GetClass())
	GAMEMODE:SaveMapEditorFile()
end
concommand.Add("mapeditor_add", function(player, _, arguments) Add(player, arguments, false) end)
concommand.Add("mapeditor_addonme", function(player, _, arguments) Add(player, arguments, true) end)
concommand.Add("mapeditor_remove", function(player)
	if not Editable(player) then return end
	local entity = Target(player)
	if not entity then return end
	local tracked, cursor = GAMEMODE.MapEditorEntities, 1
	for index = 1, #tracked do if tracked[index] ~= entity then tracked[cursor], cursor = tracked[index], cursor + 1 end end
	for index = cursor, #tracked do tracked[index] = nil end
	local class = entity:GetClass()
	entity:Remove()
	RefreshSpawns(class)
	GAMEMODE:SaveMapEditorFile()
end)
local function Pickup(player, entity, id)
	if Editable(player) and Live(entity) then
		local position = player:GetShootPos()
		entity:SetPos(util.TraceLine({start = position, endpos = position + player:GetAimVector() * 3000, filter = {player, entity}}).HitPos)
		return
	end
	timer.Destroy(id.."mapeditorpickup")
	GAMEMODE:SaveMapEditorFile()
end
concommand.Add("mapeditor_pickup", function(player)
	if not Editable(player) then return end
	local entity = Target(player)
	if entity then local id = player:UniqueID();timer.CreateEx(id.."mapeditorpickup", 0.25, 0, Pickup, player, entity, id) end
end)
for _, definition in ipairs({{"up", "Up"}, {"forward", "Forward"}, {"right", "Right"}}) do
	local name, axis = definition[1], definition[2]
	concommand.Add("mapeditor_nudge"..name, function(player, _, arguments)
		if not Editable(player) then return end
		local entity = Target(player)
		local amount = arguments[1] == nil and 1 or tonumber(arguments[1])
		if not entity or not Finite(amount) then return end
		local direction = name == "up" and Vector(0, 0, 1) or entity["Get"..axis](entity)
		local position = entity:GetPos() + direction * amount
		if not Position(position) then return end
		entity:SetPos(position)
		return GAMEMODE:SaveMapEditorFile()
	end)
	concommand.Add("mapeditor_rotate"..name, function(player, _, arguments)
		if not Editable(player) then return end
		local entity = Target(player)
		local amount = arguments[1] == nil and 1 or tonumber(arguments[1])
		if not entity or not Finite(amount) then return end
		local angles = entity:GetAngles()
		angles:RotateAroundAxis(angles[axis](angles), amount)
		if not Angles(angles) then return end
		entity:SetAngles(angles)
		return GAMEMODE:SaveMapEditorFile()
	end)
end
concommand.Add("mapeditor_drop", function(player)
	if not Admin(player) then return end
	timer.Destroy(player:UniqueID().."mapeditorpickup")
	GAMEMODE:SaveMapEditorFile()
end)
