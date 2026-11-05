player.ZSPlayerList = player.ZSPlayerList or {NativeGetAll = player.GetAll}
local nativeGetAll = player.ZSPlayerList.NativeGetAll

if player.Iterator then
	local iterator = player.Iterator
	local buildingCache = false
	function player.GetAll()
		if buildingCache then return nativeGetAll() end
		buildingCache = true
		local _, players = iterator()
		buildingCache = false
		local snapshot = {}
		for i = 1, #players do snapshot[i] = players[i] end
		return snapshot
	end
else
	player.GetAll = nativeGetAll
	function player.Iterator() return ipairs(nativeGetAll()) end
end

if not player.GetCount then
	function player.GetCount() return #nativeGetAll() end
end

if not player.GetRandom or player.GetRandom == player.ZSPlayerList.RandomFunction then
	local iterator, snapshot, random, count, traverse = player.Iterator, player.GetAll, table.Random, table.Count, pairs
	local stock = type(iterator) == "function" and type(random) == "function" and type(count) == "function"
		and debug.getinfo(iterator, "S").source == "@lua/includes/extensions/entity_iter.lua"
		and debug.getinfo(random, "S").source == "@lua/includes/extensions/table.lua"
		and debug.getinfo(count, "S").source == "@lua/includes/extensions/table.lua"
	function player.GetRandom()
		if stock and player.Iterator == iterator and player.GetAll == snapshot and table.Random == random and table.Count == count and pairs == traverse then
			local _, players = iterator()
			local size = #players
			if size == 0 then return nil, nil end
			local index = math.random(1, size)
			return players[index], index
		end
		local players = player.GetAll()
		if next(players) == nil then return nil, nil end
		return table.Random(players)
	end
	player.ZSPlayerList.RandomFunction = player.GetRandom
end

function GM:IsPlayerWithinSphere(pl, position, radius)
	local minimum, maximum = pl:WorldSpaceAABB()
	return util.IsBoxIntersectingSphere(minimum, maximum, position, radius)
end
