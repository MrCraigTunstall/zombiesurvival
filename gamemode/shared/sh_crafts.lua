GM.CraftingRange = 72

GM.Crafts = {
	{
		Name = "a big wooden crate",
		a = {"*physics*", {"models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_crate001a_damaged.mdl", "models/props_junk/wood_crate001a_damagedmax.mdl"}},
		b = {"*physics*", {"models/props_junk/wood_crate001a.mdl", "models/props_junk/wood_crate001a_damaged.mdl", "models/props_junk/wood_crate001a_damagedmax.mdl"}},
		Result = {"prop_physics", Model("models/props_junk/wood_crate002a.mdl")}
	},
    {
		Name = "a electric shovel",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/items/car_battery01.mdl") and entb:IsWeaponType("weapon_zs_shovel")
		end,
		Result = {"weapon_zs_electricshovel"}
	},
    {
		Name = "a 'infinity' plank",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_plank") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_infinityplank"}
	},
    {
		Name = "a 'infinochet' handgun",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_magnum") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_infinochet"}
	},
    {
		Name = "a medkit god",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_medicalkit") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_medicgod"}
	},
    {
		Name = "a 'crossfire' glock 9",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_glock3") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_glock9"}
	},
    {
		Name = "a empowered crowbar",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_crowbar") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_empoweredcrowbar"}
	},
    {
		Name = "a hammergod",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_hammer", "weapon_zs_electrohammer") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_hammergod"}
	},
    {
		Name = "a 'redemption' desert eagles",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_deagle") and entb:IsWeaponType("weapon_zs_redeemers")
		end,
		Result = {"weapon_zs_deagleredeemers"}
	},
    {
		Name = "a explosive 'redeemers' dual handguns",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_c17/oildrum001_explosive.mdl") and entb:IsWeaponType("weapon_zs_redeemers")
		end,
		Result = {"weapon_zs_explosiveredeemers"}
	},
    {
		Name = "a dual boom stick",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_boomstick") and entb:IsWeaponType("weapon_zs_boomstick")
		end,
		Result = {"weapon_zs_dualboomstick"}
	},
    {
		Name = "a empowered shovel",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_shovel") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_empoweredshovel"}
	},
    {
		Name = "a empowered kongol axe",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_kongol") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_empoweredkongol"}
	},
    {
		Name = "a jet hammer",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_sledgehammer") and entb:IsPhysicsModel("models/props_c17/trappropeller_engine.mdl")
		end,
		Result = {"weapon_zs_jethammer"}
	},
    {
		Name = "a kongol axe",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_axe") and entb:IsWeaponType("weapon_zs_shovel")
		end,
		Result = {"weapon_zs_kongol"}
	},
    {
		Name = "a volcano arm handgun",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_infinity") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_volcanoarm"}
	},
    {
		Name = "a multi-inferno aug",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_inferno") and entb:IsWeaponType("weapon_zs_empower")
		end,
		Result = {"weapon_zs_multiinferno"}
	},
	{
		Name = "a explosive crowbar",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_c17/oildrum001_explosive.mdl") and entb:IsWeaponType("weapon_zs_crowbar")
		end,
		Result = {"weapon_zs_explosivecrowbar"}
	},
	{
		Name = "a bust-on-a-stick",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_combine/breenbust.mdl") and entb:IsWeaponType("weapon_zs_plank")
		end,
		Result = {"weapon_zs_bust"}
	},
	{
		Name = "an oil-filled barrel",
		a = {"*physics*", "models/props_junk/gascan001a.mdl"},
		b = {"*physics*", "models/props_c17/oildrum001.mdl"},
		Result = {"prop_physics", Model("models/props_c17/oildrum001_explosive.mdl")}
	},
	{
		Name = "a sawhack",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_junk/sawblade001a.mdl") and entb:IsWeaponType("weapon_zs_axe")
		end,
		Result = {"weapon_zs_sawhack"}
	},
	{
		Name = "a mega masher",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_c17/oildrum001_explosive.mdl") and entb:IsWeaponType("weapon_zs_sledgehammer")
		end,
		Result = {"weapon_zs_megamasher"}
	},
	{
		Name = "an electrohammer",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/items/car_battery01.mdl") and entb:IsWeaponType("weapon_zs_hammer")
		end,
		Result = {"weapon_zs_electrohammer"}
	},
	{
		Name = "a 'Waraxe' handgun",
		callback = function(enta, entb)
			return enta:IsWeaponType("weapon_zs_battleaxe") and entb:IsWeaponType("weapon_zs_battleaxe")
		end,
		Result = {"weapon_zs_waraxe"}
	},
	{
		Name = "a modified manhack",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_junk/sawblade001a.mdl") and entb:IsWeaponType("weapon_zs_manhack")
		end,
		Result = {"weapon_zs_manhack_saw"}
	},
	{
		Name = "a Molotov cocktail",
		RequiredTrait = "pyrotechnics",
		callback = function(enta, entb)
			return enta:IsPhysicsModel("models/props_junk/garbage_newspaper001a.mdl") and entb:IsGlassCraftBottle()
		end,
		Result = {"weapon_zs_molotov"}
	}
}

