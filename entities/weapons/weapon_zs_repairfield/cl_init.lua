include("shared.lua")
SWEP.Slot = 4
SWEP.DrawAmmo = false
local beam = Material("cable/blue_elec")
local glow = Color(100, 210, 235, 180)

function SWEP:DrawWorldModel()
	self.BaseClass.DrawWorldModel(self)
	if self:GetDTFloat(0) <= CurTime() then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	local start = owner:GetShootPos()
	render.SetMaterial(beam)
	render.DrawBeam(start, start + owner:GetAimVector() * self.RepairRadius, 3, 0, 1, glow)
end

function SWEP:DrawHUD()
	local width, height = ScrW(), ScrH()
	local style = ZSHUDStyle
	local scale = style.Scale()
	local charge, format = self:GetFieldCharge(), translate.Get("repairfield_hud")
	if charge ~= self.FieldHUDCharge or format ~= self.FieldHUDFormat then
		self.FieldHUDCharge, self.FieldHUDFormat = charge, format
		self.FieldHUDText = string.format(format, charge)
	end
	local owner = self:GetOwner()
	local ent = IsValid(owner) and owner:GetEyeTrace().Entity
	local fraction
	if IsValid(ent) and ent:IsNailed() then
		local position = owner:GetShootPos()
		if position:DistToSqr(ent:NearestPoint(position)) <= self.RepairRadius * self.RepairRadius then
			local maximum = ent:GetMaxBarricadeHealth()
			if maximum > 0 then fraction = math.Clamp(ent:GetBarricadeHealth() / maximum, 0, 1) end
		end
	end
	local cardWidth = math.min(310 * scale, width - 32 * scale)
	local cardX, cardY = width - 16 * scale - cardWidth, height * 0.2
	local textWidth = cardWidth - 24 * scale
	if self.FieldHUDDrawSource ~= self.FieldHUDText or self.FieldHUDDrawWidth ~= textWidth then
		self.FieldHUDDrawSource, self.FieldHUDDrawWidth = self.FieldHUDText, textWidth
		self.FieldHUDDrawText = style.Fit(self.FieldHUDText, "ZSHUDSmall", textWidth)
	end
	style.Card(cardX, cardY, cardWidth, (fraction and 76 or 34) * scale, glow, true)
	draw.SimpleText(self.FieldHUDDrawText, "ZSHUDSmall", cardX + 12 * scale, cardY + 10 * scale, style.Text)
	surface.SetDrawColor(100, 210, 235, 225)
	surface.DrawRect(width * 0.5 - scale, height * 0.5 - scale, 2 * scale, 2 * scale)
	if not fraction then return end
	local x, y = cardX + 12 * scale, cardY + 35 * scale
	surface.SetDrawColor(style.Track) surface.DrawRect(x, y, textWidth, 8 * scale)
	surface.SetDrawColor(100, 210, 235, 255) surface.DrawRect(x, y, textWidth * fraction, 8 * scale)
	local capacity, capacityFormat = math.floor(ent:GetBarricadeRepairs()), translate.Get("repairfield_capacity")
	if capacity ~= self.FieldHUDCapacity or capacityFormat ~= self.FieldHUDCapacityFormat then
		self.FieldHUDCapacity, self.FieldHUDCapacityFormat = capacity, capacityFormat
		self.FieldHUDCapacityText = string.format(capacityFormat, capacity)
	end
	if self.FieldHUDCapacityDrawSource ~= self.FieldHUDCapacityText or self.FieldHUDCapacityDrawWidth ~= textWidth then
		self.FieldHUDCapacityDrawSource, self.FieldHUDCapacityDrawWidth = self.FieldHUDCapacityText, textWidth
		self.FieldHUDCapacityDrawText = style.Fit(self.FieldHUDCapacityText, "ZSHUDSmall", textWidth)
	end
	draw.SimpleText(self.FieldHUDCapacityDrawText, "ZSHUDSmall", x, y + 17 * scale, style.Text)
end
