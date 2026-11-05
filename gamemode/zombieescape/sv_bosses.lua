util.AddNetworkString("BossDefeated")
util.AddNetworkString("BossSpawn")
util.AddNetworkString("BossTakeDamage")

BOSS_MATH, BOSS_PHYSBOX = 1, 2
local types = {math_counter = BOSS_MATH, func_physbox_multiplayer = BOSS_PHYSBOX}
local BOSS = {}
BOSS.__index = BOSS

local function Live(ent)
 return IsValid(ent) and not (ent.IsMarkedForDeletion and ent:IsMarkedForDeletion())
end
local function Number(value)
 return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
local function Recipients()
 local recipients = {}
 for _, pl in player.Iterator() do
  if not pl:IsBot() then recipients[#recipients + 1] = pl end
 end
 return recipients
end
local function SpawnPacket(boss, recipients)
 net.Start("BossSpawn")
 net.WriteFloat(boss.ModelIndex)
 net.WriteString(boss.Name)
 net.Send(recipients)
end
local function HealthPacket(boss, health, maximum, recipients)
 net.Start("BossTakeDamage")
 net.WriteFloat(boss.ModelIndex)
 net.WriteFloat(health)
 net.WriteFloat(maximum)
 net.Send(recipients)
end

function BOSS:Reset()
 self.Type, self.bInitialized = -1, nil
 self.Entities = {}
 self._MaxHealth, self.LastHealth, self.LastMaximum, self.ModelIndex, self.SentModel = nil, nil, nil, nil, nil
 self.NextUpdate, self.Defeated, self.SeenAlive = 0, nil, nil
end
function BOSS:GetType() return self.Type or -1 end
function BOSS:GetCounterTarget() return self.Targets.Counter end
function BOSS:GetModelTarget() return self.Targets.Model end
function BOSS:GetName() return self.Name end
function BOSS:HasCounter(ent) return Live(ent) and ent:GetName() == self.Targets.Counter end
function BOSS:GetCounter()
 local ent = self.Entities.Counter
 if Live(ent) then return ent end
 for _, candidate in ipairs(ents.FindByName(self.Targets.Counter)) do
  local kind = Live(candidate) and types[candidate:GetClass()]
  if kind and candidate:GetName() == self.Targets.Counter then
   self.Type, self.Entities.Counter = kind, candidate
   self.GameMode.ZEBossByEntity[candidate] = self
   return candidate
  end
 end
end
function BOSS:GetClientModel()
 local ent = self.Entities.Model
 if Live(ent) then return ent end
 for _, candidate in ipairs(ents.FindByName(self.Targets.Model)) do
  if Live(candidate) and candidate:GetName() == self.Targets.Model then
   self.Entities.Model = candidate
   self.GameMode.ZEBossByEntity[candidate] = self
   return candidate
  end
 end
end
function BOSS:IsValid()
 return Live(self:GetCounter()) and Live(self:GetClientModel()) and self:GetType() ~= -1
end
function BOSS:Health()
 local counter = self:GetCounter()
 if not Live(counter) then return -1 end
 local health = self.Type == BOSS_MATH and counter:GetOutValue() or counter:Health()
 if not Number(health) then return end
 self._MaxHealth = math.max(self._MaxHealth or 0, health)
 return health
end
function BOSS:MaxHealth(current)
 local counter = self:GetCounter()
 if not Live(counter) then return -1 end
 local health = current or self:Health()
 if not Number(health) then return -1 end
 local initial = self.Type == BOSS_MATH and counter.m_InitialValue or 0
 return math.max(self._MaxHealth or 0, Number(initial) and initial or 0, health)
end
function BOSS:OnDamageTaken(activator, recipients)
 if not self:IsValid() then return end
 local health = self:Health()
 if not Number(health) then return end
 local maximum = self:MaxHealth(health)
 if health <= 0 then self:OnDeath(activator, recipients) return end
 if not Number(maximum) or maximum <= 0 then return end
 health, maximum = math.min(health, 3.4e38), math.min(maximum, 3.4e38)
 local model = self:GetClientModel()
 local index = model:EntIndex()
 if self.ModelIndex ~= index or self.SentModel ~= model then
  self.bInitialized = nil
  self.ModelIndex, self.SentModel = index, model
 end
 if self.bInitialized and self.LastHealth == health and self.LastMaximum == maximum then return end
 recipients = recipients or Recipients()
 if #recipients > 0 then
  if not self.bInitialized then SpawnPacket(self, recipients) end
  HealthPacket(self, health, maximum, recipients)
 end
 self.bInitialized, self.Defeated, self.SeenAlive = true, nil, true
 self.LastHealth, self.LastMaximum = health, maximum
end
function BOSS:OnDeath(activator, recipients)
 if self.Defeated or not (self.bInitialized or self.SeenAlive) then return end
 local gm, index = self.GameMode, self.ModelIndex
 if index then
  recipients = recipients or Recipients()
  if #recipients > 0 then
   net.Start("BossDefeated")
   net.WriteFloat(index)
   net.Send(recipients)
  end
 end
 gm.ZEBossPending[self] = nil
 self.KilledOnRound = gm:GetWave()
 self:Reset()
 self.Defeated = true
 hook.Run("OnBossDefeated", self, activator)
end

GM.Bosses = {}
GM.ValidBossEntities = types
GM.ZEBossByName = {}
GM.ZEBossByEntity = setmetatable({}, {__mode = "k"})
GM.ZEBossPending = {}
GM.ZEBossPendingAny = false

function GM:AddBoss(name, model, counter)
 if type(name) ~= "string" or type(model) ~= "string" or type(counter) ~= "string" or model == "" or counter == "" then return end
 local boss = self.ZEBossByName[counter]
 if boss then return boss end
 boss = setmetatable({Name = string.sub(name, 1, 512), Targets = {Model = model, Counter = counter}, GameMode = self}, BOSS)
 boss:Reset()
 self.Bosses[#self.Bosses + 1] = boss
 self.ZEBossByName[counter] = boss
 return boss
end
function GM:GetBoss(ent)
 if not Live(ent) then return end
 local kind = types[ent:GetClass()]
 if not kind then return end
 local name = ent:GetName()
 local boss = self.ZEBossByEntity[ent]
 if not boss or boss.Targets.Counter ~= name then boss = self.ZEBossByName[name] end
 if boss then
  boss.Type, boss.Entities.Counter = kind, ent
  self.ZEBossByEntity[ent] = boss
 end
 return boss
end
function GM:BossDamageTaken(ent, activator)
 local boss = self:GetBoss(ent)
 if not boss then return end
 if not boss.SeenAlive or boss.Defeated then
  local health = boss.Type == BOSS_MATH and ent:GetOutValue() or ent:Health()
  if Number(health) and health > 0 then
   boss.SeenAlive, boss.Defeated = true, nil
   boss._MaxHealth = math.max(boss._MaxHealth or 0, health)
  elseif not boss.Defeated and Number(ent.m_InitialValue) and ent.m_InitialValue > 0 then
   boss.SeenAlive = true
  end
 end
 self.ZEBossPending[boss] = activator or false
 self.ZEBossPendingAny = true
end
function GM:FlushZombieEscapeBossUpdates()
 if not self.ZEBossPendingAny then return end
 local now, recipients = CurTime(), nil
 for boss, activator in pairs(self.ZEBossPending) do
  if now >= boss.NextUpdate then
   self.ZEBossPending[boss] = nil
   boss.NextUpdate = now + 0.15
   if not recipients then recipients = Recipients() end
   boss:OnDamageTaken(activator or nil, recipients)
  end
 end
 self.ZEBossPendingAny = next(self.ZEBossPending) ~= nil
end
function GM:BossDeath(ent, activator)
 local boss = self.ZEBossByEntity[ent] or self:GetBoss(ent)
 if boss then boss:OnDeath(activator) end
end
function GM:MathCounterUpdate(ent, activator) self:BossDamageTaken(ent, activator) end
function GM:MathCounterHitMin(ent, activator) self:BossDeath(ent, activator) end
function GM:SyncZombieEscapeBosses(pl)
 if not self.ZombieEscape or not Live(pl) or pl:IsBot() then return end
 for _, boss in ipairs(self.Bosses) do
  if boss.bInitialized and boss:IsValid() then
   local health = boss:Health()
   local maximum = boss:MaxHealth(health)
   if Number(health) and health > 0 and maximum > 0 then
    boss.ModelIndex = boss:GetClientModel():EntIndex()
    SpawnPacket(boss, pl)
    HealthPacket(boss, math.min(health, 3.4e38), math.min(maximum, 3.4e38), pl)
   end
  end
 end
end
function GM:ResetZombieEscapeBosses()
 local recipients
 for _, boss in ipairs(self.Bosses) do
  if boss.bInitialized and boss.ModelIndex then
   if not recipients then recipients = Recipients() end
   if #recipients > 0 then
    net.Start("BossDefeated");net.WriteFloat(boss.ModelIndex);net.Send(recipients)
   end
  end
  boss:Reset()
 end
 self.ZEBossByEntity = setmetatable({}, {__mode = "k"})
 self.ZEBossPending = {}
 self.ZEBossPendingAny = false
 self.NextBossUpdate = nil
end
hook.Add("Think", "ZSBossUpdates", function() GAMEMODE:FlushZombieEscapeBossUpdates() end)
hook.Add("PreCleanupMap", "ZSBossReset", function() GAMEMODE:ResetZombieEscapeBosses() end)
hook.Add("EntityTakeDamage", "PhysboxTakeDamage", function(ent, info)
 if ent:GetClass() == "func_physbox_multiplayer" then GAMEMODE:BossDamageTaken(ent, info:GetAttacker()) end
end)
hook.Add("EntityRemoved", "PhysboxRemoved", function(ent) GAMEMODE:BossDeath(ent) end)
