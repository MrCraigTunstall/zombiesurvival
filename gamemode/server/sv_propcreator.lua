GM.ZSPropCreatorUsage = GM.ZSPropCreatorUsage or {round = GM.CurrentRound or 1, players = {}}
local bounds = {}
util.AddNetworkString("zs_propcreator_open")

function GM:OpenPropCreator(pl)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded then return false end
	local weapon = pl:GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_propcreator" or weapon:GetOwner() ~= pl then return false end
	net.Start("zs_propcreator_open")
	net.Send(pl)
	return true
end

local function OwnerKey(pl)
	if pl:IsBot() then return pl end
	if game.SinglePlayer() then return "singleplayer" end
	local id = pl:SteamID64()
	return id and id ~= "0" and id ~= "" and id or pl
end

function GM:GetPropCreatorUses(pl)
	if not IsValid(pl) or not pl:IsPlayer() then return 0 end
	local usage = self.ZSPropCreatorUsage
	local round = self.CurrentRound or 1
	if usage.round ~= round then usage.round, usage.players = round, {} end
	local count = usage.players[OwnerKey(pl)] or 0
	if not pl:IsBot() and pl:GetNW2Int("zs_propcreator_used", 0) ~= count then pl:SetNW2Int("zs_propcreator_used", count) end
	return count
end

function GM:CreatePropCreatorProp(pl, weapon, index)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded
	or pl:GetBarricadeGhosting() or pl:IsHolding() or not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_propcreator"
	or weapon:GetOwner() ~= pl or pl:GetActiveWeapon() ~= weapon then return false, "propcreator_unavailable" end
	if pl.ZSPropCreatorBusy or (pl.ZSNextPropCreation or 0) > CurTime() then return false, "propcreator_wait" end
	pl.ZSNextPropCreation = CurTime() + 0.5
	local count = self:GetPropCreatorUses(pl)
	if count >= 2 then return false, "propcreator_limit" end
	if type(index) ~= "number" or index ~= math.floor(index) or not self.PropCreatorChoices[index] then return false, "propcreator_invalid" end
	pl.ZSPropCreatorBusy = true
	local prop
	local ok, success, reason = pcall(function()
		local choice = self.PropCreatorChoices[index]
		if not util.IsValidProp(choice.model) then return false, "propcreator_model_missing" end
		local start = pl:GetShootPos()
		local trace = util.TraceLine({start = start, endpos = start + pl:GetAimVector() * 160, filter = pl, mask = MASK_SOLID})
		if not trace.Hit or trace.StartSolid or trace.HitSky or trace.HitNormal.z < 0.65 then return false, "propcreator_floor" end
		prop = ents.Create("prop_physics")
		if not IsValid(prop) then return false, "propcreator_failed" end
		prop:SetModel(choice.model)
		local cached = bounds[choice.model]
		if not cached then
			local mins, maxs = prop:GetModelBounds()
			cached = {mins = mins, maxs = maxs, rotated = {}}
			bounds[choice.model] = cached
		end
		local yaw = (math.Round(pl:EyeAngles().y / 45) * 45) % 360
		local angle = Angle(0, yaw, 0)
		local box = cached.rotated[yaw]
		if not box then
			local mins, maxs = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)
			for x = 0, 1 do for y = 0, 1 do for z = 0, 1 do
				local corner = Vector(x == 0 and cached.mins.x or cached.maxs.x, y == 0 and cached.mins.y or cached.maxs.y, z == 0 and cached.mins.z or cached.maxs.z)
				corner:Rotate(angle)
				mins.x, mins.y, mins.z = math.min(mins.x, corner.x), math.min(mins.y, corner.y), math.min(mins.z, corner.z)
				maxs.x, maxs.y, maxs.z = math.max(maxs.x, corner.x), math.max(maxs.y, corner.y), math.max(maxs.z, corner.z)
			end end end
			box = {mins = mins, maxs = maxs}
			cached.rotated[yaw] = box
		end
		local mins, maxs = box.mins, box.maxs
		local pos = trace.HitPos + Vector(0, 0, 2 - mins.z)
		if not util.IsInWorld(pos + mins) or not util.IsInWorld(pos + maxs) then return false, "propcreator_blocked" end
		local space = util.TraceHull({start = pos, endpos = pos, mins = mins, maxs = maxs, filter = prop, mask = MASK_SOLID})
		if space.Hit or space.StartSolid or space.AllSolid then return false, "propcreator_blocked" end
		prop:SetCreator(pl)
		prop:SetPos(pos)
		prop:SetAngles(angle)
		prop:Spawn()
		if not IsValid(prop) then return false, "propcreator_failed" end
		local phys = prop:GetPhysicsObject()
		if not IsValid(phys) then return false, "propcreator_failed" end
		local health = math.min(2500, math.ceil((prop:OBBMins():Length() + prop:OBBMaxs():Length()) * 10))
		prop.PropHealth = health * (self.PropHealthMultipliers[choice.model] or 1)
		prop.TotalHealth = prop.PropHealth
		prop:SetPhysicsAttacker(pl)
		prop.ZSPropCreatorOwner = OwnerKey(pl)
		phys:Wake()
		self.ZSPropCreatorUsage.players[OwnerKey(pl)] = count + 1
		self:GetPropCreatorUses(pl)
		return true
	end)
	pl.ZSPropCreatorBusy = nil
	if not ok then ErrorNoHalt("ZS Prop Creator: " .. tostring(success) .. "\n"); reason, success = "propcreator_failed", false end
	if not success then if IsValid(prop) then prop:Remove() end return false, reason end
	return true, nil, prop
end

concommand.Add("zs_propcreator_select", function(pl, _, args)
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or (pl.ZSNextPropSelection or 0) > CurTime() then return end
	pl.ZSNextPropSelection = CurTime() + 0.2
	local index = tonumber(args[1])
	local weapon = pl:GetActiveWeapon()
	if not index or index ~= math.floor(index) or not GAMEMODE.PropCreatorChoices[index] or not IsValid(weapon) or weapon:GetClass() ~= "weapon_zs_propcreator" or weapon:GetOwner() ~= pl then return end
	weapon:SetDTInt(0, index)
end)

hook.Add("PlayerSpawn", "ZSPropCreatorQuota", function(pl) GAMEMODE:GetPropCreatorUses(pl) end)
hook.Add("PlayerDisconnected", "ZSPropCreatorQuota", function(pl) GAMEMODE.ZSPropCreatorUsage.players[pl] = nil end)
