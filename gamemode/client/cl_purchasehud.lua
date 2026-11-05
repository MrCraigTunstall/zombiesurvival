local style = ZSHUDStyle

function GM:BuildPurchaseHUD()
	local pl = MySelf
	if self.RoundEnded or self.FilmMode or not IsValid(pl) or pl:Team() ~= TEAM_HUMAN or not self.GetEffectiveZSKey then self.PurchaseHUDData = nil return end
	local escape, wave, active = self.ZombieEscape, self:GetWave(), self:GetWaveActive()
	if escape and self.BuildZombieEscapeBossHUD and #self:BuildZombieEscapeBossHUD() > 0 then self.PurchaseHUDData = nil return end
	local now = RealTime()
	local cache = self.PurchaseHUDCache
	if not cache then cache = {} self.PurchaseHUDCache = cache end
	local target, discount
	if escape then target = "ze_weapon_menu"
	elseif wave <= 0 then
		if not pl:Alive() then self.PurchaseHUDData = nil return end
		target = "hud_shop_loadout"
	else
		local alive = pl:Alive()
		if cache.player ~= pl or cache.wave ~= wave or cache.alive ~= alive or now >= (cache.nextPermission or 0) then
			cache.player, cache.wave, cache.alive = pl, wave, alive
			cache.allowed = gamemode.Call("PlayerCanPurchase", pl)
			cache.nextPermission = now + 0.2
		end
		if not cache.allowed then self.PurchaseHUDData = nil return end
		target = "the_pointshop"
		if not active then discount = self.ArsenalCrateDiscountPercentage end
	end
	local binding = self:GetZSKeyBinding("shop")
	if cache.binding ~= binding or now >= (cache.nextKey or 0) then
		cache.binding, cache.code, cache.nextKey = binding, self:GetEffectiveZSKey("shop"), now + 0.25
	end
	local code = cache.code
	if not code or code <= 0 then self.PurchaseHUDData = nil return end
	local width, height, scale, revision = ScrW(), ScrH(), style.Scale(), translate.GetRevision()
	local factor = scale / 1.2
	local margin, gap, padding = math.floor(8 * factor + 0.5), math.floor(8 * factor + 0.5), math.floor(6 * factor + 0.5)
	local left = margin
	if IsValid(self.GameStatePanel) then local x = self.GameStatePanel:GetPos() left = math.max(left, x + self.GameStatePanel:GetWide() + gap) end
	local maximum = math.min(540 * factor, width - left - margin)
	if maximum < 80 * factor then self.PurchaseHUDData = nil return end
	local data = self.PurchaseHUDData
	if data and data.target == target and data.code == code and data.discount == discount and data.screenWidth == width and data.screenHeight == height
		and data.scale == scale and data.revision == revision and data.left == left then return data end
	local name = input.GetKeyName(code)
	if not name or name == "" then self.PurchaseHUDData = nil return end
	local text = translate.Format("hud_shop_shortcut", string.upper(name), translate.Get(target))
	local secondary = discount and translate.Format("x_discount_for_buying_between_waves", discount)
	local font = "ZSHUDSmall"
	text = style.Fit(text, font, maximum - padding * 2)
	if secondary then secondary = style.Fit(secondary, font, maximum - padding * 2) end
	surface.SetFont(font)
	local textWidth, textHeight = surface.GetTextSize(text)
	if secondary then textWidth = math.max(textWidth, surface.GetTextSize(secondary)) end
	local cardWidth = math.min(maximum, textWidth + padding * 2)
	data = {target = target, code = code, discount = discount, screenWidth = width, screenHeight = height, scale = scale, revision = revision, left = left,
		text = text, secondary = secondary, font = font, textHeight = textHeight, padding = padding, gap = math.floor(4 * factor + 0.5), width = cardWidth,
		x = math.max(left, math.min((width - cardWidth) * 0.5, width - margin - cardWidth)), y = margin}
	data.height = padding * 2 + textHeight * (secondary and 2 or 1) + (secondary and data.gap or 0)
	self.PurchaseHUDData = data
	return data
end

function GM:DrawPurchaseHUD()
	local data = self:BuildPurchaseHUD()
	if not data then return end
	style.Card(data.x, data.y, data.width, data.height, nil, true)
	draw.SimpleText(data.text, data.font, data.x + data.padding, data.y + data.padding, style.Text)
	if data.secondary then draw.SimpleText(data.secondary, data.font, data.x + data.padding, data.y + data.padding + data.textHeight + data.gap, style.Muted) end
end
