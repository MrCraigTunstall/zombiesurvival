include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Draw() end

local matWhite = Material("models/debug/debugwhite")
local matCore = Material("zombiesurvival/sigil/sigil_core")
local matGlow = Material("sprites/light_glow02_add")
local cDraw, cWhite = Color(255, 255, 255), Color(255, 255, 255)
local hintOffset = Vector(0, 0, 128)
local hintHealthy, hintCorrupted = Color(100, 190, 255), Color(255, 100, 90)
local viewOrigin

local function Finite(value)
 return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function Fraction(ent)
 local health, maximum = ent:GetSigilHealth(), ent:GetSigilMaxHealth()
 if not Finite(health) or not Finite(maximum) or maximum <= 0 then return 0 end
 return math.Clamp(health / maximum, 0, 1)
end

local function UpdateScale(ent, fraction)
 local parts = ent:GetModel() == "models/zombiesurvival/sigil/sigil.mdl"
 if ent.SigilParts ~= parts then ent.SigilParts, ent.CoreFraction = parts, nil end
 local scale = Finite(ent.ModelScale) and math.max(0, ent.ModelScale) or 1
 if ent.SigilModelScale ~= scale then
  ent.SigilModelScale = scale
  ent.BaseMatrix = ent.BaseMatrix or Matrix()
  ent.CoreMatrix = ent.CoreMatrix or Matrix()
  ent.CoreScale = ent.CoreScale or Vector()
  ent.BaseMatrix:Identity()
  ent.BaseMatrix:Scale(Vector(scale, scale, scale))
  ent:EnableMatrix("RenderMultiply", ent.BaseMatrix)
  ent.CoreFraction = nil
 end
 if ent.CoreFraction ~= fraction then
  ent.CoreFraction = fraction
  local height = math.max(0.02, fraction)
  if parts then ent.CoreScale:SetUnpacked(scale, scale, scale * height)
  else ent.CoreScale:SetUnpacked(scale * 0.1, scale * 0.1, scale * 0.9 * height) end
  ent.CoreMatrix:Identity()
  ent.CoreMatrix:Scale(ent.CoreScale)
  if parts then ent.CoreMatrix:SetTranslation(Vector(0, 0, 28 * scale * (1 - height))) end
 end
end

hook.Add("PostDrawTranslucentRenderables", "DrawSigilHints", function(depth, skybox)
 if depth or skybox then return end
 viewOrigin = EyePos()
 for _, ent in ipairs(GAMEMODE:GetZSClassEntities("prop_obj_sigil")) do
  if IsValid(ent) then ent:DrawWorldHint() end
 end
end)

function ENT:Initialize()
 GAMEMODE:RegisterZSClassEntity(self)
 self:SetRenderBounds(Vector(-80, -80, -32), Vector(80, 80, 120))
 UpdateScale(self, 1)
 self.AmbientSound = CreateSound(self, "zombiesurvival/sigil_loop.wav")
 self.Rotation = math.Rand(0, 360)
 self.NextEmit, self.NextLight, self.NextDecals = 0, 0, 0
 self.ParticleVelocity = Vector()
end

local function FinishParticles(ent)
 local state = ent:GetTable()
 local emitter = state.SigilEmitter
 state.SigilEmitter = nil
 if IsValid(emitter) then emitter:Finish() end
end

function ENT:Think()
 local now, origin = CurTime(), self:GetPos()
 local distance = (viewOrigin or EyePos()):DistToSqr(origin)
 local near = not self:IsDormant() and distance <= 700 * 700
 local sound = self.AmbientSound
 if sound then
  if near then
   local pitch = 75 + Fraction(self) * 25
   if not self.SoundPlaying then
    sound:PlayEx(0.6, pitch)
    self.SoundPlaying, self.SoundPitch = true, pitch
   elseif self.SoundPitch ~= pitch then
    sound:ChangePitch(pitch, 0.1)
    self.SoundPitch = pitch
   end
  elseif self.SoundPlaying then
   sound:Stop()
   self.SoundPlaying, self.SoundPitch = nil, nil
  end
 end
 if self:IsDormant() or distance > 900 * 900 or not self.LastRendered or now - self.LastRendered > 0.3 then FinishParticles(self) end
 if now >= self.NextDecals then self.NextDecals = now + 1 self:RemoveAllDecals() end
 self:SetNextClientThink(now + 0.1)
 return true
end

function ENT:OnRemove()
 local state = self:GetTable()
 if state.AmbientSound then state.AmbientSound:Stop() state.AmbientSound = nil end
 FinishParticles(self)
 if state.SigilLight then state.SigilLight.DieTime = 0 state.SigilLight = nil end
end

function ENT:DrawWorldHint()
 local position = self:GetPos()
 position:Add(hintOffset)
 DrawSigilHint(self:GetSigilLetter(), position, nil, 1, self:GetSigilCorrupted() and hintCorrupted or hintHealthy)
