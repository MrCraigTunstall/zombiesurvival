ZSHitboxTraceState = ZSHitboxTraceState or {}
local state = ZSHitboxTraceState
if not state.entities then
 state.entities = setmetatable({}, {__mode = "k"})
 for _, ent in ipairs(ents.FindByClass("fhb")) do state.entities[ent] = true end
end
function GM:RegisterManhackHitbox(ent)
 if ent:GetClass() == "fhb" then state.entities[ent] = true end
end
local function Redirect(result)
 local ent = result.Entity
 if state.entities[ent] and ent:IsValid() then result.Entity = ent:GetParent() end
 return result
end
if util.TraceLine ~= state.line then
 local trace = util.TraceLine
 state.line = function(data) return Redirect(trace(data)) end
 util.TraceLine = state.line
end
if util.TraceHull ~= state.hull then
 local trace = util.TraceHull
 state.hull = function(data) return Redirect(trace(data)) end
 util.TraceHull = state.hull
end
hook.Add("EntityRemoved", "ZSManhackHitboxes", function(ent) state.entities[ent] = nil end)
