local specialPeople = {
	["STEAM_0:1:3307510"] = {"vgui/steam/games/icon_sourcesdk", "tag_jetboom"},
	["STEAM_0:1:49624713"] = {"vgui/steam/games/icon_sourcesdk", "tag_craig"},
	["STEAM_0:0:47758537"] = {"icons/cat.png", "tag_flair"},
	["STEAM_0:0:18000855"] = {"icon16/bomb.png", "tag_mka"},
	["STEAM_0:0:22379160"] = {"icon16/wrench_orange.png", "tag_d3"},
	["STEAM_0:0:35752130"] = {"icon16/rainbow.png", "tag_gabi"},
	["STEAM_0:0:99299157"] = {"flags16/ru.png", "tag_ru"},
	["STEAM_0:0:32908051"] = {"flags16/es.png", "tag_es"},
	["STEAM_0:0:150667652"] = {"flags16/kr.png", "tag_ko"},
}

local captions, languageRevision, languageGetter = {}, nil, nil
local function Caption(key)
	local revision, getter = translate.GetRevision(), translate.Get
	if revision ~= languageRevision or getter ~= languageGetter then
		captions, languageRevision, languageGetter = {}, revision, getter
	end
	local text = captions[key]
	if text == nil then text = getter(key) captions[key] = text end
	return text
end

function GM:IsSpecialPerson(pl, image)
	local bot = pl:IsBot()
	local special = not bot and specialPeople[pl:SteamID()]
	local flash = special and true or false
	if image == nil then return flash end
	local img, key
	if special then
		img, key = special[1], special[2]
	elseif bot then
		img, key = "icon16/bug.png", "tag_bot"
	elseif pl:IsSupporter() then
		img, key = "zsr/supportericon.png", "tag_supporter"
	elseif pl:IsSuperAdmin() then
		img, key = "icon16/shield.png", "tag_sa"
	elseif pl:IsAdmin() then
		img, key = "icons/shield_gray.png", "tag_admin"
	elseif pl:IsUserGroup("moderator") then
		img, key = "icon16/award_gold_star_2.png", "tag_mod"
	elseif pl:IsUserGroup("member") then
		img, key = "icon16/user.png", "tag_user"
	end
	if CLIENT then
		image.ZSSpecialPersonFlash = flash
		if img then
			if image:GetImage() ~= img then image:SetImage(img) end
			local tooltip = Caption(key)
			if image:GetTooltip() ~= tooltip then image:SetTooltip(tooltip) end
		end
	end
	return img ~= nil
end
