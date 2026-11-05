local gm = GM or GAMEMODE
local entityMeta = FindMetaTable("Entity")
local setProxy = entityMeta.SetNWVarProxy
if type(setProxy) ~= "function" then setProxy = entityMeta.SetNetworkedVarProxy end
assert(type(setProxy) == "function", "Barricade ghost eligibility requires a supported legacy NW proxy setter")
local previous = gm.ZSBarricadeGhostClient
if type(previous) == "table" and type(previous.Destroy) == "function" then previous:Destroy() end

local dispatch = gm.ZSBarricadeGhostPropDispatch
if not dispatch then
 dispatch = {entities = setmetatable({}, {__mode = "k"}), generation = 0}
 gm.ZSBarricadeGhostPropDispatch = dispatch
 dispatch.callback = function(subject, name, oldValue, newValue)
  local current = gm.ZSBarricadeGhostClient
  if current and current.active and IsValid(subject) then current:ApplyPropValue(subject, newValue) end
 end
end
dispatch.generation = dispatch.generation + 1
local state = {active = true, hooks = {}, generation = dispatch.generation}
gm.ZSBarricadeGhostClient = state
local modeKey, policyKey, propKey = gm.BarricadeGhostModeKey, gm.BarricadeGhostPolicyKey, gm.BarricadeGhostPropKey

function state:Bind(event, name, callback)
 self.hooks[#self.hooks + 1] = {event, name, callback}
 hook.Add(event, name, callback)
end

function state:Destroy()
 if not self.active then return end
 self.active = false
 local registered = hook.GetTable()
 for _, binding in ipairs(self.hooks) do
  if registered[binding[1]] and registered[binding[1]][binding[2]] == binding[3] then hook.Remove(binding[1], binding[2]) end
 end
 if gm.ZSBarricadeGhostClient == self then gm.ZSBarricadeGhostClient = nil end
end

function state:ApplyPropValue(entity, value)
 if type(value) == "boolean" then gm:ApplyBarricadeGhostPropEligibility(entity, value)
 else gm:ForgetBarricadeGhostPropEligibility(entity) end
end

local function Initialize(entity, force)
 if not state.active or not IsValid(entity) then return end
 if entity:IsPlayer() then
  gm:ApplyBarricadeGhostPolicy(entity, entity:GetNW2Int(policyKey, 0))
  local authority = entity:GetNW2String(modeKey, "")
  if authority ~= "" then gm:ApplyBarricadeGhostAuthority(entity, authority) end
  return
 end
 if force or dispatch.entities[entity] ~= state.generation then
  setProxy(entity, propKey, dispatch.callback)
  dispatch.entities[entity] = state.generation
 end
 local absentFalse, absentTrue = entity:GetNWBool(propKey, false), entity:GetNWBool(propKey, true)
 if absentFalse == absentTrue then state:ApplyPropValue(entity, absentFalse)
 else state:ApplyPropValue(entity, nil) end
end

local function InitializeAll()
 if not state.active then return end
 for _, entity in ents.Iterator() do Initialize(entity) end
end

state:Bind("EntityNetworkedVarChanged", "ZSBarricadeGhostAuthority", function(entity, name, oldValue, newValue)
 if not state.active or not IsValid(entity) or not entity:IsPlayer() then return end
 if name == modeKey then gm:ApplyBarricadeGhostAuthority(entity, newValue)
 elseif name == policyKey then gm:ApplyBarricadeGhostPolicy(entity, newValue) end
end)

state:Bind("SetupMove", "ZSBarricadeGhostPrediction", function(pl, move, command)
 if not state.active or game.SinglePlayer() or pl ~= LocalPlayer() then return end
 gm:ObserveBarricadeGhostMode(pl)
 local brake = gm:UpdatePlayerBarricadeGhosting(pl, move:KeyDown(IN_ZOOM), move:GetOrigin(), move:KeyPressed(IN_ZOOM), command:CommandNumber())
 if brake then move:SetVelocity(vector_origin) end
end)

state:Bind("NetworkEntityCreated", "ZSBarricadeGhostEntity", function(entity) Initialize(entity, true) end)
state:Bind("NotifyShouldTransmit", "ZSBarricadeGhostTransmit", function(entity, transmitting) if transmitting then Initialize(entity, true) end end)
state:Bind("InitPostEntity", "ZSBarricadeGhostInit", InitializeAll)
state:Bind("EntityRemoved", "ZSBarricadeGhostRemoved", function(entity) dispatch.entities[entity] = nil end)

if IsValid(LocalPlayer()) then InitializeAll() end
