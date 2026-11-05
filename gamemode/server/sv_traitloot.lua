local function Positive(value)
 return type(value)=="number" and value==value and value>0 and value<math.huge
end
function GM:GetTraitLootAmmoCatalog()
 local cached=self.ZSTraitLootAmmoCatalog
 if cached and cached.cache==self.AmmoCache and cached.resupply==self.AmmoResupply then return cached.entries end
 local entries={}
 for name in pairs(self.AmmoResupply)do
  if type(name)=="string" and Positive(self.AmmoCache[name]) and game.GetAmmoID(name)>=0 then entries[#entries+1]=name end
 end
 table.sort(entries)
 self.ZSTraitLootAmmoCatalog={cache=self.AmmoCache,resupply=self.AmmoResupply,entries=entries}
 return entries
end
function GM:CreateTraitAmmoDrops(position,count)
 if not Positive(count)then return 0 end
 count=math.min(4,math.floor(count))
 local catalog=self:GetTraitLootAmmoCatalog()
 if #catalog==0 then return 0 end
 local spawned=0
 for index=1,count do
  local name=catalog[math.random(#catalog)];local amount=self.AmmoCache[name]
  if Positive(amount)then
   local ent=ents.Create("prop_ammo")
   if not IsValid(ent)then break end
   ent:SetAmmoType(name);ent:SetAmmo(math.max(1,math.min(500,math.floor(amount))))
   ent:SetPos(position+Vector((index-1)*10-15,0,12));ent:Spawn()
   spawned=spawned+1
  end
 end
 return spawned
end
function GM:TraitGraveLoot(victim,attacker)
 if self.RoundEnded or not IsValid(victim) or not victim:IsPlayer() or victim:Team()~=TEAM_UNDEAD
  or victim.ZSTraitGraveClaimed or not self:HasPlayerTrait(attacker,"gravethief")then return 0 end
 local class=victim:GetZombieClassTable()
 if class.NeverAlive or not Positive(class.Points)then return 0 end
 victim.ZSTraitGraveClaimed=true
 if math.Rand(0,1)>=(class.Boss and 0.5 or 0.1)then return 0 end
 return self:CreateTraitAmmoDrops(victim:GetPos(),math.random(1,2)*(class.Boss and 2 or 1))
end
hook.Add("PostHumanKilledZombie","ZSTraitGraveLoot",function(victim,attacker)GAMEMODE:TraitGraveLoot(victim,attacker)end)
hook.Add("PlayerSpawn","ZSTraitGraveLoot",function(pl)pl.ZSTraitGraveClaimed=nil end)

local crateModels={
 ["models/props_junk/wood_crate001a.mdl"]=true,
 ["models/props_junk/wood_crate001a_damaged.mdl"]=true,
 ["models/props_junk/wood_crate001a_damagedmax.mdl"]=true,
 ["models/props_junk/wood_crate002a.mdl"]=true,
 ["models/items/item_item_crate.mdl"]=true
}
function GM:GetTraitLootWeaponCatalog()
 local items,crafts=self.Items or {},self.Crafts or {}
 local classic=self:IsClassicMode()
 local cached=self.ZSTraitLootWeaponCatalog
 if cached and cached.items==self.Items and cached.crafts==self.Crafts and cached.itemCount==#items and cached.craftCount==#crafts
  and cached.classic==classic and cached.escape==self.ZombieEscape and #cached.entries>0 then return cached.entries,cached.total end
 local candidates={}
 local function Add(class,cost)
  if type(class)~="string" or string.sub(class,1,10)~="weapon_zs_" or weapons.IsBasedOn(class,"weapon_zs_zombie") then return end
  local stored=weapons.GetStored(class)
  if not stored or stored.ZombieOnly then return end
  local base=stored.Base and weapons.GetStored(stored.Base)
  local model=stored.WorldModel or base and base.WorldModel
  if type(model)~="string" or model=="" or not util.IsValidModel(model) then return end
  local candidate=candidates[class]
  if not candidate then candidate={class=class,tier=stored.Tier};candidates[class]=candidate end
  if type(cost)=="number" and cost==cost and cost>=0 and cost<math.huge and (not candidate.cost or cost<candidate.cost) then candidate.cost=cost end
 end
 for _,item in ipairs(items)do if not (classic and item.NoClassicMode or self.ZombieEscape and item.NoZombieEscape) then Add(item.SWEP,item.Worth)end end
 for _,recipe in ipairs(crafts)do if not (classic and recipe.NoClassicMode or self.ZombieEscape and recipe.NoZombieEscape) then Add(recipe.Result and recipe.Result[1])end end
 local entries,total={},0
 for _,candidate in pairs(candidates)do entries[#entries+1]=candidate end
 table.sort(entries,function(a,b)return a.class<b.class end)
 for _,entry in ipairs(entries)do
  local low=Positive(entry.tier) and entry.tier<=2 or not Positive(entry.tier) and entry.cost and entry.cost<=40
  entry.weight=low and 6 or 1;total=total+entry.weight;entry.ceiling=total
 end
 self.ZSTraitLootWeaponCatalog={items=self.Items,crafts=self.Crafts,itemCount=#items,craftCount=#crafts,classic=classic,escape=self.ZombieEscape,entries=entries,total=total}
 return entries,total
end
local function LootClip(definition)
 local clip=definition and definition.ClipSize
 return Positive(clip) and math.min(500,math.floor(clip)) or 0
end
function GM:CreateTraitWeaponDrop(position)
 local catalog,total=self:GetTraitLootWeaponCatalog()
 if total<=0 then return 0 end
 local choice=math.random(total);local first,last=1,#catalog
 while first<last do
  local middle=math.floor((first+last)/2)
  if choice<=catalog[middle].ceiling then last=middle else first=middle+1 end
 end
 local selected=catalog[first].class
 local stored=weapons.GetStored(selected)
 if not stored then self.ZSTraitLootWeaponCatalog=nil;return 0 end
 local ent=ents.Create("prop_weapon")
 if not IsValid(ent)then return 0 end
 ent:SetWeaponType(selected);ent:SetClip1(LootClip(stored.Primary));ent:SetClip2(LootClip(stored.Secondary))
 ent:SetPos(position+Vector(0,0,12));ent:Spawn()
 return 1
end
function GM:TraitCrateLoot(ent,attacker)
 if self.RoundEnded or not IsValid(ent) or ent.ZSTraitCrateClaimed or ent.NoTraitLoot
  or not self:HasPlayerTrait(attacker,"luckycrates") or string.sub(ent:GetClass(),1,12)~="prop_physics"
  or not crateModels[string.lower(ent:GetModel()or "")] then return 0 end
 ent.ZSTraitCrateClaimed=true
 local position=ent:GetPos()
 if math.Rand(0,1)<0.2 then
  local catalog=self:GetTraitLootWeaponCatalog()
  if #catalog>0 then return self:CreateTraitWeaponDrop(position)end
 end
 return self:CreateTraitAmmoDrops(position,math.random(2,3))
end
hook.Add("PropBroken","ZSTraitCrateLoot",function(ent,attacker)GAMEMODE:TraitCrateLoot(ent,attacker)end)
