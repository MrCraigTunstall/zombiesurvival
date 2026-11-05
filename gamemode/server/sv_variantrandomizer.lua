GM.VariantRandomizer = CreateConVar("zs_variant_randomizer", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Choose a round variant during map setup", 0, 1)
local definitions = {
	{key = "normal", name = "Normal Mode"},
	{key = "classic", name = "Classic Mode", class = "Classic Zombie"},
	{key = "sigil", name = "Sigil Mode"},
	{key = "trader", name = "Trader Mode"},
	{key = "baby", name = "Baby Mode", class = "Gore Child"},
	{key = "pants", name = "Pants Mode", class = "Zombie Legs"}
}
GM.VariantTypes = {}
for _, definition in ipairs(definitions) do
	definition.enabled = CreateConVar("zs_variant_" .. definition.key, definition.key == "classic" and "0" or "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Allow " .. definition.name .. " in round selection", 0, 1)
	GM.VariantTypes[definition.key] = definition
end

function GM:ApplyRoundVariant(key)
	local definition = key and self.VariantTypes[key]
	if key and not definition then return false end
	if definition and definition.class and not self.ZombieClasses[definition.class] then return false end
	if not self.ZSVariantBaseline then
		self.ZSVariantBaseline = {classic = self.ClassicMode, baby = self.BabyMode, pants = self.PantsMode,
			default = self.PreOverrideDefaultZombieClass or self.DefaultZombieClass, actualdefault = self.DefaultZombieClass}
	end
	local baseline = self.ZSVariantBaseline
	local classic = key and key == "classic" or not key and baseline.classic or false
	local baby = key and key == "baby" or not key and baseline.baby or false
	local pants = key and key == "pants" or not key and baseline.pants or false
	self.ClassicMode, self.BabyMode, self.PantsMode = classic, baby, pants
	SetGlobalBool("classicmode", classic)
	SetGlobalBool("babymode", baby)
	SetGlobalBool("pantsmode", pants)
	SetGlobalBool("zs_trader_only", key == "trader")
	SetGlobalString("zs_round_variant", key or "")
	local class = definition and definition.class and self.ZombieClasses[definition.class]
	if not key then class = self.ZombieClasses[classic and "Classic Zombie" or baby and "Gore Child" or pants and "Zombie Legs" or ""] end
	self.DefaultZombieClass = class and class.Index or not key and baseline.actualdefault or baseline.default
	self.SelectedVariant = key
	self:SetUseSigils(false)
	for _, pl in player.Iterator() do
		local current = pl:GetZombieClassTable()
		local special = current and (current.Name == "Classic Zombie" or current.Name == "Gore Child" or current.Name == "Zombie Legs")
		if current and ((class and current.Index ~= class.Index and current.Name ~= "Crow") or (not class and special)) then
			pl:SetZombieClass(self.DefaultZombieClass)
			if pl:Team() == TEAM_UNDEAD and pl:Alive() then pl:KillSilent(); pl:UnSpectateAndSpawn() end
			pl.DeathClass = self.DefaultZombieClass
		end
	end
	if key == "trader" then
		for _, name in ipairs({"prop_arsenalcrate", "status_arsenalcrate"}) do
			for _, ent in ipairs(self:GetZSClassEntities(name)) do if IsValid(ent) then ent:Remove() end end
		end
	end
	if self.RemoveTraders then self:RemoveTraders() end
	return true
end

function GM:SelectRandomVariant()
	if self.ZombieEscape or self.ObjectiveMap or not self.VariantRandomizer:GetBool() then
		if self.SelectedVariant then self:ApplyRoundVariant(nil) end
		self.SelectedVariant = nil
		SetGlobalString("zs_round_variant", "")
		SetGlobalBool("zs_trader_only", false)
		return
	end
	local available = {}
	for _, definition in ipairs(definitions) do
		local eligible = definition.enabled:GetBool() and (not definition.class or self.ZombieClasses[definition.class] ~= nil)
		if definition.key == "sigil" then eligible = eligible and self.MaxSigils > 0 and #(self.ProfilerNodes or {}) >= self.MaxSigils end
		if definition.key == "trader" then eligible = eligible and GetConVar("zs_trader_variant"):GetBool() end
		if eligible then available[#available + 1] = definition.key end
	end
	local key = #available > 0 and available[math.random(#available)] or "normal"
	if not self:ApplyRoundVariant(key) then return end
	local name = self.VariantTypes[key].name
	for _, pl in player.Iterator() do
		if not pl:IsBot() and pl:Team() ~= TEAM_SPECTATOR then pl:CenterNotify(COLOR_CYAN, "Round variant: ", COLOR_YELLOW, name) end
	end
	return key
end
