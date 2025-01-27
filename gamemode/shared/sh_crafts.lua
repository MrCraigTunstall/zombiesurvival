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
	}
}

local pairs = pairs
local string = string
local string_sub = string.sub
local string_lower = string.lower
local table = table
local table_HasValue = table.HasValue
local type = type
local table_insert = table.insert
local ents = ents
local ents_FindInSphere = ents.FindInSphere
local FindMetaTable = FindMetaTable

function GM:GetCraftingRecipe(enta, entb)
	if not IsValid(enta) or not IsValid(entb) or enta == entb then return end

	for _, recipe in pairs(self.Crafts) do
		if self:CraftingRecipeMatches(enta, entb, recipe) then return recipe end
	end
end

function GM:GetCraftTarget(enta, entb)
	return enta:OBBMaxs():Distance(enta:OBBMins()) > entb:OBBMaxs():Distance(entb:OBBMins()) and enta or entb
end

function GM:CraftingRecipeMatches(enta, entb, recipe, checkedswap)
	local entaclass = enta:GetClass()
	local entbclass = entb:GetClass()
	local entaisphysics = string_sub(entaclass, 1, 12) == "prop_physics"
	local entbisphysics = string_sub(entbclass, 1, 12) == "prop_physics"

	if recipe.callback and recipe.callback(enta, entb) then
		return true
	end

	if recipe.a and recipe.b and (recipe.a[1] == entaclass or entaisphysics and recipe.a[1] == "*physics*") and (recipe.b[1] == entbclass or entaisphysics and recipe.a[1] == "*physics*") then
		local mdla = string_lower(enta:GetModel())
		local mdlb = string_lower(entb:GetModel())
		if (recipe.a[2] == nil or type(recipe.a[2]) == "table" and table_HasValue(recipe.a[2], mdla) or mdla == recipe.a[2]) and (recipe.b[2] == nil or type(recipe.b[2]) == "table" and table_HasValue(recipe.b[2], mdlb) or mdlb == recipe.b[2]) then
			return true
		end
	end

	if not checkedswap then
		return self:CraftingRecipeMatches(entb, enta, recipe, true)
	end
end

function GM:CanCraft(pl, enta, entb, checkedrec)
	if (not checkedrec and self:GetCraftingRecipe(enta, entb) == nil) or not IsValid(pl) or not pl:Alive() or pl:Team() == TEAM_UNDEAD then return false end

	if enta:IsWeapon() then -- Handle weapons differently.
		if entb:IsBarricadeProp() or entb:GetName() ~= "" then return false end
		
		local plpos = pl:EyePos()
		local nearest = entb:NearestPoint(plpos)
		if nearest:Distance(plpos) > (self.CraftingRange*1.7) or not TrueVisibleFilters(nearest, plpos, pl, entb) then return false end
		return true
	end

	if enta:IsBarricadeProp() or entb:IsBarricadeProp() or enta:GetName() ~= "" or entb:GetName() ~= "" then return false end

	local nearestb = entb:NearestPoint(enta:LocalToWorld(enta:OBBCenter()))
	local nearesta = enta:NearestPoint(entb:LocalToWorld(entb:OBBCenter()))
	if nearesta:Distance(nearestb) > self.CraftingRange or not TrueVisibleFilters(nearesta, nearestb, pl, enta, entb) then return false end

	local eyepos = pl:EyePos()
	if enta:NearestPoint(eyepos):Distance(eyepos) > self.CraftingRange or entb:NearestPoint(eyepos):Distance(eyepos) > self.CraftingRange then return false end

	if not TrueVisibleFilters(nearesta, eyepos, pl, enta, entb) or not TrueVisibleFilters(nearestb, eyepos, pl, enta, entb) then return false end

	return true
end

local meta = FindMetaTable("Entity")
if not meta then return end

function meta:IsPhysicsModel(mdl)
	return self:IsAPhysicsProp() and (not mdl or string_lower(self:GetModel()) == string_lower(mdl))
end

function meta:IsWeaponType(class)
	return self:GetClass() == "prop_weapon" and self:GetWeaponType() == class
end

