return function(actions, valid)
 local state = {actions = actions, supported = {}, revision = 0}
 function state:Refresh(pl)
  if not valid(pl) then
   if self.owner then
    self.owner, self.model, self.count = nil, nil, nil
    for key in pairs(self.supported) do self.supported[key] = nil end
    self.revision = self.revision + 1
   end
   return false
  end
  local model, count = pl:GetModel(), pl:GetSequenceCount()
  if self.owner == pl and self.model == model and self.count == count then return false end
  self.owner, self.model, self.count = pl, model, count
  for _, action in ipairs(self.actions) do
   local sequence = count and count > 0 and type(action.activity) == "number" and pl:SelectWeightedSequence(action.activity) or -1
   self.supported[action.command] = sequence >= 0
  end
  self.revision = self.revision + 1
  return true
 end
 return state
end
