local entityMeta = FindMetaTable("Entity")
local getBool = entityMeta.GetDTBool
local maximumRevision = 536870911
local commandModulus = 4294967296
local state = GM.ZSBarricadeGhosting or {}
GM.ZSBarricadeGhosting = state
state.players = state.players or setmetatable({}, {__mode = "k"})
state.geometry = state.geometry or setmetatable({}, {__mode = "k"})
state.props = state.props or setmetatable({}, {__mode = "k"})
state.temporary = state.temporary or setmetatable({}, {__mode = "k"})
state.active = state.active or setmetatable({}, {__mode = "k"})
GM.BarricadeGhostModeKey = "zs_barricade_mode"
GM.BarricadeGhostPolicyKey = "zs_barricade_policy"
GM.BarricadeGhostPropKey = "zs_barricade_eligible"

local function Data(pl)
 local data = state.players[pl]
 if not data then data = {version = 0} state.players[pl] = data end
 return data
end

local function RawMode(pl)
 if not getBool(pl, 0) then return 0 end
 return getBool(pl, 1) and 3 or 1
end

local function LocalPrediction(pl)
 return CLIENT and not game.SinglePlayer() and pl == LocalPlayer()
end

local function Command(value)
 if type(value) ~= "number" or value ~= math.floor(value) or value < -2147483648 or value > 4294967295 then return 0 end
 return value % commandModulus
end

local function CommandAfter(value, previous)
 local difference = (value - previous) % commandModulus
 return difference > 0 and difference < 2147483648
end

function GM:BeginBarricadeGhostCommand(pl, value)
 if not IsValid(pl) then return end
 local data = Data(pl)
 data.command, data.commandActive, data.commandTick = Command(value), true, engine.TickCount()
end

function GM:EndBarricadeGhostCommand(pl)
 local data = state.players[pl]
 if data then data.command, data.commandActive, data.commandTick = nil, nil, nil end
end

function GM:GetBarricadeGhostMode(pl)
 if LocalPrediction(pl) then return RawMode(pl) end
 local data = state.players[pl]
 return data and data.mode or RawMode(pl)
end

function GM:GetBarricadeGhostCollisionFlag(pl, slot)
 if slot == 0 then return self:GetBarricadeGhostMode(pl) ~= 0 end
 return getBool(pl, slot)
end

function GM:GetBarricadeGhostPolicy(pl)
 if SERVER then return not not pl.NoGhosting, not not pl.GhostCade, true end
 local data = state.players[pl]
 local value = data and data.policy or pl:GetNW2Int(self.BarricadeGhostPolicyKey, 0)
 return value % 2 == 1, math.floor(value / 2) % 2 == 1, value >= 4
end

function GM:IsBarricadeGhostAuthorityReady(pl)
 if SERVER then return true end
 local data = state.players[pl]
 local _, _, policy = self:GetBarricadeGhostPolicy(pl)
 return data and data.revision and data.revision > 0 and policy or false
end

local function Publish(gm, pl, data, acknowledged)
 if not SERVER then return end
 if data.mode == nil then data.mode = RawMode(pl) end
 data.revision = (data.revision or 0) % maximumRevision + 1
 local packed = data.revision * 4 + data.mode
 local command = acknowledged ~= nil and Command(acknowledged) or data.commandActive and data.commandTick == engine.TickCount() and data.command or 0
 local value = string.format("%08x%08x", packed, command)
 data.packed, data.acknowledged = value, command
 if pl:GetNW2String(gm.BarricadeGhostModeKey, "") ~= value then pl:SetNW2String(gm.BarricadeGhostModeKey, value) end
end

