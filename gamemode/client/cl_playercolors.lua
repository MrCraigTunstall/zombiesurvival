if GM and IsValid(GM.m_PlayerColors) then GM.m_PlayerColors:Remove() GM.m_PlayerColors = nil end
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
	GAMEMODE:RefreshMenuScale()
	local width, height = math.min(U(940), screenWidth - 32), math.min(U(600), screenHeight - 64)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
	if frame.LayoutWidth == width and frame.LayoutHeight == height then
  if screenChanged then frame:Center()end
  return
 end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	frame:SetSize(width, height) frame:Center() frame:InvalidateLayout(true)
end

local function Component(value, maximum)
	value = tonumber(value) or 0
	if value ~= value or value == math.huge or value == -math.huge then return 0 end
	return math.Clamp(value, 0, maximum)
end

function GM:DecodeAppearanceColor(text)
	local r, g, b = string.match(text or "", "^%s*(%S+)%s+(%S+)%s+(%S+)%s*$")
	r, g, b = Component(r, 2.5), Component(g, 2.5), Component(b, 2.5)
	local brightness = math.max(1, r, g, b)
	return Color(r / brightness * 255, g / brightness * 255, b / brightness * 255), brightness
end

function GM:EncodeAppearanceColor(color, brightness)
	brightness = Component(brightness, 2.5)
	return string.format("%.6f %.6f %.6f", Component(color.r, 255) / 255 * brightness,
		Component(color.g, 255) / 255 * brightness, Component(color.b, 255) / 255 * brightness)
end

local function RefreshLanguage(frame)
	local revision = translate.GetRevision()
	if frame.LanguageRevision == revision then return end
	frame.LanguageRevision = revision
	for _, pair in ipairs({{frame.Title, "mm_color"}, {frame.Subtitle, "mm_color_spawn_notice"}, {frame.ApplyButton, "mm_apply_colors"},
		{frame.BackButton, "mm_back"}, {frame.CloseButton, "mm_close"}}) do pair[1]:SetText(translate.Get(pair[2])) end
	for _, section in ipairs(frame.Sections) do
		section.Title:SetText(translate.Get(section.TitleKey))
		section.Brightness:SetText(translate.Get("mm_color_brightness"))
	end
end