local builtinCallbacks = {}
for _, recipe in ipairs(GM.Crafts) do if recipe.callback then builtinCallbacks[recipe.callback] = true end end
local isPhysicsModel, isWeaponType, isGlassCraftBottle, isPhysicsProp
local recipeMatches

local function PairLive(enta, entb)
	return IsValid(enta) and IsValid(entb) and enta ~= entb and not enta:IsMarkedForDeletion() and not entb:IsMarkedForDeletion()
end

local function AvailablePair(enta, entb)
	return PairLive(enta, entb) and not enta._USEDINCRAFTING and not entb._USEDINCRAFTING and not enta._ZS_CRAFTING and not entb._ZS_CRAFTING
end

local function CraftStateLive(pl, enta, entb)
	return IsValid(pl) and pl:Alive() and pl:Team() == TEAM_HUMAN and AvailablePair(enta, entb)
		and (not SERVER or pl:IsConnected())
end

local cachedMethods = {}
function cachedMethods:IsPhysicsModel(expected)
	if self.physics == nil then self.physics = self.entity:IsAPhysicsProp() end
	if not self.physics then return false end
	if not expected then return true end
	if self.model == nil then self.model = string.lower(self.entity:GetModel() or "") end
	return self.model == string.lower(expected)
end

function cachedMethods:IsWeaponType(...)
	if self.weapon == nil then
		local class = self.entity:GetClass()
		if class == "prop_weapon" then self.weapon = self.entity:GetWeaponType()
		else self.weapon = self.entity:IsWeapon() and class or false end
	end
	for index = 1, select("#", ...) do if self.weapon == select(index, ...) then return true end end
	return false
end

function cachedMethods:IsGlassCraftBottle()
	if self.bottle == nil then self.bottle = self.entity:IsGlassCraftBottle() end
	return self.bottle
end

local cachedMeta = {__index = cachedMethods}
local function Cacheable(ent)
	if not isPhysicsProp then
		local candidate = FindMetaTable("Entity").IsAPhysicsProp
		local info = candidate and debug.getinfo(candidate, "S")
		if info and string.find(info.source, "obj_entity_extend.lua", 1, true) then isPhysicsProp = candidate end
	end
	return ent.IsPhysicsModel == isPhysicsModel and ent.IsWeaponType == isWeaponType and ent.IsGlassCraftBottle == isGlassCraftBottle
		and ent.IsAPhysicsProp == isPhysicsProp
end

local function ModelMatches(ent, expected)
	if expected == nil then return true end
	local model = string.lower(ent:GetModel() or "")
	if type(expected) == "table" then
		for _, candidate in ipairs(expected) do if type(candidate) == "string" and model == string.lower(candidate) then return true end end
		return false
	end
	return type(expected) == "string" and model == string.lower(expected)
end

local function DescriptorMatches(ent, descriptor)
	if type(descriptor) ~= "table" then return false end
	local class = ent:GetClass()
	return (descriptor[1] == class or descriptor[1] == "*physics*" and string.sub(class, 1, 12) == "prop_physics")
		and ModelMatches(ent, descriptor[2])
end

local function Match(enta, entb, recipe, left, right)
	if not left and not PairLive(enta, entb) or type(recipe) ~= "table" then return false end
	if type(recipe.callback) == "function" then
		local a, b = left or enta, right or entb
		local matched = recipe.callback(a, b)
		if not left and not PairLive(enta, entb) then return false end
		if matched then return true end
		matched = recipe.callback(b, a)
		if not left and not PairLive(enta, entb) then return false end
		if matched then return true end
	end
	return DescriptorMatches(enta, recipe.a) and DescriptorMatches(entb, recipe.b)
		or DescriptorMatches(entb, recipe.a) and DescriptorMatches(enta, recipe.b)
end

