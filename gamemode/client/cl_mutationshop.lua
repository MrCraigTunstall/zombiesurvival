local function ReadState(length)
	local used = GAMEMODE:ReadMutationState(length)
	if not used then return end
	UsedMutations = used
	local pl = LocalPlayer()
	if IsValid(pl) then GAMEMODE:ApplyMutationOwnershipFlags(pl, used) end
	hook.Run("ZSMutationsUpdated")
	return used
end

net.Receive("zs_mutations_table", ReadState)
local pendingOpen = false
local openTimer = "ZSMutationOpenSnapshot"
local function OpenPendingShop()
	if not pendingOpen then return true end
	local pl = LocalPlayer()
	if not IsValid(pl) or pl:Team() ~= TEAM_UNDEAD then return false end
	pendingOpen = false
	GAMEMODE:ApplyMutationOwnershipFlags(pl, UsedMutations)
	MakepMutationShop(UsedMutations)
	return true
end

net.Receive("zs_mutations_open", function(length)
	local used = ReadState(length)
	if not used then return end
	pendingOpen = true
	timer.Remove(openTimer)
	if OpenPendingShop() then return end
	local attempts = 20
	local deadline = RealTime() + 2
	timer.Create(openTimer, 0.1, attempts, function()
		if RealTime() > deadline then pendingOpen = false timer.Remove(openTimer) return end
		attempts = attempts - 1
		if OpenPendingShop() then timer.Remove(openTimer)
		elseif attempts == 0 then pendingOpen = false end
	end)
end)

hook.Add("InitPostEntity", "ZSMutationOwnership", function()
	local pl = LocalPlayer()
	if IsValid(pl) then GAMEMODE:ApplyMutationOwnershipFlags(pl, UsedMutations) end
end)
