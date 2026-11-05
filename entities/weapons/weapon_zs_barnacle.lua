AddCSLuaFile()
SWEP.Base = "weapon_zs_basemelee"
SWEP.PrintName = "Barnacle Cultivator"
SWEP.Description = "Grow an allied barnacle on a ceiling. Two per survivor; one placement every 30 seconds."
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.UseHands = true
SWEP.HoldType = "grenade"
SWEP.IsMelee = false
SWEP.NoWeaponForge = true
SWEP.WalkSpeed = SPEED_FAST
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 30
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
local failures = {
	ceiling = "Aim at a ceiling within reach.",
	blocked = "The barnacle needs more room beneath this ceiling.",
	clearance = "The barnacle needs a clear drop for its tongue.",
	cooldown = "Your barnacle is still growing. Wait for the cooldown.",
	limit = "The barnacle limit has been reached.",
	unavailable = "You cannot grow a barnacle right now.",
	failed = "The barnacle could not be grown. Try again."
}
function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if SERVER then
		local owner = self:GetOwner()
		local ok, reason = GAMEMODE:PlaceTraitBarnacle(owner, self)
		if not ok then
			self:SetNextPrimaryFire(CurTime() + 0.25)
			if IsValid(owner) and not owner:IsBot() then owner:CenterNotify(COLOR_RED, failures[reason] or failures.failed) end
			return
		end
		self:SendWeaponAnim(ACT_VM_THROW)
		self:GetOwner():DoAttackEvent()
		self:EmitSound("WeaponFrag.Throw")
	end
end
function SWEP:SecondaryAttack() end
