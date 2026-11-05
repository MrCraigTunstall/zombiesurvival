function GM:OnSigilDestroyed(ent, dmginfo)
	local numsigils = self:NumSigils()
	if numsigils > 0 then
		for _, pl in player.Iterator() do
			if not pl:IsBot() then
				pl:CenterNotify({killicon = "default"}, " ", COLOR_RED, translate.ClientGet(pl, "sigil_destroyed"), {killicon = "default"})
				if numsigils == 1 then
					pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, pl:Team() == TEAM_HUMAN and "sigil_destroyed_only_one_remain_h" or "sigil_destroyed_only_one_remain_z"))
				else
					local recipients = RecipientFilter()
					recipients:AddPlayer(pl)
					pl:EmitSound("zombiesurvival/sigilbreak.mp3", 100, 100, 1, CHAN_AUTO, 0, 1, recipients)
					pl:CenterNotify(COLOR_RED, translate.ClientFormat(pl, "sigil_destroyed_x_remain", numsigils))
				end
			end
		end
	else
		for _, pl in player.Iterator() do
			if not pl:IsBot() then
				pl:CenterNotify({killicon = "default"}, " ", COLOR_RED, translate.ClientGet(pl, "last_sigil_destroyed_all_is_lost"), {killicon = "default"})
				pl:CenterNotify(COLOR_RED, translate.ClientGet(pl, "last_sigil_destroyed_all_is_lost2"))
			end
		end

		self.LastHumanPosition = ent:LocalToWorld(ent:OBBCenter())
		local pending = self.ZSSigilLossPending
		if not pending or pending.round ~= self.CurrentRound then
			pending = {round = self.CurrentRound}
			self.ZSSigilLossPending = pending
			timer.Simple(4, function()
				if self.ZSSigilLossPending ~= pending then return end
				self.ZSSigilLossPending = nil
				if GAMEMODE == self and self.CurrentRound == pending.round and not self.RoundEnded and self:NumSigils() == 0 then gamemode.Call("EndRound", TEAM_UNDEAD) end
			end)
		end
	end
end

--Put this in sv_utils!
local function SortDistFromLast(a, b)
	return a.d < b.d
end
function GM:CreateSigils()
	if #self.ProfilerNodes < self.MaxSigils
	or self.SelectedVariant and self.SelectedVariant ~= "sigil"
	or self.ZombieEscape or self.ObjectiveMap
	or self:IsClassicMode() or self.PantsMode or self:IsBabyMode() then
		self:SetUseSigils(false)
		return
	end

	--TODO: Move this variable to sv_sigilpropspawner!
	local propCount = #ents.FindByClass("prop_physics*")

	-- Copy
	local nodes = {}
	for _, node in pairs(self.ProfilerNodes) do
		local vec = Vector()
		vec:Set(node)
		nodes[#nodes + 1] = {v = vec}
	end

	local NextSigilLetter = "A"
	local traceStart, traceEnd = Vector(), Vector()
	local trace = {start = traceStart, endpos = traceEnd, mask = MASK_SOLID_BRUSHONLY, output = {}}

	local spawns = team.GetSpawnPoint(TEAM_UNDEAD)
	for i=1, self.MaxSigils do
		local id
		local sigs = self:GetZSClassEntities("prop_obj_sigil")
		local positions = {}
		for _, spawn in pairs(spawns) do
			if IsValid(spawn) and not spawn:IsMarkedForDeletion() then positions[#positions + 1] = spawn:GetPos() end
		end
		for _, sig in pairs(sigs) do
			if IsValid(sig) and not sig:IsMarkedForDeletion() then positions[#positions + 1] = sig.NodePos or sig:GetPos() end
		end

		for _, n in pairs(nodes) do
			n.d = 999999

			for _, position in ipairs(positions) do
				n.d = math.min(n.d, n.v:Distance(position))
			end

			traceStart:Set(n.v); traceStart.z = traceStart.z + 8
			traceEnd:Set(n.v); traceEnd.z = traceEnd.z + 512
			local tr = util.TraceLine(trace)
			n.d = n.d * (2 - tr.Fraction)
		end

		-- Sort the nodes by their distances.
		table.sort(nodes, SortDistFromLast)

		-- Now select a node using an exponential weight.
		-- We use a random float between 0 and 1 then sqrt it.
		-- This way we're much more likely to get a lower index but a higher index is still possible.
		id = math.Rand(0, 0.7) ^ 0.3
		id = math.Clamp(math.ceil(id * #nodes), 1, #nodes)

		-- Remove the chosen point from the temp table and make the sigil.
		local point = nodes[id].v
		table.remove(nodes, id)

		local ent = ents.Create("prop_obj_sigil")
		if ent:IsValid() then
			ent:SetPos(point)
			ent:Spawn()
			ent:SetSigilLetter(NextSigilLetter)
			NextSigilLetter = util.IncreaseLetter(NextSigilLetter)
			ent.NodePos = point
			--TODO: Move this to sv_sigilpropspawner!
			if propCount < 10 or GAMEMODE.SpawnSigilProps == true then
				if GAMEMODE.SpawnSigilProps ~= false then
					gamemode.Call("SpawnRandomSigilProps", point)
					gamemode.Call("SetupProps")
				end
			end
		end
	end

	self:SetUseSigils(#self:GetZSClassEntities("prop_obj_sigil") > 0)
end

function GM:SetUseSigils(use)
	use = tobool(use)
	self.UseSigils = use
	if GetGlobalBool("sigils", false) ~= use then SetGlobalBool("sigils", use) end
end

function GM:GetUseSigils(use)
	return GetGlobalBool("sigils", false)
end

concommand.Add("zs_sigilplacer", function(sender)
		if sender:IsValid() and sender:IsSuperAdmin() then
			sender:Give("weapon_zs_sigilplacer")
		end
end)
