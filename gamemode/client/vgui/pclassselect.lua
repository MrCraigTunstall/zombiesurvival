CreateClientConVar("zs_bossclass", "", true, true)

local Window
local HoveredClassWindow

local function CreateHoveredClassWindow(classtable)
	if HoveredClassWindow and HoveredClassWindow:Valid() then
		HoveredClassWindow:Remove()
	end

	HoveredClassWindow = vgui.Create("ClassInfo")
	HoveredClassWindow:SetSize(ScrW() * 0.8, 256)
	HoveredClassWindow:CenterHorizontal()
	HoveredClassWindow:MoveBelow(Window, 32)
	HoveredClassWindow:SetClassTable(classtable)
end

function GM:OpenClassSelect(bossmode)
	if Window and Window:Valid() then Window:Remove() end

	Window = vgui.Create(bossmode and "ClassSelectBoss" or "ClassSelect")
	Window:SetSize(ScrW(), 560)
	Window:Center()

	Window:SetAlpha(0)
	Window:AlphaTo(255, 0.75)

	Window:MakePopup()

	PlayMenuOpenSound()
end

local PANEL = {}

local function BossTypeDoClick(self)
	GAMEMODE:OpenClassSelect(true)
end

function PANEL:Init()
	self.ClassButtons = {}

	for i = 1, #GAMEMODE.ZombieClasses do
		local classtab = GAMEMODE.ZombieClasses[i]
		if classtab and not classtab.Hidden or classtab.CanUse and classtab:CanUse(MySelf) then
			local button = vgui.Create("ClassButton", self)
			button:SetClassTable(classtab)

			table.insert(self.ClassButtons, button)
		end
	end

	local button = EasyButton(self, translate.Get("boss_selection"), 120, 10)
	self.ClassTypeButton = button
	button.DoClick = BossTypeDoClick
	self.ClassTypeButton:SetFont("ZSHUDFontSmall") 
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local NumButtonRow = 12
	local NumButtonTotal = #self.ClassButtons
	local NumButtonRemainder = NumButtonTotal % NumButtonRow
	local SpacingHorizontal = self:GetWide() / NumButtonRow
	local SpacingHorizontalRem = self:GetWide() / NumButtonRemainder
	local SpacingVertical = self:GetTall()/ math.max(1, math.ceil(NumButtonTotal/NumButtonRow))
 
	for i, classbutton in ipairs(self.ClassButtons) do
		if((NumButtonTotal - i) >= NumButtonRemainder) then
			classbutton:SetSize(SpacingHorizontal, SpacingVertical)
			classbutton:SetPos(((i-1) % NumButtonRow) * SpacingHorizontal + SpacingHorizontal * 0.4 - classbutton:GetWide() * 0.4, SpacingVertical * math.floor(i/(NumButtonRow + 1)))
		else
			classbutton:SetSize(SpacingHorizontalRem, SpacingVertical)
			classbutton:SetPos(((i-1) % NumButtonRow) * SpacingHorizontalRem + SpacingHorizontalRem * 0.4 - classbutton:GetWide() * 0.4, SpacingVertical * math.floor(i/(NumButtonRow + 1)))
		end
	end

	self.ClassTypeButton:CenterHorizontal()
	self.ClassTypeButton:AlignTop(4)
end

local texUpEdge = surface.GetTextureID("gui/gradient_up")
local texDownEdge = surface.GetTextureID("gui/gradient_down")
function PANEL:Paint()
	local wid, hei = self:GetSize()
	local edgesize = 32

	DisableClipping(true)
	surface.SetDrawColor(color_black_alpha220)
	surface.DrawRect(0, 0, wid, hei)
	surface.SetTexture(texUpEdge)
	surface.DrawTexturedRect(0, -edgesize, wid, edgesize)
	surface.SetTexture(texDownEdge)
	surface.DrawTexturedRect(0, hei, wid, edgesize)
	DisableClipping(false)

	return true
end

