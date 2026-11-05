local PANEL = {}
PANEL.m_ItemID = 0
PANEL.RefreshTime = 1
PANEL.NextRefresh = 0

function PANEL:Init()
	self:SetFont("ZSMenuScaledSmall")
end

function PANEL:Think()
	if not self:IsVisible() then return end
	local row = self:GetParent()
	if not IsValid(row) or not row:IsVisible() then return end
	local shop = row.m_ShopFrame
	if not IsValid(shop) or not shop:IsVisible() then return end
	local sheet = shop.m_CategorySheet
	local active = IsValid(sheet) and sheet:GetActiveTab()
	if not IsValid(active) or active:GetPanel() ~= row.m_CategoryPanel then return end
	local now = CurTime()
	if now >= self.NextRefresh then
		self.NextRefresh = now + self.RefreshTime
		self:Refresh()
	end
end

function PANEL:Refresh()
	local count = GAMEMODE:GetCurrentEquipmentCount(self:GetItemID())
	if count == self.m_LastCount then return end
	self.m_LastCount = count
	self:SetText(count == 0 and " " or count)
	self:SizeToContents()
end

function PANEL:SetItemID(id)
	if self.m_ItemID == id then return end
	self.m_ItemID, self.m_LastCount, self.NextRefresh = id, nil, 0
end

function PANEL:GetItemID()
	return self.m_ItemID
end

vgui.Register("ItemAmountCounter", PANEL, "DLabel")
