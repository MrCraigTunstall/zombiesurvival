AddCSLuaFile()
if SERVER or BuffedFPS then return end
BuffedFPS = true

local setFont, textSize, textPos = surface.SetFont, surface.GetTextSize, surface.SetTextPos
local textColor, drawText = surface.SetTextColor, surface.DrawText
local setTexture, drawColor = surface.SetTexture, surface.SetDrawColor
local rect, texturedRect, texturedUV = surface.DrawRect, surface.DrawTexturedRect, surface.DrawTexturedRectUV
local ceil, floor, min, max, round = math.ceil, math.floor, math.min, math.max, math.Round
local find, gmatch = string.find, string.gmatch
local corners = {surface.GetTextureID("gui/corner8"), surface.GetTextureID("gui/corner16"), surface.GetTextureID("gui/corner32"), surface.GetTextureID("gui/corner64"), surface.GetTextureID("gui/corner512")}
local white = surface.GetTextureID("vgui/white")
local fontHeights = {}
local fontMetrics, metricSlots, metricCursor = {}, {}, 1
local createFont = surface.CreateFont
surface.CreateFont = function(name, ...)
	fontHeights[name] = nil
	fontMetrics[name] = nil
	return createFont(name, ...)
end

local function measureText(text, font)
	local bucket = fontMetrics[font]
	local entry = bucket and bucket.values[text]
	if entry then return entry.width, entry.height end
	local width, height = textSize(text)
	if #text > 1024 then return width, height end
	entry = metricSlots[metricCursor]
	if entry then
		local previous = entry.bucket
		previous.values[entry.text] = nil
		previous.count = previous.count - 1
		if previous.count == 0 and fontMetrics[entry.font] == previous then fontMetrics[entry.font] = nil end
	else
		entry = {}
		metricSlots[metricCursor] = entry
	end
	bucket = fontMetrics[font]
	if not bucket then bucket = {count = 0, values = {}}; fontMetrics[font] = bucket end
	entry.font, entry.text, entry.bucket, entry.width, entry.height = font, text, bucket, width, height
	bucket.values[text], bucket.count = entry, bucket.count + 1
	metricCursor = metricCursor % 2048 + 1
	return width, height
end

function GM:MouthMoveAnimation(ply)
	return
end

local function fontHeight(font)
	font = font or "DermaDefault"
	local height = fontHeights[font]
	if height ~= nil then return height end
	setFont(font)
	local _, measured = textSize("W")
	fontHeights[font] = measured
	return measured
end

local function paintText(text, x, y, color, xalign, yalign, width, height)
	if xalign == 1 then x = x - width / 2 elseif xalign == 2 then x = x - width end
	if yalign == 1 then y = y - height / 2 elseif yalign == 4 then y = y - height end
	textPos(ceil(x), ceil(y))
	if color then textColor(color.r, color.g, color.b, color.a) else textColor(255, 255, 255, 255) end
	drawText(text)
end

local function simpleText(text, font, x, y, color, xalign, yalign)
	text = tostring(text)
	font = font or "DermaDefault"
	setFont(font)
	local width, height = measureText(text, font)
	paintText(text, x or 0, y or 0, color, xalign, yalign, width, height)
	return width, height
end

local function roundedBoxEx(radius, x, y, width, height, color, tl, tr, bl, br)
	if width <= 0 or height <= 0 then return end
	drawColor(color.r, color.g, color.b, color.a)
	if radius <= 0 then rect(x, y, width, height); return end
	x, y, width, height = round(x), round(y), round(width), round(height)
	radius = min(round(radius), floor(width / 2), floor(height / 2))
	if radius <= 0 then rect(x, y, width, height); return end
	rect(x + radius, y, width - radius * 2, height)
	rect(x, y + radius, radius, height - radius * 2)
	rect(x + width - radius, y + radius, radius, height - radius * 2)
	local texture = radius > 64 and corners[5] or radius > 32 and corners[4] or radius > 16 and corners[3] or radius > 8 and corners[2] or corners[1]
	setTexture(texture)
	if tl then texturedUV(x, y, radius, radius, 0, 0, 1, 1) else rect(x, y, radius, radius) end
	if tr then texturedUV(x + width - radius, y, radius, radius, 1, 0, 0, 1) else rect(x + width - radius, y, radius, radius) end
	if bl then texturedUV(x, y + height - radius, radius, radius, 0, 1, 1, 0) else rect(x, y + height - radius, radius, radius) end
	if br then texturedUV(x + width - radius, y + height - radius, radius, radius, 1, 1, 0, 0) else rect(x + width - radius, y + height - radius, radius, radius) end
