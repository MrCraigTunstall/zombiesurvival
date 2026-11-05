local meta = FindMetaTable("Player")
if not meta then return end

function meta:FakeDeath(sequenceid, modelscale, length)
	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("fakedeath")) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:GetOwner() == self then
			ent:Remove()
		end
	end

	local ent = ents.Create("fakedeath")
	if ent:IsValid() then
		ent:SetOwner(self)
		ent:SetModel(self:GetModel())
		ent:SetSkin(self:GetSkin())
		ent:SetColor(self:GetColor())
		ent:SetMaterial(self:GetMaterial())
		ent:SetPos(self:GetPos() + Vector(0, 0, 64))
		ent:Spawn()
		ent:SetModelScale(modelscale or self:GetModelScale(), 0)

		ent:SetDeathSequence(sequenceid or 0)
		ent:SetDeathAngles(self:GetAngles())
		ent:SetDeathSequenceLength(length or 1)

		self:DeleteOnRemove(ent)
	end

	return ent
end

local MuscularBones = {
	["ValveBiped.Bip01_R_Upperarm"] = Vector(1, 2, 2),
	["ValveBiped.Bip01_R_Forearm"] = Vector(1, 2, 2),
	["ValveBiped.Bip01_L_Upperarm"] = Vector(1, 2, 2),
	["ValveBiped.Bip01_L_Forearm"] = Vector(1, 2, 2)
}
function meta:DoMuscularBones()
	if self.BuffMuscular and self:Team() == TEAM_HUMAN then
		self.MuscularBones = {}

		for bonename, newscale in pairs(MuscularBones) do
			local boneid = self:LookupBone(bonename)
			if boneid and boneid > 0 then
				table.insert(self.MuscularBones, boneid)
				self:ManipulateBoneScale(boneid, newscale)
			end
		end
	elseif self.MuscularBones then
		for _, boneid in pairs(self.MuscularBones) do
			self:ManipulateBoneScale(boneid, Vector(1, 1, 1))
		end
		self.MuscularBones = nil
	end
end

local NoodleArmBones = {
	["ValveBiped.Bip01_R_Upperarm"] = Vector(1, 0.4, 0.4),
	["ValveBiped.Bip01_R_Forearm"] = Vector(1, 0.4, 0.4),
	["ValveBiped.Bip01_L_Upperarm"] = Vector(1, 0.4, 0.4),
	["ValveBiped.Bip01_L_Forearm"] = Vector(1, 0.4, 0.4)
}
function meta:DoNoodleArmBones()
	if self.NoObjectPickup and self:Team() == TEAM_HUMAN then
		self.NoodleArmBones = {}

		for bonename, newscale in pairs(NoodleArmBones) do
			local boneid = self:LookupBone(bonename)
			if boneid and boneid > 0 then
				table.insert(self.NoodleArmBones, boneid)
				self:ManipulateBoneScale(boneid, newscale)
			end
		end
	elseif self.NoodleArmBones then
		for _, boneid in pairs(self.NoodleArmBones) do
			self:ManipulateBoneScale(boneid, Vector(1, 1, 1))
		end
		self.NoodleArmBones = nil
	end
end

function meta:ChangeTeam(teamid)
	local oldteam = self:Team()
	self:SetTeam(teamid)
	if oldteam ~= teamid then
		gamemode.Call("OnPlayerChangedTeam", self, oldteam, teamid)
	end
	self:DoNoodleArmBones()
	self:DoMuscularBones()
	self:CollisionRulesChanged()
end

function meta:TrySpawnAsGoreChild()
	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("prop_thrownbaby")) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() and not ent.SpawnedOn then
			ent.SpawnedOn = true

			local ang = self:EyeAngles()
			ang.roll = 0
			ang.pitch = 0

			local deathclass = self.DeathClass
			self:SetZombieClassName("Gore Child")
			self.DeathClass = nil
			self.DidntSpawnOnSpawnPoint = true
			self:UnSpectateAndSpawn()
			self.DeathClass = deathclass
			self:SetPos(ent:GetPos())
			self:SetEyeAngles(ang)
			self:StartFeignDeath(true)
			if IsValid(self.FeignDeath) then
				self.FeignDeath:SetState(1)
				self.FeignDeath:SetDirection(math.random(2) == 1 and DIR_FORWARD or DIR_BACK)
			end

			ent:Remove()

			break
		end
	end
