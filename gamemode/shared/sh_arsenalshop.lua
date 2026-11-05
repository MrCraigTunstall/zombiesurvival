function GM:WeaponTiersEnabled()
 return not self.ZombieEscape and GetGlobalBool("zs_weapon_tiers", true)
end

function GM:GetWeaponTier(item)
 if not self:WeaponTiersEnabled() or type(item) ~= "table" or type(item.SWEP) ~= "string" or item.SWEP == "" then return end
 local wave, waves = item.Wave, self:GetNumberOfWaves()
 if type(wave) ~= "number" or wave ~= wave or math.abs(wave) == math.huge or type(waves) ~= "number" or waves < 1 or waves ~= waves or waves == math.huge then return end
 return math.max(1, math.floor(wave * waves))
end

local unlockState = GM.ZSWeaponInflictionUnlocks or {originals = setmetatable({}, {__mode = "k"}), nilValue = {}}
GM.ZSWeaponInflictionUnlocks = unlockState

function GM:SetWeaponInflictionUnlocked(item)
	if unlockState.originals[item] == nil then
		local value = item.Unlocked
		unlockState.originals[item] = value == nil and unlockState.nilValue or value
	end
	item.Unlocked = true
end

function GM:ResetWeaponInflictionUnlocks()
	for item, original in pairs(unlockState.originals) do
		if original == unlockState.nilValue then item.Unlocked = nil else item.Unlocked = original end
		unlockState.originals[item] = nil
	end
end

local families = {"prop_arsenalcrate", "status_arsenalcrate"}

local function FindNearbyArsenalCrate(gm, pl, first)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	local position, best, bestDistance = pl:EyePos()
	local traced, traceEntity
	for _, family in ipairs(families) do
		for _, crate in ipairs(gm:GetZSClassEntities(family)) do
			if IsValid(crate) and (family ~= "status_arsenalcrate" or crate:GetOwner() ~= pl) then
				local nearest = crate:NearestPoint(position)
				local distance = position:DistToSqr(nearest)
				if distance <= 80 * 80 and (not best or distance < bestDistance) then
					local visible = WorldVisible(position, nearest)
					if not visible then
						if not traced then traceEntity = pl:TraceLine(80).Entity; traced = true end
						visible = traceEntity == crate
					end
					if visible then
						if first then return crate end
						best, bestDistance = crate, distance
					end
				end
			end
		end
	end
	return best
end

function GM:GetNearbyArsenalCrate(pl)
	return FindNearbyArsenalCrate(self, pl, false)
end

function GM:HasNearbyArsenalCrate(pl)
	return FindNearbyArsenalCrate(self, pl, true) ~= nil
end

function GM:GetArsenalOwner(crate)
	if not IsValid(crate) then return end
	local owner = crate.GetObjectOwner and crate:GetObjectOwner() or crate:GetOwner()
	if IsValid(owner) and owner:IsPlayer() and owner:Team() == TEAM_HUMAN then return owner end
end

function GM:GetArsenalPriceScale(pl, crate)
	local active = self:GetWaveActive()
	local scale = active and 1 or self.ArsenalCrateMultiplier
	if type(scale) ~= "number" or scale ~= scale or scale <= 0 or scale == math.huge then return end
	if self:HasPlayerTrait(pl, "belovedcustomer") then scale = scale * 0.95 end
	local owner = self:GetArsenalOwner(crate)
	if owner ~= pl and self:HasPlayerTrait(owner, "merchant") then scale = scale * (active and 0.95 or 0.9) end
	return scale, owner
end

function GM:RoundArsenalPrice(value)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return end
	if value == 0 then return 0 end
	return math.max(1, math.ceil(value - 0.0000001))
end

function GM:GetArsenalPrice(pl, item, crate)
	if type(item) ~= "table" or type(item.Worth) ~= "number" or item.Worth ~= item.Worth or item.Worth < 0 or item.Worth == math.huge then return end
	local scale, owner = self:GetArsenalPriceScale(pl, crate)
	if not scale then return end
	local price = self:RoundArsenalPrice(item.Worth * scale * self:GetTraitArsenalItemScale(pl, item))
	if not price then return end
	return price, owner
end
