return function(clock, valid)
 local registry = {records = {}, order = {}, visible = {}, count = 0, speakers = 0}
 function registry:Start(pl)
  if not valid(pl) then return false end
  local record = self.records[pl]
  if record then
   if record.ending then self.speakers = self.speakers + 1 end
   record.ending = nil
  else
   record = {player = pl}
   self.records[pl] = record
   self.order[#self.order + 1] = record
   self.count, self.speakers = self.count + 1, self.speakers + 1
  end
  return true
 end
 function registry:End(pl)
  local record = self.records[pl]
  if record and not record.ending then
   record.ending = clock() + 0.4
   self.speakers = self.speakers - 1
  end
 end
 function registry:Remove(pl)
  local record = self.records[pl]
  if record then
   if not record.ending then self.speakers = self.speakers - 1 end
   record.removed = true
   self.records[pl] = nil
  end
 end
 function registry:Tick(limit)
  local now, nextSlot, shown, activeShown = clock(), 0, 0, 0
  for index = 1, #self.order do
   local record = self.order[index]
   if record.removed or not valid(record.player) or record.ending and now >= record.ending then
    if not record.removed then
     if not record.ending then self.speakers = self.speakers - 1 end
     self.records[record.player] = nil
    end
   else
    nextSlot = nextSlot + 1
    self.order[nextSlot] = record
    if shown < limit then
     shown = shown + 1
     self.visible[shown] = record
     if not record.ending then activeShown = activeShown + 1 end
    end
   end
  end
  for index = nextSlot + 1, #self.order do self.order[index] = nil end
  for index = shown + 1, #self.visible do self.visible[index] = nil end
  self.count = nextSlot
  return self.visible, self.speakers - activeShown, self.count
 end
 return registry
end
