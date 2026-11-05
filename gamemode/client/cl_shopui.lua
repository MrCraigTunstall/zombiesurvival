surface.CreateFont("ZSMenuTitle", {font = "Roboto", size = 24, weight = 700, antialias = true, extended = true})
surface.CreateFont("ZSMenuBody", {font = "Roboto", size = 16, weight = 500, antialias = true, extended = true})
surface.CreateFont("ZSMenuSmall", {font = "Roboto", size = 13, weight = 500, antialias = true, extended = true})

local scaledFonts = {Title = {24, 700}, Body = {16, 500}, Small = {13, 500}}
function GM:RefreshMenuScale()
	local width, height = ScrW(), ScrH()
	local scale = math.max(1, math.min(2, width / 1920, height / 1080))
	if self.MenuScale == scale then return scale end
	self.MenuScale = scale
	for name, spec in pairs(scaledFonts) do
		surface.CreateFont("ZSMenuScaled" .. name, {font = "Roboto", size = math.floor(spec[1] * scale + 0.5), weight = spec[2], antialias = true, extended = true})
	end
	return scale
end
GM:RefreshMenuScale()
hook.Add("OnScreenSizeChanged", "ZSMenuScaledFonts", function() GAMEMODE:RefreshMenuScale() end)

GM.ShopColors = {background = Color(15, 20, 26, 250), header = Color(22, 30, 39), row = Color(26, 35, 45),
	hover = Color(37, 49, 62), selected = Color(28, 66, 53), accent = Color(80, 205, 135), muted = Color(175, 189, 202)}
local colors = GM.ShopColors

function GM:StyleShopFrame(frame)
	if self.RefreshCatalogueTranslations then self:RefreshCatalogueTranslations() end
	frame.Paint = function(self, width, height)
		draw.RoundedBox(8, 0, 0, width, height, colors.background)
		draw.RoundedBox(8, 0, 0, width, 72, colors.header)
		surface.SetDrawColor(colors.accent)
		surface.DrawRect(16, 70, width - 32, 2)
	end
end

local function SetStyledDisabled(self, disabled)
	local result = self.ZSNativeSetDisabled(self, disabled)
	local foreground = disabled and colors.muted or self.ZSButtonPrimary and colors.background or color_white
	if foreground ~= self.ZSButtonForeground then
		self.ZSButtonForeground = foreground
		self:SetTextColor(foreground)
	end
	return result
end

function GM:StyleShopButton(button, primary, scaled)
	button:SetFont(scaled and "ZSMenuScaledSmall" or "ZSMenuSmall")
	if button.SetTooltipPanelOverride then button:SetTooltipPanelOverride("ZSShopTooltip") end
	button.ZSButtonPrimary = primary
	if not button.ZSNativeSetDisabled then button.ZSNativeSetDisabled = button.SetDisabled end
	button.SetDisabled = SetStyledDisabled
	button:SetDisabled(not button:IsEnabled())
	button.Paint = function(self, width, height)
		draw.RoundedBox(5, 0, 0, width, height, not self:IsEnabled() and colors.row
			or self.ZSButtonPrimary and colors.accent or self.Hovered and colors.hover or colors.row)
	end
end

function GM:PaintShopItem(width, height)
	draw.RoundedBox(5, 0, 0, width, height, self.On and colors.selected or self.Hovered and colors.hover or colors.row)
end

