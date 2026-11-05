local background = Color(15, 20, 26)
local track = Color(38, 46, 54)
local air = Color(90, 170, 245)
local lowAir = Color(245, 100, 90)
local revision, label, lastPercent, percentText, labelWidth, fittedLabel, fittedScale

function DrawBreathBar(drown)
 local fraction = type(drown) == "number" and drown == drown and drown ~= math.huge and drown ~= -math.huge and 1 - math.Clamp(drown, 0, 1) or 0
 local currentRevision = translate.GetRevision()
 if revision ~= currentRevision then revision, label, labelWidth = currentRevision, translate.Get("breath"), nil end
 local percent = math.floor(fraction * 100 + 0.00001)
 if lastPercent ~= percent then lastPercent, percentText = percent, percent .. "%" end
 local scale=GAMEMODE.MenuScale or 1
 local x, y, width = GAMEMODE:GetBreathHUDLayout()
 if labelWidth ~= width or fittedScale ~= scale then
  labelWidth, fittedScale = width, scale
  fittedLabel = ZSHUDStyle.Fit(label, "ZSMenuScaledBody", math.max(0, width - 72*scale))
 end
 local color = fraction <= 0.2 and lowAir or air
 draw.RoundedBox(6*scale, x, y, width, 56*scale, background)
 draw.SimpleText(fittedLabel, "ZSMenuScaledBody", x + 12*scale, y + 9*scale, color_white)
 draw.SimpleText(percentText, "ZSMenuScaledSmall", x + width - 12*scale, y + 12*scale, color, TEXT_ALIGN_RIGHT)
 local barWidth = math.max(0, width - 24*scale)
 surface.SetDrawColor(track) surface.DrawRect(x + 12*scale, y + 38*scale, barWidth, 6*scale)
 if fraction > 0 then surface.SetDrawColor(color) surface.DrawRect(x + 12*scale, y + 38*scale, barWidth * fraction, 6*scale) end
end

hook.Add("HUDPaint", "HUDPaint_Drown", function()
 local player = LocalPlayer()
 local data = IsValid(player) and player:Alive() and player:GetTable()
 local drown = data and data.status_drown
 local active = IsValid(drown)
 local notifications = GAMEMODE.TopNotificationHUD
 if IsValid(notifications) then
  local _, top, _, height = GAMEMODE:GetBreathHUDLayout()
  local offset = active and top + height + 8*(GAMEMODE.MenuScale or 1) or nil
  local right = GAMEMODE:GetHUDRightEdge()
  local lower = right < 800 and GAMEMODE:GetHUDStatusBottom(data) or 0
  if notifications.BreathHUDOffset ~= offset or notifications.HUDRightEdge ~= right or notifications.HUDStatusBottom ~= lower then
   notifications.BreathHUDOffset, notifications.HUDRightEdge, notifications.HUDStatusBottom = offset, right, lower
   notifications:InvalidateLayout(true)
   local center = GAMEMODE.CenterNotificationHUD
   if IsValid(center) then center:InvalidateLayout(true) end
  end
 end
 if active then DrawBreathBar(drown:GetDrown()) end
end)
