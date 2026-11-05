local source, size, normal, supers, names, entries
function GM:GetBossCatalog()
	local changed = source ~= self.ZombieClasses or size ~= #self.ZombieClasses
	if not changed then
		for i = 1, size do
			local class, entry = source[i], entries[i]
			if class ~= entry.class or class.Boss ~= entry.boss or class.SuperBoss ~= entry.super
				or class.Name ~= entry.name or class.Index ~= entry.index then
				changed = true
				break
			end
		end
	end
	if changed then
		source, normal, supers, names = self.ZombieClasses, {}, {}, {}
		size = #source
		entries = {}
		for i, class in ipairs(source) do
			entries[i] = {class = class, boss = class.Boss, super = class.SuperBoss, name = class.Name, index = class.Index}
			if class.Boss then
				local list = class.SuperBoss and supers or normal
				list[#list + 1] = class.Index
				names[string.lower(class.Name)] = class
			end
		end
	end
	return normal, supers, names
end

function GM:GetPreferredBossClass(pl)
	local choices, _, lookup = self:GetBossCatalog()
	if #choices == 0 then return -1 end
	local desired = self:IsBabyMode() and "giga gore child" or pl:IsBot() and "nightmare" or string.lower(pl:GetInfo("zs_bossclass") or "")
	if desired == "" then desired = "nightmare" end
	local class = lookup[desired]
	if class and not class.SuperBoss then return class.Index end
	return choices[math.random(#choices)]
end
