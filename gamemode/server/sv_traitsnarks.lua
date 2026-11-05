local model="models/zombiesurvival/snark/snark.mdl"
local state=GM.ZSTraitSnarks or {entities={},owners=setmetatable({},{__mode="k"}),count=0,prey={}}
GM.ZSTraitSnarks=state
state.pending=state.pending or 0
state.ownerValidity=state.ownerValidity or setmetatable({},{__mode="k"})
util.PrecacheModel(model)
local function Owner(gm,pl)
 return not gm.RoundEnded and IsValid(pl)and pl:IsPlayer()and pl:Alive()and gm:HasPlayerTrait(pl,"alientrainer")
end
local function Prey(pl)
 return IsValid(pl)and pl:IsPlayer()and pl:Alive()and pl:Team()==TEAM_UNDEAD and not pl.SpawnProtection
end
local function Relation(ent,pl)
 ent:AddEntityRelationship(pl,IsValid(pl)and pl:IsPlayer()and pl:Alive()and pl:Team()==TEAM_UNDEAD and D_HT or D_LI,99)
end
local function Drop(ent)
 local entry=state.entities[ent]
 if not entry then return end
 GAMEMODE:ReleaseNPCTargetAccessToken(ent)
 state.entities[ent]=nil;state.count=math.max(0,state.count-1)
 local owned=state.owners[entry.owner]
 if owned then owned[ent]=nil;if not next(owned)then state.owners[entry.owner]=nil end end
 if state.count==0 then
  timer.Remove("ZSTraitSnarkThink")
  for i=#state.prey,1,-1 do state.prey[i]=nil end
  for pl in pairs(state.ownerValidity)do state.ownerValidity[pl]=nil end
 end
end
local function Remove(ent)
 Drop(ent)
 if IsValid(ent)then ent:Remove()end
end
local function Target(ent,entry,target,position)
 if entry.target~=target then
  if entry.target then GAMEMODE:ReleaseNPCTargetAccess(entry.target,ent)end
  entry.target=target
 end
 if target then
  GAMEMODE:AcquireNPCTargetAccess(target,ent)
  if ent:GetEnemy()~=target then ent:SetEnemy(target)end
  ent:UpdateEnemyMemory(target,position)
 else ent:SetEnemy(NULL)end
end
local function Pulse()
 local now=CurTime()
 local count=0
 for pl in pairs(state.ownerValidity)do state.ownerValidity[pl]=nil end
 for _,pl in player.Iterator()do
  if Prey(pl)then
   count=count+1
   local row=state.prey[count]
   if not row then row={};state.prey[count]=row end
   row.player,row.position,row.index=pl,pl:GetPos(),pl:EntIndex()
  end
 end
 for i=#state.prey,count+1,-1 do state.prey[i]=nil end
 for ent,entry in pairs(state.entities)do
  local validOwner=state.ownerValidity[entry.owner]
  if validOwner==nil then validOwner=Owner(GAMEMODE,entry.owner);state.ownerValidity[entry.owner]=validOwner end
  if not IsValid(ent)or ent:IsMarkedForDeletion()or ent:Health()<=0 or not validOwner or now>=entry.expires then Remove(ent)
  else
   if entry.animationAt and now>entry.animationAt then
    local sequence=ent:LookupSequence("run")
    if sequence>=0 then ent:ResetSequence(sequence)end
    entry.animationAt=nil
   end
   local position=ent:GetPos()
   local target,targetPosition,best,index=nil,nil,768*768,math.huge
   for i=1,count do
    local row=state.prey[i]
    local distance=position:DistToSqr(row.position)
    if distance<best or distance==best and row.index<index then target,targetPosition,best,index=row.player,row.position,distance,row.index end
   end
   Target(ent,entry,target,targetPosition)
   if target then entry.emptySince=nil
   elseif not entry.emptySince then entry.emptySince=now
   elseif now-entry.emptySince>=2 then Remove(ent)end
  end
 end
end
function GM:GiveTraitSnarkWeapon(pl)
 if not Owner(self,pl)then return false,nil,false end
 if pl.ZSTraitSnarkGrantBusy then return false,nil,false end
 if pl.ZSTraitSnarkCharges==nil then pl.ZSTraitSnarkCharges=3 end
 local class="weapon_zs_snarks"
 local weapon=pl:GetWeapon(class)
 if not IsValid(weapon)then
  local pending=pl.ZSTraitSnarkGrantPending
  if IsValid(pending)then return false,nil,pending:IsWeapon()and pending:GetClass()==class and pending:IsMarkedForDeletion()and not IsValid(pending:GetOwner())end
  pl.ZSTraitSnarkGrantPending=nil
  local claims,life,spawned=self.CheckedOut,pl.ZSWorthLife,pl.SpawnedTime
  pl.ZSTraitSnarkGrantBusy=true
  local ok,returned=pcall(pl.Give,pl,class)
  if IsValid(pl)then pl.ZSTraitSnarkGrantBusy=nil end
  if not ok then error(returned,0)end
  if not Owner(self,pl)or claims~=self.CheckedOut or life~=pl.ZSWorthLife or spawned~=pl.SpawnedTime then return false,nil,false end
  weapon=pl:GetWeapon(class)
  if not IsValid(weapon)or not weapon:IsWeapon()or weapon:GetClass()~=class or weapon:IsMarkedForDeletion()or weapon:GetOwner()~=pl then
   if IsValid(weapon)then return false,nil,false end
   local recoverable=not IsValid(returned)or returned:IsWeapon()and returned:GetClass()==class and returned:IsMarkedForDeletion()and not IsValid(returned:GetOwner())
   if recoverable and IsValid(returned)then pl.ZSTraitSnarkGrantPending=returned end
   return false,nil,recoverable
  end
  if IsValid(returned)and returned~=weapon then return false,nil,false end
 end
 if not weapon:IsWeapon()or weapon:GetClass()~=class or weapon:IsMarkedForDeletion()or weapon:GetOwner()~=pl then return false,nil,false end
 pl.ZSTraitSnarkGrantPending=nil
 weapon:SetClip1(pl.ZSTraitSnarkCharges)
 return true,weapon
