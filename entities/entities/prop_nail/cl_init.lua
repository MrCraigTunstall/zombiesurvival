INC_CLIENT()

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

surface.CreateFont("ZSNailInspector", {font = "Roboto", size = 20, weight = 600, antialias = true, extended = true})
surface.CreateFont("ZSNailInspectorHealth", {font = "Roboto", size = 24, weight = 700, antialias = true, extended = true})
surface.CreateFont("ZSNailInspectorSmall", {font = "Roboto", size = 14, weight = 500, antialias = true, extended = true})

local removalFrame, removalAttempts, removalSounds, removalEmitters = -1, 0, 0, 0
local removalGravity = Vector(0, 0, -300)
local inspectionFrame, inspectionObserver, inspectionHit = -1

local function InspectNail(nail)
	local observer = MySelf
	if not IsValid(observer) or observer:Team() == TEAM_UNDEAD then return false end
	if GAMEMODE.AlwaysShowNails or observer:KeyDown(IN_SPEED) then return true end
	local frame = FrameNumber()
	if frame ~= inspectionFrame or observer ~= inspectionObserver then
		inspectionFrame, inspectionObserver = frame, observer
		inspectionHit = observer:TraceLine(256, MASK_SHOT).HitPos
	end
	return inspectionHit:DistToSqr(nail:GetPos()) <= 256
end

function ENT:OnRemove(fullUpdate)
	local observer = MySelf
	if fullUpdate or self:IsDormant() or not IsValid(observer) then return end
	local frame = FrameNumber()
	if removalFrame ~= frame then removalFrame, removalAttempts, removalSounds, removalEmitters = frame, 0, 0, 0 end
	if removalSounds >= 4 and (removalEmitters >= 8 or removalAttempts >= 64) then return end
	if observer:GetPos():DistToSqr(self:GetPos()) > 262144 then return end
	local normal = self:GetForward() * -1
	local pos = self:GetPos() + normal

	if removalSounds < 4 then
		removalSounds = removalSounds + 1
		sound.Play("physics/metal/metal_box_impact_bullet"..math.random(1, 3)..".wav", pos, 75, math.random(90, 110))
	end
	if removalAttempts >= 64 or removalEmitters >= 8 then return end

	removalEmitters = removalEmitters + 1
	local emitter = ParticleEmitter(pos)
	if not emitter then return end
	emitter:SetNearClip(22, 32)
	for i=1, math.min(math.random(8, 12), 64 - removalAttempts) do
		removalAttempts = removalAttempts + 1
		local vNormal = (VectorRand() * 0.6 + normal):GetNormalized()
		local particle = emitter:Add("effects/spark", pos + vNormal)
		if particle then
			particle:SetVelocity(vNormal * math.Rand(16, 100))
			particle:SetDieTime(math.Rand(0.5, 1))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)
			particle:SetStartSize(math.Rand(0.4, 1.5))
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(math.Rand(-8, 8))
			particle:SetCollide(false)
			particle:SetGravity(removalGravity)
		end
	end
	emitter:Finish()
end

