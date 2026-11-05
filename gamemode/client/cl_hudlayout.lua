function GM:GetHUDRightEdge()
 local menu = self.HumanMenuPanel
 if IsValid(menu) and menu:IsVisible() then
  local x = menu:GetPos()
  return math.Clamp(x, 0, ScrW())
 end
 return ScrW()
end

function GM:GetBreathHUDLayout()
 local scale = self.MenuScale or 1
 local right = self:GetHUDRightEdge()
 local width = math.min(320 * scale, math.max(0, right * 0.5 - 24 * scale))
 local x, y = right - width - 16 * scale, 72 * scale
 local state = self.GameStatePanel
 if IsValid(state) and state:IsVisible() then
  local sx, sy = state:GetPos()
  if x < sx + state:GetWide() and x + width > sx and y < sy + state:GetTall() and y + 56 * scale > sy then
   y = sy + state:GetTall() + 8 * scale
  end
 end
 return x, y, width, 56 * scale
end

function GM:GetStatusHUDTop(data)
 local scale = self.MenuScale or 1
 local y = math.max(136 * scale, ScrH() * 0.28)
 local state = self.GameStatePanel
 if IsValid(state) and state:IsVisible() then
  local _, top = state:GetPos()
  y = math.max(y, top + state:GetTall() + 8 * scale)
 end
 if IsValid(data.status_drown) then
  local _, top, _, height = self:GetBreathHUDLayout()
  y = math.max(y, top + height + 8 * scale)
 end
 return y
end

function GM:GetHUDStatusBottom(data)
 if not data then return 0 end
 local scale = self.MenuScale or 1
 local bottom = 0
 if IsValid(data.status_drown) then
  local _, y, _, height = self:GetBreathHUDLayout()
  bottom = y + height
 end
 local top = self:GetStatusHUDTop(data)
 local pack = data.status_packup
 if IsValid(pack) then bottom = math.max(bottom, top + (pack:GetNotOwner() and 96 or 56) * scale) end
 if IsValid(data.status_sigil_teleport) then bottom = math.max(bottom, top + 56 * scale) end
 return bottom
end

function GM:GetCompactNotificationRegion()
 local right = self:GetHUDRightEdge()
 if right >= 800 then return end
 local scale = BetterScreenScale()
 local width = (right - 32 * scale) * 0.5
 local x, bottom = right - 16 * scale - width, ScrH() - 112 * scale
 local health = self.HealthHUD
 if IsValid(health) and health:IsVisible() then
  local hx, hy = health:GetPos()
  if x < hx + health:GetWide() and x + width > hx then
   local start = hx + health:GetWide() + 8 * scale
   local space = right - 16 * scale - start
   if space >= 96 * math.max(1, scale) then x, width = start, space
   else bottom = math.min(bottom, hy - 12 * scale) end
  end
 end
 local notifications = self.TopNotificationHUD
 local top = math.max(16 * scale, IsValid(notifications) and (notifications.HUDStatusBottom or 0) + 8 * scale or 0)
 local state = self.GameStatePanel
 if IsValid(state) and state:IsVisible() then
  local sx, sy = state:GetPos()
  if x < sx + state:GetWide() and x + width > sx then top = math.max(top, sy + state:GetTall() + 8 * scale) end
 end
 local height = math.max(0, bottom - top)
 return x, top, width, height, math.min(8 * scale, math.max(0, height - 80 * math.max(1, scale)))
end

local labelObstacles, labelPool = {}, {}
local labelFrame, labelCount, labelRevision = -1, 0, 0
local labelUsed, labelChanged

local function LabelRect(x, y, width, height)
 if width <= 0 or height <= 0 then return end
 labelUsed = labelUsed + 1
 local rect = labelPool[labelUsed]
 if not rect then rect = {} labelPool[labelUsed] = rect end
 if rect.x ~= x or rect.y ~= y or rect.width ~= width or rect.height ~= height then labelChanged = true end
 rect.x, rect.y, rect.width, rect.height = x, y, width, height
 labelObstacles[labelUsed] = rect
end

local function LabelPanel(panel)
 if not IsValid(panel) or not panel:IsVisible() then return end
 local x, y = panel:GetPos()
 LabelRect(x, y, panel:GetWide(), panel:GetTall())
end

local function LabelNotifications(list)
 if not IsValid(list) or not list:IsVisible() or not list.ActiveNotifications then return end
 local lx, ly = list:GetPos()
 local right, bottom = lx + list:GetWide(), ly + list:GetTall()
 for _, child in ipairs(list.ActiveNotifications) do
  if IsValid(child) and not child.Retired and child:IsVisible() then
   local x, y = child:LocalToScreen(child.CardX or 0, 0)
   local cr, cb = math.min(right, x + (child.CardWidth or child:GetWide())), math.min(bottom, y + child:GetTall())
   x, y = math.max(lx, x), math.max(ly, y)
   LabelRect(x, y, cr - x, cb - y)
  end
 end
