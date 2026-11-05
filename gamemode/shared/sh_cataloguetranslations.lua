local categoryKeys = {
	[ITEMCAT_WORTHGUNS] = "title_worthguns", [ITEMCAT_HANDGUNS] = "title_guns",
	[ITEMCAT_SHOTGUNS] = "title_shotguns", [ITEMCAT_SMG] = "title_smg",
	[ITEMCAT_ASSAULTS] = "title_assault", [ITEMCAT_RIFLES] = "title_rifles",
	[ITEMCAT_AMMO] = "title_ammo", [ITEMCAT_MELEE] = "title_melee",
	[ITEMCAT_TOOLS] = "title_tools", [ITEMCAT_OTHER] = "title_other",
	[ITEMCAT_TRAITS] = "title_traits", [ITEMCAT_RETURNS] = "title_returns",
	[ITEMCAT_MUTATIONS] = "title_classm", [ITEMCAT_MUTATIONS_BOSS] = "title_bossm"
}
local categoryValues = {}
for index, key in pairs(categoryKeys) do categoryValues[index] = translate.Get(key) end
local revision

function GM:AddLocalizedMutationItem(signature, name, description, category, brains, worth, callback, model)
	local item = self:AddMutationItem(signature, translate.Get(name), translate.Get(description), category, brains, worth, callback, model)
	item.NameTranslation, item.DescriptionTranslation = name, description
	item.TranslatedName, item.TranslatedDescription = item.Name, item.Description
	revision = nil
	return item
end

function GM:RefreshCatalogueTranslations()
	local current = translate.GetRevision()
	if current == revision then return false end
	revision = current
	for index, key in pairs(categoryKeys) do
		local value = translate.Get(key)
		if self.ItemCategories[index] == categoryValues[index] then self.ItemCategories[index] = value end
		categoryValues[index] = value
	end
	for _, item in ipairs(self.Mutations) do
		if item.NameTranslation then
			local value = translate.Get(item.NameTranslation)
			if item.Name == item.TranslatedName then item.Name = value end
			item.TranslatedName = value
		end
		if item.DescriptionTranslation then
			local value = translate.Get(item.DescriptionTranslation)
			if item.Description == item.TranslatedDescription then item.Description = value end
			item.TranslatedDescription = value
		end
	end
	return true
end

if CLIENT then
	hook.Add("ZSLanguageChanged", "ZSCatalogueTranslations", function()
		GAMEMODE:RefreshCatalogueTranslations()
	end)
end
