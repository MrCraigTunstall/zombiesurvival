if IsValid(pOptions) then pOptions:Remove() pOptions = nil end

local background = Color(15, 20, 26)
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local StyleOptions

local function WrapOptionText(text, width, font)
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

local function Layout(frame)
	GAMEMODE:RefreshMenuScale()
	local width, height = ScrW(), ScrH()
	frame.LayoutDirty = nil
	if frame.LayoutWidth == width and frame.LayoutHeight == height then return end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	frame:SetSize(math.min(U(940), width - 32), math.min(U(600), height - 64))
	if frame.OptionsScale ~= GAMEMODE.MenuScale then
		frame.OptionsScale = GAMEMODE.MenuScale
		for _, item in ipairs(frame.Sheet.Items) do
			local list = item.Panel
			if list.ApplyKeyScale then list:ApplyKeyScale()
			elseif list.ZSOptionsStyled then StyleOptions(list, frame, frame.Sheet) end
			if list.SetPadding then list:SetPadding(U(12)) list:SetSpacing(U(8)) end
			if IsValid(list.VBar) then list.VBar:SetWide(U(16)) end
		end
	end
	frame:Center()
	frame:InvalidateLayout(true)
end

local function BindChoice(panel, name, normalize)
	panel:SetConVar(name)
	local function Update(value)
		if normalize then value = normalize(value) end
		panel.m_strConVarValue = value
		panel:SetValue(panel:GetOptionTextByData(value))
	end
	panel.CheckConVarChanges = function() Update(GetConVarString(name)) end
	panel.Think = function() end
	local identifier = "ZSOptionsChoice" .. tostring(panel)
	cvars.AddChangeCallback(name, function(_, _, value)
		if IsValid(panel) then Update(value) end
	end, identifier)
	local removed = panel.OnRemove
	panel.OnRemove = function(self)
		cvars.RemoveChangeCallback(name, identifier)
		if removed then return removed(self) end
	end
	panel:CheckConVarChanges()
end

local function CreateOption(class, parent)
	local panel = vgui.Create(class == "DColorMixer" and "ZSOptionsColorMixer" or class, parent)
	panel.ZSOptionsKind = class
	return panel
end

local function GuardOption(panel, frame, category, sheet)
	if panel.ConVarChanged then
		local changed = panel.ConVarChanged
		panel.ConVarChanged = function(self, value)
			local numeric = tonumber(value)
			if numeric and self.m_strConVar and GetConVarNumber(self.m_strConVar) == numeric then return end
			return changed(self, value)
		end
	end
	local think = panel.Think
	if think then
		panel.Think = function(self, ...)
			if not IsValid(frame) or not frame:IsVisible() then return end
			local active = sheet:GetActiveTab()
			if not IsValid(active) or active:GetPanel() ~= category then return end
			return think(self, ...)
		end
	end
	for _, child in ipairs(panel:GetChildren()) do GuardOption(child, frame, category, sheet) end
end

