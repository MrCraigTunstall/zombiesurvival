util.AddNetworkString("zs_menuaction")

function GM:SendMenuAction(pl, action)
	if not IsValid(pl) or not pl:IsPlayer() or pl:IsBot() then return false end
	if type(action) ~= "number" or action % 1 ~= 0 or action < 1 or action > 7 then return false end
	net.Start("zs_menuaction")
	net.WriteUInt(action, 3)
	net.Send(pl)
	return true
end

function GM:ShowHelp(pl, custom)
	if not IsValid(pl) or pl:IsBot() then return end
	if not custom and pl:GetInfoNum("zs_key_help", 0) ~= 0 then return end
	self:SendMenuAction(pl, 1)
end

function GM:ShowTeam(pl, custom)
	if not IsValid(pl) or pl:IsBot() then return end
	if not custom and pl:GetInfoNum("zs_key_shop", 0) ~= 0 then return end
	if self.ZombieEscape and pl:Team() == TEAM_HUMAN then
		self:SendMenuAction(pl, 2)
	elseif pl:Team() ~= TEAM_UNDEAD and not self.ZombieEscape then
		self:SendMenuAction(pl, self:GetWave() > 0 and 3 or 4)
	elseif pl:Team() == TEAM_UNDEAD then
		self:OpenMutationShop(pl)
	end
end

function GM:ShowSpare1(pl, custom)
	if not IsValid(pl) or pl:IsBot() then return end
	if not custom and pl:GetInfoNum("zs_key_class", 0) ~= 0 then return end
	if pl:Team() == TEAM_UNDEAD then
		if self:ShouldUseAlternateDynamicSpawn() then
			pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, "no_class_switch_in_this_mode"))
		else
			self:SendMenuAction(pl, 5)
		end
	elseif pl:Team() == TEAM_HUMAN then
		self:SendMenuAction(pl, 6)
	end
end

function GM:ShowSpare2(pl, custom)
	if not IsValid(pl) or pl:IsBot() then return end
	if not custom and pl:GetInfoNum("zs_key_options", 0) ~= 0 then return end
	self:SendMenuAction(pl, 7)
end
