GM.QuestDefinitions = {
	{title = translate.Get("quest_hold_line"), description = translate.Get("quest_hold_line_desc"), NameTranslation = "quest_hold_line", DescriptionTranslation = "quest_hold_line_desc", duration = 60},
	{title = translate.Get("quest_medical"), description = translate.Get("quest_medical_desc"), NameTranslation = "quest_medical", DescriptionTranslation = "quest_medical_desc"},
	{title = translate.Get("quest_arm"), description = translate.Get("quest_arm_desc"), NameTranslation = "quest_arm", DescriptionTranslation = "quest_arm_desc", weapons = {"weapon_zs_peashooter", "weapon_zs_magnum", "weapon_zs_boomstick"}}
}

for _, definition in ipairs(GM.QuestDefinitions) do
	definition.TranslatedName, definition.TranslatedDescription = definition.title, definition.description
end

function GM:CanReachQuest(pl, ent, range)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded
		or not IsValid(ent) then return false end
	local eye = pl:EyePos()
	local nearest = ent:NearestPoint(eye)
	return eye:DistToSqr(nearest) <= (range or 120)^2 and WorldVisible(eye, nearest)
end

function GM:GetQuestWeaponName(class, pl)
	local stored = weapons.GetStored(class)
	if stored and stored.PrintNameTranslation then
		return IsValid(pl) and translate.ClientGet(pl, stored.PrintNameTranslation) or translate.Get(stored.PrintNameTranslation)
	end
	return stored and stored.PrintName or class
end
