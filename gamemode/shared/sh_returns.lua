GM.ReturnDefinitions = {
	{"punchbag", translate.Get("return_punchbag"), translate.Get("return_punchbag_desc"), -20},
	{"weakling", translate.Get("return_weakling"), translate.Get("return_weakling_desc"), -40},
	{"inexperienced", translate.Get("return_inexperienced"), translate.Get("return_inexperienced_desc"), -15},
	{"hallucinations", translate.Get("return_hallucinations"), translate.Get("return_hallucinations_desc"), -15},
	{"weakbody", translate.Get("return_weakbody"), translate.Get("return_weakbody_desc"), -20},
	{"weakheart", translate.Get("return_weakheart"), translate.Get("return_weakheart_desc"), -30},
	{"unlucky", translate.Get("return_unlucky"), translate.Get("return_unlucky_desc"), -15},
	{"obese", translate.Get("return_obese"), translate.Get("return_obese_desc"), -30},
	{"divinehatred", translate.Get("return_divinehatred"), translate.Get("return_divinehatred_desc"), -25},
	{"fleshytreat", translate.Get("return_fleshytreat"), translate.Get("return_fleshytreat_desc"), -20},
	{"weakstomach", translate.Get("return_weakstomach"), translate.Get("return_weakstomach_desc"), -15},
	{"nightmares", translate.Get("return_nightmares"), translate.Get("return_nightmares_desc"), -15},
	{"careless", translate.Get("return_careless"), translate.Get("return_careless_desc"), -25}
}
GM.ReturnLookup = {}
for _, definition in ipairs(GM.ReturnDefinitions) do
	local flag = definition[1]
	definition.NameTranslation = "return_" .. flag
	definition.DescriptionTranslation = definition.NameTranslation .. "_desc"
	definition.TranslatedName, definition.TranslatedDescription = definition[2], definition[3]
	GM.ReturnLookup[flag] = definition
	if not GM.ItemsBySignature["return_" .. flag] then
		local item = GM:AddLocalizedStartingItem("return_" .. flag, definition.NameTranslation, definition.DescriptionTranslation, ITEMCAT_RETURNS, definition[4], nil,
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