local function Commit(gm, pl, mode, publish, commandNumber, initial)
 if not IsValid(pl) then return false end
 local data = Data(pl)
 local previous = gm:GetBarricadeGhostMode(pl)
 local changed = previous ~= mode
 data.version = data.version + 1
 local version = data.version
 data.mode = mode
 if mode ~= 0 then state.active[pl] = true else state.active[pl] = nil end
 if mode == 0 then
  pl.FirstGhostThink = nil
  data.brakeCommand, data.brakeTick = nil, nil
 elseif previous == 0 and mode == 1 then
  pl.FirstGhostThink = true
  local command = commandNumber ~= nil and Command(commandNumber) or data.commandActive and data.commandTick == engine.TickCount() and data.command or 0
  data.brakeCommand, data.brakeTick = command ~= 0 and command or nil, command == 0 and engine.TickCount() or nil
 end
 local on, fullspeed = mode ~= 0, mode == 3
 if getBool(pl, 0) ~= on then pl:SetDTBool(0, on) end
 if not IsValid(pl) or data.version ~= version then return false end
 if getBool(pl, 1) ~= fullspeed then pl:SetDTBool(1, fullspeed) end
 if not IsValid(pl) or data.version ~= version then return false end
 if (previous ~= 0) ~= on or initial then
  pl:CollisionRulesChanged()
 end
 data.collision = on
 if not IsValid(pl) or data.version ~= version then return false end
 if changed then pl:ResetJumpPower() end
 if not IsValid(pl) or data.version ~= version then return false end
 if LocalPrediction(pl) and changed and commandNumber ~= nil then
  local command = Command(commandNumber)
  if command ~= 0 and (not data.predictedCommand or not CommandAfter(data.predictedCommand, command)) then data.predictedCommand = command end
 end
 if SERVER and publish and (changed or not data.revision) then Publish(gm, pl, data, commandNumber) end
 return true, changed
end

function GM:SetPlayerBarricadeGhosting(pl, on, fullspeed, commandNumber)
 if not IsValid(pl) then return false end
 on = not not on
 local blocked = self:GetBarricadeGhostPolicy(pl)
 if on and blocked then return false end
 return Commit(self, pl, on and (fullspeed and 3 or 1) or 0, true, commandNumber)
end

function GM:ApplyBarricadeGhostAuthority(pl, value)
 if not CLIENT or not IsValid(pl) or not pl:IsPlayer() or type(value) ~= "string" or #value ~= 16 or not value:match("^[0-9a-fA-F]+$") then return false end
 local packed, acknowledged = tonumber(value:sub(1, 8), 16), tonumber(value:sub(9, 16), 16)
 if packed < 4 or packed > 2147483647 then return false end
 local mode, revision = packed % 4, math.floor(packed / 4)
 if mode == 2 or revision < 1 or revision > maximumRevision then return false end
 local data = Data(pl)
 if data.revision then
  local advance = (revision - data.revision) % maximumRevision
  if advance == 0 or advance > math.floor(maximumRevision / 2) then return false end
 end
 local initial = data.revision == nil
 data.revision, data.packed, data.authorityMode, data.acknowledged = revision, value, mode, acknowledged
 if LocalPrediction(pl) then
  if acknowledged == 0 then
   data.deniedThrough = data.predictedCommand or data.deniedThrough
   data.predictedCommand = nil
  else
   if mode == 0 and (not data.deniedThrough or CommandAfter(acknowledged, data.deniedThrough)) then data.deniedThrough = acknowledged end
   if data.predictedCommand and CommandAfter(data.predictedCommand, acknowledged) then return true end
  end
 end
 return Commit(self, pl, mode, false, nil, initial)
end

function GM:ApplyBarricadeGhostPolicy(pl, value)
 if not CLIENT or not IsValid(pl) or not pl:IsPlayer() or type(value) ~= "number" or value ~= math.floor(value) or value < 4 or value > 7 then return false end
 local data = Data(pl)
 if data.policy == value then return false end
 data.policy = value
 return true
end

function GM:SyncBarricadeGhostPolicy(pl)
 if not SERVER or not IsValid(pl) then return false end
 local value = 4 + (pl.NoGhosting and 1 or 0) + (pl.GhostCade and 2 or 0)
 local data = Data(pl)
 if data.policy == value then return false end
 data.policy = value
 if pl:GetNW2Int(self.BarricadeGhostPolicyKey, 0) == value then return false end
 pl:SetNW2Int(self.BarricadeGhostPolicyKey, value)
 return true
end

