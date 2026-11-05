local PANEL = {}
for name, method in pairs(vgui.GetControlTable("DColorMixer")) do
	if type(method) == "function" and name ~= "Init" then PANEL[name] = method end
end

local function EnsurePalette(self)
	if IsValid(self.Palette) then return self.Palette end
	local palette = vgui.Create("DColorPalette", self)
	self.Palette = palette
	palette:Dock(BOTTOM)
	palette:SetTall(75)
	palette:SetButtonSize(16)
	palette:Reset()
	palette:DockMargin(0, 8, 0, 0)
	palette:SetVisible(self:GetPalette() == true)
	palette.DoClick = function(_, color)
		self:SetColor(Color(color.r, color.g, color.b, self:GetAlphaBar() and color.a or 255))
	end
	palette.OnRightClickButton = function(control, button)
		local menu = DermaMenu()
		menu:AddOption("#spawnmenu.menu.save_palette", function() control:SaveColor(button, self:GetColor()) end):SetIcon("icon16/disk.png")
		menu:AddOption("#spawnmenu.menu.reset_palette", function() control:ResetSavedColors() end):SetIcon("icon16/arrow_rotate_clockwise.png")
		menu:Open()
	end
	return palette
end

function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
	self.label:SetText("")
	self.label:Dock(TOP)
	self.label:SetDark(true)
	self.label:SetVisible(false)
	self.WangsPanel = vgui.Create("DPanel", self)
	self.WangsPanel:SetWide(50)
	self.WangsPanel:Dock(RIGHT)
	self.WangsPanel:DockMargin(4, 0, 0, 0)
	for _, channel in ipairs({"R", "G", "B", "A"}) do
		local control = vgui.Create("DNumberWang", self.WangsPanel)
		self["txt" .. channel] = control
		control:SetDecimals(0)
		control:SetMinMax(0, 255)
		control:SetTall(20)
		control:Dock(TOP)
		control:DockMargin(0, channel == "R" and 0 or 4, 0, 0)
		control:SetTextColor(channel == "R" and Color(150, 0, 0) or channel == "G" and Color(0, 150, 0) or channel == "B" and Color(0, 0, 150) or Color(80, 80, 80))
		local key = string.lower(channel)
		control.OnValueChanged = function(panel, value)
			if panel.notuserchange then return end
			local color = self:GetColor()
			color[key] = math.Clamp(tonumber(value) or 0, 0, 255)
			self:SetColor(color)
		end
	end
	self.HSV = vgui.Create("DColorCube", self)
	self.HSV:Dock(FILL)
	self.HSV.OnUserChanged = function(_, color)
		color.a = self:GetColor().a
		self:UpdateColor(color)
	end
	self.RGB = vgui.Create("DRGBPicker", self)
	self.RGB:Dock(RIGHT)
	self.RGB:SetWide(26)
	self.RGB:DockMargin(4, 0, 0, 0)
	self.RGB.OnChange = function(_, color) self:SetBaseColor(color) end
	self.Alpha = vgui.Create("DAlphaBar", self)
	self.Alpha:Dock(RIGHT)
	self.Alpha:SetWide(26)
	self.Alpha:DockMargin(4, 0, 0, 0)
	self.Alpha.OnChange = function(_, value)
		local color = self:GetColor()
		color.a = math.floor(value * 255)
		self:UpdateColor(color)
	end
	self:SetWangs(true)
	self:SetAlphaBar(false)
	self:SetPalette(false)
	self:SetColor(Color(255, 0, 0, 255))
	self:SetSize(256, 144)
	self.NextConVarCheck = 0
end

function PANEL:SetPalette(enabled)
	self.m_bPalette = enabled == true
	if self.m_bPalette then EnsurePalette(self) end
	if IsValid(self.Palette) then self.Palette:SetVisible(self.m_bPalette) end
	self:InvalidateLayout()
end

function PANEL:SetPaletteName(name)
	local palette = EnsurePalette(self)
	palette:SetCookieName(name)
	palette:Reset()
end

function PANEL:ApplyMenuScale()
	local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
	self.WangsPanel:SetWide(U(65))
	self.WangsPanel:DockMargin(U(4), 0, 0, 0)
	for _, channel in ipairs({"R", "G", "B", "A"}) do
		local control = self["txt" .. channel]
		control:SetFont("ZSMenuScaledBody")
		if control.ApplySchemeSettings then control:ApplySchemeSettings() end
		control:SetTall(U(24))
		control:DockMargin(0, channel == "R" and 0 or U(4), 0, 0)
	end
	for _, control in ipairs({self.RGB, self.Alpha}) do
		control:SetWide(U(26))
		control:DockMargin(U(4), 0, 0, 0)
	end
	self:InvalidateLayout(true)
end

function PANEL:PerformLayout(width)
	local hue = ColorToHSV(self.HSV:GetBaseRGB())
	self.RGB.LastY = (1 - hue / 360) * self.RGB:GetTall()
	local palette = self.Palette
	if not IsValid(palette) or not self:GetPalette() then return end
	local count, size = #palette:GetChildren(), palette:GetButtonSize()
	if count == 0 or width < size then return end
	local rows = math.ceil(count / math.floor(width / size))
	local padding = math.floor((width - math.ceil(count / rows) * size) * 0.5)
	palette:DockMargin(padding, 8, padding, 0)
end

vgui.Register("ZSOptionsColorMixer", PANEL, "DPanel")
