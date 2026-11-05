function GM:QueueInflictionRefresh()
	if self.ZSInflictionRefreshPending then return end
	self.ZSInflictionRefreshPending = true
	timer.Simple(0, function()
		self.ZSInflictionRefreshPending = nil
		gamemode.Call("CalculateInfliction")
	end)
end

function GM:CalculateInfliction(victim, attacker)
	if self.RoundEnded or self:GetWave() == 0 then return self.CappedInfliction end

	local players = 0
	local zombies = 0
	local humans = 0
	local wonhumans = 0
	local hum
	for _, pl in player.Iterator() do
		if not pl:IsSpectator() and not pl.Disconnecting then
			if pl:Team() == TEAM_UNDEAD then
				zombies = zombies + 1
			elseif pl:HasWon() then
				wonhumans = wonhumans + 1
			else
				humans = humans + 1
				hum = pl
			end
		end
	end

	players = humans + zombies

	if players == 0 then
		if wonhumans > 0 then gamemode.Call("EndRound", TEAM_HUMAN) end
		return self.CappedInfliction
	end

	local infliction = math.max(zombies / players, self.CappedInfliction)
	self.CappedInfliction = infliction

	if humans == 1 and 2 < zombies then
		gamemode.Call("LastHuman", hum)
	elseif 1 <= infliction then
		infliction = 1

		if wonhumans >= 1 then
			gamemode.Call("EndRound", TEAM_HUMAN)
		else
			gamemode.Call("EndRound", TEAM_UNDEAD)

			if attacker and attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD and attacker ~= victim then
				gamemode.Call("LastBite", victim, attacker)
			end
		end
	end

	if not self:IsClassicMode() and not self.ZombieEscape and not self:IsBabyMode() and not self.PantsMode then
		for k, v in ipairs(self.ZombieClasses) do
			if v.Infliction and infliction >= v.Infliction and not self:IsClassUnlocked(v.Name) then
				v.Unlocked = true
			end
        end
    end
	
	local weaponUnlocks, notificationPlayers
	for k, v in ipairs(self.Items) do
		if v.Infliction and infliction >= v.Infliction and not self:IsWeaponUnlocked(v) then
			inflictionwepnotify = true
			weapontier = math.floor(v.Wave * self:GetNumberOfWaves())
			
			self:SetWeaponInflictionUnlocked(v)
					
			weaponUnlocks = weaponUnlocks or {}
			weaponUnlocks[#weaponUnlocks + 1] = k
					
			if inflictionwepnotify and weapontier ~= self.m_LastTierTold then
				self.m_LastTierTold = weapontier
				if weapontier > 0 and not self.ZombieEscape then
					if not notificationPlayers then
						notificationPlayers = {}
						for _, pl in player.Iterator() do
							if not pl:IsBot() then notificationPlayers[#notificationPlayers + 1] = pl end
						end
					end
					for _, pl in ipairs(notificationPlayers) do
						if pl:Team() == TEAM_HUMAN then pl:CenterNotify(COLOR_GREEN, translate.ClientFormat(pl, "weapon_tier_x", weapontier)) end
					end
				end
			elseif inflictionwepnotify then 
				inflictionwepnotify = false
			end
		end
	end

	if weaponUnlocks then self:SendWeaponUnlocks(weaponUnlocks) end

    for _, ent in pairs(self:GetZSClassEntities("logic_infliction")) do
        if ent.Infliction <= infliction then
            ent:Input("oninflictionreached", NULL, NULL, infliction)
        end
    end

    return infliction
end
timer.Create("CalculateInfliction", 2, 0, function() gamemode.Call("CalculateInfliction") end)
