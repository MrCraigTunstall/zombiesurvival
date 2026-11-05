GM.WeaponForgeMaxLevel = 5

local function Positive(value)
	return type(value) == "number" and value > 0 and value < math.huge
end

function GM:GetWeaponForgeLevel(weapon)
	if not IsValid(weapon) then return 0 end
	return math.Clamp(weapon:GetNWInt("ZSForgeLevel", 0), 0, self.WeaponForgeMaxLevel)
end

function GM:GetWeaponForgePrice(level)
	if type(level) ~= "number" or level ~= math.floor(level) or level < 0 or level >= self.WeaponForgeMaxLevel then return end
	return 100 * 2 ^ level
end

local catalog, catalogsource, catalogcount, craftsource, craftcount
local members = {}
function GM:InvalidateWeaponForgeCatalog()
 catalogsource = nil
 members = {}
end
hook.Add("OnReloaded", "ZSWeaponForgeCatalog", function()
 if GAMEMODE then GAMEMODE:InvalidateWeaponForgeCatalog() end
end)
local function InCatalog(gm, class)
	if catalogsource ~= gm.Items or catalogcount ~= #gm.Items or craftsource ~= gm.Crafts or craftcount ~= #(gm.Crafts or {}) then
		catalog, catalogsource, catalogcount = {}, gm.Items, #gm.Items
  members = {}
		craftsource, craftcount = gm.Crafts, #(gm.Crafts or {})
		for _, item in ipairs(gm.Items) do
			if item.SWEP and ((item.Category >= 1 and item.Category <= 6) or item.Category == ITEMCAT_MELEE or item.Category == ITEMCAT_OTHER) then catalog[item.SWEP] = true end
		end
		for _, craft in ipairs(gm.Crafts or {}) do
			local class = craft.Result and craft.Result[1]
			if type(class) == "string" and string.sub(class, 1, 10) == "weapon_zs_" then catalog[class] = true end
		end
	end
	local original = class
 if members[original] ~= nil then return members[original] end
 for i = 1, 16 do
  if catalog[class] then members[original] = true return true end
		local stored = weapons.GetStored(class)
		class = stored and stored.Base
		if type(class) ~= "string" then break end
	end
 members[original] = false
	return false
end

function GM:IsWeaponForgeEligible(weapon)
	if not IsValid(weapon) or not weapon:IsWeapon() or weapon.NoWeaponForge then return false end
	local class = weapon:GetClass()
	local melee = weapons.IsBasedOn(class, "weapon_zs_basemelee")
	if not (melee or weapons.IsBasedOn(class, "weapon_zs_base")) or not InCatalog(self, class) then return false end
	if melee then return Positive(weapon.MeleeDamage) end
	local primary = weapon.Primary
	local mode = weapon.WeaponForgeReload
	if mode ~= "shell" and mode ~= "timed" and mode ~= "crossbow" and mode ~= "heat" and weapon.Reload ~= weapons.GetStored("weapon_zs_base").Reload then return false end
	if (mode == "shell" or mode == "timed") and not Positive(weapon.ReloadDelay) then return false end
	return primary and Positive(primary.Damage) and Positive(primary.Delay) and Positive(primary.ClipSize)
		and primary.Ammo ~= "none" and primary.Ammo ~= "dummy" and primary.Ammo ~= "GaussEnergy"
end

function GM:ApplyWeaponForge(weapon, level)
	if not self:IsWeaponForgeEligible(weapon) or type(level) ~= "number" or level ~= math.floor(level) or level < 0 or level > self.WeaponForgeMaxLevel then return false end
	if weapon.ZSForgeApplied == level then return true end
	local base = weapon.ZSForgeBase
	if not base then
		base = {damage = weapon.Primary.Damage, delay = weapon.Primary.Delay, melee = weapon.MeleeDamage,
			reload = weapon.ReloadSpeed or 1, swing = weapon.SwingTime, shell = weapon.ReloadDelay, explosion = weapon.ExplosionDamage,
			decayshort = weapon.HeatDecayShort, decaylong = weapon.HeatDecayLong, ventshort = weapon.HeatVentShort, ventlong = weapon.HeatVentLong}
		weapon.ZSForgeBase = base
		weapon.Primary = table.Copy(weapon.Primary)
	end
	local damage, speed = 1 + level * 0.1, 1 + level * 0.12
	if Positive(base.damage) then weapon.Primary.Damage = base.damage * damage end
	if Positive(base.melee) then weapon.MeleeDamage = base.melee * damage end
	if Positive(base.explosion) then weapon.ExplosionDamage = base.explosion * damage end
	if Positive(base.delay) then weapon.Primary.Delay = base.delay / speed end
	if Positive(base.swing) then weapon.SwingTime = base.swing / speed end
	local reloadfactor = 1 + level * 0.15
	weapon.ReloadSpeed = base.reload * reloadfactor
	if Positive(base.shell) then weapon.ReloadDelay = base.shell / reloadfactor end
	if Positive(base.decayshort) then weapon.HeatDecayShort = base.decayshort * reloadfactor end
	if Positive(base.decaylong) then weapon.HeatDecayLong = base.decaylong * reloadfactor end
	if Positive(base.ventshort) then weapon.HeatVentShort = base.ventshort * reloadfactor end
	if Positive(base.ventlong) then weapon.HeatVentLong = base.ventlong * reloadfactor end
	weapon.ZSForgeApplied = level
	return true
