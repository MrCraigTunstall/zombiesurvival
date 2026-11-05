AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:PlayerSet(pPlayer, bExists)
	pPlayer:EmitSound("items/ammocrate_open.wav")

	pPlayer:GetTable().PackUp = self

	if self:GetStartTime() == 0 then
		self:SetStartTime(CurTime())
	end
end

function ENT:OnRemove()
 local owner = self:GetOwner()
 if not IsValid(owner) then return end
 local data = owner:GetTable()
 if data.PackUp == self then data.PackUp = nil end
 if data.status_packup == self then data.status_packup = nil end
end

function ENT:Think()
	if self.Removing then return end
	local packer = self:GetOwner()
	if not IsValid(packer) or not packer:IsPlayer() or not packer:Alive() or packer:Team() ~= TEAM_HUMAN then
		self.Removing = true
		self:Remove()
		return
	end
	local now = CurTime()
	local owner = packer
	local pack = self:GetPackUpEntity()
	if IsValid(pack) and not (pack.IsMarkedForDeletion and pack:IsMarkedForDeletion()) and owner:TraceLine(64, MASK_SOLID, owner:GetMeleeFilter()).Entity == pack then
		if not self:GetNotOwner() and pack.GetObjectOwner then
			local packowner = pack:GetObjectOwner()
			if IsValid(packowner) and packowner:Team() ~= TEAM_UNDEAD and packowner ~= packer and not gamemode.Call("PlayerIsAdmin", packer) then self:SetNotOwner(true) end
		end
		if now >= self:GetEndTime() then
			if self:GetNotOwner() then
				local count = 0
				for _, ent in ipairs(GAMEMODE:GetZSEquipmentEntities("status_packup", true)) do
					if IsValid(ent) and not ent.Removing and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion()) and ent:GetPackUpEntity() == pack then
						count = count + 1
						if count >= self.PackUpOverride then break end
					end
				end
				if count < self.PackUpOverride then self:NextThink(now);return true end
				if pack.GetObjectOwner then
					local objowner = pack:GetObjectOwner()
					if IsValid(objowner) and objowner:Team() ~= TEAM_UNDEAD then owner = objowner end
				end
			end
			if pack.OnPackedUp and not pack:OnPackedUp(owner) then
				owner:EmitSound("items/ammocrate_close.wav")
				self.Removing = true
				gamemode.Call("ObjectPackedUp", pack, packer, owner)
				self:Remove()
			end
		end
	else
		owner:EmitSound("items/medshotno1.wav")
		self.Removing = true
		self:Remove()
	end
	self:NextThink(now)
	return true
end
