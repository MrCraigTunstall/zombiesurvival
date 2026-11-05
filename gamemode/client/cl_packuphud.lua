local background = Color(15, 20, 26)
local track = Color(38, 46, 54)
local ownColor = Color(80, 205, 135)
local otherColor = Color(245, 190, 90)
local muted = Color(175, 189, 202)
local revision, requiredCount, packingText, otherText, requiredText
local lastPercent,percentText,labelWidth,fittedPacking,fittedOther,fittedRequired, fittedScale

local function Finite(value)
 return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function DrawPackUpBar(x, y, fraction, notowner, screenscale, required, maximumWidth)
 if not Finite(fraction) then fraction = 0 end
 fraction = math.Clamp(fraction, 0, 1)
 screenscale = Finite(screenscale) and math.Clamp(screenscale, 0.5, 2) or 1
 local scale=GAMEMODE.MenuScale or 1
 required = Finite(required) and math.max(1, math.floor(required)) or 4
 local currentRevision = translate.GetRevision()
 if revision ~= currentRevision or requiredCount ~= required then
  revision, requiredCount, labelWidth = currentRevision, required, nil
  packingText, otherText = translate.Get("packing"), translate.Get("packing_others_object")
  requiredText = translate.Format("requires_x_people", required)
 end
 local width = math.min(math.max(300, 320 * math.min(screenscale,1))*scale, GAMEMODE:GetHUDRightEdge() - 32*scale, maximumWidth or math.huge)
 if labelWidth ~= width or fittedScale ~= scale then
  labelWidth, fittedScale = width, scale
  fittedPacking = ZSHUDStyle.Fit(packingText, "ZSMenuScaledBody", math.max(0, width - 72*scale))
  fittedOther = ZSHUDStyle.Fit(otherText, "ZSMenuScaledSmall", math.max(0, width - 24*scale))
  fittedRequired = ZSHUDStyle.Fit(requiredText, "ZSMenuScaledSmall", math.max(0, width - 24*scale))
 end
 local height = (notowner and 96 or 56)*scale
 local start = x - width * 0.5
 local color = notowner and otherColor or ownColor
 draw.RoundedBox(6*scale, start, y, width, height, background)
 draw.SimpleText(fittedPacking, "ZSMenuScaledBody", start + 12*scale, y + 9*scale, color_white)
 local percent=math.floor(fraction*100)
 if lastPercent~=percent then lastPercent,percentText=percent,percent.."%"end
 draw.SimpleText(percentText, "ZSMenuScaledSmall", start + width - 12*scale, y + 12*scale, color, TEXT_ALIGN_RIGHT)
 if notowner then
  draw.SimpleText(fittedOther, "ZSMenuScaledSmall", start + 12*scale, y + 33*scale, muted)
  draw.SimpleText(fittedRequired, "ZSMenuScaledSmall", start + 12*scale, y + 53*scale, color)
 end
 local barY = y + height - 18*scale
 local barWidth = math.max(0, width - 24*scale)
 surface.SetDrawColor(track) surface.DrawRect(start + 12*scale, barY, barWidth, 6*scale)
 local fill = barWidth * fraction
 if fill > 0 then surface.SetDrawColor(color) surface.DrawRect(start + 12*scale, barY, fill, 6*scale) end
end

hook.Add("HUDPaint", "HUDPaint_Packup", function()
 local player = LocalPlayer()
 if not IsValid(player) or not player:Alive() then return end
 local data = player:GetTable()
 local packup = data.status_packup
 if not IsValid(packup) then return end
 local duration = packup:GetMaxTime()
 local remaining = packup:GetTimeRemaining()
 local fraction = Finite(duration) and duration > 0 and Finite(remaining) and 1 - remaining / duration or 0
 local right = GAMEMODE:GetHUDRightEdge()
 local x, scale = right * 0.5, BetterScreenScale()
 local maximumWidth
 local uiScale=GAMEMODE.MenuScale or 1
 local teleport = data.status_sigil_teleport
 if IsValid(teleport) and IsValid(teleport:GetDestSigil()) then
  scale = Finite(scale) and math.Clamp(scale, 0.5, 2) or 1
  scale = math.min(scale, (right - 40*uiScale) / (640*uiScale))
  maximumWidth = math.max(0, (right - 40*uiScale) * 0.5)
  local width = math.min(math.max(300, 320 * math.min(scale,1))*uiScale, right - 32*uiScale, maximumWidth)
  x = x - (width + 8*uiScale) * 0.5
 end
 DrawPackUpBar(x, GAMEMODE:GetStatusHUDTop(data), fraction, packup:GetNotOwner(), scale, packup.PackUpOverride, maximumWidth)
end)
