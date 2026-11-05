local background = Color(15, 20, 26)
local track = Color(38, 46, 54)
local accent = Color(110, 190, 245)
local revision, destinationLetter, heading
local lastPercent,percentText,labelWidth,fittedHeading, fittedScale

local function Finite(value)
 return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

hook.Add("HUDPaint", "HUDPaint_Teleport", function()
 local player = LocalPlayer()
 if not IsValid(player) or not player:Alive() then return end
 local data = player:GetTable()
 local teleport = data.status_sigil_teleport
 if not IsValid(teleport) then return end
 local destination = teleport:GetDestSigil()
 if not IsValid(destination) then return end
 local letter = destination:GetSigilLetter()
 local currentRevision = translate.GetRevision()
 if revision ~= currentRevision or destinationLetter ~= letter then
  revision, destinationLetter, labelWidth = currentRevision, letter, nil
  heading = translate.Format("sigil_teleporting", letter)
 end
 local duration, remaining = teleport:GetMaxTime(), teleport:GetTimeRemaining()
 local fraction = Finite(duration) and duration > 0 and Finite(remaining) and math.Clamp(1 - remaining / duration, 0, 1) or 0
 local scale = BetterScreenScale()
 scale = Finite(scale) and math.Clamp(scale, 0.5, 2) or 1
 local uiScale=GAMEMODE.MenuScale or 1
 local right = GAMEMODE:GetHUDRightEdge()
 local width = math.min(math.max(300, 320 * math.min(scale,1))*uiScale, right - 32*uiScale)
 local both = IsValid(data.status_packup)
 if both then width = math.min(width, (right - 40*uiScale) * 0.5) end
 if labelWidth ~= width or fittedScale ~= uiScale then
  labelWidth, fittedScale = width, uiScale
  fittedHeading = ZSHUDStyle.Fit(heading, "ZSMenuScaledBody", math.max(0, width - 72*uiScale))
 end
 local x, y = (right - width) * 0.5, GAMEMODE:GetStatusHUDTop(data)
 if both then x = x + (width + 8*uiScale) * 0.5 end
 draw.RoundedBox(6*uiScale, x, y, width, 56*uiScale, background)
 draw.SimpleText(fittedHeading, "ZSMenuScaledBody", x + 12*uiScale, y + 9*uiScale, color_white)
 local percent=math.floor(fraction*100)
 if lastPercent~=percent then lastPercent,percentText=percent,percent.."%"end
 draw.SimpleText(percentText, "ZSMenuScaledSmall", x + width - 12*uiScale, y + 12*uiScale, accent, TEXT_ALIGN_RIGHT)
 local barWidth = math.max(0, width - 24*uiScale)
 surface.SetDrawColor(track) surface.DrawRect(x + 12*uiScale, y + 38*uiScale, barWidth, 6*uiScale)
 if fraction > 0 then surface.SetDrawColor(accent) surface.DrawRect(x + 12*uiScale, y + 38*uiScale, barWidth * fraction, 6*uiScale) end
end)
