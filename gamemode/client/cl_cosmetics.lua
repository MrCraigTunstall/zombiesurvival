local glow=Material('sprites/light_glow02_add')
local orbit=Vector()
GM.ZSCosmeticModels=GM.ZSCosmeticModels or{}
local hats,bones=GM.ZSCosmeticModels,setmetatable({},{__mode='k'})
if IsValid(GM.ZSCosmeticFrame)then GM.ZSCosmeticFrame:Remove();GM.ZSCosmeticFrame=nil end
function GM:RequestCosmeticAction(action,id)
	net.Start('zs_cosmetic_action');net.WriteUInt(action,2);net.WriteUInt(id or 0,8);net.SendToServer()
end
local function HatModel(item)
	local model=hats[item.ID]
	if IsValid(model)and model.ZSCosmeticPath~=item.Data.model then model:Remove();model=nil end
	if not IsValid(model)then
		if not util.IsValidModel(item.Data.model)then return end
		model=ClientsideModel(item.Data.model,RENDERGROUP_OPAQUE)
		if not IsValid(model)then return end
		model:SetNoDraw(true);model:DrawShadow(false);model.ZSCosmeticPath=item.Data.model;hats[item.ID]=model
	end
	if model.ZSCosmeticScale~=(item.Data.scale or 1)then model.ZSCosmeticScale=item.Data.scale or 1;model:SetModelScale(model.ZSCosmeticScale,0)end
	return model
end
hook.Add('PostPlayerDraw','ZSCosmeticDraw',function(pl)
	if not IsValid(pl)or pl:IsBot()or not pl:Alive()or pl:IsDormant() then return end
	local hat=GAMEMODE.Cosmetics[pl:GetNW2Int('zs_cosmetic_hat',0)]
	local effect=GAMEMODE.Cosmetics[pl:GetNW2Int('zs_cosmetic_effect',0)]
	if not hat and not effect then return end
	local team=pl:Team()
	if not(hat and hat.Category==COSMETICCAT_HATS and hat.Team==team)then hat=nil end
	if not(effect and effect.Category==COSMETICCAT_EFFECTS and effect.Team==team)then effect=nil end
	if not hat and not effect or pl:GetPos():DistToSqr(EyePos())>700*700 or pl:GetColor().a<100 then return end
	if hat then
		local cached=bones[pl];local playerModel=pl:GetModel()
		if not cached or cached.model~=playerModel then cached={model=playerModel,index=pl:LookupBone('ValveBiped.Bip01_Head1')};bones[pl]=cached end
		local matrix=cached.index and pl:GetBoneMatrix(cached.index)
		local position=matrix and matrix:GetTranslation()or pl:EyePos()
		local model=HatModel(hat)
		if model then model:SetPos(position+Vector(0,0,hat.Data.lift or 0));model:SetAngles(Angle(0,pl:GetAngles().y,0));model:SetupBones();model:DrawModel()end
	end
	if effect then
		local center=pl:WorldSpaceCenter();local time=CurTime()*1.4+pl:EntIndex()
		render.SetMaterial(glow)
		for index=1,6 do
			local angle=time+index*math.pi/3
			orbit:SetUnpacked(math.cos(angle)*effect.Data.radius,math.sin(angle)*effect.Data.radius,math.sin(angle*2)*5)orbit:Add(center)
			render.DrawSprite(orbit,5,5,effect.Data.color)
		end
	end
end)
local function ClearModels()for id,model in pairs(hats)do if IsValid(model)then model:Remove()end;hats[id]=nil end end
hook.Add('ShutDown','ZSCosmeticCleanup',ClearModels)
hook.Add('PreCleanupMap','ZSCosmeticMapCleanup',ClearModels)
net.Receive('zs_cosmetic_state',function()
	local ok,open,message=net.ReadBool(),net.ReadBool(),net.ReadString();local count=net.ReadUInt(8)
	if count>128 or #message>256 then return end
	local owned={};for index=1,count do local id=net.ReadUInt(8);if not GAMEMODE.Cosmetics[id]then return end;owned[id]=true end
	local hat,effect=net.ReadUInt(8),net.ReadUInt(8)
	if(hat>0 and not owned[hat])or(effect>0 and not owned[effect])then return end
	if(hat>0 and GAMEMODE.Cosmetics[hat].Category~=COSMETICCAT_HATS)or(effect>0 and GAMEMODE.Cosmetics[effect].Category~=COSMETICCAT_EFFECTS)then return end
	GAMEMODE:OpenCosmeticMenu(owned,{[COSMETICCAT_HATS]=hat,[COSMETICCAT_EFFECTS]=effect},message,open)
	surface.PlaySound(ok and 'buttons/button14.wav'or 'buttons/button10.wav')
end)
