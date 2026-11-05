local logic_sequence = {
	{t="canciones_extreme2_1", i="PickRandom"},
	{t="canciones_extreme2_2", i="PickRandom"},
	{t="cancion_1_extra", i="Kill"},
	{t="cancion_1_extra2", i="Kill"},
	{t="cancion_3", i="AddOutput", p="message #mako_reactor/ffvii_e2_selfvsself.mp3"},
	{t="cancion_3_extra", i="AddOutput", p="message #mako_reactor/ffvii_tempest.mp3"},
	{t="ss_only", i="AddOutput", p="message ze_random_labyrinth/vulcan.mp3"},
	{t="cowbell", i="ForceSpawn", d=5.0},
	{t="AvisoExt2", i="Toggle"},
	{t="especial", i="Kill"},
	{t="cloud", i="Kill"},
	{t="dificil_props", i="Kill"},
	{t="trigger_n_d", i="Kill"},
	{t="trigger_n_m", i="Kill"},
	{t="trigger_n_e", i="Kill"},
	{t="trigger_n_d3", i="Kill"},
	{t="path_1", i="Kill"},
	{t="calcVidaM", i="Kill"},
	{t="sephiroth_fx", i="Kill"},
	{t="puerta_asc1", i="Kill"},
	{t="puerta_dasc1", i="Kill"},
	{t="azul", i="Disable"},
	{t="extreme2", i="Enable"},
	{t="trigger_extreme", i="Enable"},
	{t="trigger_extreme2_ex", i="Enable"},
	{t="baha_tr", i="Enable"},
	{t="bahamut_entry", i="Enable"},
	{t="dificil_trigger", i="Enable"},
	{t="extreme_props", i="EnableCollision"},
	{t="extreme_props", i="Enable"},
	{t="extremedanyo", i="Enable"},
	{t="extremedanyo", i="Trigger", d=2.0},
	{t="huida2_d", i="Enable"},
	{t="huida_e", i="Enable"},
	{t="medio_breakable", i="Break"},
	{t="rojo2", i="Enable"},
	{t="tele_Ex", i="Enable"},
	{t="nubes_secundarias", i="TurnOn"},
	{t="zm_prop3", i="Toggle", d=3.0},
	{t="puerta_admin", i="Enable"},
	{t="extreme2_trigger2", i="Enable", d=1.0},
	{t="extreme2_trigger3", i="Enable", d=1.0},
	{t="extreme2_trigger5", i="Enable", d=1.0},
	{t="extreme2_trigger6", i="Enable", d=1.0},
	{t="extreme2_trigger7", i="Enable", d=1.0},
	{t="extreme2_trigger8", i="Enable", d=1.0},
	{t="extreme2_trigger9", i="Enable"},
	{t="extreme2_trigger9", i="Enable", d=1.0},
	{t="extreme2_trigger10", i="Enable", d=1.0},
	{t="extreme2_trigger11", i="Enable", d=1.0},
	{t="extreme2_trigger12", i="Enable", d=1.0},
	{t="extreme2_trigger13", i="Enable"},
	{t="extreme2_triggers", i="Enable", d=1.0},
	{t="extreme_2_particula3", i="Enable", d=5.0},
	{t="extreme2_particula1", i="Start", d=5.0},
	{t="materias_3", i="Trigger", d=11.0},
	{t="teleportarS1", i="Teleport", d=5.0},
	{t="teleportarS2", i="Teleport", d=5.0},
	{t="teleportarSx1", i="Teleport", d=5.0},
	{t="teleportarSx2", i="Teleport", d=5.0},
	{t="teleportarSx12", i="Teleport", d=10.0}
}

if not string.find(string.lower(game.GetMap()), "mako_reactor_v5", 1, true) then return end
local function SeedNavigation()
	if not D3bot then return end
	local written=false
	for _,suffix in ipairs({".txt",".params.txt"})do
		local destination="d3bot/navmesh/map/"..game.GetMap()..suffix
		if not file.Exists(destination,"DATA") then
			local source="gamemodes/"..GM.FolderName.."/gamemode/misc/navmeshes/ze_ffvii_mako_reactor_v5_3"..suffix
			local data=file.Read(source,"GAME")
			if not data then data=file.Read("data_static/zombiesurvival/navmeshes/ze_ffvii_mako_reactor_v5_3"..suffix,"GAME") end
			if data and data~="" then file.CreateDir("d3bot/navmesh/map");file.Write(destination,data);written=true end
		end
	end
	if written and D3bot.LoadMapNavMesh then
		D3bot.LoadMapNavMesh()
		if not D3bot.IsEnabledCached and D3bot.IsEnabled then
			D3bot.IsEnabledCached=D3bot.IsEnabled()
			if D3bot.DesiredNavmeshType then D3bot.DesiredNavmeshTypeCached=D3bot.DesiredNavmeshType() end
		end
	end
end
SeedNavigation()
local names = {}
local ran, generation = false, 0
local completionTriggers = {trigger_n_m=true,trigger_n_d=true,trigger_n_e=true,trigger_n_e2=true}
local blocked = {dificultad_i_t_medio=true, dificultad_i_t_zm=true, dificultad_i_t_dificil=true, dificultad_i_t_extremo=true}
local function Named(name, callback)
	for _, ent in ipairs(names[string.lower(name)] or {}) do if IsValid(ent) then callback(ent) end end
