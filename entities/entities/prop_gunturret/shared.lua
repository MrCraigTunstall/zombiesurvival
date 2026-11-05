ENT.Type = "anim"
ENT.TraitCombine = true
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.SearchDistance = 768
ENT.MinimumAimDot = 0.5
ENT.DefaultAmmo = 0 --250
ENT.MaxAmmo = 1000

ENT.NoReviveFromKills = true

ENT.PosePitch = 0
ENT.PoseYaw = 0

ENT.m_NoNailUnfreeze = true
ENT.NoNails = true

ENT.CanPackUp = true

ENT.IsBarricadeObject = true
ENT.AlwaysGhostable = true

local nextCandidates = 0
local candidates = {}
local candidatePool = {}

local function CandidateOrder(a, b)
	return a.distance < b.distance or a.distance == b.distance and a.index < b.index
end

local function SiftTarget(ranked, index, count)
	local rank = ranked[index]
	while index * 2 <= count do
		local child = index * 2
		if child < count and CandidateOrder(ranked[child + 1], ranked[child]) then child = child + 1 end
		if not CandidateOrder(ranked[child], rank) then break end
		ranked[index] = ranked[child]
		index = child
	end
	ranked[index] = rank
end

function ENT:GetLocalAnglesToTarget(target)
	return self:WorldToLocalAngles(self:GetAnglesToTarget(target))
end

function ENT:GetAnglesToTarget(target)
	return self:GetAnglesToPos(self:GetTargetPos(target))
end

function ENT:GetLocalAnglesToPos(pos)
	return self:WorldToLocalAngles(self:GetAnglesToPos(pos))
end

function ENT:GetAnglesToPos(pos)
	return (pos - self:ShootPos()):Angle()
end

function ENT:IsValidTarget(target)
	if not IsValid(target) or not target:IsPlayer() or target:Team() ~= TEAM_UNDEAD or not target:Alive() then return false end
	local shootpos, targetpos = self:ShootPos(), self:GetTargetPos(target)
	local delta = targetpos - shootpos
	return delta:LengthSqr() <= self.SearchDistance * self.SearchDistance and self:GetForward():Dot(delta:GetNormalized()) >= self.MinimumAimDot
		and TrueVisible(shootpos, targetpos, self)
end

function ENT:SearchNearestTarget()
	local now = CurTime()
	if now >= nextCandidates then
		nextCandidates = now + 0.1
		local count = 0
		for _, pl in player.Iterator() do
			if pl:Team() == TEAM_UNDEAD and pl:Alive() then
				count = count + 1
				local entry = candidatePool[count]
				if not entry then entry = {}; candidatePool[count] = entry end
				entry.player, entry.position, entry.index = pl, self:GetTargetPos(pl), pl:EntIndex()
				candidates[count] = entry
			end
		end
		for index = #candidates, count + 1, -1 do candidates[index] = nil end
		for index = count + 1, #candidatePool do candidatePool[index].player, candidatePool[index].position = nil, nil end
	end
	local shootpos, forward, limit = self:ShootPos(), self:GetForward(), self.SearchDistance * self.SearchDistance
	local ranked, pool = self.ZSTargetRanking or {}, self.ZSTargetPool or {}
	self.ZSTargetRanking, self.ZSTargetPool = ranked, pool
	local count = 0
	for _, entry in ipairs(candidates) do
		local pl = entry.player
		if IsValid(pl) and pl:Team() == TEAM_UNDEAD and pl:Alive() then
			local delta = entry.position - shootpos
			local distance = delta:LengthSqr()
			if distance <= limit then
				delta:Normalize()
				if forward:Dot(delta) >= self.MinimumAimDot then
					count = count + 1
					local rank = pool[count]
					if not rank then rank = {}; pool[count] = rank end
					rank.player, rank.position, rank.index, rank.distance = pl, entry.position, entry.index, distance
					ranked[count] = rank
				end
			end
		end
	end
	for index = #ranked, count + 1, -1 do ranked[index] = nil end
	for index = count + 1, #pool do pool[index].player, pool[index].position = nil, nil end
	for index = math.floor(count / 2), 1, -1 do SiftTarget(ranked, index, count) end
	while count > 0 do
		local rank = ranked[1]
		if TrueVisible(shootpos, rank.position, self) then return rank.player end
		local last = ranked[count]
		ranked[count] = nil
		count = count - 1
		if count > 0 then ranked[1] = last; SiftTarget(ranked, 1, count) end
	end
