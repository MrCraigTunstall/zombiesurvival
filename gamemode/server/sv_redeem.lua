util.AddNetworkString("zs_redeemmenu")

function GM:SendRedeemMenu(pl)
 if not IsValid(pl) or pl:IsBot() then return end
 net.Start("zs_redeemmenu")
 net.Send(pl)
end

local function GiveRedeemEquipment(pl, escape)
	pl:Give("weapon_zs_fists")
	if not escape then
		pl:Give("weapon_zs_redeemers")
		pl:Give("weapon_zs_hammer")
		pl:Give("weapon_zs_arsenalcrate")
	end
end

function GM:PlayerRedeemed(pl, silent, noequip)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	if not silent then
		net.Start("zs_playerredeemed")
		net.WriteEntity(pl)
		net.WriteString(pl:Name())
		net.Broadcast()
	end

	local human = GAMEMODE.ObjectiveMap or GAMEMODE.ZombieEscape or not GAMEMODE.BanditMode or pl:GetInfo("zs_nobandit") ~= "0"
	pl:RemoveStatus("overridemodel", false, true)
	pl:ChangeTeam(human and TEAM_HUMAN or TEAM_REDEEMER)
	pl:SetPoints(human and 0 or 150)
	pl:DoHulls()
	if not noequip then pl.m_PreRedeem = true end
	pl:UnSpectateAndSpawn()
	if not human then
		GiveRedeemEquipment(pl, false)
		pl:SetModel("models/player/skeleton.mdl")
	end
	timer.Simple(0.5, function()
		if IsValid(pl) then pl:EmitSound("zombiesurvival/redeem.mp3", 100, 100, 1) end
	end)
	pl.m_PreRedeem = nil

	local frags = pl:Frags()
	pl:SetFrags(frags < 0 and frags * 5 or 0)
	pl:SetDeaths(0)
	pl.DeathClass = nil
	pl:SetZombieClass(self.DefaultZombieClass)
	if human then
		GiveRedeemEquipment(pl, GAMEMODE.ZombieEscape)
	else
		pl.SpawnedTime = CurTime()
		self:SendRedeemMenu(pl)
	end
end

function GM:PlayerRespawn(pl, silent, noequip)
	if not IsValid(pl) or not pl:IsPlayer() then return end

	pl:RemoveStatus("overridemodel", false, true)
	pl:ChangeTeam(TEAM_HUMAN)
	pl:DoHulls()
	pl:UnSpectateAndSpawn()
	pl:Give("weapon_zs_peashooter")
	pl:Give("weapon_zs_swissarmyknife")

	local frags = pl:Frags()
	if frags < 0 then
		pl:SetFrags(frags * 5)
	else
		pl:SetFrags(0)
	end
	pl:SetDeaths(0)
	pl.DeathClass = nil
	pl:SetZombieClass(self.DefaultZombieClass)
    pl:SetPoints(0)
	pl.SpawnedTime = CurTime()
	end

hook.Add("PostPlayerDeath", "PostPlayerDeath.Redeemer", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply:Team() == TEAM_REDEEMER or ply:Team() == TEAM_HUMAN then
        ply:ChangeTeam(TEAM_UNDEAD)
        ply:SetFrags(0)
        ply:SetDeaths(0)
        GAMEMODE.StartingZombie[ply:UniqueID()] = true
        GAMEMODE.PreviouslyDied[ply:UniqueID()] = CurTime()
	ply:SetZombieClass(GAMEMODE.DefaultZombieClass)
    end
end)

concommand.Add("zs_bandit", function(sender, command, arguments)
    if not IsValid(sender) or not sender:IsPlayer() then return end
    if sender:Team() ~= TEAM_REDEEMER then return end    
    sender:ChangeTeam(TEAM_HUMAN)    
end)


--[[
////////// Zombie Escape (Unused Code) //////////
]]--
	
	--[[elseif GAMEMODE.ZombieEscape then
	pl:RemoveStatus("overridemodel", false, true)
	pl:ChangeTeam(TEAM_HUMAN)
	pl:SetPoints(0)
	pl:DoHulls()
	if not noequip then pl.m_PreRedeem = true end
	pl:UnSpectateAndSpawn()
	pl:Give("weapon_zs_fists")
	timer.Simple( 0.5, function() pl:EmitSound("zombiesurvival/redeem.mp3", 100, 100, 1) end )
    pl.m_PreRedeem = nil

	local frags = pl:Frags()
	if frags < 0 then
		pl:SetFrags(frags * 5)
	else
		pl:SetFrags(0)
	end
	pl:SetDeaths(0)
	pl.DeathClass = nil
	pl:SetZombieClass(self.DefaultZombieClass)
	pl.SpawnedTime = CurTime()]]--
