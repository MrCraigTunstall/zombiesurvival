AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	self:SpawnGhost()

	return true
end

function SWEP:OnRemove()
	self:RemoveGhost()
end

function SWEP:Holster()
	self:RemoveGhost()
	return true
end

function SWEP:SpawnGhost()
	local owner = self.Owner
	if owner and owner:IsValid() then
		owner:GiveStatus("ghost_messagebeacon")
	end
end

function SWEP:RemoveGhost()
	local owner = self.Owner
	if owner and owner:IsValid() then
		owner:RemoveStatus("ghost_messagebeacon", false, true)
	end
end

util.AddNetworkString("zs_beaconmenu")

function SWEP:SecondaryAttack()
 if not game.SinglePlayer() then return end
 local owner = self:GetOwner()
 if not IsValid(owner) or owner:IsBot() then return end
 net.Start("zs_beaconmenu")
 net.WriteEntity(self)
 net.Send(owner)
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self.Owner

	local status = owner.status_ghost_messagebeacon
	if not (status and status:IsValid()) then return end
	local pos, ang = status:RecalculateValidity()
	if not pos or not ang or not status:GetValidPlacement() then return end

	self:SetNextPrimaryAttack(CurTime() + self.Primary.Delay)

	local ent = ents.Create("prop_messagebeacon")
	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()

		ent:SetObjectOwner(owner)
		ent:SetMessageID(self.MessageID)

		ent:EmitSound("npc/dog/dog_servo12.wav")

		--ent:GhostAllPlayersInMe(5)

		self:TakePrimaryAmmo(1)

		local stored = owner:PopPackedItem(ent:GetClass())
		if stored then
			ent.m_Health = stored[1]
		end

		if self:GetPrimaryAmmoCount() <= 0 then
			owner:StripWeapon(self:GetClass())
		end
	end
end

function SWEP:Think()
	local count = self:GetPrimaryAmmoCount()
	if count ~= self:GetReplicatedAmmo() then
		self:SetReplicatedAmmo(count)
		self.Owner:ResetSpeed()
	end
end

SWEP.MessageID = 1
concommand.Add("setmessagebeaconmessage", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end

	local wep = sender:GetActiveWeapon()
	if wep:IsValid() and wep:GetClass() == "weapon_zs_messagebeacon" then
		local id = tonumber(arguments[1])
		if not id or id ~= id or id == math.huge or id == -math.huge or #GAMEMODE.ValidBeaconMessages == 0 then return end
		wep.MessageID = math.Clamp(math.floor(id), 1, #GAMEMODE.ValidBeaconMessages)
		wep:SetDTInt(1, wep.MessageID)
	end
end)
