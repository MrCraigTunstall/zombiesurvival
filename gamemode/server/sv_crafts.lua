local function Registered(gm, recipe)
	for _, candidate in ipairs(gm.Crafts) do if candidate == recipe then return true end end
	return false
end

local function AliveEntity(ent)
	return IsValid(ent) and not ent:IsMarkedForDeletion()
end

function GM:CraftItem(pl, recipe, enta, entb)
	if not IsValid(pl) or pl.ZSCraftingBusy or not Registered(self, recipe) then return false end
	pl.ZSCraftingBusy = true
	local produced
	local ok, granted = pcall(function()
		if not self:CanCraft(pl, enta, entb, recipe) then return false end
		local handlers = hook.GetTable().CanCraft
		if handlers and next(handlers) then
			if gamemode.Call("CanCraft", pl, enta, entb, recipe) == false or not Registered(self, recipe) or not self:CanCraft(pl, enta, entb, recipe) then return false end
		end
		if not IsValid(pl) or not AliveEntity(enta) or not AliveEntity(entb) or enta._USEDINCRAFTING or entb._USEDINCRAFTING or enta._ZS_CRAFTING or entb._ZS_CRAFTING then return false end
		enta._ZS_CRAFTING = pl; entb._ZS_CRAFTING = pl
		if recipe.OnCraft and recipe.OnCraft(pl, enta, entb) then return true end
		local result = recipe.Result
		local class = type(result) == "table" and result[1]
		if type(class) ~= "string" or class == "" then return false end
		local weapon = string.sub(class, 1, 7) == "weapon_"
		local stored = weapon and weapons.GetStored(class)
		if weapon and not stored then return false end
		if weapon and not pl:HasWeapon(class) then
			produced = pl:Give(class)
			if not AliveEntity(produced) then return false end
		elseif weapon and stored.AmmoIfHas then
			local primary = stored.Primary
			if not primary or type(primary.DefaultClip) ~= "number" or primary.DefaultClip <= 0 or type(primary.Ammo) ~= "string" then return false end
			if pl:GiveAmmo(primary.DefaultClip, primary.Ammo) <= 0 then return false end
		else
			local target = self:GetCraftTarget(enta, entb)
			produced = ents.Create(weapon and "prop_weapon" or class)
			if not AliveEntity(produced) then return false end
			produced:SetPos(target:GetPos()); produced:SetAngles(target:GetAngles())
			if weapon then produced:SetWeaponType(class)
			elseif result[2] then produced:SetModel(result[2]) end
			produced:Spawn()
			if not AliveEntity(produced) then return false end
			if not weapon then
				if recipe.OnCrafted then recipe.OnCrafted(pl, recipe, enta, entb, produced) end
				if not AliveEntity(produced) then return false end
				produced:TemporaryBarricadeObject()
			end
			local physics = produced:GetPhysicsObject()
			if IsValid(physics) then physics:Wake(); physics:SetVelocity(target:GetVelocity()) end
		end
		if weapon and AliveEntity(produced) then produced.ZSCrafter = pl end
		if IsValid(enta) then enta._USEDINCRAFTING = true; enta:Remove() end
		if IsValid(entb) then entb._USEDINCRAFTING = true; entb:Remove() end
		return true
	end)
	pl.ZSCraftingBusy = nil
	if IsValid(enta) and enta._ZS_CRAFTING == pl then enta._ZS_CRAFTING = nil end
	if IsValid(entb) and entb._ZS_CRAFTING == pl then entb._ZS_CRAFTING = nil end
	if not ok or not granted then
		if IsValid(produced) then produced:Remove() end
		if not ok then ErrorNoHalt("ZS crafting: " .. tostring(granted) .. "\n") end
		return false
	end
	if IsValid(pl) and not pl:IsBot() then
		pl:CenterNotify(COLOR_LIMEGREEN, translate.ClientGet(pl, "crafting_successful"), color_white, "   (" .. recipe.Name .. ")")
		pl:SendLua("surface.PlaySound(\"buttons/lever" .. math.random(5) .. ".wav\")")
		print(translate.Format("x_crafted_y", pl:Name(), recipe.Name))
	end
	return true, produced
end

local function Sender(pl)
	return IsValid(pl) and pl:IsPlayer() and pl:IsConnected() and pl:Alive() and pl:Team() == TEAM_HUMAN
end

local function Index(value)
	local index = tonumber(value)
	return index and index == math.floor(index) and index > 0 and index < 65536 and index or nil
end

concommand.Add("_zs_craftcombine", function(sender, _, arguments)
	if not Sender(sender) or type(arguments) ~= "table" or #arguments ~= 2 then return end
	local now = CurTime()
	if now < (sender.ZSNextCraftRequest or 0) then return end
	sender.ZSNextCraftRequest = now + 0.2
	local a, b = Index(arguments[1]), Index(arguments[2])
	if not a or not b or a == b then return end
	local enta, entb = Entity(a), Entity(b)
	local recipe = GAMEMODE:GetCraftingRecipe(enta, entb)
	if recipe then gamemode.Call("CraftItem", sender, recipe, enta, entb) end
end)

concommand.Add("_zs_useobject", function(sender, _, arguments)
	if not Sender(sender) or type(arguments) ~= "table" or #arguments < 2 or #arguments > 8 then return end
	local now = CurTime()
	if now < (sender.ZSNextObjectAction or 0) then return end
	sender.ZSNextObjectAction = now + 0.1
	local index, action = Index(arguments[1]), arguments[2]
	if not index or type(action) ~= "string" or #action == 0 or #action > 32 or not string.match(action, "^[%w_]+$") then return end
	local ent = Entity(index)
	if not IsValid(ent) then return end
	local callback = ent["Action_" .. string.upper(action)]
	if type(callback) ~= "function" then return end
	local eye = sender:EyePos(); local nearest = ent:NearestPoint(eye)
	if eye:DistToSqr(nearest) > 64 * 64 or not TrueVisibleFilters(eye, nearest, sender, ent) then return end
	local ok, failure = pcall(callback, ent, sender, unpack(arguments, 3))
	if not ok then ErrorNoHalt("ZS object action: " .. tostring(failure) .. "\n") end
end)
