local style = ZSHUDStyle
local place = include("cl_targetplacement.lua")()
local sigilMaterial = Material("zombiesurvival/sigil/icon.png")
local safeColor = Color(85, 215, 175)
local corruptColor = Color(220, 64, 60)
local emptyColor = Color(42, 56, 65, 150)
local entries, pool = {}, {}
local snapshot, nextSnapshot, used = nil, 0, 0
local currentpower = 0
local nextSpawnCheck, spawnTarget, spawnValid = 0, nil, false
local revision, title, lastTeam, lastPercent, percentText, readyText
local data = {}

local function Finite(value)
 return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end

local function UpdateSigils(gm, now)
 local source = gm.CachedSigils
 local enabled = gm:GetUseSigils() and gm.MaxSigils > 0
 if snapshot==source and data.sigilsEnabled==enabled and now<nextSnapshot then return end
 snapshot, data.sigilsEnabled, nextSnapshot = source, enabled, now+.1
 used = 0
 if enabled and source then
  for _,sigil in ipairs(source)do
   if IsValid(sigil)then
    local health, maximum = sigil:GetSigilHealth(), sigil:GetSigilMaxHealth()
    if Finite(health)and health>=0 then
     used=used+1
     local row=pool[used]
     if not row then row={color=Color(0,0,0)}pool[used]=row end
     row.entity,row.letter=sigil,sigil:GetSigilLetter()
     row.fraction=math.Clamp(health/math.max(1,Finite(maximum)and maximum or 1),0,1)
     row.corrupted=sigil:GetSigilCorrupted()
     row.lastDamage=sigil:GetSigilLastDamaged()
     entries[used]=row
    end
   end
  end
 end
 for index=used+1,#entries do entries[index]=nil end
end

local function Geometry(gm, scale, alternate)
 local obstacles,count,obstacleRevision=gm:GetHUDLabelObstacles(true)
 local right,height=gm:GetHUDRightEdge(),ScrH()
 local footer=alternate and 16 or 0
 local margin,gap=8*scale,4*scale
 local normal=math.min(220*scale,right-margin*2)
 if data.obstacleRevision==obstacleRevision and data.right==right and data.screenHeight==height
 and data.scale==scale and data.count==used and data.footer==footer then return end
 data.obstacleRevision,data.right,data.screenHeight=obstacleRevision,right,height
 data.scale,data.count,data.footer=scale,used,footer
 data.x=nil
 for attempt=1,2 do
  local width=attempt==1 and normal or math.min(normal,132*scale)
  local inner=math.max(1,width-24*scale)
  local columns=used==0 and 1 or math.min(used,math.max(1,math.floor((inner+gap)/(24*scale))))
  local rows=used==0 and 0 or math.ceil(used/columns)
  local tall=(28+footer)*scale+(rows>0 and gap+rows*24*scale+(rows-1)*gap or 0)
  local x,y=place((right-width)*.5,height-tall-margin,width,tall,right,height,obstacles,count,margin,gap)
  if x then
   data.x,data.y,data.width,data.height=x,y,width,tall
   data.columns,data.cellWidth=columns,(inner-(columns-1)*gap)/columns
   data.sigilTop=(28+footer)*scale+gap
   data.fitWidth=nil
   return
  end
 end
end

