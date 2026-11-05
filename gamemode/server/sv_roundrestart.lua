local state = GM.ZSRoundRestartSpawns or {generation = 0}
GM.ZSRoundRestartSpawns = state

function GM:CancelRoundRestartSpawns()
	state.generation = state.generation + 1
	state.players, state.index = nil, nil
	hook.Remove("Tick", "ZSRoundRestartSpawns")
end

function GM:SpawnRoundRestartPlayers()
	self:CancelRoundRestartSpawns()
	local players = player.GetAll()
	if #players == 0 then return false end
	state.players, state.index = players, 1
	local generation = state.generation
	hook.Add("Tick", "ZSRoundRestartSpawns", function()
		local deadline = SysTime() + 0.004
		for count = 1, 16 do
			if state.generation ~= generation then return end
			local pl = players[state.index]
			if not pl then self:CancelRoundRestartSpawns(); return end
			state.index = state.index + 1
			if IsValid(pl) and pl:Team() ~= TEAM_SPECTATOR then
				pl:UnSpectateAndSpawn()
				if state.generation ~= generation then return end
				if IsValid(pl) then
					pl:GodDisable()
					gamemode.Call("PlayerInitialSpawnRound", pl)
					if state.generation ~= generation then return end
					if IsValid(pl) then gamemode.Call("PlayerReadyRound", pl) end
				end
			end
			if state.generation ~= generation then return end
			if state.index > #players then self:CancelRoundRestartSpawns(); return end
			if SysTime() >= deadline then return end
		end
		if state.generation ~= generation then return end
		if state.index > #players then self:CancelRoundRestartSpawns() end
	end)
	return true
end
