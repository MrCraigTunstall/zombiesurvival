local style = ZSHUDStyle
local track = style.Track
local damageColor = style.Warning
local muted = style.Muted
local poisonColor = Color(205, 205, 65)
local bleedColor = Color(235, 80, 85)
local ghoulColor = Color(185, 120, 225)
local ghostColor = Color(100, 185, 255)
local classic = GetConVar("zs_classichud")
local captions, captionRevision = {}, -1
local captionKeys = {"health", "health_ghosting", "pl_poison", "pl_bleed", "pl_ghtc"}
local statusLabels = {}
local healthFonts = {"ZSHUDHealth", "ZSHUDNumber", "ZSHUDTitle", "ZSHUDSmall"}
local introPlayed = false
hook.Add("Think", "ZSIntroMusic", function()
	local lp = LocalPlayer()
	if introPlayed or not IsValid(lp) or not GAMEMODE or GAMEMODE:GetWave() < 1
	or GAMEMODE.ZombieEscape or lp:GetInfo("zs_intro") ~= "1" then return end
	introPlayed = true
	lp:EmitSound("zombiesurvival/zsrintrov2.mp3", 50, 100, 0.5)
end)

local function DrawStatus(label, amount, maximum, color, x, y, width, scale)
	if amount <= 0 then return y end
	draw.RoundedBox(4 * scale, x, y, width, 24 * scale, style.GlassSurface)
	surface.SetDrawColor(color)
	surface.DrawRect(x + 8 * scale, y + 8 * scale, 3 * scale, 8 * scale)
	local value = math.ceil(amount)
	local cached = statusLabels[label]
	if not cached or cached.width ~= width or cached.scale ~= scale or cached.value ~= value or cached.revision ~= captionRevision then
		surface.SetFont("ZSHUDLabel")
		local valueWidth = surface.GetTextSize(value)
		cached = {width = width, scale = scale, value = value, revision = captionRevision, text = style.Fit(captions[label], "ZSHUDSmall", math.max(0, width - 34 * scale - valueWidth))}
		statusLabels[label] = cached
	end
	draw.SimpleText(cached.text, "ZSHUDSmall", x + 18 * scale, y + 11 * scale, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(value, "ZSHUDLabel", x + width - 8 * scale, y + 11 * scale, style.Text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	surface.SetDrawColor(color)
	surface.DrawRect(x + 5 * scale, y + 22 * scale, (width - 10 * scale) * math.Clamp(amount / maximum, 0, 1), scale)
	return y + 29 * scale
end

local PANEL = {}
local function HealthWidths(scale, compact)
 local width = math.min(340 * scale, ScrW() * 0.48)
 local side = 200 * scale
 local right = GAMEMODE:GetHUDRightEdge()
 if compact and right < ScrW() and right < 800 then
  local legacy = BetterScreenScale()
  local available = right - math.floor(16 * scale) * 2 - 8 * scale - 96 * math.max(1, legacy) - 24 * legacy
  if width + side > available then
   side = 112 * scale
   width = math.min(width, math.max(160 * scale, available - side))
  end
 end
 return width, side, right
end

function PANEL:Init()
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	self:ParentToHUD()
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local scale = style.Scale()
	self.Scale = scale
	self.MeterWidth, self.StatusCardWidth, self.ViewportRight = HealthWidths(scale, self.CompactStatuses)
	self:SetSize(math.ceil(self.MeterWidth + (self.CompactStatuses and 8 * scale + self.StatusCardWidth or 0)), math.ceil((self.ContentHeight or 112) * scale))
	self:AlignLeft(math.floor(16 * scale))
	self:AlignBottom(math.floor(16 * scale))
	if IsValid(GAMEMODE.CenterNotificationHUD) then GAMEMODE.CenterNotificationHUD:InvalidateLayout() end
	if IsValid(GAMEMODE.TopNotificationHUD) then GAMEMODE.TopNotificationHUD:InvalidateLayout() end
end

function PANEL:Paint(width, height)
	local lp = LocalPlayer()
	if not IsValid(lp) or GAMEMODE.FilmMode or classic:GetBool() then return end
	local teamid = lp:Team()
	if teamid == TEAM_SPECTATOR then return end
	local revision = translate.GetRevision()
	if revision ~= captionRevision then
		captionRevision = revision
		for _, key in ipairs(captionKeys) do captions[key] = translate.Get(key) end
	end
	local scale = self.Scale or style.Scale()
	local health = math.max(0, lp:Health())
	local maximum = math.max(1, lp:GetMaxHealthEx())
	local fraction = math.Clamp(health / maximum, 0, 1)
	local classid = lp:GetZombieClass()
	local alive = lp:Alive()
	local ghosting = alive and lp:GetBarricadeGhosting() or false
	local now = CurTime()
	if self.HealthMaximum ~= maximum or not self.HealthMaximumText then self.HealthMaximumText = "/ " .. maximum end
	if self.HealthTeam ~= teamid or self.HealthClass ~= classid or self.HealthMaximum ~= maximum or self.HealthAlive ~= alive then
		self.HealthTeam, self.HealthClass, self.HealthMaximum = teamid, classid, maximum
		self.Trail = fraction
		self.TrailHold = now
	elseif fraction < (self.LastFraction or fraction) then
		self.TrailHold = now + 0.35
	end
	if fraction >= (self.Trail or fraction) or not alive then
		self.Trail = fraction
	elseif now >= (self.TrailHold or 0) then
		self.Trail = math.Approach(self.Trail, fraction, FrameTime() * 0.65)
	end
	self.LastFraction, self.HealthAlive = fraction, alive
	local healthColor = fraction <= 0.25 and style.Danger or fraction <= 0.5 and style.Warning or style.Accent
	width = self.MeterWidth or width
	local poison, bleed = lp:GetPoisonDamage(), lp:GetBleedDamage()
	local ghoul = lp:GetStatus("ghoultouch")
	local ghoulTime = IsValid(ghoul) and math.max(0, (ghoul.DieTime or 0) - now) or 0
	local class = lp:GetZombieClassTable()
	local shade = alive and teamid == TEAM_UNDEAD and class and class.SWEP == "weapon_zs_shade"
	local compact = not shade and ScrH() <= 600 and ScrW() >= 640 and (poison > 0 or bleed > 0 or ghoulTime > 0)
	if (self.CompactStatuses or false) ~= compact or self.ViewportRight ~= GAMEMODE:GetHUDRightEdge() then
		self.CompactStatuses = compact
		self:InvalidateLayout(true)
		width = self.MeterWidth
	end
	local inset, barwidth = 16 * scale, width - 32 * scale
	if self.NumberHealth ~= health or self.NumberWidth ~= width or self.NumberScale ~= scale or self.NumberMaximum ~= maximum then
		self.NumberHealth, self.NumberWidth, self.NumberMaximum, self.NumberScale = health, width, maximum, scale
		surface.SetFont("ZSHUDLabel")
		local maximumWidth = surface.GetTextSize(self.HealthMaximumText)
		local available = math.max(0, barwidth - maximumWidth - 12 * scale)
		self.HealthFont = "ZSHUDHealth"
		for _, font in ipairs(healthFonts) do
			self.HealthFont = font
			surface.SetFont(font)
			if surface.GetTextSize(health) <= available then break end
		end
		self.HealthValueWidth = surface.GetTextSize(health)
		self.StackMaximum = self.HealthValueWidth > available
	end
	style.Card(0, 0, width, height, healthColor, true)
	draw.RoundedBox(6 * scale, inset, 16 * scale, 25 * scale, 25 * scale, style.GlassSurface)
	surface.SetDrawColor(ghosting and ghostColor or healthColor)
	surface.DrawRect(inset + 7 * scale, 27 * scale, 11 * scale, 3 * scale)
	surface.DrawRect(inset + 11 * scale, 23 * scale, 3 * scale, 11 * scale)
	if self.CaptionWidth ~= width or self.CaptionScale ~= scale or self.CaptionRevision ~= revision or self.CaptionGhosting ~= ghosting then
		self.CaptionWidth, self.CaptionRevision, self.CaptionGhosting, self.CaptionScale = width, revision, ghosting, scale
		self.HealthCaption = style.Fit(ghosting and captions.health_ghosting or captions.health, "ZSHUDLabel", math.max(0, barwidth - 34 * scale))
	end
	draw.SimpleText(self.HealthCaption, "ZSHUDLabel", inset + 34 * scale, 28 * scale, ghosting and ghostColor or muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(health, self.HealthFont, inset - 1, (self.StackMaximum and 57 or 69) * scale, style.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(self.HealthMaximumText, "ZSHUDLabel", self.StackMaximum and width - inset or inset + self.HealthValueWidth + 8 * scale, (self.StackMaximum and 79 or 76) * scale, muted, self.StackMaximum and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	surface.SetDrawColor(track)
	surface.DrawRect(inset, 91 * scale, barwidth, 10 * scale)
	surface.SetDrawColor(damageColor)
	surface.DrawRect(inset, 91 * scale, barwidth * self.Trail, 10 * scale)
	surface.SetDrawColor(healthColor)
	surface.DrawRect(inset, 91 * scale, barwidth * fraction, 10 * scale)
	surface.SetDrawColor(style.Background)
	for index = 1, 9 do surface.DrawRect(inset + barwidth * index * 0.1, 91 * scale, math.max(1, scale), 10 * scale) end
	local statusX, statusY, statusWidth = inset, 112 * scale, barwidth
	if compact then
		style.Card(width + 8 * scale, 0, self.StatusCardWidth, 112 * scale, nil, true)
		statusX, statusY, statusWidth = width + 20 * scale, 15 * scale, self.StatusCardWidth - 24 * scale
	end
	local y = DrawStatus("pl_poison", poison, 50, poisonColor, statusX, statusY, statusWidth, scale)
	y = DrawStatus("pl_bleed", bleed, 20, bleedColor, statusX, y, statusWidth, scale)
	y = DrawStatus("pl_ghtc", ghoulTime, 10, ghoulColor, statusX, y, statusWidth, scale)
	local contentHeight = compact and 112 or shade and math.ceil(y / scale - 0.0001) + 66 or y > 112 * scale + 0.0001 and math.ceil(y / scale - 0.0001) + 3 or 112
	if contentHeight ~= (self.ContentHeight or 112) then
		self.ContentHeight = contentHeight
		self:InvalidateLayout(true)
		return
	end
	if shade then GAMEMODE:DrawShadeHUD(lp, 0, y, width, scale) end
end

vgui.Register("ZSHealthArea", PANEL, "Panel")

hook.Add("OnScreenSizeChanged", "ZSHealthHUDLayout", function()
	if IsValid(GAMEMODE.HealthHUD) then GAMEMODE.HealthHUD:InvalidateLayout(true) end
end)

local colHealth = Color(0, 130, 0, 240)
local colPoison = Color(220, 220, 0, 240)
function GM:DrawHealthBar(x, y, health, maxhealth, bartexture, screenscale, poisondamage)
 local pl = MySelf
 if not IsValid(pl) then return end
 health = math.max(0, health)
 screenscale = BetterScreenScale()
 local healthfrac = math.min(1, health / math.max(1, maxhealth))
 colHealth.g = 130 * healthfrac
 colHealth.r = 130 - colHealth.g
 if health > 0 then
  local barx, bary = x + screenscale * 72, y + screenscale * 99
  local maxbarwidth = screenscale * 405
  local barwidth = maxbarwidth * healthfrac
  surface.SetDrawColor(colHealth)
  surface.DrawRect(barx, bary, barwidth, screenscale * 26)
  if poisondamage and poisondamage > 0 and barwidth < maxbarwidth then
   surface.SetDrawColor(colPoison)
   surface.DrawRect(barx + barwidth, bary, math.min(maxbarwidth * poisondamage / math.max(1, maxhealth), maxbarwidth - barwidth), screenscale * 16)
  end
 end
 surface.SetTexture(bartexture)
 surface.SetDrawColor(150, 150, 150, 240)
 surface.DrawTexturedRect(x, y, 512 * screenscale, 256 * screenscale)
 draw.SimpleText(translate.Get("health"), "ZSHUDFontSmall", x + screenscale * 70, y + screenscale * 55, COLOR_GRAY, TEXT_ALIGN_LEFT)
 draw.SimpleText(health, "ZSHUDFont", x + screenscale * 180, y + screenscale * 48, colHealth, TEXT_ALIGN_LEFT)
 if pl:Team() ~= TEAM_UNDEAD then
  local points = pl:GetPoints()
  draw.SimpleText(translate.Format("points_x", points.." / "..pl:Frags().." / "..points.." + "), "ZSHUDFontSmallNS", x + screenscale * 70, y + screenscale * 133, COLOR_GRAY, TEXT_ALIGN_LEFT)
 else
  draw.SimpleText(translate.Format("brains_eaten_x", pl:Frags()), "ZSHUDFontSmallNS", x + screenscale * 70, y + screenscale * 133, COLOR_GRAY, TEXT_ALIGN_LEFT)
 end
 local wave, active = GAMEMODE:GetWave(), GAMEMODE:GetWaveActive()
 local drawTimer = not IsValid(self.GameStatePanel) or not self.GameStatePanel:IsVisible()
 if wave > 0 and wave < 7 then
  draw.SimpleText(wave, "ZSHUDFontSmallNS", x + screenscale * 475, y + screenscale * 133, COLOR_GRAY, TEXT_ALIGN_CENTER)
  draw.SimpleText(translate.Get("wave"), "ZSHUDFontSmallNS", x + screenscale * 430, y + screenscale * 133, COLOR_GRAY, TEXT_ALIGN_CENTER)
  if not active then
   local timeleft = drawTimer and math.max(0, GAMEMODE:GetWaveStart() - CurTime()) or 0
   draw.SimpleText(translate.Get("wave_intermission"), "ZSHUDFontSmallNS", x + screenscale * 70, y + screenscale * 23, COLOR_YELLOW, TEXT_ALIGN_LEFT)
   if drawTimer then
    draw.SimpleText(util.ToMinutesSeconds(timeleft), "ZSHUDFontSmallNS", x + screenscale * 320, y + screenscale * 25, 10 < timeleft and COLOR_YELLOW or Color(255, 0, 0, math.abs(math.sin(RealTime() * 8)) * 180 + 40), TEXT_ALIGN_LEFT)
   end
  end
 end
 if active and drawTimer then
  local waveend = GAMEMODE:GetWaveEnd()
  if waveend ~= -1 then
   local timeleft = math.max(0, waveend - CurTime())
   draw.SimpleText(util.ToMinutesSeconds(timeleft), "ZSHUDFontSmallNS", x + screenscale * 483, y + screenscale * 60, 10 < timeleft and COLOR_GRAY or Color(255, 0, 0, math.abs(math.sin(RealTime() * 8)) * 180 + 40), TEXT_ALIGN_RIGHT)
  end
 end
 self:DrawShadeHUD(pl, x + 70 * screenscale, y + 180 * screenscale, 405 * screenscale, screenscale)
end
