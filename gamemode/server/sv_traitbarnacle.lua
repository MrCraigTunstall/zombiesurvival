local state = GM.ZSTraitBarnacles or {entities = {}, owners = setmetatable({}, {__mode = "k"}), count = 0}
GM.ZSTraitBarnacles = state
state.columns = state.columns or {}
state.exposed = state.exposed or setmetatable({}, {__mode = "k"})
local function Owner(gm, pl)
	return not gm.RoundEnded and IsValid(pl) and pl:IsPlayer() and pl:Alive() and gm:HasPlayerTrait(pl, "tonguelover")
end
local function Prey(pl, includeProtected)
	return IsValid(pl) and pl:IsPlayer() and pl:Alive() and pl:Team() == TEAM_UNDEAD and not pl:GetZombieClassTable().NeverAlive and (includeProtected or not pl.SpawnProtection)
end
local function Relation(ent, pl)
	ent:AddEntityRelationship(pl, Prey(pl, true) and D_HT or D_LI, 99)
end
local function HumanSource(source)
	if not IsValid(source) then return false end
	if source:IsPlayer() then return source:Team() == TEAM_HUMAN end
	local holder = source.ZSMolotovOwner or source.LastDamagedBy or (source.GetObjectOwner and source:GetObjectOwner() or source:GetOwner())
	if not IsValid(holder) and source.GetPhysicsAttacker then holder = source:GetPhysicsAttacker() end
	return IsValid(holder) and holder:IsPlayer() and holder:Team() == TEAM_HUMAN
end
function GM:GiveTraitBarnacleWeapon(pl)
	if not Owner(self, pl) then return false, nil, false end
	if pl.ZSTraitBarnacleGrantBusy then return false, nil, false end
	local class = "weapon_zs_barnacle"
	local weapon = pl:GetWeapon(class)
	if not IsValid(weapon) then
		local pending = pl.ZSTraitBarnacleGrantPending
		if IsValid(pending) then return false, nil, pending:IsWeapon() and pending:GetClass() == class and pending:IsMarkedForDeletion() and not IsValid(pending:GetOwner()) end
		pl.ZSTraitBarnacleGrantPending = nil
		local claims, life, spawned = self.CheckedOut, pl.ZSWorthLife, pl.SpawnedTime
		pl.ZSTraitBarnacleGrantBusy = true
		local ok, returned = pcall(pl.Give, pl, class)
		if IsValid(pl) then pl.ZSTraitBarnacleGrantBusy = nil end
		if not ok then error(returned, 0) end
		if not Owner(self, pl) or claims ~= self.CheckedOut or life ~= pl.ZSWorthLife or spawned ~= pl.SpawnedTime then return false, nil, false end
		weapon = pl:GetWeapon(class)
		if not IsValid(weapon) or not weapon:IsWeapon() or weapon:GetClass() ~= class or weapon:IsMarkedForDeletion() or weapon:GetOwner() ~= pl then
			if IsValid(weapon) then return false, nil, false end
			local recoverable = not IsValid(returned) or returned:IsWeapon() and returned:GetClass() == class and returned:IsMarkedForDeletion() and not IsValid(returned:GetOwner())
			if recoverable and IsValid(returned) then pl.ZSTraitBarnacleGrantPending = returned end
			return false, nil, recoverable
		end
		if IsValid(returned) and returned ~= weapon then return false, nil, false end
	end
	if not weapon:IsWeapon() or weapon:GetClass() ~= class or weapon:IsMarkedForDeletion() or weapon:GetOwner() ~= pl then return false, nil, false end
	pl.ZSTraitBarnacleGrantPending = nil
	return true
end
function GM:RemoveTraitBarnacles(pl)
	local owned = state.owners[pl]
	if owned then
		for ent in pairs(owned) do
			if IsValid(ent) then
				if IsValid(ent:GetEnemy()) then ent:Input("LetGo") end
				ent:Remove()
			end
		end
	end
	pl.ZSTraitBarnacleNext = nil
