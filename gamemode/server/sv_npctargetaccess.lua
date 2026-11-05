local state=GM.ZSNPCTargetAccess or {players={},tokens={}}
GM.ZSNPCTargetAccess=state
local function Disabled(pl)
 return bit.band(pl:GetFlags(),FL_NOTARGET)~=0
end
local function Restore(pl,record)
 if IsValid(pl)and pl:IsPlayer()and pl:Team()==TEAM_UNDEAD and Disabled(pl)~=record.previous then pl:SetNoTarget(record.previous)end
end
local function Forget(pl)
 local record=state.players[pl]
 if not record then return false end
 for token in pairs(record.tokens)do
  local targets=state.tokens[token]
  if targets then targets[pl]=nil;if not next(targets)then state.tokens[token]=nil end end
 end
 state.players[pl]=nil;Restore(pl,record)
 return true
end
function GM:AcquireNPCTargetAccess(pl,token,previous)
 if token==nil or token~=token or not IsValid(pl)or not pl:IsPlayer()or not pl:Alive()or pl:Team()~=TEAM_UNDEAD then return false end
 local record=state.players[pl]
 if not record then
  if type(previous)~="boolean"then previous=Disabled(pl)end
  record={previous=previous,tokens={},count=0}
  state.players[pl]=record
 end
 if not record.tokens[token]then
  record.tokens[token]=true;record.count=record.count+1
  local targets=state.tokens[token]
  if not targets then targets={};state.tokens[token]=targets end
  targets[pl]=true
 end
 if Disabled(pl)then pl:SetNoTarget(false)end
 return true
end
function GM:ReleaseNPCTargetAccess(pl,token)
 local record=state.players[pl]
 if not record or not record.tokens[token]then return false end
 record.tokens[token]=nil;record.count=record.count-1
 local targets=state.tokens[token]
 if targets then targets[pl]=nil;if not next(targets)then state.tokens[token]=nil end end
 if record.count==0 then state.players[pl]=nil;Restore(pl,record)end
 return true
end
function GM:ReleaseNPCTargetAccessToken(token)
 local targets=state.tokens[token]
 if not targets then return false end
 for pl in pairs(targets)do self:ReleaseNPCTargetAccess(pl,token)end
 return true
end
function GM:GetNPCTargetAccessCount(pl)
 local record=state.players[pl]
 return record and record.count or 0
end
function GM:ResetNPCTargetAccess()
 for pl in pairs(state.players)do Forget(pl)end
end
hook.Add("PlayerDeath","ZSNPCTargetAccess",function(pl)Forget(pl)end)
hook.Add("PlayerDisconnected","ZSNPCTargetAccess",function(pl)Forget(pl)end)
hook.Add("PlayerSpawn","ZSNPCTargetAccess",function(pl)Forget(pl)end)
hook.Add("OnPlayerChangedTeam","ZSNPCTargetAccess",function(pl)Forget(pl)end)
hook.Add("EntityRemoved","ZSNPCTargetAccess",function(ent)
 GAMEMODE:ReleaseNPCTargetAccessToken(ent);Forget(ent)
end)
hook.Add("PostCleanupMap","ZSNPCTargetAccess",function()GAMEMODE:ResetNPCTargetAccess()end)
