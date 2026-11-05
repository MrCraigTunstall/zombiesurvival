ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Survivor Quests"
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "QuestKind")
	self:NetworkVar("Int", 1, "QuestState")
	self:NetworkVar("Int", 2, "QuestProgress")
	self:NetworkVar("Int", 3, "QuestDuration")
	self:NetworkVar("Float", 0, "QuestDeadline")
	self:NetworkVar("Entity", 0, "QuestPlayer")
	self:NetworkVar("Entity", 1, "QuestSupply")
	self:NetworkVar("String", 0, "QuestReward")
	self:NetworkVar("Vector", 0, "QuestLocation")
end