end

function meta:AddLifeBarricadeDamage(amount)
	self.LifeBarricadeDamage = self.LifeBarricadeDamage + amount
	self.WaveBarricadeDamage = self.WaveBarricadeDamage + amount

	if not self:IsBot() and not self:Alive() and not self:GetZombieClassTable().NeverAlive then
		net.Start("zs_lifestatsbd")
			net.WriteUInt(self.LifeBarricadeDamage, 24)
		net.Send(self)
	end
end

function meta:AddLifeHumanDamage(amount)
	self.LifeHumanDamage = self.LifeHumanDamage + amount

	if not self:IsBot() and not self:Alive() then
		net.Start("zs_lifestatshd")
			net.WriteUInt(math.ceil(self.LifeHumanDamage), 24)
		net.Send(self)
	end
end

function meta:AddLifeBrainsEaten(amount)
	self.LifeBrainsEaten = self.LifeBrainsEaten + amount

	if not self:IsBot() and not self:Alive() then
		net.Start("zs_lifestatsbe")
			net.WriteUInt(self.LifeBrainsEaten, 16)
		net.Send(self)
	end
end

function meta:FloatingScore(victimorpos, effectname, frags, flags)
	if self:IsBot() then return end
	if type(victimorpos) == "Vector" then
		net.Start("zs_floatscore_vec")
			net.WriteVector(victimorpos)
			net.WriteString(effectname)
			net.WriteInt(frags, 24)
			net.WriteUInt(flags, 8)
		net.Send(self)
	else
		net.Start("zs_floatscore")
			net.WriteEntity(victimorpos)
			net.WriteString(effectname)
			net.WriteInt(frags, 24)
			net.WriteUInt(flags, 8)
		net.Send(self)
	end
end

function meta:MarkAsBadProfile()
	self.NoProfiling = true
end

function meta:CenterNotify(...)
	if not IsValid(self) or self:IsBot() then return end
	GAMEMODE:SendNotification(self, "zs_centernotify", {...})
end

function meta:TopNotify(...)
	if not IsValid(self) or self:IsBot() then return end
	GAMEMODE:SendNotification(self, "zs_topnotify", {...})
end

function meta:RefreshDynamicSpawnPoint()
	local gm = GAMEMODE
	local target = self:GetObserverTarget()
	local class = IsValid(target) and not target:IsMarkedForDeletion() and target:GetClass()
	if gm:GetDynamicSpawning() and self:GetObserverMode() == OBS_MODE_CHASE and class and
			(gm.ZombieEscape and target:IsPlayer() and target:Team() == TEAM_UNDEAD
			or not gm.ZombieEscape and class == "prop_creepernest" and target:GetNestBuilt()
			or string.sub(class, 1, 12) == "info_player_") then
		self.ForceDynamicSpawn = target
		self.ForceSpawnAngles = self:EyeAngles()
	else
		self.ForceDynamicSpawn = nil
		self.ForceSpawnAngles = nil
	end
end

function meta:PushPackedItem(class, ...)
	if self.PackedItems and ... ~= nil then
		local packed = {...}

		self.PackedItems[class] = self.PackedItems[class] or {}

		table.insert(self.PackedItems[class], packed)
	end
end

function meta:PopPackedItem(class)
	if self.PackedItems and self.PackedItems[class] and self.PackedItems[class][1] ~= nil then
		local index = #self.PackedItems[class]
		local data = self.PackedItems[class][index]
		table.remove(self.PackedItems[class], index)

		return data
	end
end

function meta:ChangeToCrow()
	self.StartCrowing = nil

	local crowclass = GAMEMODE.ZombieClasses["Crow"]
	if not crowclass then return end

	local curclass = self.DeathClass or self:GetZombieClass()
	local crowindex = crowclass.Index
	self:SetZombieClass(crowindex)
	self:DoHulls(crowindex, TEAM_UNDEAD)

	self.DeathClass = nil
	self:UnSpectateAndSpawn()
	self.DeathClass = curclass
end

