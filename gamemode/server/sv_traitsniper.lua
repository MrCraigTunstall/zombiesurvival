local function Eligible(pl, weapon)
 return IsValid(pl) and pl:IsPlayer() and pl:Alive() and pl:Team()==TEAM_HUMAN and pl.ZSTraits and pl.ZSTraits.deathmark
  and IsValid(weapon) and weapon.TraitSniper and weapon:GetOwner()==pl and not GAMEMODE.RoundEnded
end
local function Target(pl)
 return IsValid(pl) and pl:IsPlayer() and pl:Alive() and pl:Team()==TEAM_UNDEAD and not pl:GetZombieClassTable().NeverAlive
end
function GM:BeginTraitSniperBullet(pl,weapon,target)
 if not Eligible(pl,weapon) then if IsValid(pl) then pl.ZSTraitDeathMark=nil end;return end
 local mark=pl.ZSTraitDeathMark
 local count=Target(target) and mark and mark.target==target and mark.life==target.ZSTraitSniperLife and mark.count or 0
 local shot={weapon=weapon,target=target,life=IsValid(target) and target.ZSTraitSniperLife,scale=1+math.min(6,count)*0.05,previous=pl.ZSTraitSniperShot}
 pl.ZSTraitSniperShot=shot
 return shot
end
function GM:ApplyTraitSniperDamage(target,damage,pl,weapon)
 local shot=pl.ZSTraitSniperShot
 if shot and shot.target==target and shot.weapon==weapon and shot.life==target.ZSTraitSniperLife and damage:IsBulletDamage() and Eligible(pl,weapon) then
  damage:ScaleDamage(shot.scale)
 end
end
function GM:FinishTraitSniperBullet(pl,shot)
 if not shot or pl.ZSTraitSniperShot~=shot then return end
 pl.ZSTraitSniperShot=shot.previous
 if shot.hit and Eligible(pl,shot.weapon) and IsValid(shot.target) and shot.life==shot.target.ZSTraitSniperLife then
  local mark=pl.ZSTraitDeathMark or {}
  mark.target=shot.target;mark.life=shot.life;mark.count=math.min(6,math.floor((shot.scale-1)/0.05+0.5)+1)
  pl.ZSTraitDeathMark=mark
 else pl.ZSTraitDeathMark=nil end
end
hook.Add("PostEntityTakeDamage","ZSTraitSniperHit",function(target,damage,took)
 if not took or damage:GetDamage()<=0 or not damage:IsBulletDamage() or not IsValid(target) or not target:IsPlayer() or target:Team()~=TEAM_UNDEAD or target:GetZombieClassTable().NeverAlive then return end
 local pl=damage:GetAttacker()
 if not IsValid(pl) or not pl:IsPlayer() then return end
 local shot=pl.ZSTraitSniperShot
 if shot and shot.target==target and shot.weapon==damage:GetInflictor() and shot.life==target.ZSTraitSniperLife and Eligible(pl,shot.weapon) then shot.hit=true end
end)
local function Clear(pl)
 pl.ZSTraitDeathMark=nil;pl.ZSTraitSniperShot=nil
end
hook.Add("PlayerSpawn","ZSTraitSniperLife",function(pl)Clear(pl);pl.ZSTraitSniperLife=(pl.ZSTraitSniperLife or 0)+1 end)
hook.Add("PlayerDeath","ZSTraitSniperLife",Clear)
hook.Add("OnPlayerChangedTeam","ZSTraitSniperLife",Clear)
hook.Add("PlayerDisconnected","ZSTraitSniperLife",Clear)