end

function ENT:GetManualTrace()
	local owner = self:GetObjectOwner()
	local filter = owner:GetMeleeFilter()
	table.insert(filter, self)
	return owner:TraceLine(4096, MASK_SOLID, filter)
end

function ENT:CalculatePoseAngles()
	local owner = self:GetObjectOwner()
	if not owner:IsValid() or self:GetAmmo() <= 0 or self:GetMaterial() ~= "" then
		self.PoseYaw = math.Approach(self.PoseYaw, 0, FrameTime() * 60)
		self.PosePitch = math.Approach(self.PosePitch, 15, FrameTime() * 30)
		return
	end

	if self:GetManualControl() then
		local ang = self:GetLocalAnglesToPos(self:GetManualTrace().HitPos)
		self.PoseYaw = math.Approach(self.PoseYaw, math.Clamp(math.NormalizeAngle(ang.yaw), -60, 60), FrameTime() * 140)
		self.PosePitch = math.Approach(self.PosePitch, math.Clamp(math.NormalizeAngle(ang.pitch), -15, 15), FrameTime() * 140)
	else
		local target = self:GetTarget()
		if target:IsValid() then
			local ang = self:GetLocalAnglesToTarget(target)
			self.PoseYaw = math.Approach(self.PoseYaw, math.Clamp(math.NormalizeAngle(ang.yaw), -60, 60), FrameTime() * 140)
			self.PosePitch = math.Approach(self.PosePitch, math.Clamp(math.NormalizeAngle(ang.pitch), -15, 15), FrameTime() * 100)
		else
			local ct = CurTime()
			self.PoseYaw = math.Approach(self.PoseYaw, math.sin(ct) * 45, FrameTime() * 60)
			self.PosePitch = math.Approach(self.PosePitch, math.cos(ct * 1.4) * 15, FrameTime() * 30)
		end
	end
end

function ENT:GetScanFilter()
	local filter = team.GetPlayers(TEAM_HUMAN)
	filter[#filter + 1] = self
	return filter
end

-- Getting all of some team is straining every frame when there's 5 or so turrets. I could probably use CONTENTS_TEAM* if I knew what they did.
function ENT:GetCachedScanFilter()
	if CurTime() < (self.NextScanFilterCache or 0) and self.CachedScanFilter then return self.CachedScanFilter end

	self.CachedScanFilter = self:GetScanFilter()
	self.NextScanFilterCache = CurTime() + 1

	return self.CachedScanFilter
end

local tabSearch = {mask = MASK_SHOT}
function ENT:SearchForTarget()
	if SERVER and GAMEMODE:HasPlayerTrait(self:GetObjectOwner(), "technicalaim") then return self:SearchNearestTarget() end
	local shootpos = self:ShootPos()

	tabSearch.start = shootpos
	tabSearch.endpos = shootpos + self:GetGunAngles():Forward() * self.SearchDistance
	tabSearch.filter = self:GetCachedScanFilter()
	local tr = util.TraceLine(tabSearch)
	local ent = tr.Entity
	if ent and ent:IsValid() and self:IsValidTarget(ent) then
		return ent
	end
end

function ENT:GetTargetPos(target)
	if not (target:IsPlayer() and target:GetZombieClassTable().NoHead) then
		local boneid = target:GetHitBoxBone(HITGROUP_HEAD, 0)
		if boneid and boneid > 0 then
			local p, a = target:GetBonePosition(boneid)
			if p then
				return p
			end
		end
	end

	return target:LocalToWorld(target:OBBCenter())
end

function ENT:HumanHoldable(pl)
	return true
end

function ENT:DefaultPos()
	return self:GetPos() + self:GetUp() * 55
end

function ENT:ShootPos()
	local attachid = self:LookupAttachment("eyes")
	if attachid then
		local attach = self:GetAttachment(attachid)
		if attach then return attach.Pos end
	end

	return self:DefaultPos()
end

function ENT:LaserPos()
	local attachid = self:LookupAttachment("light")
	if attachid then
		local attach = self:GetAttachment(attachid)
		if attach then return attach.Pos end
	end

	return self:DefaultPos()
end
ENT.LightPos = ENT.LaserPos

function ENT:GetGunAngles()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Right(), -self.PosePitch)
	ang:RotateAroundAxis(ang:Up(), self.PoseYaw)
	return ang
