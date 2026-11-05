local state = GM.ZSReturnState or {sight = {}, stomach = {}, infections = {}}
GM.ZSReturnState = state
local unit, belly = Vector(1, 1, 1), Vector(1.15, 1.3, 1.3)
local equipment = {prop_arsenalcrate = true, prop_resupplybox = true, prop_gunturret = true}
util.AddNetworkString("zs_return_effect")

local function Human(pl)
	return IsValid(pl) and pl:IsPlayer() and pl:Alive() and pl:Team() == TEAM_HUMAN
end

local function Zombie(ent)
	return IsValid(ent) and ent:IsPlayer() and ent:Alive() and ent:Team() == TEAM_UNDEAD and not ent:GetZombieClassTable().NeverAlive
end

local function Melee(attacker, inflictor, damage)
	return Zombie(attacker) and IsValid(inflictor) and inflictor.IsMelee
		and bit.band(damage:GetDamageType(), bit.bor(DMG_SLASH, DMG_CLUB)) ~= 0
end

function GM:ApplyReturnBones(pl)
	if pl.ZSReturnBelly then
		local count = pl:GetBoneCount()
		if count and pl.ZSReturnBelly < count then pl:ManipulateBoneScale(pl.ZSReturnBelly, unit) end
	end
	pl.ZSReturnBelly, pl.ZSReturnBellyModel = nil, nil
	if pl:Team() ~= TEAM_HUMAN or not (pl.ZSReturns and pl.ZSReturns.obese) then return end
	local bone = pl:LookupBone("ValveBiped.Bip01_Spine1") or pl:LookupBone("ValveBiped.Bip01_Spine")
	if bone then pl.ZSReturnBelly = bone; pl:ManipulateBoneScale(bone, belly) end
end

function GM:SetPlayerReturn(pl, flag)
	if not IsValid(pl) or not pl:IsPlayer() or not self.ReturnLookup[flag] then return false end
	pl.ZSReturns = pl.ZSReturns or {}
	if pl.ZSReturns[flag] then return true end
	pl.ZSReturns[flag] = true
	if flag == "inexperienced" or flag == "obese" then
		pl:SetNW2Bool("zs_return_" .. flag, true)
	end
	if flag == "obese" then self:ApplyReturnBones(pl); pl:ResetSpeed() end
	if flag == "weakheart" or flag == "nightmares" then state.sight[pl] = state.sight[pl] or setmetatable({}, {__mode = "k"}) end
	if flag == "weakstomach" then state.stomach[pl] = true end
	return true
end

function GM:ResetPlayerReturns(pl)
	local obese = pl.ZSReturns and pl.ZSReturns.obese
	pl.ZSReturns = nil
	pl.ZSReturnNextEffect, pl.ZSReturnNextAccident, pl.ZSReturnNextVomit = nil, nil, nil
	state.sight[pl], state.stomach[pl], state.infections[pl] = nil, nil, nil
	for _, flag in ipairs({"inexperienced", "obese"}) do
		local key = "zs_return_" .. flag
		if pl:GetNW2Bool(key, false) then pl:SetNW2Bool(key, false) end
	end
	self:ApplyReturnBones(pl)
	if obese then pl:ResetSpeed() end
end

function GM:ReturnEffect(pl, strength, duration)
	if not Human(pl) or pl:IsBot() then return end
	pl:ViewPunch(Angle(-strength * 2, math.Rand(-strength, strength), strength))
	net.Start("zs_return_effect"); net.WriteUInt(strength, 2); net.WriteFloat(duration); net.Send(pl)
end

function GM:ApplyReturnDamage(pl, damage)
	local flags = pl.ZSReturns
	if not flags or not Human(pl) or damage:GetDamage() <= 0 then return end
	if flags.weakling then damage:ScaleDamage(1.4) end
	local attacker, inflictor = damage:GetAttacker(), damage:GetInflictor()
	if not Zombie(attacker) then return end
	if flags.punchbag and Melee(attacker, inflictor, damage) then damage:ScaleDamage(1.2) end
	if flags.careless then
		local origin, count = pl:GetPos(), 0
		for _, other in player.Iterator() do
			if IsValid(other) and other:IsPlayer() and other:Alive() and other:Team() == TEAM_UNDEAD
			and origin:DistToSqr(other:GetPos()) <= 192 * 192 and not other:GetZombieClassTable().NeverAlive then
				count = count + 1
				if count == 2 then damage:ScaleDamage(1.25); break end
			end
		end
	end
end

local function AfterDamage(pl, damage, taken)
	local flags = pl.ZSReturns
	if not taken or not flags or not IsValid(pl) or not pl:IsPlayer() or pl:Team() ~= TEAM_HUMAN or damage:GetDamage() <= 0 then return end
	local attacker, inflictor = damage:GetAttacker(), damage:GetInflictor()
	if not Zombie(attacker) then return end
	local now = CurTime()
	if flags.fleshytreat then
		local health, maximum = attacker:Health(), attacker:GetMaxZombieHealth()
		if health < maximum then attacker:SetHealth(math.min(maximum, health + math.min(5, math.ceil(damage:GetDamage() * 0.1)))) end
	end
	if not pl:Alive() then return end
	if flags.hallucinations and now >= (pl.ZSReturnNextEffect or 0) and math.random(100) <= 20 then
		pl.ZSReturnNextEffect = now + 2; GAMEMODE:ReturnEffect(pl, 3, 4)
	end
	if flags.weakbody and math.random(100) <= 20 then
		local infection = state.infections[pl]
		if infection then infection.remaining = 6 else infection = {remaining = 6, nextTick = now + 1}; state.infections[pl] = infection end
		state.nextInfection = math.min(state.nextInfection or infection.nextTick, infection.nextTick)
	end