function GM:PaintShopSearch(width, height)
	draw.RoundedBox(5, 0, 0, width, height, colors.row)
	self:DrawTextEntryText(color_white, colors.selected, colors.accent)
	if self:GetValue() == "" then
		draw.SimpleText(self:GetPlaceholderText() or "", self.ZSMenuScaled and "ZSMenuScaledBody" or "ZSMenuBody", 8 * (self.ZSMenuScaled and GAMEMODE.MenuScale or 1), height * 0.5, colors.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

function GM:StyleShopSearch(entry, scaled)
	entry.ZSMenuScaled = scaled
	entry:SetFont(scaled and "ZSMenuScaledBody" or "ZSMenuBody")
	entry:SetTextColor(color_white)
	entry:SetHighlightColor(colors.selected)
	entry:SetCursorColor(colors.accent)
	entry.Paint = self.PaintShopSearch
end

function GM:CreateScaledMenuCloseButton(frame, tooltip)
	frame:ShowCloseButton(false)
	local button = vgui.Create("DButton", frame)
	frame.CloseButton = button
	button:SetText("X") self:StyleShopButton(button, false, true)
	button:SetTooltip(tooltip or translate.Get("close"))
	button.DoClick = function() frame:Close() end
	local nativeLayout = frame.PerformLayout
	frame.PerformLayout = function(panel, width, height)
		if nativeLayout then nativeLayout(panel, width, height) end
		local scale = GAMEMODE.MenuScale or 1
		button:SetSize(math.floor(30 * scale + 0.5), math.floor(24 * scale + 0.5))
		button:SetPos(width - math.floor(38 * scale + 0.5), math.floor(4 * scale + 0.5))
	end
	return button
end

function GM:ScaleMenuChoice(choice)
	if choice.ZSScaledChoice then return end
	choice.ZSScaledChoice = true
	local layout = choice.PerformLayout
	choice.PerformLayout = function(control, ...)
		layout(control, ...)
		local scale = GAMEMODE.MenuScale or 1
		control:SetTextInset(math.floor(8 * scale + 0.5), 0)
		if IsValid(control.DropButton) then
			control.DropButton:SetSize(math.floor(15 * scale + 0.5), math.floor(15 * scale + 0.5))
			control.DropButton:AlignRight(math.floor(4 * scale + 0.5))
			control.DropButton:CenterVertical()
		end
	end
	local opened = choice.OnMenuOpened
	choice.OnMenuOpened = function(control, menu)
		if opened then opened(control, menu) end
		local scale = GAMEMODE.MenuScale or 1
		menu.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, colors.background) end
		for _, option in ipairs(menu:GetCanvas():GetChildren()) do
			if option.SetFont then
				option:SetFont("ZSMenuScaledBody")
				option:SetTextColor(color_white)
				option.UpdateColours = function(panel) panel:SetTextColor(color_white) end
				option.Paint = function(panel, width, height)
					draw.RoundedBox(4, 0, 0, width, height, panel:IsHovered() and colors.hover or colors.row)
				end
				option:SetTextInset(math.floor(8 * scale + 0.5), 0)
				local layout = option.PerformLayout
				option.PerformLayout = function(panel, width, height)
					layout(panel, width, height)
					panel:SetTall(math.floor(32 * scale + 0.5))
				end
			end
		end
		menu:InvalidateLayout(true)
		local x, y = control:LocalToScreen(0, control:GetTall())
		menu:Open(x, y, false, control)
	end
end

function GM:ScaleMenuSheet(sheet)
	if sheet.ZSScaledMenuSheet then return end
	sheet.ZSScaledMenuSheet = true
	local nativeLayout = sheet.PerformLayout
	sheet.PerformLayout = function(panel, ...)
		local scale = GAMEMODE.MenuScale or 1
		local function pixels(value) return math.floor(value * scale + 0.5) end
		panel:SetPadding(pixels(8))
		panel.tabScroller:DockMargin(pixels(3), 0, pixels(3), 0)
		for _, item in ipairs(panel.Items) do
			local tab = item.Tab
			if not tab.ZSScaledMenuTab then
				tab.ZSScaledMenuTab = true
				local nativeHeight, nativeScheme, nativeTabLayout = tab.GetTabHeight, tab.ApplySchemeSettings, tab.PerformLayout
				tab.GetTabHeight = function(control) return math.floor(nativeHeight(control) * (GAMEMODE.MenuScale or 1) + 0.5) end
				tab.ApplySchemeSettings = function(control)
					nativeScheme(control)
					local factor = GAMEMODE.MenuScale or 1
					local icon = IsValid(control.Image)
					if icon then control.Image:SetSize(math.floor(16 * factor + 0.5), math.floor(16 * factor + 0.5)) end
					control:SetTextInset(math.floor((icon and 26 or 10) * factor + 0.5), math.floor(4 * factor + 0.5))
					local width = control:GetContentSize()
					control:SetSize(width + math.floor(10 * factor + 0.5), control:GetTabHeight())
				end
				tab.PerformLayout = function(control, ...)
					nativeTabLayout(control, ...)
					local factor = GAMEMODE.MenuScale or 1
					if IsValid(control.Image) then control.Image:SetPos(math.floor(7 * factor + 0.5), math.floor(3 * factor + 0.5)) end
				end
			end
			item.Panel:SetPos(panel:GetPadding(), pixels(20) + panel:GetPadding())
		end
		return nativeLayout(panel, ...)
	end
