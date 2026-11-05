GM.ZombieSkinVariants=CreateConVar("zs_zombie_skin_variants","1",FCVAR_ARCHIVE+FCVAR_NOTIFY,"Enable zombie model, tint, skin and bodygroup variety.",0,1)
GM.ZombieColorVariants={Color(255,255,255),Color(200,180,160),Color(180,200,180),Color(200,160,160),Color(160,180,200),Color(220,200,180),Color(180,160,140),Color(200,180,200)}
GM.ZombieClassModelVariants={
	["Zombie"]={"models/player/zombie_classic.mdl","models/player/zombie_classic_hbfix.mdl","models/player/zombie_soldier.mdl"},
	["Classic Zombie"]={"models/player/zombie_classic.mdl","models/player/zombie_classic_hbfix.mdl"},
	["Fast Zombie"]={"models/player/zombie_fast.mdl"},
	["Poison Zombie"]={"models/player/zombie_classic.mdl"},
	["Zombine"]={"models/zombiesurvival/zombine/zombie_soldier.mdl"}
}
GM.ZombieModelMaterialVariants={
 ["models/player/zombie_classic.mdl"]={"zombiesurvival/skins/industrial_worker"},
 ["models/player/zombie_classic_hbfix.mdl"]={"zombiesurvival/skins/industrial_worker"},
 ["models/player/zombie_fast.mdl"]={"zombiesurvival/skins/quarry_runner"},
 ["models/zombie/poison.mdl"]={"zombiesurvival/skins/containment_worker"}
}
GM.ZombieModelMaterialTargets={
 ["models/player/zombie_fast.mdl"]="models/zombie_fast_players/fast_zombie_sheet",
 ["models/zombie/poison.mdl"]="models/zombie_poison/poisonzombie_sheet"
}
local models,materialSlots={},{}
function GM:ClearZombieSkinVariant(pl)
	local state=pl.ZSZombieSkinVariant
	if not state then return end
	pl:SetColor(state.color)
	if pl:GetModel()==state.model then
		pl:SetSkin(state.skin)
		for id,value in pairs(state.bodygroups)do pl:SetBodygroup(id,value)end
	end
	if state.materialSlot then
  if pl:GetSubMaterial(state.materialSlot)==state.material then pl:SetSubMaterial(state.materialSlot,state.originalMaterial~="" and state.originalMaterial or nil)end
 end
 pl.ZSZombieSkinVariant=nil
end
function GM:ApplyZombieSkinVariant(pl)
	if not self.ZombieSkinVariants:GetBool() or not self:CanHaveZombieSpawnVariant(pl) or pl.ZSZombieSkinVariant then return false end
	local class=pl:GetZombieClassTable()
	if class.OverrideModel then return false end
	local state={color=pl:GetColor(),skin=pl:GetSkin(),bodygroups={}}
	local source=self.ZombieClassModelVariants[class.Name]
	if source and #source>0 then
		local current=pl:GetModel()
		local key=class.Name.."|"..current
		local cached=models[key]
		if not cached or cached.source~=source or cached.count~=#source then
			cached={source=source,count=#source,list={current}}
			local seen={[string.lower(current)]=true}
			for _,model in ipairs(source)do
				local lower=string.lower(model)
				if not seen[lower] and util.IsValidModel(model) then cached.list[#cached.list+1]=model;seen[lower]=true end
			end
			models[key]=cached
		end
		local model=cached.list[math.random(#cached.list)]
		if model~=current then pl:SetModel(model)end
	end
	state.model=pl:GetModel()
	state.skin=pl:GetSkin()
	local tint=self.ZombieColorVariants[math.random(#self.ZombieColorVariants)]
	local skins=pl:SkinCount()
	if skins>1 then pl:SetSkin(math.random(0,skins-1))end
	local locked=type(class.SkinBodygroupLocks)=="table"and class.SkinBodygroupLocks
	for id=0,pl:GetNumBodyGroups()-1 do
		if not locked or not locked[id] then
		local count=pl:GetBodygroupCount(id)
		if count>1 then state.bodygroups[id]=pl:GetBodygroup(id);pl:SetBodygroup(id,math.random(0,count-1))end
		end
	end
	local variants=self.ZombieModelMaterialVariants[string.lower(state.model)]
 if variants and #variants>0 then
  local target=self.ZombieModelMaterialTargets[string.lower(state.model)] or "models/zombie_classic/zombie_players_sheet"
  local cached=materialSlots[state.model]
  if not cached or cached.target~=target then
   cached={target=target,slot=false}
   for index,name in ipairs(pl:GetMaterials())do
    if string.lower(name)==target and index<=32 then cached.slot=index-1;break end
   end
   materialSlots[state.model]=cached
  end
  local slot=cached.slot
  if slot~=false then
   local choice=math.random(#variants+1)
   if choice<=#variants then
    state.materialSlot,state.material,state.originalMaterial=slot,variants[choice],pl:GetSubMaterial(slot)
    pl:SetSubMaterial(slot,state.material)
   end
  end
 end
 if not state.materialSlot and(tint.r~=state.color.r or tint.g~=state.color.g or tint.b~=state.color.b)then
  pl:SetColor(Color(tint.r,tint.g,tint.b,state.color.a))
 end
 pl.ZSZombieSkinVariant=state
	return true
end
hook.Add("OnReloaded","ZSZombieSkinModels",function()models={};materialSlots={}end)
