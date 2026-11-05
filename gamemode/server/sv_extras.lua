util.AddNetworkString("SMAddSpray")
util.AddNetworkString("SMClearDecals")
util.AddNetworkString("SMSpray")

local noDelay = CreateConVar("spraymon_nodelay", 1, FCVAR_SERVER_CAN_EXECUTE, "no delay for 0:nobody | 1:admins | 2:superadmins/owner")
CreateConVar("spraymon_nooverspraying", 0, FCVAR_REPLICATED, "anti over spraying: 0 | 1")

hook.Add("PlayerSpray", "SMSendSpray", function(ply)
	local trace = ply:GetEyeTrace()
	net.Start("SMAddSpray")
		net.WriteEntity(ply)
		net.WriteFloat(trace.HitNormal.x)
		net.WriteFloat(trace.HitNormal.y)
		net.WriteFloat(trace.HitNormal.z)
		net.WriteFloat(trace.HitPos.x)
		net.WriteFloat(trace.HitPos.y)
		net.WriteFloat(trace.HitPos.z)
	net.Broadcast()
end)

local plymeta = FindMetaTable("Player")
plymeta.ZSSprayConCommand = plymeta.ZSSprayConCommand or {Original = plymeta.ConCommand}
local commands = plymeta.ZSSprayConCommand
commands.Notify = function(self, cmd)
	if not self:IsBot() and string.find(cmd, "r_cleardecals", 1, true) then
		net.Start("SMClearDecals")
		net.Send(self)
	end
end
if not commands.Wrapper then
	commands.Wrapper = function(self, cmd, ...)
		commands.Notify(self, cmd)
		return commands.Original(self, cmd, ...)
	end
	plymeta.ConCommand = commands.Wrapper
end

net.Receive("SMSpray", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local mode = noDelay:GetInt()
	if mode > 0 and (ply:IsUserGroup("owner") or mode == 1 and ply:IsAdmin() or mode >= 2 and ply:IsSuperAdmin()) then
		ply:AllowImmediateDecalPainting()
	end
end)
