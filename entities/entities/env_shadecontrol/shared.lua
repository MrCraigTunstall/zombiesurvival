ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "ControllerWeapon")
end
