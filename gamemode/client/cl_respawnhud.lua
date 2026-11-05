local style = ZSHUDStyle
local baby, babyUntil, babyGetter

local function HasBaby(gm, now)
 if now >= (babyUntil or 0) or babyGetter ~= gm.GetZSEquipmentEntities or baby and not IsValid(baby) then
  baby, babyUntil, babyGetter = nil, now + .25, gm.GetZSEquipmentEntities
  for _, ent in ipairs(gm:GetZSEquipmentEntities("prop_thrownbaby", true)) do
   if IsValid(ent) and ent:GetSettled() then baby = ent break end
  end
 end
 return IsValid(baby) and baby:GetSettled()
end

local function Lines(text, width)
 local lines, line = {}, ""
 surface.SetFont("ZSHUDSmall")
 for word in text:gmatch("%S+") do
  local candidate = line == "" and word or line .. " " .. word
  if surface.GetTextSize(candidate) > width and line ~= "" then
   if #lines == 1 then lines[2] = style.Fit(line .. " " .. word .. " …", "ZSHUDSmall", width) return lines end
   lines[#lines + 1] = style.Fit(line, "ZSHUDSmall", width)
   line = word
  else line = candidate end
 end
 if line ~= "" then lines[#lines + 1] = style.Fit(line, "ZSHUDSmall", width) end
 for index, value in ipairs(lines) do lines[index] = style.Fit(value, "ZSHUDSmall", width) end
 return lines
end

local function Row(data, count, text, color)
 local row = data.rows[count]
 if not row then row = {} data.rows[count] = row end
 local width = data.width - 32 * data.scale
 if row.raw ~= text or row.width ~= width then row.raw, row.width, row.lines = text, width, Lines(text, width) end
 row.color = color
 return count + 1
end

function GM:BuildRespawnHUD(obsmode)
 local pl = MySelf
 if not IsValid(pl) then self.RespawnHUDData = nil return end
 obsmode = obsmode or pl:GetObserverMode()
 local active, alive = self:GetWaveActive(), pl:Alive()
 local waiting = obsmode == OBS_MODE_NONE and not active and not alive
 local nextBoss = self.NextBossZombie
 local boss = IsValid(nextBoss) and (waiting or not GetGlobalBool("waveactive") and alive)
 if obsmode == OBS_MODE_NONE and not waiting and not boss then self.RespawnHUDData = nil return end
 local scale, right, now = style.Scale(), self:GetHUDRightEdge(), RealTime()
 local width = math.min(420 * scale, right * .48)
 local target = obsmode == OBS_MODE_CHASE and pl:GetObserverTarget() or NULL
 local data = self.RespawnHUDCache
 if not data then data = {rows = {}} self.RespawnHUDCache = data end
 local revision = translate.GetRevision()
 if data.width ~= width or data.scale ~= scale or data.revision ~= revision or data.mode ~= obsmode or data.active ~= active or data.alive ~= alive or data.target ~= target or data.boss ~= nextBoss then data.nextUpdate = 0 end
 if now >= (data.nextUpdate or 0) then
  data.nextUpdate, data.width, data.scale, data.revision = now + .1, width, scale, revision
  data.mode, data.active, data.alive, data.target, data.boss = obsmode, active, alive, target, nextBoss
  local title = translate.Get(waiting and "waiting_for_next_wave" or alive and "class_zombie" or "you_have_died")
  local count = 1
  if obsmode ~= OBS_MODE_NONE then
   local dyn
   if obsmode == OBS_MODE_CHASE and IsValid(target) then
    if target:IsPlayer() and target:Team() == TEAM_UNDEAD then title = translate.Format("observing_x", target:Name(), math.max(0, target:Health())) end
    dyn = self:GetDynamicSpawning() and self:DynamicSpawnIsValid(target)
   end
   if active then count = Row(data, count, translate.Get(dyn and "press_lmb_to_spawn_on_them" or "press_lmb_to_spawn"), dyn and style.Accent or style.Text) end
   count = Row(data, count, translate.Get("press_rmb_to_cycle_targets"), style.Muted)
   count = Row(data, count, translate.Get("press_reload_to_spawn_at_normal_point"), style.Muted)
   count = Row(data, count, translate.Get("press_jump_to_free_roam"), style.Muted)
  end
  if boss then
   local text = nextBoss == pl and translate.Format("you_will_be_x_soon", "'" .. self.NextBossZombieClass .. "'") or translate.Format("x_will_be_y_soon", nextBoss:Name(), "'" .. self.NextBossZombieClass .. "'")
   count = Row(data, count, text, nextBoss == pl and style.Warning or style.Muted)
  end
  if (obsmode ~= OBS_MODE_NONE or waiting and pl:GetZombieClassTable().NeverAlive) and HasBaby(self, now) then count = Row(data, count, translate.Format("press_walk_to_spawn_as_x", self.ZombieClasses["Gore Child"].Name), style.Accent) end
  data.title = style.Fit(title, "ZSHUDLabel", width - 32 * scale)
  data.rawTitle, data.count = title, count - 1
  local height = 44 * scale
  for index = 1, data.count do height = height + (#data.rows[index].lines * 16 + 6) * scale end
  data.height = height + 8 * scale
 end
 self.RespawnHUDData = data
 return data
end

local function Avoid(data, panel, x, y, gap)
 if not IsValid(panel) or not panel:IsVisible() then return y end
 if panel.ActiveNotifications then
  for _, card in ipairs(panel.ActiveNotifications) do
   if IsValid(card) and not card.Retired and card:IsVisible() then
    local cx, cy = card:LocalToScreen(card.CardX or 0, 0)
    if x < cx + (card.CardWidth or card:GetWide()) and x + data.width > cx then y = math.max(y, cy + card:GetTall() + gap) end
   end
  end
 else
  local px, py = panel:GetPos()
  if x < px + panel:GetWide() and x + data.width > px then y = math.max(y, py + panel:GetTall() + gap) end
 end
 return y
end

function GM:DrawRespawnHUD(obsmode)
 local data = self:BuildRespawnHUD(obsmode)
 if not data then return end
 local scale, gap = data.scale, 10 * data.scale
 local x, y = self:GetHUDRightEdge() - data.width - 16 * scale, 16 * scale
 y = Avoid(data, self.GameStatePanel, x, y, gap)
 y = Avoid(data, self.TopNotificationHUD, x, y, gap)
 y = Avoid(data, self.CenterNotificationHUD, x, y, gap)
 if MySelf:Alive() then y = math.max(y, self:GetHUDStatusBottom(MySelf:GetTable()) + gap) end
 y = math.Clamp(y, 16 * scale, math.max(16 * scale, ScrH() - data.height - 16 * scale))
 data.x, data.y = math.max(0, x), y
 style.Card(data.x, y, data.width, data.height, style.Accent, true)
 draw.SimpleText(data.title, "ZSHUDLabel", data.x + 16 * scale, y + 16 * scale, style.Text)
 y = y + 44 * scale
 for index = 1, data.count do
  local row = data.rows[index]
  for _, text in ipairs(row.lines) do draw.SimpleText(text, "ZSHUDSmall", data.x + 16 * scale, y, row.color) y = y + 16 * scale end
  y = y + 6 * scale
 end
end

function GM:ZombieObserverHUD(obsmode)
 return self:DrawRespawnHUD(obsmode)
end
