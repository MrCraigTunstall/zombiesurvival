GM.ReturnDefinitions = {
	{"punchbag", "Punchbag", "Zombie melee attacks deal 20% more damage to you.", -20},
	{"weakling", "Weakling", "All damage to you is increased by 40%.", -40},
	{"inexperienced", "Inexperienced Shooter", "Your weapon spread is 10% wider, even when healthy.", -15},
	{"hallucinations", "Hallucinations", "Zombie damage has a 20% chance to cause brief poison-like hallucinations.", -15},
	{"weakbody", "Weak Body", "Zombie damage has a 20% chance to infect you for six seconds, losing 1 HP per second.", -20},
	{"weakheart", "Weak Heart", "First sight of each boss during a life has a 5% chance to cause a fatal heart attack.", -30},
	{"unlucky", "Unlucky", "Placing or packing equipment and lifting heavy props has a 5% chance to hurt you for 3 HP.", -15},
	{"obese", "Morbidly Obese", "Your movement speed is reduced by 25% and your belly is enlarged.", -30},
	{"divinehatred", "Divine Hatred", "You cannot teleport using sigils.", -25},
	{"fleshytreat", "Fleshy Treat", "Zombie hits heal their attacker for up to 5 HP.", -20},
	{"weakstomach", "Weak Stomach", "Nearby infected gibs have a 25% chance to make you vomit, losing 3 HP and shaking your view.", -15},
	{"nightmares", "Nightmares", "First sight of each boss during a life causes a mild hallucination.", -15},
	{"careless", "Careless", "Zombies deal 25% extra damage when two or more living infected are within 192 units.", -25}
}
GM.ReturnLookup = {}
for _, definition in ipairs(GM.ReturnDefinitions) do
	local flag = definition[1]
	GM.ReturnLookup[flag] = definition
	if not GM.ItemsBySignature["return_" .. flag] then
		local item = GM:AddStartingItem("return_" .. flag, definition[2], definition[3], ITEMCAT_RETURNS, definition[4], nil,
			function(pl) if SERVER then GAMEMODE:SetPlayerReturn(pl, flag) end end, "models/gibs/hgibs.mdl")
		item.WorthReturn, item.WorthGrantCallback = flag, item.Callback
		if flag == "divinehatred" then item.RequiresSigils, item.NoZombieEscape = true, true end
	end
end

function GM:GetReturnAimScale(pl)
	return IsValid(pl) and pl:Team() == TEAM_HUMAN and pl:GetNW2Bool("zs_return_inexperienced", false) and 1.1 or 1
end

function GM:GetReturnSpeedScale(pl)
	return pl:Team() == TEAM_HUMAN and pl:GetNW2Bool("zs_return_obese", false) and 0.75 or 1
end