if true then return end

function GM:GetCraftingRecipe(enta, entb)
	if not IsValid(enta) or not IsValid(entb) or enta == entb then return end

	for _, recipe in pairs(self.Crafts) do
		if self:CraftingRecipeMatches(enta, entb, recipe) then return recipe end
	end
end

function GM:GetCraftTarget(enta, entb)
	return enta:OBBMaxs():Distance(enta:OBBMins()) > entb:OBBMaxs():Distance(entb:OBBMins()) and enta or entb
end

function GM:CraftingRecipeMatches(enta, entb, recipe, checkedswap)
	local entaclass = enta:GetClass()
	local entbclass = entb:GetClass()
	local entaisphysics = string_sub(entaclass, 1, 12) == "prop_physics"
	local entbisphysics = string_sub(entbclass, 1, 12) == "prop_physics"

	if recipe.callback and recipe.callback(enta, entb) then
		return true
	end

	if recipe.a and recipe.b and (recipe.a[1] == entaclass or entaisphysics and recipe.a[1] == "*physics*") and (recipe.b[1] == entbclass or entaisphysics and recipe.a[1] == "*physics*") then
		local mdla = string_lower(enta:GetModel())
		local mdlb = string_lower(entb:GetModel())
		if (recipe.a[2] == nil or type(recipe.a[2]) == "table" and table_HasValue(recipe.a[2], mdla) or mdla == recipe.a[2]) and (recipe.b[2] == nil or type(recipe.b[2]) == "table" and table_HasValue(recipe.b[2], mdlb) or mdlb == recipe.b[2]) then
			return true
		end
	end

	if not checkedswap then
		return self:CraftingRecipeMatches(entb, enta, recipe, true)
	end
end

function GM:GetAllValidCraftingRecipes(pl)
	local craftable = {}

	for _, craft in pairs(self.Crafts) do
		if self:CanCraftAll(pl, craft) then
			table_insert(craftable, craft)
		end
	end

	return craftable
end

-- Preliminary tests for all entity types.
-- Classes are enforced by the recipes so if someone makes a recipe inolving players or worldspawn then oh well.
function GM:IsValidCraftingEntity(ent, pl)
	return not ent:IsWeapon()
	and not (ent:IsPhysicsModel() and ent:GetName() ~= "")
	and not (ent:IsWeapon() and ent:GetOwner() ~= pl)
end

-- This checks everything and is what determines if a recipe displays to the player in their menu.
function GM:CanCraftAll(pl, craft)
	if not IsValid(pl) or not pl:Alive() or pl:Team() == TEAM_UNDEAD then return false end

	local plpos = pl:EyePos()
	--local entities = ents_FindInSphere(plpos, self.CraftingRange)
	local entities = util.FindRadiusEntities(plpos,self.CraftingRange)

	if craft.CanCraft and not craft:CanCraft(pl, entities, plpos) then return false end

	local ingredients = {}

	for _, ent in pairs(entities) do
		if craft.CanUseEntity and not craft:CanUseEntity(ent, pl) then continue end
	end

	-- All ingredients accounted for?
	--for _, ingredient

	local nearestb = entb:NearestPoint(enta:LocalToWorld(enta:OBBCenter()))
	local nearesta = enta:NearestPoint(entb:LocalToWorld(entb:OBBCenter()))
	if nearesta:Distance(nearestb) > self.CraftingRange or not TrueVisibleFilters(nearesta, nearestb, pl, enta, entb) then return false end

	local eyepos = pl:EyePos()
	if enta:NearestPoint(eyepos):Distance(eyepos) > self.CraftingRange or entb:NearestPoint(eyepos):Distance(eyepos) > self.CraftingRange then return false end

	if not TrueVisibleFilters(nearesta, eyepos, pl, enta, entb) or not TrueVisibleFilters(nearestb, eyepos, pl, enta, entb) then return false end

	return true
end

local meta = FindMetaTable("Entity")
if not meta then return end

function meta:IsPhysicsModel(mdl)
	return self:IsAPhysicsProp() and (not mdl or string_lower(self:GetModel()) == string_lower(mdl))
end
