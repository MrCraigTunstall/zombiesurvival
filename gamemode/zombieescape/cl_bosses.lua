local style = ZSHUDStyle
local records, visible, empty = {}, {}, {}
GM.ZEBossHUDRecords = records
local nextRefresh = 0
local nextIndex = 0
local moreCount, moreRevision, moreText
local sightTrace = {mask = MASK_VISIBLE, output = {}}
local placements = {}
local maximumRows = 4
local function Number(value)
 return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
local function Index(value)
 return Number(value) and value > 0 and value <= 65535 and value == math.floor(value)
end
local function Row(index)
 local row = records[index]
 if not row then
  nextIndex = nextIndex + 1
  row = {Index = index, Order = nextIndex, Halo = {}}
  records[index] = row
 end
 return row
end
function GM:SetZombieEscapeBossName(index, name)
 if not Index(index) or type(name) ~= "string" or #name > 512 then return false end
 local previous = records[index]
 if previous and previous.Resolved and not IsValid(previous.Entity) then records[index] = nil end
 local row = Row(index)
 row.Name = name ~= "" and string.upper(name) or nil
 row.FitWidth = nil
 nextRefresh = 0
 return true
end
function GM:SetZombieEscapeBossHealth(index, health, maximum)
 if not Index(index) or not Number(health) or not Number(maximum) or maximum <= 0 then return false end
 if health <= 0 then return self:RemoveZombieEscapeBoss(index) end
 local row = Row(index)
 maximum = math.max(health, maximum)
 if row.Health == health and row.Maximum == maximum then return true end
 local fraction = math.Clamp(health / maximum, 0, 1)
 if not row.Fraction or fraction > row.Fraction then row.Trail = fraction
 elseif fraction < row.Fraction then row.TrailUntil = RealTime() + 0.3 end
 row.Health, row.Maximum, row.Fraction = health, maximum, fraction
 row.Color = fraction <= 0.25 and style.Danger or fraction <= 0.5 and style.Warning or style.Accent
 row.Values = math.ceil(health) .. " / " .. math.ceil(maximum) .. "   ·   " .. math.ceil(fraction * 100) .. "%"
 row.FitWidth = nil
 nextRefresh = 0
 return true
end
function GM:RemoveZombieEscapeBoss(index)
 if not Index(index) then return false end
 records[index] = nil
 nextRefresh = 0
 return true
end
function GM:ClearZombieEscapeBossHUD()
 for index in pairs(records) do records[index] = nil end
 for index in pairs(visible) do visible[index] = nil end
 nextRefresh = 0
end
local function Nearer(a, b)
 if a.Distance ~= b.Distance then return a.Distance < b.Distance end
 return a.Order < b.Order