function meta:SelectRandomPlayerModel()
	self:SetModel(player_manager.TranslatePlayerModel(GAMEMODE.RandomPlayerModels[math.random(#GAMEMODE.RandomPlayerModels)]))
end

function meta:GiveEmptyWeapon(weptype)
	if not self:HasWeapon(weptype) then
		local wep = self:Give(weptype)
		if wep and wep:IsValid() and wep:IsWeapon() then
			wep:EmptyAll()
		end

		return wep
	end
end

meta.ZSOriginalGive = meta.ZSOriginalGive or meta.Give
local OldGive = meta.ZSOriginalGive
function meta:Give(weptype, noammo)
	if self:Team() ~= TEAM_HUMAN then
		return OldGive(self, weptype, noammo)
	end

	local weps = self:GetWeapons()
	local autoswitch = #weps == 1 and weps[1]:IsValid() and weps[1].AutoSwitchFrom

	local ret = OldGive(self, weptype, noammo)

	if autoswitch then
		self:SelectWeapon(weptype)
	end

	return ret
end

function meta:StartFeignDeath(force)
	local feigndeath = self.FeignDeath
	if feigndeath and feigndeath:IsValid() then
		if CurTime() >= feigndeath:GetStateEndTime() then
			feigndeath:SetState(1)
			feigndeath:SetStateEndTime(CurTime() + 1.5)
		end
	elseif force or self:IsOnGround() and not self:IsPlayingTaunt() then
		local wep = self:GetActiveWeapon()
		if force or wep:IsValid() and not wep:IsSwinging() and CurTime() > wep:GetNextPrimaryFire() then
			if wep:IsValid() and wep.StopMoaning then
				wep:StopMoaning()
			end

			local status = self:GiveStatus("feigndeath")
			if status and status:IsValid() then
				status:SetStateEndTime(CurTime() + 1.5)
			end
		end
	end
end

function meta:UpdateLegDamage()
	if self:IsBot() then return end
	net.Start("zs_legdamage")
		net.WriteFloat(self.LegDamage)
	net.Send(self)
end

function meta:SendHint()
end

local function RemoveSkyCade(groundent, timername)
	if not groundent:IsValid() or not (groundent.IsBarricadeObject or groundent:IsNailedToWorldHierarchy()) then
		timer.Destroy(timername)
		return
	end

	for _, pl in player.Iterator() do
		if pl:Alive() and pl:GetGroundEntity() == groundent then
		if groundent:GetBarricadeRepairs() ~= 0 then
			groundent:SetBarricadeRepairs(math.max(groundent:GetBarricadeRepairs() - 10, 0))
			else
			groundent:TakeDamage(3, groundent, groundent)
			end			
			pl:ViewPunch(Angle(math.Rand(-25, 25), math.Rand(-25, 25), math.Rand(-25, 25)))
			if math.random(9) == 1 then
				groundent:EmitSound("npc/strider/creak"..math.random(4)..".wav", 65, math.random(95, 105))
			end

			return
		end
	end

	timer.Destroy(timername)
end
local checkoffset = Vector(0, 0, -128)
function meta:PreventSkyCade()
	local groundent = self:GetGroundEntity()
	if groundent:IsValid() then
		if groundent:IsNailedToWorldHierarchy() then
			local phys = groundent:GetPhysicsObject()
			if phys:IsValid() and phys:GetMass() <= CARRY_DRAG_MASS then
				local timername = "RemoveSkyCade"..tostring(groundent)
				local start = groundent:WorldSpaceCenter()
				if not timer.Exists(timername) and not util.TraceHull({start = start,
										endpos = start + checkoffset,
										mins = groundent:OBBMins() * 0.85, maxs = groundent:OBBMaxs() * 0.85,
										mask = MASK_SOLID_BRUSHONLY}).Hit then
					self:MarkAsBadProfile()
					timer.Create(timername, 0.25, 0, function() RemoveSkyCade(groundent, timername) end) -- Oh dear.
				end
			end
		elseif groundent.IsBarricadeObject then
			local timername = "RemoveSkyCade"..tostring(groundent)
			local start = groundent:WorldSpaceCenter()
			if not timer.Exists(timername) and not util.TraceHull({start = start,
									endpos = start + checkoffset,
									mins = groundent:OBBMins() * 0.85, maxs = groundent:OBBMaxs() * 0.85,
									mask = MASK_SOLID_BRUSHONLY}).Hit then
				self:MarkAsBadProfile()
				timer.Create(timername, 0.25, 0, function() RemoveSkyCade(groundent, timername) end) -- Oh dear.
			end
		end
	end
end

function meta:CoupleWith(plheadcrab)
	if self:GetZombieClassTable().Headcrab == plheadcrab:GetZombieClassTable().Name then
		local status = self:GiveStatus("headcrabcouple")
		if status:IsValid() then
			status:SetCouple(plheadcrab)
		end
	end
end

function meta:FixModelAngles(velocity)
	local eye = self:EyeAngles()
	self:SetLocalAngles(eye)
	self:SetPoseParameter("move_yaw", GAMEMODE:GetAnimationMoveYaw(velocity, eye.y))
end

function meta:RemoveAllStatus(bSilent, bInstant)
	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("status_*", true)) do
		if IsValid(ent) and not ent.NoRemoveOnDeath and ent:GetOwner() == self then
			if bInstant then ent:Remove() else ent.SilentRemove = bSilent; ent:SetDie() end
		end
	end
end

function meta:RemoveStatus(sType, bSilent, bInstant, sExclude)
	local removed
	local excluded = sExclude and "status_" .. sExclude
	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("status_" .. sType, true)) do
		if IsValid(ent) and ent:GetOwner() == self and not (excluded and ent:GetClass() == excluded) then
			if bInstant then ent:Remove() else ent.SilentRemove = bSilent; ent:SetDie() end
			removed = true
		end
	end
	return removed
end

function meta:GetStatus(sType)
	local ent = self["status_"..sType]
	if IsValid(ent) and not ent:IsMarkedForDeletion() and ent.Owner == self and ent:GetOwner() == self then return ent end
end

function meta:GiveStatus(sType, fDie)
	if sType == "knockdown" and GAMEMODE:HasPlayerTrait(self, "strongfeet") then return end
	local cur = self:GetStatus(sType)
	if cur then
		if fDie then
			cur:SetDie(fDie)
		end
		cur:SetPlayer(self, true)
		return cur
	else
		local ent = ents.Create("status_"..sType)
		if ent:IsValid() then
			ent:Spawn()
			if fDie then
				ent:SetDie(fDie)
			end
			ent:SetPlayer(self)
			return ent
		end
	end
end

function meta:UnSpectateAndSpawn()
	self:UnSpectate()
	self:Spawn()
end

function meta:SecondWind(pl)
	if self.Gibbed or self:Alive() or self:Team() ~= TEAM_UNDEAD then return end

	local pos = self:GetPos()
	local angles = self:EyeAngles()
	local lastattacker = self:GetLastAttacker()
	local dclass = self.DeathClass
	self.DeathClass = nil
	self.Revived = true
	self:UnSpectateAndSpawn()
	self.Revived = nil
	self.DeathClass = dclass
	self:SetLastAttacker(lastattacker)
	self:SetPos(pos)
	self:SetHealth(self:Health() * 0.2)
	self:SetEyeAngles(angles)

	self:CallZombieFunction("OnSecondWind")
end

function meta:DropAll()
	self:DropAllAmmo()
	self:DropAllWeapons()
end

local function CreateRagdoll(pl)
	if pl:IsValid() then pl:OldCreateRagdoll() end
end
local function SetModel(pl, mdl)
	if pl:IsValid() then
		pl:SetModel(mdl)
		timer.Simple(0, function() CreateRagdoll(pl) end)
	end
end

meta.OldCreateRagdoll = meta.OldCreateRagdoll or meta.CreateRagdoll
function meta:CreateRagdoll()
	local status = self.status_overridemodel
	if status and status:IsValid() then
		local mdl = status:GetModel()
		timer.Simple(0, function() SetModel(self, mdl) end)
		status:SetRenderMode(RENDERMODE_NONE)
	else
		self:OldCreateRagdoll()
	end
end

function meta:DropWeaponByType(class)
	if GAMEMODE.ZombieEscape then return end

	local wep = self:GetWeapon(class)
	if wep and wep:IsValid() and not wep.Undroppable then
		local ent = ents.Create("prop_weapon")
		if ent:IsValid() then
			ent:SetWeaponType(class)
			ent.ZSCrafter = wep.ZSCrafter
			ent.ZSForgeLevel = GAMEMODE:GetWeaponForgeLevel(wep)
			ent:Spawn()

			if wep.AmmoIfHas then
				local ammocount = wep:GetPrimaryAmmoCount()
				local desiredrop = math.min(ammocount, wep.Primary.ClipSize) - wep:Clip1()
				if desiredrop > 0 then
					wep:TakeCombinedPrimaryAmmo(desiredrop)
					wep:SetClip1(desiredrop)
				end
			end
			ent:SetClip1(wep:Clip1())
			ent:SetClip2(wep:Clip2())
			ent.DroppedTime = CurTime()

			self:StripWeapon(class)
			self:UpdateAltSelectedWeapon()

			return ent
		end
	end
end

function meta:DropAllWeapons()
	local vPos = self:GetPos()
	local vVel = self:GetVelocity()
	local zmax = self:OBBMaxs().z * 0.75
	for _, wep in pairs(self:GetWeapons()) do
		local ent = self:DropWeaponByType(wep:GetClass())
		if ent and ent:IsValid() then
			ent:SetPos(vPos + Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(2, zmax)))
			ent:SetAngles(VectorRand():Angle())
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddAngleVelocity(Vector(math.Rand(-720, 720), math.Rand(-720, 720), math.Rand(-720, 720)))
				phys:ApplyForceCenter(phys:GetMass() * (math.Rand(32, 328) * VectorRand():GetNormalized() + vVel))
			end
		end
	end
end

function meta:DropAmmoByType(ammotype, amount)
	if GAMEMODE.ZombieEscape then return end

	local mycount = self:GetAmmoCount(ammotype)
	amount = math.min(mycount, amount or mycount)
	if not amount or amount <= 0 then return end

	local ent = ents.Create("prop_ammo")
	if ent:IsValid() then
		ent:SetAmmoType(ammotype)
		ent:SetAmmo(amount)
		ent:Spawn()

		self:RemoveAmmo(amount, ammotype)

		return ent
	end
end

function meta:DropAllAmmo()
	local vPos = self:GetPos()
	local vVel = self:GetVelocity()
	local zmax = self:OBBMaxs().z * 0.75
	for ammotype in pairs(GAMEMODE.AmmoCache) do
		local ent = self:DropAmmoByType(ammotype)
		if ent and ent:IsValid() then
			ent:SetPos(vPos + Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(2, zmax)))
			ent:SetAngles(VectorRand():Angle())
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddAngleVelocity(Vector(math.Rand(-720, 720), math.Rand(-720, 720), math.Rand(-720, 720)))
				phys:ApplyForceCenter(phys:GetMass() * (math.Rand(32, 328) * VectorRand():GetNormalized() + vVel))
			end
		end
	end