end

local function WrapShopMessageText(text, width, font)
	surface.SetFont(font)
	local _, height = surface.GetTextSize("Mg")
	local lines, line = {}, ""
	local function Append(word)
		local candidate = line == "" and word or line .. " " .. word
		if surface.GetTextSize(candidate) <= width then line = candidate return end
		if line ~= "" then lines[#lines + 1] = line line = "" end
		if surface.GetTextSize(word) <= width then line = word return end
		for character in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			candidate = line .. character
			if line ~= "" and surface.GetTextSize(candidate) > width then lines[#lines + 1] = line line = character else line = candidate end
		end
	end
	for paragraph in (text .. "\n"):gmatch("(.-)\n") do
		for word in paragraph:gmatch("%S+") do Append(word) end
		lines[#lines + 1] = line line = ""
	end
	return table.concat(lines, "\n"), #lines * height
end

function GM:ShowShopMessage(text, title, buttonText)
 self:RefreshMenuScale()
 local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
 local frame = self.ShopMessageFrame
 if IsValid(frame) then frame:Remove() end
 frame = vgui.Create("DFrame")
 self.ShopMessageFrame = frame
 frame:SetTitle(title or "")
 frame:SetDeleteOnClose(true)
 frame:SetSizable(false)
 surface.SetFont("ZSMenuScaledBody")
 local desiredWidth = surface.GetTextSize(title or "") + U(64)
 for line in ((text or "") .. "\n"):gmatch("(.-)\n") do desiredWidth = math.max(desiredWidth, surface.GetTextSize(line) + U(48)) end
 frame:SetSize(math.min(math.max(U(280), desiredWidth), U(520), ScrW() - U(24)), U(128))
 frame.lblTitle:SetFont("ZSMenuScaledBody")
 self:StyleShopFrame(frame)
 self:CreateScaledMenuCloseButton(frame)
 local scroll = frame:Add("DScrollPanel")
 scroll:SetZPos(2)
 local body = scroll:Add("DLabel")
 body:SetFont("ZSMenuScaledBody")
 body:SetTextColor(color_white)
 body:SetWrap(false)
 body:SetAutoStretchVertical(false)
 body:SetText(text or "")
 local button = frame:Add("DButton")
 button:SetZPos(1)
 button:SetText(buttonText or translate.Get("close"))
 self:StyleShopButton(button, true, true)
 button.DoClick = function() frame:Close() end
 local nativeLayout = frame.PerformLayout
 frame.PerformLayout = function(panel, wide, tall)
  nativeLayout(panel, wide, tall)
  panel.lblTitle:SetPos(U(12), U(6))
  panel.lblTitle:SetSize(wide - U(64), U(26))
  scroll:SetPos(U(16), U(48))
  scroll:SetSize(wide - U(32), math.max(U(24), tall - U(106)))
  button:SetPos(U(16), tall - U(46))
  button:SetSize(wide - U(32), U(30))
 end
 frame.Paint = function(panel, wide, tall)
  draw.RoundedBox(U(8), 0, 0, wide, tall, colors.background)
  draw.RoundedBox(U(8), 0, 0, wide, U(38), colors.header)
  surface.SetDrawColor(colors.accent)
  surface.DrawRect(U(12), U(38), wide - U(24), U(2))
 end
 local wide = frame:GetWide()
 body:SetWide(wide - U(32))
 local wrapped, textHeight = WrapShopMessageText(text or "", wide - U(48), "ZSMenuScaledBody")
 body:SetText(wrapped)
 body:SetTall(textHeight)
 frame:SetTall(math.min(ScrH() - U(24), math.max(U(122), textHeight + U(106))))
 body:Dock(TOP)
 frame:InvalidateLayout(true)
 frame:Center()
 frame:MakePopup()
 return frame
end
