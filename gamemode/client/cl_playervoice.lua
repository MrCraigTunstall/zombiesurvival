if not CLIENT then return end

local meta = FindMetaTable("Player")
if not meta then return end

local function PlayVoiceSound(pl, sounds)
	if sounds and #sounds > 0 then
		local sound = sounds[math.random(#sounds)]
		if sound then pl:EmitSound(sound) end
	end
end

function meta:PlayEyePainSound()
	PlayVoiceSound(self, self:GetVoiceLines(VOICELINE_EYEPAIN))
end

function meta:PlayGiveAmmoSound()
	PlayVoiceSound(self, self:GetVoiceLines(VOICELINE_GIVEAMMO))
end

function meta:PlayDeathSound()
	PlayVoiceSound(self, self:GetVoiceLines(VOICELINE_DEATH))
end

function meta:PlayZombieDeathSound()
	if self:CallZombieFunction0("PlayDeathSound") then return end
	local class = self:GetZombieClassTable()
	PlayVoiceSound(self, class and class.DeathSounds)
end

function meta:PlayPainSound(health)
	local line = health >= 70 and VOICELINE_PAIN_LIGHT or health >= 35 and VOICELINE_PAIN_MED or VOICELINE_PAIN_HEAVY
	PlayVoiceSound(self, self:GetVoiceLines(line))
end

function meta:PlayZombiePainSound()
	if self:CallZombieFunction0("PlayPainSound") then return end
	local class = self:GetZombieClassTable()
	PlayVoiceSound(self, class and class.PainSounds)
end

local function ReceiveVoice(name, method, health)
	net.Receive(name, function()
		local ent = net.ReadEntity()
		if not IsValid(ent) or not ent:IsPlayer() then return end
		if health then ent[method](ent, net.ReadUInt(4) * 25) else ent[method](ent) end
	end)
end

ReceiveVoice("voice_eyepain", "PlayEyePainSound")
ReceiveVoice("voice_giveammo", "PlayGiveAmmoSound")
ReceiveVoice("voice_death", "PlayDeathSound")
ReceiveVoice("voice_zombiedeath", "PlayZombieDeathSound")
ReceiveVoice("voice_pain", "PlayPainSound", true)
ReceiveVoice("voice_zombiepain", "PlayZombiePainSound")
