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

local function RefreshText(item, field, keyField, previousField)
	local key = item[keyField]
	if type(key) ~= "string" then return end
	local value = translate.Get(key)
	if item[field] == item[previousField] then item[field] = value end
	item[previousField] = value
end

local function RefreshItems(items)
	if not items then return end
	for _, item in ipairs(items) do
		RefreshText(item, "Name", "NameTranslation", "TranslatedName")
		RefreshText(item, "Description", "DescriptionTranslation", "TranslatedDescription")
	end
end

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
	for _, weapon in ipairs(weapons.GetList()) do
		RefreshText(weapon, "PrintName", "PrintNameTranslation", "TranslatedPrintName")
		RefreshText(weapon, "Description", "DescriptionTranslation", "TranslatedDescription")
	end
	if CLIENT then
		for _, weapon in ents.Iterator() do
			if weapon:IsWeapon() then
				RefreshText(weapon, "PrintName", "PrintNameTranslation", "TranslatedPrintName")
				RefreshText(weapon, "Description", "DescriptionTranslation", "TranslatedDescription")
			end
		end
	end
	RefreshItems(self.Items)
	RefreshItems(self.Mutations)
	RefreshItems(self.Cosmetics)
	for _, definitions in ipairs({self.TraitDefinitions, self.ReturnDefinitions}) do
		for _, definition in ipairs(definitions) do
			RefreshText(definition, 2, "NameTranslation", "TranslatedName")
			RefreshText(definition, 3, "DescriptionTranslation", "TranslatedDescription")
		end
	end
	for _, definition in ipairs(self.QuestDefinitions) do
		RefreshText(definition, "title", "NameTranslation", "TranslatedName")
		RefreshText(definition, "description", "DescriptionTranslation", "TranslatedDescription")
	end
	return true
end

if CLIENT then
	hook.Add("ZSLanguageChanged", "ZSCatalogueTranslations", function()
		if GAMEMODE then GAMEMODE:RefreshCatalogueTranslations() end
	end)
end