function GM:SetBarricadeGhostPolicy(pl, blocked, fast)
 if not SERVER or not IsValid(pl) then return false end
 local revoked = blocked and not pl.NoGhosting
 pl.NoGhosting, pl.GhostCade = blocked and true or nil, fast and true or nil
 self:SyncBarricadeGhostPolicy(pl)
 if revoked and self:GetBarricadeGhostMode(pl) ~= 0 then
  local data = Data(pl)
  local version = data.version
  local inside = self:IsPlayerInsideBarricade(pl, false)
  if IsValid(pl) and data.version == version and not inside then self:SetPlayerBarricadeGhosting(pl, false) end
 end
 return true
end

function GM:ObserveBarricadeGhostMode(pl)
 if not IsValid(pl) then return end
 local data, mode = Data(pl), RawMode(pl)
 if SERVER then
  if data.mode == nil then Commit(self, pl, mode, true, nil, true)
  elseif data.mode ~= mode or mode == 0 and getBool(pl, 1) then Commit(self, pl, mode, true)
  elseif not data.revision then Publish(self, pl, data) end
 elseif LocalPrediction(pl) then
  local on = mode ~= 0
  if data.collision ~= nil and data.collision ~= on then pl:CollisionRulesChanged() end
  data.collision = on
 end
end

local function MovementHull(pl)
 if pl:Crouching() then return pl:GetHullDuck() end
 return pl:GetHull()
end

local function Context(pl)
 local pool = state.geometry[pl]
 if not pool then pool = {depth = 0} state.geometry[pl] = pool end
 local depth = pool.depth + 1
 local context = pool[depth]
 if not context then
  context = {mins = Vector(), maxs = Vector(), start = Vector(), output = {}, filter = {}}
  context.trace = {mins = context.mins, maxs = context.maxs, start = context.start, endpos = context.start, output = context.output, filter = context.filter, whitelist = true, ignoreworld = true, mask = MASK_SOLID, collisiongroup = COLLISION_GROUP_NONE}
  pool[depth] = context
 end
 return pool, context, depth
end

function GM:PlayerHullIntersectsBarricadeEntity(pl, target, origin, padding, low, high)
 if not IsValid(pl) or not pl:IsPlayer() or not IsValid(target) or target:IsMarkedForDeletion() or target:IsWorld() then return false end
 if not low or not high then low, high = MovementHull(pl) end
 origin, padding = origin or pl:GetPos(), padding or 0
 local minimum, maximum = target:WorldSpaceAABB()
 if origin.x + high.x + padding < minimum.x or origin.x + low.x - padding > maximum.x
  or origin.y + high.y + padding < minimum.y or origin.y + low.y - padding > maximum.y
  or origin.z + high.z < minimum.z or origin.z + low.z > maximum.z then return false end
 local pool, context, depth = Context(pl)
 context.mins:Set(low)context.maxs:Set(high)context.start:Set(origin)
 context.mins.x, context.mins.y = context.mins.x - padding, context.mins.y - padding
 context.maxs.x, context.maxs.y = context.maxs.x + padding, context.maxs.y + padding
 if context.mins.x > context.maxs.x or context.mins.y > context.maxs.y then return false end
 context.filter[1] = target
 pool.depth = depth
 local ok, trace = pcall(util.TraceHull, context.trace)
 pool.depth = depth - 1
 if not ok then error(trace, 0) end
 if not IsValid(pl) or not IsValid(target) or target:IsMarkedForDeletion() then return false end
 return not not (trace.Hit or trace.StartSolid)
end

local function ScanInside(gm, pl, override, origin, low, high, context, data, version)
 if not context.minimum then context.minimum, context.maximum = Vector(), Vector() end
 local minimum, maximum = context.minimum, context.maximum
 minimum:Set(origin)minimum:Add(low)maximum:Set(origin)maximum:Add(high)
 if minimum.x > maximum.x or minimum.y > maximum.y then return false end
 for _, ent in ipairs(ents.FindInBox(minimum, maximum)) do
  if IsValid(ent) and not ent:IsMarkedForDeletion() and pl:ShouldBarricadeGhostWith(ent) then
   if not IsValid(pl) or data.version ~= version or pl:Team() ~= TEAM_HUMAN and not override or gm:GetBarricadeGhostMode(pl) == 0 then return false end
   if IsValid(ent) and gm:PlayerHullIntersectsBarricadeEntity(pl, ent, origin, 0, low, high) then
    return IsValid(pl) and data.version == version and (pl:Team() == TEAM_HUMAN or override) and gm:GetBarricadeGhostMode(pl) ~= 0
   end
  end
 end
 return false
