GM.NotifyFadeTime = 8

local fontScale
local lists = setmetatable({}, {__mode = "k"})
local function NotificationScale()
 local scale = math.max(1, BetterScreenScale())
 if fontScale ~= scale then
  fontScale = scale
  surface.CreateFont("ZSNotifyBody", {font = "Roboto", size = 16 * scale, weight = 500, antialias = true, extended = true})
  surface.CreateFont("ZSNotifyTitle", {font = "Roboto", size = 22 * scale, weight = 700, antialias = true, extended = true})
 end
 return scale
end
NotificationScale()
hook.Add("OnScreenSizeChanged", "ZSNotificationScale", function()
 NotificationScale()
 for list in pairs(lists) do if IsValid(list) then list:InvalidateLayout(true) end end
end)
local DefaultFont = "ZSNotifyBody"
local DefaultFontEntity = DefaultFont
local fonts = {ZSHUDFont = "ZSNotifyTitle", ZSHUDFontSmall = "ZSNotifyTitle", ZSHUDFontSmaller = DefaultFont, ZSHUDFontSmallest = DefaultFont, ZSHUDFontTiny = DefaultFont}

local PANEL  = {}

local background = Color(14, 19, 27, 238)
local border = Color(71, 87, 106, 110)
local accent = Color(99, 200, 227)
local badgeBackground = Color(31, 43, 57, 245)

local function PaintBotAvatar(self, w, h)
 draw.RoundedBox(h * 0.15, 0, 0, w, h, badgeBackground)
 surface.SetDrawColor(self.ZSBotColor)
 surface.DrawRect(w * 0.45, h * 0.12, w * 0.1, h * 0.2)
 draw.RoundedBox(h * 0.1, w * 0.15, h * 0.28, w * 0.7, h * 0.55, self.ZSBotColor)
 surface.SetDrawColor(background)
 surface.DrawRect(w * 0.29, h * 0.43, w * 0.12, h * 0.12)
 surface.DrawRect(w * 0.59, h * 0.43, w * 0.12, h * 0.12)
 surface.DrawRect(w * 0.36, h * 0.66, w * 0.28, h * 0.06)
end

function PANEL:Init()
	self:DockMargin(0, 0, 0, 6)
	self:DockPadding(16, 0, 16, 0)
	self.Content = vgui.Create("Panel", self)
	self.Parts = {}
	self.Content:SetMouseInputEnabled(false)
	self:SetMouseInputEnabled(false)
	self.Content.Paint = function(_, w, h)
		for _, run in ipairs(self.Runs or {}) do
			draw.SimpleText(run.text, run.font, run.x, run.y, run.color)
		end
	end
	self.Count = 1
	self.Accent = accent
end

