local meta = FindMetaTable("Player")
if not meta then return end

function meta:RadiusCheck(ent2, client_distance)
	if not IsValid(self) then return false end
	local hidden = false
	if type(client_distance) == "number" and client_distance > 0 and client_distance < math.huge
	and ent2 ~= self and IsValid(ent2) and ent2:IsPlayer() and self:Team() == ent2:Team() then
		local eyepos = EyePos()
		hidden = ent2:NearestPoint(eyepos):DistToSqr(eyepos) < client_distance * client_distance
	end
	self.HideModel = hidden
	return hidden
end

function meta:FloatingScore(victim, effectname, frags, flags)
	if MySelf == self then
		gamemode.Call("FloatingScore", victim, effectname, frags, flags)
	end
end

function meta:FixModelAngles(velocity)
	local eye = self:EyeAngles()
	self:SetLocalAngles(eye)
	self:SetRenderAngles(eye)
	self:SetPoseParameter("move_yaw", GAMEMODE:GetAnimationMoveYaw(velocity, eye.y))
end

function meta:RemoveAllStatus(bSilent, bInstant)
end

function meta:RemoveStatus(sType, bSilent, bInstant, sExclude)
end

function meta:GetStatus(sType)
	local ent = self["status_"..sType]
	if IsValid(ent) and not ent.Removing and not ent:IsMarkedForDeletion() and ent:GetOwner() == self then return ent end
end

function meta:GiveStatus(sType, fDie)
end

function meta:IsFriend()
	return self.m_IsFriend
end

timer.Create("checkfriend", 5, 0, function()
	for _, pl in player.Iterator() do
		pl.m_IsFriend = not pl:IsBot() and pl:GetFriendStatus() == "friend"
	end
end)

if not meta.SetGroundEntity then
	function meta:SetGroundEntity(ent) end
end

if not meta.Kill then
	function meta:Kill() end
end

if not meta.HasWeapon then
	function meta:HasWeapon(class)
		for _, wep in pairs(self:GetWeapons()) do
			if wep:GetClass() == class then return true end
		end

		return false
	end
end

function meta:SetMaxHealth(num)
	self:SetDTInt(0, math.ceil(num))
end

meta.OldGetMaxHealth = FindMetaTable("Entity").GetMaxHealth
function meta:GetMaxHealth()
	return self:GetDTInt(0)
end

function meta:DoHulls(classid, teamid)
	if not IsValid(self) or not self:IsPlayer() then return end
	local oldnocollide = self.NoCollideAll
	teamid = teamid or self:Team()
	classid = classid or self:GetZombieClass()

	if teamid == TEAM_UNDEAD then
		local classtab = GAMEMODE.ZombieClasses[classid]
		if classtab then
			self:SetIK(false)
			if classtab.ModelScale then
				self:SetModelScale(classtab.ModelScale, 0)
			elseif self:GetModelScale() ~= DEFAULT_MODELSCALE then
				self:SetModelScale(DEFAULT_MODELSCALE, 0)
			end

			if not classtab.Hull or not classtab.HullDuck then
				self:ResetHull()
			end
			if classtab.ViewOffset then
				self:SetViewOffset(classtab.ViewOffset)
			elseif self:GetViewOffset() ~= DEFAULT_VIEW_OFFSET then
				self:SetViewOffset(DEFAULT_VIEW_OFFSET)
			end
			if classtab.ViewOffsetDucked then
				self:SetViewOffsetDucked(classtab.ViewOffsetDucked)
			elseif self:GetViewOffsetDucked() ~= DEFAULT_VIEW_OFFSET_DUCKED then
				self:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)
			end
			if classtab.HullDuck then
				self:SetHullDuck(classtab.HullDuck[1], classtab.HullDuck[2])
			end
			if classtab.Hull then
				self:SetHull(classtab.Hull[1], classtab.Hull[2])
			end
			if classtab.StepSize then
				self:SetStepSize(classtab.StepSize)
			elseif self:GetStepSize() ~= DEFAULT_STEP_SIZE then
				self:SetStepSize(DEFAULT_STEP_SIZE)
			end
			if classtab.JumpPower then
				self:SetJumpPower(classtab.JumpPower)
			elseif self:GetJumpPower() ~= DEFAULT_JUMP_POWER then
				self:SetJumpPower(DEFAULT_JUMP_POWER)
			end

			if classtab.ClientsideModelScale then
				local scale = classtab.ClientsideModelScale
				self.ClientsideModelScale = Vector(scale, scale, scale)
				local m = Matrix()
				m:Scale(self.ClientsideModelScale)
				self:EnableMatrix("RenderMultiply", m)
			elseif self.ClientsideModelScale then
				self.ClientsideModelScale = nil
				self:DisableMatrix("RenderMultiply")
			end
			self.NoCollideAll = classtab.NoCollideAll
			self.AllowTeamDamage = classtab.AllowTeamDamage
			self.NeverAlive = classtab.NeverAlive
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetMass(classtab.Mass or DEFAULT_MASS)
			end
		end
	else
		self:SetIK(true)

		self:SetModelScale(DEFAULT_MODELSCALE, 0)
		self:ResetHull()
		self:SetViewOffset(DEFAULT_VIEW_OFFSET)
		self:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)
		self:SetStepSize(DEFAULT_STEP_SIZE)
		self:SetJumpPower(DEFAULT_JUMP_POWER)

		if self.ClientsideModelScale then
			self.ClientsideModelScale = nil
			self:DisableMatrix("RenderMultiply")
		end
		self.NoCollideAll = nil
		self.AllowTeamDamage = nil
		self.NeverAlive = nil
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMass(DEFAULT_MASS)
		end
	end
	if oldnocollide ~= self.NoCollideAll then self:CollisionRulesChanged() end
