local finish, start, strength = 0, 0, 0
net.Receive("zs_return_effect", function()
	local amount, length = net.ReadUInt(2), net.ReadFloat()
	if amount < 1 or length ~= length or length <= 0 or length > 6 then return end
	start = CurTime(); strength, finish = amount / 3, start + length
end)
local function Power()
	local now = CurTime()
	if now >= finish or not GAMEMODE.PostProcessingEnabled then return 0 end
	local pl = LocalPlayer()
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN then finish = 0; return 0 end
	return strength * math.max(0, math.min(1, now - start, finish - now))
end
hook.Add("RenderScreenspaceEffects", "ZSReturns", function()
	local power = Power()
	if power <= 0 then return end
	local time = CurTime() * 1.5
	DrawSharpen(power * 0.4, math.sin(time) * 128)
	DrawSharpen(power * 0.4, math.cos(time) * 128)
	DrawMotionBlur(0.1 * power, 4 * power, 0.05)
end)
hook.Add("CalcView", "ZSReturns", function(_, _, ang)
	local power = Power()
	if power > 0 then ang.roll = ang.roll + math.sin(CurTime() * 0.5) * 50 * power end
end)
hook.Add("PostCleanupMap", "ZSReturns", function() finish = 0 end)