end

function ENT:SetAmmo(ammo)
	self:SetDTInt(0, ammo)
end

function ENT:GetAmmo()
	return self:GetDTInt(0)
end

function ENT:SetTarget(ent)
	if ent:IsValid() then
		self:SetTargetReceived(CurTime())
		if SERVER then
			self.LastHitSomething = CurTime()
		end
	else
		self:SetTargetLost(CurTime())
	end
	self:SetDTEntity(0, ent)
end

function ENT:GetObjectHealth()
	return self:GetDTFloat(3)
end

function ENT:SetMaxObjectHealth(health)
	self:SetDTInt(1, health)
end

function ENT:GetMaxObjectHealth()
	return self:GetDTInt(1)
end

function ENT:GetChannel()
	return self:GetDTInt(2)
end

function ENT:SetChannel(channel)
	self:SetDTInt(2, channel)
end

function ENT:GetTarget()
	return self:GetDTEntity(0)
end

function ENT:SetObjectOwner(ent)
	self:SetDTEntity(1, ent)
end

function ENT:GetObjectOwner()
	return self:GetDTEntity(1)
end

function ENT:ClearObjectOwner()
	self:SetObjectOwner(NULL)
end

function ENT:ClearTarget()
	self:SetTarget(NULL)
end

function ENT:SetTargetReceived(tim)
	self:SetDTFloat(0, tim)
end

function ENT:GetTargetReceived()
	return self:GetDTFloat(0)
end

function ENT:SetTargetLost(tim)
	self:SetDTFloat(1, tim)
end

function ENT:GetTargetLost()
	return self:GetDTFloat(1)
end

function ENT:SetNextFire(tim)
	self:SetDTFloat(2, tim)
end

function ENT:GetNextFire()
	return self:GetDTFloat(2)
end

function ENT:SetFiring(onoff)
	self:SetDTBool(0, onoff)
end

function ENT:IsFiring()
	return self:GetDTBool(0)
end

function ENT:GetManualControl()
	local owner = self:GetObjectOwner()
	if owner:IsValid() and owner:Alive() and owner:Team() == TEAM_HUMAN then
		local wep = owner:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "weapon_zs_gunturretcontrol" and wep.GetTurret and wep:GetTurret() == self and not wep:GetDTBool(0) then
			return true
		end
	end

	return false
end

function ENT:CanBePackedBy(pl)
	local owner = self:GetObjectOwner()
	return not owner:IsValid() or owner == pl or owner:Team() ~= TEAM_HUMAN or gamemode.Call("PlayerIsAdmin", pl)
end

util.PrecacheSound("npc/turret_floor/die.wav")
util.PrecacheSound("npc/turret_floor/active.wav")
util.PrecacheSound("npc/turret_floor/deploy.wav")
util.PrecacheSound("npc/turret_floor/shoot1.wav")
util.PrecacheSound("npc/turret_floor/shoot2.wav")
util.PrecacheSound("npc/turret_floor/shoot3.wav")
