local foods = {
	["models/props_junk/watermelon01.mdl"] = 15,
	["models/props_junk/garbage_milkcarton001a.mdl"] = 10,
	["models/props_junk/garbage_milkcarton002a.mdl"] = 10,
	["models/props/cs_italy/bananna.mdl"] = 5,
	["models/props/cs_italy/bananna_bunch.mdl"] = 10,
	["models/props/cs_italy/orange.mdl"] = 5
}

function GM:TryTraitFood(pl, ent)
	if self.RoundEnded or not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or not self:HasPlayerTrait(pl, "glutton")
	 or pl:GetBarricadeGhosting() or pl:IsCarrying() or not IsValid(ent) or ent.ZSTraitConsumed
	 or ent.IsMarkedForDeletion and ent:IsMarkedForDeletion() then return false end
	local amount = foods[string.lower(ent:GetModel() or "")]
	if not amount or string.sub(ent:GetClass(), 1, 12) ~= "prop_physics" or ent.m_NoPickup or ent.NoTraitConsume or ent:IsNailed() then return false end
	local health, maximum = pl:Health(), pl:GetMaxHealth()
	if maximum <= 0 or health >= maximum then return false end
	local now = CurTime()
	if now < (pl.ZSTraitFoodNext or 0) then return false end
	local position = pl:GetShootPos()
	if position:DistToSqr(ent:NearestPoint(position)) > 64 * 64 or ent:GetHolder()
	 or pl:TraceLine(64, MASK_SOLID, pl).Entity ~= ent then return false end
	ent.ZSTraitConsumed = true
	pl.ZSTraitFoodNext = now + 0.25
	pl:SetHealth(math.min(maximum, health + amount))
	ent:Remove()
	pl:EmitSound("npc/barnacle/barnacle_gulp1.wav")
	return true
end

local junk = {
	["models/props_junk/shoe001a.mdl"] = true,
	["models/props_junk/popcan01a.mdl"] = true,
	["models/props_junk/garbage_metalcan001a.mdl"] = true,
	["models/props_junk/garbage_metalcan002a.mdl"] = true,
	["models/props_junk/garbage_plasticbottle001a.mdl"] = true,
	["models/props_junk/garbage_plasticbottle002a.mdl"] = true,
	["models/props_junk/garbage_takeoutcarton001a.mdl"] = true,
	["models/props_junk/garbage_coffeemug001a.mdl"] = true,
	["models/props_junk/garbage_newspaper001a.mdl"] = true
}

local gunholds = {pistol = true, revolver = true, smg = true, ar2 = true, shotgun = true, crossbow = true, rpg = true, duel = true, physgun = true}

function GM:TryTraitJunk(pl, ent)
	if self.RoundEnded or not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or not self:HasPlayerTrait(pl, "junkyard")
		or pl:GetBarricadeGhosting() or pl:IsCarrying() or not IsValid(ent) or ent.ZSTraitConsumed
		or ent.IsMarkedForDeletion and ent:IsMarkedForDeletion() then return false end
	if not junk[string.lower(ent:GetModel() or "")] or string.sub(ent:GetClass(), 1, 12) ~= "prop_physics"
		or ent.m_NoPickup or ent.NoTraitConsume or ent:IsNailed() then return false end
	local weapon = pl:GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetOwner() ~= pl or weapon.IsMelee or not gunholds[weapon.HoldType or weapon:GetHoldType()] then return false end
	local primary = weapon.Primary
	local clip = primary and primary.ClipSize
	if type(clip) ~= "number" or clip ~= clip or clip <= 0 or clip >= math.huge then return false end
	local ammo = weapon:GetPrimaryAmmoType()
	if type(ammo) ~= "number" or ammo ~= ammo or ammo < 0 or ammo >= math.huge or ammo ~= math.floor(ammo) or not game.GetAmmoName(ammo) then return false end
	local now = CurTime()
	if now < (pl.ZSTraitFoodNext or 0) then return false end
	local position = pl:GetShootPos()
	if position:DistToSqr(ent:NearestPoint(position)) > 64 * 64 or ent:GetHolder()
		or pl:TraceLine(64, MASK_SOLID, pl).Entity ~= ent then return false end
	local before = pl:GetAmmoCount(ammo)
	ent.ZSTraitConsumed = true
	local ok = pcall(pl.GiveAmmo, pl, math.min(30, math.max(1, math.ceil(clip * 0.25))), ammo, true)
	if not ok then
		pl:SetAmmo(before, ammo)
		ent.ZSTraitConsumed = nil
		return false
	end
	if pl:GetAmmoCount(ammo) <= before then ent.ZSTraitConsumed = nil;return false end
	pl.ZSTraitFoodNext = now + 0.25
	ent:Remove()
	pl:EmitSound("items/ammo_pickup.wav")
	return true
end

local function ClearFood(pl) pl.ZSTraitFoodNext = nil end
hook.Add("PlayerDeath", "ZSTraitFood", ClearFood)
hook.Add("OnPlayerChangedTeam", "ZSTraitFood", ClearFood)
hook.Add("PlayerDisconnected", "ZSTraitFood", ClearFood)
