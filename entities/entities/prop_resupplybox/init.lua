AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local function RefreshCrateOwners(pl)
	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_resupplybox")) do
		if ent:IsValid() and ent:GetObjectOwner() == pl then
			ent:SetObjectOwner(NULL)
		end
	end
end
hook.Add("PlayerDisconnected", "ResupplyBox.PlayerDisconnected", RefreshCrateOwners)
hook.Add("OnPlayerChangedTeam", "ResupplyBox.OnPlayerChangedTeam", RefreshCrateOwners)

function ENT:Initialize()
	GAMEMODE:RegisterZSClassEntity(self)
	self:SetModel("models/Items/ammocrate_ar2.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetPlaybackRate(1)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	self:SetMaxObjectHealth(200)
	self:SetObjectHealth(self:GetMaxObjectHealth())
	self:NextThink(CurTime() + 1)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "maxcratehealth" then
		value = tonumber(value)
		if not value then return end

		self:SetMaxObjectHealth(value)
	elseif key == "cratehealth" then
		value = tonumber(value)
		if not value then return end

		self:SetObjectHealth(value)
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	if name == "setcratehealth" then
		self:KeyValue("cratehealth", args)
		return true
	elseif name == "setmaxcratehealth" then
		self:KeyValue("maxcratehealth", args)
		return true
	end
end

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)
	if health <= 0 and not self.Destroyed then
		self.Destroyed = true
		self:NextThink(CurTime())

		local ent = ents.Create("prop_physics")
		if ent:IsValid() then
			ent:SetModel(self:GetModel())
			ent:SetMaterial(self:GetMaterial())
			ent:SetAngles(self:GetAngles())
			ent:SetPos(self:GetPos())
			ent:SetSkin(self:GetSkin() or 0)
			ent:SetColor(self:GetColor())
			ent:Spawn()
			ent:Fire("break", "", 0)
			ent:Fire("kill", "", 0.1)
		end
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()
	if not (attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN) then
		GAMEMODE:DamageTraitObject(self, dmginfo)
		self:ResetLastBarricadeAttacker(attacker, dmginfo)
	end
end

function ENT:AltUse(activator, tr)
	self:PackUp(activator)
end

function ENT:OnPackedUp(pl)
  	if pl:HasWeapon("weapon_zs_resupplybox") then
		pl:GiveAmmo(1, "helicoptergun")
	else
		pl:Give("weapon_zs_resupplybox")
	end

	pl:PushPackedItem(self:GetClass(), self:GetObjectHealth())

	self:Remove()
end

function ENT:Think()
	if self.Destroyed then self:Remove() return end
	local now = CurTime()
	if self.Close and now >= self.Close then
		self.Close = nil
		self:ResetSequence("open")
		self:EmitSound("items/ammocrate_close.wav")
	end
	self:NextThink(self.Close and math.min(self.Close, now + 1) or now + 1)
	return true
end

local NextUse = {}
function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	local teamid = activator:Team()
	if (teamid ~= TEAM_HUMAN and teamid ~= TEAM_REDEEMER) or not activator:Alive() or GAMEMODE:GetWave() <= 0 then return end
	local now = CurTime()

	local owner = self:GetObjectOwner()
	if not IsValid(owner) then
		self:SetObjectOwner(activator)
		owner = activator
	end
	local myuid = activator:UniqueID()

	if now < (NextUse[myuid] or 0) then
		activator:CenterNotify(COLOR_RED, translate.ClientGet(activator, "no_ammo_here"))
		return
	end

	local ammotype
	local wep = activator:GetActiveWeapon()
	if not wep:IsValid() then
		ammotype = "smg1"
	end

	if not ammotype then
		ammotype = wep:GetPrimaryAmmoTypeString()
		if not GAMEMODE.AmmoResupply[ammotype] then
			ammotype = "smg1"
		end
	end

	NextUse[myuid] = now + GAMEMODE:GetTraitResupplyCooldown(owner)

	if not activator:IsBot() then
		net.Start("zs_nextresupplyuse")
			net.WriteFloat(NextUse[myuid])
		net.Send(activator)
	end

	activator:GiveAmmo(GAMEMODE.AmmoResupply[ammotype], ammotype)
	if activator ~= owner and owner:IsValid() and owner:IsPlayer() and owner:Team() == TEAM_HUMAN then
		owner.ResupplyBoxUsedByOthers = owner.ResupplyBoxUsedByOthers + 1

		if owner.ResupplyBoxUsedByOthers % 2 == 0 then
			owner:AddPoints(1)
		end

		if not owner:IsBot() then
			net.Start("zs_commission")
				net.WriteEntity(self)
				net.WriteEntity(activator)
				net.WriteUInt(1, 16)
			net.Send(owner)
		end
	end

	if not self.Close then
		self:ResetSequence("close")
		self:EmitSound("items/ammocrate_open.wav")
	end
	self.Close = now + 3
	self:NextThink(math.min(self.Close, now + 1))
end
