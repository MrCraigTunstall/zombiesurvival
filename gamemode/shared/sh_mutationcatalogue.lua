GM.Mutations = {}
GM.MutationsBySignature = {}
GM.MutationIDsBySignature = {}
GM:AddLocalizedMutationItem("m_zombie_health", "zshop_alphazomb", "zshop_alphazomb2", ITEMCAT_MUTATIONS, 50, nil, function(pl) pl.m_Zombie_Health = true end, "models/items/healthkit.mdl")
GM:AddLocalizedMutationItem("m_zombie_moan", "zshop_zombsprint", "zshop_zombsprint2", ITEMCAT_MUTATIONS, 15, nil, function(pl) pl.m_Zombie_Moan = true end, "models/player/zombie_classic.mdl")
GM:AddLocalizedMutationItem("m_zombie_moanguard", "zshop_zombguard", "zshop_zombguard2", ITEMCAT_MUTATIONS, 80, nil, function(pl) pl.m_Zombie_MoanGuard = true end, "models/player/zombie_classic.mdl")

GM:AddLocalizedMutationItem("m_shade_damage", "zshop_bossphysicshazard", "zshop_bossphysicshazard2", ITEMCAT_MUTATIONS_BOSS, 550, nil, function(pl) pl.m_Shade_Force = true end, "models/player/zombie_classic.mdl")




GM:AddLocalizedMutationItem("m_zombie_armor", "zshop_armour", "zshop_armour_desc", ITEMCAT_MUTATIONS, 45, nil, function(pl) pl.m_Zombie_Armor = true end, "models/items/battery.mdl")
GM:AddLocalizedMutationItem("m_zombie_tough", "zshop_tough", "zshop_tough_desc", ITEMCAT_MUTATIONS, 55, nil, function(pl) pl.m_Zombie_Tough = true end, "models/items/healthkit.mdl")

GM.MutationsBySignature.m_zombie_moanguard.Requires = "m_zombie_moan"