end
function GM:RemoveTraitSnarks(pl)
 local owned=state.owners[pl]
 if owned then for ent in pairs(owned)do Remove(ent)end end
 pl.ZSTraitSnarkNext=nil
end
function GM:DeployTraitSnark(pl,weapon)
 if not Owner(self,pl)or pl.ZSTraitSnarkDeploying or pl:GetBarricadeGhosting()or pl:IsHolding()or not IsValid(weapon)
  or weapon:GetClass()~="weapon_zs_snarks"or weapon:GetOwner()~=pl or pl:GetActiveWeapon()~=weapon then return false,"unavailable"end
 local now=CurTime()
 if now<(pl.ZSTraitSnarkNext or 0)then return false,"cooldown"end
 if (pl.ZSTraitSnarkCharges or 0)<=0 then return false,"empty"end
 local owned=state.owners[pl]
 local count=0
 if owned then for ent in pairs(owned)do if IsValid(ent)and not ent:IsMarkedForDeletion()and ent:Health()>0 then count=count+1 end end end
 if count>=3 or state.count+state.pending>=64 then return false,"limit"end
 if not util.IsValidModel(model)then return false,"failed"end
 local start=pl:GetShootPos()
 local direction=pl:GetAimVector()
 local trace=util.TraceHull({start=start,endpos=start+direction*24,mins=Vector(-6,-6,0),maxs=Vector(6,6,10),mask=MASK_SOLID,filter=pl})
 if trace.Hit or trace.StartSolid or trace.AllSolid then return false,"blocked"end
 local ent
 pl.ZSTraitSnarkDeploying=true;state.pending=state.pending+1
 local ok=pcall(function()
  ent=ents.Create("monster_snark")
  if not IsValid(ent)then return end
  ent.ZSTraitSnarkOwner=pl
  ent:SetPos(trace.HitPos);ent:Spawn();ent:SetModel(model)
  ent:SetOwner(pl);ent:SetSaveValue("m_hOwner",pl);ent:SetSaveValue("m_flDie",now+12)
  ent:SetVelocity(direction*200+pl:GetVelocity())
  for _,candidate in player.Iterator()do Relation(ent,candidate)end
 end)
 pl.ZSTraitSnarkDeploying=nil;state.pending=state.pending-1
 if not ok or not IsValid(ent)or ent:Health()<=0 or not Owner(self,pl)or (pl.ZSTraitSnarkCharges or 0)<=0 then
  if IsValid(ent)then ent:Remove()end;return false,"failed"
 end
 owned=owned or {};state.owners[pl]=owned;owned[ent]=true
 state.entities[ent]={owner=pl,expires=now+12,animationAt=now};state.count=state.count+1
 pl.ZSTraitSnarkCharges=pl.ZSTraitSnarkCharges-1;weapon:SetClip1(pl.ZSTraitSnarkCharges);pl.ZSTraitSnarkNext=now+1
 Pulse()
 if state.count>0 and not timer.Exists("ZSTraitSnarkThink")then timer.Create("ZSTraitSnarkThink",0.25,0,Pulse)end
 return true,ent
end
local function Source(ent)
 return IsValid(ent)and ent.ZSTraitSnarkOwner and ent
end
hook.Add("EntityTakeDamage","ZSTraitSnarks",function(victim,info)
 local own=state.entities[victim]
 local attacker=info:GetAttacker()
 if own and IsValid(attacker)and attacker:IsPlayer()and attacker:Team()~=TEAM_UNDEAD then return true end
 local source=Source(info:GetInflictor())or Source(attacker)
 if not source or victim==source then return end
 local owner=source.ZSTraitSnarkOwner
 if not Owner(GAMEMODE,owner)or not Prey(victim)then return true end
 info:SetAttacker(owner)
end)
hook.Add("EntityRemoved","ZSTraitSnarks",Drop)
local function Changed(pl)
 if not Owner(GAMEMODE,pl)then GAMEMODE:RemoveTraitSnarks(pl)end
 for ent in pairs(state.entities)do if IsValid(ent)then Relation(ent,pl)end end
end
hook.Add("OnPlayerChangedTeam","ZSTraitSnarks",Changed)
hook.Add("PlayerDeath","ZSTraitSnarks",Changed)
hook.Add("PlayerDisconnected","ZSTraitSnarks",function(pl)GAMEMODE:RemoveTraitSnarks(pl)end)
hook.Add("PlayerSpawn","ZSTraitSnarks",function(pl)
 timer.Simple(0,function()if IsValid(pl)then Changed(pl);GAMEMODE:GiveTraitSnarkWeapon(pl)end end)
end)
hook.Add("PostCleanupMap","ZSTraitSnarks",function()
 for ent in pairs(state.entities)do Remove(ent)end
end)
if state.count>0 then timer.Create("ZSTraitSnarkThink",0.25,0,Pulse)end