end

local function SetParts(ent, core)
 if not ent.SigilParts or ent.RenderingCore == core then return end
 ent.RenderingCore = core
 ent:SetBodygroup(0, core and 1 or 0)
 ent:SetBodygroup(1, core and 1 or 0)
 ent:SetBodygroup(2, core and 1 or 0)
end

local function DrawModels(ent, detailed, r, g, b)
 SetParts(ent, false)
 render.SuppressEngineLighting(false)
 render.SetColorModulation(math.sqrt(r), math.sqrt(g), math.sqrt(b))
 ent:DrawModel()
 if detailed then
  render.SuppressEngineLighting(true)
  SetParts(ent, true)
  render.ModelMaterialOverride(ent.SigilParts and matCore or matWhite)
  render.SetColorModulation(r, g, b)
  ent:EnableMatrix("RenderMultiply", ent.CoreMatrix)
  ent:DrawModel()
 end
end

function ENT:DrawTranslucent()
 if self:IsDormant() then FinishParticles(self) return end
 local now, origin = CurTime(), self:GetPos()
 self.LastRendered = now
 local distance = EyePos():DistToSqr(origin)
 self.LastRenderDistance = distance
 local fraction, pulse = Fraction(self), math.abs(math.sin(now))
 local r, g, b = 0.15 + pulse * 0.125, 0.4 + pulse * 0.125, 1
 local power = fraction
 if self:GetSigilCorrupted() then r, g, b, power = 1, 0.18, 0.14, 0.25 end
 local radius, inner = 40 + math.cos(pulse) * 6, 24 + math.sin(pulse) * 5
 if distance <= 900 * 900 and now >= self.NextLight then
  self.NextLight = now + 0.1
  local light = DynamicLight(self:EntIndex())
  if light then
   self.SigilLight = light
   light.Pos, light.r, light.g, light.b = origin, r * 255, g * 255, b * 255
   light.Brightness, light.Size, light.Decay, light.DieTime = (2 + pulse) * power, 100 + pulse * 50, 400 + pulse * 200, now + 0.25
  end
 end
 r, g, b = r * power, g * power, b * power
 UpdateScale(self, fraction)
 local ok, problem = pcall(DrawModels, self, distance <= 700 * 700, r, g, b)
 if distance <= 700 * 700 or not ok then self:EnableMatrix("RenderMultiply", self.BaseMatrix) end
 SetParts(self, false)
 render.SetBlend(1)
 render.ModelMaterialOverride()
 render.SuppressEngineLighting(false)
 render.SetColorModulation(1, 1, 1)
 if not ok then error(problem, 0) end
 local up = self:GetUp()
 local position = origin + up
 local rotation = (self.Rotation + now * 5) % 360
 cDraw.r, cDraw.g, cDraw.b = r * 255, g * 255, b * 255
 cWhite.r, cWhite.g, cWhite.b = power * 255, power * 255, power * 255
 render.SetMaterial(matGlow)
 render.DrawQuadEasy(position, up, inner, inner, cWhite, rotation)
 render.DrawQuadEasy(position, -up, inner, inner, cWhite, rotation)
 render.DrawQuadEasy(position, up, radius, radius, cDraw, rotation)
 render.DrawQuadEasy(position, -up, radius, radius, cDraw, rotation)
 render.DrawSprite(self:WorldSpaceCenter(), radius, radius * 2, cDraw)
 if distance > 900 * 900 then FinishParticles(self) return end
 if now < self.NextEmit then return end
 self.NextEmit = now + (distance <= 450 * 450 and 0.08 or 0.2)
 local emitter = self.SigilEmitter
 if not IsValid(emitter) then
  emitter = ParticleEmitter(origin)
  self.SigilEmitter = emitter
  if not IsValid(emitter) then return end
  emitter:SetNearClip(24, 32)
 end
 emitter:SetPos(origin)
 local offset = VectorRand()
 offset.z = 0
 offset:Normalize()
 offset:Mul(math.Rand(-32, 32))
 offset.z = 1
 local position = self:LocalToWorld(offset)
 local particle = emitter:Add("sprites/glow04_noz", position)
 if not particle then return end
 self.ParticleVelocity:SetUnpacked(0, 0, math.Rand(32, 64))
 particle:SetDieTime(math.Rand(1.5, 4))
 particle:SetVelocity(self.ParticleVelocity)
 particle:SetStartAlpha(100)
 particle:SetEndAlpha(0)
 particle:SetStartSize(math.Rand(2, 4))
 particle:SetEndSize(0)
 particle:SetRoll(math.Rand(0, 360))
 particle:SetRollDelta(math.Rand(-1, 1))
 particle:SetColor(r * 255, g * 255, b * 255)
 particle:SetCollide(false)
end