function GM:GetCraftingRecipe(enta, entb)
	if not AvailablePair(enta, entb) then return end
	local left, right
	for _, recipe in ipairs(self.Crafts) do
		local matched, cached
		local ownMatch = self.CraftingRecipeMatches == recipeMatches
		if ownMatch and type(recipe) == "table" and recipe.a == nil and recipe.b == nil and builtinCallbacks[recipe.callback]
			and (left or Cacheable(enta) and Cacheable(entb)) then
			if not left then left, right = setmetatable({entity = enta}, cachedMeta), setmetatable({entity = entb}, cachedMeta) end
			matched = Match(enta, entb, recipe, left, right)
			cached = true
		elseif ownMatch then
			left, right = nil, nil
			matched = Match(enta, entb, recipe)
		else left, right = nil, nil; matched = self:CraftingRecipeMatches(enta, entb, recipe) end
		if not cached and not AvailablePair(enta, entb) then return end
		if matched then return recipe end
	end
end

function GM:GetCraftTarget(enta, entb)
	return enta:OBBMaxs():DistToSqr(enta:OBBMins()) > entb:OBBMaxs():DistToSqr(entb:OBBMins()) and enta or entb
end

function GM:CraftingRecipeMatches(enta, entb, recipe)
	return Match(enta, entb, recipe)
end
recipeMatches = GM.CraftingRecipeMatches

function GM:CanCraft(pl, enta, entb, recipe)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN
		or not AvailablePair(enta, entb) then return false end
	if SERVER and not pl:IsConnected() then return false end
	if recipe then if not self:CraftingRecipeMatches(enta, entb, recipe) then return false end
	else recipe = self:GetCraftingRecipe(enta, entb); if not recipe then return false end end
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or not AvailablePair(enta, entb)
		or SERVER and not pl:IsConnected() then return false end
	if recipe.RequiredTrait and not self:HasPlayerTrait(pl, recipe.RequiredTrait) then return false end
	local aWeapon, bWeapon = enta:IsWeapon(), entb:IsWeapon()
	if aWeapon and enta:GetOwner() ~= pl or bWeapon and entb:GetOwner() ~= pl then return false end
	if enta:IsBarricadeProp() or entb:IsBarricadeProp() or enta:GetName() ~= "" or entb:GetName() ~= "" then return false end
	local eye, range = pl:EyePos(), self.CraftingRange
	if aWeapon or bWeapon then
		local other = aWeapon and entb or enta
		local nearest = other:NearestPoint(eye)
		return eye:DistToSqr(nearest) <= (range * 1.7) ^ 2 and TrueVisibleFilters(nearest, eye, pl, enta, entb) and CraftStateLive(pl, enta, entb)
	end
	local nearestb = entb:NearestPoint(enta:LocalToWorld(enta:OBBCenter()))
	local nearesta = enta:NearestPoint(entb:LocalToWorld(entb:OBBCenter()))
	local squared = range * range
	if nearesta:DistToSqr(nearestb) > squared or enta:NearestPoint(eye):DistToSqr(eye) > squared or entb:NearestPoint(eye):DistToSqr(eye) > squared then return false end
	return TrueVisibleFilters(nearesta, nearestb, pl, enta, entb)
		and TrueVisibleFilters(nearesta, eye, pl, enta, entb) and TrueVisibleFilters(nearestb, eye, pl, enta, entb) and CraftStateLive(pl, enta, entb)
end

local meta = FindMetaTable("Entity")

function meta:IsGlassCraftBottle()
	if not self:IsAPhysicsProp() then return false end
	local model = string.lower(self:GetModel() or "")
	if string.find(model, "glassbottle", 1, true) then return true end
	if not string.find(model, "bottle", 1, true) then return false end
	local physics = self:GetPhysicsObject()
	return IsValid(physics) and string.find(string.lower(physics:GetMaterial() or ""), "glass", 1, true) ~= nil
end

function meta:IsPhysicsModel(model)
	return self:IsAPhysicsProp() and (not model or string.lower(self:GetModel() or "") == string.lower(model))
end

function meta:IsWeaponType(...)
	local class = self:GetClass()
	if class == "prop_weapon" then class = self:GetWeaponType()
	elseif not self:IsWeapon() then return false end
	for index = 1, select("#", ...) do if class == select(index, ...) then return true end end
	return false
end

isPhysicsModel, isWeaponType, isGlassCraftBottle, isPhysicsProp = meta.IsPhysicsModel, meta.IsWeaponType, meta.IsGlassCraftBottle, meta.IsAPhysicsProp