end

-- Lets other players know about our maximum health.
meta.OldSetMaxHealth = FindMetaTable("Entity").SetMaxHealth
function meta:SetMaxHealth(num)
	num = math.ceil(num)
	self:SetDTInt(0, num)
	self:OldSetMaxHealth(num)
end

function meta:PointCashOut(ent, fmtype)
	if self.m_PointQueue >= 1 and self:Team() ~= TEAM_UNDEAD then
		local points = math.floor(self.m_PointQueue)
		self.m_PointQueue = self.m_PointQueue - points

		self:AddPoints(points)
		self:FloatingScore(ent or self.m_LastDamageDealtPosition or vector_origin, "floatingscore", points, fmtype or FM_NONE)
	end
end

function meta:AddPoints(points)
	self:AddFrags(points)
	self:SetPoints(self:GetPoints() + points)

	gamemode.Call("PlayerPointsAdded", self, points)
end

function meta:TakePoints(points)
	self:SetPoints(self:GetPoints() - points)
	gamemode.Call("PlayerPointsRemoved", self, points)
end

function meta:AddTokens(pts)
	self:SetNWInt('btokens', self:GetTokens() + pts)
end

function meta:TakeTokens(pts)
	self:SetNWInt('btokens', self:GetTokens() - pts)
end

