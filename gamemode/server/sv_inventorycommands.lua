local ERROR_SOUND = "surface.PlaySound(\"buttons/button10.wav\")"
local dropMins, dropMaxs = Vector(-2, -2, -2), Vector(2, 2, 2)

local function LockOnTarget(sender, arguments, ammo)
	local target = Entity(tonumbersafe(arguments[2] or 0) or 0)
	if GAMEMODE:ValidMenuLockOnTarget(sender, target) then return target end
	if ammo then return sender:MeleeTrace(48, 2, nil, nil, true).Entity end
	return sender:MeleeTrace(48, 2).Entity
end

local function AmmoNotice(channel, recipient, other, amount, ammotype)
	net.Start(channel)
	net.WriteUInt(amount, 16)
	net.WriteString(ammotype)
	net.WriteEntity(other)
	net.Send(recipient)
end

function GM:ConCommandErrorMessage(pl, message)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return end
	pl:CenterNotify(COLOR_RED, message)
	pl:SendLua(ERROR_SOUND)
end

concommand.Add("zsdropweapon", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	if GAMEMODE.ZombieEscape then return end

	if not (sender:IsValid() and sender:Alive() and sender:Team() ~= TEAM_UNDEAD) or CurTime() < (sender.NextWeaponDrop or 0) then return end
	sender.NextWeaponDrop = CurTime() + 0.15

	local currentwep = sender:GetActiveWeapon()
	if currentwep and currentwep:IsValid() then
		if string.StartWith(currentwep:GetClass(), "weapon_zs") then
			local ent = sender:DropWeaponByType(currentwep:GetClass())
			if ent and ent:IsValid() then
				local shootpos = sender:GetShootPos()
				local aimvec = sender:GetAimVector()
				ent:SetPos(util.TraceHull({start = shootpos, endpos = shootpos + aimvec * 32, mask = MASK_SOLID, filter = sender, mins = dropMins, maxs = dropMaxs}).HitPos)
				ent:SetAngles(sender:GetAngles())
			end
		end
	end
end)

concommand.Add("zsemptyclip", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	if GAMEMODE.ZombieEscape then return end

	if not (sender:IsValid() and sender:Alive() and sender:Team() ~= TEAM_UNDEAD) then return end

	sender.NextEmptyClip = sender.NextEmptyClip or 0
	if sender.NextEmptyClip <= CurTime() then
		sender.NextEmptyClip = CurTime() + 0.1

		local wep = sender:GetActiveWeapon()
		if wep:IsValid() and not wep.NoMagazine then
			local primary = wep:ValidPrimaryAmmo()
			if primary and 0 < wep:Clip1() then
				sender:GiveAmmo(wep:Clip1(), primary, true)
				wep:SetClip1(0)
			end
			local secondary = wep:ValidSecondaryAmmo()
			if secondary and 0 < wep:Clip2() then
				sender:GiveAmmo(wep:Clip2(), secondary, true)
				wep:SetClip2(0)
			end
		end
	end
end)

function GM:TryGetLockOnTrace(sender, arguments)
	return LockOnTarget(sender, arguments, true)
end

concommand.Add("zsgiveammo", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	if GAMEMODE.ZombieEscape then return end

	if not sender:IsValid() or not sender:Alive() or sender:Team() ~= TEAM_HUMAN then return end

	local ammotype = arguments[1]
	if not ammotype or #ammotype == 0 or not GAMEMODE.AmmoCache[ammotype] then return end

	local count = sender:GetAmmoCount(ammotype)
	if count <= 0 then
		GAMEMODE:ConCommandErrorMessage(sender, translate.ClientGet(sender, "no_spare_ammo_to_give"))
		return
	end

	local ent = GAMEMODE:TryGetLockOnTrace(sender, arguments)
	if ent and ent:IsValidLivingHuman() then
		local desiredgive = math.min(count, GAMEMODE.AmmoCache[ammotype])
		if desiredgive >= 1 then
			sender:RemoveAmmo(desiredgive, ammotype)
			ent:GiveAmmo(desiredgive, ammotype)

			if CurTime() >= (sender.NextGiveAmmoSound or 0) then
				sender.NextGiveAmmoSound = CurTime() + 1
				sender:PlayGiveAmmoSound()
			end

			sender:RestartGesture(ACT_GMOD_GESTURE_ITEM_GIVE)

			if not sender:IsBot() then AmmoNotice("zs_ammogive", sender, ent, desiredgive, ammotype) end
			if not ent:IsBot() then AmmoNotice("zs_ammogiven", ent, sender, desiredgive, ammotype) end

			return
		end
	else
		GAMEMODE:ConCommandErrorMessage(sender, translate.ClientGet(sender, "no_person_in_range"))
	end
end)

local function GiveWeapon(sender, arguments, withclip)
	if not IsValid(sender) or not sender:IsPlayer() or GAMEMODE.ZombieEscape or not sender:Alive() or sender:Team() == TEAM_UNDEAD then return end
	local weapon = sender:GetActiveWeapon()
	if not IsValid(weapon) then return end
	local recipient = LockOnTarget(sender, arguments, false)
	if IsValid(recipient) and recipient:IsPlayer() and recipient:Team() ~= TEAM_UNDEAD and recipient:Alive() then
		if not recipient:HasWeapon(weapon:GetClass()) then
			sender:GiveWeaponByType(weapon, recipient, withclip)
			return
		end
		if not sender:IsBot() then
			sender:SendLua(ERROR_SOUND)
			sender:PrintTranslatedMessage(HUD_PRINTCENTER, "person_has_weapon")
		end
	elseif not sender:IsBot() then
		sender:SendLua(ERROR_SOUND)
		sender:PrintTranslatedMessage(HUD_PRINTCENTER, "no_person_in_range")
	end
end

concommand.Add("zsgiveweapon", function(sender, command, arguments)
	GiveWeapon(sender, arguments, false)
end)

concommand.Add("zsgiveweaponclip", function(sender, command, arguments)
	GiveWeapon(sender, arguments, true)
end)

concommand.Add("zsdropammo", function(sender, command, arguments)
	if not IsValid(sender) or not sender:IsPlayer() then return end
	if GAMEMODE.ZombieEscape then return end

	if not sender:IsValid() or not sender:Alive() or sender:Team() ~= TEAM_HUMAN or CurTime() < (sender.NextDropClip or 0) then return end

	sender.NextDropClip = CurTime() + 0.2

	local wep = sender:GetActiveWeapon()
	if not wep:IsValid() then return end

	local ammotype = arguments[1] or wep:GetPrimaryAmmoTypeString()
	if GAMEMODE.AmmoNames[ammotype] and GAMEMODE.AmmoCache[ammotype] then
		local ent = sender:DropAmmoByType(ammotype, GAMEMODE.AmmoCache[ammotype] * 2)
		if ent and ent:IsValid() then
			ent:SetPos(sender:EyePos() + sender:GetAimVector() * 8)
			ent:SetAngles(sender:GetAngles())
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(sender:GetVelocity() * 0.85)
			end
		end
	end
end)

