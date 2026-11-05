GM.LastHumanMusicLibrary = {
	"zombiesurvival/lasthuman.ogg",
	"music/hl2_song12_long.mp3",
	"music/hl2_song14.mp3",
	"music/hl2_song16.mp3"
}
if SERVER then
	GM.LastHumanMusicRandomizer = CreateConVar("zs_lasthuman_music_randomizer", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Randomize last-human music each round", 0, 1)
end
local source, count, fallback, candidates, contents

function GM:GetLastHumanMusicCandidates()
	local library = self.LastHumanMusicLibrary
	local size = type(library) == "table" and #library or 0
	local stable = source == library and count == size and fallback == self.LastHumanSound and candidates
	if stable then
		for index = 1, math.min(size, 64) do
			if contents[index] ~= library[index] then stable = false break end
		end
		if stable then return candidates end
	end
	source, count, fallback = library, size, self.LastHumanSound
	candidates, contents = {}, {}
	local seen = {}
	local function Add(path)
		if type(path) ~= "string" or #path > 128 or path:find("..", 1, true) or path:find("\\", 1, true) or seen[path] then return end
		if not path:match("%.ogg$") and not path:match("%.mp3$") and not path:match("%.wav$") then return end
		if not file.Exists("sound/" .. path, "GAME") then return end
		seen[path] = true
		candidates[#candidates + 1] = path
	end
	Add(self.LastHumanSound)
	for index = 1, math.min(size, 64) do
		contents[index] = library[index]
		Add(library[index])
	end
	return candidates
end

function GM:SelectLastHumanMusic()
	local available = self:GetLastHumanMusicCandidates()
	if #available == 0 then return "" end
	if not self.LastHumanMusicRandomizer:GetBool() then self.ZSPreviousLastHumanMusic = available[1]; return available[1] end
	local previous
	for index, path in ipairs(available) do if path == self.ZSPreviousLastHumanMusic then previous = index; break end end
	local index = math.random(#available > 1 and previous and #available - 1 or #available)
	if #available > 1 and previous and index >= previous then index = index + 1 end
	local sound = available[index]
	self.ZSPreviousLastHumanMusic = sound
	return sound
end
