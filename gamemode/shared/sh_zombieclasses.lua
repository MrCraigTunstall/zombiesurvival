GM.RevertableZombieClasses = {}

local function CopyZombieClasses(source, copies)
	if type(source) ~= "table" then return source end
	copies = copies or {}
	if copies[source] then return copies[source] end
	local result = setmetatable({}, debug.getmetatable(source))
	copies[source] = result
	for key, value in pairs(source) do result[key] = CopyZombieClasses(value, copies) end
	return result
end

function GM:IsClassUnlocked(classname)
	local classtab = self.ZombieClasses[classname]
	if not classtab then return false end

	if classtab.IsClassUnlocked then
		local ret = classtab:IsClassUnlocked()
		if ret ~= nil then return ret end
	end

	if classtab.Locked then return false end
	if classtab.Unlocked then return classtab.Unlocked end
	local requiredWave = classtab.Wave
	if type(requiredWave) ~= "number" then return false end
	local wave = self:GetWave()
	return wave >= requiredWave or not self:GetWaveActive() and wave + 1 >= requiredWave
end

local function ReorderZombieClassesSort(a, b)
	if (a.Order or b.Order) and a.Order ~= b.Order then
		return (a.Order or 255) < (b.Order or 255)
	end

	if (a.Wave or b.Wave) and a.Wave ~= b.Wave then
		return (a.Wave or 255) < (b.Wave or 255)
	end

	return a.Name < b.Name
end
function GM:ReorderZombieClasses()
	table.sort(self.ZombieClasses, ReorderZombieClassesSort)
	for index, class in ipairs(self.ZombieClasses) do
		self.ZombieClasses[class.Name] = class
		class.Index = index

		if class.IsDefault then
			self.DefaultZombieClass = index
		end
	end
	if self.SelectZombieEscapeDefaultClass then self:SelectZombieEscapeDefaultClass() end
end

function GM:RegisterZombieClass(name, tab)
	local gm = self

	if tab.Wave then tab.Wave = math.floor(tab.Wave * self:GetNumberOfWaves()) end
	table.insert(gm.ZombieClasses, tab)
	tab.Index = #gm.ZombieClasses
	if CLIENT then
		tab.Icon = tab.Icon or "zombiesurvival/killicons/genericundead"
	end

	if tab.IsDefault then
		gm.DefaultZombieClass = tab.Index
	end

	tab.TranslationName = tab.TranslationName or tab.Name

	gm.ZombieClasses[name] = tab
end

function GM:RevertZombieClasses()
	self.ZombieClasses = CopyZombieClasses(self.RevertableZombieClasses)
	self.DefaultZombieClass = self.RevertableDefaultZombieClass or self.DefaultZombieClass
	if self.SelectZombieEscapeDefaultClass then self:SelectZombieEscapeDefaultClass() end
end

function GM:RegisterZombieClasses()
	self.ZombieClasses = {}
	self.DefaultZombieClass = self.DefaultZombieClass or 1

	local included = {}

	local classes = file.Find(self.FolderName.."/gamemode/shared/zombieclasses/*.lua", "LUA")
	table.sort(classes)
	for i, filename in ipairs(classes) do
		AddCSLuaFile("zombieclasses/"..filename)
		CLASS = {}
		include("zombieclasses/"..filename)
		if CLASS.Name then
			self:RegisterZombieClass(CLASS.Name, CLASS)
		else
			ErrorNoHalt("CLASS "..filename.." has no 'Name' member!")
		end
		included[filename] = CLASS
		CLASS = nil
	end

	local resolved = {}
	for _, class in ipairs(self.ZombieClasses) do
		if not resolved[class] then
			local path, visiting, cursor = {}, {}, class
			while cursor and not resolved[cursor] do
				if visiting[cursor] then
					ErrorNoHalt("CLASS "..tostring(cursor.Name).." has cyclic inheritance!\n")
					for _, entry in ipairs(path) do resolved[entry] = true end
					path = {}
					break
				end
				path[#path + 1], visiting[cursor] = cursor, true
				local base = cursor.Base
				if not base then break end
				local parent = (type(base) == "string" or type(base) == "number") and included[base..".lua"]
				if not parent then
					ErrorNoHalt("CLASS "..tostring(cursor.Name).." uses missing base class "..tostring(base).."!\n")
					break
				end
				cursor = parent
			end
			for index = #path, 1, -1 do
				local entry = path[index]
				local parent = (type(entry.Base) == "string" or type(entry.Base) == "number") and included[entry.Base..".lua"]
				if parent then table.Inherit(entry, parent) end
				resolved[entry] = true
			end
		end
	end
	for _, class in ipairs(self.ZombieClasses) do
		if class.Unlocked or class.Wave == 0 then class.UnlockedNotify = true end
	end

	self:ReorderZombieClasses()

	self.RevertableZombieClasses = CopyZombieClasses(self.ZombieClasses)
	self.RevertableDefaultZombieClass = self.DefaultZombieClass
end

GM:RegisterZombieClasses()

if CLIENT then
	net.Receive( "unlockClass", function()
		local targetName = net.ReadString()

		for k, v in pairs(GAMEMODE.ZombieClasses) do
			if(v.Name == targetName) then
				v.Unlocked = true
			end
		end
	end)
end