StyleOptions = function(list, frame, sheet)
	local initialized = list.ZSOptionsStyled
	list.ZSOptionsStyled = true
	for _, item in ipairs(list:GetItems()) do
		local kind = item.ZSOptionsKind or (item.OpenMenu and item.AddChoice and "DComboBox")
			or (item.GetChecked and item.Button and item.Label and "DCheckBoxLabel")
			or (item.SetDecimals and item.SetConVar and "DNumSlider")
		if kind == "DCheckBoxLabel" then
			item:SetFont("ZSMenuScaledBody")
			item:SetTextColor(color_white)
			item:SetTall(U(28))
			item.WrapWidth = nil
			if not initialized then
			item.OptionText = item.Label:GetText()
			local setText = item.SetText
			item.SetText = function(panel, text)
				panel.OptionText = text
				return setText(panel, text)
			end
			item.GetText = function(panel) return panel.OptionText end
			end
			item.Label:SetWrap(false)
			item.PerformLayout = function(panel, width)
				local indent = panel:GetIndent() or 0
				local available = math.max(1, width - indent - U(24))
				local text, font = panel.OptionText, panel.Label:GetFont()
				if panel.WrapWidth == available and panel.WrapText == text and panel.WrapFont == font then return end
				panel.WrapWidth, panel.WrapText, panel.WrapFont = available, text, font
				panel.Label:SetWide(available)
				local wrapped, textHeight = WrapOptionText(text, available, font)
				panel.Label:SetText(wrapped)
				panel.Label:SetTall(textHeight)
				local height = math.max(U(28), textHeight + U(8))
				if panel:GetTall() ~= height then panel:SetTall(height) end
				panel.Button:SetSize(U(15), U(15))
				panel.Button:SetPos(indent, math.floor((height - U(15)) * 0.5))
				panel.Label:SetPos(indent + U(24), math.floor((height - textHeight) * 0.5))
			end
		elseif kind == "DNumSlider" then
			item.Label:SetFont("ZSMenuScaledSmall")
			item.Label:SetTextColor(color_white)
			item:SetTall(U(36))
			if IsValid(item.TextArea) then item.TextArea:SetFont("ZSMenuScaledBody") item.TextArea:SetWide(U(65)) end
			if IsValid(item.Slider) then
				item.Slider:SetTall(U(16))
				if IsValid(item.Slider.Knob) then item.Slider.Knob:SetSize(U(15), U(15)) end
			end
		elseif kind == "DComboBox" then
			item:SetFont("ZSMenuScaledBody")
			item:SetTextColor(color_white)
			item:SetTall(U(32))
			GAMEMODE:ScaleMenuChoice(item)
			item.Paint = function(self, width, height)
				draw.RoundedBox(4, 0, 0, width, height, self:IsHovered() and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
			end
		elseif kind == "DColorMixer" then
			item:SetTall(U(144))
			if item.ApplyMenuScale then item:ApplyMenuScale() end
			if not initialized then
			local read, write = item.ConVarThink, item.UpdateConVars
			item.ConVarThink = function(self, ...)
				local now = SysTime()
				if self.NextConVarCheck > now then return end
				self.ZSReadingOptions = true
				read(self, ...)
				self.ZSReadingOptions = nil
				self.NextConVarCheck = now + 0.2
			end
			item.UpdateConVars = function(self, color)
				if not self.ZSReadingOptions then return write(self, color) end
			end
			end
		elseif item.SetTextColor then
			item:SetFont("ZSMenuScaledSmall")
			item:SetTextColor(GAMEMODE.ShopColors.muted)
			item:SizeToContentsY()
		end
	end
	if not initialized then GuardOption(list, frame, list, sheet) end
end

local function BuildGameplay(Window, gameplay_list)
	gamemode.Call("AddExtraOptions", gameplay_list, Window)
	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_movement_view_roll"))
	check:SetConVar("zs_movementviewroll")
	check:SizeToContents()
	gameplay_list:AddItem(check)



	gameplay_list:AddItem(EasyLabel(Window, translate.Get("options_proprotation"), "ZSMenuScaledSmall", color_white))
	local dropdown = CreateOption("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	dropdown:AddChoice("No snap", "0")
	dropdown:AddChoice("15 degrees", "15")
	dropdown:AddChoice("30 degrees", "30")
	dropdown:AddChoice("45 degrees", "45")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_proprotationsnap", data)
	end
	BindChoice(dropdown, "zs_proprotationsnap", function(value)
		local number = tonumber(value)
		return number == 15 and "15" or number == 30 and "30" or number == 45 and "45" or "0"
	end)
	gameplay_list:AddItem(dropdown)

	local slider = CreateOption("DNumSlider", Window)
	slider:SetDecimals(0)
	slider:SetMinMax(0, 512)
	slider:SetConVar("zs_transparencyradius")
	slider:SetText(translate.Get("options_transparency_radius"))
	slider:SizeToContents()
	gameplay_list:AddItem(slider)

	local slider = CreateOption("DNumSlider", Window)
	slider:SetDecimals(1)
	slider:SetMinMax(0, 255)
	slider:SetConVar("zs_filmgrainopacity")
	slider:SetText(translate.Get("options_film_grain"))
	slider:SizeToContents()
	gameplay_list:AddItem(slider)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_crosshair_p"))
	local colpicker = CreateOption("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_crosshair_colr")
	colpicker:SetConVarG("zs_crosshair_colg")
	colpicker:SetConVarB("zs_crosshair_colb")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_crosshair_s"))
	local colpicker = CreateOption("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_crosshair_colr2")
	colpicker:SetConVarG("zs_crosshair_colg2")
	colpicker:SetConVarB("zs_crosshair_colb2")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_hp_full"))
	local colpicker = CreateOption("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_auracolor_full_r")
	colpicker:SetConVarG("zs_auracolor_full_g")
	colpicker:SetConVarB("zs_auracolor_full_b")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_hp_no"))
	local colpicker = CreateOption("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_auracolor_empty_r")
	colpicker:SetConVarG("zs_auracolor_empty_g")
	colpicker:SetConVarB("zs_auracolor_empty_b")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)
end

local function BuildWeapons(Window, weapon_options)
	GAMEMODE:AddMeleeCrosshairOptions(weapon_options, Window)
	gamemode.Call("AddExtraOptions", weapon_options, Window)
	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_floating_score"))
	check:SetConVar("zs_nofloatingscore")
	check:SizeToContents()
	weapon_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_iron_sights_crosshair"))
	check:SetConVar("zs_ironsightscrosshair")
	check:SizeToContents()
	weapon_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_crosshair_rotate"))
	check:SetConVar("zs_nocrosshairrotate")
	check:SizeToContents()
	weapon_options:AddItem(check)


	weapon_options:AddItem(EasyLabel(Window, translate.Get("options_weapon_hud_mode"), "ZSMenuScaledSmall", color_white))
	local dropdown = CreateOption("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	dropdown:AddChoice("3D", "0")
	dropdown:AddChoice("2D", "1")
	dropdown:AddChoice("Both", "2")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_weaponhudmode", data)
	end
	BindChoice(dropdown, "zs_weaponhudmode", function(value)
		local number = tonumber(value)
		return number == 2 and "2" or number == 1 and "1" or "0"
	end)
	weapon_options:AddItem(dropdown)
end

local function BuildSound(Window, sound_options)
	gamemode.Call("AddExtraOptions", sound_options, Window)
	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_beats"))
	check:SetConVar("zs_beats")
	check:SizeToContents()
	sound_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_play_music"))
	check:SetConVar("zs_playmusic")
	check:SizeToContents()
	sound_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_intro_music"))
	check:SetConVar("zs_intro")
	check:SizeToContents()
	sound_options:AddItem(check)

	sound_options:AddItem(EasyLabel(Window, translate.Get("options_beatset_human"), "ZSMenuScaledSmall", color_white))
	local dropdown = CreateOption("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	for setname in pairs(GAMEMODE.Beats) do
		if setname ~= GAMEMODE.BeatSetHumanDefault then
			dropdown:AddChoice(setname, setname)
		end
	end
	dropdown:AddChoice("none", "none")
	dropdown:AddChoice("default", "default")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_beatset_human", data)
	end
	BindChoice(dropdown, "zs_beatset_human", function(value)
		return value == GAMEMODE.BeatSetHumanDefault and "default" or value
	end)
	sound_options:AddItem(dropdown)

	sound_options:AddItem(EasyLabel(Window, translate.Get("options_beatset_zombie"), "ZSMenuScaledSmall", color_white))
	local dropdown = CreateOption("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	for setname in pairs(GAMEMODE.Beats) do
		if setname ~= GAMEMODE.BeatSetZombieDefault then
			dropdown:AddChoice(setname, setname)
		end
	end
	dropdown:AddChoice("none", "none")
	dropdown:AddChoice("default", "default")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_beatset_zombie", data)
	end
	BindChoice(dropdown, "zs_beatset_zombie", function(value)
		return value == GAMEMODE.BeatSetZombieDefault and "default" or value
	end)
	sound_options:AddItem(dropdown)

	local slider = CreateOption("DNumSlider", Window)
	slider:SetDecimals(0)
	slider:SetMinMax(0, 100)
	slider:SetConVar("zs_beatsvolume")
	slider:SetText(translate.Get("options_music_volume"))
	slider:SizeToContents()
	sound_options:AddItem(slider)
end

local function BuildPlayer(Window, player_options)
	gamemode.Call("AddExtraOptions", player_options, Window)
	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_discord"))
	check:SetConVar("zs_nodiscord")
	check:SizeToContents()
	player_options:AddItem(check)


	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_redeem"))
	check:SetConVar("zs_noredeem")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_bandit"))
	check:SetConVar("zs_nobandit")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_always_volunteer"))
	check:SetConVar("zs_alwaysvolunteer")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_boss_pick"))
	check:SetConVar("zs_nobosspick")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_suicide_on_change"))
	check:SetConVar("zs_suicideonchange")
	check:SizeToContents()
	player_options:AddItem(check)
end

local function BuildHUD(Window, hud_options)
	gamemode.Call("AddExtraOptions", hud_options, Window)
	local voice = CreateOption("DCheckBoxLabel", Window)
	voice:SetText(translate.Get("options_custom_voice"))
	voice:SetTooltip(translate.Get("custom_voice_desc"))
	voice:SetConVar("zs_custom_voice")
	voice:SizeToContents()
	hud_options:AddItem(voice)
	local selection = CreateOption("DCheckBoxLabel", Window)
	selection:SetText(translate.Get("options_custom_weaponselect"))
	selection:SetTooltip(translate.Get("weaponselect_desc"))
	selection:SetConVar("zs_custom_weaponselect")
	selection:SizeToContents()
	hud_options:AddItem(selection)
	local mode = CreateOption("DComboBox", Window)
	mode:SetTooltip(translate.Get("weaponselect_mode_desc"))
	mode:SetSortItems(false)
	mode:AddChoice(translate.Get("weaponselect_follow"), "-1")
	mode:AddChoice(translate.Get("weaponselect_confirm"), "0")
	mode:AddChoice(translate.Get("weaponselect_instant"), "1")
	BindChoice(mode, "zs_weaponselect_mode")
	mode.OnSelect = function(self, index, value, data) GetConVar("zs_weaponselect_mode"):SetInt(tonumber(data)) end
	hud_options:AddItem(mode)
	local leave = CreateOption("DCheckBoxLabel", Window)
	leave:SetText(translate.Get("options_pointshop_autoclose"))
	leave:SetConVar("zs_pointshop_autoclose")
	leave:SizeToContents()
	hud_options:AddItem(leave)
	local delay = CreateOption("DNumSlider", Window)
	delay:SetText(translate.Get("options_pointshop_close_delay"))
	delay:SetDecimals(2)
	delay:SetMinMax(0, 2)
	delay:SetConVar("zs_pointshop_close_delay")
	delay:SizeToContents()
	hud_options:AddItem(delay)
	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_old_hud"))
	check:SetConVar("zs_classichud")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_ars_crate"))
	check:SetConVar("zs_noarscrate")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_status_ars_crate"))
	check:SetConVar("zs_nostatusarscrate")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_resupply"))
	check:SetConVar("zs_noresupply")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_film_mode"))
	check:SetConVar("zs_filmmode")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_post_processing"))
	check:SetConVar("zs_postprocessing")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_film_grain"))
	check:SetConVar("zs_filmgrain")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_color_mod"))
	check:SetConVar("zs_colormod")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_draw_pain_flash"))
	check:SetConVar("zs_drawpainflash")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_auras"))
	check:SetConVar("zs_auras")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_damage_floaters"))
	check:SetConVar("zs_damagefloaters")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_always_show_nails"))
	check:SetConVar("zs_alwaysshownails")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = CreateOption("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_show_old_baseoutlined_hud"))
	check:SetConVar("zs_oldbaseoutlinedhud")
	check:SizeToContents()
	hud_options:AddItem(check)
end

function MakepOptions()
	GAMEMODE:RefreshMenuScale()
	local frame = pOptions
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		frame:SetVisible(false)
		pOptions = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		local nativeThink = frame.Think
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if panel.LayoutDirty then Layout(panel) end
			if nativeThink then return nativeThink(panel) end
		end
		frame.Paint = function(_, width, height)
			draw.RoundedBox(8, 0, 0, width, height, background)
			draw.RoundedBoxEx(8, 0, 0, width, U(54), GAMEMODE.ShopColors.header, true, true, false, false)
			surface.SetDrawColor(GAMEMODE.ShopColors.accent)
			surface.DrawRect(0, U(52), width, U(2))
		end
		frame.Title = EasyLabel(frame, translate.Get("mm_options"), "ZSMenuScaledTitle", color_white)
		frame.Sheet = vgui.Create("DPropertySheet", frame)
		frame.Sheet:SetPadding(U(8))
		GAMEMODE:ScaleMenuSheet(frame.Sheet)
		frame.Sheet:SetFadeTime(0)
		frame.Sheet.Paint = function(self, width, height)
			draw.RoundedBox(5, 0, U(20), width, height - U(20), GAMEMODE.ShopColors.row)
		end
		local categories = {
			{"options_weapon", "icon16/gun.png", BuildWeapons},
			{"options_gameplay", "icon16/bomb.png", BuildGameplay},
			{"options_visual", "icon16/eye.png", BuildHUD},
			{"options_sound", "icon16/sound.png", BuildSound},
			{"options_player", "icon16/user.png", BuildPlayer},
			{"keys_title", "icon16/keyboard.png"}
		}
		for _, entry in ipairs(categories) do
			local list = vgui.Create(entry[3] and "DPanelList" or "DPanel", frame.Sheet)
			list.Paint = function() end
			if entry[3] then
				list:EnableVerticalScrollbar()
				if IsValid(list.VBar) then list.VBar:SetWide(U(16)) end
				local bar = list.VBar
				if IsValid(bar) then
					bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, GAMEMODE.ShopColors.row) end
					for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
						button.Paint = function(panel, width, height)
							draw.RoundedBox(4, 2, 0, width - 4, height, panel:IsHovered() and GAMEMODE.ShopColors.accent or GAMEMODE.ShopColors.hover)
						end
					end
				end
				list:EnableHorizontal(false)
				list:SetPadding(U(12))
				list:SetSpacing(U(8))
			end
			local item = GAMEMODE:AddLazyShopSheet(frame.Sheet, translate.Get(entry[1]), list, entry[2], function()
				if entry[3] then
					entry[3](frame, list)
					StyleOptions(list, frame, frame.Sheet)
				else
					GAMEMODE:AddKeyBindingOptions(frame.Sheet, list)
					GuardOption(list, frame, list, frame.Sheet)
				end
			end)
			item.Tab:SetFont("ZSMenuScaledSmall")
			item.Tab:SetTextColor(color_white)
			item.Tab.Paint = function(tab, width, height)
				local selected = frame.Sheet:GetActiveTab() == tab
				draw.RoundedBox(4, 0, 0, width, height, selected and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
				if selected then surface.SetDrawColor(GAMEMODE.ShopColors.accent) surface.DrawRect(4, height - 2, width - 8, 2) end
			end
		end
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SetPos(U(20), U(12))
			panel.Title:SizeToContents()
			panel.Title:SetWide(width - U(40))
			panel.Sheet:SetPos(U(20), U(54))
			panel.Sheet:SetSize(width - U(40), height - U(118))
			panel.BackButton:SetSize(U(100), U(32))
			panel.BackButton:SetPos(U(20), height - U(48))
			panel.CloseButton:SetSize(U(100), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48))
		end
		frame.OnRemove = function(panel)
			panel.Sheet, panel.Title, panel.BackButton, panel.CloseButton = nil, nil, nil, nil
			if pOptions == panel then pOptions = nil end
		end
	end
	Layout(frame)
	if frame:IsVisible() then return frame end
	PlayMenuOpenSound()
	frame:SetVisible(true)
	frame:MakePopup()
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSOptionsLayout", function()
	if IsValid(pOptions) then
		if pOptions:IsVisible() then Layout(pOptions) else pOptions.LayoutDirty = true end
	end
end)
