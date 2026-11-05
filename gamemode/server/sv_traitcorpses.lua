local models={["models/headcrabclassic.mdl"]=true,["models/headcrab.mdl"]=true,["models/headcrabblack.mdl"]=true}
GM.ZSTraitHeadcrabBodies=GM.ZSTraitHeadcrabBodies or {}
function GM:HasHeadcrabConsumer()
 for pl in pairs(self.ZSTraitState.headcrabConsumers)do
  if not IsValid(pl) or not pl.ZSTraits or not pl.ZSTraits.headcrabconnoisseur then self.ZSTraitState.headcrabConsumers[pl]=nil
  elseif pl:Team()==TEAM_HUMAN and pl:Alive()then return true end
 end
 return false
end
local function Available(ent)return IsValid(ent) and not ent.Removing and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())end
function GM:CreateTraitHeadcrabBody(pl)
 if self.RoundEnded or not IsValid(pl) or not pl:IsPlayer() or pl:Alive() or pl:Team()~=TEAM_UNDEAD
  or not pl:GetZombieClassTable().IsHeadcrab or not models[string.lower(pl:GetModel()or "")] or not self:HasHeadcrabConsumer()then return end
 local old=pl:GetRagdollEntity()
 if not IsValid(old)then return end
 local existing=pl:GetNW2Entity("zs_headcrab_body")
 if Available(existing)then return existing end
 local body=ents.Create("prop_ragdoll")
 if not IsValid(body)then return end
 body:SetModel(pl:GetModel());body:SetPos(pl:GetPos());body:SetAngles(pl:GetAngles());body:Spawn();body:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
 if not IsValid(body:GetPhysicsObject())then body:Remove();return end
 local velocity=pl:GetVelocity()
 for index=0,body:GetPhysicsObjectCount()-1 do local physics=body:GetPhysicsObjectNum(index);if IsValid(physics)then physics:SetVelocity(velocity)end end
 body.ZSTraitHeadcrabBody=true
 local lifetime=tonumber(self.GibLifeTime)
 if not lifetime or lifetime~=lifetime or lifetime==math.huge or lifetime==-math.huge then lifetime=25 end
 body:Fire("kill","",math.max(0.1,math.min(60,lifetime)))
 local limit=tonumber(self.MaxDroppedItems)
 if not limit or limit~=limit or limit==math.huge or limit==-math.huge then limit=32 end
 limit=math.max(0,math.min(32,math.floor(limit)))
 local bodies={}
 for _,ent in ipairs(self.ZSTraitHeadcrabBodies)do if Available(ent)then bodies[#bodies+1]=ent end end
 bodies[#bodies+1]=body
 while #bodies>limit do table.remove(bodies,1):Remove()end
 self.ZSTraitHeadcrabBodies=bodies
 if not Available(body)then return end
 pl:SetNW2Entity("zs_headcrab_body",body);old:Remove()
 return body
end
local corpseMask=bit.bor(MASK_SOLID,CONTENTS_DEBRIS,CONTENTS_HITBOX)
function GM:TryTraitHeadcrab(pl,ent,traced)
 if self.RoundEnded or not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or not self:HasPlayerTrait(pl,"headcrabconnoisseur")
  or pl:GetBarricadeGhosting() or pl:IsCarrying() or not Available(ent) or ent.ZSTraitConsumed
  or ent:GetClass()~="prop_ragdoll" or not models[string.lower(ent:GetModel()or "")] or ent.NoTraitConsume or ent.m_NoPickup or ent:IsNailed()then return false end
 local health,maximum=pl:Health(),pl:GetMaxHealth()
 if maximum<=0 or health>=maximum or CurTime()<(pl.ZSTraitFoodNext or 0)then return false end
 local position=pl:GetShootPos()
 if position:DistToSqr(ent:NearestPoint(position))>64*64 or ent:GetHolder() or (not traced and pl:TraceLine(64,corpseMask,pl).Entity~=ent) then return false end
 ent.ZSTraitConsumed=true;pl.ZSTraitFoodNext=CurTime()+0.25;pl:SetHealth(math.min(maximum,health+10));ent:Remove();pl:EmitSound("npc/barnacle/barnacle_gulp1.wav")
 return true
end
hook.Add("PlayerDeath","ZSTraitHeadcrabBody",function(pl)GAMEMODE:CreateTraitHeadcrabBody(pl)end)
hook.Add("PlayerSpawn","ZSTraitHeadcrabBody",function(pl)if IsValid(pl:GetNW2Entity("zs_headcrab_body"))then pl:SetNW2Entity("zs_headcrab_body",NULL)end end)

function GM:TryTraitHeadcrabUse(pl)
 if not self:HasPlayerTrait(pl,"headcrabconnoisseur") or not pl:Alive() or pl:GetBarricadeGhosting() or pl:IsCarrying() then return false end
 return self:TryTraitHeadcrab(pl,pl:TraceLine(64,corpseMask,pl).Entity,true)
end
