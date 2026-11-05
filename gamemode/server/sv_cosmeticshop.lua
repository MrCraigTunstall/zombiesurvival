local function LocalizedText(pl, key, ...)
	if IsValid(pl) and pl:IsPlayer() then return translate.ClientFormat(pl, key, ...) end
	return translate.Format(key, ...)
end
local enabled=CreateConVar('zs_cosmetics_enabled','1',FCVAR_ARCHIVE,'Enable the built-in cosmetic shop.',0,1)
local state=GM.ZSCosmeticState or{profiles={},assets={}}
GM.ZSCosmeticState=state
if state.catalog~=GM.Cosmetics then state.profiles={};state.assets={};state.categoryCount=nil;state.categorySQL=nil;state.catalog=GM.Cosmetics end
local tableName='zs_cosmetics_v1'
sql.Query('CREATE TABLE IF NOT EXISTS '..tableName..' (steamid TEXT NOT NULL, cosmetic TEXT NOT NULL, equipped INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (steamid, cosmetic))')
util.AddNetworkString('zs_cosmetic_action');util.AddNetworkString('zs_cosmetic_state')
local fields={[COSMETICCAT_HATS]='zs_cosmetic_hat',[COSMETICCAT_EFFECTS]='zs_cosmetic_effect'}
local function Key(pl)
	if not IsValid(pl)or not pl:IsPlayer()or pl:IsBot()then return end
	local key=pl:SteamID64()
	if type(key)=='string'and key~='0'and key:match('^%d+$')then return key end
	if game.SinglePlayer()then return 'singleplayer'end
end
local function Sync(pl,profile)
	for category,field in pairs(fields)do
		local id=profile and profile.equipped[category]or 0
		local item=GAMEMODE.Cosmetics[id]
		if not enabled:GetBool()or not item or item.Team~=pl:Team()then id=0 end
		if pl:GetNW2Int(field,0)~=id then pl:SetNW2Int(field,id)end
	end
end
function GM:LoadPlayerCosmetics(pl)
	local key=Key(pl);if not key then return end
	local profile=state.profiles[key]
	if not profile then
		local rows=sql.Query('SELECT cosmetic,equipped FROM '..tableName..' WHERE steamid='..sql.SQLStr(key)..' LIMIT 128')
		if rows==false then return end
		profile={owned={},equipped={}}
		for _,row in ipairs(rows or{})do
			local item=self.CosmeticLookup[row.cosmetic]
			if item then profile.owned[item.ID]=true;if tonumber(row.equipped)==1 then profile.equipped[item.Category]=item.ID end end
		end
		state.profiles[key]=profile
	end
	pl.ZSCosmeticKey=key;Sync(pl,profile)
	return profile,key
end
function GM:PlayerOwnsCosmetic(pl,signature)
	local item=self.CosmeticLookup[signature];local profile=self:LoadPlayerCosmetics(pl)
	return item and profile and profile.owned[item.ID]==true or false
end
local function Asset(item)
	local model=item.Data.model
	if not model then return true end
	if state.assets[model]==nil then state.assets[model]=util.IsValidModel(model)end
	return state.assets[model]
