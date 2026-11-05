local meta = FindMetaTable("Player")

local function NotifyDenied(self, reason, field, key, prefix)
	if self:IsBot() then return false end
	local now = CurTime()
	local warning = self[field]
	if not warning or warning.reason ~= reason or now - warning.time > 3 then
		warning = {reason = reason, count = 0}
		self[field] = warning
	end
	warning.count = math.min(1000000, warning.count + 1)
	warning.time = now
	local message = translate.ClientGet(self, prefix or reason)
	if prefix and reason and reason ~= prefix then message = message .. ": " .. translate.ClientGet(self, reason) end
	self:CenterNotify(COLOR_RED, message, {NotificationKey = key .. tostring(reason), TotalCount = warning.count, CustomTime = 4})
	return false
end

function meta:NotifyNailDenied(reason)
	return NotifyDenied(self, reason, "ZSNailWarning", "nail:", "nail_cannot_place")
end

function meta:NotifyNailRemovalDenied(reason)
	return NotifyDenied(self, reason, "ZSNailRemovalWarning", "nailremove:")
end

function meta:ClearNailWarning()
	self.ZSNailWarning = nil
end

function meta:ClearNailRemovalWarning()
	self.ZSNailRemovalWarning = nil
end
