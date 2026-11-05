GM.MaxStartingPurchaseItems = 128
util.AddNetworkString("zs_worthdefault")
util.AddNetworkString("zs_worthcheckout")
util.AddNetworkString("zs_worthreceipt")
local state = GM.ZSWorthGrantState or {players = setmetatable({}, {__mode = "k"}), serial = 0}
GM.ZSWorthGrantState = state
state.scopes = state.scopes or setmetatable({}, {__mode = "k"})

local function Scope(gm, pl)
	local record = state.scopes[pl]
	if not record or record.claims ~= gm.CheckedOut or record.life ~= (pl.ZSWorthLife or 0) or record.spawned ~= pl.SpawnedTime then
		state.serial = state.serial % 4294967295 + 1
		record = {claims = gm.CheckedOut, life = pl.ZSWorthLife or 0, spawned = pl.SpawnedTime, token = state.serial}
		state.scopes[pl] = record
	end
	return record.token
end

local function Actor(gm, pl)
	return IsValid(pl) and pl:IsPlayer() and pl:IsConnected() and not pl:IsMarkedForDeletion() and pl:Alive() and pl:Team() == TEAM_HUMAN and not gm.RoundEnded
end

local function Current(gm, pl, transaction)
	return Actor(gm, pl) and state.players[pl] == transaction and transaction.claims == gm.CheckedOut
		and transaction.life == (pl.ZSWorthLife or 0) and transaction.spawned == pl.SpawnedTime
end

local function Pending(gm, pl)
	local transaction = state.players[pl]
	return transaction and Current(gm, pl, transaction) and not transaction.complete and not transaction.terminal and transaction
end

