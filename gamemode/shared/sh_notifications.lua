local fields = {"r", "g", "b", "a", "font", "killicon", "headshot", "image"}

function GM:GetNotificationKey(args)
	local parts = {}
	for i = 1, #args do
		local value = args[i]
		local kind = type(value)
		if kind == "string" or kind == "number" or kind == "boolean" then
			value = tostring(value)
			parts[#parts + 1] = kind .. #value .. ":" .. value
		elseif kind == "table" then
			if value.NoGroup then return nil end
			if value.NotificationKey then return "key:" .. tostring(value.NotificationKey) end
			for _, field in ipairs(fields) do
				local item = value[field]
				if item ~= nil then
					item = tostring(item)
					parts[#parts + 1] = field .. #item .. ":" .. item
				end
			end
			if value.color then
				local color = value.color
				parts[#parts + 1] = string.format("color:%s:%s:%s:%s", color.r, color.g, color.b, color.a or 255)
			end
		else
			return nil
		end
	end
	return table.concat(parts, "|")
end

function GM:GetNotificationOptions(args)
	local lifetime, count, total = self.NotifyFadeTime or 8, 1
	for i = 1, #args do
		local value = args[i]
		if type(value) == "table" then
			if type(value.CustomTime) == "number" and value.CustomTime == value.CustomTime then
				lifetime = math.Clamp(value.CustomTime, 2, 30)
			end
			if type(value.RepeatCount) == "number" and value.RepeatCount == value.RepeatCount then
				count = math.Clamp(math.floor(value.RepeatCount), 1, 1000000)
			end
			if type(value.TotalCount) == "number" and value.TotalCount == value.TotalCount then
				total = math.Clamp(math.floor(value.TotalCount), 1, 1000000)
			end
		end
	end
	return lifetime, count, total
end
