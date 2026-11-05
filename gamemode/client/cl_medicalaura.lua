local MedicalAuraDistance = 800
local MedicalAuraDistanceSquared = MedicalAuraDistance * MedicalAuraDistance
local matAura = Material("models/debug/debugwhite")
local skip = false
function GM.PostPlayerDrawMedical(pl)
	if not skip and pl:Team() ~= TEAM_UNDEAD and pl ~= LocalPlayer() then
		local eyepos = EyePos()
		local distanceSquared = pl:NearestPoint(eyepos):DistToSqr(eyepos)
		if distanceSquared < MedicalAuraDistanceSquared then
			local dist = math.sqrt(distanceSquared)
			local green = math.Clamp(pl:Health() / math.max(1, pl:GetMaxHealth()), 0, 1)
			local previousSkip = pl.SkipDrawHooks

			pl.SkipDrawHooks = true
			skip = true

			render.SuppressEngineLighting(true)
			render.ModelMaterialOverride(matAura)
			render.SetBlend((1 - (dist / MedicalAuraDistance)) * 0.1 * (1 + math.abs(math.sin((CurTime() + pl:EntIndex()) * 4)) * 0.05))
			render.SetColorModulation(1 - green, green, 0)
				local ok, failure = pcall(pl.DrawModel, pl)
			render.SetColorModulation(1, 1, 1)
			render.SetBlend(1)
			render.ModelMaterialOverride()
			render.SuppressEngineLighting(false)

			skip = false
			pl.SkipDrawHooks = previousSkip
			if not ok then error(failure, 0) end
		end
	end
end