function MakepPlayerColor()
	GAMEMODE:RefreshMenuScale()
	local frame = GAMEMODE.m_PlayerColors
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		frame:SetVisible(false)
		GAMEMODE.m_PlayerColors = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(8, 0, 0, width, height, GAMEMODE.ShopColors.background)
			draw.RoundedBox(8, 0, 0, width, U(72), GAMEMODE.ShopColors.header)
			surface.SetDrawColor(GAMEMODE.ShopColors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		frame.Title = EasyLabel(frame, translate.Get("mm_color"), "ZSMenuScaledTitle", color_white)
		frame.Subtitle = EasyLabel(frame, translate.Get("mm_color_spawn_notice"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
		frame.Subtitle:SetWrap(true)
		frame.Scroll = vgui.Create("DScrollPanel", frame)
		frame.Sections = {}
		frame.ApplyButton = vgui.Create("DButton", frame)
		frame.ApplyButton:SetText(translate.Get("mm_apply_colors"))
		GAMEMODE:StyleShopButton(frame.ApplyButton, true, true)
		frame.ApplyButton.DoClick = function()
			for _, section in ipairs(frame.Sections) do
				if section.Dirty then
					local value = GAMEMODE:EncodeAppearanceColor(section.Mixer:GetColor(), section.Brightness:GetValue())
					if value ~= section.SavedEncoding then RunConsoleCommand(section.ConVar, value) end
					section.SavedEncoding = value
					section.WidgetEncoding = value
					section.Dirty = false
				end
			end
			frame.ApplyButton:SetEnabled(false)
		end
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		for _, entry in ipairs({{"cl_playercolor", "mm_pm_color"}, {"cl_weaponcolor", "mm_w_color"}}) do
			local section = vgui.Create("DPanel", frame.Scroll:GetCanvas())
			section.ConVar = entry[1]
			section.TitleKey = entry[2]
			section.Paint = function(panel, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
			section.Title = EasyLabel(section, translate.Get(entry[2]), "ZSMenuScaledBody", color_white)
			section.Mixer = vgui.Create("ZSOptionsColorMixer", section)
			section.Mixer:SetAlphaBar(false)
			section.Mixer:SetPalette(false)
			section.Mixer.UpdateConVars = function() end
			section.Mixer.Think = function() end
			section.Brightness = vgui.Create("DNumSlider", section)
			section.Brightness:SetText(translate.Get("mm_color_brightness"))
			section.Brightness:SetMin(0)
			section.Brightness:SetMax(2.5)
			section.Brightness:SetDecimals(2)
			section.Brightness.Label:SetTextColor(color_white)
			section.Brightness.Label:SetFont("ZSMenuScaledSmall")
			local function Changed()
				if frame.Loading then return end
				section.Dirty = GAMEMODE:EncodeAppearanceColor(section.Mixer:GetColor(), section.Brightness:GetValue()) ~= section.WidgetEncoding
				local dirty = false
				for _, current in ipairs(frame.Sections) do if current.Dirty then dirty = true break end end
				if frame.ApplyButton:IsEnabled() ~= dirty then frame.ApplyButton:SetEnabled(dirty) end
			end
			section.Mixer.ValueChanged = Changed
			section.Brightness.OnValueChanged = Changed
			section.PerformLayout = function(panel, width, height)
				panel.Title:SetPos(U(12), U(10)) panel.Title:SetSize(width - U(24), U(24))
				panel.Mixer:SetPos(U(12), U(40)) panel.Mixer:SetSize(width - U(24), height - U(100))
				panel.Brightness:SetPos(U(12), height - U(46)) panel.Brightness:SetSize(width - U(24), U(32))
				if panel.AppearanceScale ~= GAMEMODE.MenuScale then
					panel.AppearanceScale = GAMEMODE.MenuScale
					if panel.Mixer.ApplyMenuScale then panel.Mixer:ApplyMenuScale() end
					if IsValid(panel.Brightness.TextArea) then panel.Brightness.TextArea:SetFont("ZSMenuScaledBody") panel.Brightness.TextArea:SetWide(U(65)) if panel.Brightness.TextArea.ApplySchemeSettings then panel.Brightness.TextArea:ApplySchemeSettings() end end
					if IsValid(panel.Brightness.Slider) and IsValid(panel.Brightness.Slider.Knob) then panel.Brightness.Slider.Knob:SetSize(U(15), U(15)) end
				end
			end
			frame.Sections[#frame.Sections+1] = section
		end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SetPos(U(20), U(12))
			panel.Title:SetSize(width - U(40), U(32))
			panel.Subtitle:SetPos(U(20), U(44))
			panel.Subtitle:SetSize(width - U(40), U(32))
			panel.Scroll:SetPos(U(20), U(88))
			panel.Scroll:SetSize(width - U(40), height - U(152))
			local columns = width >= U(760) and 2 or 1
			local available = width - U(58)
			local sectionWidth = (available - (columns - 1) * U(12)) / columns
			local sectionHeight = math.max(U(220), math.min(U(280), height - U(152)))
			for index, section in ipairs(panel.Sections) do
				section:SetSize(sectionWidth, sectionHeight)
				section:SetPos((index - 1) % columns * (sectionWidth + U(12)), math.floor((index - 1) / columns) * (sectionHeight + U(12)))
			end
			panel.Scroll:GetCanvas():SetTall(math.ceil(2 / columns) * (sectionHeight + U(12)) - U(12))
			panel.BackButton:SetSize(U(100), U(32))
			panel.BackButton:SetPos(U(20), height - U(48))
			panel.ApplyButton:SetSize(U(150), U(32))
			panel.ApplyButton:SetPos(width - U(280), height - U(48))
			panel.CloseButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48))
			panel.Scroll:GetVBar():SetWide(U(16))
		end
		frame.OnRemove = function(panel)
			panel.Sections = nil
			if GAMEMODE.m_PlayerColors == panel then GAMEMODE.m_PlayerColors = nil end
		end
		local nativeThink = frame.Think
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if nativeThink then nativeThink(panel) end
			local now = RealTime()
			if now < (panel.NextLanguageRefresh or 0) then return end
			panel.NextLanguageRefresh = now + 0.2
			RefreshLanguage(panel)
		end
	end
	Layout(frame)
	if frame:IsVisible() then return frame end
	PlayMenuOpenSound()
	frame.Loading = true
	for _, section in ipairs(frame.Sections) do
		local color, brightness = GAMEMODE:DecodeAppearanceColor(GetConVarString(section.ConVar))
		section.SavedEncoding = GAMEMODE:EncodeAppearanceColor(color, brightness)
		section.Mixer:SetColor(color)
		section.Brightness:SetValue(brightness)
		section.WidgetEncoding = GAMEMODE:EncodeAppearanceColor(section.Mixer:GetColor(), section.Brightness:GetValue())
		section.Dirty = false
	end
	frame.Loading = false
	frame.ApplyButton:SetEnabled(false)
	RefreshLanguage(frame)
	frame.NextLanguageRefresh = 0
	frame:SetVisible(true)
	frame:MakePopup()
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSPlayerColorLayout", function()
 if IsValid(GAMEMODE.m_PlayerColors) then Layout(GAMEMODE.m_PlayerColors) end
end)
