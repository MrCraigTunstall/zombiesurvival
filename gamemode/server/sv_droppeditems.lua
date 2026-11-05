local function Available(ent)
 return IsValid(ent) and not ent.PlacedInMap and not ent.Removing and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())
end
local function SortItems(a,b)
 local ap,bp=a.CleanupPriority or 2,b.CleanupPriority or 2
 if ap~=bp then return ap<bp end
 local ac,bc=a.Created or 0,b.Created or 0
 if ac~=bc then return ac<bc end
 return a:EntIndex()<b:EntIndex()
end
function GM:TrimDroppedItems()
 local limit=tonumber(self.MaxDroppedItems)
 if not limit or limit~=limit or limit==math.huge or limit==-math.huge then limit=32 end
 limit=math.max(0,math.floor(limit))
 local items={}
 for _,class in ipairs({"prop_ammo","prop_weapon"})do
  for _,ent in ipairs(self:GetZSEquipmentEntities(class,true))do if Available(ent)then items[#items+1]=ent end end
 end
 local excess=#items-limit
 if excess<=0 then return 0 end
 table.sort(items,SortItems)
 for index=1,excess do items[index]:Remove()end
 return excess
end
function GM:QueueDroppedItemCleanup()
 if self.ZSDroppedItemCleanupPending then return end
 self.ZSDroppedItemCleanupPending=true
 timer.Simple(0,function()
  local gm=GAMEMODE
  gm.ZSDroppedItemCleanupPending=nil
  gm:TrimDroppedItems()
 end)
end
