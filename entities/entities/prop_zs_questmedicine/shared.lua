ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Quest Medicine"

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "QuestNPC")
end