vgui.Register("ClassSelect", PANEL, "Panel")

local PANEL = {}

local function ClassTypeDoClick(self)
	GAMEMODE:OpenClassSelect(false)
end

function PANEL:Init()
	self.ClassButtons = {}

	for i = 1, #GAMEMODE.ZombieClasses do
		local classtab = GAMEMODE.ZombieClasses[i]
		if classtab and classtab.Boss then
			local button = vgui.Create("ClassButton", self)
			button:SetClassTable(classtab)

			table.insert(self.ClassButtons, button)
		end
	end

	local button = EasyButton(self, translate.Get("normal_selection"), 120, 10)
	self.ClassTypeButton = button
	button.DoClick = ClassTypeDoClick
	self.ClassTypeButton:SetFont("ZSHUDFontSmall")
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local NumButtonRow = 12
	local NumButtonTotal = #self.ClassButtons
	local NumButtonRemainder = NumButtonTotal % NumButtonRow
	local SpacingHorizontal = self:GetWide() / NumButtonRow
	local SpacingHorizontalRem = self:GetWide() / NumButtonRemainder
	local SpacingVertical = self:GetTall()/ math.max(1, math.ceil(NumButtonTotal/NumButtonRow))
 
	for i, classbutton in ipairs(self.ClassButtons) do
		if((NumButtonTotal - i) >= NumButtonRemainder) then
			classbutton:SetSize(SpacingHorizontal, SpacingVertical)
			classbutton:SetPos(((i-1) % NumButtonRow) * SpacingHorizontal + SpacingHorizontal * 0.5 - classbutton:GetWide() * 0.5, SpacingVertical * math.floor(i/(NumButtonRow + 1)))
		else
			classbutton:SetSize(SpacingHorizontalRem, SpacingVertical)
			classbutton:SetPos(((i-1) % NumButtonRow) * SpacingHorizontalRem + SpacingHorizontalRem * 0.5 - classbutton:GetWide() * 0.5, SpacingVertical * math.floor(i/(NumButtonRow + 1)))
		end
	end

	self.ClassTypeButton:AlignLeft(4)
	self.ClassTypeButton:AlignTop(4)
end

function PANEL:Paint()
	local wid, hei = self:GetSize()
	local edgesize = 32

	DisableClipping(true)
	surface.SetDrawColor(color_black_alpha220)
	surface.DrawRect(0, 0, wid, hei)
	surface.SetTexture(texUpEdge)
	surface.DrawTexturedRect(0, -edgesize, wid, edgesize)
	surface.SetTexture(texDownEdge)
	surface.DrawTexturedRect(0, hei, wid, edgesize)
	DisableClipping(false)
end

vgui.Register("ClassSelectBoss", PANEL, "Panel")

local PANEL = {}

function PANEL:Init()
	self.NameLabel = vgui.Create("DLabel", self)
	self.NameLabel:SetFont("ZSHUDFontTiny")
	self.NameLabel:SetAlpha(255)
	self.Image = vgui.Create("DImage", self)

	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local imgsize = math.min(self:GetWide(), self:GetTall()) * 0.75
	self.Image:SetSize(imgsize, imgsize)
	self.Image:Center()

	self.NameLabel:SizeToContents()
	self.NameLabel:CenterHorizontal()
	self.NameLabel:AlignBottom()
end

function PANEL:SetClassTable(classtable)
	self.ClassTable = classtable

	self.NameLabel:SetText(translate.Get(classtable.TranslationName))
	self.Image:SetImage(classtable.Icon)

	self:InvalidateLayout()
end

function PANEL:Paint()
	return true
end

function PANEL:OnCursorEntered()
	self.NameLabel:SetAlpha(255)

	CreateHoveredClassWindow(self.ClassTable)
end

function PANEL:OnCursorExited()
	self.NameLabel:SetAlpha(180)

	if HoveredClassWindow and HoveredClassWindow:Valid() and HoveredClassWindow.ClassTable == self.ClassTable then
		HoveredClassWindow:Remove()
	end
