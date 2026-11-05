GM.TraitDefinitions = {
	{"marksman", "Marksman", "Weapon spread is reduced by 10%.", 20},
	{"chosenone", "Chosen One", "Deal 5% extra damage to zombie bosses.", 15},
	{"strongfeet", "Strong Feet", "You cannot be knocked down.", 20},
	{"thickskin", "Thick Skin", "Take 20% less damage from zombie slash and club melee attacks.", 25},
	{"acrobatic", "Acrobatic", "Jump 20% higher, including while ghosting through barricades.", 15},
	{"kleiner", "Just Kleiner", "Using the Kleiner model grants 2.5% extra zombie damage and 2.5% resistance to zombie damage.", 10},
	{"venomimmunity", "Venom Immunity", "Poison and acid cannot damage you or trigger their poison effects.", 30},
	{"steady", "Steady", "Low health and Palsy do not shake your aim.", 15},
	{"butcher", "Butcher", "Successful melee hits against infected heal 1 to 3 HP, without exceeding maximum health.", 25},
	{"sniper", "Sniper", "Sniper bullets deal 20% extra damage while grounded and crouching or standing still.", 20},
	{"swordsman", "Swordsman", "Holding a melee weapon gives a 40% chance to block normal zombie melee damage.", 30},
	{"sticky", "Sticky", "A zombie that damages you with a normal melee attack moves 10% slower for three seconds.", 20},
	{"highnoon", "High Noon", "Pistol bullet headshots deal 20% extra damage to infected.", 20},
	{"kenjutsu", "Kenjutsu", "Katana melee damage and attack speed improve by 10%, with 5% extra movement speed while wielding it.", 30},
	{"punisher", "Punisher", "Deal 7.5% extra damage to infected who killed a human this round.", 20},
	{"divinegift", "Divine Gift", "Completed sigil teleports restore 10 HP, without exceeding maximum health.", 20},
	{"merchant", "Merchant", "Other survivors using your arsenal receive 5% off during waves and 10% off between waves.", 25},
	{"belovedcustomer", "Beloved Customer", "Arsenal purchases cost 5% less, including from your own crate.", 20},
	{"gunman", "Gunman", "Reload weapons and vent the Helios 10% faster.", 20},
	{"experiencedhunter", "Experienced Hunter", "Rifles and shotguns reload 5% faster and deal 5% extra bullet damage to infected.", 20},
	{"demolitionist", "Demolitionist", "Grenades and C4 cost 30% less. Your explosives cannot hurt other humans, and human explosions damage you 50% less.", 35},
	{"bigbang", "Big Bang Theory", "Each explosive weapon blast has a 50% chance to deal 25% extra damage.", 30},
	{"combinefellow", "Combine Fellow", "Owned automatic turrets, manhacks, Adonis, Owens, Tosser and Z9000 deal 10% extra damage to infected.", 25},
	{"crafty", "Crafty", "Weapons you craft deal 10% extra damage while you use them, including their projectiles and deployed manhacks.", 20},
	{"pyrotechnics", "Pyrotechnics", "Craft a Molotov cocktail from a newspaper and a glass bottle.", 20},
	{"mysteriousstranger", "Mysterious Stranger", "Each wave intermission gives a 25% chance of a random pistol with a loaded magazine and extra ammunition.", 25},
	{"technicalaim", "Technical Aim", "Your automatic turrets seek the nearest visible undead within their firing arc and range.", 25},
	{"cheerleader", "Cheerleader", "Other living survivors within 256 units move 5% faster. Multiple Cheerleaders do not stack.", 20},
	{"glutton", "Glutton", "Eat melons and fruit or drink milk from props to recover health.", 20},
	{"junkyard", "Junkyard", "Convert discarded boots, cans, plastic bottles and other rubbish props into ammunition for your held firearm.", 20},
	{"gravethief", "Gravethief", "Zombie kills have a 10% chance to drop one or two random ammo boxes. Boss kills have a 50% chance to drop two or four.", 25},
	{"luckycrates", "Lucky Crates", "Breaking wooden crates has a 20% chance to reveal a random weapon, with low-cost weapons more common. Otherwise find two or three random ammo boxes.", 30},
	{"headcrabconnoisseur", "Headcrab Connoisseur", "Eat headcrab ragdolls with Use to restore up to 10 HP.", 20},
	{"deathmark", "Death Mark", "Consecutive sniper hits against the same infected build 5% extra damage per hit, up to 30%. A failed hit resets the streak.", 25},
	{"drunktard", "Drunktard", "Consume glass bottles for health or ammunition, with a rare weapon reward. Your view sways slightly for ten seconds.", 20},
	{"dronepilot", "Drone Pilot", "Reload your manhack controller to attach a gun. While controlling it, secondary fire uses one SMG round per shot.", 30},
	{"tonguelover", "Tongue Lover", "Grow allied barnacles on ceilings with a cultivator. Two per survivor, a 30-second cooldown, double bite damage and improved resistance.", 35},
	{"explosivetouch", "Explosive Touch", "Your nailed props and deployable equipment explode like a grenade when destroyed by zombies.", 35},
	{"parkour", "Parkour Expert", "With fists, hold Reload in the air to grip a wall. Forward climbs up to 96 units; Jump pushes off. Three seconds per grip, reset by landing.", 30},
	{"alientrainer", "Alien Trainer", "Start with three genuine Snark charges. Three active companions per survivor, twelve-second lifespan, and removal after two seconds without nearby zombies. Snarks only damage infected.", 35}
}
function GM:BuildTraitCatalog()
	self.TraitLookup, self.TraitNetKeys = {}, {}
	self.TraitWordCount = math.max(1, math.ceil(#self.TraitDefinitions / 31))
	for word = 1, self.TraitWordCount do self.TraitNetKeys[word] = word == 1 and "zs_traits" or "zs_traits_" .. word end
	for index, definition in ipairs(self.TraitDefinitions) do
		local flag = definition[1]
		definition.Word = math.floor((index - 1) / 31) + 1
		definition.Mask = 2 ^ ((index - 1) % 31)
		definition.NetKey = self.TraitNetKeys[definition.Word]
		self.TraitLookup[flag] = definition
		if not self.ItemsBySignature["trait_" .. flag] then
			local item = self:AddStartingItem("trait_" .. flag, definition[2], definition[3], ITEMCAT_TRAITS, definition[4], nil,
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
