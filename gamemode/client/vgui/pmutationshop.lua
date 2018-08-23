
local TokensRemaining = 0
local MutationButtons = {}

local function Checkout(tobuy)
	if tobuy and #tobuy > 0 then
		RunConsoleCommand("zs_mutationshop_click", unpack(tobuy))
		if pMutation and pMutation:Valid() then
			pMutation:Close()
		end
	else
		surface.PlaySound("buttons/combine_button_locked.wav")
	end
end

local function CheckoutDoClick(self)
	local tobuy = {}
	for _, btn in pairs(MutationButtons) do
		if btn and btn.On and btn.ID then
			table.insert(tobuy, btn.ID)
		end
	end
	Checkout(tobuy)
end

function MakepMutationShop(used)
	if pMutation and pMutation:Valid() then
		pMutation:Remove()
		pMutation = nil
	end

	local maxtokens = MySelf:GetTokens()
	TokensRemaining = maxtokens

	local wid, hei = math.min(ScrW(), 720), ScrH() * 0.7
	local frame = vgui.Create("DFrame")
	pMutation = frame
	frame:SetSize(wid, hei)
	frame:SetDeleteOnClose(true)
	frame:SetKeyboardInputEnabled(false)
	frame:SetTitle(" ")
	frame.Paint = function() draw.RoundedBox( 0, 0, 0, wid, hei, Color( 0, 0, 0, 200 ) ) end

	local propertysheet = vgui.Create("DPropertySheet", frame)
	propertysheet:StretchToParent(4, 24, 4, 50)
	propertysheet.Paint = function() end

	local panfont = "ZSHUDFontSmall"
	local panhei = 40
	
	for catid, catname in ipairs(GAMEMODE.ItemCategories) do
		local hasitems = false
		for i, tab in ipairs(GAMEMODE.Mutations) do
			if tab.Category == catid and tab.MutationShop then
				hasitems = true
				break
			end
		end

		if hasitems then
			local list = vgui.Create("DPanelList", propertysheet)
			list:SetPaintBackground(false)
			propertysheet:AddSheet(catname, list, GAMEMODE.ItemCategoryIcons[catid], false, false)
			list:EnableVerticalScrollbar(true)
			list:SetWide(propertysheet:GetWide() - 16)
			list:SetSpacing(2)
			list:SetPadding(2)

			for i, tab in ipairs(GAMEMODE.Mutations) do
				if tab.Category == catid and tab.MutationShop then
					local button = vgui.Create("ZSMutationButton")
					button:SetMutationID(i)
					list:AddItem(button)
					MutationButtons[i] = button
					
				end
			end
		end
	end	

	local worthlab = EasyLabel(frame, translate.Get("mutationsdamagetokens")..": "..tostring(TokensRemaining), "ZSHUDFontSmall", COLOR_LIMEGREEN)
	worthlab:SetPos(8, frame:GetTall() - worthlab:GetTall() - 8)
	frame.WorthLab = worthlab

	local checkout = vgui.Create("DButton", frame)
	checkout:SetFont("ZSHUDFontSmall")
	checkout:SetText(translate.Get("worth_checkout"))
	checkout:SizeToContents()
	checkout:SetSize(130, 30)
	checkout:AlignBottom(8)
	checkout:CenterHorizontal()
	checkout.DoClick = CheckoutDoClick

	frame:Center()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.5, 0)
	frame:MakePopup()
	return frame
end

local PANEL = {}
PANEL.m_ItemID = 0
PANEL.RefreshTime = 1
PANEL.NextRefresh = 0

function PANEL:Init()
	self:SetFont("DefaultFontSmall")
end

function PANEL:Think()
	if CurTime() >= self.NextRefresh then
		self.NextRefresh = CurTime() + self.RefreshTime
		self:Refresh()
	end
end

function PANEL:Refresh()
	local count = GAMEMODE:GetCurrentEquipmentCount(self:GetItemID())
	if count == 0 then
		self:SetText(" ")
	else
		self:SetText(count)
	end
	self:SizeToContents()
end

function PANEL:SetItemID(id) self.m_ItemID = id end
function PANEL:GetItemID() return self.m_ItemID end

vgui.Register("ItemAmountCounter", PANEL, "DLabel")

PANEL = {}