function PANEL:Paint(w, h)
	local x, width = self.CardX or 0, self.CardWidth or w
	local scale = self.LayoutScale or 1
	draw.RoundedBox(6 * scale, x, 0, width, h, border)
	draw.RoundedBox(6 * scale, x + scale, scale, width - 2 * scale, h - 2 * scale, background)
	surface.SetDrawColor(self.Accent)
	surface.DrawRect(x + scale, 6 * scale, 3 * scale, h - 12 * scale)
	if self.Count > 1 then
		local badgeWidth = self.BadgeWidth or 40 * scale
		local badgeX = x + width - badgeWidth - 10 * scale
		local badgeHeight = self.BadgeHeight or 24 * scale
		draw.RoundedBox(4 * scale, badgeX, (h - badgeHeight) / 2, badgeWidth, badgeHeight, badgeBackground)
		draw.SimpleText(self.BadgeText or "", DefaultFont, badgeX + badgeWidth / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PANEL:UpdateCard()
 local parent = self:GetParent()
 local scale = self.DetailMode and 1 or NotificationScale()
 if self.LayoutScale ~= scale then
  self:DockMargin(0, 0, 0, 6 * scale)
  self:DockPadding(16 * scale, 0, 16 * scale, 0)
  if not self.DetailMode then self.MinimumHeight = math.max(40 * scale, BetterScreenScale() * parent:GetMessageHeight()) end
  for _, part in ipairs(self.Parts) do
   if part.text then
    surface.SetFont(part.font) part.width, part.height = surface.GetTextSize(part.text)
   elseif part.panel then
    part.baseWidth, part.baseHeight = part.baseWidth or part.width, part.baseHeight or part.height
    part.width, part.height = part.baseWidth * scale, part.baseHeight * scale
   end
  end
 end
 local available = self.DetailMode and self:GetWide() or parent:GetWide()
 local availableHeight = self.DetailMode and math.huge or parent:GetTall()
 local align = LEFT
 if parent.GetAlign then align = parent:GetAlign() or TEXT_ALIGN_CENTER end
 if self.LayoutWidth == available and self.LayoutHeight == availableHeight and self.LayoutCount == self.Count and self.LayoutAlign == align and self.LayoutScale == scale then return end
 local badgeWidth = 0
 self.BadgeText = self.Count > 1 and "x" .. self.Count or ""
 if self.Count > 1 then
  surface.SetFont(DefaultFont)
  badgeWidth = surface.GetTextSize(self.BadgeText) + 16 * scale
 end
 self.BadgeWidth, self.BadgeHeight = badgeWidth, 24 * scale
 local reserve = 32 * scale + (badgeWidth > 0 and badgeWidth + 10 * scale or 0)
 local natural, longest = 0, 0
 for _, part in ipairs(self.Parts) do
  if part.newline then longest = math.max(longest, natural) natural = 0
  else natural = natural + part.width end
 end
 local cardWidth = math.min(available, math.max(longest, natural) + reserve)
 local innerWidth = math.max(1, cardWidth - reserve)
 local rows, row, x = {}, {height = 20 * scale, items = {}}, 0
 local function NextRow()
  rows[#rows + 1] = row
  row, x = {height = 20 * scale, items = {}}, 0
 end
 local function Add(part, text, width)
  if x > 0 and x + width > innerWidth then NextRow() end
  row.items[#row.items + 1] = {part = part, text = text, width = width, x = x}
  row.height = math.max(row.height, part.drawHeight or part.height)
  x = x + width
 end
 for _, part in ipairs(self.Parts) do
  if part.newline then NextRow()
  elseif part.space then
   if x > 0 and x + part.width <= innerWidth then Add(part, part.text, part.width) end
  elseif part.text and part.width > innerWidth then
   surface.SetFont(part.font)
   local fragment, width = "", 0
   for character in part.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local characterWidth = surface.GetTextSize(character)
    if #fragment > 0 and width + characterWidth > innerWidth then
     Add(part, fragment, width) fragment, width = "", 0
    end
    fragment, width = fragment .. character, width + characterWidth
   end
   if #fragment > 0 then Add(part, fragment, width) end
  elseif part.panel then
   local width = math.min(part.width, innerWidth)
   part.drawHeight = part.height * width / math.max(1, part.width)
   part.panel:SetSize(width, part.drawHeight) part.panel:SetVisible(false)
   Add(part, nil, width)
  else Add(part, part.text, part.width) end
 end
 if #row.items > 0 or #rows == 0 then rows[#rows + 1] = row end
 local maximumHeight = math.max(40 * scale, availableHeight - 6 * scale)
 local runs, y, visibleRows = {}, 10 * scale, 0
 for _, line in ipairs(rows) do
  if y + line.height + 10 * scale > maximumHeight then break end
  visibleRows = visibleRows + 1
  y = y + line.height
 end
 self.Truncated = visibleRows < #rows
 if self.Truncated and not self.DetailMode then GAMEMODE.NotificationDetailsText = self.PlainText end
 local ellipsisWidth
 if self.Truncated then surface.SetFont(DefaultFont) ellipsisWidth = surface.GetTextSize("F1...") end
 y = 10 * scale
 for index = 1, visibleRows do
  local line = rows[index]
  local limit = self.Truncated and index == visibleRows and innerWidth - ellipsisWidth - 4 * scale or innerWidth
  for _, item in ipairs(line.items) do
   local part = item.part
   local itemY = y + (line.height - (part.drawHeight or part.height)) * 0.5
   if item.x < limit then
   if part.panel then
    if item.x + item.width <= limit then part.panel:SetPos(item.x, itemY) part.panel:SetVisible(true) end
   else
    if item.x + item.width > limit then
     surface.SetFont(part.font)
     local fragment, width = "", 0
     for character in item.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      local candidate = fragment .. character
      local candidateWidth = surface.GetTextSize(candidate)
      if item.x + candidateWidth > limit then break end
      fragment, width = candidate, candidateWidth
     end
     item.text, item.width = fragment, width
    end
    local previous = runs[#runs]
    if previous and previous.font == part.font and previous.color == part.color and previous.y == itemY and previous.x + previous.width == item.x then
     previous.text, previous.width = previous.text .. item.text, previous.width + item.width
    else runs[#runs + 1] = {text = item.text, font = part.font, color = part.color, x = item.x, y = itemY, width = item.width} end
   end
  end
   end
  if self.Truncated and index == visibleRows then
   runs[#runs + 1] = {text = "F1...", font = DefaultFont, color = color_white, x = math.max(0, innerWidth - ellipsisWidth), y = y + (line.height - 20 * scale) * 0.5, width = ellipsisWidth}
  end
  y = y + line.height
 end
 local height = math.max(self.MinimumHeight or 40 * scale, y + 10 * scale)
 self:SetTall(math.min(height, maximumHeight))
 self.Runs = runs
 local cardX = align == RIGHT and available - cardWidth or align == TEXT_ALIGN_CENTER and (available - cardWidth) / 2 or 0
 self.CardX, self.CardWidth = math.max(0, cardX), cardWidth
 self.Content:SetPos(self.CardX + 16 * scale, 0)
 self.Content:SetSize(innerWidth, height)
 self.LayoutWidth, self.LayoutHeight, self.LayoutCount = available, availableHeight, self.Count
 self.LayoutAlign, self.LayoutScale = align, scale
 self:SetTooltip(self.Truncated and translate.Get("notification_details_hint") or nil)
end

function PANEL:AddLabel(text, col, font, extramargin)
 NotificationScale()
 self.LayoutWidth = nil
 self.PlainText = (self.PlainText or "") .. text
 font, col = font or DefaultFont, col or color_white
 surface.SetFont(font)
 local function Token(value, space)
  if #value == 0 then return end
  local width, height = surface.GetTextSize(value)
  self.Parts[#self.Parts + 1] = {text = value, width = width, height = height, font = font, color = col, space = space}
 end
 local position = 1
 while position <= #text do
  local first, last = text:find("%s+", position)
  if not first then Token(text:sub(position), false) break end
  Token(text:sub(position, first - 1), false)
  local whitespace = text:sub(first, last)
  if whitespace:find("\n", 1, true) then
   for _ in whitespace:gmatch("\n") do self.Parts[#self.Parts + 1] = {newline = true} end
  else Token(whitespace, true) end
  position = last + 1
 end
end

function PANEL:AddImage(mat, col)
 self.LayoutWidth = nil
 local img = vgui.Create("DImage", self.Content)
 img:SetImage(mat) img:SetMouseInputEnabled(false)
 if col then img:SetImageColor(col) end
 img:SizeToContents()
 local height = img:GetTall()
 if height > 28 then img:SetSize(28 / height * img:GetWide(), 28) end
 local scale = self.DetailMode and 1 or NotificationScale()
 self.Parts[#self.Parts + 1] = {panel = img, width = img:GetWide() * scale, height = img:GetTall() * scale, baseWidth = img:GetWide(), baseHeight = img:GetTall()}
end

function PANEL:AddKillIcon(class)
	local icondata = killicon.GetIcon(class)

	if icondata then
		self:AddImage(icondata[1], icondata[2])
	else
		local fontdata = killicon.GetFont(class) or killicon.GetFont("default")
		if fontdata then
			self:AddLabel(fontdata[2], fontdata[3], fontdata[1], true)
		end
	end
end

function PANEL:AddPlayerAvatar(pl)
 local size = self:GetTall() >= 32 and 32 or 16
 local bot = pl:IsValid() and pl:IsBot()
 local avatar = vgui.Create(bot and "Panel" or "AvatarImage", self.Content)
 avatar:SetSize(size, size)
 if bot then
  avatar.ZSBotAvatar, avatar.ZSBotColor = true, team.GetColor(pl:Team())
  avatar.Paint = PaintBotAvatar
 elseif pl:IsValid() then avatar:SetPlayer(pl, size) end
 avatar:SetAlpha(220) avatar:SetMouseInputEnabled(false)
 local scale = self.DetailMode and 1 or NotificationScale()
 self.Parts[#self.Parts + 1] = {panel = avatar, width = size * scale, height = size * scale, baseWidth = size, baseHeight = size}
end

function PANEL:SetNotification(...)
	local args = {...}

	local defaultcol = color_white
	local defaultfont
	for k, v in ipairs(args) do
		local vtype = type(v)

		if vtype == "table" then
			if v.r and v.g and v.b then
				defaultcol = v
				self.Accent = v
			elseif v.font then
				if v.font == "" then
					defaultfont = nil
				else
					local th = draw.GetFontHeight(v.font)
					if th then
						defaultfont = fonts[v.font] or v.font
					end
				end
			elseif v.killicon then
				self:AddKillIcon(v.killicon)
				if v.headshot then
					self:AddKillIcon("headshot")
				end
			elseif v.image then
				self:AddImage(v.image, v.color)
			end
		elseif vtype == "Player" then
			self:AddPlayerAvatar(v)

			if v:IsValid() then
				self:AddLabel(" "..v:Name(), team.GetColor(v:Team()), DefaultFontEntity)
			else
				self:AddLabel(" ?", team.GetColor(TEAM_UNASSIGNED), DefaultFontEntity)
			end
		elseif vtype == "Entity" then
			self:AddLabel("["..(v:IsValid() and v:GetClass() or "?").."]", COLOR_RED, DefaultFontEntity)
		else
			local text = tostring(v)

			self:AddLabel(text, defaultcol, defaultfont)
		end
	end
end

vgui.Register("DEXNotification", PANEL, "Panel")

local PANEL  = {}

AccessorFunc(PANEL, "m_Align", "Align", FORCE_NUMBER)
AccessorFunc(PANEL, "m_MessageHeight", "MessageHeight", FORCE_NUMBER)

function PANEL:Init()
	lists[self] = true
	self:SetAlign(LEFT)
	self:SetMessageHeight(32)
	self.ActiveNotifications = {}
	self.Grouped = {}
	self:ParentToHUD()
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
end

function PANEL:Paint()
end

local function RetireNotification(list, child)
 if child.Retired then return end
 child.Retired = true
 child:SetVisible(false)
 if child.Key and list.Grouped[child.Key] == child then list.Grouped[child.Key] = nil end
 child:Remove()
end

function PANEL:ClearNotifications()
	for _, child in ipairs(self.ActiveNotifications) do
		if IsValid(child) then RetireNotification(self, child) end
	end
	self.ActiveNotifications = {}
	self.Grouped = {}
end

function PANEL:TrimNotifications(now)
 local children, used, count = self.ActiveNotifications, 0, 0
 now = now or CurTime()
 for i = #children, 1, -1 do
  local child = children[i]
  if not IsValid(child) or child.Retired or child:IsMarkedForDeletion() or child.DieTime and now >= child.DieTime then
   if IsValid(child) then RetireNotification(self, child)
   else for key, grouped in pairs(self.Grouped) do if grouped == child then self.Grouped[key] = nil end end end
   table.remove(children, i)
  elseif count >= 8 or count > 0 and used + child:GetTall() + 6 * (child.LayoutScale or 1) > self:GetTall() then
   RetireNotification(self, child)
   table.remove(children, i)
  else
   used = used + child:GetTall() + 6 * (child.LayoutScale or 1)
   count = count + 1
  end
 end
end

function PANEL:AddNotification(...)
	local args = {...}
	local now = CurTime()
	local key = GAMEMODE:GetNotificationKey(args)
	local lifetime, count, total = GAMEMODE:GetNotificationOptions(args)
	self:TrimNotifications(now)
	local notif = key and self.Grouped[key]
	if IsValid(notif) and not notif.Retired and now < notif.DieTime and now - notif.LastSeen <= 3 then
		notif.Count = total or math.min(1000000, notif.Count + count)
		notif.LastSeen, notif.DieTime = now, now + lifetime
		notif:UpdateCard()
		notif:SetAlpha(255)
		self:TrimNotifications(now)
		return notif
	end
	notif = vgui.Create("DEXNotification", self)
	notif.MinimumHeight = math.max(40 * NotificationScale(), BetterScreenScale() * self:GetMessageHeight())
	notif:SetTall(notif.MinimumHeight)
	notif:SetNotification(...)
	notif.Count = total or count
	notif.Key, notif.Created, notif.LastSeen, notif.DieTime = key, now, now, now + lifetime
	notif:UpdateCard()
	notif:Dock(TOP)
	notif:SetAlpha(1)
	if key then self.Grouped[key] = notif end
	self.ActiveNotifications[#self.ActiveNotifications + 1] = notif
	self:TrimNotifications(now)
	return notif
end

function PANEL:Think()
	if not self:IsVisible() then return end
	local now = CurTime()
	local scale = NotificationScale()
	for _, notif in ipairs(self.ActiveNotifications) do
		if notif.LayoutScale ~= scale or notif.LayoutWidth ~= self:GetWide() or notif.LayoutHeight ~= self:GetTall() or notif.LayoutAlign ~= (self:GetAlign() or TEXT_ALIGN_CENTER) then notif:UpdateCard() end
		if notif.DieTime then
				local alpha = math.min(1, (now - notif.Created) / 0.16, notif.DieTime - now)
				notif:SetAlpha(math.max(1, math.floor(alpha * 255)))
		end
	end
	self:TrimNotifications(now)
end

vgui.Register("DEXNotificationsList", PANEL, "Panel")
