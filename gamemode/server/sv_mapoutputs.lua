local meta = FindMetaTable("Entity")
if not meta then return end

local depths = setmetatable({}, {__mode = "k"})
local dirty = setmetatable({}, {__mode = "k"})
local find, sub = string.find, string.sub

local function OutputNumber(value, fallback)
	if value == nil or value == "" then return fallback end
	if type(value) == "string" then value = tonumber(value); if value == nil then return fallback end end
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return end
	return value
end

local function OutputTarget(ent)
	return IsValid(ent) and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())
end

local function DispatchOutputs(self, list, count, activator, caller, args)
	for index = 1, count do
		local action = list[index]
		if type(action) == "table" and action.reps ~= 0 then
			local delay, repetitions = OutputNumber(action.delay, 0), OutputNumber(action.reps, -1)
			if delay and repetitions and repetitions ~= 0 and type(action.entityname) == "string" and action.entityname ~= "" and type(action.input) == "string" and action.input ~= "" then
				action.reps = repetitions == -1 and -1 or math.max(0, repetitions - 1)
				if action.reps == 0 then dirty[list] = true end
				local input = action.input
				local param = ((action.args == "") and args) or action.args
				for _, target in pairs(self:FindByNameHammer(action.entityname, activator, caller)) do
					if OutputTarget(target) then
						if delay > 0 then target:Fire(input, param, delay, activator, caller)
						else target:Input(input, activator, caller, param) end
					end
				end
			else
				action.reps = 0
				dirty[list] = true
			end
		else
			dirty[list] = true
		end
	end
end

function meta:FireOutput(output, activator, caller, args)
	if type(output) ~= "string" then return end
	local list = self[output]
	if type(list) ~= "table" then return end
	local count = #list
	if count == 0 then return end
	local depth = depths[list] or 0
	depths[list] = depth + 1
	local ok, failure = pcall(DispatchOutputs, self, list, count, activator, caller, args)
	if depth == 0 then
		depths[list] = nil
		if dirty[list] then
			dirty[list] = nil
			local write, finish = 1, #list
			for index = 1, finish do
				local action = list[index]
				if type(action) == "table" and action.reps ~= 0 then list[write], write = action, write + 1 end
			end
			for index = write, finish do list[index] = nil end
		end
	else
		depths[list] = depth
	end
	if not ok then error(failure, 0) end
end

function meta:AddOnOutput(key, value)
	if type(key) ~= "string" or key == "" or type(value) ~= "string" or find(value, "\0", 1, true) then return end
	local list = self[key]
	if list ~= nil and type(list) ~= "table" then return end
	local separator = find(value, "\27", 1, true) and "\27" or ","
	local fields, start = {}, 1
	for index = 1, 5 do
		local finish = find(value, separator, start, true)
		fields[index] = sub(value, start, finish and finish - 1 or #value)
		if not finish then break end
		start = finish + 1
	end
	local delay, repetitions = OutputNumber(fields[4], 0), OutputNumber(fields[5], -1)
	if not fields[1] or fields[1] == "" or not fields[2] or fields[2] == "" or not delay or not repetitions then return end
	if not list then list = {}; self[key] = list end
	list[#list + 1] = {entityname = fields[1], input = fields[2], args = fields[3] or "", delay = delay, reps = repetitions}
end

function meta:FindByNameHammer(name, activator, caller)
	local ent
	if name == "!self" then ent = self
	elseif name == "!activator" then ent = activator
	elseif name == "!caller" then ent = caller
	elseif name == "!player" then return player.GetAll()
	elseif type(name) == "string" and name ~= "" then return ents.FindByName(name)
	else return {} end
	return OutputTarget(ent) and {ent} or {}
end
