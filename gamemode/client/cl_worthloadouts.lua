local maximumCarts, maximumItems, maximumNameBytes = 128, 128, 128
local function Paths(gm)
	local path = string.lower(gm.CartFile)
	return path, path .. ".zs-pending.txt", path .. ".zs-previous.txt"
end

local function Read(path)
	local ok, value = pcall(file.Read, path, "DATA")
	return ok and value or nil
end

local function RemoveTemporary(path)
	if not file.Exists(path, "DATA") then return true end
	pcall(file.Delete, path)
	return not file.Exists(path, "DATA")
end

local function Move(source, destination, data)
	pcall(file.Rename, source, destination)
	return Read(destination) == data and not file.Exists(source, "DATA")
end

local function RecoveryPath(gm)
	local path, pending, previous = Paths(gm)
	if not file.Exists(path, "DATA") and file.Exists(previous, "DATA") then
		local data = Read(previous)
		if not data or not Move(previous, path, data) then return previous, true end
	end
	return path, false
end
local function Name(value)
	if type(value) ~= "string" then return end
	value = string.Trim(value)
	if value == "" or #value > maximumNameBytes or value:find("[%z\1-\31\127]") then return end
	return value
end

local function Items(values)
	if type(values) ~= "table" then return end
	local out, seen = {}, {}
	for index, value in ipairs(values) do
		if index > maximumItems then break end
		local kind = type(value)
		if kind == "string" and #value > 0 and #value <= 128 or kind == "number" and value > 0 and value < math.huge and value % 1 == 0 then
			if not seen[value] then out[#out + 1] = value seen[value] = true end
		end
	end
	return out
end

function GM:NormalizeWorthCarts(values)
	local out, names = {}, {}
	if type(values) ~= "table" then return out end
	for index, value in ipairs(values) do
		if index > maximumCarts then break end
		if type(value) == "table" then
			local name, ids = Name(value[1]), Items(value[2])
			if name and ids then
				local key = string.lower(name)
				local previous = names[key]
				if previous then out[previous] = {name, ids} else out[#out + 1] = {name, ids} names[key] = #out end
			end
		end
	end
	return out
end

function GM:LoadWorthCarts()
	local carts = {}
	local path, recovery = RecoveryPath(self)
	local primary, pending, previous = Paths(self)
	self.WorthCartsReadOnly = recovery
	if file.Exists(path, "DATA") then
		self.WorthCartsReadOnly = true
		if file.Size(path, "DATA") <= 2097152 then
			local data = Read(path)
			if type(data) == "string" then
				local ok, values, failure = pcall(Deserialize, data)
				if ok and not failure and type(values) == "table" then
					carts = self:NormalizeWorthCarts(values)
					self.WorthCartsReadOnly = recovery or values[maximumCarts + 1] ~= nil
					for index, value in ipairs(values) do
						if index > maximumCarts then break end
						if type(value) == "table" and type(value[2]) == "table" and value[2][maximumItems + 1] ~= nil then self.WorthCartsReadOnly = true break end
					end
				end
			end
		end
	end
	if not self.WorthCartsReadOnly and path == primary then RemoveTemporary(pending) RemoveTemporary(previous) end
	self.SavedCarts = carts
	return carts
end

local function Persist(gm, carts)
	local encoded, data = pcall(Serialize, carts)
	if not encoded or type(data) ~= "string" then return false, "worth_save_failed" end
	if #data > 2097152 then return false, "worth_loadout_limit" end
	local path, pending, previous = Paths(gm)
	if file.Exists(previous, "DATA") and not file.Exists(path, "DATA") then gm.WorthCartsReadOnly = true return false, "worth_save_failed" end
	if not RemoveTemporary(pending) or not RemoveTemporary(previous) then return false, "worth_save_failed" end
	local existed = file.Exists(path, "DATA")
	local committed = existed and Read(path) or nil
	if existed and not committed then gm.WorthCartsReadOnly = true return false, "worth_save_failed" end
	if committed == data then gm.SavedCarts = carts return true end
	local ok = pcall(file.Write, pending, data)
	if not ok or Read(pending) ~= data then RemoveTemporary(pending) return false, "worth_save_failed" end
	if existed and not Move(path, previous, committed) then
		if Read(path) ~= committed then gm.WorthCartsReadOnly = true end
		RemoveTemporary(pending) return false, "worth_save_failed"
	end
	if not Move(pending, path, data) then
		if existed and Read(previous) == committed then
			if file.Exists(path, "DATA") then RemoveTemporary(path) end
			if not Move(previous, path, committed) then gm.WorthCartsReadOnly = true end
		end
		if not gm.WorthCartsReadOnly then RemoveTemporary(pending) end
		return false, "worth_save_failed"
	end
	RemoveTemporary(previous)
	gm.SavedCarts = carts
	return true
end

function GM:SaveWorthCart(name, values)
	if self.WorthCartsReadOnly then return false, "worth_loadout_readonly" end
	name = Name(name)
	local ids = Items(values)
	if not name or not ids or #values > maximumItems then return false, "worth_invalid_name" end
	local carts, selected = self:NormalizeWorthCarts(self.SavedCarts)
	local key = string.lower(name)
	for index, cart in ipairs(carts) do if string.lower(cart[1]) == key then selected = index break end end
	if not selected then
		if #carts >= maximumCarts then return false, "worth_loadout_limit" end
		selected = #carts + 1
	end
	carts[selected] = {name, ids}
	local ok, reason = Persist(self, carts)
	if not ok then return false, reason end
	return true, selected
end

function GM:DeleteWorthCart(index)
	if self.WorthCartsReadOnly then return false, "worth_loadout_readonly" end
	local carts = self:NormalizeWorthCarts(self.SavedCarts)
	if type(index) ~= "number" or index % 1 ~= 0 or not carts[index] then return false end
	table.remove(carts, index)
	return Persist(self, carts)
end

function GM:RequestedDefaultCart()
	local cvar = GetConVar("zs_defaultcart")
	local name = cvar and cvar:GetString() or ""
	if name == "" then return end
	name = string.lower(name)
	for _, cart in ipairs(self.SavedCarts or {}) do
		if type(cart) == "table" and type(cart[1]) == "string" and string.lower(cart[1]) == name then
			local ids = self:PrepareWorthCheckout(cart[2])
			if ids then
				gamemode.Call("SuppressArsenalUpgrades", 1)
				RunConsoleCommand("worthcheckout", unpack(ids))
				return
			end
			break
		end
	end
	RunConsoleCommand("worthrandom")
end

GM.SavedCarts = GM.SavedCarts or {}
hook.Add("Initialize", "LoadCarts", function() GAMEMODE:LoadWorthCarts() end)