end

if CLIENT then
 local function ApplyNetworkLevel(ent, _, _, level)
  GAMEMODE:ApplyWeaponForge(ent, level)
 end
 hook.Add("NetworkEntityCreated", "ZSWeaponForge", function(ent)
  if not ent:IsWeapon() then return end
  ent:SetNWVarProxy("ZSForgeLevel", ApplyNetworkLevel)
  local level = GAMEMODE:GetWeaponForgeLevel(ent)
  if level > 0 then GAMEMODE:ApplyWeaponForge(ent, level) end
 end)
end

GM.ZSForgeReloads = GM.ZSForgeReloads or {}

function GM:CancelForgeReload(weapon)
	local pending = self.ZSForgeReloads[weapon]
	if not pending then return end
	self.ZSForgeReloads[weapon] = nil
	if IsValid(pending.owner) and pending.owner:GetActiveWeapon() == weapon then
		local view = pending.owner:GetViewModel()
		if IsValid(view) then view:SetPlaybackRate(1) end
	end
end

function GM:StartForgeReload(weapon, durationOverride)
	local owner = weapon:GetOwner()
	if not IsValid(owner) or not owner:Alive() or owner:GetActiveWeapon() ~= weapon or owner:IsHolding() or owner:GetBarricadeGhosting() then return false end
	local now = CurTime()
	if self.ZSForgeReloads[weapon] or weapon:GetNextReload() > now or weapon:GetNextPrimaryFire() > now then return false end
	local primary = weapon.Primary
	if weapon:Clip1() >= primary.ClipSize or owner:GetAmmoCount(primary.Ammo) <= 0 then return false end
	weapon:SendWeaponAnim(ACT_VM_RELOAD)
	local view = owner:GetViewModel()
	local duration = durationOverride or (IsValid(view) and view:SequenceDuration() or weapon:SequenceDuration())
	local speed = self:GetTraitReloadScale(weapon)
	if not durationOverride then speed = speed * (weapon.ReloadSpeed or 1) end
	duration = math.max(0.05, duration / speed)
	local finish = now + duration
	self.ZSForgeReloads[weapon] = {owner = owner, finish = finish}
	weapon:SetNextPrimaryFire(finish); weapon:SetNextSecondaryFire(finish); weapon:SetNextReload(finish)
	weapon.IdleAnimation = finish
	if IsValid(view) then view:SetPlaybackRate(speed) end
	owner:DoReloadEvent()
	if weapon.ReloadSound then weapon:EmitSound(weapon.ReloadSound) end
	return true
end

hook.Add("Think", "ZSWeaponForgeReload", function()
	local gm = GAMEMODE
	if next(gm.ZSForgeReloads) == nil then return end
	local now = CurTime()
	for weapon, pending in pairs(gm.ZSForgeReloads) do
		local owner = pending.owner
		if not IsValid(weapon) or not IsValid(owner) or weapon:GetOwner() ~= owner or owner:GetActiveWeapon() ~= weapon or not owner:Alive() then
			gm:CancelForgeReload(weapon)
		elseif now >= pending.finish then
			if SERVER then
				local primary = weapon.Primary
				local amount = math.min(math.max(0, primary.ClipSize - weapon:Clip1()), owner:GetAmmoCount(primary.Ammo))
				if amount > 0 then owner:RemoveAmmo(amount, primary.Ammo); weapon:SetClip1(weapon:Clip1() + amount) end
			end
			gm:CancelForgeReload(weapon)
		end
	end
end)

hook.Add("EntityRemoved", "ZSWeaponForgeReload", function(ent) GAMEMODE:CancelForgeReload(ent) end)