end
function GM:CosmeticAction(pl,action,id)
	if not Key(pl)then return false,LocalizedText(pl, "cosmetic_humans_only")end
	if not enabled:GetBool()then return false,LocalizedText(pl, "cosmetic_disabled")end
	if pl.ZSCosmeticBusy then return false,LocalizedText(pl, "cosmetic_busy")end
	local profile,key=self:LoadPlayerCosmetics(pl)
	if not profile then return false,LocalizedText(pl, "cosmetic_profile_failed")end
	if action==0 then return true,LocalizedText(pl, "cosmetic_choose_team")end
	local item=self.Cosmetics[id]
	if not item or(action~=1 and action~=2)then return false,LocalizedText(pl, "cosmetic_unknown_action")end
	if type(item.Cost)~='number'or item.Cost~=item.Cost or item.Cost<0 or item.Cost>100000 or item.Cost~=math.floor(item.Cost)then return false,LocalizedText(pl, "cosmetic_invalid_price")end
	if not pl:Alive()or item.Team~=pl:Team()then return false,LocalizedText(pl, "cosmetic_wrong_team")end
	if not Asset(item)then return false,LocalizedText(pl, "cosmetic_asset_unavailable")end
	local balance=self:GetCosmeticBalance(pl)
	if action==1 and profile.owned[id]then return false,LocalizedText(pl, "cosmetic_already_owned")end
	if action==2 and not profile.owned[id]then return false,LocalizedText(pl, "cosmetic_buy_first")end
	if action==1 and(type(balance)~='number'or balance~=balance or balance==math.huge or balance<item.Cost)then return false,LocalizedText(pl, pl:Team()==TEAM_UNDEAD and "you_dont_have_enough_btokens" or "dont_have_enough_points")end
	pl.ZSCosmeticBusy=true
	local team=pl:Team()
	local cost=action==1 and item.Cost or 0
	local selected=profile.equipped[item.Category]~=id and id or 0
	if action==1 then selected=id end
	local function Query(text)return sql.Query(text)~=false end
	local begun,charged=false,false
	local ok,failure=xpcall(function()
		assert(Query('BEGIN'))
		begun=true
		if action==1 then
			charged=true
			if team==TEAM_UNDEAD then pl:SetTokens(balance-cost)else pl:TakePoints(cost)end
			assert(Query('INSERT INTO '..tableName..' (steamid,cosmetic,equipped) VALUES ('..sql.SQLStr(key)..','..sql.SQLStr(item.Signature)..',0)'))
		end
		if state.categoryCount~=#self.Cosmetics then state.categoryCount=#self.Cosmetics;state.categorySQL={}end
		local categorySQL=state.categorySQL[item.Category]
		if not categorySQL then
			local signatures={};for _,other in ipairs(self.Cosmetics)do if other.Category==item.Category then signatures[#signatures+1]=sql.SQLStr(other.Signature)end end
			categorySQL=table.concat(signatures,',');state.categorySQL[item.Category]=categorySQL
		end
		assert(Query('UPDATE '..tableName..' SET equipped=CASE WHEN cosmetic='..sql.SQLStr(selected>0 and item.Signature or'')..' THEN 1 ELSE 0 END WHERE steamid='..sql.SQLStr(key)..' AND cosmetic IN ('..categorySQL..')'))
		assert(Key(pl)==key and pl:Team()==team and pl:Alive())
		assert(Query('COMMIT'))
	end,debug.traceback)
	if not ok then
		if begun then sql.Query('ROLLBACK')end
		if charged and cost>0 then if team==TEAM_UNDEAD then pl:SetTokens(balance)else pl:SetPoints(balance)end end
		pl.ZSCosmeticBusy=nil
		ErrorNoHalt('[ZS] Cosmetic transaction failed: '..tostring(failure)..'\n')
		return false,LocalizedText(pl, "cosmetic_save_failed")
	end
	if action==1 then profile.owned[id]=true end
	profile.equipped[item.Category]=selected;pl.ZSCosmeticBusy=nil;Sync(pl,profile)
	local name=item.NameTranslation and translate.ClientGet(pl,item.NameTranslation)or item.Name
	return true,action==1 and LocalizedText(pl,"cosmetic_purchased_equipped",name)or(selected>0 and LocalizedText(pl,"cosmetic_equipped",name)or LocalizedText(pl,"cosmetic_unequipped"))
end
function GM:SendCosmeticData(pl,ok,message,open)
	if not Key(pl)then return end
	local profile=self:LoadPlayerCosmetics(pl);if not profile then return end
	local owned={};for _,item in ipairs(self.Cosmetics)do if profile.owned[item.ID]then owned[#owned+1]=item.ID end end
	net.Start('zs_cosmetic_state');net.WriteBool(ok);net.WriteBool(open or false);net.WriteString(message or'')
	net.WriteUInt(#owned,8);for _,id in ipairs(owned)do net.WriteUInt(id,8)end
	net.WriteUInt(profile.equipped[COSMETICCAT_HATS]or 0,8);net.WriteUInt(profile.equipped[COSMETICCAT_EFFECTS]or 0,8);net.Send(pl)
end
local function Request(pl,action,id)
	if not Key(pl)or(pl.ZSNextCosmeticRequest or 0)>CurTime()then return end
	pl.ZSNextCosmeticRequest=CurTime()+0.3
	local ok,message=GAMEMODE:CosmeticAction(pl,action,id)
	GAMEMODE:SendCosmeticData(pl,ok,message,action==0)
end
net.Receive('zs_cosmetic_action',function(_,pl)Request(pl,net.ReadUInt(2),net.ReadUInt(8))end)
concommand.Add('zs_cosmetics',function(pl)Request(pl,0,0)end)
concommand.Add('zs_cosmetic_purchase',function(pl,_,args)local item=GAMEMODE.CosmeticLookup[args[1]];if item then Request(pl,1,item.ID)end end)
concommand.Add('zs_cosmetic_equip',function(pl,_,args)local item=GAMEMODE.CosmeticLookup[args[1]];if item then Request(pl,2,item.ID)end end)
hook.Add('PlayerInitialSpawn','ZSCosmeticLoad',function(pl)GAMEMODE:LoadPlayerCosmetics(pl)end)
hook.Add('PlayerAuthed','ZSCosmeticAuth',function(pl)GAMEMODE:LoadPlayerCosmetics(pl)end)
hook.Add('PlayerSpawn','ZSCosmeticSpawn',function(pl)if Key(pl)then GAMEMODE:LoadPlayerCosmetics(pl)end end)
hook.Add('OnPlayerChangedTeam','ZSCosmeticTeam',function(pl)if Key(pl)then GAMEMODE:LoadPlayerCosmetics(pl)end end)
hook.Add('PlayerDisconnected','ZSCosmeticDisconnect',function(pl)if pl.ZSCosmeticKey then state.profiles[pl.ZSCosmeticKey]=nil end end)
cvars.AddChangeCallback('zs_cosmetics_enabled',function()for _,pl in player.Iterator()do if Key(pl)then Sync(pl,state.profiles[pl.ZSCosmeticKey])end end end,'ZSCosmeticEnabled')
for _,pl in player.Iterator()do GM:LoadPlayerCosmetics(pl)end