end

function GM:IsPlayerInsideBarricade(pl, override, origin)
 if not IsValid(pl) or pl:Team() ~= TEAM_HUMAN and not override or self:GetBarricadeGhostMode(pl) == 0 then return false end
 local low, high = MovementHull(pl)
 origin = origin or pl:GetPos()
 local pool, context, depth = Context(pl)
 local data = Data(pl)
 pool.depth = depth
 local ok, inside = pcall(ScanInside, self, pl, override, origin, low, high, context, data, data.version)
 pool.depth = depth - 1
 if not ok then error(inside, 0) end
 return inside
end

function GM:IsEntityBarricadeGhostEligible(ent)
 if ent.IsBarricadeObject then return true end
 if SERVER then return ent:IsNailed() end
 local cached = state.props[ent]
 if cached ~= nil then return cached end
 return ent:GetNWBool(self.BarricadeGhostPropKey, ent:IsNailed())
end

function GM:ApplyBarricadeGhostPropEligibility(ent, value)
 if not CLIENT or not IsValid(ent) or type(value) ~= "boolean" then return false end
 local initial = state.props[ent] == nil
 local previous = self:IsEntityBarricadeGhostEligible(ent)
 state.props[ent] = value
 local changed = initial and value or previous ~= self:IsEntityBarricadeGhostEligible(ent)
 if changed then ent:CollisionRulesChanged() end
 return changed
end

function GM:ForgetBarricadeGhostPropEligibility(ent)
 if not CLIENT or not IsValid(ent) or state.props[ent] == nil then return false end
 local previous = self:IsEntityBarricadeGhostEligible(ent)
 state.props[ent] = nil
 local changed = previous ~= self:IsEntityBarricadeGhostEligible(ent)
 if changed then ent:CollisionRulesChanged() end
 return changed
end

function GM:SyncBarricadeGhostPropEligibility(ent)
 if not SERVER or not IsValid(ent) or ent:IsWorld() then return false end
 local value = not not (ent.IsBarricadeObject or ent:IsNailed())
 local previous = state.props[ent]
 if previous == value then return false end
 local old = previous
 if old == nil then old = ent:GetNWBool(self.BarricadeGhostPropKey, false) end
 local changed = old ~= value
 state.props[ent] = value
 if previous ~= nil or ent:GetNWBool(self.BarricadeGhostPropKey, not value) ~= value then ent:SetNWBool(self.BarricadeGhostPropKey, value) end
 if changed then ent:CollisionRulesChanged() end
 return changed
end

function GM:SetTemporaryBarricadeGhostEligibility(ent, value)
 if not SERVER or not IsValid(ent) or ent:IsWorld() then return false end
 if value then
  if ent.IsBarricadeObject and not state.temporary[ent] then return false end
  state.temporary[ent], ent.IsBarricadeObject = true, true
 else
  if not state.temporary[ent] and not (ZSTemporaryCollisions and ZSTemporaryCollisions.props[ent]) then return false end
  state.temporary[ent], ent.IsBarricadeObject = nil, nil
 end
 self:SyncBarricadeGhostPropEligibility(ent)
 return true
end

function GM:GetBarricadeGhostSpeed(pl)
 local mode = self:GetBarricadeGhostMode(pl)
 if mode == 0 or mode == 3 then return end
 local _, fast = self:GetBarricadeGhostPolicy(pl)
 return fast and 80 or 40
end

local function CanEnter(gm, pl)
 local blocked = gm:GetBarricadeGhostPolicy(pl)
 if blocked or gm.ZombieEscape or not pl:Alive() or pl:Team() ~= TEAM_HUMAN then return false end
 if pl:IsOnGround() then pl.LastGhostFailureVelocity = nil return true end
 local velocity, physics = pl:GetVelocity(), pl:GetPhysicsObject()
 if IsValid(physics) and physics:IsPenetrating() then
  if velocity.x == 0 and velocity.y == 0 and (velocity.z == -4.5 or velocity.z == 0) then pl.LastGhostFailureVelocity = nil return true end
  return false, true
 end
 if pl.LastGhostFailureVelocity == velocity then pl.LastGhostFailureVelocity = nil return true end
 pl.LastGhostFailureVelocity = velocity
 return false
