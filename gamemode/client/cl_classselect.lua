CreateClientConVar("zs_bossclass", "", true, true)
if IsValid(GM.ClassMenu) then GM.ClassMenu:Remove() GM.ClassMenu = nil end
local colors = GM.ShopColors
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local lockedColor = Color(235, 166, 99)
local background = Color(15, 20, 26)
local classFields = {"Index", "Name", "TranslationName", "Description", "Help", "Health", "Speed", "SWEP", "Icon", "Boss", "SuperBoss"}

local function CaptureClass(entry)
	local class = entry.class
	entry.values = {}
	for index, field in ipairs(classFields) do entry.values[index] = class[field] end
	local weapon = class.SWEP and weapons.GetStored(class.SWEP)
	entry.weapon, entry.damage, entry.pounce, entry.force = weapon, weapon and weapon.MeleeDamage, weapon and weapon.PounceDamage, weapon and weapon.PhysicsForce
	return weapon
end

local function ClassCurrent(entry)
	for index, field in ipairs(classFields) do if entry.values[index] ~= entry.class[field] then return false end end
	local weapon = entry.class.SWEP and weapons.GetStored(entry.class.SWEP)
	return weapon == entry.weapon and (weapon and weapon.MeleeDamage) == entry.damage and (weapon and weapon.PounceDamage) == entry.pounce and (weapon and weapon.PhysicsForce) == entry.force
end

local function CatalogueChanged(frame, now, force)
	local gm = GAMEMODE
	if frame.CatalogueDirty or frame.Source ~= gm.ZombieClasses or frame.SourceSize ~= #gm.ZombieClasses or frame.LanguageRevision ~= (translate.GetRevision and translate.GetRevision()) then return true end
	if not force and now < (frame.NextCatalogueCheck or 0) then return false end
	local count = 0
	for index, class in ipairs(gm.ZombieClasses) do
		if index == class.Index then
			count = count + 1
			local entry = frame.Entries[index]
			if not entry or entry.class ~= class or not ClassCurrent(entry) then frame.CatalogueDirty = true return true end
		end
	end
	if count ~= #frame.Rows then frame.CatalogueDirty = true return true end
	frame.NextCatalogueCheck = now + 1
	return false
end

