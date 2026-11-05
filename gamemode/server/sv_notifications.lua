local pending = {}
local nextFlush = 0
local notificationKey = GM.GetNotificationKey

local function Send(pl, channel, args, count)
	if not IsValid(pl) or pl:IsBot() then return end
	if count and count > 1 then
		local counted = {}
		for key, value in pairs(args) do counted[key] = value end
		counted[#counted + 1] = {RepeatCount = count}
		args = counted
	end
	net.Start(channel)
	net.WriteTable(args)
	net.Send(pl)
end

local function Queue(pl, channel, args, key)
	local queue = pending[pl]
	if not queue then queue = {size = 0, entries = {}, order = {}}; pending[pl] = queue end
	local entry = queue.entries[key]
	if entry then
		entry.count = math.min(1000000, entry.count + 1)
		entry.args = args
	elseif queue.size < 32 then
		queue.entries[key] = {channel = channel, args = args, count = 1}
		queue.size = queue.size + 1
		queue.order[queue.size] = queue.entries[key]
	else
		Send(pl, channel, args)
	end
end

function GM:SendNotification(pl, channel, args)
	if not IsValid(pl) or pl:IsBot() then return end
	local key = self:GetNotificationKey(args)
	if not key then Send(pl, channel, args) return end
	Queue(pl, channel, table.Copy(args), channel .. ":" .. key)
end
local sendNotification = GM.SendNotification

function GM:BroadcastNotification(channel, args)
	if self.SendNotification ~= sendNotification or self.GetNotificationKey ~= notificationKey then
		for _, pl in player.Iterator() do self:SendNotification(pl, channel, args) end
		return
	end
	local prepared, payload, key = false
	for _, pl in player.Iterator() do
		if IsValid(pl) and not pl:IsBot() then
			if not prepared then
				key = notificationKey(self, args)
				if key then key, payload = channel .. ":" .. key, table.Copy(args) end
				prepared = true
			end
			if key then Queue(pl, channel, payload, key) else Send(pl, channel, args) end
		end
	end
end

hook.Add("Think", "ZSNotificationBatch", function()
	local now = CurTime()
	if now < nextFlush then return end
	nextFlush = now + 0.1
	if next(pending) == nil then return end
	local batch = pending
	pending = {}
	for pl, queue in pairs(batch) do
		for _, entry in ipairs(queue.order) do Send(pl, entry.channel, entry.args, entry.count) end
	end
end)

hook.Add("PlayerDisconnected", "ZSNotificationBatch", function(pl) pending[pl] = nil end)
