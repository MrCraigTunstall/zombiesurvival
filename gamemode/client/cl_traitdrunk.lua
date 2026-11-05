local sin=math.sin
function GM:ApplyTraitDrunkView(pl,angles)
 if not IsValid(pl) or not pl:Alive() or pl:Team()~=TEAM_HUMAN or not self:HasPlayerTrait(pl,"drunktard")then return end
 local now=CurTime();local remaining=pl:GetNW2Float("zs_trait_drunk",0)-now
 if remaining<=0 or remaining~=remaining or remaining==math.huge then return end
 local amplitude=math.min(1,remaining/2)
 angles.p=angles.p+sin(now*14.4513262)*0.6*amplitude
 angles.r=angles.r+sin(now*9.7389372)*0.8*amplitude
end
