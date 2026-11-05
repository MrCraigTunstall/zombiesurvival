local state = GM.ZSBarricadeGhosting
GM.ZSBarricadeGhostCommandController = true

local function Reset(pl)
 if not IsValid(pl) then return end
 GAMEMODE:SyncBarricadeGhostPolicy(pl)
 GAMEMODE:ResetBarricadeGhosting(pl, true)
end

hook.Add("PlayerSpawn", "ZSBarricadeGhosting", Reset)
hook.Add("PlayerDeath", "ZSBarricadeGhosting", Reset)
hook.Add("PlayerSilentDeath", "ZSBarricadeGhosting", Reset)
hook.Add("OnPlayerChangedTeam", "ZSBarricadeGhosting", function(pl, oldteam, newteam)
 if oldteam ~= newteam then Reset(pl) end
end)
hook.Add("PlayerDisconnected", "ZSBarricadeGhosting", function(pl)
 state.active[pl], state.players[pl], state.geometry[pl] = nil, nil, nil
end)

hook.Add("StartCommand", "ZSBarricadeGhosting", function(pl, command)
 GAMEMODE:BeginBarricadeGhostCommand(pl, command:CommandNumber())
end)

hook.Add("SetupMove", "ZSBarricadeGhosting", function(pl, move, command)
 local gm = GAMEMODE
 gm:ObserveBarricadeGhostMode(pl)
 local teamid = pl:Team()
 if teamid ~= TEAM_HUMAN and teamid ~= TEAM_REDEEMER and not state.active[pl] then return end
 gm:SyncBarricadeGhostPolicy(pl)
 if gm:UpdatePlayerBarricadeGhosting(pl, move:KeyDown(IN_ZOOM), move:GetOrigin(), move:KeyPressed(IN_ZOOM), command:CommandNumber()) then move:SetVelocity(vector_origin) end
end)

hook.Add("FinishMove", "ZSBarricadeGhosting", function(pl)
 GAMEMODE:EndBarricadeGhostCommand(pl)
end)

hook.Add("Think", "ZSBarricadeGhosting", function()
 local tick = engine.TickCount()
 for pl in pairs(state.active) do
  if not IsValid(pl) then state.active[pl], state.players[pl], state.geometry[pl] = nil, nil, nil
  else
   local data = state.players[pl]
   if data and data.processedTick ~= tick then
    data.processedTick = tick
    local teamid = pl:Team()
    if teamid == TEAM_HUMAN or teamid == TEAM_REDEEMER then
     pl:BarricadeGhostingThink()
     if IsValid(pl) then GAMEMODE:ObserveBarricadeGhostMode(pl) end
    end
   end
  end
 end
end)

hook.Add("EntityRemoved", "ZSBarricadeGhosting", function(ent)
 state.active[ent], state.players[ent], state.geometry[ent], state.props[ent], state.temporary[ent] = nil, nil, nil, nil, nil
end)

local function Bootstrap()
 for _, pl in player.Iterator() do
  GAMEMODE:SyncBarricadeGhostPolicy(pl)
  GAMEMODE:ObserveBarricadeGhostMode(pl)
 end
 for _, ent in ents.Iterator() do
  if IsValid(ent) and not ent:IsPlayer() and not ent:IsWorld()
   and (ent.IsBarricadeObject or ent:IsNailed() or state.props[ent] ~= nil) then
   GAMEMODE:SyncBarricadeGhostPropEligibility(ent)
  end
 end
end

hook.Add("InitPostEntity", "ZSBarricadeGhosting", Bootstrap)
hook.Add("OnReloaded", "ZSBarricadeGhosting", Bootstrap)
