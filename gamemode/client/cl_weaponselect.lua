local factory = include("cl_weaponinventory.lua")
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local solveLayout = include("cl_hudstriplayout.lua")()
local gm = GM or GAMEMODE
if gm.ZSWeaponSelector then gm.ZSWeaponSelector:Destroy() end
local state = {inventory = factory(IsValid), untilTime = 0, nextRefresh = 0, alive = true, bounds = {}}
gm.ZSWeaponSelector = state
local custom = CreateClientConVar("zs_custom_weaponselect", "1", true, false, translate.Get("weaponselect_desc"))
local mode = CreateClientConVar("zs_weaponselect_mode", "-1", true, false, translate.Get("weaponselect_mode_desc"), -1, 1)
local fast = GetConVar("hud_fastswitch")
local background, muted, selected = Color(22, 30, 39, 245), Color(175, 189, 202), Color(80, 205, 135)
local selectedBackground = Color(28, 66, 53, 245)
local function WeaponName(weapon, class, zombieClass)
 if zombieClass and class == zombieClass.SWEP then
  local key = zombieClass.TranslationName or zombieClass.Name
  if key then return translate.Get(key) end
 end
 return language.GetPhrase(weapon:GetPrintName() or class)
end
local function Allowed(pl)
 return custom:GetBool() and IsValid(pl) and pl == LocalPlayer() and pl:Alive() and not vgui.CursorVisible()
end
function state:Refresh(pl, force)
 if self.owner ~= pl then self.inventory:Clear() self.owner = pl self.selected = nil self.pending = nil self.requested = nil self.nextRefresh = 0 end
 if force or RealTime() >= self.nextRefresh then
  self.inventory:Refresh(pl:GetWeapons())
  self.nextRefresh = RealTime() + 0.25
  if self.selected and not self.inventory.indices[self.selected] then self.selected = nil self.pending = nil self.requested = nil end
 end
 local active = pl:GetActiveWeapon()
 if self.requested and (active == self.requested or RealTime() >= self.requestDeadline) then self.requested = nil end
 if not self.pending and not self.requested then self.selected = self.inventory.indices[active] and active or nil end
end
function state:Commit(pl)
 local weapon = self.selected
 if IsValid(weapon) and weapon:GetOwner() == pl and self.inventory.indices[weapon] then
  self.requested, self.requestDeadline = weapon, RealTime() + 1
  input.SelectWeapon(weapon)
  return true
 end
end
function state:Bind(pl, bind, pressed)
 if not self.alive or not pressed or not Allowed(pl) then return end
 bind = input.TranslateAlias(bind) or bind
 local open = RealTime() < self.untilTime
 if bind == "cancelselect" and open then self.untilTime = 0 self.pending = nil self.selected = nil self.requested = nil return true end
 if bind == "+attack" and open and self.pending then
  self.blockAttack = true
  self:Refresh(pl, true)
  self:Commit(pl)
  self.untilTime = 0 self.pending = nil
  return true
 end
 local direction = bind == "invnext" and 1 or bind == "invprev" and -1
 local slot = bind:match("^slot(%d+)$")
 slot = slot and tonumber(slot)
 if not direction and (not slot or slot < 1 or slot > 10) then return end
 self:Refresh(pl, true)
 local from = open and self.selected or pl:GetActiveWeapon()
 local weapon
 if direction then weapon = self.inventory:Cycle(from, direction) else weapon = self.inventory:Slot(from, slot - 1) end
 if not IsValid(weapon) or weapon:GetOwner() ~= pl then return end
 self.selected, self.untilTime = weapon, RealTime() + 3
 self.pending = not (mode:GetInt() == 1 or mode:GetInt() < 0 and fast and fast:GetInt() > 0)
 if self.pending then self.requested = nil end
 if not self.pending then self:Commit(pl) end
 return true
end
function state:SuppressAttack(command)
 if not self.blockAttack then return end
 if command:KeyDown(IN_ATTACK) then command:RemoveKey(IN_ATTACK) else self.blockAttack = nil end
