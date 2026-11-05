GM.ZSShadeControls = GM.ZSShadeControls or {
	owners = setmetatable({}, {__mode = "kv"}),
	objects = setmetatable({}, {__mode = "kv"}),
	weapons = setmetatable({}, {__mode = "kv"})
}
local state = GM.ZSShadeControls
local function active(ent)
	return IsValid(ent) and not ent:IsMarkedForDeletion()
end

function GM:IsShadeControllerOwner(pl, weapon)
	return active(pl) and pl:IsPlayer() and pl:Alive() and pl:Team() == TEAM_UNDEAD
		and pl:GetZombieClassTable().SWEP == "weapon_zs_shade" and active(weapon)
		and weapon:GetClass() == "weapon_zs_shade" and pl:GetActiveWeapon() == weapon and not self.RoundEnded
		and (not IsValid(pl.status_shadeambience) or pl.status_shadeambience:GetLastDamage() < 12)
end

function GM:GetShadeControl(pl)
	local ent = state.owners[pl]
	if active(ent) and ent:GetOwner() == pl then return ent end
	state.owners[pl] = nil
end

function GM:GetShadeObjectControl(obj)
	local ent = state.objects[obj]
	if active(ent) and ent:GetParent() == obj then return ent end
	state.objects[obj] = nil
end

function GM:CanShadeHoldObject(obj)
	if not active(obj) or obj:IsPlayer() or obj:IsNPC() or not obj:IsPhysicsModel() or obj:IsBarricadeProp() then return false end
	local phys = obj:GetPhysicsObject()
	if not IsValid(phys) or not phys:IsMoveable() then return false end
	local mass = phys:GetMass()
	return mass == mass and mass >= 1 and mass <= 300
end

function GM:RegisterShadeControl(ent, pl, obj, weapon)
	if not self:IsShadeControllerOwner(pl, weapon) or not self:CanShadeHoldObject(obj)
		or self:GetShadeControl(pl) or self:GetShadeObjectControl(obj) then return false end
	state.owners[pl], state.objects[obj], state.weapons[weapon] = ent, ent, ent
	ent.ZSShadeOwner, ent.ZSShadeObject, ent.ZSShadeWeapon = pl, obj, weapon
	weapon:SetShadeControl(ent)
	return true
end

function GM:UnregisterShadeControl(ent)
	local pl, obj, weapon = ent.ZSShadeOwner, ent.ZSShadeObject, ent.ZSShadeWeapon
	if pl and state.owners[pl] == ent then state.owners[pl] = nil end
	if obj and state.objects[obj] == ent then state.objects[obj] = nil end
	if weapon and state.weapons[weapon] == ent then state.weapons[weapon] = nil end
	if IsValid(weapon) and weapon:GetShadeControl() == ent then weapon:SetShadeControl(NULL) end
end

function GM:ReleaseShadeControl(pl, weapon)
	local ent = weapon and state.weapons[weapon] or state.owners[pl]
	if not ent then return end
	self:UnregisterShadeControl(ent)
	if active(ent) then ent:Remove() end
end

local function clear(pl) GAMEMODE:ReleaseShadeControl(pl) end
hook.Add("PlayerDeath", "ZSShadeControl", clear)
hook.Add("PlayerDisconnected", "ZSShadeControl", clear)
hook.Add("OnPlayerChangedTeam", "ZSShadeControl", clear)
hook.Add("PostCleanupMap", "ZSShadeControl", function()
	for pl in pairs(state.owners) do clear(pl) end
end)
