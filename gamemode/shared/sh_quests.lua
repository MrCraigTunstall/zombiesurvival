GM.QuestDefinitions = {
	{title = "Hold the line", description = "Stay within 200 units and protect this survivor during an active wave.", duration = 60},
	{title = "Medical emergency", description = "Find the marked medicine, pick it up with USE, then return it here with USE."},
	{title = "Arm the survivors", description = "Donate each requested weapon with USE. Donations consume the weapon and its loaded ammunition.", weapons = {"weapon_zs_peashooter", "weapon_zs_magnum", "weapon_zs_boomstick"}}
}

function GM:CanReachQuest(pl, ent, range)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded
		or not IsValid(ent) then return false end
	local eye = pl:EyePos()
	local nearest = ent:NearestPoint(eye)
	return eye:DistToSqr(nearest) <= (range or 120)^2 and WorldVisible(eye, nearest)
end

function GM:GetQuestWeaponName(class)
	local stored = weapons.GetStored(class)
	return stored and stored.PrintName or class
end
