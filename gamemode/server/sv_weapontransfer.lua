local meta = FindMetaTable("Player")
if not meta then return end

local function Count(value)
	return type(value) == "number" and value >= 0 and value < math.huge and value == math.floor(value) and value or 0
end

local function AmmoName(value)
	return type(value) == "string" and value ~= "" and value ~= "none" and value or nil
end

local function Notify(channel, recipient, other, amount, ammotype)
	if recipient:IsBot() then return end
	net.Start(channel)
	net.WriteUInt(amount, 16)
	net.WriteString(ammotype)
	net.WriteEntity(other)
	net.Send(recipient)
end

local function Transfer(sender, weapon, recipient, withammo, class)
	local gm = GAMEMODE
	if (withammo or weapon.AmmoIfHas) and type(weapon.Primary) ~= "table" then return false, "ammo" end
	local level, crafter = gm:GetWeaponForgeLevel(weapon), weapon.ZSCrafter
	local received = recipient:Give(class, true)
	if not IsValid(received) or not received:IsWeapon() or received:GetOwner() ~= recipient or received:GetClass() ~= class then return false, "grant" end
	if not IsValid(weapon) or weapon:GetOwner() ~= sender or sender:GetWeapon(class) ~= weapon then
		received:Remove()
		return false, "changed"
	end
	if level > 0 then
		local ok, applied = pcall(gm.ApplyWeaponForge, gm, received, level)
		if not ok or not applied then received:Remove(); return false, "forge" end
		received:SetNWInt("ZSForgeLevel", level)
	end
	received.ZSCrafter = crafter
	local primary, secondary = AmmoName(weapon:ValidPrimaryAmmo()), AmmoName(weapon:ValidSecondaryAmmo())
	local clip, clip2 = Count(weapon:Clip1()), Count(weapon:Clip2())
	local amount = 0
	if primary and (withammo or weapon.AmmoIfHas) then
		local capacity = Count(gm.AmmoCache[primary])
		if capacity == 0 then capacity = math.max(1, Count(weapon.Primary.ClipSize)) end
		local reserves = Count(sender:GetAmmoCount(primary))
		amount = math.min(reserves + clip, 65535, math.ceil(capacity * (withammo and 5 or 1)))
		if amount > 0 then
			local fromreserves = math.min(reserves, amount)
			if fromreserves > 0 then sender:RemoveAmmo(fromreserves, primary) end
			clip = clip - (amount - fromreserves)
			recipient:GiveAmmo(amount, primary)
		end
	end
	if primary then
		if clip > 0 then sender:GiveAmmo(clip, primary, true) end
		weapon:SetClip1(0)
	end
	if secondary then
		if clip2 > 0 then sender:GiveAmmo(clip2, secondary, true) end
		weapon:SetClip2(0)
	end
	if AmmoName(received:ValidPrimaryAmmo()) then received:SetClip1(0) end
	if AmmoName(received:ValidSecondaryAmmo()) then received:SetClip2(0) end
	sender:StripWeapon(class)
	sender:UpdateAltSelectedWeapon()
	if amount > 0 then
		Notify("zs_ammogive", sender, recipient, amount, primary)
		Notify("zs_ammogiven", recipient, sender, amount, primary)
		sender:PlayGiveAmmoSound()
		sender:RestartGesture(ACT_GMOD_GESTURE_ITEM_GIVE)
	end
	return true, received
end

function meta:GiveWeaponByType(weapon, recipient, withammo)
	if not IsValid(self) or not self:IsPlayer() or not IsValid(recipient) or not recipient:IsPlayer() or recipient == self
		or not self:Alive() or not recipient:Alive() or self:Team() == TEAM_UNDEAD or recipient:Team() == TEAM_UNDEAD or GAMEMODE.ZombieEscape then return false, "player" end
	if not IsValid(weapon) or not weapon:IsWeapon() or weapon:GetOwner() ~= self or weapon:IsMarkedForDeletion() or weapon.NoTransfer then return false, "weapon" end
	local class = weapon:GetClass()
	if self:GetWeapon(class) ~= weapon or recipient:HasWeapon(class) then return false, "owned" end
	local senderbusy, recipientbusy = self.ZSWeaponTransferBusy, recipient.ZSWeaponTransferBusy
	if senderbusy or recipientbusy then return false, "busy" end
	self.ZSWeaponTransferBusy, recipient.ZSWeaponTransferBusy = true, true
	local ok, accepted, result = pcall(Transfer, self, weapon, recipient, withammo, class)
	self.ZSWeaponTransferBusy, recipient.ZSWeaponTransferBusy = senderbusy, recipientbusy
	if not ok then return false, "failed" end
	return accepted, result
end