local matOutlineWhite = Material("white_outline")
local ScaleOutline = 1.4
local colNail = Color(0, 0, 5, 220)
function ENT:DrawTranslucent()
	local drawowner = InspectNail(self)
	local maximum, current, repairs, maxrepairs, health

	if drawowner then
		render.SuppressEngineLighting(true)
		render.SetAmbientLight(1, 1, 1)

		maximum, current = self:GetMaxNailHealth(), self:GetNailHealth()
		repairs, maxrepairs = self:GetRepairs(), self:GetMaxRepairs()
		health = maximum > 0 and math.Clamp(current / maximum, 0, 1) or 0
		if health ~= health then health = 0 end
		render.SetColorModulation(1 - health, health, 0)

		local scale = self:GetModelScale()
		self:SetModelScale(ScaleOutline * scale, 0)
		render.ModelMaterialOverride(matOutlineWhite)

		self:DrawModel()

		render.ModelMaterialOverride()
		self:SetModelScale(scale, 0)

		render.SuppressEngineLighting(false)
		render.SetColorModulation(1, 1, 1)
	end

	self:DrawModel()

	if drawowner then
		local displayowner = self:GetDTString(0)
		local redname = false
		if displayowner == "" then
			displayowner = nil

			local deployer = self:GetOwner()
			if deployer:IsValid() then
				displayowner = deployer:Name()
				if deployer:Team() == TEAM_UNDEAD or not deployer:Alive() then
					displayowner = "(DEAD) "..displayowner
					redname = true
				end
			end
		end

		local ang = EyeAngles()
		ang:RotateAroundAxis(ang:Up(), -90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		local position = self:GetPos()
		local scale = math.Clamp(EyePos():Distance(position) * 0.00125, 0.025, 0.32)
		if self.ZSNailDisplayOwner ~= displayowner then
			self.ZSNailDisplayOwner = displayowner
			surface.SetFont("ZSNailInspector")
			self.ZSNailDisplayWidth = math.max(220, displayowner and surface.GetTextSize(displayowner) + 24 or 220)
		end
		local width = self.ZSNailDisplayWidth or 220
		local x, top = width * -0.5, 14
		local green = health * 185
		colNail.r, colNail.g, colNail.b = 235 - green, 85 + green * 0.9, 100 + green * 0.35
		cam.Start3D2D(position, ang, scale)
			surface.SetDrawColor(9, 16, 23, 205)
			surface.DrawRect(x, top, width, 99)
			surface.SetDrawColor(128, 151, 169, 65)
			surface.DrawOutlinedRect(x, top, width, 99)
			surface.SetDrawColor(colNail)
			surface.DrawRect(x, top, 2, 99)
			if displayowner then
				draw.SimpleText(displayowner, "ZSNailInspector", 0, top + 8, redname and COLOR_DARKRED or COLOR_GRAY, TEXT_ALIGN_CENTER)
			end
			if maximum > 0 then
				local rounded, roundedmax = math.ceil(current), math.ceil(maximum)
				if rounded ~= self.ZSNailDisplayHealth or roundedmax ~= self.ZSNailDisplayMaximum then
					self.ZSNailDisplayHealth, self.ZSNailDisplayMaximum = rounded, roundedmax
					self.ZSNailDisplayText = rounded.." / "..roundedmax
				end
				draw.SimpleText(self.ZSNailDisplayText, "ZSNailInspectorHealth", 0, top + 34, colNail, TEXT_ALIGN_CENTER)
				surface.SetDrawColor(255, 255, 255, 24)
				surface.DrawRect(x + 12, top + 63, width - 24, 5)
				surface.SetDrawColor(colNail)
				surface.DrawRect(x + 12, top + 63, (width - 24) * health, 5)
			end
			if maxrepairs > 0 then
				local rounded, revision = math.ceil(repairs), translate.GetRevision()
				if rounded ~= self.ZSNailDisplayRepairs or revision ~= self.ZSNailDisplayLanguage then
					self.ZSNailDisplayRepairs, self.ZSNailDisplayLanguage = rounded, revision
					self.ZSNailDisplayRepairText = translate.Format("repairfield_capacity", rounded)
				end
				draw.SimpleText(self.ZSNailDisplayRepairText, "ZSNailInspectorSmall", 0, top + 76, repairs > 0 and COLOR_GRAY or COLOR_DARKRED, TEXT_ALIGN_CENTER)
				surface.SetDrawColor(255, 255, 255, 20)
				surface.DrawRect(x + 12, top + 94, width - 24, 2)
				surface.SetDrawColor(168, 187, 203, 160)
				surface.DrawRect(x + 12, top + 94, (width - 24) * math.Clamp(repairs / maxrepairs, 0, 1), 2)
			end
		cam.End3D2D()
	end
end