end

local function LabelOrder(a, b)
 if a.y ~= b.y then return a.y < b.y end
 if a.x ~= b.x then return a.x < b.x end
 if a.width ~= b.width then return a.width < b.width end
 return a.height < b.height
end

local function BaseLabelObstacles(self)
 local frame = FrameNumber()
 if labelFrame == frame then return labelObstacles, labelCount, labelRevision end
 labelFrame, labelUsed, labelChanged = frame, 0, false
 LabelPanel(self.GameStatePanel)
 LabelPanel(self.HealthHUD)
 local respawn = self.RespawnHUDData
 if respawn and respawn.x and IsValid(MySelf) and MySelf:Team() == TEAM_UNDEAD then LabelRect(respawn.x, respawn.y, respawn.width, respawn.height) end
 local voice = self.ZSVoiceHUD
 if voice then LabelPanel(voice.panel) end
 local prep = self.PreparationHUDData
 if prep then LabelRect(prep.x, prep.y, prep.width, prep.height) end
 LabelNotifications(self.TopNotificationHUD)
 LabelNotifications(self.CenterNotificationHUD)
 if chat and chat.GetChatBoxPos and chat.GetChatBoxSize then
  local x, y = chat.GetChatBoxPos()
  local width, height = chat.GetChatBoxSize()
  LabelRect(x, y, width, height)
 end
 local pl = LocalPlayer()
 if IsValid(pl) and pl:Alive() then
  local data, scale, right = pl:GetTable(), self.MenuScale or 1, self:GetHUDRightEdge()
  if IsValid(data.status_drown) then LabelRect(self:GetBreathHUDLayout()) end
  local pack, tele = data.status_packup, data.status_sigil_teleport
  local hasPack = IsValid(pack)
  local hasTele = IsValid(tele) and IsValid(tele:GetDestSigil())
  if hasPack or hasTele then
   local width = math.min(math.max(300, 320 * math.min(BetterScreenScale(), 1)) * scale, right - 32 * scale)
   if hasPack and hasTele then width = math.min(width, (right - 40 * scale) * 0.5) * 2 + 8 * scale end
   LabelRect((right - width) * 0.5, self:GetStatusHUDTop(data), width, (hasPack and pack:GetNotOwner() and 96 or 56) * scale)
  end
 end
 local selector = self.ZSWeaponSelector
 if selector and selector.alive and selector.untilTime > RealTime() and not vgui.CursorVisible() then
  local bounds = selector.bounds
  if bounds and bounds.x then LabelRect(bounds.x, bounds.y, bounds.width, bounds.height) end
 end
 if self.ZombieEscape and self.BuildZombieEscapeBossHUD then
  local rows, scale = self:BuildZombieEscapeBossHUD(), ZSHUDStyle.Scale()
  local maximum = math.min(4, math.max(1, math.floor(ScrH() * 0.36 / (76 * scale))))
  for index = 1, math.min(#rows, maximum) do
   local rect = self:GetZombieEscapeBossPlacement(rows[index], index, scale)
   LabelRect(rect.x, rect.y, rect.w, rect.h)
  end
 end
 if labelCount ~= labelUsed then labelChanged = true end
 for index = labelUsed + 1, #labelObstacles do labelObstacles[index] = nil end
 labelCount = labelUsed
 table.sort(labelObstacles, LabelOrder)
 if labelChanged then labelRevision = labelRevision + 1 end
 return labelObstacles, labelCount, labelRevision
end

local combinedLabels, fearRect = {}, {}
local combinedBase, combinedCount, combinedRevision, hadFear = -1, 0, 0, false
function GM:GetHUDLabelObstacles(ignoreFear)
 local base,count,revision=BaseLabelObstacles(self)
 if ignoreFear then return base,count,revision end
 local data=self.FearHUDData
 local active=data and data.x and data.frame==FrameNumber()or false
 local changed=combinedBase~=revision or hadFear~=active
 if active and (fearRect.x~=data.x or fearRect.y~=data.y or fearRect.width~=data.width or fearRect.height~=data.height)then changed=true end
 if changed then
  combinedBase,hadFear=revision,active
  for index=1,count do combinedLabels[index]=base[index]end
  combinedCount=count
  if active then
   fearRect.x,fearRect.y,fearRect.width,fearRect.height=data.x,data.y,data.width,data.height
   combinedCount=count+1 combinedLabels[combinedCount]=fearRect
  end
  for index=combinedCount+1,#combinedLabels do combinedLabels[index]=nil end
  table.sort(combinedLabels,LabelOrder)
  combinedRevision=combinedRevision+1
 end
 return combinedLabels,combinedCount,combinedRevision
end
