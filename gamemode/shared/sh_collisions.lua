ZSTemporaryCollisions = ZSTemporaryCollisions or {players = {}, props = {}}
local state = ZSTemporaryCollisions
local nextcheck = 0

local playerCollisionRule, playerMeta, playerTeam, entityValid, entityTable, playerGhost
local binding = GM.ZSPlayerCollisionBinding
if binding then
	playerCollisionRule, playerMeta, playerTeam, entityValid, entityTable, playerGhost = binding.rule, binding.meta, binding.team, binding.valid, binding.getTable, binding.getBool
end
local entityMeta = getmetatable
local escapeCollisionRule = GM.ZSEscapeCollisionRule
function GM:BindZombieEscapeCollisionRule(rule)
	escapeCollisionRule = rule
	self.ZSEscapeCollisionRule = rule
end
function GM:BindPlayerCollisionRule(rule, meta, team, valid, getTable, getBool)
	playerCollisionRule, playerMeta, playerTeam, entityValid, entityTable, playerGhost = rule, meta, team, valid, getTable, getBool
	self.ZSPlayerCollisionBinding = {rule = rule, meta = meta, team = team, valid = valid, getTable = getTable, getBool = getBool}
end

function GM:ShouldCollide(enta, entb)
	local metaA = entityMeta(enta)
	if playerMeta and metaA == playerMeta then
		local metaB = entityMeta(entb)
		local playerPair = metaB == playerMeta
		if playerCollisionRule and playerPair and playerMeta.ShouldNotCollide == playerCollisionRule and entityValid(entb) then
			return not (playerTeam(enta) == playerTeam(entb) or entityTable(enta).NoCollideAll or entityTable(entb).NoCollideAll)
		end
		if playerCollisionRule and playerGhost and not playerPair and playerMeta.ShouldNotCollide == playerCollisionRule then
			if playerGhost(enta, 0) and entityValid(entb) and entb:IsBarricadeProp() then return false end
		else
			local rule = enta.ShouldNotCollide
			if rule and rule(enta, entb) then return false end
		end
	else
		local rule = enta.ShouldNotCollide
		if rule and rule(enta, entb) then return false end
	end
	local rule = entb.ShouldNotCollide
	if playerCollisionRule and playerGhost and rule == playerCollisionRule and entityMeta(enta) ~= playerMeta then
		if playerGhost(entb, 0) and entityValid(enta) and enta:IsBarricadeProp() then return false end
	elseif rule and rule(entb, enta) then return false end
	if escapeCollisionRule and not (playerMeta and entityMeta(enta) == playerMeta and entityMeta(entb) == playerMeta) then
		local collide = escapeCollisionRule(enta, entb)
		if collide ~= nil then return collide end
	end
	return true
end

local movementCollisionRule = GM.ShouldCollide

function GM:GetGhostMovementFilter(pl, target, cache, force)
	local collisionHooks = hook.GetTable().ShouldCollide
	if not force and self.ShouldCollide == movementCollisionRule and playerMeta and entityMeta(pl) == playerMeta
		and playerMeta.ShouldNotCollide == playerCollisionRule and (not collisionHooks or next(collisionHooks) == nil) then
		local teamid, all = playerTeam(pl), entityTable(pl).NoCollideAll
		local key = all and "all" or teamid
		local entry = cache[key]
		if not entry then entry = {filter = {}} cache[key] = entry end
		if entry.epoch ~= cache.epoch or entry.target ~= target then
			entry.epoch, entry.target = cache.epoch, target
			local filter, count = entry.filter, 1
			filter[1] = target
			for _, other in player.Iterator() do
				if entityValid(other) and (all or playerTeam(other) == teamid or entityTable(other).NoCollideAll) then
					count = count + 1 filter[count] = other
				end
			end
			for index = count + 1, #filter do filter[index] = nil end
		end
		return entry.filter
	end
	cache.actor, cache.target = pl, target
	if not cache.fallback then
		cache.fallback = function(other)
			local actor = cache.actor
			return IsValid(actor) and other ~= actor and other ~= cache.target and hook.Run("ShouldCollide", actor, other) ~= false
		end
	end
	return cache.fallback
end

function GM:HasTemporaryCollisionOverlap(ent, prop)
	for _, other in ipairs(ents.FindInBox(ent:WorldSpaceAABB())) do
		if IsValid(other) and other ~= ent and other:IsPlayer() then
			if prop and other:Alive() and self:PlayerHullIntersectsBarricadeEntity(other, ent) or not prop and self:ShouldCollide(ent, other) then return true end
		end
	end
	return false
end

function GM:TrackTemporaryCollision(ent, prop)
	(prop and state.props or state.players)[ent] = true
end

function GM:StopTemporaryCollision(ent, prop)
	(prop and state.props or state.players)[ent] = nil
end

hook.Add("EntityRemoved", "ZSTemporaryCollisions", function(ent)
	state.players[ent], state.props[ent] = nil, nil
end)

hook.Add("Think", "ZSTemporaryCollisions", function()
	if next(state.players) == nil and next(state.props) == nil then return end
	local now = CurTime()
	if now < nextcheck then return end
	nextcheck = now + 0.1
	for ent in pairs(state.players) do
		if not IsValid(ent) or ent:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS_TRIGGER then
			state.players[ent] = nil
		elseif not GAMEMODE:HasTemporaryCollisionOverlap(ent, false) then
			state.players[ent] = nil
			ent:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		end
	end
	for ent in pairs(state.props) do
		if not IsValid(ent) or not ent.IsBarricadeObject then
			state.props[ent] = nil
		elseif not GAMEMODE:HasTemporaryCollisionOverlap(ent, true) then
			GAMEMODE:SetTemporaryBarricadeGhostEligibility(ent, false)
			state.props[ent] = nil
		end
	end
end)
