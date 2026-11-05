local maximumBytes, maximumValues, maximumDepth = 16777216, 262144, 64
local byte, sub, find, concat = string.byte, string.sub, string.find, table.concat
local escapes = {a = "\a", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", v = "\v", ["\\"] = "\\", ['"'] = '"', ["'"] = "'"}
local reserved = {}
for name in string.gmatch("and break do else elseif end false for function if in local nil not or repeat return then true until while", "%S+") do reserved[name] = true end

local function ReadInteger(text, position)
	local cursor, number, character = position, 0, byte(text, position)
	for offset = 1, 9 do
		number, cursor = number * 10 + character - 48, cursor + 1
		character = byte(text, cursor)
		if not character or character < 48 or character > 57 then
			if not character or character == 44 or character == 59 or character == 125 or character == 93 or character == 41 or character == 32 or character >= 9 and character <= 13 then return number, cursor end
			return
		end
	end
end

local function ReadSerialized(text)
	local position, count, escapeCount, length = 1, 0, 0, #text
	local readValue
	local function fail(reason)
		error("Invalid serialized data at byte " .. position .. ": " .. reason, 0)
	end
	local function space()
		local character = byte(text, position)
		if character == 32 or character and character >= 9 and character <= 13 then
			local _, finish = find(text, "^%s+", position)
			position = finish + 1
		end
	end
	local function expect(character)
		space()
		if sub(text, position, position) ~= character then fail("expected " .. character) end
		position = position + 1
	end
	local function quoted(quote)
		local quoteByte = quote == '"' and 34 or 39
		local pattern = quoteByte == 34 and '["\\\r\n%z]' or "['\\\r\n%z]"
		position = position + 1
		local start, parts = position
		while true do
			local nextPosition = find(text, pattern, position)
			if not nextPosition then fail("unterminated string") end
			local character = byte(text, nextPosition)
			if character == quoteByte then
				local tail = string.sub(text, start, nextPosition - 1)
				position = nextPosition + 1
				if not parts then return tail end
				parts[#parts + 1] = tail
				return concat(parts)
			end
			if character ~= 92 then fail("unescaped string line or zero byte") end
			escapeCount = escapeCount + 1
			if escapeCount > maximumValues then fail("string escape limit exceeded") end
			parts = parts or {}
			parts[#parts + 1] = string.sub(text, start, nextPosition - 1)
			position = nextPosition + 1
			character = string.sub(text, position, position)
			local decoded = escapes[character]
			if decoded then
				position = position + 1
			elseif byte(text, position) and byte(text, position) >= 48 and byte(text, position) <= 57 then
				local _, finish = string.find(text, "^%d%d?%d?", position)
				local number = tonumber(string.sub(text, position, finish))
				if number > 255 then fail("string escape exceeds byte range") end
				decoded, position = string.char(number), finish + 1
			elseif character == "x" then
				local hex = string.sub(text, position + 1, position + 2)
				if not string.match(hex, "^%x%x$") then fail("invalid hexadecimal escape") end
				decoded, position = string.char(tonumber(hex, 16)), position + 3
			elseif character == "z" then
				position = position + 1
				space()
				decoded = ""
			elseif character == "\n" or character == "\r" then
				position = position + 1
				local following = string.sub(text, position, position)
				if following ~= character and (following == "\n" or following == "\r") then position = position + 1 end
				decoded = "\n"
			else
				fail("invalid string escape")
			end
			parts[#parts + 1] = decoded
			start = position
		end
	end
	local function readTable(depth)
		if depth > maximumDepth then fail("nesting limit exceeded") end
		position = position + 1
		local values, index = {}, 1
		space()
		while byte(text, position) ~= 125 do
			if position > length then fail("unterminated table") end
			local key, keyed
			local character = byte(text, position)
			if character == 91 then
				position = position + 1
				key, keyed = readValue(depth), true
				if key == nil then fail("nil table key") end
				expect("]")
				expect("=")
			elseif character == 95 or character and (character >= 65 and character <= 90 or character >= 97 and character <= 122) then
				local start, finish = find(text, "^[_%a][_%w]*", position)
				if start then
					local previous = position
					key = string.sub(text, start, finish)
					position = finish + 1
					space()
					if string.sub(text, position, position) == "=" and not reserved[key] then
						keyed, position = true, position + 1
					else
						position = previous
					end
				end
			end
			local value = readValue(depth)
			if keyed then values[key] = value else values[index], index = value, index + 1 end
			space()
			local separator = byte(text, position)
			if separator == 44 or separator == 59 then position = position + 1; space()
			elseif separator ~= 125 then fail("expected field separator") end
		end
		position = position + 1
		return values
	end
	readValue = function(depth)
		if depth > maximumDepth then fail("nesting limit exceeded") end
		count = count + 1
		if count > maximumValues then fail("value limit exceeded") end
		space()
		local character = byte(text, position)
		if character == 123 then return readTable(depth + 1) end
		if character == 34 then return quoted('"') end
		if character == 39 then return quoted("'") end
		if character and character >= 48 and character <= 57 then
			local number, finish = ReadInteger(text, position)
			if finish then position = finish; return number end
		end
		local start, finish
		if character == 95 or character and (character >= 65 and character <= 90 or character >= 97 and character <= 122) then
			start, finish = find(text, "^[_%a][_%w]*", position)
			local name = string.sub(text, start, finish)
			position = finish + 1
			if name == "true" then return true end
			if name == "false" then return false end
			if name == "nil" then return nil end
			if name ~= "Vector" and name ~= "Angle" then fail("unsupported value") end
			expect("(")
			local x = readValue(depth + 1)
			expect(",")
			local y = readValue(depth + 1)
			expect(",")
			local z = readValue(depth + 1)
			expect(")")
			if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then fail("constructor requires three numbers") end
			return name == "Vector" and Vector(x, y, z) or Angle(x, y, z)
		end
		local token = sub(text, position, position + 128)
		start, finish = find(token, "^[%+%-]?[%d%.][%da-fA-FxXpPeE%.%+%-]*")
		if not start or finish > 128 then fail("invalid number or value") end
		local number = tonumber(sub(token, start, finish))
		if not number or number ~= number or number == math.huge or number == -math.huge then fail("invalid or non-finite number") end
		if number == 0 and byte(text, position) == 45 then number = -1 / math.huge end
		position = position + finish
		return number
	end
	space()
	if string.sub(text, position, position + 2) == "SRL" then position = position + 3; expect("="); space() end
	if string.sub(text, position, position) ~= "{" then fail("expected table") end
	local values = readValue(0)
	space()
	if position <= length then fail("trailing data") end
	return values
end

function Deserialize(text)
	if type(text) ~= "string" then return {}, "Serialized data must be a string" end
	if #text == 0 then return {} end
	if #text > maximumBytes then return {}, "Serialized data exceeds size limit" end
	local ok, result = pcall(ReadSerialized, text)
	if not ok then return {}, result end
	return result
end

local allowedtypes = {}
allowedtypes["string"] = true
allowedtypes["number"] = true
allowedtypes["table"] = true
allowedtypes["Vector"] = true
allowedtypes["Angle"] = true
allowedtypes["boolean"] = true
local function NumberLiteral(value)
	local text = tostring(value)
	if value > -1e14 and value < 1e14 and value % 1 == 0 or tonumber(text) == value then return text end
	return string.format("%.17g", value)
end

local function MakeTable(tab, done)
	local parts = {}
	local done = done or {}

	local sequential = table.IsSequential(tab)

	for key, value in pairs(tab) do
		local keytype = type(key)
		local valuetype = type(value)

		if allowedtypes[keytype] and allowedtypes[valuetype] then
			if sequential then
				key = ""
			else
				if keytype == "number" then
					key = "["..NumberLiteral(key).."]="
				elseif keytype == "boolean" then
					key = "["..tostring(key).."]="
				else
					key = "["..string.format("%q", tostring(key)).."]="
				end
			end

			if valuetype == "table" and not done[value] then
				done[value] = true
				if type(value._serialize) == "function" then
					parts[#parts + 1] = key..value:_serialize()
				else
					parts[#parts + 1] = key.."{"..MakeTable(value, done).."}"
				end
			else
				if valuetype == "string" then 
					value = string.format("%q", value)
				elseif valuetype == "number" then
					value = NumberLiteral(value)
				elseif valuetype == "Vector" then
					value = "Vector("..value.x..","..value.y..","..value.z..")"
				elseif valuetype == "Angle" then
					value = "Angle("..value.pitch..","..value.yaw..","..value.roll..")"
				else
					value = tostring(value)
				end

				parts[#parts + 1] = key .. value
			end
		end
	end

	return table.concat(parts, ",")
end

function Serialize(tIn, bRaw)
	if #tIn == 0 then
		local empty = true
		for k in pairs(tIn) do
			empty = false
			break
		end
		if empty then
			return ""
		end
	end

	if bRaw then
		return "{"..MakeTable(tIn).."}"
	end

	return "SRL={"..MakeTable(tIn).."}"
end
