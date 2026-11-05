local state = GM.ZSTraitState or {sticky = {}}
GM.ZSTraitState = state
state.headcrabConsumers = state.headcrabConsumers or setmetatable({}, {__mode = "k"})
state.strangerWave = state.strangerWave or setmetatable({}, {__mode = "k"})
local meleeTypes = bit.bor(DMG_SLASH, DMG_CLUB)
local poisonTypes = bit.bor(DMG_POISON, DMG_ACID)

local function Zombie(pl)
	return IsValid(pl) and pl:IsPlayer() and pl:Team() == TEAM_UNDEAD and not pl:GetZombieClassTable().NeverAlive
end

local function Kleiner(pl)
	return string.lower(pl:GetModel()) == "models/player/kleiner.mdl"
end

local function Positive(value)
	return type(value) == "number" and value > 0 and value < math.huge
end

function GM:ResetTraitIntermission()
	state.strangerWave = setmetatable({}, {__mode = "k"})
end

function GM:GetStrangerPistolCatalog()
	if state.strangerCatalog then return state.strangerCatalog end
	local catalog, seen = {}, {}
	for _, entry in ipairs(weapons.GetList()) do
		local class = entry.ClassName
		if type(class) == "string" and not seen[class] and weapons.IsBasedOn(class, "weapon_zs_base") then
			local stored = weapons.GetStored(class)
			local primary = stored and stored.Primary
			local hold = stored and stored.HoldType
			local ammo = primary and primary.Ammo
			if primary and not stored.IsMelee and (hold == "pistol" or hold == "revolver" or hold == "duel" and (ammo == "pistol" or ammo == "357" or ammo == "pulse"))
				and Positive(primary.Damage) and Positive(primary.ClipSize) and type(ammo) == "string" and game.GetAmmoID(ammo) >= 0 then
				catalog[#catalog + 1] = class; seen[class] = true
			end
		end
	end
	table.sort(catalog); state.strangerCatalog = catalog
	return catalog
end

function GM:TraitIntermissionReward(pl, wave)
	if self.RoundEnded or self.ZombieEscape or self:GetWaveActive() or wave ~= self:GetWave() or wave <= 0 or wave >= self:GetNumberOfWaves()
		or not self:HasPlayerTrait(pl, "mysteriousstranger") or not pl:IsConnected() or not pl:Alive() then return false, "unavailable" end
	if state.strangerWave[pl] == wave then return false, "duplicate" end
	state.strangerWave[pl] = wave
	if math.Rand(0, 1) >= 0.25 then return false, "roll" end
	local catalog = self:GetStrangerPistolCatalog()
	if #catalog == 0 then return false, "catalog" end
	local class = catalog[math.random(#catalog)]
	local stored = weapons.GetStored(class)
	local primary = stored and stored.Primary
	if not primary or type(primary.Ammo) ~= "string" or not Positive(primary.ClipSize) then state.strangerCatalog = nil; return false, "catalog" end
	local ammo = game.GetAmmoID(primary.Ammo)
	if ammo < 0 then state.strangerCatalog = nil; return false, "catalog" end
	local created
	local ok, weapon = pcall(function()
		local held = pl:GetWeapon(class)
		if not IsValid(held) then
			local reserve = pl:GetAmmoCount(ammo)
			held = pl:Give(class); created = held
			if not IsValid(held) or held:GetOwner() ~= pl then return end
			pl:SetAmmo(reserve, ammo)
		end
		if not held.Primary or not Positive(held.Primary.ClipSize) then return end
		local capacity = math.min(512, math.floor(held.Primary.ClipSize))
		if held:Clip1() < capacity then held:SetClip1(capacity) end
		pl:GiveAmmo(capacity * 2, ammo, true)
		return held
	end)
	if not ok or not IsValid(weapon) then
		if IsValid(created) then created:Remove() end
		if not ok then ErrorNoHalt("ZS stranger reward: " .. tostring(weapon) .. "\n") end
		return false, "failed"
	end
	if not pl:IsBot() then pl:CenterNotify(COLOR_LIMEGREEN, "Mysterious Stranger: " .. (type(weapon.PrintName) == "string" and weapon.PrintName or class)) end
	return true, weapon
end

hook.Add("OnReloaded", "ZSTraitPistolCatalog", function() state.strangerCatalog = nil end)
hook.Add("PlayerDisconnected", "ZSTraitIntermission", function(pl) state.strangerWave[pl] = nil end)

function GM:SetPlayerTrait(pl, flag)
	local definition = self.TraitLookup[flag]
	if not IsValid(pl) or not pl:IsPlayer() or not definition then return false end
	pl.ZSTraits = pl.ZSTraits or {}
	if pl.ZSTraits[flag] then return true end
	pl.ZSTraits[flag] = true
	local delivered, tool, recoverable = true
	if flag == "headcrabconnoisseur" then state.headcrabConsumers[pl] = true end
	if flag == "tonguelover" and self.GiveTraitBarnacleWeapon then delivered, tool, recoverable = self:GiveTraitBarnacleWeapon(pl) end
	if flag == "alientrainer" and self.GiveTraitSnarkWeapon then delivered, tool, recoverable = self:GiveTraitSnarkWeapon(pl) end
	pl.ZSTraitWordCount = math.max(pl.ZSTraitWordCount or 1, definition.Word or 1)
	local previous = pl:GetNW2Int(definition.NetKey or "zs_traits", 0)
	local value = bit.bor(previous, definition.Mask)
	if previous ~= value then pl:SetNW2Int(definition.NetKey or "zs_traits", value) end
	if flag == "acrobatic" then pl:ResetJumpPower() end
	if flag == "kenjutsu" then pl:ResetSpeed() end
	if flag == "cheerleader" then self:RegisterTraitAura(pl) end
	if flag == "strongfeet" then
		local status = pl:GetStatus("knockdown")
		if IsValid(status) then status:Remove() end
	end
	return true, delivered ~= false, recoverable
end

function GM:GrantWorthTrait(pl, flag, progress)
	if not progress.traitApplied then
		local applied, delivered, recoverable = self:SetPlayerTrait(pl, flag)
		if not applied then return false end
		progress.traitApplied = true
		if delivered == false then return false, recoverable end
	end
	if flag == "tonguelover" or flag == "alientrainer" then
		local helper = flag == "tonguelover" and self.GiveTraitBarnacleWeapon or self.GiveTraitSnarkWeapon
		if not helper then return false, false end
		local delivered, tool, recoverable = helper(self, pl)
		return delivered == true, recoverable
	end
	return true
end
GM.ZSWorthTraitAdapter = GM.GrantWorthTrait
GM.ZSWorthTraitSetter = GM.SetPlayerTrait

function GM:ResetPlayerTraits(pl)
	if pl.ZSTraits and pl.ZSTraits.parkour then
		local weapon = pl:GetWeapon("weapon_zs_fists")
		if IsValid(weapon) and weapon.GetParkourSpent then
			if weapon:GetParkourActive() then weapon:SetParkourActive(false) end
			if IsValid(weapon:GetParkourSurface()) then weapon:SetParkourSurface(NULL) end
		end
	end
	if self.RemoveTraitBarnacles then self:RemoveTraitBarnacles(pl) end
	if self.RemoveTraitSnarks then self:RemoveTraitSnarks(pl) end
	pl.ZSTraitSnarkCharges = nil
	if pl.ZSTraits and pl.ZSTraits.cheerleader then self:UnregisterTraitAura(pl) end
	if pl.ZSTraitDrunkUntil then self:ClearTraitDrunk(pl) end
	local jumping = pl.ZSTraits and pl.ZSTraits.acrobatic
	local running = pl.ZSTraits and pl.ZSTraits.kenjutsu
	pl.ZSTraits, pl.ZSTraitHumanKiller = nil, nil
	pl.ZSTraitDeathMark, pl.ZSTraitSniperShot = nil, nil
	self:ClearTraitSticky(pl)
	for word = 1, math.max(self.TraitWordCount, pl.ZSTraitWordCount or 1) do
		local key = self.TraitNetKeys[word] or "zs_traits_" .. word
		if pl:GetNW2Int(key, 0) ~= 0 then pl:SetNW2Int(key, 0) end
	end
	pl.ZSTraitWordCount = nil
	if jumping then pl:ResetJumpPower() end
	if running then pl:ResetSpeed() end
end

local function Melee(damage, inflictor)
	local kind = damage:GetDamageType()
	return IsValid(inflictor) and inflictor.IsMelee and bit.band(kind, meleeTypes) ~= 0 and bit.band(kind, poisonTypes) == 0
end

function GM:IsTraitCombineSource(source, owner)
	if not IsValid(source) or not source.TraitCombine then return false end
	if source.GetManualControl and source:GetManualControl() then return false end
	local holder = source.GetObjectOwner and source:GetObjectOwner() or source:GetOwner()
	return holder == owner
end

function GM:GetTraitBlastScale(attacker, inflictor)
	if self:HasPlayerTrait(attacker, "bigbang") and self:IsTraitBlastSource(inflictor) and math.Rand(0, 1) < 0.5 then return 1.25 end
	return 1
end

function GM:ApplyCraftDamage(damage, attacker, source)
	if not IsValid(source) or source.ZSCrafter ~= attacker or not self:HasPlayerTrait(attacker, "crafty") or damage:GetDamage() <= 0 then return end
	local owner = source.GetObjectOwner and source:GetObjectOwner() or source:GetOwner()
	if owner == attacker then damage:ScaleDamage(1.1) end
end

function GM:ApplyTraitDamage(pl, damage)
	if damage:GetDamage() <= 0 then return end
	local attacker, inflictor = damage:GetAttacker(), damage:GetInflictor()
	local flags = pl.ZSTraits
	local attacking
	if not flags then
		attacking = IsValid(attacker) and attacker.ZSTraits
		if not attacking then return end
	end
	if damage:IsExplosionDamage() and pl:Team() == TEAM_HUMAN and IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN then
		if attacker ~= pl and attacker.ZSTraits and attacker.ZSTraits.demolitionist then
			damage:SetDamage(0); damage:ScaleDamage(0); return true
		end
		if flags and flags.demolitionist then damage:ScaleDamage(0.5) end
	end
	if flags and pl:Team() == TEAM_HUMAN then
		if flags.venomimmunity and bit.band(damage:GetDamageType(), poisonTypes) ~= 0 then
			damage:SetDamage(0); damage:ScaleDamage(0); return true
		end
		if Zombie(attacker) then
			if (flags.swordsman or flags.thickskin) and Melee(damage, inflictor) then
				if flags.swordsman then
					local held = pl:GetActiveWeapon()
					if IsValid(held) and held.IsMelee and math.Rand(0, 1) < 0.4 then
						damage:SetDamage(0); damage:ScaleDamage(0); return true
					end
				end
				if flags.thickskin then damage:ScaleDamage(0.8) end
			end
			if flags.kleiner and Kleiner(pl) then damage:ScaleDamage(0.975) end
		end
	end
	if not Zombie(pl) or (not attacking and not IsValid(attacker)) or not attacker:IsPlayer() or attacker:Team() ~= TEAM_HUMAN then return end
	flags = attacking or attacker.ZSTraits
	if not flags then return end
	if flags.deathmark then self:ApplyTraitSniperDamage(pl, damage, attacker, inflictor) end
	if flags.chosenone and pl:GetZombieClassTable().Boss then damage:ScaleDamage(1.05) end
	if flags.kleiner and Kleiner(attacker) then damage:ScaleDamage(1.025) end
	if flags.punisher and pl.ZSTraitHumanKiller then damage:ScaleDamage(1.075) end
	if flags.combinefellow and self:IsTraitCombineSource(inflictor, attacker) then damage:ScaleDamage(1.1) end
	if flags.experiencedhunter and self:IsTraitHunterWeapon(inflictor) and damage:IsBulletDamage() then damage:ScaleDamage(1.05) end
	if flags.sniper and IsValid(inflictor) and inflictor.TraitSniper and damage:IsBulletDamage() and attacker:OnGround()
		and (attacker:Crouching() or attacker:GetVelocity():Length2DSqr() <= 1) then damage:ScaleDamage(1.2) end
	if flags.kenjutsu and IsValid(inflictor) and inflictor:GetClass() == "weapon_zs_katana" and Melee(damage, inflictor) then damage:ScaleDamage(1.1) end
end

function GM:ClearTraitSticky(pl)
	state.sticky[pl] = nil
	local changed = pl.ZSTraitStickyUntil ~= nil
	pl.ZSTraitStickyUntil = nil
	if IsValid(pl) then
		if pl:GetNW2Float("zs_trait_sticky", 0) ~= 0 then pl:SetNW2Float("zs_trait_sticky", 0) end
		if changed and pl:Alive() then pl:ResetSpeed() end
	end
	if next(state.sticky) == nil then state.nextSticky = nil end
end

function GM:UpdateTraitEffects(now)
	if not state.nextSticky or now < state.nextSticky then return end
	local nextExpiry
	for pl, expiry in pairs(state.sticky) do
		if not Zombie(pl) or not pl:Alive() or expiry <= now then
			self:ClearTraitSticky(pl)
		elseif not nextExpiry or expiry < nextExpiry then nextExpiry = expiry end
	end
	state.nextSticky = nextExpiry
end

function GM:TraitSigilHeal(pl)
	if not self:HasPlayerTrait(pl, "divinegift") or not pl:Alive() then return end
	local health, maximum = pl:Health(), pl:GetMaxHealth()
	if health < maximum then pl:SetHealth(math.min(maximum, health + 10)) end
end

function GM:ApplyTraitHeadshot(pl, group, damage)
	if group ~= HITGROUP_HEAD or not damage:IsBulletDamage() or not Zombie(pl) then return end
	local attacker, weapon = damage:GetAttacker(), damage:GetInflictor()
	if not self:HasPlayerTrait(attacker, "highnoon") or not IsValid(weapon) then return end
	if weapon.HoldType == "pistol" or weapon.HoldType == "revolver" then damage:ScaleDamage(1.2) end
end

hook.Add("PostEntityTakeDamage", "ZSTraits", function(pl, damage, taken)
	if not taken or not IsValid(pl) or not pl:IsPlayer() then return end
	local attacker = damage:GetAttacker()
	local heal = IsValid(attacker) and attacker.ZSTraits and attacker.ZSTraits.butcher
	local slow = pl.ZSTraits and pl.ZSTraits.sticky
	if not (heal or slow) or damage:GetDamage() <= 0 then return end
	local inflictor = damage:GetInflictor()
	if not Melee(damage, inflictor) then return end
	if heal and Zombie(pl) and attacker:IsPlayer() and attacker:Alive() and attacker:Team() == TEAM_HUMAN then
		local health, maximum = attacker:Health(), attacker:GetMaxHealth()
		if health < maximum then attacker:SetHealth(math.min(maximum, health + math.min(3, math.ceil(damage:GetDamage() * 0.02)))) end
	elseif slow and pl:Team() == TEAM_HUMAN and pl:Alive() and Zombie(attacker) and attacker:Alive() then
		local now = CurTime()
		local active = attacker.ZSTraitStickyUntil and attacker.ZSTraitStickyUntil > now
		local expiry = now + 3
		if attacker.ZSTraitStickyUntil ~= expiry then attacker:SetNW2Float("zs_trait_sticky", expiry) end
		attacker.ZSTraitStickyUntil = expiry; state.sticky[attacker] = expiry
		if not active then attacker:ResetSpeed() end
		if not state.nextSticky or expiry < state.nextSticky then state.nextSticky = expiry end
	end
end)
hook.Add("PostZombieKilledHuman", "ZSTraits", function(pl, attacker, inflictor, damage, headshot, suicide)
	if not suicide and IsValid(pl) and pl:IsPlayer() and pl:Team() == TEAM_HUMAN and Zombie(attacker) then attacker.ZSTraitHumanKiller = true end
end)
hook.Add("Think", "ZSTraits", function()
	if state.nextSticky then GAMEMODE:UpdateTraitEffects(CurTime()) end
end)
hook.Add("PlayerDeath", "ZSTraits", function(pl) GAMEMODE:ClearTraitSticky(pl) end)
hook.Add("OnPlayerChangedTeam", "ZSTraits", function(pl) GAMEMODE:ClearTraitSticky(pl) end)
hook.Add("PlayerDisconnected", "ZSTraits", function(pl) GAMEMODE:ClearTraitSticky(pl); state.headcrabConsumers[pl] = nil; pl.ZSTraits, pl.ZSTraitHumanKiller = nil, nil
	pl.ZSTraitDeathMark, pl.ZSTraitSniperShot = nil, nil end)