end

function PANEL:DoClick()
	if self.ClassTable then
		if self.ClassTable.Boss then
			RunConsoleCommand("zs_bossclass", self.ClassTable.Name)
			GAMEMODE:CenterNotify(translate.Format("boss_class_select", self.ClassTable.Name))
		else
			RunConsoleCommand("zs_class", self.ClassTable.Name, GAMEMODE.SuicideOnChangeClass and "1" or "0")
		end
	end

	surface.PlaySound("buttons/button15.wav")

	Window:Remove()
end

function PANEL:Think()
	if not self.ClassTable then return end

	local enabled = LocalPlayer():GetZombieClass() == self.ClassTable.Index and 2 or gamemode.Call("IsClassUnlocked", self.ClassTable.Index) and 1 or 0
	if enabled ~= self.LastEnabledState then
		self.LastEnabledState = enabled

		if enabled == 2 then
			self.NameLabel:SetTextColor(COLOR_GREEN)
			self.Image:SetImageColor(color_white)
		elseif enabled == 1 then
			self.NameLabel:SetTextColor(COLOR_GRAY)
			self.Image:SetImageColor(color_white)
		else
			self.NameLabel:SetTextColor(COLOR_DARKRED)
			self.Image:SetImageColor(COLOR_RED)
		end
	end
end

vgui.Register("ClassButton", PANEL, "Button")

local PANEL = {}

function PANEL:Init()
	self.NameLabel = vgui.Create("DLabel", self)
	self.NameLabel:SetFont("ZSHUDFontSmaller")

	self.DescLabels = self.DescLabels or {}

	self:InvalidateLayout()
end

function PANEL:SetClassTable(classtable)
	self.ClassTable = classtable

	self.NameLabel:SetText(translate.Get(classtable.TranslationName))
	self.NameLabel:SizeToContents()

	self:CreateDescLabels()

	self:InvalidateLayout()
end

function PANEL:RemoveDescLabels()
	for _, label in pairs(self.DescLabels) do
		label:Remove()
	end

	self.DescLabels = {}
end

function PANEL:CreateDescLabels()
	self:RemoveDescLabels()

	self.DescLabels = {}

	local classtable = self.ClassTable
	if not classtable or not classtable.Description then return end

	local lines = string.Explode("\n", translate.Get(classtable.Description))
	if classtable.Wave and classtable.Wave > 0 then
		table.insert(lines, 1, "("..translate.Format("unlocked_on_wave_x", classtable.Wave)..")")
	end

	if classtable.Help then
		table.insert(lines, " ")
		table.Add(lines, string.Explode("\n", translate.Get(classtable.Help)))
	end

	for _, line in ipairs(lines) do
		local label = vgui.Create("DLabel", self)
		label:SetText(line)
		label:SetFont("ZSHUDFontTiny")
		label:SizeToContents()
		table.insert(self.DescLabels, label)
	end
end

function PANEL:PerformLayout()
	self.NameLabel:SizeToContents()
	self.NameLabel:CenterHorizontal()

	local maxw = self.NameLabel:GetWide()
	for _, label in pairs(self.DescLabels) do
		maxw = math.max(maxw, label:GetWide())
	end
	self:SetWide(maxw + 64)
	self:CenterHorizontal()

	for i, label in ipairs(self.DescLabels) do
		label:MoveBelow(self.DescLabels[i - 1] or self.NameLabel)
		label:CenterHorizontal()
	end

	local lastlabel = self.DescLabels[#self.DescLabels] or self.NameLabel
	local x, y = lastlabel:GetPos()
	self:SetTall(y + lastlabel:GetTall())
end

function PANEL:Think()
	if not Window or not Window:Valid() or not Window:IsVisible() then
		self:Remove()
	end
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "Frame", self, w, h)

	return true
end

vgui.Register("ClassInfo", PANEL, "Panel")