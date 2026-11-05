include("shared.lua")

SWEP.PrintName = translate.Get("wn_claws")
SWEP.ViewModelFOV = 60
SWEP.DrawCrosshair = false

function SWEP:Initialize()
 self:DrawShadow(false)
end

local gripBones = {
 {"ValveBiped.Bip01_L_Finger0", 25}, {"ValveBiped.Bip01_L_Finger01", 25}, {"ValveBiped.Bip01_L_Finger02", 20},
 {"ValveBiped.Bip01_L_Finger1", -45}, {"ValveBiped.Bip01_L_Finger11", -45}, {"ValveBiped.Bip01_L_Finger12", -35},
 {"ValveBiped.Bip01_L_Finger2", -45}, {"ValveBiped.Bip01_L_Finger21", -45}, {"ValveBiped.Bip01_L_Finger22", -35},
 {"ValveBiped.Bip01_L_Finger3", -45}, {"ValveBiped.Bip01_L_Finger31", -45}, {"ValveBiped.Bip01_L_Finger32", -35}
}

function SWEP:ResetGrenadeGrip()
 local state = self.ZSGrenadeGrip
 self.ZSGrenadeGrip = nil
 if not state or not IsValid(state.vm) or state.vm:GetModel() ~= state.model then return end
 for i = 1, #state.bones do
  local item = state.bones[i]
  local current = state.vm:GetManipulateBoneAngles(item.bone)
  if math.abs(current.p - item.applied.p) < 0.001 and math.abs(current.y - item.applied.y) < 0.001 and math.abs(current.r - item.applied.r) < 0.001 then
   state.vm:ManipulateBoneAngles(item.bone, item.original)
  end
 end
end

function SWEP:PreDrawViewModel(vm)
 local result
 if self.BaseClass.PreDrawViewModel then result = self.BaseClass.PreDrawViewModel(self, vm) end
 local owner = self:GetOwner()
 if result or not self:GetGrenading() or not IsValid(owner) or not owner:Alive() or not IsValid(vm) then
  self:ResetGrenadeGrip()
  return result
 end
 local model = vm:GetModel()
 local state = self.ZSGrenadeGrip
 if not state or state.vm ~= vm or state.model ~= model then
  self:ResetGrenadeGrip()
  state = {vm = vm, model = model, bones = {}}
  for i = 1, #gripBones do
   local definition = gripBones[i]
   local bone = vm:LookupBone(definition[1])
   if bone then
    local original = vm:GetManipulateBoneAngles(bone)
    state.bones[#state.bones + 1] = {bone = bone, original = Angle(original.p, original.y, original.r), applied = Angle(original.p, original.y, original.r), curl = definition[2]}
   end
  end
  self.ZSGrenadeGrip = state
 end
 local step = math.floor(math.Clamp(1 - (self:GetGrenadeTime() - CurTime()) / self.GrenadePullTime, 0, 1) * 8 + 0.5)
 if state.step ~= step then
  state.step = step
  for i = 1, #state.bones do
   local item = state.bones[i]
   item.applied.y = item.original.y + item.curl * step / 8
   vm:ManipulateBoneAngles(item.bone, item.applied)
  end
 end
 return result
end

function SWEP:RemoveGrenadeModel()
 self:ResetGrenadeGrip()
 local world, view = self.GrenadeModel, self.ViewGrenadeModel
 self.GrenadeModel, self.ViewGrenadeModel = nil, nil
 if world and IsValid(world) then world:Remove() end
 if view and IsValid(view) then view:Remove() end
end

local glow = Material("sprites/glow04_noz")
function SWEP:PostDrawViewModel(vm)
 if self.BaseClass.PostDrawViewModel then self.BaseClass.PostDrawViewModel(self, vm) end
 local owner = self:GetOwner()
 if not self:GetGrenading() or not IsValid(owner) or not owner:Alive() then self:RemoveGrenadeModel() return end
 if not IsValid(vm) then return end
 local frame = FrameNumber()
 if self.ZSViewGrenadeDrawFrame == frame then return end
 local bone = vm:LookupBone("ValveBiped.Bip01_L_Hand")
 if not bone then return end
 local position, angles = vm:GetBonePositionMatrixed(bone)
 if not isvector(position) or not isangle(angles) then return end
 local model = self.ViewGrenadeModel
 if not IsValid(model) then
  model = ClientsideModel("models/weapons/w_grenade.mdl", RENDERGROUP_OPAQUE)
  if not IsValid(model) then return end
  model:SetNoDraw(true)
  self.ViewGrenadeModel = model
 end
 self.ZSViewGrenadeDrawFrame = frame
 local forward, right, up = angles:Forward(), angles:Right(), angles:Up()
 local rotation = Angle(angles.p, angles.y, angles.r)
 rotation:RotateAroundAxis(rotation:Right(), 240)
 rotation:RotateAroundAxis(rotation:Forward(), -80)
 model:SetPos(position + up * 3 + forward * 5 + right * 3)
 model:SetAngles(rotation)
 model:DrawModel()
 render.SetMaterial(glow)
 render.DrawSprite(position + up * 2.5 + forward * 6 - right * 4, 8, 8, COLOR_RED)
end

function SWEP:DrawWorldModel()
 if not self:GetGrenading() then self:RemoveGrenadeModel() return end
 local frame = FrameNumber()
 if self.ZSGrenadeDrawFrame == frame then return end
 local owner = self:GetOwner()
 if not IsValid(owner) or not owner:Alive() then self:RemoveGrenadeModel() return end
 local bone = owner:LookupBone("ValveBiped.Bip01_L_Hand")
 if not bone then return end
 local position, angles = owner:GetBonePositionMatrixed(bone)
 if not isvector(position) or not isangle(angles) then return end
 local model = self.GrenadeModel
 if not IsValid(model) then
  model = ClientsideModel("models/weapons/w_grenade.mdl", RENDERGROUP_OPAQUE)
  if not IsValid(model) then return end
  model:SetNoDraw(true)
  self.GrenadeModel = model
 end
 self.ZSGrenadeDrawFrame = frame
 local forward, right, up = angles:Forward(), angles:Right(), angles:Up()
 local origin = position + up * 3 + forward * 5 + right * 3
 local rotation = Angle(angles.p, angles.y, angles.r)
 rotation:RotateAroundAxis(rotation:Right(), 240)
 rotation:RotateAroundAxis(rotation:Forward(), -80)
 model:SetPos(origin)
 model:SetAngles(rotation)
 model:DrawModel()
 render.SetMaterial(glow)
 render.DrawSprite(position + up * 2.5 + forward * 6 - right * 4, 16, 16, COLOR_RED)
 if EyePos():DistToSqr(origin) <= 512 * 512 then
  local light = DynamicLight(self:EntIndex())
  if light then
   light.Pos, light.r, light.g, light.b = origin, 255, 0, 0
   light.Brightness, light.Size, light.Decay, light.DieTime = 0.75, 64, 256, CurTime() + 0.1
  end
 end
end
SWEP.DrawWorldModelTranslucent = SWEP.DrawWorldModel

function SWEP:DrawHUD()
 if GetConVarNumber("crosshair") == 1 then self:DrawCrosshairDot() end
end

function SWEP:DrawWeaponSelection(...)
 return self:BaseDrawWeaponSelection(...)
end
