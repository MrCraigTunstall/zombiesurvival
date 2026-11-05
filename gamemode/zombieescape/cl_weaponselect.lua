CreateClientConVar("zs_zeweapon", "", true, true)
local descriptions = {
	weapon_zs_zeakbar = "ze_weapon_akbar_detail", weapon_zs_zesweeper = "ze_weapon_sweeper_detail",
	weapon_zs_zesmg = "ze_weapon_smg_detail", weapon_zs_zestubber = "ze_weapon_stubber_detail",
	weapon_zs_zebulletstorm = "ze_weapon_bulletstorm_detail"
}
local colors = GM.ShopColors
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local function WrapZEText(text, width, font)
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


local function Choose(self)
	if RealTime() < (self.ZSNextChoice or 0) then return end
	self.ZSNextChoice = RealTime() + 0.5
	RunConsoleCommand("zs_zeweapon_select", self.WeaponClass)
end

local function PaintRow(self, width, height)
	draw.RoundedBox(5, 0, 0, width, height, self.Selected and colors.selected or self.Hovered and colors.hover or colors.row)
	if self.Selected then surface.SetDrawColor(colors.accent) surface.DrawRect(0, U(10), U(3), height - U(20)) end
end

local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
	GAMEMODE:RefreshMenuScale()
	local width, height = math.min(U(660), screenWidth - 24), math.min(U(640), screenHeight - 24)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
	if frame.LayoutWidth == width and frame.LayoutHeight == height then
  if screenChanged then frame:Center()end
  return
 end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	frame:SetSize(width, height)
	frame:Center()
	frame.Title:SetPos(U(16), U(12)) frame.Title:SetSize(width - U(68), U(28))
	frame.CloseButton:SetPos(width - U(44), U(12)) frame.CloseButton:SetSize(U(28), U(28))
	frame.Help:SetPos(U(16), U(78)) frame.Help:SetSize(width - U(32), U(62))
	frame.List:SetPos(U(16), U(146)) frame.List:SetSize(width - U(32), height - U(210))
	frame.Status:SetPos(U(16), height - U(56)) frame.Status:SetSize(width - U(32), U(40))
	frame.List:GetVBar():SetWide(U(16))
	for _, row in ipairs(frame.Rows) do row:DockMargin(0, 0, 0, U(8)) row:InvalidateLayout(true) end
end

