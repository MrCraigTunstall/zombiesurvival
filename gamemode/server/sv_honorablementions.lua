function GM:CacheHonorableMentions()
	if self.CachedHMs then return end
	local leaders = self:BuildHonorableMentionLeaders()
	self.CachedHMs = leaders or {}
	if not leaders then
		for id, mention in ipairs(self.HonorableMentions) do
			if mention.GetPlayer then
				local pl, magnitude = mention.GetPlayer(self)
				if pl then self.CachedHMs[id] = {pl, id, magnitude or 0} end
			end
		end
	end
	gamemode.Call("PostDoHonorableMentions")
end

function GM:DoHonorableMentions(filter)
	self:CacheHonorableMentions()
	if not filter then
		filter = {}
		for _, pl in player.Iterator() do if not pl:IsBot() then filter[#filter + 1] = pl end end
		if #filter == 0 then return end
	elseif IsValid(filter) and filter:IsPlayer() and filter:IsBot() then return end
	local mentions, seen = {}, {}
	for _, tab in pairs(self.CachedHMs) do
		local id = tab[2]
		if IsValid(tab[1]) and tab[1]:IsPlayer() and type(id) == "number" and id >= 1 and id <= 255 and id == math.floor(id) and not seen[id] then
			seen[id] = true
			mentions[#mentions + 1] = tab
		end
	end
	net.Start("zs_honmention")
	net.WriteUInt(#mentions, 8)
	for _, tab in ipairs(mentions) do
		net.WriteEntity(tab[1]) net.WriteUInt(tab[2], 8) net.WriteInt(tab[3], 32)
	end
	net.Send(filter)
end

function GM:PostDoHonorableMentions()
end