function meta:UpdateAllZombieClasses()
	if self:IsBot() then return end
	local entries, count = {}, 0
	local function SendBatch()
		net.Start("zs_zclass_snapshot")
		net.WriteUInt(count, 8)
		for i = 1, count * 2, 2 do
			net.WriteUInt(entries[i]:UserID(), 32)
			net.WriteUInt(entries[i + 1], 8)
		end
		net.Send(self)
		count = 0
	end
	for _, pl in player.Iterator() do
		if pl ~= self and pl:Team() == TEAM_UNDEAD then
			local id = pl:GetZombieClass()
			if id and 0 < id then
				count = count + 1
				entries[count * 2 - 1], entries[count * 2] = pl, id
				if count == 128 then SendBatch() end
			end
		end
	end
	if count > 0 then SendBatch() end
end

function meta:CreateAmbience(class)
	class = "status_"..class
	local current = self[class]
	if IsValid(current) and not current:IsMarkedForDeletion() and current:GetOwner() == self then return end

	for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities(class, true)) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() and ent:GetOwner() == self then return end
	end

	local ent = ents.Create(class)
	if ent:IsValid() then
		ent:SetPos(self:LocalToWorld(self:OBBCenter()))
		self[class] = ent
		ent:SetOwner(self)
		ent:SetParent(self)
		ent:Spawn()
	end