end
function GM:PlaceTraitBarnacle(pl, weapon)
	if not Owner(self, pl) or pl:GetBarricadeGhosting() or pl:IsHolding() or not IsValid(weapon)
		or weapon:GetClass() ~= "weapon_zs_barnacle" or weapon:GetOwner() ~= pl or pl:GetActiveWeapon() ~= weapon then return false, "unavailable" end
	local now = CurTime()
	if now < (pl.ZSTraitBarnacleNext or 0) then return false, "cooldown" end
	local owned = state.owners[pl]
	local count = 0
	if owned then for ent in pairs(owned) do if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:Health() > 0 then count = count + 1 end end end
	if count >= 2 or state.count >= 128 then return false, "limit" end
	local start = pl:GetShootPos()
	local hit = util.TraceLine({start = start, endpos = start + pl:GetAimVector() * 512, mask = MASK_SOLID, filter = pl})
	if not hit.Hit or not hit.HitWorld or hit.HitSky or hit.StartSolid or hit.AllSolid or hit.HitNormal.z > -0.9 then return false, "ceiling" end
	local position = hit.HitPos + hit.HitNormal * 2
	local body = util.TraceHull({start = position - Vector(0, 0, 22), endpos = position - Vector(0, 0, 22), mins = Vector(-17, -17, -20), maxs = Vector(17, 17, 20), mask = MASK_SOLID, filter = pl})
	if body.Hit or body.StartSolid or body.AllSolid then return false, "blocked" end
	local floor = util.TraceLine({start = position - Vector(0, 0, 42), endpos = position - Vector(0, 0, 114), mask = MASK_SOLID, filter = pl})
	if floor.Hit or floor.StartSolid or floor.AllSolid then return false, "clearance" end
	local ent = ents.Create("npc_barnacle")
	if not IsValid(ent) then return false, "failed" end
	ent.ZSTraitBarnacleOwner = pl
	ent:SetOwner(pl)
	ent:SetPos(position)
	ent:SetKeyValue("OnGrab", "!self,ZSTraitBarnacleGrab,,0,-1")
	ent:Spawn()
	ent:Activate()
	ent:SetHealth(200)
	ent:SetMaxHealth(200)
	for _, candidate in player.Iterator() do Relation(ent, candidate) end
	owned = owned or {}
	state.owners[pl], owned[ent], state.entities[ent] = owned, true, pl
	state.count = state.count + 1
	local cx, cy = math.floor(position.x / 64), math.floor(position.y / 64)
	local row = state.columns[cx] or {}
	state.columns[cx] = row
	local column = row[cy] or {}
	row[cy] = column
	column[ent] = position
	ent.ZSTraitBarnacleCellX, ent.ZSTraitBarnacleCellY = cx, cy
	pl.ZSTraitBarnacleNext = now + 30
	weapon:SetNextPrimaryFire(now + 30)
	ent:SetNW2Entity("zs_barnacle_owner", pl)
	return true, ent
end
hook.Add("AcceptInput", "ZSTraitBarnacles", function(ent, name)
	if name ~= "ZSTraitBarnacleGrab" or not state.entities[ent] then return end
	if not Owner(GAMEMODE, state.entities[ent]) or not Prey(ent:GetEnemy()) then ent:Fire("LetGo", "", 0) end
	return true
end)
hook.Add("EntityTakeDamage", "ZSTraitBarnacles", function(ent, damage)
	local attacker, inflictor = damage:GetAttacker(), damage:GetInflictor()
	local owner = state.entities[ent]
	if owner then
		if HumanSource(attacker) or not (IsValid(attacker) and attacker:IsPlayer()) and HumanSource(inflictor) then damage:SetDamage(0) return true end
		local kind = damage:GetDamageType()
		if bit.band(kind, DMG_CLUB) ~= 0 then damage:SetDamageType(bit.bor(bit.band(kind, bit.bnot(DMG_CLUB)), DMG_SLASH)) end
		damage:ScaleDamage(0.5)
	elseif state.entities[inflictor] or state.entities[attacker] then
		local source = state.entities[inflictor] and inflictor or attacker
		local pilot = state.entities[source]
		if attacker == pilot then return end
		if not Owner(GAMEMODE, pilot) or not Prey(ent) then damage:SetDamage(0) source:Fire("LetGo", "", 0) return true end
		local amount, kind = damage:GetDamage() * 2, damage:GetDamageType()
		local position, force = damage:GetDamagePosition(), damage:GetDamageForce()
		local px, py, pz, fx, fy, fz = position.x, position.y, position.z, force.x, force.y, force.z
		damage:SetDamage(0)
		if amount > 0 then
			timer.Simple(0, function()
				if not IsValid(source) or source:IsMarkedForDeletion() or source:Health() <= 0 or state.entities[source] ~= pilot or not Owner(GAMEMODE, pilot) or not Prey(ent) then return end
				local hit = DamageInfo()
				hit:SetDamage(amount)
				hit:SetDamageType(kind)
				hit:SetAttacker(pilot)
				hit:SetInflictor(source)
				hit:SetDamagePosition(Vector(px, py, pz))
				hit:SetDamageForce(Vector(fx, fy, fz))
				ent:TakeDamageInfo(hit)
			end)
		end
		return true
	end
end)
hook.Add("EntityRemoved", "ZSTraitBarnacles", function(ent)
	local pl = state.entities[ent]
	if not pl then return end
	state.entities[ent] = nil
	state.count = math.max(0, state.count - 1)
	local cx, cy = ent.ZSTraitBarnacleCellX, ent.ZSTraitBarnacleCellY
	local row = cx and state.columns[cx]
	local column = row and row[cy]
	if column then column[ent] = nil if not next(column) then row[cy] = nil end if not next(row) then state.columns[cx] = nil end end
	local owned = state.owners[pl]
	if owned then owned[ent] = nil if not next(owned) then state.owners[pl] = nil end end
end)
local function RestoreTarget(pl, previous)
	GAMEMODE:ReleaseNPCTargetAccess(pl, state)
	state.exposed[pl] = nil
