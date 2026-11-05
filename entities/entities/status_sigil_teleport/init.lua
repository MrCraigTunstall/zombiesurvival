AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:PlayerSet(pPlayer, bExists)
	if self:GetStartTime() == 0 then
		self:SetStartTime(CurTime())
	end
end

local sigilOffset = Vector(0, 0, 64)

function ENT:GetSigilAngle(aimSigil)
	local owner = self:GetOwner()
	if not IsValid(owner) or not IsValid(aimSigil) then return end
	return math.acos(math.Clamp(owner:GetAimVector():Dot((aimSigil:GetPos() + sigilOffset - owner:EyePos()):GetNormalized()), -1, 1))
end

function ENT:GetAimSigil()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	local current = self:GetCurrentSigil()
	local aim, eye = owner:GetAimVector(), owner:EyePos()
	local best, bestdot
	for _, sigil in ipairs(GAMEMODE:GetZSClassEntities("prop_obj_sigil")) do
		if sigil ~= current and IsValid(sigil) and not sigil:GetSigilCorrupted() then
			local dot = aim:Dot((sigil:GetPos() + sigilOffset - eye):GetNormalized())
			if not bestdot or dot > bestdot then best, bestdot = sigil, dot end
		end
	end
	return best
end

local function GhostProps(pl, newPos)
	local ents = ents.FindInBox(newPos + pl:OBBMins() - Vector(1,1,1), newPos + pl:OBBMaxs() + Vector(1,1,1))
	
	for k, v in ipairs(ents) do
		if IsValid(v) and v:GetMoveType() == MOVETYPE_VPHYSICS and v:GetClass() ~= "prop_obj_sigil" and v:GetClass() ~= "status_arsenalcrate" 
		and not v:IsNailed() then
			v:GhostAllPlayersInMe(30, true)
		end
	end
end

-- Set pos in hook, to prevent the position from being overwritten by something else
hook.Add("FinishMove", "SigilTeleporting", function(ply, mv)
	if ply.TeleportTo then
		local position, sigil = ply.TeleportTo, ply.TeleportSigil
		ply.TeleportTo, ply.TeleportSigil = nil, nil
		if not ply:Alive() or ply:Team() ~= TEAM_SURVIVORS or (ply.ZSReturns and ply.ZSReturns.divinehatred) then return end
		if sigil ~= nil and (not IsValid(sigil) or sigil:GetSigilCorrupted() or sigil:IsMarkedForDeletion()) then return end
		ply:SetPos(position)
		ply:SetBarricadeGhosting(true)
		GhostProps(ply, position)
		
		GAMEMODE:TraitSigilHeal(ply)
		return true
	end 
end)

local function sigilTeleport(status, owner, currentSigil)
	local sigil = status:GetAimSigil()
	if not sigil then return end
	
	local sigilPos = sigil:GetPos()
	
	owner:EmitSound("ambient/machines/teleport1.wav")
	
	owner.TeleportTo = sigilPos
	owner.TeleportSigil = sigil
end

function ENT:Think()
	if self.Removing then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) and owner.ZSReturns and owner.ZSReturns.divinehatred then self:Remove(); return end
	local sigil = self:GetCurrentSigil()
	local aimSigil = self:GetAimSigil()
	
	if self:GetDestSigil() ~= aimSigil then self:SetDestSigil(aimSigil) end
	
	if IsValid(sigil) and IsValid(owner) and owner:Alive() and owner:GetPos():DistToSqr(sigil:GetPos() + sigilOffset) < (sigil.MaxDistance or 100) ^ 2 and not owner:KeyDown(IN_SPEED) and owner:Team() == TEAM_SURVIVORS then
		if not owner.FastTeleport and not self.PlayedPreTelSound and CurTime() >= self:GetEndTime() - 2.0 then
			self.PlayedPreTelSound = true
			owner:EmitSound("ambient/levels/labs/teleport_preblast_suckin1.wav")
		end
		if CurTime() >= self:GetEndTime() then
			sigilTeleport(self, owner, sigil)
			self.Removing = true
			self:Remove()
		end
	else
		if IsValid(owner) then owner:EmitSound("items/medshotno1.wav") end
		self.Removing = true
		self:Remove()
	end

	self:NextThink(CurTime())
	return true
end
