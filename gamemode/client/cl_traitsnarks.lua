local background=Color(17,23,29,235)
local foreground=Color(230,237,243)
local accent=Color(126,229,213)
local empty=Color(239,115,115)
local graph=GetConVar("net_graph")
function GM:DrawTraitSnarkHUD(pl,weapon)
 if self.RoundEnded or not IsValid(pl)or not pl:Alive()or not self:HasPlayerTrait(pl,"alientrainer")
  or not IsValid(weapon)or weapon:GetOwner()~=pl or pl:GetActiveWeapon()~=weapon then return false end
 local charges=math.Clamp(weapon:Clip1(),0,3)
 if weapon.ZSSnarkHUDCharges~=charges then weapon.ZSSnarkHUDCharges=charges;weapon.ZSSnarkHUDText=tostring(charges).." / 3"end
 local scale=math.max(1,BetterScreenScale());local margin=24*scale
 local width=math.max(1,math.min(280*scale,ScrW()-margin*2));local height=88*scale
 local x,y=ScrW()-width-margin,ScrH()-height-margin
 if graph and graph:GetInt()>0 then y=margin end
 draw.RoundedBox(8*scale,x,y,width,height,background)
 draw.SimpleText("SNARKS","ZSMenuBody",x+14*scale,y+10*scale,foreground)
 draw.SimpleText(weapon.ZSSnarkHUDText,"ZSMenuTitle",x+width-14*scale,y+10*scale,charges>0 and accent or empty,TEXT_ALIGN_RIGHT)
 draw.SimpleText(charges==0 and "No charges remaining"or "Primary fire: release","ZSMenuBody",x+14*scale,y+40*scale,foreground)
 draw.SimpleText("3 active | 12s lifespan","ZSMenuSmall",x+14*scale,y+62*scale,foreground)
 return true
end
