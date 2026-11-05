COSMETICCAT_HATS,COSMETICCAT_EFFECTS=1,2
GM.Cosmetics={}
GM.CosmeticLookup={}
function GM:AddCosmetic(signature,name,description,category,team,cost,data)
	assert(type(signature)=='string'and #signature<=48 and not self.CosmeticLookup[signature]and #self.Cosmetics<128)
	assert((category==COSMETICCAT_HATS or category==COSMETICCAT_EFFECTS)and(team==TEAM_HUMAN or team==TEAM_UNDEAD))
	assert(type(cost)=='number'and cost>=0 and cost==math.floor(cost)and cost<=100000)
	local item={ID=#self.Cosmetics+1,Signature=signature,Name=name,Description=description,Category=category,Team=team,Cost=cost,Data=data or{}}
	self.Cosmetics[item.ID]=item;self.CosmeticLookup[signature]=item
	return item
end
function GM:AddLocalizedCosmetic(signature,name,description,...)
	local item=self:AddCosmetic(signature,translate.Get(name),translate.Get(description),...)
	item.NameTranslation,item.DescriptionTranslation=name,description
	item.TranslatedName,item.TranslatedDescription=item.Name,item.Description
	return item
end
GM:AddLocalizedCosmetic('human_hat_1','cosmetic_human_hat_1','cosmetic_human_hat_1_desc',COSMETICCAT_HATS,TEAM_HUMAN,50,{model='models/props_junk/TrafficCone001a.mdl',scale=0.3,lift=5})
GM:AddLocalizedCosmetic('human_pot_hat','cosmetic_human_pot_hat','cosmetic_human_pot_hat_desc',COSMETICCAT_HATS,TEAM_HUMAN,50,{model='models/props_junk/garbage_metalcan001a.mdl',scale=0.45,lift=5})
GM:AddLocalizedCosmetic('human_azure_halo','cosmetic_human_azure_halo','cosmetic_human_azure_halo_desc',COSMETICCAT_EFFECTS,TEAM_HUMAN,75,{color=Color(105,185,255),radius=17})
GM:AddLocalizedCosmetic('zombie_bloody_aura','cosmetic_zombie_bloody_aura','cosmetic_zombie_bloody_aura_desc',COSMETICCAT_EFFECTS,TEAM_UNDEAD,75,{color=Color(210,30,45),radius=22})
function GM:GetCosmeticBalance(pl)
	if pl:Team()==TEAM_UNDEAD then return pl:GetTokens()end
	return pl:GetPoints()
end
