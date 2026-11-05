GM.Mutations = GM.Mutations or {}
GM.MutationsBySignature = GM.MutationsBySignature or {}
GM.MutationIDsBySignature = GM.MutationIDsBySignature or {}
for index, mutation in ipairs(GM.Mutations) do GM.MutationIDsBySignature[mutation.Signature] = index end

function GM:AddMutation(signature, name, desc, category, worth, swep, callback, model, worthshop, mutationshop)
	local tab = {Signature = signature, Name = name, Description = desc, Category = category, Worth = worth or 0, SWEP = swep, Callback = callback, Model = model, WorthShop = worthshop, MutationShop = mutationshop}
	local index = self.MutationIDsBySignature[signature] or #self.Mutations + 1
	self.Mutations[index] = tab
	self.MutationIDsBySignature[signature] = index
	self.MutationsBySignature[signature] = tab

	return tab
end

function GM:AddMutationItem(signature, name, desc, category, brains, worth, callback, model)
	return self:AddMutation(signature, name, desc, category, brains, worth, callback, model, false, true)
end

function FindMutation(id)
	if type(id) ~= "string" and type(id) ~= "number" then return end
	local num = tonumber(id)
	local mutation
	if num then
		if num % 1 ~= 0 then return end
		mutation = GAMEMODE.Mutations[num]
	else
		mutation = GAMEMODE.MutationsBySignature[id]
	end
	if mutation and mutation.MutationShop then return mutation end
end

function GM:ZombieCanPurchase(pl)
	return not self.RoundEnded and pl:Team() == TEAM_UNDEAD and self:GetWave() > 0
end

GM.MutationEffectFlags = {
	m_zombie_health = "m_Zombie_Health",
	m_zombie_moan = "m_Zombie_Moan",
	m_zombie_moanguard = "m_Zombie_MoanGuard",
	m_shade_damage = "m_Shade_Force",
	m_zombie_armor = "m_Zombie_Armor",
	m_zombie_tough = "m_Zombie_Tough"
}

function GM:ResetMutationEffects(pl)
	for _, flag in pairs(self.MutationEffectFlags) do pl[flag] = nil end
end

function GM:ApplyMutationOwnershipFlags(pl, used)
	self:ResetMutationEffects(pl)
	for _, signature in ipairs(used or {}) do
		local flag = self.MutationEffectFlags[signature]
		if flag then pl[flag] = true end
	end
end

GM.MaxMutationPurchaseItems = 32
GM.MaxMutationStateEntries = 1024
GM.MaxMutationSignatureBytes = 256
GM.MaxMutationStateBytes = 60000

local function ValidMutationSignature(signature, maxBytes)
	return type(signature) == "string" and #signature > 0 and #signature <= maxBytes and not string.find(signature, "\0", 1, true)
end

function GM:GetMutationStateSize(used)
	if used == nil then return 0, 2 end
	if type(used) ~= "table" or #used > self.MaxMutationStateEntries then return end
	local size = 2
	for i = 1, #used do
		if not ValidMutationSignature(used[i], self.MaxMutationSignatureBytes) then return end
		size = size + #used[i] + 1
		if size > self.MaxMutationStateBytes then return end
	end
	return #used, size
end

function GM:WriteMutationState(used, count)
	count = count or self:GetMutationStateSize(used)
	if count == nil then return false end
	net.WriteUInt(count, 11)
	for i = 1, count do net.WriteString(used[i]) end
	return true
end

function GM:ReadMutationState(length)
	if type(length) ~= "number" or length < 11 then return end
	local count = net.ReadUInt(11)
	if count > self.MaxMutationStateEntries or 11 + count * 8 > length then return end
	local used, size = {}, 2
	for i = 1, count do
		local signature = net.ReadString()
		if not ValidMutationSignature(signature, self.MaxMutationSignatureBytes) then return end
		size = size + #signature + 1
		if size > self.MaxMutationStateBytes or 11 + (size - 2) * 8 > length then return end
		used[i] = signature
	end
	return used
end

function GM:MutationRequirementMet(mutation, owned, selected)
	local required = mutation.Requires
	if required == nil then return true end
	for _ = 1, self.MaxMutationPurchaseItems do
		if type(required) ~= "string" then return false end
		if owned[required] == true then return true end
		if not selected or selected[required] ~= true then return false end
		local prerequisite = self.MutationsBySignature[required]
		if not prerequisite or not prerequisite.MutationShop then return false end
		required = prerequisite.Requires
		if required == nil then return true end
	end
	return false
end

function GM:BuildMutationPurchase(pl, arguments)
	if type(arguments) ~= "table" or #arguments == 0 or #arguments > self.MaxMutationPurchaseItems then
		return nil, "cant_buy_mutations"
	end
	local count, stateSize = self:GetMutationStateSize(pl.UsedMutations)
	if count == nil then return nil, "cant_buy_mutations" end
	local used, seen, purchase = {}, {}, {}
	for _, signature in ipairs(pl.UsedMutations or {}) do used[signature] = true end
	local total = 0
	for _, id in ipairs(arguments) do
		local mutation = FindMutation(id)
		if not mutation or not ValidMutationSignature(mutation.Signature, self.MaxMutationSignatureBytes) or type(mutation.Callback) ~= "function"
		or type(mutation.Worth) ~= "number" or mutation.Worth ~= mutation.Worth
		or mutation.Worth < 0 or mutation.Worth == math.huge or mutation.Worth % 1 ~= 0
		or used[mutation.Signature] or seen[mutation.Signature] then
			return nil, "cant_buy_mutations"
		end
		seen[mutation.Signature] = true
		count, stateSize = count + 1, stateSize + #mutation.Signature + 1
		if count > self.MaxMutationStateEntries or stateSize > self.MaxMutationStateBytes then return nil, "cant_buy_mutations" end
		total = total + mutation.Worth
		purchase[#purchase + 1] = {
			Signature = mutation.Signature,
			Name = mutation.Name,
			NameTranslation = mutation.Name == mutation.TranslatedName and mutation.NameTranslation or nil,
			Worth = mutation.Worth,
			Callback = mutation.Callback,
			Requires = mutation.Requires
		}
	end
	local ordered, added = {}, {}
	for _ = 1, #purchase do
		local found
		for index, mutation in ipairs(purchase) do
			if not added[index] and self:MutationRequirementMet(mutation, used) then
				ordered[#ordered + 1], added[index], used[mutation.Signature] = mutation, true, true
				found = true
				break
			end
		end
		if not found then return nil, "mutation_requirement_missing" end
	end
	local tokens = pl:GetTokens()
	if type(tokens) ~= "number" or tokens ~= tokens or tokens == math.huge or tokens == -math.huge then return nil, "cant_buy_mutations" end
	if total > tokens then return nil, "you_dont_have_enough_btokens" end
	return ordered, total
end
