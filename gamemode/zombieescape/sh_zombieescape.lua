if string.sub(string.lower(game.GetMap()), 1, 3) ~= "ze_" then return end

GM.ZombieEscape = true
GM.WaveZeroLength = 90
GM.EndGameTime = 35
GM.ZE_FreezeTime = 20
GM.ZE_TimeLimit = 60 * 16

function GM:SelectZombieEscapeDefaultClass()
	if not self.ZombieEscape or not self.ZombieClasses then return end
	local class = self.ZombieClasses["Super Zombie"]
	if class and type(class.Index) == "number" and self.ZombieClasses[class.Index] == class then self.DefaultZombieClass = class.Index end
end
GM:SelectZombieEscapeDefaultClass()

include("sh_mapweapons.lua")

function GM:Move(pl, move)
	if pl:Team() == TEAM_HUMAN then
		if pl:GetBarricadeGhosting() then
			move:SetMaxSpeed(36)
			move:SetMaxClientSpeed(36)
		else
			local forward = move:GetForwardSpeed()
			if forward < 0 then
				move:SetMaxSpeed(move:GetMaxSpeed() * 0.9)
				move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.9)
			elseif forward == 0 then
				move:SetMaxSpeed(move:GetMaxSpeed() * 0.95)
				move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.95)
			end
		end
	elseif pl:CallZombieFunction("Move", move) then
		return
	end

	local legdamage = pl:GetLegDamage()
	if legdamage > 0 then
		local scale = 1 - math.min(1, legdamage * 0.25)
		move:SetMaxSpeed(move:GetMaxSpeed() * scale)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * scale)
	end
end

function GM:GetZombieDamageScale(pos, ignore)
	return self.ZombieDamageMultiplier
end

function GM:ScalePlayerDamage(pl, hitgroup, dmginfo)
	if SERVER then self:ApplyTraitHeadshot(pl, hitgroup, dmginfo) end
	if hitgroup == HITGROUP_HEAD and dmginfo:IsBulletDamage() then
		pl.m_LastHeadShot = CurTime()
	end

	if not pl:CallZombieFunction("ScalePlayerDamage", hitgroup, dmginfo) then
		if hitgroup == HITGROUP_HEAD then
			dmginfo:SetDamage(dmginfo:GetDamage() * 2)
		elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_GEAR then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.25)
		elseif hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.75)
		end
	end

	if pl:Team() == TEAM_UNDEAD and self:PlayerShouldTakeDamage(pl, dmginfo:GetAttacker()) then
		pl:AddLegDamage(((hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG) and 1 or 0.125) * dmginfo:GetDamage())
	end
end

local function EscapeCollisionRule(ent1, ent2)

	local collisionGroup0 = ent1:GetCollisionGroup()
	local collisionGroup1 = ent2:GetCollisionGroup()
	if collisionGroup0 == collisionGroup1 then return end

	if collisionGroup0 > collisionGroup1 then
		local old = collisionGroup0
		collisionGroup0 = collisionGroup1
		collisionGroup1 = old
	end

	if collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT and
		collisionGroup1 == COLLISION_GROUP_WEAPON then
		return false
	end

	if (collisionGroup0 == COLLISION_GROUP_PLAYER or collisionGroup0 == COLLISION_GROUP_PLAYER_MOVEMENT) and
		collisionGroup1 == COLLISION_GROUP_PUSHAWAY then
		return false
	end

	if collisionGroup0 == COLLISION_GROUP_DEBRIS and collisionGroup1 == COLLISION_GROUP_PUSHAWAY then
		return true
	end

end

local collisionHooks = hook.GetTable().ShouldCollide
GM:BindZombieEscapeCollisionRule(not (collisionHooks and collisionHooks.CSSShouldCollide) and EscapeCollisionRule or nil)

hook.Add( "OnEntityCreated", "CSSCustomCollisions", function( ent )
	ent:SetCustomCollisionCheck(true)
end )

CVars.BossDebug = CreateConVar( "ze_boss_debug", 0, {FCVAR_REPLICATED}, "Debug mode for finding boss entities." )