end

function meta:GivePenalty(amount)
	surface.PlaySound("ambient/alarms/klaxon1.wav")
end

function meta:SetZombieClass(cl)
	local classtab = GAMEMODE.ZombieClasses[cl]
	if not classtab then return end
	self:CallZombieFunction("SwitchedAway")
	if self.Class ~= (classtab.Index or cl) then GAMEMODE:ResetZombieAnimation(self) end
	self.Class = classtab.Index or cl
	self:CallZombieFunction("SwitchedTo")
end

net.Receive("zs_playercondition", function(length)
	if length < 3 then return end
	local pl = LocalPlayer()
	if not IsValid(pl) then return end
	local hemophilia = net.ReadBool()
	local state = net.ReadUInt(2)
	if state > 2 then return end
	local value
	if state ~= 0 then value = state == 2 end
	if hemophilia then pl:SetHemophilia(value, true) else pl:SetPalsy(value, true) end
end)

net.Receive("zs_penalty", function(length)
	if length < 16 then return end
	local penalty = net.ReadUInt(16)

	if IsValid(MySelf) then MySelf:GivePenalty(penalty) end
end)

net.Receive("zs_dohulls", function(length)
	if length < MAX_EDICT_BITS + 32 then return end
	local ent = net.ReadEntity()
	local classid = net.ReadUInt(16)
	local teamid = net.ReadUInt(16)

	if ent:IsValid() and ent:IsPlayer() then
		ent:DoHulls(classid, teamid)
	end
end)

local pendingZombieClasses = {}
local pendingZombieClassCount = 0
local pendingZombieClassOrder = 0
local pendingZombieClassRetry = 0

local function ClearPendingZombieClass(userid)
	if pendingZombieClasses[userid] then
		pendingZombieClasses[userid] = nil
		pendingZombieClassCount = pendingZombieClassCount - 1
		if pendingZombieClassCount == 0 then timer.Remove("ZSQueuedZombieClasses") end
	end
end

local function ApplyZombieClass(userid, id)
	local ent = Player(userid)
	if IsValid(ent) and ent:IsPlayer() and ent:UserID() == userid then
		ClearPendingZombieClass(userid)
		ent:SetZombieClass(id)
		return true
	end
end

local function RetryZombieClasses()
	for userid, entry in pairs(pendingZombieClasses) do
		ApplyZombieClass(userid, entry.id)
	end
	if RealTime() >= pendingZombieClassRetry then timer.Remove("ZSQueuedZombieClasses") end
end

local function QueueZombieClass(userid, id)
	if userid == 0 or not GAMEMODE.ZombieClasses[id] then return end
	if ApplyZombieClass(userid, id) then return end
	if not pendingZombieClasses[userid] then
		if pendingZombieClassCount == 128 then
			local oldest, order
			for uid, entry in pairs(pendingZombieClasses) do
				if not order or entry.order < order then oldest, order = uid, entry.order end
			end
			ClearPendingZombieClass(oldest)
		end
		pendingZombieClassCount = pendingZombieClassCount + 1
	end
	pendingZombieClassOrder = pendingZombieClassOrder + 1
	pendingZombieClasses[userid] = {id = id, order = pendingZombieClassOrder}
	pendingZombieClassRetry = RealTime() + 10
	if not timer.Exists("ZSQueuedZombieClasses") then
		timer.Create("ZSQueuedZombieClasses", 0.25, 0, RetryZombieClasses)
	end
end

hook.Add("NetworkEntityCreated", "ZSQueuedZombieClasses", function(ent)
	if not ent:IsPlayer() then return end
	local userid = ent:UserID()
	local entry = pendingZombieClasses[userid]
	if entry then ApplyZombieClass(userid, entry.id) end
end)

net.Receive("zs_zclass", function(length)
	if length < 40 then return end
	local userid = net.ReadUInt(32)
	local id = net.ReadUInt(8)
	QueueZombieClass(userid, id)
end)

net.Receive("zs_zclass_snapshot", function(length)
	if length < 8 then return end
	local count = net.ReadUInt(8)
	if count > 128 or length < 8 + count * 40 then return end
	for _ = 1, count do
		local userid = net.ReadUInt(32)
		local id = net.ReadUInt(8)
		QueueZombieClass(userid, id)
	end
end)

net.Receive("zs_floatscore", function(length)
	local victim = net.ReadEntity()
	local effectname = net.ReadString()
	local frags = net.ReadInt(24)
	local flags = net.ReadUInt(8)

	if IsValid(MySelf) and victim and victim:IsValid() then
		MySelf:FloatingScore(victim, effectname, frags, flags)
	end
end)

net.Receive("zs_floatscore_vec", function(length)
	local pos = net.ReadVector()
	local effectname = net.ReadString()
	local frags = net.ReadInt(24)
	local flags = net.ReadUInt(8)

	if IsValid(MySelf) then MySelf:FloatingScore(pos, effectname, frags, flags) end
end)
