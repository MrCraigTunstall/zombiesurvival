return function(valid)
 local inventory = {records = {}, order = {}, indices = {}, ranges = {}, revision = 0, generation = 0, sorts = 0}
 local function Before(a, b)
  if a.slot ~= b.slot then return a.slot < b.slot end
  if a.position ~= b.position then return a.position < b.position end
  if a.class ~= b.class then return a.class < b.class end
  return a.id < b.id
 end
 function inventory:Refresh(weapons)
  self.generation = self.generation + 1
  local generation, changed = self.generation, false
  for _, weapon in ipairs(weapons) do
   if valid(weapon) then
    local record = self.records[weapon]
    local slot, position, class, id = weapon:GetSlot(), weapon:GetSlotPos(), weapon:GetClass(), weapon:EntIndex()
    if not record then
     record = {weapon = weapon}
     self.records[weapon] = record
     changed = true
    end
    if record.slot ~= slot or record.position ~= position or record.class ~= class or record.id ~= id then
     record.slot, record.position, record.class, record.id = slot, position, class, id
     changed = true
    end
    record.seen = generation
   end
  end
  for weapon, record in pairs(self.records) do
   if record.seen ~= generation then self.records[weapon] = nil changed = true end
  end
  if not changed then return false end
  for index = #self.order, 1, -1 do self.order[index] = nil end
  for weapon in pairs(self.indices) do self.indices[weapon] = nil end
  for slot in pairs(self.ranges) do self.ranges[slot] = nil end
  for _, record in pairs(self.records) do self.order[#self.order + 1] = record end
  table.sort(self.order, Before)
  self.sorts = self.sorts + 1
  for index, record in ipairs(self.order) do
   self.indices[record.weapon] = index
   local range = self.ranges[record.slot]
   if range then range.last = index else self.ranges[record.slot] = {first = index, last = index} end
  end
  self.revision = self.revision + 1
  return true
 end
 function inventory:Cycle(from, direction)
  local count = #self.order
  if count == 0 then return end
  local index = self.indices[from] or (direction > 0 and 0 or 1)
  return self.order[(index - 1 + direction) % count + 1].weapon
 end
 function inventory:Slot(from, slot)
  local range = self.ranges[slot]
  if not range then return end
  local index = self.indices[from]
  if not index or index < range.first or index >= range.last then index = range.first else index = index + 1 end
  return self.order[index].weapon
 end
 function inventory:Clear()
  for key in pairs(self.records) do self.records[key] = nil end
  for key in pairs(self.indices) do self.indices[key] = nil end
  for key in pairs(self.ranges) do self.ranges[key] = nil end
  for index = #self.order, 1, -1 do self.order[index] = nil end
  self.revision = self.revision + 1
 end
 return inventory
end
