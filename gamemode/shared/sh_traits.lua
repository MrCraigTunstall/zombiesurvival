GM.TraitDefinitions = {
	{"marksman", translate.Get("trait_marksman"), translate.Get("trait_marksman_desc"), 20},
	{"chosenone", translate.Get("trait_chosenone"), translate.Get("trait_chosenone_desc"), 15},
	{"strongfeet", translate.Get("trait_strongfeet"), translate.Get("trait_strongfeet_desc"), 20},
	{"thickskin", translate.Get("trait_thickskin"), translate.Get("trait_thickskin_desc"), 25},
	{"acrobatic", translate.Get("trait_acrobatic"), translate.Get("trait_acrobatic_desc"), 15},
	{"kleiner", translate.Get("trait_kleiner"), translate.Get("trait_kleiner_desc"), 10},
	{"venomimmunity", translate.Get("trait_venomimmunity"), translate.Get("trait_venomimmunity_desc"), 30},
	{"steady", translate.Get("trait_steady"), translate.Get("trait_steady_desc"), 15},
	{"butcher", translate.Get("trait_butcher"), translate.Get("trait_butcher_desc"), 25},
	{"sniper", translate.Get("trait_sniper"), translate.Get("trait_sniper_desc"), 20},
	{"swordsman", translate.Get("trait_swordsman"), translate.Get("trait_swordsman_desc"), 30},
	{"sticky", translate.Get("trait_sticky"), translate.Get("trait_sticky_desc"), 20},
	{"highnoon", translate.Get("trait_highnoon"), translate.Get("trait_highnoon_desc"), 20},
	{"kenjutsu", translate.Get("trait_kenjutsu"), translate.Get("trait_kenjutsu_desc"), 30},
	{"punisher", translate.Get("trait_punisher"), translate.Get("trait_punisher_desc"), 20},
	{"divinegift", translate.Get("trait_divinegift"), translate.Get("trait_divinegift_desc"), 20},
	{"merchant", translate.Get("trait_merchant"), translate.Get("trait_merchant_desc"), 25},
	{"belovedcustomer", translate.Get("trait_belovedcustomer"), translate.Get("trait_belovedcustomer_desc"), 20},
	{"gunman", translate.Get("trait_gunman"), translate.Get("trait_gunman_desc"), 20},
	{"experiencedhunter", translate.Get("trait_experiencedhunter"), translate.Get("trait_experiencedhunter_desc"), 20},
	{"demolitionist", translate.Get("trait_demolitionist"), translate.Get("trait_demolitionist_desc"), 35},
	{"bigbang", translate.Get("trait_bigbang"), translate.Get("trait_bigbang_desc"), 30},
	{"combinefellow", translate.Get("trait_combinefellow"), translate.Get("trait_combinefellow_desc"), 25},
	{"crafty", translate.Get("trait_crafty"), translate.Get("trait_crafty_desc"), 20},
	{"pyrotechnics", translate.Get("trait_pyrotechnics"), translate.Get("trait_pyrotechnics_desc"), 20},
	{"mysteriousstranger", translate.Get("trait_mysteriousstranger"), translate.Get("trait_mysteriousstranger_desc"), 25},
	{"technicalaim", translate.Get("trait_technicalaim"), translate.Get("trait_technicalaim_desc"), 25},
	{"cheerleader", translate.Get("trait_cheerleader"), translate.Get("trait_cheerleader_desc"), 20},
	{"glutton", translate.Get("trait_glutton"), translate.Get("trait_glutton_desc"), 20},
	{"junkyard", translate.Get("trait_junkyard"), translate.Get("trait_junkyard_desc"), 20},
	{"gravethief", translate.Get("trait_gravethief"), translate.Get("trait_gravethief_desc"), 25},
	{"luckycrates", translate.Get("trait_luckycrates"), translate.Get("trait_luckycrates_desc"), 30},
	{"headcrabconnoisseur", translate.Get("trait_headcrabconnoisseur"), translate.Get("trait_headcrabconnoisseur_desc"), 20},
	{"deathmark", translate.Get("trait_deathmark"), translate.Get("trait_deathmark_desc"), 25},
	{"drunktard", translate.Get("trait_drunktard"), translate.Get("trait_drunktard_desc"), 20},
	{"dronepilot", translate.Get("trait_dronepilot"), translate.Get("trait_dronepilot_desc"), 30},
	{"tonguelover", translate.Get("trait_tonguelover"), translate.Get("trait_tonguelover_desc"), 35},
	{"explosivetouch", translate.Get("trait_explosivetouch"), translate.Get("trait_explosivetouch_desc"), 35},
	{"parkour", translate.Get("trait_parkour"), translate.Get("trait_parkour_desc"), 30},
	{"alientrainer", translate.Get("trait_alientrainer"), translate.Get("trait_alientrainer_desc"), 35}
}
function GM:BuildTraitCatalog()
	self.TraitLookup, self.TraitNetKeys = {}, {}
	self.TraitWordCount = math.max(1, math.ceil(#self.TraitDefinitions / 31))
	for word = 1, self.TraitWordCount do self.TraitNetKeys[word] = word == 1 and "zs_traits" or "zs_traits_" .. word end
	for index, definition in ipairs(self.TraitDefinitions) do
		local flag = definition[1]
		definition.NameTranslation = "trait_" .. flag
		definition.DescriptionTranslation = definition.NameTranslation .. "_desc"
		definition.TranslatedName, definition.TranslatedDescription = definition[2], definition[3]
		definition.Word = math.floor((index - 1) / 31) + 1
		definition.Mask = 2 ^ ((index - 1) % 31)
		definition.NetKey = self.TraitNetKeys[definition.Word]
		self.TraitLookup[flag] = definition
		if not self.ItemsBySignature["trait_" .. flag] then
			local item = self:AddLocalizedStartingItem("trait_" .. flag, definition.NameTranslation, definition.DescriptionTranslation, ITEMCAT_TRAITS, definition[4], nil,
				function(pl) if SERVER then GAMEMODE:SetPlayerTrait(pl, flag) end end, "models/healthvial.mdl")
			item.WorthTrait = flag
			item.WorthGrantCallback = item.Callback
			if flag == "divinegift" then item.RequiresSigils, item.NoZombieEscape = true, true end
			if flag == "mysteriousstranger" then item.NoZombieEscape = true end
		end
	end
end
GM:BuildTraitCatalog()

function GM:HasPlayerTrait(pl, flag)
	if not IsValid(pl) or not pl:IsPlayer() or pl:Team() ~= TEAM_HUMAN then return false end
	if SERVER then return pl.ZSTraits and pl.ZSTraits[flag] or false end
	local definition = self.TraitLookup[flag]
	return definition ~= nil and bit.band(pl:GetNW2Int(definition.NetKey or "zs_traits", 0), definition.Mask) ~= 0
end

function GM:GetTraitAimScale(pl)
	return self:HasPlayerTrait(pl, "marksman") and 0.9 or 1
end

function GM:GetTraitJumpScale(pl)
	return self:HasPlayerTrait(pl, "acrobatic") and math.sqrt(1.2) or 1
end

function GM:ShouldStaggerAim(pl, health, threshold)
	return health <= threshold and not self:HasPlayerTrait(pl, "steady")
end

function GM:GetTraitSpeedScale(pl)
	if pl:Team() == TEAM_UNDEAD then
		local untilTime
		if SERVER then untilTime = pl.ZSTraitStickyUntil else untilTime = pl:GetNW2Float("zs_trait_sticky", 0) end
		return untilTime and untilTime > CurTime() and 0.9 or 1
	end
	if pl:Team() ~= TEAM_HUMAN then return 1 end
	local scale = (SERVER and pl.ZSTraitCheered == true or not SERVER and pl:GetNW2Bool("zs_trait_cheer", false)) and 1.05 or 1
	if not self:HasPlayerTrait(pl, "kenjutsu") then return scale end
	local weapon = pl:GetActiveWeapon()
	return IsValid(weapon) and weapon:GetClass() == "weapon_zs_katana" and scale * 1.05 or scale
end

function GM:GetTraitSwingScale(weapon)
	return IsValid(weapon) and weapon:GetClass() == "weapon_zs_katana" and self:HasPlayerTrait(weapon:GetOwner(), "kenjutsu") and 1 / 1.1 or 1
end

function GM:GetTraitResupplyCooldown(owner)
	return IsValid(owner) and owner:IsPlayer() and owner:Team() == TEAM_HUMAN and owner.FastResupply and self.ResupplyTimeTrait or self.ResupplyTime
end


function GM:IsTraitHunterWeapon(weapon)
	return IsValid(weapon) and not weapon.IsMelee and (weapon.HoldType == "ar2" or weapon.HoldType == "shotgun" or weapon.Primary and weapon.Primary.Ammo == "buckshot")
		and weapon.Primary and type(weapon.Primary.ClipSize) == "number" and weapon.Primary.ClipSize > 0
end

function GM:GetTraitReloadScale(weapon)
	if not IsValid(weapon) then return 1 end
	local owner = weapon:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() or owner:Team() ~= TEAM_HUMAN then return 1 end
	local gunman, hunter
	if SERVER then
		local flags = owner.ZSTraits
		if not flags then return 1 end
		gunman, hunter = flags.gunman, flags.experiencedhunter
	else
		local flags = owner:GetNW2Int("zs_traits", 0)
		if flags == 0 then return 1 end
		gunman = bit.band(flags, self.TraitLookup.gunman.Mask) ~= 0
		hunter = bit.band(flags, self.TraitLookup.experiencedhunter.Mask) ~= 0
	end
	local scale = gunman and 1.1 or 1
	if hunter and self:IsTraitHunterWeapon(weapon) then scale = scale * 1.05 end
	return scale
end

function GM:GetTraitReloadDelay(weapon)
	return weapon.ReloadDelay / self:GetTraitReloadScale(weapon)
end


function GM:IsTraitExplosivePurchase(item)
	local class = item and item.SWEP
	if type(class) ~= "string" then return false end
	return class == "weapon_zs_grenade" or class == "weapon_zs_detpack"
		or weapons.IsBasedOn(class, "weapon_zs_grenade") or weapons.IsBasedOn(class, "weapon_zs_detpack")
end

function GM:GetTraitArsenalItemScale(pl, item, selected)
	if not item or not item.SWEP then return 1 end
	if selected == nil then selected = self:HasPlayerTrait(pl, "demolitionist") end
	return selected and self:IsTraitExplosivePurchase(item) and 0.7 or 1
end

function GM:IsTraitBlastSource(inflictor)
	if not IsValid(inflictor) then return false end
	local class = inflictor:GetClass()
	return class == "projectile_zsgrenade" or class == "prop_detpack" or inflictor.TraitExplosive
		or inflictor:IsWeapon() and type(inflictor.ExplosionDamage) == "number" and inflictor.ExplosionDamage > 0
end
