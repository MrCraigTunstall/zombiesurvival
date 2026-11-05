local function Number(value)
	local number=tonumber(value)
	if number and number==number and number>-math.huge and number<math.huge then return number end
end
local function GetOutValue(ent)
	return ent.ZSMathCounter and ent.ZSMathCounter.value or 0
end
local function State(ent)
	if ent.ZSMathCounter then return ent.ZSMathCounter end
	local keys=ent:GetKeyValues()
	local state={value=Number(keys.startvalue) or 0,min=Number(keys.min) or 0,max=Number(keys.max) or 0,disabled=tobool(keys.StartDisabled or keys.startdisabled)}
	ent.ZSMathCounter=state
	ent.GetOutValue=GetOutValue
	ent.m_InitialValue=state.value
	return state
end
local function Clamp(state,value)
	if state.min==0 and state.max==0 then return value end
	return math.Clamp(value,math.min(state.min,state.max),math.max(state.min,state.max))
end
local function TrackKey(ent,key,value)
	if ent:GetClass()~="math_counter" then return end
	local state=State(ent)
	key=string.lower(key)
	if key=="startvalue" then state.value=Number(value) or 0;ent.m_InitialValue=state.value
	elseif key=="min" then state.min=Number(value) or 0
	elseif key=="max" then state.max=Number(value) or 0
	elseif key=="startdisabled" then state.disabled=tobool(value) end
end
hook.Add("EntityKeyValue","ZSMathCounter",TrackKey)
local meta=FindMetaTable("Entity")
ZSMathNativeSetKeyValue=ZSMathNativeSetKeyValue or meta.SetKeyValue
function meta:SetKeyValue(key,value)
	if self:GetClass()=="math_counter" then TrackKey(self,key,value) end
	return ZSMathNativeSetKeyValue(self,key,value)
end

hook.Add("OnEntityCreated","ZSMathCounter",function(ent)
	if ent:GetClass()=="math_counter" then State(ent) end
end)
local function Refresh()
	for _,ent in ipairs(ents.FindByClass("math_counter"))do
		local state=State(ent)
		state.value=Clamp(state,state.value)
		ent.m_InitialValue=math.max(ent.m_InitialValue or 0,state.value)
	end
end
hook.Add("InitPostEntity","ZSMathCounter",Refresh)
hook.Add("InitPostEntityMap","ZSMathCounter",Refresh)
hook.Add("AcceptInput","ZSMathCounter",function(ent,input,activator,caller,value)
	if ent:GetClass()~="math_counter" then return end
	local state=State(ent)
	input=string.lower(input)
	if input=="enable" then state.disabled=false;return end
	if input=="disable" then state.disabled=true;return end
	local number=Number(value)
	if not number then return end
	local old=state.value
	local nextvalue
	if input=="sethitmin" then state.min=number;if state.max<number then state.max=number end;nextvalue=old
	elseif input=="sethitmax" then state.max=number;if state.min>number then state.min=number end;nextvalue=old
	elseif state.disabled then return
	elseif input=="add" then nextvalue=old+number
	elseif input=="subtract" then nextvalue=old-number
	elseif input=="multiply" then nextvalue=old*number
	elseif input=="divide" then if number==0 then return end;nextvalue=old/number
	elseif input=="setvalue" or input=="setvaluenofire" then nextvalue=number
	else return end
	if not Number(nextvalue) then return end
	state.value=Clamp(state,nextvalue)
	ent.m_InitialValue=math.max(ent.m_InitialValue or 0,state.value)
	local gm=GAMEMODE
	if state.value~=old and input~="setvaluenofire" and gm and gm.ZombieEscape then
		if gm.MathCounterUpdate then gm:MathCounterUpdate(ent,activator) end
		if old>state.min and state.value<=state.min and gm.MathCounterHitMin then gm:MathCounterHitMin(ent,activator) end
	end
end)
