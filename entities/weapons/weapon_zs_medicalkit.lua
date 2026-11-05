SWEP.PrintNameTranslation = "worth_medkit"
SWEP.DescriptionTranslation = "medkit_desk"
AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = translate.Get("worth_medkit")
	SWEP.TranslatedPrintName = SWEP.PrintName
	SWEP.Description = translate.Get("medkit_desk")
	SWEP.TranslatedDescription = SWEP.Description
	SWEP.Slot = 4
	SWEP.SlotPos = 0

	SWEP.ViewModelFOV = 50
	SWEP.ViewModelFlip = false

	SWEP.BobScale = 2
	SWEP.SwayScale = 1.5
end

SWEP.Base = "weapon_zs_base"

SWEP.WorldModel = "models/weapons/w_medkit.mdl"
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.UseHands = true

SWEP.DefaultHealMultiplier = 1
SWEP.EmptyChargeDelay = 0.75

SWEP.Primary.Delay = 10
SWEP.Primary.Heal = 15

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 150
SWEP.Primary.Ammo = "Battery"

SWEP.Secondary.Delay = 20
SWEP.Secondary.Heal = 10

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = "none"

SWEP.WalkSpeed = SPEED_NORMAL

SWEP.NoMagazine = true

SWEP.HoldType = "slam"

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	self:SetDeploySpeed(1.1)
end

function SWEP:Think()
	if self.IdleAnimation and self.IdleAnimation <= CurTime() then
		self.IdleAnimation = nil
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self.Owner

	owner:LagCompensation(true)
	local ent = owner:MeleeTrace(32, 2).Entity
	owner:LagCompensation(false)

	if ent and ent:IsValid() and ent:IsPlayer() and ent:Team() == owner:Team() and ent:Alive() and gamemode.Call("PlayerCanBeHealed", ent) then
		local health, maxhealth = ent:Health(), ent:GetMaxHealth()
		local multiplier = owner.HumanHealMultiplier or self.DefaultHealMultiplier
		local toheal = math.min(self:GetPrimaryAmmoCount(), math.ceil(math.min(self.Primary.Heal * multiplier, maxhealth - health)))
		local totake = math.ceil(toheal / multiplier)
		if toheal > 0 then
			self:SetNextCharge(CurTime() + self.Primary.Delay * math.min(1, toheal / self.Primary.Heal))
			owner.NextMedKitUse = self:GetNextCharge()

			self:TakeCombinedPrimaryAmmo(totake)

			ent:SetHealth(health + toheal)
			self:EmitSound("items/medshot4.wav")

			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

			owner:DoAttackEvent()
			self.IdleAnimation = CurTime() + self:SequenceDuration()

			gamemode.Call("PlayerHealedTeamMember", owner, ent, toheal, self)
		end
	end
end

function SWEP:SecondaryAttack()
	local owner = self.Owner
	if not self:CanPrimaryAttack() or not gamemode.Call("PlayerCanBeHealed", owner) then return end

	local health, maxhealth = owner:Health(), owner:GetMaxHealth()
	local multiplier = owner.HumanHealMultiplier or self.DefaultHealMultiplier
	local toheal = math.min(self:GetPrimaryAmmoCount(), math.ceil(math.min(self.Secondary.Heal * multiplier, maxhealth - health)))
	local totake = math.ceil(toheal / multiplier)
	if toheal > 0 then
		self:SetNextCharge(CurTime() + self.Secondary.Delay * math.min(1, toheal / self.Secondary.Heal))
		owner.NextMedKitUse = self:GetNextCharge()

		self:TakeCombinedPrimaryAmmo(totake)

		owner:SetHealth(health + toheal)
		self:EmitSound("items/smallmedkit1.wav")

		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		owner:DoAttackEvent()
		self.IdleAnimation = CurTime() + self:SequenceDuration()
	end
end

function SWEP:Deploy()
	gamemode.Call("WeaponDeployed", self.Owner, self)

	local sharedCharge = self.Owner.NextMedKitUse or 0
	if sharedCharge > CurTime() and sharedCharge > self:GetNextCharge() then self:SetNextCharge(sharedCharge) end

	self.IdleAnimation = CurTime() + self:SequenceDuration()

	if CLIENT then
		hook.Add("PostPlayerDraw", "PostPlayerDrawMedical", GAMEMODE.PostPlayerDrawMedical)
		GAMEMODE.MedicalAura = true
	end

	return true