end
if not state.sharedTargetAccess then
	for pl, previous in pairs(state.exposed) do
		if GM:AcquireNPCTargetAccess(pl, state, previous) then state.exposed[pl] = true
		else
			if IsValid(pl) and pl:Team() == TEAM_UNDEAD then pl:SetNoTarget(previous) end
			state.exposed[pl] = nil
		end
	end
	state.sharedTargetAccess = true
end
timer.Create("ZSTraitBarnacleTargets", 0.25, 0, function()
	if state.count == 0 then
		for pl, previous in pairs(state.exposed) do RestoreTarget(pl, previous) end
		return
	end
	for _, pl in player.Iterator() do
		local near = false
		if Prey(pl, true) then
			local position = pl:GetPos()
			local cx, cy = math.floor(position.x / 64), math.floor(position.y / 64)
			for x = cx - 1, cx + 1 do
				local row = state.columns[x]
				if row then
					for y = cy - 1, cy + 1 do
						local column = row[y]
						if column then
							for ent, root in pairs(column) do
								if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:Health() > 0 and math.abs(position.x - root.x) <= 32 and math.abs(position.y - root.y) <= 32 and position.z <= root.z and position.z >= root.z - 2112 then near = true break end
							end
						end
						if near then break end
					end
				end
				if near then break end
			end
		end
		if near then
			if GAMEMODE:AcquireNPCTargetAccess(pl, state) then state.exposed[pl] = true end
		elseif state.exposed[pl] ~= nil then RestoreTarget(pl, state.exposed[pl]) end
	end
end)
local function Changed(pl)
	if not Owner(GAMEMODE, pl) then GAMEMODE:RemoveTraitBarnacles(pl) end
	for ent in pairs(state.entities) do
		if IsValid(ent) then
			Relation(ent, pl)
			if ent:GetEnemy() == pl and not Prey(pl) then ent:Fire("LetGo", "", 0) end
		end
	end
end
hook.Add("OnPlayerChangedTeam", "ZSTraitBarnacles", Changed)
hook.Add("PlayerDeath", "ZSTraitBarnacles", Changed)
hook.Add("PlayerDisconnected", "ZSTraitBarnacles", function(pl) GAMEMODE:RemoveTraitBarnacles(pl) end)
hook.Add("PlayerSpawn", "ZSTraitBarnacles", function(pl)
	timer.Simple(0, function() if IsValid(pl) then Changed(pl) GAMEMODE:GiveTraitBarnacleWeapon(pl) end end)
end)
timer.Create("ZSTraitBarnacleOwners", 0.5, 0, function()
	for ent, pl in pairs(state.entities) do
		if IsValid(ent) then
			if not Owner(GAMEMODE, pl) or ent:Health() <= 0 then
				if IsValid(ent:GetEnemy()) then ent:Input("LetGo") end
				ent:Remove()
			else
				local enemy = ent:GetEnemy()
				if IsValid(enemy) and not Prey(enemy) then ent:Fire("LetGo", "", 0) end
			end
		end
	end
end)
