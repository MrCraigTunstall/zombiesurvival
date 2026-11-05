GM.QuestSystem = CreateConVar("zs_quest_system", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Enable stationary survivor mini quests", 0, 1)
GM.QuestCount = CreateConVar("zs_quest_count", "3", FCVAR_ARCHIVE, "Maximum quest survivors per round", 1, 3)
GM.QuestProtectTime = CreateConVar("zs_quest_protect_time", "60", FCVAR_ARCHIVE, "Active-wave seconds to protect a survivor", 10, 180)
GM.ZSActiveQuests = GM.ZSActiveQuests or {}
local active = GM.ZSActiveQuests
local rewards = {"weapon_zs_dualboomstick", "weapon_zs_infinochet", "weapon_zs_empoweredshovel"}
local cachedRewards, rewardAvailability
util.AddNetworkString("zs_quest_open")
util.AddNetworkString("zs_quest_action")
util.AddNetworkString("zs_quest_result")

local function Notice(pl, message, success)
	if IsValid(pl) and not pl:IsBot() then pl:CenterNotify(success and COLOR_GREEN or COLOR_RED, message) end
end

local function Stop(ent)
	active[ent] = nil
	local pl = ent:GetQuestPlayer()
	if IsValid(pl) and pl.ZSActiveQuest == ent then pl.ZSActiveQuest = nil end
	local supply = ent:GetQuestSupply()
	if IsValid(supply) then supply:Remove() end
	ent:SetQuestSupply(NULL)
	ent.QuestMedicine = nil
	if next(active) == nil then timer.Remove("ZSQuestProgress") end
end

function GM:FailQuest(ent, message)
	if not IsValid(ent) or ent:GetQuestState() ~= 1 then return end
	Notice(ent:GetQuestPlayer(), message or "Quest failed. Return to the survivor to try again.", false)
	Stop(ent)
	ent:SetQuestState(3)
	ent:SetQuestPlayer(NULL)
end

function GM:RemoveQuestNPCs()
	for _, ent in ipairs(self:GetZSClassEntities("npc_zs_quest")) do if IsValid(ent) then ent:Remove() end end
	timer.Remove("ZSQuestProgress")
end

function GM:GetQuestRewards()
	local changed = not cachedRewards
	local available = rewardAvailability or {}
	for i, class in ipairs(rewards) do
		local present = weapons.GetStored(class) ~= nil
		if available[i] ~= present then changed = true; available[i] = present end
	end
	if not changed then return cachedRewards end
	rewardAvailability = available
	cachedRewards = {}
	for i, class in ipairs(rewards) do if available[i] then cachedRewards[#cachedRewards + 1] = class end end
	return cachedRewards
end

function GM:SpawnQuestNPCs()
	if not self.QuestSystem:GetBool() or self.ZombieEscape or self.ObjectiveMap or self.RoundEnded then return end
	if #self:GetZSClassEntities("npc_zs_quest") > 0 then return end
	local catalog = self:GetQuestRewards()
	for kind = 1, math.Clamp(self.QuestCount:GetInt(), 1, 3) do
		local pos = self:FindTraderPosition()
		if pos then
			local ent = ents.Create("npc_zs_quest")
			if IsValid(ent) then
				ent:SetPos(pos); ent:SetAngles(Angle(0, math.random(0, 359), 0)); ent:Spawn()
				ent:SetQuestKind(kind)
				ent:SetQuestDuration(math.Clamp(self.QuestProtectTime:GetInt(), 10, 180))
				ent:SetQuestReward(#catalog > 0 and catalog[math.random(#catalog)] or "")
			end
		end
	end
end

function GM:CompleteQuest(ent)
	if not IsValid(ent) or ent:GetQuestState() ~= 1 or ent.QuestRewardBusy then return false end
	local kind, progress = ent:GetQuestKind(), ent:GetQuestProgress()
	if kind ~= 1 and CurTime() >= ent:GetQuestDeadline() then self:FailQuest(ent, "Quest timed out."); return false end
	if kind == 1 and progress < ent:GetQuestDuration() or kind == 2 and not ent.QuestMedicine
		or kind == 3 and progress < #self.QuestDefinitions[3].weapons or not self.QuestDefinitions[kind]
		or CurTime() < (ent.QuestNextReward or 0) then return false end
	local pl = ent:GetQuestPlayer()
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or self.RoundEnded then return false end
	ent.QuestRewardBusy = true
	local class = ent:GetQuestReward()
	local points = class == "" or not weapons.GetStored(class) or self:IsClassicMode() or self:IsBabyMode() or self.PantsMode or pl:HasWeapon(class)
	local balance = pl:GetPoints()
	if points and (type(balance) ~= "number" or balance ~= balance or math.abs(balance) == math.huge) then ent.QuestRewardBusy = nil; return false end
	local ok, granted = pcall(function()
		if points then
			pl:SetPoints(balance + 60)
			return true
		end
		return IsValid(pl:Give(class))
	end)
	if not ok or not granted then
		if points then granted = pl:GetPoints() == balance + 60 else
			local weapon = pl:GetWeapon(class)
			granted = IsValid(weapon) and weapon:GetOwner() == pl
		end
		if granted then ok = true end
	end
	ent.QuestRewardBusy = nil
	if not ok or not granted then
		ent.QuestNextReward = CurTime() + 2
		if not ok then ErrorNoHalt("ZS quest reward: " .. tostring(granted) .. "\n") end
		return false
	end
	ent:SetQuestState(2)
	Stop(ent)
	Notice(pl, "Quest complete! Reward: " .. (points and "60 points" or self:GetQuestWeaponName(class)), true)
	return true
end

function GM:CheckQuestProgress(now)
	for ent in pairs(active) do
		if not IsValid(ent) then active[ent] = nil else
			local pl = ent:GetQuestPlayer()
			if not self.QuestSystem:GetBool() or self.RoundEnded or not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN then
				self:FailQuest(ent)
			elseif ent:GetQuestKind() == 1 then
				if pl:GetPos():DistToSqr(ent:GetPos()) > 200^2 or ent:Health() <= 0 then self:FailQuest(ent) else
					local elapsed = now - (ent.QuestLastTick or now)
					ent.QuestLastTick = now
					if self:GetWaveActive() then ent.QuestElapsed = math.min(ent:GetQuestDuration(), (ent.QuestElapsed or 0) + elapsed) end
					local progress = math.floor(ent.QuestElapsed or 0)
					if progress ~= ent:GetQuestProgress() then ent:SetQuestProgress(progress) end
					if progress >= ent:GetQuestDuration() and now >= (ent.QuestNextReward or 0) then self:CompleteQuest(ent) end
				end
			elseif now >= ent:GetQuestDeadline() then self:FailQuest(ent, "Quest timed out. Return to the survivor to try again.")
			elseif ent:GetQuestKind() == 2 and not ent.QuestMedicine and not IsValid(ent:GetQuestSupply()) then self:FailQuest(ent, "The medicine was lost. Return to the survivor to try again.") end
		end
	end
	if next(active) == nil then timer.Remove("ZSQuestProgress") end
end

function GM:StartQuest(pl, ent)
	if not self.QuestSystem:GetBool() or not self:CanReachQuest(pl, ent) or ent:GetClass() ~= "npc_zs_quest"
		or ent:GetQuestState() == 1 or ent:GetQuestState() == 2 or IsValid(pl.ZSActiveQuest) then return false, "This quest is unavailable." end
	local kind = ent:GetQuestKind()
	if not self.QuestDefinitions[kind] then return false, "This quest is unavailable." end
	if kind == 1 and not self:GetWaveActive() then return false, "Protection quests start during an active wave." end
	if kind == 2 then
		local pos = self:FindTraderPosition()
		if not pos then return false, "There is no safe medicine location. Try again later." end
		local supply = ents.Create("prop_zs_questmedicine")
		if not IsValid(supply) then return false, "Medicine could not be placed. Try again later." end
		supply:SetPos(pos); supply:Spawn(); supply:SetQuestNPC(ent); ent:SetQuestSupply(supply); ent:SetQuestLocation(pos)
	end
	ent:SetHealth(ent:GetMaxHealth())
	ent.QuestNextDelivery = nil
	ent:SetQuestPlayer(pl); ent:SetQuestState(1); ent:SetQuestProgress(0); ent:SetQuestDeadline(CurTime() + 180)
	ent.QuestElapsed, ent.QuestLastTick, ent.QuestNextReward = 0, CurTime(), nil
	pl.ZSActiveQuest = ent; active[ent] = true
	if not timer.Exists("ZSQuestProgress") then timer.Create("ZSQuestProgress", 0.25, 0, function() GAMEMODE:CheckQuestProgress(CurTime()) end) end
	Notice(pl, "Quest accepted: " .. self.QuestDefinitions[kind].title, true)
	return true, "Quest accepted."
end

function GM:CollectQuestMedicine(pl, supply)
	if not self.QuestSystem:GetBool() or not self:CanReachQuest(pl, supply, 100) or supply:GetClass() ~= "prop_zs_questmedicine" then return false end
	local ent = supply:GetQuestNPC()
	if not IsValid(ent) or ent:GetQuestState() ~= 1 or ent:GetQuestPlayer() ~= pl or ent:GetQuestSupply() ~= supply then return false end
	if CurTime() >= ent:GetQuestDeadline() then self:FailQuest(ent, "Quest timed out."); return false end
	ent.QuestMedicine = true; ent:SetQuestProgress(1); ent:SetQuestSupply(NULL); supply:Remove()
	Notice(pl, "Medicine collected. Return to the survivor and press USE.", true)
	return true
end

function GM:DeliverQuest(pl, ent)
	if not self.QuestSystem:GetBool() or not self:CanReachQuest(pl, ent) or ent:GetClass() ~= "npc_zs_quest"
		or ent:GetQuestState() ~= 1 or ent:GetQuestPlayer() ~= pl or ent.QuestRewardBusy then return false, "This quest is unavailable." end
	local now = CurTime()
	if ent:GetQuestKind() ~= 1 and now >= ent:GetQuestDeadline() then self:FailQuest(ent, "Quest timed out."); return false, "Quest timed out. Accept it again to retry." end
	if now < (ent.QuestNextDelivery or 0) then return false, "Please wait before delivering again." end
	ent.QuestNextDelivery = now + 0.5
	if ent:GetQuestKind() == 2 then
		if not ent.QuestMedicine then return false, "Find and collect the marked medicine first." end
	elseif ent:GetQuestKind() == 3 then
		local list = self.QuestDefinitions[3].weapons
		local progress = ent:GetQuestProgress()
		local class = list[progress + 1]
		if class then
			local weapon = pl:GetWeapon(class)
			if not IsValid(weapon) or weapon:GetOwner() ~= pl then return false, "Bring " .. self:GetQuestWeaponName(class) .. "." end
			pl:StripWeapon(class)
			if pl:HasWeapon(class) then return false, "The weapon could not be donated." end
			ent:SetQuestProgress(progress + 1)
			if progress + 1 < #list then return true, "Weapon donated. Next: " .. self:GetQuestWeaponName(list[progress + 2]) .. "." end
		end
	else return false, "Stay close and protect the survivor during the wave." end
	local completed = self:CompleteQuest(ent)
	return completed, completed and "Quest complete!" or "Reward unavailable. Press USE again to retry."
end

function GM:OpenQuest(pl, ent)
	if not IsValid(pl) or pl:IsBot() or not self.QuestSystem:GetBool() or not self:CanReachQuest(pl, ent) then return false end
	local now = CurTime()
	if now < (pl.ZSNextQuestOpen or 0) then return false end
	pl.ZSNextQuestOpen = now + 0.5
	net.Start("zs_quest_open"); net.WriteEntity(ent); net.Send(pl)
	return true
end

net.Receive("zs_quest_action", function(len, pl)
	if len > 32 or not IsValid(pl) or pl:IsBot() then return end
	local now = CurTime()
	if now < (pl.ZSNextQuestAction or 0) then return end
	pl.ZSNextQuestAction = now + 0.5
	local ent = net.ReadEntity()
	if not IsValid(ent) or ent:GetClass() ~= "npc_zs_quest" then return end
	local ok, message
	if ent:GetQuestState() == 1 then ok, message = GAMEMODE:DeliverQuest(pl, ent) else ok, message = GAMEMODE:StartQuest(pl, ent) end
	net.Start("zs_quest_result"); net.WriteEntity(ent); net.WriteBool(ok); net.WriteString(message); net.Send(pl)
end)

hook.Add("EntityRemoved", "ZSQuests", function(ent)
	if ent:GetClass() == "npc_zs_quest" then Stop(ent) end
end)
hook.Add("PlayerDisconnected", "ZSQuests", function(pl) if IsValid(pl.ZSActiveQuest) then GAMEMODE:FailQuest(pl.ZSActiveQuest) end end)
local function Schedule()
	timer.Create("ZSQuestSpawn", 0.2, 1, function() GAMEMODE:SpawnQuestNPCs() end)
end
hook.Add("InitPostEntity", "ZSQuests", Schedule)
hook.Add("PostCleanupMap", "ZSQuests", Schedule)
hook.Add("PostEndRound", "ZSQuests", function() timer.Remove("ZSQuestSpawn"); GAMEMODE:RemoveQuestNPCs() end)
cvars.AddChangeCallback("zs_quest_system", function()
	if GAMEMODE.QuestSystem:GetBool() then Schedule() else timer.Remove("ZSQuestSpawn"); GAMEMODE:RemoveQuestNPCs() end
end, "ZSQuests")