end
local function Fit(text, width)
 if surface.GetTextSize(text) <= width then return text end
 local count = utf8.len(text) or #text
 while count > 0 do
  local finish = utf8.offset(text, count + 1)
  local candidate = string.sub(text, 1, finish and finish - 1 or #text) .. "…"
  if surface.GetTextSize(candidate) <= width then return candidate end
  count = count - 1
 end
 return "…"
end
function state:AddObstacle(x, y, width, height)
 if width <= 0 or height <= 0 then return end
 self.obstacleUsed = self.obstacleUsed + 1
 local index = self.obstacleUsed
 local rect = self.obstaclePool[index] or {}
 self.obstaclePool[index], self.obstacles[index] = rect, rect
 rect.x, rect.y, rect.width, rect.height = x, y, width, height
end
function state:AddPanel(panel, parent)
 if not IsValid(panel) or not panel:IsVisible() then return end
 local x, y = panel:GetPos()
 if parent then local px, py = parent:GetPos() x, y = x + px, y + py end
 self:AddObstacle(x, y, panel:GetWide(), panel:GetTall())
end
function state:AddNotifications(list)
 if not IsValid(list) or not list:IsVisible() then return end
 for _, child in ipairs(list:GetChildren()) do if not child.Retired then self:AddPanel(child, list) end end
end
function state:Layout()
 if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
 local voice = GAMEMODE.ZSVoiceHUD
 local voicePanel = voice and voice.panel
 local voiceCount = IsValid(voicePanel) and voicePanel:IsVisible() and voice.registry.count or 0
 if self.nextLayout and RealTime() < self.nextLayout and self.screenWidth == ScrW() and self.screenHeight == ScrH() and self.voicePanel == voicePanel and self.voiceCount == voiceCount and self.inventoryRevision == self.inventory.revision and self.scale == (GAMEMODE.MenuScale or 1) then return end
 self.nextLayout, self.screenWidth, self.screenHeight = RealTime() + 0.1, ScrW(), ScrH()
 self.scale = GAMEMODE.MenuScale or 1
 self.voicePanel, self.voiceCount, self.inventoryRevision = voicePanel, voiceCount, self.inventory.revision
 self.obstacles, self.obstaclePool = self.obstacles or {}, self.obstaclePool or {}
 self.obstacleUsed = 0
 self:AddPanel(GAMEMODE.GameStatePanel) self:AddPanel(GAMEMODE.HealthHUD)
 local prep = GAMEMODE.PreparationHUDData
 if prep then self:AddObstacle(prep.x, prep.y, prep.width, prep.height) end
 if voice then self:AddPanel(voice.panel) end
 self:AddNotifications(GAMEMODE.CenterNotificationHUD) self:AddNotifications(GAMEMODE.TopNotificationHUD)
 local chatX, chatY = chat.GetChatBoxPos()
 local chatWidth, chatHeight = chat.GetChatBoxSize()
 self:AddObstacle(chatX, chatY, chatWidth, chatHeight)
 for index = self.obstacleUsed + 1, #self.obstacles do self.obstacles[index] = nil end
 self.layoutX, self.layoutY, self.cardWidth, self.cardCount = solveLayout(ScrW(), ScrH(), U(104), #self.inventory.order, self.obstacles, ScrH() - U(208), self.scale)
end
function state:ResetSelection()
 self.untilTime, self.nextRefresh, self.nextLayout = 0, 0, 0
 self.owner, self.selected, self.pending, self.requested, self.requestDeadline, self.blockAttack = nil, nil, nil, nil, nil, nil
 self.inventory:Clear()
end
function state:Paint()
 local pl = LocalPlayer()
 if not self.alive or RealTime() >= self.untilTime then return end
 if not Allowed(pl) then
  if IsValid(pl) and not pl:Alive() then self:ResetSelection() end
  return
 end
 self:Refresh(pl)
 local order = self.inventory.order
 if #order == 0 then return end
 self:Layout()
 if not self.layoutX then return end
 local left, top, width, height, limit = self.layoutX, self.layoutY + U(24), self.cardWidth, U(80), self.cardCount
 local index = self.inventory.indices[self.selected] or self.inventory.indices[pl:GetActiveWeapon()] or 1
 local first = math.Clamp(index - math.floor(limit / 2), 1, #order - limit + 1)
 local revision = translate.GetRevision()
 if self.revision ~= revision or self.labelPending ~= self.pending or self.shown ~= limit or self.count ~= #order then
  self.revision, self.labelPending, self.shown, self.count = revision, self.pending, limit, #order
  self.header = translate.Format(self.pending and "weaponselect_confirm_header" or "weaponselect_header", limit, #order)
  self.equipped = translate.Get("weaponselect_equipped")
 end
 draw.RoundedBox(U(4), left, top - U(24), limit * (width + U(8)) - U(8), U(22), background)
 draw.SimpleText(self.header, "ZSMenuScaledSmall", left + U(8), top - U(20), color_white)
 local active = pl:GetActiveWeapon()
 local zombieClass = pl:Team() == TEAM_UNDEAD and pl:GetZombieClassTable()
 for offset = 0, limit - 1 do
  local record = order[first + offset]
  local weapon = record.weapon
  if IsValid(weapon) then
   local x = left + offset * (width + U(8))
   draw.RoundedBox(U(6), x, top, width, height, weapon == self.selected and selectedBackground or background)
   surface.SetDrawColor(weapon == self.selected and selected or muted)
   surface.DrawRect(x, top + U(8), U(3), height - U(16))
   local name = WeaponName(weapon, record.class, zombieClass)
   if record.name ~= name or record.width ~= width or record.revision ~= revision then
    record.name, record.width, record.revision = name, width, revision
    surface.SetFont("ZSMenuScaledBody") record.fitted = Fit(name, width - U(20))
   end
   local tier = GAMEMODE:GetWeaponTier(GAMEMODE.WeaponTierItems and GAMEMODE.WeaponTierItems[record.class])
   if tier ~= record.tier or record.tierRevision ~= revision then
    record.tier, record.tierRevision = tier, revision
    record.tierText = tier and translate.Format("weapon_tier_label", tier) or nil
   end
   if record.tierText then draw.SimpleText(record.tierText, "ZSMenuScaledSmall", x + width - U(10), top + U(8), selected, TEXT_ALIGN_RIGHT) end
   draw.SimpleText(record.slot + 1, "ZSMenuScaledSmall", x + U(10), top + U(8), muted)
   draw.SimpleText(record.fitted, "ZSMenuScaledBody", x + U(10), top + U(27), color_white)
   local clip, capacity, ammoType = weapon:Clip1(), weapon:GetMaxClip1(), weapon:GetPrimaryAmmoType()
   if capacity > 0 and clip >= 0 and ammoType >= 0 then
    local reserve = pl:GetAmmoCount(ammoType)
    if record.clip ~= clip or record.reserve ~= reserve then record.clip, record.reserve, record.ammoText = clip, reserve, clip .. " / " .. reserve end
    draw.SimpleText(record.ammoText, "ZSMenuScaledSmall", x + U(10), top + U(51), muted)
    surface.SetDrawColor(45, 57, 69) surface.DrawRect(x + U(10), top + U(71), width - U(20), U(3))
    surface.SetDrawColor(selected) surface.DrawRect(x + U(10), top + U(71), (width - U(20)) * math.Clamp(clip / capacity, 0, 1), U(3))
   elseif weapon == active then draw.SimpleText(self.equipped, "ZSMenuScaledSmall", x + U(10), top + U(51), selected) end
  end
 end
 self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height = left, top - U(24), limit * (width + U(8)) - U(8), height + U(24)
end
hook.Add("PlayerBindPress", "ZSWeaponSelector", function(pl, bind, pressed) return state:Bind(pl, bind, pressed) end)
hook.Add("HUDPaint", "ZSWeaponSelector", function() state:Paint() end)
hook.Add("CreateMove", "ZSWeaponSelector", function(command) state:SuppressAttack(command) end)
hook.Add("HUDShouldDraw", "ZSWeaponSelector", function(name) if name == "CHudWeaponSelection" and Allowed(LocalPlayer()) then return false end end)
function state:Destroy()
 self.alive = false
 for _, event in ipairs({"PlayerBindPress", "HUDPaint", "HUDShouldDraw", "CreateMove"}) do hook.Remove(event, "ZSWeaponSelector") end
 self.inventory:Clear()
 if gm.ZSWeaponSelector == self then gm.ZSWeaponSelector = nil end
end
return state
