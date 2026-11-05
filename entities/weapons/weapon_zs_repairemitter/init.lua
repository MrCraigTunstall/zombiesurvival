INC_SERVER()

function SWEP:SpawnGhost()
	local owner = self:GetOwner()
	if IsValid(owner) then owner:GiveStatus("ghost_repairemitter") end
end

function SWEP:RemoveGhost()
	local owner = self:GetOwner()
	if IsValid(owner) then owner:RemoveStatus("ghost_repairemitter", false, true) end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	if owner:Team() ~= TEAM_HUMAN then return end
	local ghost = owner.status_ghost_repairemitter
	if not IsValid(ghost) then return end
	local position, angles = ghost:RecalculateValidity()
	if not position or not angles or not ghost:GetValidPlacement() then return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	local ent = ents.Create("prop_repairemitter")
	if not IsValid(ent) then return end
	ent:SetPos(position)
	ent:SetAngles(angles)
	ent:Spawn()
	ent:SetObjectOwner(owner)
	ent:EmitSound("npc/dog/dog_servo12.wav")
	self:TakePrimaryAmmo(1)
	local stored = owner:PopPackedItem(ent:GetClass())
	if stored then ent:SetObjectHealth(stored[1]) end
	if self:GetPrimaryAmmoCount() <= 0 then owner:StripWeapon(self:GetClass()) end
end
