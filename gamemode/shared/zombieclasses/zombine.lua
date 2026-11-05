CLASS.Name = "Zombine"
CLASS.TranslationName = "class_zombine"
CLASS.Description = "description_zombine"
CLASS.Help = "controls_zombine"
CLASS.Wave = 1
CLASS.Health = 380
CLASS.Speed = 120
CLASS.JumpPower = 150
CLASS.Mass = DEFAULT_MASS
CLASS.CanTaunt = false
CLASS.Points = 7
CLASS.SWEP = "weapon_zs_zombine"
CLASS.Model = Model("models/zombiesurvival/zombine/zombie_soldier.mdl")
CLASS.DeathSounds = {"weapons/npc/zombine/zombine_die1.wav", "weapons/npc/zombine/zombine_die2.wav"}
CLASS.PainSounds = {"weapons/npc/zombine/zombine_pain1.wav", "weapons/npc/zombine/zombine_pain2.wav", "weapons/npc/zombine/zombine_pain3.wav", "weapons/npc/zombine/zombine_pain4.wav"}
CLASS.VoicePitch = 0.6
CLASS.CanFeignDeath = false
CLASS.SkinBodygroupLocks = {[1] = true}

local steps = {"npc/combine_soldier/gear1.wav", "npc/combine_soldier/gear2.wav", "npc/combine_soldier/gear3.wav"}
local scuffs = {"npc/combine_soldier/gear4.wav", "npc/combine_soldier/gear5.wav", "npc/combine_soldier/gear6.wav"}
local random = math.random

function CLASS:PlayerFootstep(pl)
 local sounds = random() < 0.15 and scuffs or steps
 pl:EmitSound(sounds[random(#sounds)], 70, 75)
 return true
end

function CLASS:Move(pl, mv)
 local weapon = pl:GetActiveWeapon()
 if not weapon or not weapon:IsValid() then return end
 if weapon.IsInAttackAnim and weapon:IsInAttackAnim()
  or weapon.GetGrenading and weapon:GetGrenading() and weapon.GetGrenadeTime and CurTime() < weapon:GetGrenadeTime() then
  mv:SetForwardSpeed(0)
  mv:SetSideSpeed(0)
 end
end

function CLASS:CalcMainActivity(pl, velocity)
 local weapon = pl:GetActiveWeapon()
 if not weapon or not weapon:IsValid() then return end
 if weapon.IsInAttackAnim and weapon:IsInAttackAnim() then
  pl.CalcSeqOverride = GAMEMODE:GetAnimationSequence(pl, "FastAttack")
  return true
 end
 local moving = velocity:Length2D() > 0.5
 local grenade = weapon.GetGrenading and weapon:GetGrenading()
 if weapon.IsMoaning and weapon:IsMoaning() then
  if grenade then
   pl.CalcSeqOverride = GAMEMODE:GetAnimationSequence(pl, moving and "Run_All_grenade" or "Idle_Grenade")
  else pl.CalcIdeal = moving and ACT_RUN or ACT_IDLE end
 elseif grenade then
  local sequence = weapon.GetGrenadeTime and CurTime() <= weapon:GetGrenadeTime() and "pullGrenade"
   or moving and "walk_All_Grenade" or "Idle_Grenade"
  pl.CalcSeqOverride = GAMEMODE:GetAnimationSequence(pl, sequence)
 else pl.CalcIdeal = not pl:OnGround() and ACT_RUN or moving and ACT_WALK or ACT_IDLE end
 return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
 pl:FixModelAngles(velocity)
 local weapon = pl:GetActiveWeapon()
 local valid = weapon and weapon:IsValid()
 if valid and weapon.IsInAttackAnim and weapon:IsInAttackAnim() then
  local delay = weapon.Primary and weapon.Primary.Delay
  local remaining = weapon:GetAttackAnimTime() - CurTime()
  local cycle = 0
  if type(delay) == "number" and delay > 0 and delay < math.huge and remaining == remaining and math.abs(remaining) < math.huge then
   cycle = math.max(0, math.min(1, 1 - remaining / delay))
  end
  pl:SetPlaybackRate(0)
  pl:SetCycle(cycle)
  return true
 end
 if not pl:IsOnGround() or pl:WaterLevel() >= 3 then
  pl:SetPlaybackRate(1)
  local cycle = pl:GetCycle()
  if cycle ~= cycle or math.abs(cycle) == math.huge then pl:SetCycle(0)
  elseif cycle >= 1 or cycle < 0 then pl:SetCycle(cycle % 1) end
  return true
 end
 local speed, rate = velocity:Length2D(), 1
 if speed > 0.5 and speed < math.huge then
  if type(maxseqgroundspeed) ~= "number" or maxseqgroundspeed ~= maxseqgroundspeed or maxseqgroundspeed <= 0 then maxseqgroundspeed = self.Speed or 120 end
  local sprint = valid and weapon.IsMoaning and weapon:IsMoaning()
  local grenade = not sprint and valid and weapon.GetGrenading and weapon:GetGrenading()
  rate = math.min(speed / maxseqgroundspeed * (sprint and 1 or 0.555), grenade and 2 or 3)
 end
 pl:SetPlaybackRate(rate)
 return true
end

function CLASS:DoAnimationEvent(pl, event)
 if event == PLAYERANIMEVENT_ATTACK_PRIMARY then return ACT_INVALID end
end

function CLASS:ProcessDamage(pl, info)
 local attacker = info:GetAttacker()
 if not IsValid(attacker) or not attacker:IsPlayer() or attacker:Team() ~= TEAM_HUMAN then return end
 local weapon = pl:GetActiveWeapon()
 if weapon and weapon:IsValid() and weapon.IsMoaning and weapon.StopMoaning and weapon:IsMoaning() then weapon:StopMoaning(true) end
end

function CLASS:DoesntGiveFear(pl)
 return IsValid(pl.FeignDeath)
end

if SERVER then
 function CLASS:OnSpawned(pl)
  pl:SetBodygroup(1, 1)
 end
 function CLASS:OnKilled(pl)
  pl:SetBodygroup(1, 0)
 end
end

if CLIENT then CLASS.Icon = "zombiesurvival/killicons/zs_zombine" end
