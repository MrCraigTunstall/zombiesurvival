local classes = {prop_manhack = true, prop_manhack_saw = true}
local muzzle = Vector(12, 0, 16)
local function Pilot(gm, pl, controller)
 return not gm.RoundEnded and IsValid(pl) and pl:IsPlayer() and pl:Alive() and not pl:GetBarricadeGhosting()
  and gm:HasPlayerTrait(pl,"dronepilot") and IsValid(controller) and controller:GetOwner()==pl
  and pl:GetActiveWeapon()==controller and classes[controller.EntityClass]
end
local function Owned(drone, pl, controller)
 return IsValid(drone) and not drone.Destroyed and not drone:IsMarkedForDeletion() and drone:GetObjectHealth()>0
  and drone:GetOwner()==pl and drone:GetClass()==controller.EntityClass and drone.ControllerClass==controller:GetClass()
end
function GM:UpgradeTraitDrone(pl, controller)
 if not Pilot(self,pl,controller) then return false end
 local drone=controller:GetDTEntity(0)
 if not Owned(drone,pl,controller) then
  local position,distance=pl:GetPos(),math.huge
  drone=nil
  for _,ent in ipairs(self:GetZSClassEntities(controller.EntityClass))do
   if Owned(ent,pl,controller) then
    local squared=ent:GetPos():DistToSqr(position)
    if squared<distance or squared==distance and (not drone or ent:EntIndex()<drone:EntIndex()) then drone,distance=ent,squared end
   end
  end
 end
 if not drone then return false end
 if controller:GetDTEntity(0)~=drone then controller:SetDTEntity(0,drone)end
 if not drone:GetNW2Bool("zs_drone_gun",false) then drone:SetNW2Bool("zs_drone_gun",true)end
 return true,drone
end
function GM:FireTraitDrone(pl, controller)
 if not Pilot(self,pl,controller) or not controller:GetDTBool(0) then return false end
 local drone=controller:GetDTEntity(0)
 if not Owned(drone,pl,controller) or not drone:GetNW2Bool("zs_drone_gun",false) or not drone:BeingControlled()then return false end
 local now=CurTime()
 if now<(drone.ZSTraitDroneNextShot or 0) or pl:GetAmmoCount("smg1")<1 then return false end
 local filter=drone.ZSTraitDroneFilter
 if not filter then
  filter=function(ent)
   return ent~=drone and ent:GetParent()~=drone and not ent.NeverAlive and not ent.SpawnProtection
    and not ent.IgnoreBullets and not(ent:IsPlayer() and ent:Team()==TEAM_HUMAN)
  end
  drone.ZSTraitDroneFilter=filter
 end
 local trace=drone.ZSTraitDroneMuzzleTrace
 if not trace then trace={mask=MASK_SHOT,filter=filter,output={}};drone.ZSTraitDroneMuzzleTrace=trace end
 local source=drone:LocalToWorld(muzzle)
 trace.start,trace.endpos=drone:GetPos(),source
 local blocked=util.TraceLine(trace)
 if blocked.Hit or blocked.StartSolid or blocked.AllSolid then return false end
 drone.ZSTraitDroneNextShot=now+0.2
 pl:RemoveAmmo(1,"smg1")
 local ok,failure=pcall(drone.FireBulletsLua,drone,source,pl:EyeAngles():Forward(),0,1,8,pl,1,"Tracer",nil,nil,false,1200,filter,drone)
 if not ok then ErrorNoHalt("ZS drone shot: "..tostring(failure).."\n");return false end
 drone:EmitSound("Weapon_SMG1.Single",70,110)
 return true
end
