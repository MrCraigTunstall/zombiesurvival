local VoiceSetTranslate = {}
VoiceSetTranslate["models/player/alyx.mdl"] = VOICESET_ALYX
VoiceSetTranslate["models/player/barney.mdl"] = VOICESET_BARNEY
VoiceSetTranslate["models/player/combine_soldier.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/player/combine_soldier_prisonguard.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/player/combine_super_soldier.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/player/police.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/grim.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/player/police_fem.mdl"] = VOICESET_COMBINE
VoiceSetTranslate["models/player/monk.mdl"] = VOICESET_MONK
VoiceSetTranslate["models/jason278-players/gabe_3.mdl"] = VOICESET_MONK
VoiceSetTranslate["models/player/mossman.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/brsp.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/moe_glados_p.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/mossman_arctic.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/p2_chell.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/dawson/obese_male_deluxe/obese_male_deluxe.mdl"] = VOICESET_MONK
VoiceSetTranslate["models/player/cirno/cirno_player.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/dewobedil/eromanga_sensei/sagiri/pajama_p.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/loyalists/mmd/remilia/remilia_mp_pm.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/loyalists/mmd/flandre/flandre_mp_pm.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/jazzmcfly/kantai/yuudachi/yuudachi.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/dewobedil/vocaloid/haku/bikini_p.mdl"] = VOICESET_FEMALE
VoiceSetTranslate["models/player/dewobedil/touhou/junko/default_p.mdl"] = VOICESET_FEMALE
function GM:PlayerSpawn(pl)
	pl.TeleportTo, pl.TeleportSigil = nil, nil
	pl.KilledByTriggerHurt = nil
	self:ResetZombieAnimation(pl)
	if pl.ZSSpawnPlacementFailed then
		pl.ZSSpawnPlacementFailed = nil
		pl:KillSilent()
		if not pl:IsBot() then pl:CenterNotify(COLOR_RED, "All spawn locations are blocked. Clear a spawn or try again.") end
		return
	end
	pl.ZSSuperBoss = nil
	pl.ZSNextBossAbility = nil
	self:ClearZombieSpawnVariants(pl)
	pl:StripWeapons()
	pl:RemoveStatus("confusion", false, true)
	pl:RemoveFlags(FL_ONGROUND) 

	if pl:GetMaterial() ~= "" then
		pl:SetMaterial("")
	end

	pl:UnSpectate()

	pl.StartCrowing = nil
	pl.StartSpectating = nil
	pl.NextSpawnTime = nil
	pl.Gibbed = nil

	pl.SpawnNoSuicide = CurTime() + 1
	pl.SpawnedTime = CurTime()

	pl:ShouldDropWeapon(false)

	pl:SetLegDamage(0)
	pl:SetLastAttacker()

	local pcol = Vector(pl:GetInfo("cl_playercolor"))
	pcol.x = math.Clamp(pcol.x, 0, 2.5)
	pcol.y = math.Clamp(pcol.y, 0, 2.5)
	pcol.z = math.Clamp(pcol.z, 0, 2.5)
	pl:SetPlayerColor(pcol)

	if pl:Team() == TEAM_UNDEAD then
		pl:RemoveStatus("overridemodel", false, true)

		if not pl.Revived then
			pl.DamagedBy = {}
		end

		pl.LifeBarricadeDamage = 0
		pl.LifeHumanDamage = 0
		pl.LifeBrainsEaten = 0

		pl.BossHealRemaining = nil

		if self:GetUseSigils() and self:GetEscapeSequence() and self:GetEscapeStage() >= ESCAPESTAGE_BOSS and not pl.Revived then
			pl:SetZombieClassName("Super Zombie")
		elseif pl.DeathClass and self:GetWaveActive() then
			pl:SetZombieClass(pl.DeathClass)
			pl.DeathClass = nil
		end

		local classtab = pl:GetZombieClassTable()
		pl:DoHulls(pl:GetZombieClass(), TEAM_UNDEAD)
		
		pl:CollisionRulesChanged()

		if classtab.Model then
			if (type(classtab.Model) == "table") then
				pl:SetModel(table.Random(classtab.Model))
			else
				pl:SetModel(classtab.Model)
			end
		elseif classtab.UsePlayerModel then
			local mdl = player_manager.TranslatePlayerModel(pl:GetInfo("cl_playermodel"))
			if table.HasValue(self.RestrictedModels, mdl) then
				pl:SelectRandomPlayerModel()
			else
				pl:SetModel(mdl)
			end
		elseif classtab.UsePreviousModel then
			local curmodel = string.lower(pl:GetModel())
			if table.HasValue(self.RestrictedModels, curmodel) or (not VoiceSetTranslate[curmodel] and string.sub(curmodel, 1, 14) ~= "models/player") then
				pl:SelectRandomPlayerModel()
			end
		elseif classtab.UseRandomModel then
			pl:SelectRandomPlayerModel()
		else
			pl:SetModel("models/player/zombie_classic_hbfix.mdl")
		end

		if classtab.Boss then
			pl:SetHealth(classtab.Health)
		else
			local lowundead = team.NumPlayers(TEAM_UNDEAD) < 4

			local healthmulti = (self.ObjectiveMap or self.ZombieEscape) and 1 or lowundead and 1.5 or 1
			pl:SetHealth(classtab.Health * healthmulti)
		end

		if classtab.SWEP then
			pl:Give(classtab.SWEP)
		end

		pl:SetNoTarget(true)
		pl:SetMaxHealth(pl:Health())

		pl:ResetSpeed()
		pl:SetCrouchedWalkSpeed(classtab.CrouchedWalkSpeed or 0.45)

		if not pl.Revived or not self:GetWaveActive() or CurTime() > self:GetWaveEnd() then
			pl.StartCrowing = 0
		end

		if pl.ForceSpawnAngles then
			pl:SetEyeAngles(pl.ForceSpawnAngles)
			pl.ForceSpawnAngles = nil
		end

		if not pl.Revived and not pl:GetZombieClassTable().NeverAlive and pl.SpawnedOnSpawnPoint and not pl.DidntSpawnOnSpawnPoint then
			pl:GiveStatus("zombiespawnbuff", self.ObjectiveMap and 1.5 or 3)
		end
		pl.DidntSpawnOnSpawnPoint = nil
		pl.SpawnedOnSpawnPoint = nil
		pl.m_PointQueue = 0
		local overridemodel = pl:GetZombieClassTable().OverrideModel
		if overridemodel then
			local current = pl:GiveStatus("overridemodel")
			if current and current:IsValid() then
				current:SetModel(overridemodel)
				current:ResetBones()
				pl:CallZombieFunction1("ManipulateOverrideModel", current)
			end
		else
			pl:RemoveStatus("overridemodel", false, true)
		end

		local oldhands = pl:GetHands()
		if IsValid(oldhands) then
			oldhands:Remove()
		end

		pl:CallZombieFunction0("OnSpawned")
	elseif pl:Team() == TEAM_HUMAN then
		pl:DoHulls(pl:GetZombieClass(), TEAM_HUMAN)
		pl.PointQueue = 0
		pl.PackedItems = {}
		pl:ClearUselessDamage()
		
		local desiredname = pl:GetInfo("cl_playermodel")
		local modelname = player_manager.TranslatePlayerModel(#desiredname == 0 and self.RandomPlayerModels[math.random(#self.RandomPlayerModels)] or desiredname)
		local lowermodelname = string.lower(modelname)
		if table.HasValue(self.RestrictedModels, lowermodelname) then
			modelname = "models/player/alyx.mdl"
			lowermodelname = modelname
		end
		pl:SetModel(modelname)

		
		if VoiceSetTranslate[lowermodelname] then
			pl:SetDTInt(DT_PLAYER_INT_VOICESET, VoiceSetTranslate[lowermodelname])
		elseif string.find(lowermodelname, "female", 1, true) then
			pl:SetDTInt(DT_PLAYER_INT_VOICESET, VOICESET_FEMALE)
		else
			pl:SetDTInt(DT_PLAYER_INT_VOICESET, VOICESET_MALE)
		end

		pl.HumanSpeedAdder = nil

		pl:SetNoTarget(false)
		pl:SetMaxHealth(100)
		
		pl:CollisionRulesChanged()

		pl.BonusDamageCheck = CurTime()

		pl:ResetSpeed()
		pl:SetJumpPower(DEFAULT_JUMP_POWER)
		pl:SetCrouchedWalkSpeed(0.65)
		pl:SetViewOffset(DEFAULT_VIEW_OFFSET)
		pl:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)

		if self.ZombieEscape then
			pl:Give("weapon_zs_zeknife")
			pl:Give("weapon_zs_zegrenade")
			pl.ZEWeaponChoiceUsed = false
			pl.ZEWeaponNextChoice = nil
			pl.ZEPrimaryWeapon = self:GetZombieEscapeWeapon(pl)
			pl:Give(pl.ZEPrimaryWeapon)
			pl:Give(table.Random(self.ZombieEscapeWeapons2))
		else
			pl:Give("weapon_zs_fists")

			if self.StartingLoadout then
				self:GiveStartingLoadout(pl)
			elseif pl.m_PreRedeem then
				if self.RedeemLoadout then
					for _, class in pairs(self.RedeemLoadout) do
						pl:Give(class)
					end
				else
					pl:Give("weapon_zs_redeemers")
					pl:Give("weapon_zs_swissarmyknife")
				end
			end
		end

		local oldhands = pl:GetHands()
		if IsValid(oldhands) then
			oldhands:Remove()
		end

		local hands = ents.Create("zs_hands")
		if hands:IsValid() then
			hands:DoSetup(pl)
			hands:Spawn()
		end
	end

	pl:DoMuscularBones()
	pl:DoNoodleArmBones()
	self:ApplyReturnBones(pl)

	local pcol = Vector(pl:GetInfo("cl_playercolor"))
	pcol.x = math.Clamp(pcol.x, 0, 2.5)
	pcol.y = math.Clamp(pcol.y, 0, 2.5)
	pcol.z = math.Clamp(pcol.z, 0, 2.5)
	pl:SetPlayerColor(pcol)

	local wcol = Vector(pl:GetInfo("cl_weaponcolor"))
	wcol.x = math.Clamp(wcol.x, 0, 2.5)
	wcol.y = math.Clamp(wcol.y, 0, 2.5)
	wcol.z = math.Clamp(wcol.z, 0, 2.5)
	pl:SetWeaponColor(wcol)

	pl.m_PreHurtHealth = pl:Health()
	self:ApplyMutationSpawnEffects(pl)
	self:ApplyZombieSkinVariant(pl)
	if self:ShouldGetZombieVariant(pl) then self:ApplyZombieVariant(pl) end
	if pl.ZSSpawnPlayerOverlap then pl.ZSSpawnPlayerOverlap = nil; pl:TemporaryNoCollide(true) end
end
