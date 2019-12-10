local trace = {mask = MASK_SHOT, mins = Vector(-2, -2, -2), maxs = Vector(2, 2, 2)}
local filter = {}
local entitylist = {}

local colTemp = Color(255, 255, 255)
function GM:DrawTargetID(ent, fade)
	fade = fade or 1
	local ts = ent:GetPos():ToScreen()
	local x, y = ts.x, math.Clamp(ts.y, 0, ScrH() * 0.95)

	colTemp.a = fade * 255
	util.ColorCopy(COLOR_FRIENDLY, colTemp)

	local name = ent:Name()
	draw.SimpleTextBlur(name, "ZSHUDFontSmaller", x, y, colTemp, TEXT_ALIGN_CENTER)
	y = y + draw.GetFontHeight("ZSHUDFontSmaller") + 4

	local healthfraction = math.max(ent:Health() / (ent:Team() == TEAM_UNDEAD and ent:GetMaxZombieHealth() or ent:GetMaxHealth()), 0)
	if healthfraction ~= 1 then
		util.ColorCopy(0.75 <= healthfraction and COLOR_HEALTHY or 0.5 <= healthfraction and COLOR_SCRATCHED or 0.25 <= healthfraction and COLOR_HURT or COLOR_CRITICAL, colTemp)

		local healthdisplay = math.ceil(healthfraction * 100).."%"
		draw.SimpleTextBlur(healthdisplay, "ZSHUDFont", x, y, colTemp, TEXT_ALIGN_CENTER)
		y = y + draw.GetFontHeight("ZSHUDFont") + 4
	end

	util.ColorCopy(color_white, colTemp)

	if ent:Team() == TEAM_UNDEAD then
		local classtab = ent:GetZombieClassTable()
		local classname = classtab.TranslationName and translate.Get(classtab.TranslationName) or classtab.Name
		if classname then
			draw.SimpleTextBlur(classname, "ZSHUDFontTiny", x, y, colTemp, TEXT_ALIGN_CENTER)
		end
	else
		local holding = ent:GetHolding()
		if holding:IsValid() then
			local mdl = holding:GetModel()
			local name = string.match(mdl, ".*/(.+)%.mdl") or "object"
			draw.SimpleTextBlur(translate.Format("carrying_prop", name), "ZSHUDFontTiny", x, y, colTemp, TEXT_ALIGN_CENTER)
		else
			local wep = ent:GetActiveWeapon()
			if wep:IsValid() then
				draw.SimpleTextBlur(wep:GetPrintName(), "ZSHUDFontTiny", x, y, colTemp, TEXT_ALIGN_CENTER)
			end
		end
	end
end

GM.TraceTarget = NULL

local function FuncFilterPlayers(ent)
	return not ent:IsPlayer()
end
local function FuncFilterTeam(ent)
	return not (ent:IsPlayer() and ent:Team() == MySelf:Team())
end
function GM:HUDDrawTargetID(teamid)
	local start = EyePos()
	trace.start = start
	trace.endpos = start + EyeVector() * 2048
	filter[1] = MySelf.TargetIDFilter or MySelf
	filter[2] = MySelf:GetObserverTarget()
	trace.filter = filter

	local isspectator = MySelf:IsSpectator()

	local entity = util.TraceHull(trace).Entity
	self.TraceTarget = entity
	trace.filter = FuncFilterPlayers
	self.TraceTargetNoPlayers = util.TraceLine(trace).Entity

	if entity:IsValid() and (entity:IsPlayer() and (entity:Team() == teamid or isspectator) or entity.Sigil) then
		entitylist[entity] = CurTime()
	end

	for ent, time in pairs(entitylist) do
		if ent:IsValidPlayer() and (ent:Team() == teamid or isspectator) and CurTime() < time + 1.5 then
			self:DrawTargetID(ent, 1 - math.Clamp((CurTime() - time) / 1.5, 0, 1))
		else
			entitylist[ent] = nil
		end
	end
end
