local function Flush(field)
	local gm = GAMEMODE
	local pending = gm[field]
	gm[field] = nil
	local visited = {}
	for ent in pairs(pending or {}) do
		if IsValid(ent) then gm:EvaluatePropFreeze(ent, visited) end
	end
end

local function FlushRetry()
	timer.Remove("ZSPropFreezeRetry")
	local gm = GAMEMODE
	local pending = gm.ZSPropFreezeRetry
	if not pending then return end
	local now, visited = CurTime(), {}
	for ent, deadline in pairs(pending) do
		if not IsValid(ent) then
			pending[ent] = nil
		elseif type(deadline) ~= "number" or now >= deadline then
			pending[ent] = nil
			gm:EvaluatePropFreeze(ent, visited)
		end
	end
	local earliest
	for _, deadline in pairs(pending) do
		if type(deadline) ~= "number" then deadline = now end
		if not earliest or deadline < earliest then earliest = deadline end
	end
	if earliest then
		timer.Create("ZSPropFreezeRetry", math.max(0.001, earliest - CurTime()), 1, FlushRetry)
	else
		gm.ZSPropFreezeRetry = nil
	end
end

function GM:QueuePropFreeze(ent, recheck)
	if not IsValid(ent) or ent:IsWorld() then return end
	self.ZSPropFreezeQueue = self.ZSPropFreezeQueue or {}
	self.ZSPropFreezeQueue[ent] = true
	if not timer.Exists("ZSPropFreezeQueue") then
		timer.Create("ZSPropFreezeQueue", 0, 1, function() Flush("ZSPropFreezeQueue") end)
	end
	if recheck then
		self.ZSPropFreezeRetry = self.ZSPropFreezeRetry or {}
		self.ZSPropFreezeRetry[ent] = CurTime() + 0.2
		if not timer.Exists("ZSPropFreezeRetry") then
			timer.Create("ZSPropFreezeRetry", 0.2, 1, FlushRetry)
		end
	end
end

function GM:EvaluatePropFreeze(ent, neighbors)
	neighbors = neighbors or {}
	if not ent then
		for _, e in ipairs(ents.GetAll()) do
			if IsValid(e) then self:EvaluatePropFreeze(e, neighbors) end
		end
		return
	end
	if not IsValid(ent) or ent:IsWorld() or neighbors[ent] then return end
	local connected = constraint.GetAllConstrainedEntities(ent) or {[ent] = ent}
	connected[ent] = ent
	local anchored = false
	for prop in pairs(connected) do
		if IsValid(prop) and not prop:IsWorld() and prop:IsNailedToWorld() then anchored = true; break end
	end
	for prop in pairs(connected) do
		if IsValid(prop) and not prop:IsWorld() then
			neighbors[prop] = true
			if anchored then prop:SetNailFrozen(true) elseif prop:GetNailFrozen() then prop:SetNailFrozen(false) end
		end
	end
end


function GM:OnNailDamaged(ent, attacker, inflictor, damage, dmginfo)
end

function GM:OnNailRemoved(nail, ent1, ent2, remover)
	self:QueuePropFreeze(ent1, true)
	self:QueuePropFreeze(ent2, true)

	if remover and remover:IsValid() and remover:IsPlayer() then
		local deployer = nail:GetDeployer()
		local deployername = "[unconnected]"
		if deployer:IsValid() and deployer:Team() == TEAM_HUMAN then
			deployername = deployer:Name()

			if deployer ~= remover then
				net.Start("zs_nailremoved")
					net.WriteEntity(remover)
				net.Send(deployer)
			end
		end

		PrintTranslatedMessage(HUD_PRINTCONSOLE, "nail_removed_by", remover:Name(), deployername)
	end
end


function GM:OnNailCreated(ent1, ent2, nail)
	self:QueuePropFreeze(ent1)
	self:QueuePropFreeze(ent2)
end

function GM:PlayerShouldTakeNailRemovalPenalty(pl, nail, nailowner, prop)
	if gamemode.Call("PlayerIsAdmin", pl) then return false end

	if not gamemode.Call("CanPlaceNail", nailowner) then return false end

	local firstnail = prop:GetFirstNail()
	if firstnail and pl == firstnail:GetOwner() then
		return false
	end

	return true
end
