return function()
 local candidates = {}
 local function Clear(x, y, width, height, obstacles, count, gap)
  for index = 1, count do
   local rect = obstacles[index]
   if x < rect.x + rect.width + gap and x + width > rect.x - gap
   and y < rect.y + rect.height + gap and y + height > rect.y - gap then return false end
  end
  return true
 end

 return function(desiredX, desiredY, width, height, right, bottom, obstacles, count, margin, gap)
  local maxX, maxY = right - margin - width, bottom - margin - height
  if maxX < margin or maxY < margin then return end
  local x = math.max(margin, math.min(maxX, desiredX))
  local y = math.max(margin, math.min(maxY, desiredY))
  if Clear(x, y, width, height, obstacles, count, gap) then return x, y end
  candidates[1], candidates[2], candidates[3] = x, margin, maxX
  local used = 3
  for index = 1, count do
   local rect = obstacles[index]
   used = used + 2
   candidates[used - 1], candidates[used] = rect.x - gap - width, rect.x + rect.width + gap
  end
  local bestX, bestY, bestCost
  for index = 1, used do
   local cx = candidates[index]
   if cx >= margin and cx <= maxX then
    local lower = margin
    for position = 1, count + 1 do
     local rect = obstacles[position]
     if position == count + 1 or cx < rect.x + rect.width + gap and cx + width > rect.x - gap then
      local upper = position == count + 1 and maxY or math.min(maxY, rect.y - gap - height)
      if upper >= lower then
       local cy = math.max(lower, math.min(upper, y))
       local cost = (cx - x)^2 + (cy - y)^2
       if not bestCost or cost < bestCost then bestX, bestY, bestCost = cx, cy, cost end
      end
      if position <= count then lower = math.max(lower, rect.y + rect.height + gap) end
      if lower > maxY then break end
     end
    end
   end
  end
  return bestX, bestY
 end
end
