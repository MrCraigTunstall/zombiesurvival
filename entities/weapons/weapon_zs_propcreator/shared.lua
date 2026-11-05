SWEP.Base = "weapon_zs_base"
SWEP.PrintName = translate.Get("propcreator_name")
SWEP.Description = translate.Get("propcreator_description")
SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.HoldType = "revolver"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 0.5
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.EmptyWhenPurchased = false

function SWEP:GetSelectedProp()
	local index = self:GetDTInt(0)
	return index > 0 and index or 1
end

function SWEP:GetRemainingProps()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return 0 end
	return math.max(0, 2 - (SERVER and GAMEMODE:GetPropCreatorUses(owner) or owner:GetNW2Int("zs_propcreator_used", 0)))
end

function SWEP:PrimaryAttack()
	if CurTime() < self:GetNextPrimaryFire() then return end
	self:SetNextPrimaryFire(CurTime() + 0.5)
	if SERVER then
		local owner = self:GetOwner()
		local ok, reason = GAMEMODE:CreatePropCreatorProp(owner, self, self:GetSelectedProp())
		if ok then
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			self:EmitSound("weapons/airboat/airboat_gun_lastshot1.wav", 60, 120)
		elseif IsValid(owner) and not owner:IsBot() then
			owner:CenterNotify(COLOR_RED, translate.ClientGet(owner, reason))
		end
	end
end

function SWEP:SecondaryAttack()
	if CurTime() < self:GetNextSecondaryFire() then return end
	self:SetNextSecondaryFire(CurTime() + 0.5)
	if SERVER then
		GAMEMODE:OpenPropCreator(self:GetOwner())
	end
end

function SWEP:Reload()
end
