util.AddNetworkString("zs_mutations_result")
util.AddNetworkString("zs_mutations_table")
util.AddNetworkString("zs_mutations_open")
local requests = setmetatable({}, {__mode = "k"})
local function SendMutationReceipt(pl, mutation)
	local name = mutation.NameTranslation and translate.ClientGet(pl, mutation.NameTranslation) or mutation.Name
	pl:PrintTranslatedMessage(HUD_PRINTTALK, "purchased_x_for_y_btokens", name, mutation.Worth)
end

function GM:SendMutationState(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return false end
	local count = self:GetMutationStateSize(pl.UsedMutations)
	if count == nil then return false end
	net.Start("zs_mutations_table")
	self:WriteMutationState(pl.UsedMutations, count)
	net.Send(pl)
	return true
end

local function PrepareMutationPurchase(gm, pl, arguments, now)
	if not gamemode.Call("ZombieCanPurchase", pl) then return nil, "cant_buy_mutations" end
	pl.NextMutationPurchase = now + 0.25
	return gm:BuildMutationPurchase(pl, arguments)
end

function GM:PurchaseMutations(pl, arguments)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() then return false, "cant_buy_mutations", false end
	if pl.ZSMutationPurchaseBusy then return false, "cant_buy_mutations", false end
	local now = CurTime()
	if now < (pl.NextMutationPurchase or 0) then return false, "cant_buy_mutations", false end
	pl.ZSMutationPurchaseBusy = true
	local prepared, purchase, total = pcall(PrepareMutationPurchase, self, pl, arguments, now)
	if not prepared then
		pl.ZSMutationPurchaseBusy = nil
		ErrorNoHalt("[ZS] Mutation validation failed: " .. tostring(purchase) .. "\n")
		return false, "cant_buy_mutations", false
	end
	if not purchase then pl.ZSMutationPurchaseBusy = nil; return false, total, false end
	pl.UsedMutations = pl.UsedMutations or {}
	local notify = not pl:IsBot()
	for index, mutation in ipairs(purchase) do
		pl:TakeTokens(mutation.Worth)
		local ok, err = pcall(mutation.Callback, pl)
		if not ok then
			pl:TakeTokens(-mutation.Worth)
			pl.ZSMutationPurchaseBusy = nil
			ErrorNoHalt("[ZS] Mutation callback failed: " .. mutation.Signature .. ": " .. tostring(err) .. "\n")
			return false, "cant_buy_mutations", index > 1
		end
		pl.UsedMutations[#pl.UsedMutations + 1] = mutation.Signature
		if notify then
			local delivered, message = pcall(SendMutationReceipt, pl, mutation)
			if not delivered then ErrorNoHalt("[ZS] Mutation receipt failed: " .. mutation.Signature .. ": " .. tostring(message) .. "\n") end
		end
	end
	pl.ZSMutationPurchaseBusy = nil
	return true, nil, true
end

concommand.Add("zs_mutationshop_click", function(sender, _, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	local now = SysTime()
	if now < (requests[sender] or 0) then return end
	requests[sender] = now + 0.25
	local success, reason, changed = GAMEMODE:PurchaseMutations(sender, arguments)
	if sender:IsBot() then return end
	if changed ~= false then GAMEMODE:SendMutationState(sender) end
	net.Start("zs_mutations_result")
	net.WriteBool(success)
	net.WriteString(reason or "")
	net.Send(sender)
	if not success then sender:CenterNotify(COLOR_RED, translate.ClientGet(sender, reason)) end
end)

function GM:ResetMutationState(pl)
	self:ResetMutationEffects(pl)
	pl.UsedMutations = {}
	pl.NextMutationPurchase, pl.ZSNextMutationMenu = nil, nil
	requests[pl] = nil
	self:SendMutationState(pl)
end

function GM:ApplyMutationSpawnEffects(pl)
	if pl:Team() == TEAM_UNDEAD and pl.m_Zombie_Health then
		local health = pl:Health() + 50
		pl:SetMaxHealth(health)
		pl:SetHealth(health)
	end
end

function GM:OpenMutationShop(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() or pl:Team() ~= TEAM_UNDEAD then return false end
	local now = SysTime()
	if now < (pl.ZSNextMutationMenu or 0) then return false end
	local count = self:GetMutationStateSize(pl.UsedMutations)
	if count == nil then return false end
	pl.ZSNextMutationMenu = now + 0.25
	net.Start("zs_mutations_open")
	self:WriteMutationState(pl.UsedMutations, count)
	net.Send(pl)
	return true
end