end
hook.Add("PostEntityTakeDamage", "ZSReturns", AfterDamage)

function GM:ReturnEquipmentRisk(pl, ent, heavy)
	if not Human(pl) or not (pl.ZSReturns and pl.ZSReturns.unlucky) or not IsValid(ent) then return end
	if not equipment[ent:GetClass()] then
		if not heavy then return end
		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) or phys:GetMass() < 40 then return end
	end
	local now = CurTime()
	if now < (pl.ZSReturnNextAccident or 0) then return end
	pl.ZSReturnNextAccident = now + 1
	if math.random(100) <= 5 then pl:TakeSpecialDamage(3, DMG_GENERIC, pl, pl, pl:WorldSpaceCenter()) end
end
hook.Add("ObjectPackedUp", "ZSReturns", function(ent, packer) GAMEMODE:ReturnEquipmentRisk(packer, ent) end)

function GM:ReturnZombieGib(zombie, origin)
	if not IsValid(zombie) or zombie:Team() ~= TEAM_UNDEAD or next(state.stomach) == nil then return end
	local now = CurTime()
	for pl in pairs(state.stomach) do
		if not Human(pl) or not (pl.ZSReturns and pl.ZSReturns.weakstomach) then
			state.stomach[pl] = nil
		elseif now >= (pl.ZSReturnNextVomit or 0) and pl:GetPos():DistToSqr(origin) <= 256 * 256 then
			pl.ZSReturnNextVomit = now + 5
			if math.random(100) <= 25 then
				self:ReturnEffect(pl, 2, 2); pl:EmitSound("player/pl_pain7.wav", 60, 90)
				pl:TakeSpecialDamage(3, DMG_GENERIC, pl, pl, origin)
			end
		end
	end
end

function GM:ReturnSightVisible(pl, boss)
	local start, target = pl:EyePos(), boss:WorldSpaceCenter()
	local delta = target - start
	local distance = delta:LengthSqr()
	if distance > 1024 * 1024 then return false end
	local fov = pl:GetFOV(); if fov <= 0 then fov = 90 end
	if distance > 0 and pl:GetAimVector():Dot(delta) < math.sqrt(distance) * math.cos(math.rad(math.Clamp(fov, 1, 179) * 0.5)) then return false end
	local trace = state.sightTrace or {}; state.sightTrace = trace
	trace.start, trace.endpos, trace.mask, trace.filter = start, target, MASK_VISIBLE, pl
	local result = util.TraceLine(trace)
	return not result.StartSolid and (not result.Hit or result.Entity == boss)
end

function GM:UpdatePlayerReturns(now)
	if now >= (state.nextInfection or 0) then
		local deadline = math.huge
		for pl, infection in pairs(state.infections) do
			if not Human(pl) or not (pl.ZSReturns and pl.ZSReturns.weakbody) then state.infections[pl] = nil
			elseif now >= infection.nextTick then
				infection.nextTick = now + 1; infection.remaining = infection.remaining - 1
				if infection.remaining <= 0 then state.infections[pl] = nil end
				pl:TakeSpecialDamage(1, DMG_POISON, pl, pl, pl:WorldSpaceCenter())
			end
			if state.infections[pl] then deadline = math.min(deadline, infection.nextTick) end
		end
		state.nextInfection = deadline
	end
	if next(state.sight) == nil or now < (state.nextSight or 0) then return end
	state.nextSight = now + 0.25
	local bosses = state.bosses or {}; state.bosses = bosses; table.Empty(bosses)
	for _, candidate in player.Iterator() do
		if Zombie(candidate) and candidate:GetZombieClassTable().Boss then bosses[#bosses + 1] = candidate end
	end
	for pl, seen in pairs(state.sight) do
		local flags = pl.ZSReturns
		if not Human(pl) or not flags or not (flags.weakheart or flags.nightmares) then state.sight[pl] = nil
		else
			for _, boss in ipairs(bosses) do
				local life = boss.SpawnedTime or 0
				if seen[boss] ~= life and self:ReturnSightVisible(pl, boss) then
					seen[boss] = life
					if flags.nightmares then self:ReturnEffect(pl, 1, 2) end
					if flags.weakheart and math.random(100) <= 5 then
						pl:TakeSpecialDamage(pl:Health() * 2 + 100, DMG_GENERIC, boss, boss, pl:WorldSpaceCenter()); break
					end
				end
			end
		end
	end
end
hook.Add("Think", "ZSReturns", function()
	if next(state.infections) ~= nil or next(state.sight) ~= nil then GAMEMODE:UpdatePlayerReturns(CurTime()) end
end)

local function ClearLife(pl)
	state.infections[pl], state.sight[pl], state.stomach[pl] = nil, nil, nil
	pl.ZSReturnNextEffect, pl.ZSReturnNextAccident, pl.ZSReturnNextVomit = nil, nil, nil
end
local function RegisterLife(pl)
	ClearLife(pl)
	local flags = pl.ZSReturns
	if pl:Team() ~= TEAM_HUMAN or not flags then return end
	if flags.weakheart or flags.nightmares then state.sight[pl] = setmetatable({}, {__mode = "k"}) end
	if flags.weakstomach then state.stomach[pl] = true end
end
hook.Add("PlayerSpawn", "ZSReturns", RegisterLife)
hook.Add("OnPlayerChangedTeam", "ZSReturns", function(pl) RegisterLife(pl); GAMEMODE:ApplyReturnBones(pl) end)
hook.Add("PlayerDeath", "ZSReturns", ClearLife)
hook.Add("PlayerDisconnected", "ZSReturns", function(pl) ClearLife(pl); pl.ZSReturns = nil end)
for _, pl in player.Iterator() do RegisterLife(pl) end