local function Populate(gm, frame)
	frame.List:Clear()
	frame.Rows = {}
	for _, class in ipairs(gm.ZombieEscapeWeapons) do
		local definition = weapons.Get(class)
		if definition then
			local row = frame.List:Add("DButton")
			row:Dock(TOP) row:DockMargin(0, 0, 0, U(8)) row:SetTall(U(108)) row:SetText("")
			row.WeaponClass, row.DoClick, row.Paint = class, Choose, PaintRow
			local title = row:Add("DLabel")
			title:SetWrap(false)
			title:SetFont("ZSMenuScaledBody") title:SetTextColor(color_white) title:SetText(definition.PrintName or class)
			local detail = row:Add("DLabel")
			detail:SetWrap(false)
			detail:SetFont("ZSMenuScaledSmall") detail:SetTextColor(colors.muted)
			detail:SetText(descriptions[class] and translate.Get(descriptions[class]) or definition.Description or translate.Get("ze_weapon_custom_detail"))
			local stats = row:Add("DLabel")
			stats:SetWrap(false)
			stats:SetFont("ZSMenuScaledSmall") stats:SetTextColor(colors.accent)
			local primary = definition.Primary or {}
			stats:SetText(translate.Format("ze_weapon_stats", tostring(primary.Damage or "?"), tostring(primary.ClipSize or "?")))
			row.Title, row.Detail, row.Stats = title, detail, stats
			local texts = {title:GetText(), detail:GetText(), stats:GetText()}
			for _, label in ipairs({title, detail, stats}) do label:SetMouseInputEnabled(false) end
			row.PerformLayout = function(panel, width)
				local scale = GAMEMODE.MenuScale
				if panel.LayoutWidth == width and panel.LayoutScale == scale then return end
				panel.LayoutWidth, panel.LayoutScale = width, scale
				local y = U(9)
				for index, label in ipairs({title, detail, stats}) do
					local usable = math.max(1, width - U(28))
					local text, height = WrapZEText(texts[index], usable, label:GetFont())
					label:SetPos(U(14), y) label:SetSize(usable, height)
					if label.ZSWrappedText ~= text then label.ZSWrappedText = text label:SetText(text) end
					y = y + label:GetTall() + U(index == 1 and 2 or 3)
				end
				panel:SetTall(math.max(U(108), y + U(9)))
			end
			frame.Rows[#frame.Rows + 1] = row
		end
	end
	frame.LanguageRevision = translate.GetRevision()
end

local function Update(frame)
	if not frame:IsVisible() then return end
	local now = RealTime()
	if now < (frame.NextUpdate or 0) then return end
	frame.NextUpdate = now + 0.1
	local gm, pl = GAMEMODE, LocalPlayer()
	if not gm.ZombieEscape or not IsValid(pl) or pl:Team() ~= TEAM_HUMAN then frame:Close() return end
	if frame.LanguageRevision ~= translate.GetRevision() then
		Populate(gm, frame)
		frame.Title:SetText(translate.Get("ze_weapon_menu"))
		frame.Help:SetText(translate.Get("ze_weapon_help_shortcuts"))
		frame.CloseButton:SetTooltip(translate.Get("ze_weapon_close"))
		frame.State = nil
	end
	local weapon = pl:GetActiveWeapon()
	local preference = GetConVar("zs_zeweapon"):GetString()
	local current = IsValid(weapon) and weapon:GetClass() or ""
	for _, row in ipairs(frame.Rows) do row.Selected = row.WeaponClass == preference or preference == "" and row.WeaponClass == current end
	local state = not pl:Alive() or gm:GetWave() ~= 0 or gm:GetWaveActive()
	local key = state and "ze_weapon_choose_future" or "ze_weapon_choose_now"
	if frame.State ~= key then frame.State = key frame.Status:SetText(translate.Get(key)) end
end

function GM:OpenZombieEscapeWeapons()
	self:RefreshMenuScale()
	local pl = LocalPlayer()
	if not self.ZombieEscape or not IsValid(pl) or pl:Team() ~= TEAM_HUMAN then return end
	local frame = self.ZEWeaponMenu
	if not IsValid(frame) then
		frame = vgui.Create("DFrame") self.ZEWeaponMenu = frame
		frame:SetVisible(false)
		frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
		self:StyleShopFrame(frame)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(8, 0, 0, width, height, colors.background)
			draw.RoundedBox(8, 0, 0, width, U(72), colors.header)
			surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		frame.Title = frame:Add("DLabel") frame.Title:SetFont("ZSMenuScaledTitle") frame.Title:SetTextColor(color_white)
		frame.Help = frame:Add("DLabel") frame.Help:SetFont("ZSMenuScaledBody") frame.Help:SetTextColor(colors.muted) frame.Help:SetWrap(true)
		frame.Status = frame:Add("DLabel") frame.Status:SetFont("ZSMenuScaledSmall") frame.Status:SetTextColor(colors.accent) frame.Status:SetWrap(true)
		frame.List = frame:Add("DScrollPanel")
		local bar = frame.List:GetVBar()
		bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, colors.row) end
		for _, control in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
			control.Paint = function(panel, width, height) draw.RoundedBox(4, 0, 0, width, height, panel:IsHovered() and colors.accent or colors.muted) end
		end
		frame.CloseButton = frame:Add("DButton") frame.CloseButton:SetText("X") self:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.Think = Update
		Populate(self, frame)
		frame.Title:SetText(translate.Get("ze_weapon_menu")) frame.Help:SetText(translate.Get("ze_weapon_help_shortcuts"))
		frame.CloseButton:SetTooltip(translate.Get("ze_weapon_close"))
	end
	Layout(frame) frame.NextUpdate = nil
	if frame:IsVisible() then Update(frame) return frame end
	frame:SetVisible(true) frame:MakePopup() frame:SetKeyboardInputEnabled(false)
	Update(frame)
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSZEWeaponMenu", function()
	local frame = GAMEMODE and GAMEMODE.ZEWeaponMenu
	if IsValid(frame) then Layout(frame) end
end)

net.Receive("zs_zeweapon_result", function()
	local ok, reason, class = net.ReadBool(), net.ReadString(), net.ReadString()
	if ok then
		RunConsoleCommand("zs_zeweapon", class)
		if IsValid(GAMEMODE.ZEWeaponMenu) then GAMEMODE.ZEWeaponMenu:Close() end
	end
	GAMEMODE:CenterNotify(ok and COLOR_GREEN or COLOR_RED, translate.Get(reason))
end)
