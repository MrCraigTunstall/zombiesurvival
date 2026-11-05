function GM:SetWave(wave)
	if wave == 0 then self:ResetTraitIntermission() end
	local previouslylocked = {}
	local UnlockedClasses = {}
	for classid in ipairs(self.ZombieClasses) do
		if not gamemode.Call("IsClassUnlocked", classid) then
			previouslylocked[classid] = true
		end
	end

	SetGlobalInt("wave", wave)

	for classid in pairs(previouslylocked) do
		if gamemode.Call("IsClassUnlocked", classid) then
			local classtab = self.ZombieClasses[classid]
			if not classtab.UnlockedNotify then
				classtab.UnlockedNotify = true
				table.insert(UnlockedClasses, classid)
			end

			for _, ent in pairs(ents.FindByClass("logic_classunlock")) do
				local classname = GAMEMODE.ZombieClasses[classid].Name
				if ent.Class == string.lower(classname) then
					ent:Input("onclassunlocked", ent, ent, classname)
				end
			end
		end
	end

	if not self.ZombieEscape and #UnlockedClasses > 0 then
		for _, pl in player.Iterator() do
			if pl:IsBot() then continue end
			local classnames = {}
			for __, classid in pairs(UnlockedClasses) do
				table.insert(classnames, translate.ClientGet(pl, self.ZombieClasses[classid].TranslationName))
			end
			net.Start("zs_classunlock")
				net.WriteString(string.AndSeparate(classnames))
			net.Send(pl)
		end
	end
end

