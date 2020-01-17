local specialPeople = {
	{
		id = "STEAM_0:1:3307510",
		img = "vgui/steam/games/icon_sourcesdk",
		tooltip = translate.Get("tag_jetboom")
	},
	{
		id = "STEAM_0:1:49624713",
		img = "vgui/steam/games/icon_sourcesdk",
		tooltip = translate.Get("tag_craig")
	},
	{
		id = "STEAM_0:0:47758537",
		img = "icons/cat.png",
		tooltip = translate.Get("tag_flair")
	},
	{
		id = "STEAM_0:0:18000855",
		img = "icon16/bomb.png",
		tooltip = translate.Get("tag_mka")
	},
	{
		id = "STEAM_0:0:22379160",
		img = "icon16/wrench_orange.png",
		tooltip = translate.Get("tag_d3")
	},
	{
		id = "STEAM_0:0:35752130",
		img = "icon16/rainbow.png",
		tooltip = translate.Get("tag_gabi")
	},
	{
		id = "STEAM_0:0:99299157",
		img = "flags16/ru.png",
		tooltip = translate.Get("tag_ru")
	},
	{
		id = "STEAM_0:0:32908051",
		img = "flags16/es.png",
		tooltip = translate.Get("tag_es")
	},
	{
		id = "STEAM_0:0:150667652",
		img = "flags16/kr.png",
		tooltip = translate.Get("tag_ko")
	}
}

function GM:IsSpecialPerson(pl, image)
	local img, tooltip, size, color, flash
	
	if pl:IsBot() then
		img = "icon16/bug.png"
		tooltip = translate.Get("tag_bot")
	elseif pl:IsSuperAdmin() then
		img = "icon16/shield.png"
		tooltip = translate.Get("tag_sa")
	elseif pl:IsAdmin() then
		img = "icons/shield_gray.png"
		tooltip = translate.Get("tag_admin")
	elseif pl:IsUserGroup("moderator") then
		img = "icon16/award_gold_star_2.png"
		tooltip = translate.Get("tag_mod")
	elseif pl:IsUserGroup("member") then
		img = "icon16/user.png"
		tooltip = translate.Get("tag_user")
	end
	
	if not pl:IsBot() then
		for k,v in pairs(specialPeople) do
			if v.id == pl:SteamID() or v.id64 == pl:SteamID64() then
				img = v.img
				tooltip = v.tooltip
				flash = true
			end
		end
	end
	
	if image == nil and flash then
		return true
	elseif image == nil then
		return false
	end
	
	if img then
		if CLIENT then
			image:SetImage(img)
			image:SetTooltip(tooltip)
			if size ~= nil then
				image:SetSize(size, size)
			end
			if color ~= nil then
				image:SetImageColor(color)
			end
		end
		
		return true
	end
	
	return false
end