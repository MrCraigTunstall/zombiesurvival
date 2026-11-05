GM.ZSTraitAuraState = GM.ZSTraitAuraState or {providers = setmetatable({}, {__mode = "k"}), affected = setmetatable({}, {__mode = "k"})}
local state = GM.ZSTraitAuraState
local positions = {}
local grid, pool = {}, {}
local used = 0
local radius = 256
local radiusSqr = radius * radius

local function Table()
	used = used + 1
	local value = pool[used]
	if not value then value = {}; pool[used] = value end
	return value
end

local function ResetGrid()
	for _, value in ipairs(pool) do table.Empty(value) end
	table.Empty(grid); table.Empty(positions); used = 0
end

local function SetCheered(pl, active)
	if not IsValid(pl) then state.affected[pl] = nil; return end
	if (pl.ZSTraitCheered == true) == active then return end
	pl.ZSTraitCheered = active and true or nil
	state.affected[pl] = active and true or nil
	if pl:GetNW2Bool("zs_trait_cheer", false) ~= active then pl:SetNW2Bool("zs_trait_cheer", active) end
	if pl:Alive() then pl:ResetSpeed() end
end

function GM:RegisterTraitAura(pl)
	state.providers[pl] = true
	state.nextUpdate = nil
end

function GM:UnregisterTraitAura(pl)
	state.providers[pl] = nil
	state.nextUpdate = nil
	if next(state.providers) == nil then ResetGrid() end
end

function GM:ClearTraitAuraRecipient(pl)
	SetCheered(pl, false)
end

function GM:UpdateTraitAuras(now)
	if state.nextUpdate and now < state.nextUpdate then return end
	state.nextUpdate = now + 0.25
	ResetGrid()
	local count = 0
	for pl in pairs(state.providers) do
		if not IsValid(pl) or not pl.ZSTraits or not pl.ZSTraits.cheerleader then
			state.providers[pl] = nil
		elseif not self.RoundEnded and pl:Team() == TEAM_HUMAN and pl:Alive() then
			local pos = pl:GetPos()
			positions[pl] = pos
			local x,y,z = math.floor(pos.x / radius), math.floor(pos.y / radius), math.floor(pos.z / radius)
			local ys = grid[x]
			if not ys then ys = Table(); grid[x] = ys end
			local zs = ys[y]
			if not zs then zs = Table(); ys[y] = zs end
			local bucket = zs[z]
			if not bucket then bucket = Table(); zs[z] = bucket end
			bucket[#bucket + 1] = pl
			count = count + 1
		end
	end
	if count == 0 then
		for pl in pairs(state.affected) do SetCheered(pl, false) end
		return
	end
	for _, pl in player.Iterator() do
		local active = false
		if pl:Team() == TEAM_HUMAN and pl:Alive() then
			local pos = positions[pl] or pl:GetPos()
			for x = math.floor((pos.x - radius) / radius), math.floor((pos.x + radius) / radius) do
				local ys = grid[x]
				if ys then
					for y = math.floor((pos.y - radius) / radius), math.floor((pos.y + radius) / radius) do
						local zs = ys[y]
						if zs then
							for z = math.floor((pos.z - radius) / radius), math.floor((pos.z + radius) / radius) do
								local bucket = zs[z]
								if bucket then
									for _, provider in ipairs(bucket) do
										if provider ~= pl and pos:DistToSqr(positions[provider]) <= radiusSqr then active = true; break end
									end
								end
								if active then break end
							end
						end
						if active then break end
					end
				end
				if active then break end
			end
		end
		SetCheered(pl, active)
	end
end

hook.Add("Think", "ZSTraitAuras", function()
	if next(state.providers) or next(state.affected) then GAMEMODE:UpdateTraitAuras(CurTime()) end
end)
local function Changed(pl)
	GAMEMODE:ClearTraitAuraRecipient(pl)
	state.nextUpdate = nil
end
hook.Add("PlayerDeath", "ZSTraitAuras", Changed)
hook.Add("OnPlayerChangedTeam", "ZSTraitAuras", Changed)
hook.Add("PlayerDisconnected", "ZSTraitAuras", function(pl)
	GAMEMODE:UnregisterTraitAura(pl); GAMEMODE:ClearTraitAuraRecipient(pl)
end)
hook.Add("PostEndRound", "ZSTraitAuras", function()
	state.nextUpdate = nil; GAMEMODE:UpdateTraitAuras(CurTime())
end)
