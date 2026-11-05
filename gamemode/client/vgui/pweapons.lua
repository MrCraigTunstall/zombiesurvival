if IsValid(pWeapons)then pWeapons:Remove();pWeapons=nil end
local features = {
	{"WalkSpeed", "wb_wspeed"}, {"MeleeDamage", "wb_mdmg"}, {"MeleeRange", "wb_range"}, {"MeleeSize", "wb_msize"},
	{"ClipSize", "wb_clipsize", "Primary"}, {"Damage", "wb_dmg", "Primary"}, {"NumShots", "wb_numshots", "Primary"},
	{"Delay", "wb_fire_delay", "Primary"}, {"ConeMax", "wb_spread_max"}, {"ConeMin", "wb_spread_min"}
}
GM.WeaponBrowserCatalogue,GM.WeaponBrowserRecords,GM.WeaponBrowserSeen=nil,nil,nil
local colors = GM.ShopColors
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end

local function FeatureValue(stored, feature)
	local source = stored and (feature[3] and stored[feature[3]] or not feature[3] and stored)
	local value = type(source) == "table" and source[feature[1]]
	if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

local function RecordCurrent(record)
	local stored = weapons.GetStored(record.class)
	if stored ~= record.stored or (stored and stored.PrintName or record.class) ~= record.name
		or (stored and stored.Description or "") ~= record.description or (stored and stored.WorldModel) ~= record.model then return false end
	for index, feature in ipairs(features) do if FeatureValue(stored, feature) ~= record.values[index] then return false end end
	return true
end