GM.NextEscapeDamage = 0
function GM:WaveStateChanged(newstate)
	if newstate then
		if self:GetWave() == 0 then
			self:SetClosestsToZombie()

			local humans = {}
			for _, pl in player.Iterator() do
				if pl:Team() == TEAM_HUMAN and pl:Alive() then
					table.insert(humans, pl)
				end
			end

			if #humans >= 1 then
				for _, pl in pairs(humans) do
					gamemode.Call("GiveDefaultOrRandomEquipment", pl)
					pl.BonusDamageCheck = CurTime()
				end
			end

			
			if not self.ZombieEscape and not self:IsTraderOnlyRound() and #self:GetZSClassEntities("prop_arsenalcrate") == 0 then
				local have = false
				for _, pl in pairs(humans) do
					if pl:HasWeapon("weapon_zs_arsenalcrate") then
						have = true
						break
					end
				end

				if not have and #humans >= 1 then
					local spawn = self:PlayerSelectSpawn(humans[math.random(#humans)])
					if spawn and spawn:IsValid() then
						local ent = ents.Create("prop_arsenalcrate")
						if ent:IsValid() then
							ent:SetPos(spawn:GetPos())
							ent:Spawn()
							ent:DropToFloor()
							ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER) 
							ent.NoTakeOwnership = true
						end
					end
				end
			end
		end

		local prevwave = self:GetWave()

		if self:GetUseSigils() and prevwave >= self:GetNumberOfWaves() then return end

		gamemode.Call("SetWave", prevwave + 1)
		gamemode.Call("SetWaveStart", CurTime())
		if self.ZombieEscape then
			gamemode.Call("SetWaveEnd", -1)
			SetGlobalInt("numwaves", -1)
		else
			gamemode.Call("SetWaveEnd", self:GetWaveStart() + self:GetWaveOneLength() + (self:GetWave() - 1) * (GetGlobalBool("classicmode") and self.TimeAddedPerWaveClassic or self.TimeAddedPerWave))
		end

		net.Start("zs_wavestart")
			net.WriteInt(self:GetWave(), 16)
			net.WriteFloat(self:GetWaveEnd())
		net.Broadcast()

		for _, pl in pairs(team.GetPlayers(TEAM_UNDEAD)) do
			pl.m_LastWaveStartSpawn = CurTime()
			if pl:GetZombieClassTable().Name == "Crow" then
				pl:SetZombieClass(pl.DeathClass or 1)
				pl:UnSpectateAndSpawn()
			elseif not pl:Alive() and not pl.Revive then
				pl:UnSpectateAndSpawn()
			end
		end
		
		for _, pl in player.Iterator() do
			pl.WaveBarricadeDamage = 0
			pl.WaveHumanDamage = 0
		end

		local curwave = self:GetWave()
		for _, ent in pairs(ents.FindByClass("logic_waves")) do
			if ent.Wave == curwave or ent.Wave == -1 then
				ent:Input("onwavestart", ent, ent, curwave)
			end
		end
		for _, ent in pairs(ents.FindByClass("logic_wavestart")) do
			if ent.Wave == curwave or ent.Wave == -1 then
				ent:Input("onwavestart", ent, ent, curwave)
			end
		end
	elseif self:GetWave() >= self:GetNumberOfWaves() then 
		if self:GetUseSigils() then
			if self:GetEscapeStage() == ESCAPESTAGE_BOSS then
				self:SetEscapeStage(ESCAPESTAGE_DEATH)

				PrintTranslatedMessage(3, "sigil_deathfog")

				gamemode.Call("SetWaveEnd", -1)
			elseif self:GetEscapeStage() == ESCAPESTAGE_ESCAPE then
				self:SetEscapeStage(ESCAPESTAGE_BOSS)

				
				gamemode.Call("SetWaveEnd", CurTime() + 120)

				PrintTranslatedMessage(3, "sigil_escapeboss")

				
			elseif self:GetEscapeStage() == ESCAPESTAGE_NONE then
				
				for _, sigil in ipairs(self:GetZSClassEntities("prop_obj_sigil")) do
					local ent = ents.Create("prop_obj_exit")
					if ent:IsValid() then
						ent:SetPos(sigil.NodePos or sigil:GetPos())
						ent:SetAngles(sigil:GetAngles())
						ent:Spawn()
					end

					sigil:Destroy()
				end

				



				PrintTranslatedMessage(3, "sigil_escapestart")

				
				gamemode.Call("SetWaveActive", true)
				gamemode.Call("SetWaveEnd", CurTime() + 120)
				self:SetEscapeStage(ESCAPESTAGE_ESCAPE)

				local curwave = self:GetWave()
				for _, ent in pairs(ents.FindByClass("logic_waves")) do
					if ent.Wave == curwave or ent.Wave == -1 then
						ent:Input("onwaveend", ent, ent, curwave)
					end
				end
				for _, ent in pairs(ents.FindByClass("logic_waveend")) do
					if ent.Wave == curwave or ent.Wave == -1 then
						ent:Input("onwaveend", ent, ent, curwave)
					end
				end
			end
		else
			
			gamemode.Call("EndRound", TEAM_HUMAN)

			local curwave = self:GetWave()
			for _, ent in pairs(ents.FindByClass("logic_waves")) do
				if ent.Wave == curwave or ent.Wave == -1 then
					ent:Input("onwaveend", ent, ent, curwave)
				end
			end
			for _, ent in pairs(ents.FindByClass("logic_waveend")) do
				if ent.Wave == curwave or ent.Wave == -1 then
					ent:Input("onwaveend", ent, ent, curwave)
				end
			end
		end
	else
		gamemode.Call("SetWaveStart", CurTime() + (GetGlobalBool("classicmode") and self.WaveIntermissionLengthClassic or self.WaveIntermissionLength))
		local curwave = self:GetWave()

		net.Start("zs_waveend")
			net.WriteInt(curwave, 16)
			net.WriteFloat(self:GetWaveStart())
		net.Broadcast()

		for _, pl in player.Iterator() do
			if pl:Team() == TEAM_HUMAN and pl:Alive() then
				if pl.ZSTraits and pl.ZSTraits.mysteriousstranger then self:TraitIntermissionReward(pl, curwave) end
				if self.EndWaveHealthBonus > 0 then
					pl:SetHealth(math.min(pl:GetMaxHealth(), pl:Health() + self.EndWaveHealthBonus))
				end
			elseif pl:Team() == TEAM_UNDEAD and not pl:Alive() and not pl.Revive then
				local curclass = pl.DeathClass or pl:GetZombieClass()
				local crowindex = GAMEMODE.ZombieClasses["Crow"].Index
				pl:SetZombieClass(crowindex)
				pl:DoHulls(crowindex, TEAM_UNDEAD)
				pl.DeathClass = nil
				pl:UnSpectateAndSpawn()
				pl.DeathClass = curclass
			end

			pl.SkipCrow = nil
		end

		for _, ent in pairs(ents.FindByClass("logic_waves")) do
			if ent.Wave == curwave or ent.Wave == -1 then
				ent:Input("onwaveend", ent, ent, curwave)
			end
		end
		for _, ent in pairs(ents.FindByClass("logic_waveend")) do
			if ent.Wave == curwave or ent.Wave == -1 then
				ent:Input("onwaveend", ent, ent, curwave)
			end
		end
	end

	hook.Run("OnWaveStateChanged")
end
