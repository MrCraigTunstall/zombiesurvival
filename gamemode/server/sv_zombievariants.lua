local flags=FCVAR_ARCHIVE+FCVAR_NOTIFY
GM.ZombieVariantChance=CreateConVar("zs_zombie_variant_chance","0.05",flags,"Base chance for a powered-up zombie variant.",0,1)
GM.ZombieVariantKillScaling=CreateConVar("zs_zombie_variant_kill_scaling","0.01",flags,"Additional variant chance per kill above the minimum.",0,1)
GM.ZombieVariantMaxChance=CreateConVar("zs_zombie_variant_max_chance","0.25",flags,"Maximum powered-up zombie variant chance.",0,1)
GM.ZombieVariantHealthMult=CreateConVar("zs_zombie_variant_health_mult","1.5",flags,"Powered-up variant health multiplier.",1,10)
GM.ZombieVariantSpeedMult=CreateConVar("zs_zombie_variant_speed_mult","1.2",flags,"Powered-up variant speed multiplier.",1,3)
GM.ZombieVariantDamageMult=CreateConVar("zs_zombie_variant_damage_mult","1.3",flags,"Powered-up variant attack damage multiplier.",1,10)
GM.ZombieVariantKillsRequired=CreateConVar("zs_zombie_variant_kills_required","3",flags,"Minimum kills for a powered-up zombie variant.",0,100000)
local colors={Color(255,200,100),Color(255,150,150),Color(200,150,255),Color(150,255,200),Color(255,220,150)}
local function Limited(cvar,min,max)
	local value=cvar:GetFloat()
	if value~=value then return min end
	return math.Clamp(value,min,max)
end
function GM:CanHaveZombieSpawnVariant(pl)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:Alive() or pl:Team()~=TEAM_UNDEAD or self.ZombieEscape or self.RoundEnded then return false end
	local class=pl:GetZombieClassTable()
	return class and not class.Boss and not class.SuperBoss and not class.NeverAlive
end
function GM:ShouldGetZombieVariant(pl)
	if not self:CanHaveZombieSpawnVariant(pl) or pl.ZSZombieVariant then return false end
	local base=Limited(self.ZombieVariantChance,0,1)
	local kills=pl:Frags()
	local minimum=math.max(0,self.ZombieVariantKillsRequired:GetInt())
	if base<=0 or kills<minimum then return false end
	local chance=math.min(Limited(self.ZombieVariantMaxChance,0,1),base+(kills-minimum)*Limited(self.ZombieVariantKillScaling,0,1))
	return chance>0 and math.Rand(0,1)<chance
end
function GM:ApplyZombieVariant(pl)
	if not self:CanHaveZombieSpawnVariant(pl) or pl.ZSZombieVariant then return false end
	local health=math.max(1,math.ceil(pl:Health()*Limited(self.ZombieVariantHealthMult,1,10)))
	local state={speed=Limited(self.ZombieVariantSpeedMult,1,3),damage=Limited(self.ZombieVariantDamageMult,1,10),health=health,basehealth=pl:Health(),basemax=pl:GetDTInt(0),color=pl:GetColor()}
	pl.ZSZombieVariant=state
	pl:SetNW2Int("zs_zombie_variant_health",health)
	pl:SetNW2Float("zs_zombie_variant_speed",state.speed)
	pl:SetMaxHealth(health);pl:SetHealth(health);pl:ResetSpeed()
	local color=colors[math.random(#colors)]
	pl:SetColor(Color(color.r,color.g,color.b,state.color.a))
	if not pl:IsBot() then
		pl:CenterNotify(COLOR_YELLOW,translate.ClientGet(pl,"zombie_variant_active"))
		for _,other in player.Iterator()do
			if other~=pl and not other:IsBot() and other:Team()~=TEAM_SPECTATOR then
				other:CenterNotify(COLOR_YELLOW,translate.ClientFormat(other,"zombie_variant_spawned",pl:Name()))
			end
		end
	end
	return true
end
function GM:ClearZombieSpawnVariants(pl)
	local state=pl.ZSZombieVariant
	if state then pl:SetColor(state.color);pl:SetHealth(math.min(pl:Health(),state.basehealth));pl:SetMaxHealth(state.basemax) end
	pl.ZSZombieVariant=nil
	if pl:GetNW2Int("zs_zombie_variant_health",0)~=0 then pl:SetNW2Int("zs_zombie_variant_health",0)end
	if pl:GetNW2Float("zs_zombie_variant_speed",1)~=1 then pl:SetNW2Float("zs_zombie_variant_speed",1)end
	if self.ClearZombieSkinVariant then self:ClearZombieSkinVariant(pl)end
	if state and pl:Alive() then pl:ResetSpeed()end
end
hook.Add("OnPlayerChangedTeam","ZSZombieSpawnVariants",function(pl)GAMEMODE:ClearZombieSpawnVariants(pl)end)
hook.Add("PlayerDisconnected","ZSZombieSpawnVariants",function(pl)pl.ZSZombieVariant=nil;pl.ZSZombieSkinVariant=nil end)
hook.Add("PostEndRound","ZSZombieSpawnVariants",function()
	for _,pl in player.Iterator()do GAMEMODE:ClearZombieSpawnVariants(pl)end
end)
hook.Add("EntityTakeDamage","ZSZombieVariantDamage",function(target,info)
	local attacker=info:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() or not attacker:Alive() or attacker:Team()~=TEAM_UNDEAD then return end
	local state=attacker.ZSZombieVariant
	if not state then return end
	local weapon=info:GetInflictor()
	if not IsValid(weapon) or weapon:GetOwner()~=attacker then return end
	if weapon:IsWeapon() and attacker:GetActiveWeapon()==weapon or weapon:IsProjectile() then info:ScaleDamage(state.damage)end
end)
