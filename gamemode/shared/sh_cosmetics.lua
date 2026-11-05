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
GM:AddCosmetic('human_hat_1','Roadwork crown','A traffic-cone hat for survivors.',COSMETICCAT_HATS,TEAM_HUMAN,50,{model='models/props_junk/TrafficCone001a.mdl',scale=0.3,lift=5})
GM:AddCosmetic('human_pot_hat','Tin guardian','A metal-can hat for survivors.',COSMETICCAT_HATS,TEAM_HUMAN,50,{model='models/props_junk/garbage_metalcan001a.mdl',scale=0.45,lift=5})
GM:AddCosmetic('human_azure_halo','Azure halo','A subtle blue orbit around your shoulders.',COSMETICCAT_EFFECTS,TEAM_HUMAN,75,{color=Color(105,185,255),radius=17})
GM:AddCosmetic('zombie_bloody_aura','Bloody aura','A crimson orbit for the undead.',COSMETICCAT_EFFECTS,TEAM_UNDEAD,75,{color=Color(210,30,45),radius=22})
function GM:GetCosmeticBalance(pl)
	if pl:Team()==TEAM_UNDEAD then return pl:GetTokens()end
	return pl:GetPoints()
end