end

function meta:SetZombieClass(cl, onlyupdate, filter)
	if onlyupdate then
		if filter == self and self:IsBot() then return end
		net.Start("zs_zclass")
			net.WriteUInt(self:UserID(), 32)
			net.WriteUInt(cl, 8)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end

		return
	end

	self:CallZombieFunction("SwitchedAway")

	local classtab = GAMEMODE.ZombieClasses[cl]
	if classtab then
		if self.Class ~= cl then
			GAMEMODE:ResetZombieAnimation(self)
			GAMEMODE:ClearZombieSpawnVariants(self)
		end
		self.Class = cl
		if self:Team() == TEAM_UNDEAD then
			self:DoHulls(cl)
		end
		self:CallZombieFunction("SwitchedTo")

		net.Start("zs_zclass")
			net.WriteUInt(self:UserID(), 32)
			net.WriteUInt(cl, 8)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end
	end
end

function meta:DoHulls(classid, teamid)
	teamid = teamid or self:Team()
	classid = classid or self:GetZombieClass()

	if teamid == TEAM_UNDEAD then
		local classtab = GAMEMODE.ZombieClasses[classid]
		if classtab then
			if self:Alive() then
				self:SetMoveType(classtab.MoveType or MOVETYPE_WALK)
			end

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

			self:DrawShadow(not classtab.NoShadow)

			self.NoCollideAll = classtab.NoCollideAll
			self.AllowTeamDamage = classtab.AllowTeamDamage
			self.NeverAlive = classtab.NeverAlive
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetMass(classtab.Mass or DEFAULT_MASS)
			end
		end
	else
		self:SetModelScale(DEFAULT_MODELSCALE, 0)
		self:ResetHull()
		self:SetViewOffset(DEFAULT_VIEW_OFFSET)
		self:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)
		self:SetStepSize(DEFAULT_STEP_SIZE)
		self:SetJumpPower(DEFAULT_JUMP_POWER)

		self:DrawShadow(true)

		self.NoCollideAll = nil
		self.AllowTeamDamage = nil
		self.NeverAlive = nil
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMass(DEFAULT_MASS)
		end
	end

	net.Start("zs_dohulls")
		net.WriteEntity(self)
		net.WriteUInt(classid, 16)
		net.WriteUInt(teamid, 16)
	net.Broadcast()

	self:CollisionRulesChanged()
end

function meta:Redeem()
	gamemode.Call("PlayerRedeemed", self)
end

function meta:RedeemNextFrame()
	if self.ZSRedeemPending then return end
	self.ZSRedeemPending = true
	timer.Simple(0, function()
		if IsValid(self) then
			self.ZSRedeemPending = nil
			self:CheckRedeem(true)
		end
	end)
end

function meta:TakeBrains(amount)
	self:AddFrags(-amount)
	self.BrainsEaten = self.BrainsEaten - 1
