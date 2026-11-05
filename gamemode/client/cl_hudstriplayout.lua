return function()
 local rows, blocked = {}, {}
 local scale = 1
 local bestX, bestY, bestWidth, bestCount, bestDistance, itemCount, preferredY
 local function Before(a, b) return a.x < b.x end
 local function Consider(y, left, finish)
  left, finish = math.ceil(left), math.floor(finish)
  local span = finish - left
  if span < (136 * scale) then return end
  local count = math.min(6, itemCount, math.floor((span + 8 * scale) / (144 * scale)))
  if count < 1 then return end
  local cardWidth = math.floor(math.min((180 * scale), (span + 8 * scale) / count) - 8 * scale)
  local used, distance = count * (cardWidth + 8 * scale) - 8 * scale, math.abs(y - preferredY)
  if not bestCount or count > bestCount or count == bestCount and (distance < bestDistance or distance == bestDistance and cardWidth > bestWidth) then
   bestX, bestY, bestWidth, bestCount, bestDistance = math.floor(left + (span - used) / 2), y, cardWidth, count, distance
  end
 end
 return function(width, height, stripHeight, items, obstacles, preferred, uiScale)
  scale = uiScale or 1
  bestX, bestY, bestWidth, bestCount, bestDistance = nil, nil, nil, nil, nil
  itemCount = items
  for index = #rows, 1, -1 do rows[index] = nil end
  preferred = math.max(16 * scale, math.min(height - stripHeight - 16 * scale, preferred))
  preferredY = preferred
  rows[1], rows[2], rows[3] = preferred, 16 * scale, height - stripHeight - 16 * scale
  for _, rect in ipairs(obstacles) do
   rows[#rows + 1] = rect.y - stripHeight - 8 * scale
   rows[#rows + 1] = rect.y + rect.height + 8 * scale
  end
  for _, y in ipairs(rows) do
   if y >= 16 * scale and y + stripHeight <= height - 16 * scale then
    for index = #blocked, 1, -1 do blocked[index] = nil end
    for _, rect in ipairs(obstacles) do
     if y < rect.y + rect.height + 8 * scale and y + stripHeight > rect.y - 8 * scale then blocked[#blocked + 1] = rect end
    end
    table.sort(blocked, Before)
    local cursor, right = 16 * scale, width - 16 * scale
    for _, rect in ipairs(blocked) do
     Consider(y, cursor, math.min(right, rect.x - 8 * scale))
     cursor = math.max(cursor, rect.x + rect.width + 8 * scale)
     if cursor >= right then break end
    end
    Consider(y, cursor, right)
   end
  end
  return bestX, bestY, bestWidth, bestCount
 end
end
