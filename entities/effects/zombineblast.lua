function EFFECT:Init(data)
 local pos = data:GetOrigin() + Vector(0, 0, 24)
 sound.Play("ambient/explosions/explode_9.wav", pos, 90, math.Rand(95, 105))
 local emitter = ParticleEmitter(pos)
 if not emitter then return end
 emitter:SetNearClip(8, 12)
 local flash = emitter:Add("effects/fire_cloud1", pos)
 if flash then
  flash:SetDieTime(0.18)
  flash:SetStartAlpha(220) flash:SetEndAlpha(0)
  flash:SetStartSize(48) flash:SetEndSize(96)
  flash:SetColor(255, 180, 90)
  flash:SetRoll(math.Rand(0, 360))
 end
 for i = 1, 6 do
  local direction = VectorRand()
  local particle = emitter:Add("effects/fire_cloud1", pos + direction * 8)
  if particle then
   particle:SetVelocity(direction * math.Rand(60, 130))
   particle:SetDieTime(math.Rand(0.25, 0.4))
   particle:SetStartAlpha(180) particle:SetEndAlpha(0)
   particle:SetStartSize(16) particle:SetEndSize(32)
   particle:SetColor(255, 130, 45)
   particle:SetRoll(math.Rand(0, 360))
   particle:SetAirResistance(80)
   particle:SetGravity(Vector(0, 0, 24))
  end
 end
 for i = 1, 4 do
  local particle = emitter:Add("sprites/glow04_noz", pos)
  if particle then
   particle:SetVelocity(VectorRand() * 200)
   particle:SetDieTime(0.4)
   particle:SetStartAlpha(220) particle:SetEndAlpha(0)
   particle:SetStartSize(3) particle:SetEndSize(0)
   particle:SetColor(255, 180, 70)
   particle:SetAirResistance(40)
   particle:SetGravity(Vector(0, 0, -180))
  end
 end
 emitter:Finish()
end

function EFFECT:Think()
 return false
end

function EFFECT:Render()
end