function GM:GetWeaponBrowserRecord(class)
	local stored = weapons.GetStored(class)
	local name = stored and stored.PrintName or class
	local description = stored and stored.Description or ""
	local model = stored and stored.WorldModel
	local lines, values = {}, {}
	for index, feature in ipairs(features) do
		local value = FeatureValue(stored, feature) values[index] = value
		if value ~= nil then
			lines[#lines + 1] = translate.Get(feature[2]) .. ": " .. tostring(value)
		end
	end
	local stats = #lines > 0 and table.concat(lines, "\n") or translate.Get("wb_no_stats")
	return {class = class, stored = stored, name = name, description = description, model = model,
		stats = stats, values = values, search = string.lower(name .. " " .. class .. " " .. description),
		stamp = name .. "\0" .. description .. "\0" .. (model or "") .. "\0" .. stats}
end

function GM:BuildWeaponBrowserCatalogue()
 local revision=translate.GetRevision and translate.GetRevision()
 local cached=self.WeaponBrowserCatalogue
 local seen=self.WeaponBrowserSeen or {};self.WeaponBrowserSeen=seen
 for class in pairs(seen)do seen[class]=nil end
 local current=cached~=nil and self.WeaponBrowserLanguage==revision
 local count=0
 for _,item in pairs(self.Items)do
  local class=item.SWEP
  if type(class)=="string"and not seen[class]then
   seen[class]=true;count=count+1
   local record=self.WeaponBrowserRecords and self.WeaponBrowserRecords[class]
   if not record or not RecordCurrent(record)then current=false end
  end
 end
 if current and count==#cached then return cached end
	local entries, seen = {}, {}
	for _, item in pairs(self.Items) do
		local class = item.SWEP
		if type(class) == "string" and not seen[class] then
			seen[class] = true entries[#entries + 1] = self:GetWeaponBrowserRecord(class)
		end
	end
	table.sort(entries, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.class < b.class end)
 self.WeaponBrowserCatalogue,self.WeaponBrowserLanguage=entries,revision
 self.WeaponBrowserRecords={}
 for _,record in ipairs(entries)do self.WeaponBrowserRecords[record.class]=record end
 return entries
end

local function Text(label, value)
	if label.ZSWeaponText ~= value then label.ZSWeaponText = value label:SetText(value) end
end

local function Measure(frame)
	if not frame.NeedsMeasure then return end
	frame.NeedsMeasure = nil
	frame.Description:SizeToContentsY() frame.Stats:SizeToContentsY()
	local descriptionHeight = frame.Description:GetTall()
	frame.StatsTitle:SetPos(0, descriptionHeight + U(20))
	frame.Stats:SetPos(0, descriptionHeight + U(46))
	frame.DetailBody:SetTall(descriptionHeight + frame.Stats:GetTall() + U(58))
end

local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
	GAMEMODE:RefreshMenuScale()
	local width, height = math.min(screenWidth - 32, U(1000)), math.min(screenHeight - 32, U(720))
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
	if frame.LayoutWidth==width and frame.LayoutHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth,frame.LayoutHeight=width,height
 frame:SetSize(width, height) frame:Center()
	frame.Title:SetPos(U(20), U(14)) frame.Title:SetSize(width - U(80), U(28))
	frame.Subtitle:SetPos(U(20), U(44)) frame.Subtitle:SetSize(width - U(40), U(22))
	frame.CloseButton:SetPos(width - U(50), U(16)) frame.CloseButton:SetSize(U(30), U(30))
	frame.Search:SetPos(U(20), U(84)) frame.Search:SetSize(width - U(40), U(30))
	local left = math.floor((width - U(56)) * 0.34)
	frame.List:SetPos(U(20), U(126)) frame.List:SetSize(left, height - U(166))
	frame.Empty:SetPos(U(28), U(140)) frame.Empty:SetSize(left - U(16), U(60))
	local x, right = left + U(36), width - left - U(56)
	frame.Viewer:SetPos(x, U(126)) frame.Viewer:SetSize(right, height - U(166))
	frame.WeaponTitle:SetPos(U(12), U(8)) frame.WeaponTitle:SetSize(right - U(24), U(44))
	local previewHeight = math.min(U(150), math.floor((height - U(166)) * 0.35))
	frame.ModelPanel:SetPos(U(12), U(58)) frame.ModelPanel:SetSize(right - U(24), previewHeight)
	frame.ModelFallback:SetPos(U(12), U(58)) frame.ModelFallback:SetSize(right - U(24), previewHeight)
	frame.DetailScroll:SetPos(U(12), U(68) + previewHeight) frame.DetailScroll:SetSize(right - U(24), height - U(246) - previewHeight)
	frame.DetailBody:SetWide(right - U(44))
	for _, label in ipairs({frame.Description, frame.StatsTitle, frame.Stats}) do label:SetWide(right - U(48)) end
	frame.Description:SetPos(U(0), U(0))
	frame.Description:InvalidateLayout(true) frame.Stats:InvalidateLayout(true) frame.NeedsMeasure = true
	frame.Footer:SetPos(U(20), height - U(30)) frame.Footer:SetSize(width - U(40), U(20))
	frame.StatsTitle:SetTall(U(24))
	for _, scroll in ipairs({frame.List, frame.DetailScroll}) do scroll:GetVBar():SetWide(U(16)) end
	for _, row in ipairs(frame.Rows) do row:SetTall(U(52)) row:DockMargin(0, 0, 0, U(6)) end

end

local function SelectWeapon(frame, class, record)
	if not record and class == frame.ViewerSWEP and frame.SelectedRecord and RecordCurrent(frame.SelectedRecord) then return end
	if not record or not RecordCurrent(record) then record = class and GAMEMODE:GetWeaponBrowserRecord(class) end
	if not record then return end
	if frame.SelectedRecord ~= record or frame.ViewerSWEP ~= class then
		for _, row in ipairs(frame.Rows) do
			row.Selected = row.Record.class == class
			if row.Selected and row.Record ~= record then
				if row.Record.name ~= record.name then row:SetTooltip(record.name .. "\n" .. class) row.Label:SetText(record.name) end
				row.Record = record
			end
		end
	end
	frame.SelectedRecord = record
	if frame.ViewerSWEP == class and frame.ViewerStamp == record.stamp then frame.ViewerTable = record.stored return end
	frame.ViewerSWEP, frame.ViewerTable, frame.ViewerStamp = class, record.stored, record.stamp
	Text(frame.WeaponTitle, record.name) Text(frame.Description, record.description ~= "" and record.description or translate.Get("wb_no_description"))
	Text(frame.Stats, record.stats)
	local model = record.model
	if model ~= frame.PreviewModel then
		frame.PreviewModel = model
		if type(model) == "string" and model ~= "" then frame.ModelPanel:SetModel(model) frame.ModelPanel:AutoCam()
		elseif IsValid(frame.ModelPanel.Entity) then frame.ModelPanel.Entity:Remove() frame.ModelPanel.Entity = nil end
	end
	local valid = IsValid(frame.ModelPanel.Entity)
	frame.ModelPanel:SetVisible(valid) frame.ModelFallback:SetVisible(not valid)
	frame.DetailScroll:GetVBar():SetScroll(0) frame.NeedsMeasure = true
	frame.Description:InvalidateLayout(true) frame.Stats:InvalidateLayout(true)
end

local function Filter(frame)
	local query, count = string.lower(frame.Search:GetValue()), 0
	for _, row in ipairs(frame.Rows) do
		local visible = query == "" or string.find(row.Record.search, query, 1, true) ~= nil
		if row.Shown ~= visible then row.Shown = visible row:SetVisible(visible) end
		if visible then count = count + 1 end
	end
	frame.List:InvalidateLayout()
 if frame.Empty:IsVisible()~=(count==0)then frame.Empty:SetVisible(count==0)end
	Text(frame.Footer, translate.Format("wb_count", count))
end

local function Populate(frame, entries)
 if frame.Catalogue==entries then return end
 frame.Catalogue=entries
 for index,record in ipairs(entries)do
  local row=frame.Rows[index]
  if not IsValid(row)then
   row=frame.List:Add("DButton");frame.Rows[index]=row;row:SetText("")
   row:SetTall(U(52));row:Dock(TOP);row:DockMargin(0,0,0,U(6));row:SetZPos(index)
   row:SetTooltipPanelOverride("ZSShopTooltip")
   row.Label=row:Add("DLabel");row.Label:SetFont("ZSMenuScaledBody");row.Label:SetTextColor(color_white)
   row.Label:SetWrap(true);row.Label:SetMouseInputEnabled(false)
   row.PerformLayout=function(self,width)self.Label:SetPos(U(10),U(6));self.Label:SetSize(width-U(20),U(40))end
   row.Paint=function(self,width,height)draw.RoundedBox(5,0,0,width,height,self.Selected and colors.selected or self:IsHovered()and colors.hover or colors.row)end
   row.DoClick=function(self)SelectWeapon(frame,self.Record.class,self.Record)end
  end
  if not row.Record or row.Record.name~=record.name or row.Record.class~=record.class then
   row:SetTooltip(record.name.."\n"..record.class);row.Label:SetText(record.name)
  end
  row.Record=record;row.Selected=record.class==frame.ViewerSWEP
 end
 for index=#frame.Rows,#entries+1,-1 do frame.Rows[index]:Remove();frame.Rows[index]=nil end
	local selected
	for _, record in ipairs(entries) do if record.class == frame.ViewerSWEP then selected = record break end end
	selected = selected or entries[1]
	frame.Viewer:SetVisible(selected ~= nil)
	if selected then SelectWeapon(frame, selected.class, selected) end
	Filter(frame)
end

local function Label(parent, font, color)
	local label = parent:Add("DLabel") label:SetFont(font) label:SetTextColor(color) label:SetText("")
	return label
end

function MakepWeapons(silent)
	GAMEMODE:RefreshMenuScale()
	if not silent then PlayMenuOpenSound() end
	local revision = translate.GetRevision and translate.GetRevision()
	local frame = pWeapons
	if IsValid(frame) and frame.LanguageRevision ~= revision then frame:Remove() frame = nil end
	if not IsValid(frame) then
		frame = vgui.Create("DFrame") pWeapons = frame frame.LanguageRevision = revision
  frame:SetVisible(false)
		frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDeleteOnClose(false) frame:SetDraggable(false)
  GAMEMODE:StyleShopFrame(frame)
  local background=Color(14,22,34)
  frame.Paint=function(_,width,height)
   draw.RoundedBox(8,0,0,width,height,background)
   draw.RoundedBox(8,0,0,width,U(72),colors.header)
   surface.SetDrawColor(colors.accent);surface.DrawRect(U(20),U(72),width-U(40),U(2))
  end
  frame.btnMinim:SetVisible(false);frame.btnMaxim:SetVisible(false)
  local nativeThink=frame.Think
  frame.Think=function(self)if not self:IsVisible()then return end;if nativeThink then nativeThink(self)end end
		frame.Title = Label(frame, "ZSMenuScaledTitle", color_white) Text(frame.Title, translate.Get("wb_database"))
		frame.Subtitle = Label(frame, "ZSMenuScaledSmall", colors.muted) Text(frame.Subtitle, translate.Get("wb_reference_help"))
		frame.CloseButton = frame:Add("DButton") frame.CloseButton:SetText("X") GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton:SetTooltip(translate.Get("close")) frame.CloseButton.DoClick = function() frame:Close() end
		frame.Search = frame:Add("DTextEntry") frame.Search:SetFont("ZSMenuScaledBody") frame.Search:SetPlaceholderText(translate.Get("wb_search"))
  frame.Search:SetTextColor(color_white);frame.Search:SetCursorColor(colors.accent);frame.Search:SetHighlightColor(colors.selected)
  frame.Search.Paint=function(self,width,height)
   draw.RoundedBox(5,0,0,width,height,colors.row)
   self:DrawTextEntryText(color_white,colors.selected,colors.accent)
   if self:GetValue()==""and not self:HasFocus()then draw.SimpleText(translate.Get("wb_search"),"ZSMenuScaledBody",U(8),height*0.5,colors.muted,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)end
  end
  frame.Search.OnValueChange = function() Filter(frame) end
		frame.List = frame:Add("DScrollPanel") frame.Rows = {}
		frame.Empty = Label(frame, "ZSMenuScaledSmall", colors.muted) Text(frame.Empty, translate.Get("wb_empty")) frame.Empty:SetWrap(true)
		frame.Viewer = frame:Add("DPanel") frame.Viewer:SetPaintBackground(false)
		frame.Viewer.Paint = function(_, width, height) draw.RoundedBox(6, 0, 0, width, height, colors.row) end
		frame.WeaponTitle = Label(frame.Viewer, "ZSMenuScaledBody", color_white) frame.WeaponTitle:SetWrap(true)
		frame.ModelPanel = frame.Viewer:Add("DModelPanelEx") frame.ModelPanel.LayoutEntity = function() end
		frame.ModelFallback = Label(frame.Viewer, "ZSMenuScaledSmall", colors.muted) Text(frame.ModelFallback, translate.Get("wb_no_model"))
		frame.ModelFallback:SetContentAlignment(5)
		frame.DetailScroll = frame.Viewer:Add("DScrollPanel") frame.DetailBody = frame.DetailScroll:Add("DPanel") frame.DetailBody:SetPaintBackground(false) frame.DetailBody:SetTall(U(200))
		frame.Description = Label(frame.DetailBody, "ZSMenuScaledBody", colors.muted) frame.Description:SetWrap(true)
		frame.StatsTitle = Label(frame.DetailBody, "ZSMenuScaledBody", colors.accent) Text(frame.StatsTitle, translate.Get("wb_base_stats")) frame.StatsTitle:SetTall(U(24))
		frame.Stats = Label(frame.DetailBody, "ZSMenuScaledSmall", color_white) frame.Stats:SetWrap(true)
		frame.Description.PaintOver = function() Measure(frame) end
		frame.Footer = Label(frame, "ZSMenuScaledSmall", colors.muted)
		frame.SetWeaponViewerSWEP = SelectWeapon
  for _,panel in ipairs({frame.List,frame.DetailScroll})do
   local bar=panel:GetVBar()
   bar.Paint=function(_,width,height)draw.RoundedBox(4,0,0,width,height,colors.row)end
   for _,button in ipairs({bar.btnUp,bar.btnDown,bar.btnGrip})do
    button.Paint=function(self,width,height)draw.RoundedBox(4,0,0,width,height,self:IsHovered()and colors.accent or colors.muted)end
   end
  end
  frame.OnRemove=function(self)
   self.Rows,self.SelectedRecord,self.ViewerTable,self.Catalogue=nil,nil,nil,nil
   if pWeapons==self then pWeapons=nil end
  end
	end
	Layout(frame) Populate(frame, GAMEMODE:BuildWeaponBrowserCatalogue())
	if not frame:IsVisible()then frame:SetVisible(true);frame:MakePopup()end
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSWeaponBrowserLayout", function()
	if IsValid(pWeapons) then Layout(pWeapons) end
end)
