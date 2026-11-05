ZSHUDStyle = {}
local style = ZSHUDStyle
style.Background = Color(13, 20, 27, 240)
style.Surface = Color(27, 38, 47, 245)
style.Glass = Color(13, 20, 27, 112)
style.GlassSurface = Color(27, 38, 47, 68)
style.GlassBorder = Color(158, 180, 190, 45)
style.Border = Color(57, 75, 85, 180)
style.Text = Color(240, 246, 247)
style.Muted = Color(215, 225, 232)
style.Accent = Color(107, 229, 177)
style.Danger = Color(255, 112, 120)
style.Warning = Color(245, 194, 112)
style.Track = Color(48, 64, 72)
style.Shadow = Color(0, 0, 0, 65)

function style.Scale()
 return math.Clamp(ScrH() / 900, 0.9, 2.4)
end

function style.RebuildFonts()
 local scale = style.Scale()
 for name, spec in pairs({Small = {13, 500}, Label = {14, 600}, Title = {17, 700}, Number = {30, 700}, Health = {44, 700}}) do
  surface.CreateFont("ZSHUD" .. name, {font = "Roboto", size = math.floor(spec[1] * scale + 0.5), weight = spec[2], antialias = true, extended = true, shadow = true})
 end
end

function style.Fit(text, font, width)
 surface.SetFont(font)
 if surface.GetTextSize(text) <= width then return text end
 local clipped = ""
 for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
  local candidate = clipped .. character
  if surface.GetTextSize(candidate .. "…") > width then break end
  clipped = candidate
 end
 return clipped .. "…"
end

function style.Card(x, y, width, height, accent, glass)
 local scale = style.Scale()
 local radius = 9 * scale
 if glass then
  draw.RoundedBox(radius, x, y, width, height, style.Glass)
  surface.SetDrawColor(style.GlassBorder)
  surface.DrawRect(x + radius, y, width - radius * 2, 1)
  surface.DrawRect(x + radius, y + height - 1, width - radius * 2, 1)
 else
 draw.RoundedBox(radius, x, y + 2, width, height, style.Shadow)
 draw.RoundedBox(radius, x, y, width, height, style.Border)
 draw.RoundedBox(radius - 1, x + 1, y + 1, width - 2, height - 2, style.Background)
 end
 if accent then
  surface.SetDrawColor(accent)
  surface.DrawRect(x + 16 * scale, y, math.min(34 * scale, math.max(0, width - 32 * scale)), math.max(1, 2 * scale))
 end
end

style.RebuildFonts()
hook.Add("OnScreenSizeChanged", "ZSHUDStyleFonts", style.RebuildFonts)