end

function SWEP:Holster()
	if CLIENT then
		hook.Remove("PostPlayerDraw", "PostPlayerDrawMedical")
		GAMEMODE.MedicalAura = false
	end

	return true
end

function SWEP:OnRemove()
	if CLIENT and self.Owner == LocalPlayer() then
		hook.Remove("PostPlayerDraw", "PostPlayerDrawMedical")
		GAMEMODE.MedicalAura = false
	end
end

function SWEP:Reload()
end

function SWEP:SetNextCharge(tim)
	self:SetDTFloat(0, tim)
end

function SWEP:GetNextCharge()
	return self:GetDTFloat(0)
end

function SWEP:CanPrimaryAttack()
	local owner = self.Owner
	if owner:IsHolding() or owner:GetBarricadeGhosting() then return false end

	local now = CurTime()
	if self:GetNextCharge() > now or (owner.NextMedKitUse or 0) > now then return false end

	if self:GetPrimaryAmmoCount() <= 0 then
		self:EmitSound("items/medshotno1.wav")

		self:SetNextCharge(now + self.EmptyChargeDelay)
		owner.NextMedKitUse = self:GetNextCharge()
		return false
	end

	return true
end

if not CLIENT then return end

function SWEP:DrawWeaponSelection(...)
	return self:BaseDrawWeaponSelection(...)
end

local style = ZSHUDStyle
local crosshair = GetConVar("crosshair")
local layout, captions = {}, {}
local revision = -1
local lastCharge, chargeText, lastTime, timeText

function SWEP:DrawHUD()
 local screenWidth, screenHeight = ScrW(), ScrH()
 local right = GAMEMODE:GetHUDRightEdge()
 if layout.screenWidth ~= screenWidth or layout.screenHeight ~= screenHeight or layout.right ~= right then
  local scale = style.Scale()
  layout.screenWidth, layout.screenHeight, layout.right, layout.scale = screenWidth, screenHeight, right, scale
  layout.width = math.min(300 * scale, math.max(0, right * 0.45 - 16 * scale))
  layout.height = 72 * scale
  layout.x, layout.y = right - layout.width - 16 * scale, screenHeight - 160 * scale
  captions = {}
 end
 local currentRevision = translate.GetRevision()
 if revision ~= currentRevision then revision = currentRevision captions = {} end
 local scale, width = layout.scale, layout.width
 if width >= 128 * scale then
  local x, y, pad = layout.x, layout.y, 14 * scale
  local color = self.MedicalHUDColor or style.Accent
  local key = self.MedicalHUDLabel or "medkit_text"
  local caption = captions[key]
  if not caption then caption = style.Fit(translate.Get(key), "ZSHUDTitle", math.max(0, width - 100 * scale))captions[key] = caption end
  local charges = self:GetPrimaryAmmoCount()
  if lastCharge ~= charges then lastCharge, chargeText = charges, tostring(charges) end
  local owner = self:GetOwner()
  local sharedCharge = IsValid(owner) and owner.NextMedKitUse or 0
  local remaining = math.max(0, math.max(self:GetNextCharge(), sharedCharge or 0) - CurTime())
  local bucket = math.ceil(remaining * 10)
  if lastTime ~= bucket then lastTime = bucket timeText = bucket > 0 and string.format("%.1fs", bucket / 10) or nil end
  style.Card(x, y, width, layout.height, color, true)
  draw.SimpleText(caption, "ZSHUDTitle", x + pad, y + 21 * scale, style.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  draw.SimpleText(chargeText, "ZSHUDNumber", x + width - pad, y + 21 * scale, charges > 0 and color or style.Danger, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
  if timeText then draw.SimpleText(timeText, "ZSHUDSmall", x + width - pad, y + 43 * scale, style.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)end
  local trackWidth = width - pad * 2
  surface.SetDrawColor(style.Track)
  surface.DrawRect(x + pad, y + 56 * scale, trackWidth, 5 * scale)
  surface.SetDrawColor(charges > 0 and color or style.Danger)
  surface.DrawRect(x + pad, y + 56 * scale, trackWidth * (1 - math.Clamp(remaining / math.max(1, self.Primary.Delay, self.Secondary.Delay), 0, 1)), 5 * scale)
 end
 if crosshair:GetBool() then self:DrawCrosshairDot() end
end
