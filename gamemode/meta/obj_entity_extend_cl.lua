local meta = FindMetaTable("Entity")

local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team

function meta:HealPlayer(pl, amount)
	local healed, rmv = 0, 0

	local health, maxhealth = pl:Health(), pl:GetDTBool(DT_PLAYER_BOOL_FRAIL) and math.floor(pl:GetMaxHealth() * 0.25) or pl:GetMaxHealth()
	local missing_health = maxhealth - health
	local poison = pl:GetPoisonDamage()
	local bleed = pl:GetBleedDamage()

	local multiplier = self.MedicHealMul or 1

	amount = amount * multiplier

	-- Heal bleed first.
	if bleed > 0 then
		rmv = math.min(amount, bleed)
		healed = healed + rmv
		amount = amount - rmv
	end

	-- Heal poison next.
	if poison > 0 and amount > 0 then
		rmv = math.min(amount, poison)
		healed = healed + rmv
		amount = amount - rmv
	end

	-- Then heal missing health.
	if missing_health > 0 and amount > 0 then
		rmv = math.min(amount, missing_health)
		healed = healed + rmv
		amount = amount - rmv
	end

	return healed
end