function GM:DrawFearMeter(power, screenscale)
 if self.ZombieEscape then self.FearHUDData=nil return end
 local actor=MySelf
 if not IsValid(actor)then self.FearHUDData=nil return end
 power=Finite(power)and math.Clamp(power,0,1)or 0
 local step=FrameTime()*(math.tan(currentpower)*2+.05)
 if currentpower<power then currentpower=math.min(power,currentpower+step)
 elseif power<currentpower then currentpower=math.max(power,currentpower-step)end
 local now,scale,teamid=RealTime(),style.Scale(),actor:Team()
 UpdateSigils(self,now)
 local alternate=teamid==TEAM_UNDEAD and self:GetDynamicSpawning()and self:ShouldUseAlternateDynamicSpawn()
 if alternate then
  local observer=actor:GetObserverTarget()
  local target=IsValid(observer)and observer:IsPlayer()and observer:Team()==TEAM_UNDEAD and observer or actor
  if spawnTarget~=target or now>=nextSpawnCheck then
   spawnTarget,nextSpawnCheck=target,now+.1
   spawnValid=self:DynamicSpawnIsValid(target)and true or false
  end
 else spawnTarget,nextSpawnCheck=nil,0 end
 local language=translate.GetRevision()
 local percent=math.ceil((teamid==TEAM_UNDEAD and self:GetDamageResistance(currentpower)or currentpower)*100)
 if revision~=language or lastTeam~=teamid then
  revision,lastTeam=language,teamid
  title=translate.Get(teamid==TEAM_UNDEAD and "fear_hud_resistance"or "fear_hud_fear")
  data.fitWidth=nil
 end
 if lastPercent~=percent then lastPercent,percentText=percent,percent.."%"data.fitWidth=nil end
 if data.ready~=spawnValid or data.readyRevision~=language then
  data.ready,data.readyRevision=spawnValid,language
  readyText=translate.Get(spawnValid and "fear_spawn_ready"or "fear_spawn_blocked")
  data.fitWidth=nil
 end
 Geometry(self,scale,alternate)
 self.FearHUDData=data
 data.frame=FrameNumber()
 if not data.x then return end
 if data.fitWidth~=data.width then
  data.fitWidth=data.width
  surface.SetFont("ZSHUDLabel")local valueWidth=surface.GetTextSize(percentText)
  data.title=style.Fit(title,"ZSHUDSmall",math.max(0,data.width-32*scale-valueWidth))
  data.readyText=style.Fit(readyText,"ZSHUDSmall",math.max(0,data.width-24*scale))
 end
 local x,y,width=data.x,data.y,data.width
 local color=currentpower>=.75 and style.Danger or style.Accent
 style.Card(x,y,width,data.height,nil,true)
 draw.SimpleText(data.title,"ZSHUDSmall",x+12*scale,y+5*scale,style.Muted)
 draw.SimpleText(percentText,"ZSHUDLabel",x+width-12*scale,y+4*scale,color,TEXT_ALIGN_RIGHT)
 surface.SetDrawColor(style.Track)surface.DrawRect(x+12*scale,y+23*scale,width-24*scale,3*scale)
 surface.SetDrawColor(color)surface.DrawRect(x+12*scale,y+23*scale,(width-24*scale)*currentpower,3*scale)
 if alternate then draw.SimpleText(data.readyText,"ZSHUDSmall",x+12*scale,y+29*scale,spawnValid and safeColor or corruptColor)end
 surface.SetMaterial(sigilMaterial)
 local clock=CurTime()
 for index=1,used do
  local row=entries[index]
  if IsValid(row.entity)then
   local cx=x+12*scale+(index-1)%data.columns*(data.cellWidth+4*scale)
   local cy=y+data.sigilTop+math.floor((index-1)/data.columns)*28*scale
   draw.RoundedBox(3*scale,cx,cy,data.cellWidth,24*scale,emptyColor)
   local tint=row.color
   if row.corrupted then tint.r,tint.g,tint.b=220,64,60
   else
    local flash=math.Clamp((clock-(Finite(row.lastDamage)and row.lastDamage or clock))*2,0,1)*255
    tint.r,tint.g,tint.b=(255-flash)*row.fraction,flash*row.fraction,220
   end
   surface.SetDrawColor(tint.r,tint.g,tint.b,220)
   surface.DrawTexturedRect(cx+4*scale,cy+4*scale,8*scale,16*scale)
   surface.DrawRect(cx+3*scale,cy+22*scale,(data.cellWidth-6*scale)*row.fraction,2*scale)
   draw.SimpleText(row.letter,"ZSHUDLabel",cx+(data.cellWidth+10*scale)*.5,cy+12*scale,style.Text,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  end
 end
end
