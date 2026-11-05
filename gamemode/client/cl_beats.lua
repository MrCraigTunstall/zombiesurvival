local music = CreateClientConVar("zs_playmusic", 1, true, false)
GM.ZSBeatsState = GM.ZSBeatsState or {next = 0, level = 0, durations = {}}
local state = GM.ZSBeatsState

function GM:ResetBeats()
	if state.patch then state.patch:Stop() end
	state.patch, state.owner, state.next, state.level = nil, nil, 0, 0
	self.ZSLastHumanMusic = nil
end

function GM:SetLastHumanMusic(path)
	self:ResetBeats()
	for _, candidate in ipairs(self:GetLastHumanMusicCandidates()) do
		if candidate == path then self.ZSLastHumanMusic = path; return true end
	end
	self.ZSLastHumanMusic = self:GetLastHumanMusicCandidates()[1]
	return false
end

local function Duration(gm, path)
	local duration = state.durations[path]
	if duration then return duration end
	duration = gm.SoundDuration and gm.SoundDuration[path] or SoundDuration(path)
	if type(duration) ~= "number" or duration ~= duration or duration <= 0 or duration == math.huge then return end
	state.durations[path] = duration
	return duration
end

function GM:ShouldPlayBeats(teamid, fear)
	return not self.RoundEnded and not self.ZombieEscape and not GetGlobalBool("beatsdisabled", false)
end

function GM:PlayBeats(teamid, fear)
	local allowed = IsValid(MySelf) and gamemode.Call("ShouldPlayBeats", teamid, fear)
	local lastHuman = LASTHUMAN and music:GetBool() and allowed
	if state.patch and (not lastHuman or state.owner ~= MySelf) then state.patch:Stop(); state.patch, state.owner, state.next = nil, nil, 0 end
	if not allowed then return end
	local now = RealTime()
	if now < state.next then return end
	if lastHuman then
		local path = self.ZSLastHumanMusic or self:GetLastHumanMusicCandidates()[1]
		local duration = path and Duration(self, path)
		if not duration then state.next = now + 2; return end
		if not state.patch then state.patch = CreateSound(MySelf, path); state.owner = MySelf end
		if not state.patch then state.next = now + 2; return end
		state.patch:Stop(); state.patch:PlayEx(self.BeatsVolume, 100)
		state.next = now + duration
		return
	end
	if fear <= 0 or not self.BeatsEnabled then return end
	local beats = self.Beats[teamid == TEAM_HUMAN and self.BeatSetHuman or self.BeatSetZombie]
	if not beats then return end
	state.level = math.Approach(state.level, math.ceil(fear * 10), 3)
	local path = beats[state.level]
	local duration = path and Duration(self, path)
	if not duration then state.next = now + 2; return end
	MySelf:EmitSound(path, 0, 100, self.BeatsVolume)
	state.next = now + math.max(0.05, duration - 0.025)
end

cvars.AddChangeCallback("zs_playmusic", function(_, _, value)
	if tonumber(value) ~= 1 and state.patch then state.patch:Stop(); state.patch, state.owner, state.next = nil, nil, 0 end
end, "ZSLastHumanMusic")
cvars.AddChangeCallback("zs_beatsvolume", function(_, _, value)
	if state.patch then state.patch:ChangeVolume(math.Clamp(tonumber(value) or 0, 0, 100) / 100, 0) end
end, "ZSLastHumanMusic")
hook.Add("ShutDown", "ZSLastHumanMusic", function() GAMEMODE:ResetBeats() end)
