local classes = {"weapon_knife", "weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle",
 "weapon_elite", "weapon_fiveseven", "weapon_m3", "weapon_xm1014", "weapon_galil",
 "weapon_ak47", "weapon_scout", "weapon_sg552", "weapon_awp", "weapon_g3sg1",
 "weapon_famas", "weapon_m4a1", "weapon_aug", "weapon_sg550", "weapon_mac10",
 "weapon_tmp", "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m249"}
local known = {weapon_map_base = true}
local heldMaps = setmetatable({}, {__mode = "k"})
for _, class in ipairs(classes) do known[class] = true end

function GM:IsZombieEscapeMapWeapon(weapon)
 if not IsValid(weapon) or weapon.IsMarkedForDeletion and weapon:IsMarkedForDeletion() then return false end
 local class = weapon:GetClass()
 return known[class] == true or weapon.Base == "weapon_map_base" or weapons.IsBasedOn(class, "weapon_map_base")
end

local dummy = {Type = "anim", RenderGroup = RENDERGROUP_NONE}
function dummy:Initialize() self:SetNoDraw(true) end
if SERVER then function dummy:Think() self:Remove() end end
hook.Add("Initialize", "RegisterDummyEntities", function()
 for _, class in ipairs({"ammo_50ae", "ammo_556mm_box", "player_weaponstrip"}) do scripted_ents.Register(dummy, class) end
 for _, class in ipairs(classes) do weapons.Register({Base = "weapon_map_base"}, class) end
end)

local function FixPickup(weapon)
 for _, ent in ipairs(ents.FindInSphere(weapon:GetPos(), 30)) do
  if IsValid(ent) and ent:GetClass() == "func_physbox_multiplayer" and ent:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS then
   ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
  end
 end
end

hook.Add("PlayerCanPickupWeapon", "RestrictMapWeapons", function(pl, weapon)
 if not GAMEMODE:IsZombieEscapeMapWeapon(weapon) or pl:IsSpectator() or pl:Team() ~= TEAM_HUMAN or weapon.ZombieOnly then return end
 local previous = heldMaps[pl]
 if GAMEMODE:IsZombieEscapeMapWeapon(previous) and previous:GetOwner() == pl then return false end
 heldMaps[pl] = nil
 for _, held in ipairs(pl:GetWeapons()) do
  if GAMEMODE:IsZombieEscapeMapWeapon(held) and held:GetOwner() == pl then heldMaps[pl] = held; return false end
 end
 if SERVER then FixPickup(weapon) end
end)
