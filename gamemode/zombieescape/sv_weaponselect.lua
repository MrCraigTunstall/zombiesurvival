util.AddNetworkString("zs_zeweapon_result")
local requests = setmetatable({}, {__mode = "k"})

local function ClearAmmoOverflow(pl)
	pl.ZEWeaponAmmoOverflow = nil
end

hook.Add("PlayerSpawn", "ZSZEAmmoOverflow", ClearAmmoOverflow)
hook.Add("PlayerDeath", "ZSZEAmmoOverflow", ClearAmmoOverflow)
hook.Add("PlayerSilentDeath", "ZSZEAmmoOverflow", ClearAmmoOverflow)
hook.Add("PlayerChangedTeam", "ZSZEAmmoOverflow", ClearAmmoOverflow)
hook.Add("PlayerAmmoChanged", "ZSZEAmmoOverflow", function(pl, ammo, oldCount, newCount)
	local overflow = pl.ZEWeaponAmmoOverflow
	if not overflow or overflow.busy or overflow.ammo ~= ammo or newCount >= oldCount then return end
	if not IsValid(overflow.weapon) or overflow.weapon:GetOwner() ~= pl then
		pl.ZEWeaponAmmoOverflow = nil
		return
	end
	overflow.busy = true
	local given = pl:GiveAmmo(overflow.amount, ammo, true)
	overflow.amount = math.max(0, overflow.amount - given)
	overflow.busy = nil
	if overflow.amount == 0 then pl.ZEWeaponAmmoOverflow = nil end
end)

function GM:IsZombieEscapeWeapon(class)
	if type(class) ~= "string" or #class > 64 then return false end
	for _, allowed in ipairs(self.ZombieEscapeWeapons) do
		if class == allowed then return weapons.GetStored(class) ~= nil end
	end
	return false
end

function GM:GetZombieEscapeWeapon(pl)
	local preference = pl.ZEWeaponPreference or pl:GetInfo("zs_zeweapon")
	if self:IsZombieEscapeWeapon(preference) then return preference end
	return self.ZombieEscapeWeapons[math.random(#self.ZombieEscapeWeapons)]
end

function GM:SelectZombieEscapeWeapon(pl, class)
	if not IsValid(pl) or not pl:IsPlayer() or not self.ZombieEscape or pl:Team() ~= TEAM_HUMAN then
		return false, "ze_weapon_unavailable"
	end
	if not self:IsZombieEscapeWeapon(class) then return false, "ze_weapon_invalid" end
	if (pl.ZEWeaponNextChoice or 0) > CurTime() then return false, "ze_weapon_wait" end
	pl.ZEWeaponNextChoice = CurTime() + 0.5
	if not pl:Alive() or self:GetWave() ~= 0 or self:GetWaveActive() then
		pl.ZEWeaponPreference = class
		return true, "ze_weapon_next_spawn"
	end
	local oldClass = pl.ZEPrimaryWeapon
	local old = oldClass and pl:GetWeapon(oldClass)
	if not IsValid(old) then return false, "ze_weapon_unavailable" end
	if class == oldClass then
		pl.ZEWeaponPreference = class
		return true, "ze_weapon_selected"
	end
	if pl.ZEWeaponChoiceUsed then return false, "ze_weapon_locked" end
	local definition = weapons.Get(class)
	if not definition or not definition.Primary or type(definition.Primary.Ammo) ~= "string" then return false, "ze_weapon_invalid" end
	local oldAmmo = old:GetPrimaryAmmoType()
	local newAmmo = game.GetAmmoID(definition.Primary.Ammo or "")
	if oldAmmo < 0 or newAmmo < 0 then return false, "ze_weapon_invalid" end
	local total = math.max(0, old:Clip1()) + pl:GetAmmoCount(oldAmmo)
	local reserve = oldAmmo == newAmmo and 0 or pl:GetAmmoCount(newAmmo)
	pl.ZEWeaponChoiceUsed = true
	local replacement = pl:Give(class)
	if not IsValid(replacement) then
		pl.ZEWeaponChoiceUsed = false
		return false, "ze_weapon_unavailable"
	end
	local clip = math.min(math.max(0, replacement:GetMaxClip1()), total)
	replacement:SetClip1(clip)
	local desired = reserve + total - clip
	pl:SetAmmo(desired, newAmmo)
	local overflow = desired - pl:GetAmmoCount(newAmmo)
	if overflow > 0 then
		pl.ZEWeaponAmmoOverflow = {weapon = replacement, ammo = newAmmo, amount = overflow}
	end
	if oldAmmo ~= newAmmo then pl:SetAmmo(0, oldAmmo) end
	pl:StripWeapon(oldClass)
	pl.ZEPrimaryWeapon = class
	pl.ZEWeaponPreference = class
	pl:SelectWeapon(class)
	return true, "ze_weapon_selected"
end

concommand.Add("zs_zeweapon_select", function(pl, _, args)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	local now = SysTime()
	if now < (requests[pl] or 0) then return end
	requests[pl] = now + 0.25
	local ok, reason = GAMEMODE:SelectZombieEscapeWeapon(pl, args[1])
	if not IsValid(pl) or pl:IsBot() then return end
	net.Start("zs_zeweapon_result")
	net.WriteBool(ok)
	net.WriteString(reason)
	net.WriteString(ok and args[1] or "")
	net.Send(pl)
end)