function PANEL:Init()
	self:SetText("")

	self:DockPadding(4, 4, 4, 4)
	self:SetTall(48)

	local mdlframe = vgui.Create("DEXRoundedPanel", self)
	mdlframe:SetWide(self:GetTall() - 8)
	mdlframe:Dock(LEFT)
	mdlframe:DockMargin(0, 0, 20, 0)

	self.ModelPanel = vgui.Create("DModelPanel", mdlframe)
	self.ModelPanel:Dock(FILL)
	self.ModelPanel:DockPadding(0, 0, 0, 0)
	self.ModelPanel:DockMargin(0, 0, 0, 0)

	self.NameLabel = EasyLabel(self, "", "ZSHUDFontSmall")
	self.NameLabel:SetContentAlignment(4)
	self.NameLabel:Dock(FILL)

	self.PriceLabel = EasyLabel(self, "", "ZSHUDFontTiny")
	self.PriceLabel:SetWide(80)
	self.PriceLabel:SetContentAlignment(6)
	self.PriceLabel:Dock(RIGHT)
	self.PriceLabel:DockMargin(8, 0, 4, 0)
	
	self:SetMutationID(nil)
end

function PANEL:SetMutationID(id)
	self.ID = id

	local tab = FindMutation(id)

	if not tab then
		self.ModelPanel:SetVisible(false)
		self.NameLabel:SetText("")
		return
	end
	
	for k,v in pairs(UsedMutations) do
		if v == tab.Signature then
			self.NameLabel:SetTextColor(COLOR_RED)
		end
	end

	local mdl = tab.Model or (weapons.GetStored(tab.SWEP) or tab).WorldModel
	if mdl then
		self.ModelPanel:SetModel(mdl)
		local mins, maxs = self.ModelPanel.Entity:GetRenderBounds()
		self.ModelPanel:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5))
		self.ModelPanel:SetLookAt((mins + maxs) / 2)
		self.ModelPanel:SetVisible(true)
	else
		self.ModelPanel:SetVisible(false)
	end

	if tab.Worth then
		self.PriceLabel:SetText(tostring(tab.Worth).." "..translate.Get("mutationstokens"))
	else
		self.PriceLabel:SetText("")
	end
	
	self:SetTooltip(tab.Description)

	self.NameLabel:SetText(tab.Name or "")
end

function PANEL:Paint(w, h)
	local outline
	
	if self.Hovered then
		outline = self.On and COLOR_GREEN or COLOR_GRAY
	else
		outline = self.On and COLOR_DARKGREEN or COLOR_DARKGRAY
	end

	draw.RoundedBox(8, 0, 0, w, h, outline)
	draw.RoundedBox(4, 4, 4, w - 8, h - 8, color_black)
end

function PANEL:DoClick(silent, force)
	local id = self.ID
	local tab = FindMutation(id)
	if not tab then return end

	if self.On then
		self.On = nil
		if not silent then
			surface.PlaySound("buttons/button18.wav")
		end
		TokensRemaining = TokensRemaining + tab.Worth
	else
	
		for k,v in pairs(UsedMutations) do
			if v == tab.Signature then
				surface.PlaySound("buttons/button8.wav")
				return
			end

		end
		
		if TokensRemaining < tab.Worth and not force then
			surface.PlaySound("buttons/button8.wav")
			return
		end
		
		self.On = true
		if not silent then
			surface.PlaySound("buttons/button17.wav")
		end
		TokensRemaining = TokensRemaining - tab.Worth
	end

	pMutation.WorthLab:SetText(translate.Get("mutationsdamagetokens")..": ".. TokensRemaining)
	if TokensRemaining <= 0 then
		pMutation.WorthLab:SetTextColor(COLOR_RED)
		pMutation.WorthLab:InvalidateLayout()
	elseif TokensRemaining <= MySelf:GetTokens() * 0.25 then
		pMutation.WorthLab:SetTextColor(COLOR_YELLOW)
		pMutation.WorthLab:InvalidateLayout()
	else
		pMutation.WorthLab:SetTextColor(COLOR_LIMEGREEN)
		pMutation.WorthLab:InvalidateLayout()
	end
	pMutation.WorthLab:SizeToContents()
end

vgui.Register("ZSMutationButton", PANEL, "DButton")