end
function GM:BuildZombieEscapeBossHUD()
 if self.RoundEnded or self.FilmMode or not next(records) then return empty end
 local now = RealTime()
 if now < nextRefresh then return visible end
 nextRefresh = now + 0.1
 for index in pairs(visible) do visible[index] = nil end
 local pl = LocalPlayer()
 if not IsValid(pl) then return visible end
 local position = pl:GetPos()
 for index, row in pairs(records) do
  local ent = row.Entity
  if not IsValid(ent) then
   if row.Resolved then records[index] = nil
   else
    ent = Entity(index)
    if IsValid(ent) then row.Entity, row.Resolved = ent, true end
   end
  end
  if IsValid(ent) and row.Health then
   row.Distance = position:DistToSqr(ent:GetPos())
   if row.Distance <= 16777216 then
    row.Halo[1] = ent
    visible[#visible + 1] = row
   end
  end
 end
 table.sort(visible, Nearer)
 sightTrace.start, sightTrace.filter = EyePos(), pl
 for index = 1, math.min(#visible, maximumRows) do
  local row = visible[index]
  row.InSight = false
  if not row.Entity:IsDormant() and not row.Entity:GetNoDraw() then
   sightTrace.endpos = row.Entity:WorldSpaceCenter()
   util.TraceLine(sightTrace)
   row.InSight = not sightTrace.output.Hit or sightTrace.output.Entity == row.Entity
  end
 end
 return visible
end
local function Layout(row, width, scale, revision)
 if row.FitWidth == width and row.FitRevision == revision then return end
 row.FitWidth, row.FitRevision = width, revision
 row.ValueText = style.Fit(row.Values or "", "ZSHUDSmall", width - 32 * scale)
 row.Title = style.Fit(row.Name or translate.Get("ze_boss"), "ZSHUDTitle", width - 32 * scale)
end
local function Overlaps(x, y, width, height, other, gap)
 return x < other.x + other.w + gap and x + width + gap > other.x and y < other.y + other.h + gap and y + height + gap > other.y
end
function GM:GetZombieEscapeBossPlacement(row, slot, scale)
 local screenWidth, screenHeight = ScrW(), ScrH()
 local margin, gap, height = 16 * scale, 8 * scale, 68 * scale
 local left = math.min(340 * scale, screenWidth * 0.48) + margin
 local width = math.min(560 * scale, screenWidth - margin * 2)
 local available = screenWidth - (left + gap) * 2
 local top = margin
 if available >= 340 * scale then width = math.min(width, available)
 else top = margin + 156 * scale + gap end
 local fallbackY = top + (slot - 1) * (height + gap)
 local x, y = (screenWidth - width) * 0.5, fallbackY
 local attached = false
 if row.InSight and IsValid(row.Entity) and not row.Entity:IsDormant() then
  local ent = row.Entity
  local bounds = ent:OBBMaxs()
  local point = ent:LocalToWorld(Vector(0, 0, bounds.z + 12)):ToScreen()
  local worldWidth = math.min(360 * scale, screenWidth - margin * 2)
  local worldX, worldY = point.x - worldWidth * 0.5, point.y - height - gap
  if point.visible and worldX >= margin and worldX + worldWidth <= screenWidth - margin and worldY >= margin and worldY + height < screenHeight * 0.72 and not (worldX < left + gap and worldY < margin + 156 * scale + gap) then
   attached = true
   for previous = 1, slot - 1 do
    if Overlaps(worldX, worldY, worldWidth, height, placements[previous], gap) then attached = false; break end
   end
   if attached then x, y, width = worldX, worldY, worldWidth end
  end
 end
 if not attached then
  for attempt = 1, slot do
   local moved = false
   for previous = 1, slot - 1 do
    local other = placements[previous]
    if Overlaps(x, y, width, height, other, gap) then y = other.y + other.h + gap; moved = true end
   end
   if not moved then break end
  end
 end
 local placement = placements[slot] or {}
 placements[slot] = placement
 placement.x, placement.y, placement.w, placement.h, placement.attached = x, y, width, height, attached
 return placement
end
function GM:DrawZombieEscapeBossHUD()
 local rows = self:BuildZombieEscapeBossHUD()
 if #rows == 0 then return end
 local scale = style.Scale()
 local maximum = math.min(maximumRows, math.max(1, math.floor(ScrH() * 0.36 / (76 * scale))))
 local now, delta = RealTime(), FrameTime() * 0.85
 local revision = translate.GetRevision()
 for index = 1, math.min(#rows, maximum) do
  local row = rows[index]
  local placement = self:GetZombieEscapeBossPlacement(row, index, scale)
  local x, y, width, height = placement.x, placement.y, placement.w, placement.h
  Layout(row, width, scale, revision)
  style.Card(x, y, width, height, row.Color, true)
  draw.SimpleText(row.Title, "ZSHUDTitle", x + width * 0.5, y + 17 * scale, style.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  draw.SimpleText(row.ValueText, "ZSHUDSmall", x + width * 0.5, y + 53 * scale, style.Muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  if now >= (row.TrailUntil or 0) then row.Trail = math.Approach(row.Trail or row.Fraction, row.Fraction, delta) end
  row.Display = Lerp(1 - math.exp(-FrameTime() * 14), row.Display or row.Fraction, row.Fraction)
  local barWidth, barY = width - 32 * scale, y + 32 * scale
  surface.SetDrawColor(style.Track);surface.DrawRect(x + 16 * scale, barY, barWidth, 9 * scale)
  surface.SetDrawColor(style.Warning);surface.DrawRect(x + 16 * scale, barY, barWidth * row.Trail, 9 * scale)
  surface.SetDrawColor(row.Color);surface.DrawRect(x + 16 * scale, barY, barWidth * row.Display, 9 * scale)
  surface.SetDrawColor(style.GlassBorder)
  for segment = 1, 3 do surface.DrawRect(x + 16 * scale + barWidth * segment * 0.25, barY, 1, 9 * scale) end
 end
 if #rows > maximum then
  if moreCount ~= #rows - maximum or moreRevision ~= revision then
   moreCount, moreRevision = #rows - maximum, revision
   moreText = translate.Format("ze_more_bosses", moreCount)
  end
  local last = placements[maximum]
  draw.SimpleText(moreText, "ZSHUDSmall", ScrW() * 0.5, last.y + last.h + 8 * scale, style.Muted, TEXT_ALIGN_CENTER)
 end
end
hook.Add("HUDPaint", "BossHealth", function() GAMEMODE:DrawZombieEscapeBossHUD() end)
hook.Add("PreDrawHalos", "ZSBossHalos", function()
 local rows = GAMEMODE:BuildZombieEscapeBossHUD()
 local maximum = math.min(maximumRows, math.max(1, math.floor(ScrH() * 0.36 / (76 * style.Scale()))))
 for index = 1, math.min(#rows, maximum) do
  local row = rows[index]
  if row.InSight then halo.Add(row.Halo, row.Color, 1, 1, 1, true, false) end
 end
end)
hook.Add("PreCleanupMap", "ZSBossHUDReset", function() GAMEMODE:ClearZombieEscapeBossHUD() end)
hook.Add("OnScreenSizeChanged", "ZSBossHUDLayout", function()
 for _, row in pairs(records) do row.FitWidth = nil end
 nextRefresh = 0
end)
net.Receive("BossSpawn", function(length)
 if length < 40 then return end
 GAMEMODE:SetZombieEscapeBossName(net.ReadFloat(), net.ReadString())
end)
net.Receive("BossTakeDamage", function(length)
 if length < 96 then return end
 local index, health, maximum = net.ReadFloat(), net.ReadFloat(), net.ReadFloat()
 GAMEMODE:SetZombieEscapeBossHealth(index, health, maximum)
end)
net.Receive("BossDefeated", function(length)
 if length >= 32 then GAMEMODE:RemoveZombieEscapeBoss(net.ReadFloat()) end
end)
