local trace = {mask = MASK_SHOT, mins = Vector(-2, -2, -2), maxs = Vector(2, 2, 2)}
local filter = {}
local entitylist = {}

local colTemp = Color(255, 255, 255)
local labelShadow = Color(0, 0, 0)
local targetLabels=setmetatable({},{__mode="k"})
local placeTarget = include("cl_targetplacement.lua")()
local function TargetLine(cache,index,text,font,width,scale)
 local line=cache.lines[index]
 if not line then line={}cache.lines[index]=line end
 line.visible=text~=nil
 if not line.visible then return end
 if line.text~=text or line.font~=font or line.limit~=width or line.scale~=scale or line.revision~=GAMEMODE.LegacyFontRevision then
  line.text,line.font,line.limit,line.scale=text,font,width,scale
  line.revision=GAMEMODE.LegacyFontRevision
  line.drawText=ZSHUDStyle.Fit(text,font,width)
  surface.SetFont(font)line.width,line.height=surface.GetTextSize(line.drawText)
 end
 return line
end
function GM:DrawTargetID(ent, fade)
 local point = ent:EyePos()
 point.z = point.z + 12
 local ts = point:ToScreen()
 if ts.visible==false or ts.x~=ts.x or ts.y~=ts.y or math.abs(ts.x)==math.huge or math.abs(ts.y)==math.huge then return end
 local scale=BetterScreenScale()
 local screenWidth,screenHeight=self:GetHUDRightEdge(),ScrH()
 local margin,gap=8*scale,4*scale
 local width=math.max(1,math.min(320*scale,screenWidth-margin*2))
 local cache=targetLabels[ent]
 if not cache then cache={lines={}}targetLabels[ent]=cache end
 local teamid=ent:Team()
 local healthfraction=math.max(ent:Health()/math.max(1,teamid==TEAM_UNDEAD and ent:GetMaxZombieHealth()or ent:GetMaxHealth()),0)
 TargetLine(cache,1,ent:Name(),"ZSHUDFontSmaller",width,scale)
 local revision=translate.GetRevision and translate.GetRevision()
 local level
 if not ent:IsBot()then
  local value=ent:GetZSLevel()
  if cache.level~=value or cache.revision~=revision then cache.level,cache.revision=value,revision cache.levelText=translate.Format("player_level",value)end
  level=cache.levelText
 end
 TargetLine(cache,2,level,"ZSHUDFontTiny",width,scale)
 local health
 if healthfraction~=1 then
  local percent=math.ceil(healthfraction*100)
  if cache.percent~=percent then cache.percent,cache.healthText=percent,percent.."%"end
  health=cache.healthText
 end
 TargetLine(cache,3,health,"ZSHUDFontSmaller",width,scale)
 local extra
 if teamid==TEAM_UNDEAD then
  local class=ent:GetZombieClassTable()
  if cache.class ~= class or cache.classKey ~= class.TranslationName or cache.className ~= class.Name or cache.classRevision ~= revision then
   cache.class, cache.classKey, cache.className, cache.classRevision = class, class.TranslationName, class.Name, revision
   cache.classText = class.TranslationName and translate.Get(class.TranslationName) or class.Name
  end
  extra = cache.classText
 else
  local holding=ent:GetHolding()
  if IsValid(holding)then
   local model=holding:GetModel()
   if cache.model~=model or cache.modelRevision~=revision then
    cache.model,cache.modelRevision=model,revision cache.carriedText=translate.Format("carrying_prop",string.match(model,".*/(.+)%.mdl")or "object")
   end
   extra=cache.carriedText
  else
   local weapon=ent:GetActiveWeapon()
   if IsValid(weapon)then extra=weapon:GetPrintName()end
  end
 end
 TargetLine(cache,4,extra,"ZSHUDFontTiny",width,scale)
 local height,longest,count=0,0,0
 for _,line in ipairs(cache.lines)do if line.visible then height=height+line.height longest=math.max(longest,line.width)count=count+1 end end
 height=height+math.max(0,count-1)*gap
 local obstacles, obstacleCount, obstacleRevision = self:GetHUDLabelObstacles()
 local desiredX, desiredY = math.floor(ts.x - longest * .5 + .5), math.floor(ts.y - height - gap + .5)
 if cache.anchorX ~= desiredX or cache.anchorY ~= desiredY or cache.boxWidth ~= longest or cache.boxHeight ~= height
 or cache.obstacleRevision ~= obstacleRevision or cache.right ~= screenWidth or cache.bottom ~= screenHeight then
  cache.anchorX, cache.anchorY, cache.boxWidth, cache.boxHeight = desiredX, desiredY, longest, height
  cache.obstacleRevision, cache.right, cache.bottom = obstacleRevision, screenWidth, screenHeight
  cache.drawX, cache.drawY = placeTarget(desiredX, desiredY, longest, height, screenWidth, screenHeight, obstacles, obstacleCount, margin, gap)
 end
 if not cache.drawX then return end
 local x, y = cache.drawX + longest * .5, cache.drawY
 local alpha=(type(fade)=="number"and fade==fade and math.Clamp(fade,0,1)or 1)*255
 local shadowOffset = math.max(1, math.floor(scale + .5))
 labelShadow.a = alpha * .7
 for index,line in ipairs(cache.lines)do if line.visible then
  local color=index<=2 and COLOR_FRIENDLY or index==3 and (healthfraction>=.75 and COLOR_HEALTHY or healthfraction>=.5 and COLOR_SCRATCHED or healthfraction>=.25 and COLOR_HURT or COLOR_CRITICAL)or color_white
  util.ColorCopy(color,colTemp)colTemp.a=alpha
  draw.SimpleText(line.drawText,line.font,x+shadowOffset,y+shadowOffset,labelShadow,TEXT_ALIGN_CENTER)
  draw.SimpleText(line.drawText,line.font,x,y,colTemp,TEXT_ALIGN_CENTER)
  y=y+line.height+gap
 end end
end

GM.TraceTarget = NULL

local function FuncFilterPlayers(ent)
	return not ent:IsPlayer()
end
local function FuncFilterTeam(ent)
	return not (ent:IsPlayer() and ent:Team() == MySelf:Team())
end
function GM:HUDDrawTargetID(teamid)
	local start = EyePos()
	trace.start = start
	trace.endpos = start + EyeVector() * 2048
	filter[1] = MySelf.TargetIDFilter or MySelf
	filter[2] = MySelf:GetObserverTarget()
	trace.filter = filter

	local isspectator = MySelf:IsSpectator()

	local entity = util.TraceHull(trace).Entity
	self.TraceTarget = entity
	trace.filter = FuncFilterPlayers
	self.TraceTargetNoPlayers = util.TraceLine(trace).Entity

	if entity:IsValid() and (entity:IsPlayer() and (entity:Team() == teamid or isspectator) or entity.Sigil) then
		entitylist[entity] = CurTime()
	end

	for ent, time in pairs(entitylist) do
		if ent:IsValidPlayer() and (ent:Team() == teamid or isspectator) and CurTime() < time + 1.5 then
			self:DrawTargetID(ent, 1 - math.Clamp((CurTime() - time) / 1.5, 0, 1))
		else
			entitylist[ent] = nil
		end
	end
end
