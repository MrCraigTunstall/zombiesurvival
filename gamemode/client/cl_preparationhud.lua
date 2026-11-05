surface.CreateFont("ZSPreparationTitle", {font = "Roboto", size = 18, weight = 700, antialias = true, extended = true})
surface.CreateFont("ZSPreparationTitleSmall", {font = "Roboto", size = 14, weight = 700, antialias = true, extended = true})
surface.CreateFont("ZSPreparationText", {font = "Roboto", size = 14, weight = 500, antialias = true, extended = true})
local style = ZSHUDStyle
local muted, accent, warning = style.Muted, style.Accent, style.Danger
local function U(value, scale) return math.floor(value * scale + 0.5) end
hook.Add("StartChat", "ZSPreparationHUDChat", function()
 if GAMEMODE then GAMEMODE.PreparationChatOpen = true end
end)
hook.Add("FinishChat", "ZSPreparationHUDChat", function()
 if GAMEMODE then GAMEMODE.PreparationChatOpen = false end
end)

local function Fit(text, width)
 if surface.GetTextSize(text) <= width then return text end
 local clipped = ""
 for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
  local candidate = clipped .. character
  if surface.GetTextSize(candidate .. "...") > width then break end
  clipped = candidate
 end
 return clipped .. "..."
end

local function Wrap(text, width, limit)
 local lines, line = {}, ""
 for word in text:gmatch("%S+") do
  local candidate = line == "" and word or line .. " " .. word
  if surface.GetTextSize(candidate) > width and line ~= "" then
   lines[#lines + 1] = line
   if #lines == limit then return lines end
   line = Fit(word, width)
  else line = Fit(candidate, width) end
 end
 if line ~= "" and #lines < limit then lines[#lines + 1] = line end
 return lines
end

function GM:BuildPreparationHUD()
 if self.RoundEnded or self:GetWave() ~= 0 or self:GetWaveActive() then
  self.PreparationHUDData = nil
  return
 end
 local width, height, now = ScrW(), ScrH(), RealTime()
 local scale = style.Scale()
 local x, y = U(16, scale), U(160, scale)
 if IsValid(self.GameStatePanel) then
  local px, py = self.GameStatePanel:GetPos()
  x, y = px, py + self.GameStatePanel:GetTall() + U(12, scale)
 end
 local bottom = math.min(height - U(100, scale), height * 0.6 - U(8, scale))
 local _, chatY = chat.GetChatBoxPos()
 if self.PreparationChatOpen and chatY > 0 then bottom = math.min(bottom, chatY - U(12, scale)) end
 if IsValid(self.HealthHUD) then
  local _, healthY = self.HealthHUD:GetPos()
  if healthY > 0 then bottom = math.min(bottom, healthY - U(12, scale)) end
 end
 local cardWidth = IsValid(self.GameStatePanel) and self.GameStatePanel:GetWide() or math.min(340 * style.Scale(), width * 0.48)
 local maximumHeight = bottom - y
 if maximumHeight < U(74, scale) then self.PreparationHUDData = nil return end
 local revision = translate.GetRevision()
 local data = self.PreparationHUDData
 if data and data.screenWidth == width and data.screenHeight == height and data.x == x and data.y == y
 and data.scale == scale and data.maximumHeight == maximumHeight and data.revision == revision and now < data.nextRefresh then
  return data
 end
 data = {screenWidth = width, screenHeight = height, x = x, y = y, width = cardWidth,
  maximumHeight = maximumHeight, scale = scale, revision = revision, nextRefresh = now + 0.25,
  rows = {}, volunteers = {}, volunteerCount = 0}
 local innerWidth, rowY = cardWidth - U(32, scale), U(14, scale)
 local titleFont = "ZSHUDLabel"
 surface.SetFont(titleFont)
 local _, titleHeight = surface.GetTextSize("Mg")
 titleHeight = titleHeight + U(3, scale)
 for _, text in ipairs(Wrap(translate.Get("zombie_volunteers"), innerWidth - U(32, scale), 1)) do
  data.rows[#data.rows + 1] = {text = text, font = titleFont, y = rowY, height = titleHeight - U(3, scale), color = color_white}
  rowY = rowY + titleHeight
 end
 rowY = rowY + U(8, scale)
 surface.SetFont("ZSHUDSmall")
 local _, textHeight = surface.GetTextSize("Mg")
 local lineHeight = textHeight + U(2, scale)
 for _, text in ipairs(Wrap(translate.Get("stay_from_zombie_spawns"), innerWidth, 3)) do
  if rowY + lineHeight + U(10, scale) > maximumHeight then break end
  data.rows[#data.rows + 1] = {text = text, font = "ZSHUDSmall", y = rowY, height = textHeight, color = muted}
  rowY = rowY + lineHeight
 end
 rowY = rowY + U(8, scale)
 local maximumRows = math.max(0, math.min(4, math.floor((maximumHeight - rowY - U(30, scale)) / lineHeight)))
 local selected, localVolunteer, localSelected = {}, false, false
 for _, pl in ipairs(self.ZombieVolunteers or {}) do
  if pl:IsValid() then
   data.volunteerCount = data.volunteerCount + 1
   if pl == MySelf then localVolunteer = true end
   if #selected < maximumRows then
    selected[#selected + 1] = pl
    if pl == MySelf then localSelected = true end
   end
  end
 end
 if localVolunteer and not localSelected and #selected > 0 then selected[#selected] = MySelf end
 for _, pl in ipairs(selected) do
  local row = {text = Fit(pl:Name(), innerWidth), font = "ZSHUDSmall", y = rowY, height = textHeight,
   color = pl == MySelf and warning or pl:IsFriend() and accent or muted}
  data.volunteers[#data.volunteers + 1] = row
  data.rows[#data.rows + 1] = row
  rowY = rowY + lineHeight
 end
 local hidden = data.volunteerCount - #data.volunteers
 if hidden > 0 and rowY + lineHeight + U(10, scale) <= maximumHeight then
  data.rows[#data.rows + 1] = {text = Fit(translate.Format("preparation_more_volunteers", hidden), innerWidth), font = "ZSHUDSmall", y = rowY, height = textHeight, color = muted}
  rowY = rowY + lineHeight
 end
 data.height = math.min(maximumHeight, rowY + U(10, scale))
 self.PreparationHUDData = data
 return data
end

function GM:DrawPreparationHUD()
 local data = self:BuildPreparationHUD()
 if not data then return end
 style.Card(data.x, data.y, data.width, data.height, nil, true)
 draw.RoundedBox(U(4, data.scale), data.x + data.width - U(42, data.scale), data.y + U(12, data.scale), U(26, data.scale), U(20, data.scale), style.GlassSurface)
 draw.SimpleText(data.volunteerCount, "ZSHUDSmall", data.x + data.width - U(29, data.scale), data.y + U(22, data.scale), accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
 for _, row in ipairs(data.rows) do
  if row.y + row.height <= data.height then
   draw.SimpleText(row.text, row.font, data.x + U(16, data.scale), data.y + row.y, row.color)
  end
 end
end