end

function meta:AddBrains(amount)
	self:AddFrags(amount)
	self.BrainsEaten = self.BrainsEaten + 1
	self:CheckRedeem()
end

meta.GetBrains = meta.Frags

function meta:CheckRedeem(instant)
	if not self:IsValid() or self:Team() ~= TEAM_UNDEAD then return end
	local gm = GAMEMODE
	local required = gm:GetRedeemBrains()
	if required <= 0 or self:GetBrains() < required
	or gm.NoRedeeming or self.NoRedeeming or self:GetZombieClassTable().Boss then return end
	local waves = gm:GetNumberOfWaves()
	if gm:GetWave() ~= waves or not gm.ObjectiveMap and waves == 1 and CurTime() < gm:GetWaveEnd() - 300 then
		if instant then
			self:Redeem()
		else
			self:RedeemNextFrame()
		end
	end
end

function meta:AntiGrief(dmginfo, overridenostrict)
	if GAMEMODE.GriefStrict and not overridenostrict then
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return
	end

	dmginfo:SetDamage(dmginfo:GetDamage() * GAMEMODE.GriefForgiveness)

	self:GivePenalty(math.ceil(dmginfo:GetDamage() * 0.5))
	self:ReflectDamage(dmginfo:GetDamage())
end

function meta:GivePenalty(amount)
	self.m_PenaltyCarry = (self.m_PenaltyCarry or 0) + amount * 0.1
	local frags = math.floor(self.m_PenaltyCarry)
	if frags > 0 then
		self.m_PenaltyCarry = self.m_PenaltyCarry - frags
		self:GivePointPenalty(frags)
	end
end

function meta:GivePointPenalty(amount)
	self:SetFrags(self:Frags() - amount)
	if self:IsBot() then return end

	net.Start("zs_penalty")
		net.WriteUInt(amount, 16)
	net.Send(self)
end

function meta:ReflectDamage(damage)
	local frags = self:Frags()
	if frags < GAMEMODE.GriefReflectThreshold then
		self:TakeDamage(math.ceil(damage * frags * -0.05 * GAMEMODE.GriefDamageMultiplier))
	end
end

function meta:UpdateAltSelectedWeapon()
	if self:IsBot() then return end
	net.Start("zs_updatealtselwep")
	net.Send(self)
end


function meta:Gib()
	local pos = self:WorldSpaceCenter()
	local headoffset = self:LocalToWorld(self:OBBMaxs()).z - pos.z

	local effectdata = EffectData()
		effectdata:SetEntity(self)
		effectdata:SetOrigin(pos)
	util.Effect("gib_player", effectdata, true, true)

	self.Gibbed = CurTime()

	GAMEMODE:ReturnZombieGib(self, pos)
	timer.Simple(0, function() GAMEMODE:CreateGibs(pos, headoffset) end)
end

function meta:GetLastAttacker()
	local ent = self.LastAttacker
	if ent and ent:IsValid() and CurTime() <= self.LastAttacked + 10 then
		return ent
	end
	--self:SetLastAttacker()
end

function meta:SetLastAttacker(ent)
	if ent then
		if ent ~= self then
			self.LastAttacker = ent
			self.LastAttacked = CurTime()
		end
	else
		self.LastAttacker = nil
		self.LastAttacked = nil
	end
end

meta.OldUnSpectate = meta.OldUnSpectate or meta.UnSpectate
function meta:UnSpectate()
	if self:GetObserverMode() ~= OBS_MODE_NONE then
		self:OldUnSpectate()
	end
end

function meta:PlayEyePainSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_eyepain")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayGiveAmmoSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_giveammo")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayDeathSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_death")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayZombieDeathSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_zombiedeath")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayPainSound()
	local now = CurTime()
	if now < self.NextPainSound then return end
	self.NextPainSound = now + 0.5

	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_pain")
	net.WriteEntity(self)
	net.WriteUInt(math.ceil(self:Health() / 25), 4)
	net.Send(rf)
end

function meta:PlayZombiePainSound()
	local now = CurTime()
	if now < self.NextPainSound then return end
	self.NextPainSound = now + 0.5

	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_zombiepain")
	net.WriteEntity(self)
	net.Send(rf)
end