end

local function Brake(pl, data, commandNumber)
 local command = Command(commandNumber)
 if commandNumber ~= nil and command ~= 0 and data.brakeCommand == command then pl.FirstGhostThink = false return true end
 if commandNumber ~= nil and command == 0 and data.brakeTick == engine.TickCount() then pl.FirstGhostThink = false return true end
 if pl.FirstGhostThink then
  pl.FirstGhostThink = false
  if commandNumber ~= nil and command ~= 0 then data.brakeCommand, data.brakeTick = command, nil
  else data.brakeCommand, data.brakeTick = nil, engine.TickCount() end
  return true
 end
 return false
end

function GM:UpdatePlayerBarricadeGhosting(pl, zoomDown, origin, pressed, commandNumber)
 if not IsValid(pl) then return false end
 if CLIENT and game.SinglePlayer() then return false end
 local data = Data(pl)
 data.processedTick = engine.TickCount()
 local mode = self:GetBarricadeGhostMode(pl)
 if not pl:Alive() then
  if mode ~= 0 then Commit(self, pl, 0, true) end
  return false
 end
 local teamid = pl:Team()
 if teamid ~= TEAM_HUMAN and teamid ~= TEAM_REDEEMER then return false end
 local command = Command(commandNumber)
 if LocalPrediction(pl) and pressed then
  if command == 0 or data.deniedThrough and not CommandAfter(command, data.deniedThrough) then return false end
  if data.acknowledged and data.acknowledged ~= 0 and not CommandAfter(command, data.acknowledged) then
   if command ~= data.acknowledged or data.authorityMode == 0 then return false end
   if mode ~= data.authorityMode then
    if not Commit(self, pl, data.authorityMode, false, commandNumber) then return false end
    mode = self:GetBarricadeGhostMode(pl)
   end
  end
 end
 if mode == 0 and pressed and (SERVER or self:IsBarricadeGhostAuthorityReady(pl)) then
  local allowed, stop = CanEnter(self, pl)
  if allowed then self:SetPlayerBarricadeGhosting(pl, true, false, commandNumber)mode = self:GetBarricadeGhostMode(pl)
  else
   if SERVER then
    local attempt = command ~= 0 and command or -engine.TickCount() - 1
    if data.deniedCommand ~= attempt then data.deniedCommand = attempt Publish(self, pl, data, commandNumber) end
   end
   return stop or false
  end
 end
 if mode == 0 then return false end
 local custom = commandNumber ~= nil and self.ZSBarricadeGhostThink and pl.BarricadeGhostingThink
 if custom and custom ~= self.ZSBarricadeGhostThink and not data.customBusy then
  data.customBusy = true
  local ok, failure = pcall(custom, pl)
  data.customBusy = nil
  if not ok then error(failure, 0) end
  if SERVER and IsValid(pl) then self:ObserveBarricadeGhostMode(pl) end
  return false
 end
 if mode == 3 then
  local version = data.version
  local inside = self:IsPlayerInsideBarricade(pl, false, origin)
  if IsValid(pl) and data.version == version and not inside then Commit(self, pl, 0, true, commandNumber) end
  return false
 end
 local blocked = self:GetBarricadeGhostPolicy(pl)
 if not blocked and zoomDown then return Brake(pl, data, commandNumber) end
 local version = data.version
 local inside = self:IsPlayerInsideBarricade(pl, false, origin)
 if not IsValid(pl) or data.version ~= version then return false end
 if inside then return Brake(pl, data, commandNumber) end
 Commit(self, pl, 0, true, commandNumber)
 return false
end

function GM:ResetBarricadeGhosting(pl, publish)
 if not IsValid(pl) then return end
 local data = Data(pl)
 Commit(self, pl, 0, false)
 pl.FirstGhostThink, pl.LastGhostFailureVelocity = nil, nil
 data.deniedCommand, data.processedTick = nil, nil
 state.geometry[pl] = nil
 if SERVER and publish then Publish(self, pl, data, 0) end
end