end
local function Index(ent, name)
	name = string.lower(name or ent:GetName() or "")
	if name == "" then return end
	local list = names[name]
	if not list then list = {}; names[name] = list end
	if not table.HasValue(list,ent) then list[#list+1] = ent end
end
local function RegisterBoss()
	if not GAMEMODE.ZombieEscape or not GAMEMODE.AddBoss then return end
	local model, counter
	for _, name in ipairs({"bahamut", "bahamut_model", "bahamut_entry", "bahamut_2", "bahamut_3"}) do
		Named(name,function(ent) if not model and string.sub(ent:GetClass(),1,5)=="prop_" then model=ent end end)
		if model then break end
	end
	for _, name in ipairs({"bahamut_vida", "calcVidaM", "bahamut_health", "bahamut_counter", "boss_health", "boss_counter"}) do
		Named(name,function(ent) if not counter and (ent:GetClass()=="math_counter" or ent:GetClass()=="func_physbox_multiplayer") then counter=ent end end)
		if counter then break end
	end
	if not counter then
		for name,list in pairs(names) do
			if name:find("bahamut",1,true) or name:find("boss",1,true) or name:find("vida",1,true) or name:find("health",1,true) then
				for _,ent in ipairs(list) do
					if IsValid(ent) and (ent:GetClass()=="math_counter" or ent:GetClass()=="func_physbox_multiplayer") then counter=ent;break end
				end
			end
			if counter then break end
		end
	end
	if model and counter and not GAMEMODE:GetBoss(counter) then GAMEMODE:AddBoss("BAHAMUT",model:GetName(),counter:GetName()) end
end
local function Initialize()
	if ran and (not GAMEMODE.RegisterZombieEscapeWinTrigger or IsValid(GAMEMODE.ZSEscapeWinRelay) and not GAMEMODE.ZSEscapeWinRelay:IsMarkedForDeletion()) then return end
	ran=true
	generation=generation+1
	names={}
	for _,ent in ipairs(ents.GetAll()) do Index(ent) end
	GAMEMODE.MKStage=4
	if GAMEMODE.ZombieSpeedMultiplier then GAMEMODE.ZombieSpeedMultiplier=1.5 end
	if GAMEMODE.ZombieDamageMultiplier then GAMEMODE.ZombieDamageMultiplier=0.5 end
	for name in pairs(blocked) do Named(name,function(ent) ent:Fire("Disable"); ent:Remove() end) end
	for _, action in ipairs(logic_sequence) do Named(action.t,function(ent) ent:Fire(action.i,action.p or "",action.d or 0) end) end
	Named("azul",function(ent) ent:Fire("Disable");ent:Fire("Kill") end)
	Named("rojo",function(ent)ent:Fire("Disable")end)
	Named("rojo2",function(ent)ent:Fire("Enable")end)
	Named("dificultad_inicio_extremo2",function(ent)ent:Fire("Enable")end)
	for _,name in ipairs({"dificultad_inicio_zm","dificultad_inicio_dificil","dificultad_inicio_medio"})do Named(name,function(ent)ent:Fire("Disable")end)end
	Named("consola",function(ent)ent:Fire("Command","say **CURRENT DIFFICULTY ** >> EXTREME II << **",10)end)
	Named("AvisoExt2",function(ent)ent:Fire("Display");ent:Fire("Trigger")end)
	Named("botones_dificultad_2",function(ent)ent:Fire("Trigger");ent:Fire("Enable")end)
	if GAMEMODE.RegisterZombieEscapeWinTrigger then
		for _,name in ipairs({"trigger_n_m","trigger_n_d","trigger_n_e","trigger_n_e2"})do
			Named(name,function(ent)
				GAMEMODE:RegisterZombieEscapeWinTrigger(ent)
			end)
		end
	end
	local epoch=generation
	timer.Simple(1,function()if epoch==generation then RegisterBoss()end end)
end
hook.Add("EntityKeyValue","MakoExtremeII",function(ent,key,value)
	key=string.lower(key)
	local name=string.lower(ent:GetName() or "")
	if key=="targetname" then
		Index(ent,value)
		if completionTriggers[string.lower(value)] then ent:SetKeyValue("filtername","humanos") end
	end
	if key=="startdisabled" then
		if blocked[name] or name=="azul" or name=="rojo" then return "1" end
		if name=="rojo2" then return "0" end
	end
end)
hook.Add("AcceptInput","MakoExtremeII",function(ent,input)
	local name=string.lower(ent:GetName() or "")
	input=string.lower(input)
	if (blocked[name] or name=="azul" or name=="rojo") and (input=="enable" or input=="turnon") then return true end
	if (name=="rojo2" or name=="extreme2" or name=="trigger_extreme") and (input=="disable" or input=="turnoff") then return true end
end)
hook.Add("InitPostEntity","MakoExtremeII",Initialize)
hook.Add("InitPostEntityMap","MakoExtremeII",Initialize)
hook.Add("PostCleanupMap","MakoExtremeII",function()ran=false;Initialize()end)
