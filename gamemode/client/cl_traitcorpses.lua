function GM:GetHeadcrabDeathView(pl)
 if pl:Alive() or pl:Team()~=TEAM_UNDEAD or pl:GetObserverMode()~=OBS_MODE_NONE then return end
 local body=pl:GetNW2Entity("zs_headcrab_body")
 if not IsValid(body)then return end
 local target=body:WorldSpaceCenter()
 local desired=target+Vector(0,0,48)-pl:EyeAngles():Forward()*48
 local trace=util.TraceHull({start=target,endpos=desired,mins=Vector(-4,-4,-4),maxs=Vector(4,4,4),filter={pl,body},mask=MASK_SOLID})
 return trace.HitPos,(target-trace.HitPos):Angle()
end