function GM:BuildWorthPurchase(arguments, preset)
	if type(arguments) ~= "table" or #arguments == 0 or #arguments > self.MaxStartingPurchaseItems then return nil end
	for key in pairs(arguments) do if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #arguments then return nil end end
	local purchase, seen, total = {}, {}, 0
	for index = 1, #arguments do
		local id = arguments[index]
		local item = FindStartingItem(id)
		if not item or type(item.Signature) ~= "string" or seen[item.Signature] or type(item.Worth) ~= "number"
		or item.Worth ~= item.Worth or math.abs(item.Worth) == math.huge
		or item.Worth % 1 ~= 0 or item.Callback ~= nil and type(item.Callback) ~= "function"
		or not (type(item.Callback) == "function" or type(item.SWEP) == "string" and item.SWEP ~= "") then return nil end
		local reason, detail = self:GetWorthItemUnavailableReason(item)
		if reason then return nil, reason, detail end
		seen[item.Signature] = true
		total = total + item.Worth
		purchase[#purchase + 1] = item
	end
	if total ~= total or math.abs(total) == math.huge or not preset and total > self.StartingWorth then return nil end
	return purchase, total
end

local function AddStartingReserve(reserves, weapon, definition, getter)
	if type(definition) ~= "table" then return end
	local default, clip = definition.DefaultClip, definition.ClipSize
	if type(default) ~= "number" or type(clip) ~= "number" or default ~= default or clip ~= clip
	or default <= 0 or default == math.huge or math.abs(clip) == math.huge then return end
	local amount = math.max(0, default - math.max(0, clip))
	if amount <= 0 then return end
	local ammo = weapon[getter](weapon)
	if not ammo then return end
	local reserve = reserves[ammo]
	if reserve then
		reserve.total = reserve.total + amount
		reserve.maximum = math.max(reserve.maximum, amount)
	else
		reserves[ammo] = {total = amount, maximum = amount}
	end
end

function GM:RemoveDuplicateAmmo(pl, credited)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	local reserves = credited or {}
	if not credited then for _, weapon in ipairs(pl:GetWeapons()) do
		if IsValid(weapon) then
			AddStartingReserve(reserves, weapon, weapon.Primary, "ValidPrimaryAmmo")
			AddStartingReserve(reserves, weapon, weapon.Secondary, "ValidSecondaryAmmo")
		end
	end end
	for ammo, reserve in pairs(reserves) do
		local amount = reserve.total - reserve.maximum
		if amount > 0 and amount < math.huge then pl:RemoveAmmo(amount, ammo) end
	end
end

local function Owned(pl, class)
	local weapon = pl:GetWeapon(class)
	return IsValid(weapon) and weapon:IsWeapon() and weapon:GetClass() == class and weapon:GetOwner() == pl and not weapon:IsMarkedForDeletion() and weapon
end

local function ListedWeapon(class)
	local registry = list and list.GetForEdit and list.GetForEdit("Weapon", true)
	local definition = registry and registry[class]
	return type(definition) == "table" and definition.ClassName == class
end

local traitSources = setmetatable({}, {__mode = "k"})
local function FirstParty(helper, filename)
	if type(helper) ~= "function" then return false end
	local record = traitSources[helper]
	if record == nil then
		local info = debug.getinfo(helper, "S")
		record = info and type(info.source) == "string" and info.source:gsub("\\", "/") or false
		traitSources[helper] = record
	end
	return record and record:sub(-#filename) == filename
end

local function TraitRetryable(gm, flag)
	if gm.GrantWorthTrait ~= gm.ZSWorthTraitAdapter or gm.SetPlayerTrait ~= gm.ZSWorthTraitSetter then return false end
	if flag == "tonguelover" then return FirstParty(gm.GiveTraitBarnacleWeapon, "/gamemode/server/sv_traitbarnacle.lua") end
	if flag == "alientrainer" then return FirstParty(gm.GiveTraitSnarkWeapon, "/gamemode/server/sv_traitsnarks.lua") end
	return true
end

local function ReserveSnapshot(pl, stored)
	local result = {}
	for _, field in ipairs({"Primary", "Secondary"}) do
		local definition = stored[field]
		if type(definition) == "table" and type(definition.Ammo) == "string" then
			local ammo = string.lower(definition.Ammo)
			local default, clip = definition.DefaultClip, definition.ClipSize
			if type(default) == "number" and type(clip) == "number" and default == default and clip == clip and math.abs(default) < math.huge and math.abs(clip) < math.huge then
				local amount = math.max(0, default - math.max(0, clip))
				if amount > 0 then result[ammo] = {before = pl:GetAmmoCount(ammo), amount = amount} end
			end
		end
	end
	return result
end

local function GrantWeapon(pl, item, transaction)
	if item.weaponDone then return true end
	local class = item.weapon
	if not item.legacyRepeat and Owned(pl, class) then item.weaponDone = true return true end
	if IsValid(item.doomed) then
		local weapon = item.doomed
		return false, weapon:IsWeapon() and weapon:GetClass() == class and weapon:IsMarkedForDeletion() and not IsValid(weapon:GetOwner())
	end
	item.doomed = nil
	local stored = weapons.GetStored(class)
	if not stored and not item.legacyRepeat and not ListedWeapon(class) then return false, true end
	local reserves = stored and ReserveSnapshot(pl, stored) or {}
	local weapon = pl:Give(class)
	if not Current(GAMEMODE, pl, transaction) then return false, false end
	local owned = Owned(pl, class)
	if not owned then
		for ammo, reserve in pairs(reserves) do if pl:GetAmmoCount(ammo) ~= reserve.before then return false, false end end
		if IsValid(weapon) then
			if not weapon:IsWeapon() or weapon:GetClass() ~= class or not weapon:IsMarkedForDeletion() or IsValid(weapon:GetOwner()) then return false, false end
			item.doomed = weapon
		end
		return false, true
	end
	if IsValid(weapon) and weapon ~= owned then return false, false end
	if item.legacyRepeat then
		item.units = (item.units or 0) + 1
		item.weaponDone = item.units >= item.quantity
		return true
	end
	item.weaponDone = true
	if item.empty then
		if weapon == owned then owned:EmptyAll() end
	else
		for ammo, reserve in pairs(reserves) do
			local amount = math.min(reserve.amount, math.max(0, pl:GetAmmoCount(ammo) - reserve.before))
			local credit = transaction.reserves[ammo]
			if credit then credit.total = credit.total + amount; credit.maximum = math.max(credit.maximum, amount)
			else transaction.reserves[ammo] = {total = amount, maximum = amount} end
		end
	end
	return true
end

local function Snapshot(item)
	if #item.Signature == 0 or #item.Signature > 64 or item.Signature:find("\0", 1, true) then return end
	local record = {signature = item.Signature, name = tostring(item.Name or item.Signature):sub(1, 160), callback = item.Callback, worth = item.Worth, trait = item.Callback == item.WorthGrantCallback and item.WorthTrait or nil,
		returnFlag = item.Callback == item.WorthGrantCallback and item.WorthReturn or nil,
		policy = {NoClassicMode = item.NoClassicMode, NoZombieEscape = item.NoZombieEscape, RequiresSigils = item.RequiresSigils, NoodleArm = item.NoodleArm, SWEP = item.SWEP, Name = item.Name}}
	local bundle = item.Callback == item.WorthGrantCallback and item.WorthGrant or nil
	local ammoOnly = item.Callback == item.WorthGrantCallback and item.WorthAmmo or nil
	if bundle then
		if type(bundle) ~= "table" or type(bundle.Weapon) ~= "string" or type(bundle.Ammo) ~= "table" then return end
		record.weapon, record.empty, record.ammo = bundle.Weapon, bundle.Empty == true, {}
		for index, ammo in ipairs(bundle.Ammo) do
			if type(ammo.Type) ~= "string" or #ammo.Type > 64 or type(ammo.Amount) ~= "number" or ammo.Amount % 1 ~= 0 or ammo.Amount < 0 or ammo.Amount > 100000 then return end
			record.ammo[index] = {type = ammo.Type, amount = ammo.Amount, given = 0}
		end
	elseif ammoOnly then
		if type(ammoOnly.Type) ~= "string" or #ammoOnly.Type > 64 then return end
		local amount = ammoOnly.Amount
		if amount == nil then amount = (GAMEMODE.AmmoCache[ammoOnly.Type] or ammoOnly.Default) * ammoOnly.Multiplier end
		if type(amount) ~= "number" or amount % 1 ~= 0 or amount < 0 or amount > 100000 then return end
		record.ammo = {{type = ammoOnly.Type, amount = amount, given = 0}}
	elseif not record.trait and not record.returnFlag and not record.callback then record.weapon = item.SWEP end
	if record.weapon and (type(record.weapon) ~= "string" or not weapons.GetStored(record.weapon) and not ListedWeapon(record.weapon)) then return end
	if record.trait and (type(record.trait) ~= "string" or not GAMEMODE.TraitLookup[record.trait] or type(GAMEMODE.GrantWorthTrait) ~= "function") then return end
	if record.returnFlag and (type(record.returnFlag) ~= "string" or not GAMEMODE.ReturnLookup[record.returnFlag] or type(GAMEMODE.SetPlayerReturn) ~= "function") then return end
	return record
end

local function GrantAmmo(gm, pl, item, transaction)
	for _, ammo in ipairs(item.ammo) do
		if ammo.given < ammo.amount then
			local remaining = ammo.amount - ammo.given
			local given = pl:GiveAmmo(remaining, ammo.type, true)
			if type(given) ~= "number" or given % 1 ~= 0 or given < 0 or given > remaining then return false, false end
			ammo.given = ammo.given + given
			if not Current(gm, pl, transaction) then return false, false end
			if ammo.given < ammo.amount then return false, true end
		end
	end
	return true
end

local function SameCart(arguments, transaction)
	if type(arguments) ~= "table" or #arguments ~= #transaction.items then return false end
	for key in pairs(arguments) do if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #arguments then return false end end
	for index = 1, #arguments do
		local id = arguments[index]
		local item = FindStartingItem(id)
		if transaction.configured then
			if id ~= transaction.items[index].signature then return false end
		elseif not item or item.Signature ~= transaction.items[index].signature then return false end
	end
	return true
end

local function Attempt(gm, pl, arguments, token, random, configured)
	local transaction = state.players[pl]
	if transaction and not Current(gm, pl, transaction) then state.players[pl] = nil transaction = nil end
	if token and (not transaction or transaction.token ~= token) then return false, "worth_grant_stale" end
	local claims, life, spawned = gm.CheckedOut, pl.ZSWorthLife or 0, pl.SpawnedTime
	if not gamemode.Call("PlayerCanCheckout", pl, random or transaction and transaction.random) or not Actor(gm, pl) then return false, "cant_use_worth_anymore" end
	if claims ~= gm.CheckedOut or life ~= (pl.ZSWorthLife or 0) or spawned ~= pl.SpawnedTime then return false, "worth_grant_stale" end
	if transaction then
		if transaction.terminal then return false, "worth_grant_failed", transaction.detail end
		if transaction.complete then return false, "cant_use_worth_anymore" end
		if not SameCart(arguments, transaction) then return false, "worth_grant_cart_locked" end
	else
		local records = {}
		if configured then
			for index, class in ipairs(arguments) do
				local amount = tonumber(gm.StartingLoadout[class])
				if type(class) ~= "string" or #class == 0 or #class > 64 or class:find("\0", 1, true)
					or not amount or amount ~= amount or amount > 4096 or amount < 1 then return false, "worth_grant_unavailable", tostring(class):sub(1, 160) end
				records[index] = {signature = class, name = class, weapon = class, legacyRepeat = true, quantity = math.floor(amount)}
			end
			if #records == 0 or #records > gm.MaxStartingPurchaseItems then return false, "cant_use_worth_anymore" end
		else
			local purchase, reason, detail = gm:BuildWorthPurchase(arguments, random)
			if not purchase then return false, reason or "cant_use_worth_anymore", detail end
			for index, item in ipairs(purchase) do
				records[index] = Snapshot(item)
				if not records[index] then return false, "worth_grant_unavailable", tostring(item.Name or item.Signature):sub(1, 160) end
			end
		end
		if not Actor(gm, pl) or claims ~= gm.CheckedOut or life ~= (pl.ZSWorthLife or 0) or spawned ~= pl.SpawnedTime then return false, "worth_grant_stale" end
		state.serial = state.serial % 4294967295 + 1
		local order = {}
		for index, item in ipairs(records) do if (item.worth or 0) < 0 then order[#order + 1] = index end end
		for index, item in ipairs(records) do if (item.worth or 0) >= 0 then order[#order + 1] = index end end
		transaction = {items = records, order = order, cursor = 1, claims = gm.CheckedOut, life = pl.ZSWorthLife or 0, spawned = pl.SpawnedTime, token = state.serial, reserves = {}, random = random, configured = configured}
		state.players[pl] = transaction
		gm.CheckedOut[pl:UniqueID()] = true
	end
	while transaction.cursor <= #transaction.items do
		if not Current(gm, pl, transaction) then transaction.terminal = true return false, "worth_grant_stale" end
		local item = transaction.items[transaction.order[transaction.cursor]]
		transaction.detail = item.name
		if item.policy then
			local reason, detail = gm:GetWorthItemUnavailableReason(item.policy)
			if reason then return false, reason, detail end
			local live = FindStartingItem(item.signature)
			if not live then return false, "worth_grant_retry", item.name end
			reason, detail = gm:GetWorthItemUnavailableReason(live)
			if reason then return false, reason, detail end
			if not Current(gm, pl, transaction) then transaction.terminal = true return false, "worth_grant_stale" end
		end
		local granted, retryable
		if item.weapon then
			granted, retryable = GrantWeapon(pl, item, transaction)
			if granted and Current(gm, pl, transaction) and item.ammo then
				granted, retryable = GrantAmmo(gm, pl, item, transaction)
			end
		elseif item.ammo then granted, retryable = GrantAmmo(gm, pl, item, transaction)
		elseif item.returnFlag then
			retryable = FirstParty(gm.SetPlayerReturn, "/gamemode/server/sv_returns.lua")
			granted = gm:SetPlayerReturn(pl, item.returnFlag) == true
		elseif item.trait then
			retryable = TraitRetryable(gm, item.trait)
			local recoverable
			granted, recoverable = gm:GrantWorthTrait(pl, item.trait, item)
			if recoverable == false then retryable = false end
		else granted = item.callback(pl) ~= false end
		if not Current(gm, pl, transaction) then transaction.terminal = true return false, "worth_grant_stale" end
		if not granted then
			transaction.terminal = not retryable
			return false, retryable and "worth_grant_retry" or "worth_grant_failed", item.name
		end
		if not item.legacyRepeat or item.weaponDone then transaction.cursor = transaction.cursor + 1 end
	end
	if not transaction.finalized then
		transaction.finalized = true
		if not transaction.configured then gamemode.Call("RemoveDuplicateAmmo", pl, transaction.reserves) end
	end
	if not Current(gm, pl, transaction) then transaction.terminal = true return false, "worth_grant_stale" end
	transaction.complete = true
	return true
end

function GM:CheckoutWorth(pl, arguments, token, random, configured)
	if not Actor(self, pl) or pl.ZSWorthCheckoutBusy then return false, "cant_use_worth_anymore" end
	pl.ZSWorthCheckoutBusy = true
	local ok, granted, reason, detail = pcall(Attempt, self, pl, arguments, token, random, configured)
	if IsValid(pl) then pl.ZSWorthCheckoutBusy = nil end
	if not ok then
		local transaction = state.players[pl]
		if transaction then transaction.terminal = true end
		ErrorNoHalt("[ZS] Worth grant failed: " .. tostring(granted) .. "\n")
		return false, "worth_grant_failed", transaction and transaction.detail or ""
	end
	return granted, reason, detail
end

local function RandomAuthority(pl)
	if pl.ZSWorthCheckoutBusy then return false end
	pl.ZSWorthCheckoutBusy = true
	local ok, allowed = pcall(gamemode.Call, "PlayerCanCheckout", pl)
	if IsValid(pl) then pl.ZSWorthCheckoutBusy = nil end
	if not ok then ErrorNoHalt("[ZS] Worth permission failed: " .. tostring(allowed) .. "\n") return false end
	return allowed
end

local function Receipt(pl, request, ok, reason, detail)
	if not IsValid(pl) or pl:IsBot() then return end
	local transaction = state.players[pl]
	if transaction and not Current(GAMEMODE, pl, transaction) then transaction = nil end
	local status = ok and 1 or transaction and (transaction.complete and 1 or transaction.terminal and 3 or 2) or reason and 4 or 0
	net.Start("zs_worthreceipt")
	net.WriteUInt(request or 0, 16); net.WriteUInt(transaction and transaction.token or 0, 32); net.WriteUInt(Scope(GAMEMODE, pl), 32); net.WriteUInt(status, 3)
	net.WriteString((reason or (status == 2 and "worth_grant_retry" or status == 3 and "worth_grant_failed") or ""):sub(1, 64))
	net.WriteString(tostring(detail or transaction and transaction.detail or ""):sub(1, 160))
	local count = status == 2 and #transaction.items or 0
	net.WriteUInt(count, 8)
	for index = 1, count do net.WriteString(transaction.items[index].signature) end
	net.Send(pl)
end

net.Receive("zs_worthcheckout", function(length, pl)
	if length < 82 or length > 66650 or not Actor(GAMEMODE, pl) or pl:IsBot() then return end
	local now = CurTime()
	local operation, request, token, scope = net.ReadUInt(2), net.ReadUInt(16), net.ReadUInt(32), net.ReadUInt(32)
	local rate = operation == 3 and "ZSNextWorthQuery" or "ZSNextWorthRequest"
	if now < (pl[rate] or 0) then return end
	pl[rate] = now + 0.15
	if operation ~= 3 and scope ~= Scope(GAMEMODE, pl) then Receipt(pl, request, false, "worth_grant_stale") return end
	if operation == 0 then
		if length < 98 then return end
		local count, arguments, expected = net.ReadUInt(8), {}, 90
		if count == 0 or count > GAMEMODE.MaxStartingPurchaseItems then return end
		for index = 1, count do
			local id = net.ReadString()
			if #id == 0 or #id > 64 then return end
			arguments[index], expected = id, expected + (#id + 1) * 8
		end
		if length ~= expected then return end
		local ok, reason, detail = GAMEMODE:CheckoutWorth(pl, arguments, token ~= 0 and token or nil)
		Receipt(pl, request, ok, reason, detail)
	elseif length == 82 then
		if operation == 3 then Receipt(pl, request) return end
		local transaction = Pending(GAMEMODE, pl)
		if operation == 1 then
			if not transaction or token ~= transaction.token then Receipt(pl, request, false, "worth_grant_stale") return end
			local arguments = {} for index, item in ipairs(transaction.items) do arguments[index] = item.signature end
			local ok, reason, detail = GAMEMODE:CheckoutWorth(pl, arguments, token)
			Receipt(pl, request, ok, reason, detail)
		elseif operation == 2 then
			if not RandomAuthority(pl) then Receipt(pl, request, false, "cant_use_worth_anymore") return end
			if not Actor(GAMEMODE, pl) or scope ~= Scope(GAMEMODE, pl) then Receipt(pl, request, false, "worth_grant_stale") return end
			local ok, reason, detail = GAMEMODE:GiveRandomEquipment(pl)
			Receipt(pl, request, ok, reason, detail)
		end
	end
end)

hook.Add("PlayerSpawn", "ZSWorthGrantLife", function(pl) pl.ZSWorthLife = (pl.ZSWorthLife or 0) % 4294967295 + 1; state.players[pl], state.scopes[pl] = nil, nil end)
hook.Add("PlayerDisconnected", "ZSWorthGrantLife", function(pl) state.players[pl], state.scopes[pl] = nil, nil end)

concommand.Add("worthcheckout", function(sender, _, arguments)
	local ok, reason, detail = GAMEMODE:CheckoutWorth(sender, arguments)
	Receipt(sender, 0, ok, reason, detail)
	if not ok and reason and IsValid(sender) and not sender:IsBot() then
		local message = detail and translate.ClientFormat(sender, reason, detail) or translate.ClientGet(sender, reason)
		sender:CenterNotify(COLOR_RED, message)
	end
end)

local function TimedOut(pl, claims, life, spawned)
    if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() then return end
    if claims and (claims ~= GAMEMODE.CheckedOut or life ~= (pl.ZSWorthLife or 0) or spawned ~= pl.SpawnedTime) then return end
    if GAMEMODE.RoundEnded then return end
    if pl:IsValid() and pl:Team() == TEAM_HUMAN and pl:Alive() and not GAMEMODE.CheckedOut[pl:UniqueID()] then
        gamemode.Call("GiveRandomEquipment", pl)
    end
end

function GM:GiveDefaultOrRandomEquipment(pl)
    if Pending(self, pl) then
        local transaction, arguments = state.players[pl], {}
        for index, item in ipairs(transaction.items) do arguments[index] = item.signature end
        local ok, reason, detail = self:CheckoutWorth(pl, arguments, transaction.token)
        Receipt(pl, 0, ok, reason, detail)
        return ok, reason, detail
    end
    if not self.CheckedOut[pl:UniqueID()] and not self.ZombieEscape then
        if self.StartingLoadout then
            self:GiveStartingLoadout(pl)
        elseif pl:IsBot() then
            if self.StartingWorth > 0 then TimedOut(pl) end
        else
            net.Start("zs_worthdefault")
            net.Send(pl)
            if self.StartingWorth > 0 then
                local claims, life, spawned = self.CheckedOut, pl.ZSWorthLife or 0, pl.SpawnedTime
                timer.Simple(4, function() TimedOut(pl, claims, life, spawned) end)
            end
        end
    end
end

function GM:GiveStartingLoadout(pl)
    if not Actor(self, pl) or type(self.StartingLoadout) ~= "table" then return false, "cant_use_worth_anymore" end
    local transaction, arguments = Pending(self, pl), {}
    if transaction then
        for index, item in ipairs(transaction.items) do arguments[index] = item.signature end
        return self:CheckoutWorth(pl, arguments, transaction.token)
    end
    for class, amount in pairs(self.StartingLoadout) do if tonumber(amount) and tonumber(amount) >= 1 then arguments[#arguments + 1] = class end end
    table.sort(arguments, function(left, right) return tostring(left) < tostring(right) end)
    return self:CheckoutWorth(pl, arguments, nil, "configured", true)
end

function GM:GiveRandomEquipment(pl)
    if not Actor(self, pl) or pl.ZSWorthCheckoutBusy then return false, "cant_use_worth_anymore" end
    local transaction = Pending(self, pl)
    if transaction then
        local arguments = {} for index, item in ipairs(transaction.items) do arguments[index] = item.signature end
        return self:CheckoutWorth(pl, arguments, transaction.token)
    end
    if self.CheckedOut[pl:UniqueID()] or self.ZombieEscape then return false, "cant_use_worth_anymore" end
    if self.StartingLoadout then
        return self:GiveStartingLoadout(pl)
    elseif GAMEMODE.OverrideStartingWorth then
        return self:CheckoutWorth(pl, {"csknf"}, nil, true)
    elseif #self.StartLoadouts >= 1 then
        local arguments = {}
        for _, id in ipairs(self.StartLoadouts[math.random(#self.StartLoadouts)]) do
            local tab = FindStartingItem(id)
            if tab and not self:GetWorthItemUnavailableReason(tab) then arguments[#arguments + 1] = tab.Signature end
        end
        return self:CheckoutWorth(pl, arguments, nil, true)
    end
    return false, "cant_use_worth_anymore"
end

function GM:PlayerCanCheckout(pl, preset)
    return Actor(self, pl) and (preset == "configured" or not self.CheckedOut[pl:UniqueID()] or Pending(self, pl)) and (preset == "configured" or not self.StartingLoadout) and not self.ZombieEscape and (preset == "configured" or self.StartingWorth > 0) and (preset or self:GetWave() < 2)
end

concommand.Add("worthrandom", function(sender, command, arguments)
    if not Actor(GAMEMODE, sender) then return end
    local claims, life, spawned = GAMEMODE.CheckedOut, sender.ZSWorthLife or 0, sender.SpawnedTime
    if RandomAuthority(sender) and Actor(GAMEMODE, sender) and claims == GAMEMODE.CheckedOut and life == (sender.ZSWorthLife or 0) and spawned == sender.SpawnedTime then
        local ok, reason, detail = gamemode.Call("GiveRandomEquipment", sender)
        Receipt(sender, 0, ok, reason, detail)
    end
end)

