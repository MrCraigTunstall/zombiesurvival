function GM:ClearTraitDrunk(pl)
 pl.ZSTraitDrunkUntil=nil
 if IsValid(pl) and pl:GetNW2Float("zs_trait_drunk",0)~=0 then pl:SetNW2Float("zs_trait_drunk",0)end
end
function GM:TryTraitBottle(pl,ent)
 if self.RoundEnded or not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or not self:HasPlayerTrait(pl,"drunktard")
  or pl:GetBarricadeGhosting() or pl:IsCarrying() or not IsValid(ent) or ent.ZSTraitConsumed or ent.Removing
  or ent.IsMarkedForDeletion and ent:IsMarkedForDeletion() then return false end
 if not ent:IsGlassCraftBottle() or ent.m_NoPickup or ent.NoTraitConsume or ent:IsNailed()then return false end
 local now=CurTime()
 if now<(pl.ZSTraitFoodNext or 0)then return false end
 local position=pl:GetShootPos()
 if position:DistToSqr(ent:NearestPoint(position))>64*64 or ent:GetHolder() or pl:TraceLine(64,MASK_SOLID,pl).Entity~=ent then return false end
 local roll=ent.ZSTraitBottleRoll
 if roll==nil then roll=math.Rand(0,1);ent.ZSTraitBottleRoll=roll end
 ent.ZSTraitConsumed=true
 local rewarded=0
 if roll<0.02 then
  rewarded=self:CreateTraitWeaponDrop(ent:GetPos())
  if rewarded==0 then rewarded=self:CreateTraitAmmoDrops(ent:GetPos(),1)end
 elseif roll>=0.5 and pl:GetMaxHealth()>0 and pl:Health()<pl:GetMaxHealth() then
  pl:SetHealth(math.min(pl:GetMaxHealth(),pl:Health()+10));rewarded=1
 else rewarded=self:CreateTraitAmmoDrops(ent:GetPos(),1)end
 if rewarded==0 then ent.ZSTraitConsumed=nil;return false end
 pl.ZSTraitFoodNext=now+0.25;pl.ZSTraitDrunkUntil=now+10;pl:SetNW2Float("zs_trait_drunk",pl.ZSTraitDrunkUntil)
 ent:Remove();pl:EmitSound("npc/barnacle/barnacle_gulp1.wav")
 return true
end
local function Clear(pl)GAMEMODE:ClearTraitDrunk(pl)end
hook.Add("PlayerDeath","ZSTraitDrunk",Clear)
hook.Add("PlayerSpawn","ZSTraitDrunk",Clear)
hook.Add("OnPlayerChangedTeam","ZSTraitDrunk",Clear)
hook.Add("PlayerDisconnected","ZSTraitDrunk",Clear)
