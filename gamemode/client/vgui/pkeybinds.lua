local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local editor
if IsValid(GM.ZSKeySettingsFrame) then GM.ZSKeySettingsFrame:Remove() end
GM.ZSKeySettingsFrame = nil

function GM:AddKeyBindingOptions(sheet, parent)
	local panel = parent or vgui.Create("DPanel", sheet)
	panel:DockPadding(8, 8, 8, 8)
	panel.Paint = function() end
	local draft, binders, rows = {}, {}, {}
	for _, action in ipairs(self.ZSKeyActions) do draft[action.id] = self:GetZSKeyBinding(action.id) end
	local status = panel:Add("DLabel")
	status:Dock(BOTTOM)
	status:SetTall(36)
	status:SetWrap(true)
	status:SetFont("ZSMenuScaledSmall")
	status:SetTextColor(self.ShopColors.muted)
	status:SetText(translate.Get("keys_description"))
	local profiles = panel:Add("DPanel")
	profiles:Dock(TOP)
	profiles:SetTall(34)
	profiles:DockMargin(0, 0, 0, 6)
	profiles.Paint = function() end
	local picker = profiles:Add("DComboBox")
	picker:Dock(FILL)
	picker:SetFont("ZSMenuScaledBody")
	picker:SetTextColor(color_white)
	self:ScaleMenuChoice(picker)
	picker.Paint = function(control, width, height)
		draw.RoundedBox(5, 0, 0, width, height, control:IsHovered() and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
	end
	local name = panel:Add("DTextEntry")
	name:Dock(TOP)
	name:SetTall(30)
	name:DockMargin(0, 0, 0, 6)
	name:SetPlaceholderText(translate.Get("keys_profile_name"))
	name:SetFont("ZSMenuScaledBody")
	name:SetTextColor(color_white)
	name:SetCursorColor(color_white)
	name:SetHighlightColor(self.ShopColors.accent)
	name.Paint = function(control, width, height)
		draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row)
		control:DrawTextEntryText(color_white, GAMEMODE.ShopColors.accent, color_white)
	end
	local chosen
	local function RefreshProfiles()
		local names, current = GAMEMODE:GetZSKeyProfiles()
		picker:Clear()
		chosen = current
		name:SetText(current)
		for _, id in ipairs(names) do picker:AddChoice(id, id, id == current) end
	end
	picker.OnSelect = function(_, _, _, id) chosen = id name:SetText(id) end
	local refreshing = false
	local function RefreshBinders()
		refreshing = true
		for id, binder in pairs(binders) do
			binder:SetValue(math.max(0, GAMEMODE:GetEffectiveZSKey(id, draft) or 0))
			binder.Mode:SetText(translate.Get(draft[id] == 0 and "keys_engine_default" or draft[id] < 0 and "keys_unbound" or "keys_custom"))
		end
		refreshing = false
	end
	local function Report(ok, reason, conflict)
		status:SetText(ok and translate.Get("keys_saved") or conflict and translate.Format(reason, translate.Get(conflict)) or translate.Get(reason or "keys_invalid"))
	end
	local load = profiles:Add("DButton")
	load:Dock(RIGHT)
	load:SetWide(70)
	load:SetText(translate.Get("keys_load"))
	self:StyleShopButton(load, false, true)
	load.DoClick = function()
		local ok, reason, conflict = GAMEMODE:LoadZSKeyProfile(chosen)
		if ok then for _, action in ipairs(GAMEMODE.ZSKeyActions) do draft[action.id] = GAMEMODE:GetZSKeyBinding(action.id) end; RefreshBinders() end
		Report(ok, reason, conflict)
	end
	local controls = panel:Add("DPanel")
	controls:Dock(TOP)
	controls:SetTall(32)
	controls:DockMargin(0, 0, 0, 10)
	controls.Paint = function() end
	local save = controls:Add("DButton")
	save:Dock(LEFT)
	save:SetWide(90)
	save:SetText(translate.Get("keys_save"))
	self:StyleShopButton(save, true, true)
	save.DoClick = function()
		local ok, reason, conflict = GAMEMODE:SaveZSKeyProfile(name:GetValue(), draft)
		if ok then RefreshProfiles() end
		Report(ok, reason, conflict)
	end
	local rename = controls:Add("DButton")
	rename:Dock(LEFT)
	rename:SetWide(90)
	rename:SetText(translate.Get("keys_rename"))
	self:StyleShopButton(rename, false, true)
	rename.DoClick = function()
		local ok, reason = GAMEMODE:RenameZSKeyProfile(chosen, name:GetValue())
		if ok then RefreshProfiles() end
		Report(ok, reason)
	end
	local import = controls:Add("DButton")
	import:Dock(LEFT)
	import:SetWide(130)
	import:SetText(translate.Get("keys_import"))
	panel.KeyImport = import
	self:StyleShopButton(import, false, true)
	import.DoClick = function()
		local ok, reason, report = GAMEMODE:ImportLegacyZSKeyProfile()
		if ok then
			for _, action in ipairs(GAMEMODE.ZSKeyActions) do draft[action.id] = GAMEMODE:GetZSKeyBinding(action.id) end
			RefreshProfiles() RefreshBinders()
			status:SetText(translate.Format("keys_legacy_imported", report.imported, report.rejected))
		else Report(false, reason) end
	end
	local engine = controls:Add("DButton")
	engine:Dock(FILL)
	engine:SetText(translate.Get("keys_engine_settings"))
	self:StyleShopButton(engine, false, true)
	engine.DoClick = function() RunGameUICommand("OpenOptionsDialog") end
	local scroll = panel:Add("DScrollPanel")
	scroll:Dock(FILL)
	local bar = scroll:GetVBar()
	bar:SetWide(8)
	bar:SetHideButtons(true)
	bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, GAMEMODE.ShopColors.row) end
	bar.btnGrip.Paint = function(control, width, height)
		draw.RoundedBox(4, 0, 0, width, height, control.Hovered and GAMEMODE.ShopColors.accent or GAMEMODE.ShopColors.muted)
	end
	for _, action in ipairs(self.ZSKeyActions) do
		local id = action.id
		local row = scroll:Add("DPanel")
		row:Dock(TOP)
		row:SetTall(58)
		row:DockMargin(0, 0, 0, 6)
		row:DockPadding(8, 4, 8, 4)
		row.Paint = function(_, width, height) draw.RoundedBox(5, 0, 0, width, height, GAMEMODE.ShopColors.row) end
		local label = row:Add("DLabel")
		label:Dock(TOP)
		label:SetText(translate.Get(action.label))
		label:SetFont("ZSMenuScaledBody")
		label:SetTextColor(color_white)
		local unbound = row:Add("DButton")
		unbound:Dock(RIGHT)
		unbound:SetWide(70)
		unbound:SetText(translate.Get("keys_clear"))
		self:StyleShopButton(unbound, false, true)
		unbound.DoClick = function() draft[id] = -1 RefreshBinders() end
		local defaults = row:Add("DButton")
		defaults:Dock(RIGHT)
		defaults:SetWide(70)
		defaults:SetText(translate.Get("keys_default"))
		self:StyleShopButton(defaults, false, true)
		defaults.DoClick = function() draft[id] = action.default RefreshBinders() end
		local binder = row:Add("DBinder")
		binder:Dock(RIGHT)
		binder:SetWide(100)
		self:StyleShopButton(binder, false, true)
		binder.Mode = row:Add("DLabel")
		binder.Mode:Dock(FILL)
		binder.Mode:SetFont("ZSMenuScaledSmall")
		binder.Mode:SetTextColor(self.ShopColors.muted)
		binders[id] = binder
		rows[#rows + 1] = {row, label, unbound, defaults, binder}
		binder.OnChange = function(_, code)
			if refreshing then return end
			local previous = draft[id]
			draft[id] = code > 0 and code or -1
			local valid, reason, conflict = GAMEMODE:CheckZSKeyBindings(draft)
			if not valid then draft[id] = previous Report(false, reason, conflict) end
			RefreshBinders()
		end
	end
	panel.ApplyKeyScale = function()
		panel:DockPadding(U(8), U(8), U(8), U(8))
		status:SetTall(U(36))
		profiles:SetTall(U(34)) profiles:DockMargin(0, 0, 0, U(6))
		name:SetTall(U(30)) name:DockMargin(0, 0, 0, U(6))
		load:SetWide(U(70))
		controls:SetTall(U(32)) controls:DockMargin(0, 0, 0, U(10))
		save:SetWide(U(90)) rename:SetWide(U(90)) import:SetWide(U(130))
		bar:SetWide(U(8))
		for _, entry in ipairs(rows) do
			entry[1]:SetTall(U(66)) entry[1]:DockMargin(0, 0, 0, U(6)) entry[1]:DockPadding(U(8), U(4), U(8), U(4))
			entry[2]:SetTall(U(24))
			entry[3]:SetWide(U(70)) entry[4]:SetWide(U(70)) entry[5]:SetWide(U(100))
		end
		panel:InvalidateLayout(true)
	end
	panel.ReloadKeyOptions = function()
		for _, action in ipairs(GAMEMODE.ZSKeyActions) do draft[action.id] = GAMEMODE:GetZSKeyBinding(action.id) end
		RefreshProfiles()
		RefreshBinders()
		status:SetText(translate.Get("keys_description"))
	end
	panel.KeyDraft, panel.KeyBinders = draft, binders
	panel.KeyProfileName, panel.KeyProfilePicker = name, picker
	panel.KeySave, panel.KeyRename, panel.KeyLoad, panel.KeyEngine = save, rename, load, engine
	panel.KeyStatus, panel.KeyScroll = status, scroll
	panel:ApplyKeyScale()
	panel:ReloadKeyOptions()
	if not parent then sheet:AddSheet(translate.Get("keys_title"), panel, "icon16/keyboard.png") end
	return panel
end

function GM:OpenKeySettings()
	self:RefreshMenuScale()
	if not IsValid(editor) then
		editor = vgui.Create("DFrame")
		self.ZSKeySettingsFrame = editor
		editor:SetTitle("")
		editor:ShowCloseButton(false)
		editor:SetDraggable(false)
		editor:SetDeleteOnClose(false)
		self:StyleShopFrame(editor)
		editor.Paint = function(panel, width, height)
			draw.RoundedBox(8, 0, 0, width, height, GAMEMODE.ShopColors.header)
			surface.SetDrawColor(GAMEMODE.ShopColors.accent)
			surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		editor.Heading = EasyLabel(editor, "", "ZSMenuScaledTitle", color_white)
		editor.Body = editor:Add("DPanel")
		self:AddKeyBindingOptions(nil, editor.Body)
		editor.CloseButton = editor:Add("DButton")
		self:StyleShopButton(editor.CloseButton, false, true)
		editor.CloseButton.DoClick = function(button) button:GetParent():Close() end
		editor.PerformLayout = function(panel, width, height)
			panel.Heading:SetPos(U(20), U(12)) panel.Heading:SetSize(width - U(40), U(32))
			panel.Body:SetPos(U(12), U(82)) panel.Body:SetSize(width - U(24), height - U(146))
			panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
		end
		editor.OnRemove = function(panel)
			if GAMEMODE.ZSKeySettingsFrame == panel then GAMEMODE.ZSKeySettingsFrame = nil end
			if editor == panel then editor = nil end
		end
	elseif not editor:IsVisible() then
		editor.Body:ReloadKeyOptions()
	end
	editor.Heading:SetText(translate.Get("keys_title"))
	editor.CloseButton:SetText(translate.Get("mm_close"))
	editor:SetSize(math.min(U(640), ScrW() - 24), math.min(U(660), ScrH() - 24))
	editor.Body:ApplyKeyScale()
	editor:Center()
	editor:SetVisible(true)
	editor:MakePopup()
	return editor
end

concommand.Add("zs_keysettings", function() GAMEMODE:OpenKeySettings() end)

hook.Add("OnScreenSizeChanged", "ZSKeySettingsLayout", function()
	if not IsValid(editor) then return end
	GAMEMODE:RefreshMenuScale()
	editor:SetSize(math.min(U(640), ScrW() - 24), math.min(U(660), ScrH() - 24))
	editor.Body:ApplyKeyScale()
	editor:Center()
	editor:InvalidateLayout(true)
end)