end

local function roundedBox(radius, x, y, width, height, color)
	return roundedBoxEx(radius, x, y, width, height, color, true, true, true, true)
end

local function multilineText(text, font, x, y, color, xalign)
	font, x, y = font or "DermaDefault", x or 0, y or 0
	text = tostring(text)
	setFont(font)
	local _, lineHeight = textSize("\n")
	local curX, curY = x, y
	for line in gmatch(text, "[^\n]*") do
		if #line == 0 then
			curX, curY = x, curY + lineHeight / 2
		elseif find(line, "\t", 1, true) then
			for tabs, segment in gmatch(line, "(\t*)([^\t]*)") do
				curX = ceil((curX + 50 * max(#tabs - 1, 0)) / 50) * 50
				if #segment > 0 then
					local width, height = measureText(segment, font)
					paintText(segment, curX, curY, color, xalign, nil, width, height)
					curX = curX + width
				end
			end
		else
			local width = (xalign == 1 or xalign == 2) and measureText(line, font) or 0
			paintText(line, curX, curY, color, xalign, nil, width, 0)
		end
	end
end

function draw.WordBox(radius, x, y, text, font, color, fontColor, xalign, yalign)
	setFont(font)
	local width, height = measureText(text, font)
	if xalign == 1 then x = x - radius - width / 2 elseif xalign == 2 then x = x - radius * 2 - width end
	if yalign == 1 then y = y - radius - height / 2 elseif yalign == 4 then y = y - radius * 2 - height end
	roundedBox(radius, x, y, width + radius * 2, height + radius * 2, color)
	textColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
	textPos(x + radius, y + radius)
	drawText(text)
	return width + radius * 2, height + radius * 2
end

local shadow = {r = 0, g = 0, b = 0, a = 200}
function draw.TextShadow(tab, distance, alpha)
	local text = tostring(tab.text)
	local font = tab.font or "DermaDefault"
	setFont(font)
	local width, height = measureText(text, font)
	shadow.a = alpha or 200
	paintText(text, tab.pos[1] + distance, tab.pos[2] + distance, shadow, tab.xalign, tab.yalign, width, height)
	paintText(text, tab.pos[1], tab.pos[2], tab.color, tab.xalign, tab.yalign, width, height)
	return width, height
end

function draw.TexturedQuad(tab)
	local color = tab.color or color_white
	setTexture(tab.texture)
	drawColor(color.r, color.g, color.b, color.a)
	texturedRect(tab.x, tab.y, tab.w, tab.h)
end

function draw.NoTexture()
	setTexture(white)
end

function draw.SimpleTextOutlined(text, font, x, y, color, xalign, yalign, outlineWidth, outlineColor)
	text, x, y = tostring(text), x or 0, y or 0
	font = font or "DermaDefault"
	setFont(font)
	local width, height = measureText(text, font)
	local step = max(outlineWidth * 2 / 3, 1)
	for dx = -outlineWidth, outlineWidth, step do
		for dy = -outlineWidth, outlineWidth, step do
			paintText(text, x + dx, y + dy, outlineColor, xalign, yalign, width, height)
		end
	end
	paintText(text, x, y, color, xalign, yalign, width, height)
	return width, height
end

function draw.Text(tab)
	return simpleText(tab.text, tab.font, tab.pos[1], tab.pos[2], tab.color, tab.xalign, tab.yalign)
end

draw.GetFontHeight = fontHeight
draw.SimpleText = simpleText
draw.DrawText = multilineText
draw.RoundedBox = roundedBox
draw.RoundedBoxEx = roundedBoxEx
