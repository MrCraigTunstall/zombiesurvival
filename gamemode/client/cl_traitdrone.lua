local mount=Vector(0,0,13)
local orientation=Angle(0,0,0)
local background=Color(17,23,29,235)
local textColor=Color(230,237,243)
local accent=Color(126,229,213)
local empty=Color(239,115,115)
function GM:RemoveTraitDroneModel(drone)
 if IsValid(drone.ZSTraitDroneModel)then drone.ZSTraitDroneModel:Remove()end
 drone.ZSTraitDroneModel=nil
end
function GM:DrawTraitDroneHUD(pl, controller)
 if self.RoundEnded or not IsValid(pl) or not pl:Alive() or not self:HasPlayerTrait(pl,"dronepilot")
  or not IsValid(controller) or controller:GetOwner()~=pl or pl:GetActiveWeapon()~=controller then return false end
 local drone=controller:GetDTEntity(0)
 local ready=IsValid(drone) and drone:GetNW2Bool("zs_drone_gun",false)
 local ammo=pl:GetAmmoCount("smg1")
 if controller.ZSTraitDroneHUDAmmo~=ammo then controller.ZSTraitDroneHUDAmmo=ammo;controller.ZSTraitDroneHUDText=tostring(ammo).." SMG"end
 local scale=BetterScreenScale();local margin=24*scale
 local width=math.max(1,math.min(280*scale,ScrW()-margin*2));local height=66*scale
 local x,y=ScrW()-width-margin,ScrH()-height-margin
 draw.RoundedBox(8*scale,x,y,width,height,background)
 draw.SimpleText("DRONE GUN","ZSHUDFontSmaller",x+14*scale,y+10*scale,textColor)
 draw.SimpleText(controller.ZSTraitDroneHUDText,"ZSHUDFont",x+width-14*scale,y+10*scale,ammo>0 and accent or empty,TEXT_ALIGN_RIGHT)
 draw.SimpleText(not ready and "Reload: attach gun" or controller:GetDTBool(0) and "Secondary fire: shoot" or "Primary fire: pilot","ZSHUDFontSmaller",x+14*scale,y+38*scale,textColor)
 return true
end
function GM:DrawTraitDroneModel(drone)
 local now=CurTime()
 if now>=(drone.ZSTraitDroneModelCheck or 0)then
  drone.ZSTraitDroneModelCheck=now+0.1
  if not drone:GetNW2Bool("zs_drone_gun",false)then self:RemoveTraitDroneModel(drone)
  elseif not IsValid(drone.ZSTraitDroneModel)then
   local model=ClientsideModel("models/weapons/w_smg1.mdl",RENDERGROUP_OPAQUE)
   if IsValid(model)then
    model:SetParent(drone);model:SetLocalPos(mount);model:SetLocalAngles(orientation)
    model:SetNoDraw(true);model:SetModelScale(0.35,0);drone.ZSTraitDroneModel=model
   end
  end
 end
 local model=drone.ZSTraitDroneModel
 if not IsValid(model)then return end
 local owner=drone:GetOwner()
 model:SetRenderAngles(IsValid(owner) and drone:BeingControlled() and owner:EyeAngles() or drone:GetAngles())
 model:DrawModel()
end
