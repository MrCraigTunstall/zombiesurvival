if not string.find(string.lower(game.GetMap()), "mako_reactor_v5", 1, true) then return end
local sky=GetConVar("r_3dsky")
local correction=GetConVar("mat_colorcorrection")
local function EnableSky()
	if sky and sky:GetInt()==0 then RunConsoleCommand("r_3dsky","1") end
end
EnableSky()
hook.Add("InitPostEntity","MakoSky",EnableSky)
cvars.AddChangeCallback("r_3dsky",function(_,old,value)if tonumber(value)==0 then EnableSky()end end,"MakoSky")
local extreme = {
	["$pp_colour_addr"]=0.1,["$pp_colour_addg"]=0,["$pp_colour_addb"]=0,
	["$pp_colour_brightness"]=-0.15,["$pp_colour_contrast"]=1.3,["$pp_colour_colour"]=1,
	["$pp_colour_mulr"]=0,["$pp_colour_mulg"]=0,["$pp_colour_mulb"]=0
}
GM.MapColorModOverride=true
hook.Add("RenderScreenspaceEffects","MakoExtremeII",function()
	if correction and correction:GetBool() then DrawColorModify(extreme) end
end)
