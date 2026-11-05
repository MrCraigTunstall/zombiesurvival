util.AddNetworkString("zs_humanflashlight")
GM.ZSHumanFlashlights = GM.ZSHumanFlashlights or setmetatable({}, {__mode = "k"})
local active = GM.ZSHumanFlashlights
local requests = setmetatable({}, {__mode = "k"})
local nextCheck = 0

function GM:SetHumanFlashlight(pl, enabled)
	if not IsValid(pl) or not pl:IsPlayer() then return false end
	enabled = enabled == true and pl:Alive() and pl:Team() == TEAM_HUMAN
	active[pl] = enabled and true or nil
	if pl:GetNW2Bool("zs_humanflashlight", false) ~= enabled then pl:SetNW2Bool("zs_humanflashlight", enabled) end
	return enabled
end

net.Receive("zs_humanflashlight", function(length, pl)
	if length ~= 1 or not IsValid(pl) or not pl:IsPlayer() then return end
	local now = CurTime()
	if now < (requests[pl] or 0) then return end
	requests[pl] = now + 0.1
	GAMEMODE:SetHumanFlashlight(pl, net.ReadBool())
end)

hook.Add("PlayerSwitchFlashlight", "ZSHumanFlashlight", function(pl, enabled)
	GAMEMODE:SetHumanFlashlight(pl, enabled)
	return false
end)

hook.Add("Think", "ZSHumanFlashlight", function()
	local now = CurTime()
	if now < nextCheck then return end
	nextCheck = now + 0.1
	for pl in pairs(active) do
		if not IsValid(pl) then active[pl] = nil
		elseif not pl:Alive() or pl:Team() ~= TEAM_HUMAN then GAMEMODE:SetHumanFlashlight(pl, false) end
	end
end)

local function clear(pl)
	active[pl], requests[pl] = nil, nil
	if IsValid(pl) then GAMEMODE:SetHumanFlashlight(pl, false) end
end
hook.Add("PlayerDeath", "ZSHumanFlashlight", clear)
hook.Add("PlayerDisconnected", "ZSHumanFlashlight", clear)
hook.Add("OnPlayerChangedTeam", "ZSHumanFlashlight", clear)
