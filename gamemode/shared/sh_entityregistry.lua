ZSClassEntities = ZSClassEntities or {classes = {}, entities = {}}
local state = ZSClassEntities
state.patterns = state.patterns or {}
state.pending = state.pending or setmetatable({}, {__mode = "k"})
local classes = {"prop_arsenalcrate", "status_arsenalcrate", "prop_resupplybox", "prop_obj_sigil", "point_worldhint", "logic_infliction", "npc_zs_trader", "npc_zs_quest", "prop_detpack", "prop_gunturret", "prop_drone", "prop_manhack", "prop_manhack_saw", "prop_creepernest"}
local empty = {}

local function RegistryValid(ent)
	return IsValid(ent) or ent and ent.IsWorld and ent:IsWorld()
end

local function CompilePattern(class, bucket)
	local parts = {}
	bucket.query, bucket.question = class, string.find(class, "?", 1, true)
	for part in string.gmatch(class, "[^*]+") do parts[#parts + 1] = part end
	bucket.parts, bucket.leading, bucket.trailing = parts, string.sub(class, 1, 1) == "*", string.sub(class, -1) == "*"
	bucket.matcher = nil
end

local function Matches(class, bucket)
	if bucket.question then
		local pattern = bucket.query
		local c, p, star, checkpoint = 1, 1
		while c <= #class do
			local char = string.sub(pattern, p, p)
			if char == "*" then
				star, checkpoint, p = p, c, p + 1
			elseif char == "?" or char == string.sub(class, c, c) then
				c, p = c + 1, p + 1
			elseif star then
				checkpoint = checkpoint + 1
				c, p = checkpoint, star + 1
			else return false end
		end
		while string.sub(pattern, p, p) == "*" do p = p + 1 end
		return p > #pattern
	end
	local position, parts = 1, bucket.parts
	for index, part in ipairs(parts) do
		if index == 1 and not bucket.leading then
			if string.sub(class, 1, #part) ~= part then return false end
			position = #part + 1
		elseif index == #parts and not bucket.trailing then
			local start = #class - #part + 1
			if start < position or string.sub(class, start) ~= part then return false end
			position = #class + 1
		else
			local start, finish = string.find(class, part, position, true)
			if not start then return false end
			position = finish + 1
		end
	end
	return true
end

for class, bucket in pairs(state.patterns) do CompilePattern(class, bucket) end

local function Unregister(ent)
	state.pending[ent] = nil
	for _, bucket in pairs(state.patterns) do
		if bucket.members[ent] then
			bucket.members[ent] = nil
			if bucket.count then bucket.count = bucket.count - 1 end
			bucket.dirty, bucket.unordered = true, nil
		end
	end
	local class = state.entities[ent]
	if not class then return end
	local bucket = state.classes[class]
	bucket.members[ent] = nil
	if bucket.count then bucket.count = bucket.count - 1 end
	bucket.dirty, bucket.unordered = true, nil
	state.entities[ent] = nil
end

local function Register(ent)
	if not RegistryValid(ent) then Unregister(ent); return end
	local class = ent:GetClass()
	if not class or class == "" then state.pending[ent] = true; return end
	state.pending[ent] = nil
	class = string.lower(class)
	local bucket = state.classes[class]
	if bucket and state.entities[ent] ~= class then
		Unregister(ent)
		state.entities[ent] = class
		bucket.members[ent] = true
		if bucket.count then bucket.count = bucket.count + 1 end
		bucket.dirty, bucket.unordered = true, nil
	end
	for _, pattern in pairs(state.patterns) do
		if not pattern.members[ent] and Matches(class, pattern) then
			pattern.members[ent] = true
			if pattern.count then pattern.count = pattern.count + 1 end
			pattern.dirty, pattern.unordered = true, nil
		end
	end
end

local function FlushPending()
	for ent in pairs(state.pending) do Register(ent) end
end

local function EnsureClass(class)
	if type(class) ~= "string" or class == "" then return end
	class = string.lower(class)
	local wildcard = string.find(class, "*", 1, true) or string.find(class, "?", 1, true)
	local buckets = wildcard and state.patterns or state.classes
	local bucket = buckets[class]
	if not bucket then
		bucket = {members = {}, ordered = {}, dirty = true, count = 0}
		buckets[class] = bucket
		if wildcard then CompilePattern(class, bucket) end
		for _, ent in ipairs(ents.FindByClass(class)) do Register(ent) end
	end
	return bucket
end

function GM:GetZSClassCount(class)
	local bucket = EnsureClass(class)
	if not bucket then return #ents.FindByClass(class) end
	FlushPending()
	if bucket.count == nil then
		local count = 0
		for ent in pairs(bucket.members) do
			if RegistryValid(ent) then count = count + 1 else Unregister(ent) end
		end
		bucket.count = count
	end
	return bucket.count
end

function GM:GetZSEquipmentEntities(class, unordered)
	local bucket = EnsureClass(class)
	if not bucket then return ents.FindByClass(class) end
	if not unordered then return self:GetZSClassEntities(class) end
	FlushPending()
	if not bucket.unordered then
		local entities = {}
		for ent in pairs(bucket.members) do
			if RegistryValid(ent) then entities[#entities + 1] = ent else Unregister(ent) end
		end
		bucket.unordered = entities
	end
	return bucket.unordered
end

function GM:HasZSClassInSphere(class, position, radius)
	if #self:GetZSEquipmentEntities(class, true) == 0 then return false end
	for _, ent in pairs(ents.FindInSphere(position, radius)) do
		if IsValid(ent) and ent:GetClass() == class then return true end
	end
	return false
end

function GM:RegisterZSClassEntity(ent)
	Register(ent)
end

function GM:GetZSClassEntities(class)
	FlushPending()
	if type(class) == "string" then class = string.lower(class) end
	local bucket = state.patterns[class] or state.classes[class]
	if not bucket then return empty end
	if bucket.dirty then
		local ordered = {}
		for ent in pairs(bucket.members) do
			if RegistryValid(ent) then ordered[#ordered + 1] = ent else Unregister(ent) end
		end
		table.sort(ordered, function(a, b) return a:EntIndex() < b:EntIndex() end)
		bucket.ordered, bucket.dirty = ordered, false
	end
	return bucket.ordered
end

for _, class in ipairs(classes) do
	if not state.classes[class] then
		state.classes[class] = {members = {}, ordered = {}, dirty = true, count = 0}
		for _, ent in ipairs(ents.FindByClass(class)) do Register(ent) end
	end
end

hook.Add("OnEntityCreated", "ZSClassEntities", Register)
hook.Add("NetworkEntityCreated", "ZSClassEntities", Register)
hook.Add("EntityRemoved", "ZSClassEntities", Unregister)
hook.Add("InitPostEntity", "ZSClassEntities", function()
	for class in pairs(state.classes) do
		for _, ent in ipairs(ents.FindByClass(class)) do Register(ent) end
	end
	for class in pairs(state.patterns) do
		for _, ent in ipairs(ents.FindByClass(class)) do Register(ent) end
	end
end)

hook.Add("Think", "ZSClassEntities", function()
	if next(state.pending) then FlushPending() end
end)