local function ClassStats(class, weapon)
	local parts = {translate.Format("classes_hp_x", class.Health or "?"), translate.Format("classes_speed_x", class.Speed or "?")}
	if weapon then
		local damage = weapon.MeleeDamage or weapon.PounceDamage
		if damage then parts[#parts + 1] = translate.Format("classes_dmg_x", damage)
		elseif weapon.PhysicsForce then parts[#parts + 1] = translate.Format("classes_force_x", weapon.PhysicsForce) end
	end
	return table.concat(parts, "   •   ")
end

function GM:BuildClassMenuEntries()
	local entries = {}
	for index, class in ipairs(self.ZombieClasses) do
		if index == class.Index then
			local name = translate.Get(class.TranslationName or class.Name)
			local description = class.Description and translate.Get(class.Description) or ""
			local help = class.Help and translate.Get(class.Help) or ""
			local entry = {class = class, name = name, description = description, help = help,
				search = string.lower(name .. " " .. description .. " " .. help),
				icon = class.Icon and Material(class.Icon, "noclamp")}
			entry.stats = ClassStats(class, CaptureClass(entry)) entries[#entries + 1] = entry
		end
	end
	table.sort(entries, function(a, b)
		local aSuper, bSuper = a.class.SuperBoss and true or false, b.class.SuperBoss and true or false
		if aSuper ~= bSuper then return not aSuper end
		return a.class.Index < b.class.Index
	end)
	return entries
end

function GM:GetClassMenuState(pl, class, bossmode, context)
	if not IsValid(pl) or pl:Team() ~= TEAM_UNDEAD then return false, false, "", false end
	local visible = bossmode and class.Boss or not bossmode and not class.Boss
	if visible and class.Hidden and not bossmode then visible = class.CanUse and class:CanUse(pl) or false end
	if not visible then return false, false, "", false end
	if bossmode then
		if class.SuperBoss then return true, false, translate.Get("classes_round_assigned"), false end
		local preference = context and context.preference or string.lower(GetConVarString("zs_bossclass"))
		local selected = preference == string.lower(class.Name)
		return true, true, translate.Get(selected and "classes_preferred_boss" or "classes_choose_boss"), selected
	end
	local current = (context and context.current or pl:GetZombieClass()) == class.Index
	local unlocked = gamemode.Call("IsClassUnlocked", class.Index) and true or false
	local status = current and translate.Get("classes_current") or unlocked and translate.Get("classes_available")
		or class.Locked and translate.Get("classes_unavailable") or translate.Format("unlocked_on_wave_x", class.Wave or 0)
	return true, unlocked, status, current
end

local function SetText(label, text)
	if label.ZSClassText ~= text then label.ZSClassText = text label:SetText(text) end
end

local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
	GAMEMODE:RefreshMenuScale()
	local width, height = math.min(screenWidth - 32, U(960)), math.min(screenHeight - 32, U(720))
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
	if frame.LayoutWidth == width and frame.LayoutHeight == height then
  if screenChanged then frame:Center()end
  return
 end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	frame:SetSize(width, height) frame:Center()
	frame.Title:SetPos(U(20), U(14)) frame.Title:SetSize(width - U(80), U(28))
	frame.Subtitle:SetPos(U(20), U(44)) frame.Subtitle:SetSize(width - U(40), U(22))
	frame.CloseButton:SetPos(width - U(50), U(16)) frame.CloseButton:SetSize(U(30), U(30))
	local tabWidth = (width - U(56)) / 3
	for index, button in ipairs(frame.Tabs) do button:SetPos(U(20) + (index - 1) * (tabWidth + U(8)), U(84)) button:SetSize(tabWidth, U(34)) end
	frame.Search:SetPos(U(20), U(128)) frame.Search:SetSize(width - U(40), U(30))
	frame.List:SetPos(U(20), U(168)) frame.List:SetSize(width - U(40), height - U(204))
	frame.Empty:SetPos(U(20), U(180)) frame.Empty:SetSize(width - U(40), U(38))
	frame.Footer:SetPos(U(20), height - U(28)) frame.Footer:SetSize(width - U(40), U(20))
	frame.List:GetVBar():SetWide(U(16))
	if frame.LayoutScale ~= GAMEMODE.MenuScale then
		frame.LayoutScale = GAMEMODE.MenuScale
		for _, row in ipairs(frame.Rows) do
			row:SetTall(U(170)) row:DockMargin(0, 0, 0, U(8))
			row.DescriptionHeight, row.HelpHeight, row.LayoutWidth = nil, nil, nil
			row:InvalidateLayout(true)
		end
	end
end

local function Label(parent, font, color)
	local label = parent:Add("DLabel") label:SetFont(font) label:SetTextColor(color) label:SetText("")
	return label
end

local function CreateRow(frame, entry)
	local row = frame.List:Add("DButton")
	row.Entry = entry row:SetText("") row:SetTall(U(170)) row:Dock(TOP) row:DockMargin(0, 0, 0, U(8))
	row:SetTooltip(entry.name .. "\n" .. entry.description .. "\n" .. entry.help)
	if row.SetTooltipPanelOverride then row:SetTooltipPanelOverride("ZSShopTooltip") end
	row.NameLabel = Label(row, "ZSMenuScaledBody", color_white)
	row.StatusLabel = Label(row, "ZSMenuScaledSmall", colors.accent)
	row.StatsLabel = Label(row, "ZSMenuScaledSmall", colors.muted)
	row.DescriptionLabel = Label(row, "ZSMenuScaledSmall", colors.muted) row.DescriptionLabel:SetWrap(true)
	row.HelpLabel = Label(row, "ZSMenuScaledSmall", color_white) row.HelpLabel:SetWrap(true)
	for _, label in ipairs({row.NameLabel, row.StatusLabel, row.StatsLabel, row.DescriptionLabel, row.HelpLabel}) do label:SetMouseInputEnabled(false) end
	SetText(row.NameLabel, entry.name) SetText(row.StatsLabel, entry.stats)
	SetText(row.DescriptionLabel, entry.description) SetText(row.HelpLabel, entry.help)
	row.PerformLayout = function(self, width)
		local x, usable = U(88), width - U(104)
		self.NameLabel:SetPos(x, U(12)) self.NameLabel:SetSize(usable, U(22))
		self.StatusLabel:SetPos(x, U(36)) self.StatusLabel:SetSize(usable, U(18))
		self.StatsLabel:SetPos(x, U(58)) self.StatsLabel:SetSize(usable, U(18))
		self.DescriptionLabel:SetPos(x, U(82)) self.DescriptionLabel:SetSize(usable, self.DescriptionHeight or U(48))
		self.HelpLabel:SetPos(x, U(90) + (self.DescriptionHeight or U(48))) self.HelpLabel:SetSize(usable, self.HelpHeight or U(28))
		if self.LayoutWidth ~= width then
			self.LayoutWidth = width self.NeedsMeasure = true
			self.DescriptionLabel:InvalidateLayout(true) self.HelpLabel:InvalidateLayout(true)
		end
	end
	row.HelpLabel.PaintOver = function()
		if not row.NeedsMeasure then return end
		row.NeedsMeasure = nil
		row.DescriptionLabel:SizeToContentsY() row.HelpLabel:SizeToContentsY()
		row.DescriptionHeight, row.HelpHeight = row.DescriptionLabel:GetTall(), row.HelpLabel:GetTall()
		row:SetTall(math.max(U(120), U(106) + row.DescriptionHeight + row.HelpHeight)) row:InvalidateLayout(true)
	end
	row.Paint = function(self, width, height)
		draw.RoundedBox(6, 0, 0, width, height, self.Selected and colors.selected or self:IsHovered() and colors.hover or colors.row)
		if entry.icon then
			surface.SetDrawColor(self.Allowed and color_white or colors.muted) surface.SetMaterial(entry.icon)
			surface.DrawTexturedRect(U(12), U(14), U(60), U(60))
		end
	end
	row.DoClick = function(self)
		if GAMEMODE.ZombieClasses[entry.class.Index] ~= entry.class or not ClassCurrent(entry) then frame.CatalogueDirty = true GAMEMODE:OpenClassSelect(frame.BossMode) return end
		local visible, allowed = GAMEMODE:GetClassMenuState(LocalPlayer(), entry.class, frame.BossMode)
		if not visible or not allowed then return end
		if frame.BossMode then
			RunConsoleCommand("zs_bossclass", entry.class.Name)
			GAMEMODE:CenterNotify(translate.Format("boss_class_select", entry.name))
		else
			RunConsoleCommand("zs_class", entry.class.Name, GAMEMODE.SuicideOnChangeClass and "1" or "0")
		end
		surface.PlaySound("buttons/button15.wav") frame:Close()
	end
	return row
end

local function Refresh(frame)
	if not frame:IsVisible() then return end
	local now = RealTime()
	if now < (frame.NextRefresh or 0) then return end
	frame.NextRefresh = now + 0.2
	local pl, query, count = LocalPlayer(), string.lower(frame.Search:GetValue()), 0
	if not IsValid(pl) or pl:Team() ~= TEAM_UNDEAD then frame:Close() return end
	if CatalogueChanged(frame, now) then GAMEMODE:OpenClassSelect(frame.BossMode) return end
	local context = frame.StateContext
	if frame.BossMode then context.preference = string.lower(GetConVarString("zs_bossclass")) else context.current = pl:GetZombieClass() end
	if frame.LastBossMode ~= frame.BossMode then
		frame.LastBossMode = frame.BossMode
		GAMEMODE:StyleShopButton(frame.Tabs[1], not frame.BossMode, true)
		GAMEMODE:StyleShopButton(frame.Tabs[2], frame.BossMode, true)
	end
	for _, row in ipairs(frame.Rows) do
		local entry = row.Entry
		local visible, allowed, status, selected = GAMEMODE:GetClassMenuState(pl, entry.class, frame.BossMode, context)
		visible = visible and (query == "" or string.find(entry.search, query, 1, true) ~= nil) and true or false
		if row.Shown ~= visible then row.Shown = visible row:SetVisible(visible) frame.List:InvalidateLayout() end
		if visible then
			count = count + 1 row.Selected = selected
			if row.Allowed ~= allowed then row.Allowed = allowed row:SetEnabled(allowed) row.StatusLabel:SetTextColor(allowed and colors.accent or lockedColor) end
			SetText(row.StatusLabel, status)
		end
	end
	if frame.EmptyShown ~= (count == 0) then frame.EmptyShown = count == 0 frame.Empty:SetVisible(frame.EmptyShown) end
	SetText(frame.Footer, translate.Format("classes_count", count))
	SetText(frame.Subtitle, translate.Get(frame.BossMode and "classes_boss_help" or "classes_chooseresawn"))
end

function GM:OpenClassSelect(bossmode)
	self:RefreshMenuScale()
	local pl = LocalPlayer()
	if not IsValid(pl) or pl:Team() ~= TEAM_UNDEAD then return end
	local revision = translate.GetRevision and translate.GetRevision()
	local frame = self.ClassMenu
	local query, scroll
	if IsValid(frame) and CatalogueChanged(frame, RealTime(), not frame:IsVisible()) then
		query, scroll = frame.Search:GetValue(), frame.List:GetVBar():GetScroll()
		frame:Remove() frame = nil
	end
	if IsValid(frame) and frame:IsVisible() and frame.BossMode == not not bossmode then return frame end
	if not IsValid(frame) then
		frame = vgui.Create("DFrame") self.ClassMenu = frame
		frame.Source, frame.SourceSize, frame.LanguageRevision = self.ZombieClasses, #self.ZombieClasses, revision
		frame.NextCatalogueCheck = RealTime() + 1
		frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDeleteOnClose(false) frame:SetDraggable(false)
		self:StyleShopFrame(frame)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(8, 0, 0, width, height, background)
			surface.SetDrawColor(colors.accent) surface.DrawRect(0, U(72), width, U(2))
		end
		frame.Title = Label(frame, "ZSMenuScaledTitle", color_white) SetText(frame.Title, translate.Get("classes_undeadclasses"))
		frame.Subtitle = Label(frame, "ZSMenuScaledSmall", colors.muted)
		frame.CloseButton = frame:Add("DButton") frame.CloseButton:SetText("X") self:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton:SetTooltip(translate.Get("close")) frame.CloseButton.DoClick = function() frame:Close() end
		frame.Tabs = {}
		for index, key in ipairs({"classes_normal_tab", "classes_boss_tab", "mutations_selection"}) do
			local button = frame:Add("DButton") button:SetText(translate.Get(key)) self:StyleShopButton(button, false, true)
			button.DoClick = function()
				if index == 3 then frame:Close() RunConsoleCommand("zs_keyaction", "shop") return end
				frame.BossMode = index == 2 frame.NextRefresh = nil
				frame.List:GetVBar():SetScroll(0) Refresh(frame)
			end
			frame.Tabs[index] = button
		end
		frame.Search = frame:Add("DTextEntry") frame.Search:SetFont("ZSMenuScaledBody") frame.Search:SetPlaceholderText(translate.Get("classes_search"))
		frame.Search:SetTextColor(color_white) frame.Search:SetHighlightColor(colors.selected) frame.Search:SetCursorColor(colors.accent)
		frame.Search.Paint = function(control, width, height)
			draw.RoundedBox(5, 0, 0, width, height, colors.row)
			control:DrawTextEntryText(color_white, colors.selected, colors.accent)
			if control:GetValue() == "" and not control:HasFocus() then draw.SimpleText(control:GetPlaceholderText(), "ZSMenuScaledBody", U(5), height / 2, colors.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
		end
		frame.Search.OnValueChange = function() frame.NextRefresh = nil frame.List:GetVBar():SetScroll(0) Refresh(frame) end
		frame.List = frame:Add("DScrollPanel")
		local bar = frame.List:GetVBar()
		bar.Paint = function(_, width, height) surface.SetDrawColor(colors.row) surface.DrawRect(0, 0, width, height) end
		for _, button in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			if IsValid(button) then button.Paint = function(control, width, height) draw.RoundedBox(4, 0, 0, width, height, control:IsHovered() and colors.hover or colors.muted) end end
		end
		frame.Empty = Label(frame, "ZSMenuScaledBody", colors.muted) SetText(frame.Empty, translate.Get("classes_empty")) frame.Empty:SetWrap(true)
		frame.Footer = Label(frame, "ZSMenuScaledSmall", colors.muted)
		frame.Rows, frame.Entries, frame.StateContext = {}, {}, {}
		for index, entry in ipairs(self:BuildClassMenuEntries()) do
			local row = CreateRow(frame, entry) row:SetZPos(index) frame.Rows[index] = row
			frame.Entries[entry.class.Index] = entry
		end
		frame.Think = Refresh
		frame.OnRemove = function(self)
			if GAMEMODE.ClassMenu == self then GAMEMODE.ClassMenu = nil end
			self.Rows, self.Entries, self.Source, self.StateContext = nil, nil, nil, nil
		end
	end
	if query then frame.Search:SetText(query) end
	frame.BossMode = bossmode and true or false frame.NextRefresh = nil
	Layout(frame) frame:SetVisible(true) frame:MakePopup() frame.List:GetVBar():SetScroll(0) Refresh(frame)
	if scroll and scroll > 0 then
		local list = frame.List
		list:GetCanvas():InvalidateLayout(true) list:InvalidateLayout(true)
		list:GetVBar():SetScroll(scroll)
	end
	return frame
end

function MakepClassSelect(bossmode)
	return GAMEMODE:OpenClassSelect(bossmode)
end

hook.Add("OnScreenSizeChanged", "ZSClassMenuLayout", function()
	local frame = GAMEMODE and GAMEMODE.ClassMenu
	if IsValid(frame) then Layout(frame) end
end)
