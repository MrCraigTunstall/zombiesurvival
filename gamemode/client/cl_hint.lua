local Hints = {}

function GM:DrawPointWorldHints()
	for _, ent in ipairs(self:GetZSClassEntities("point_worldhint")) do ent:DrawHint() end
end

function GM:WorldHint(hint, pos, ent, lifetime)
	lifetime = lifetime or 8

	if ent and ent:IsValid() then
		if pos then
			pos = ent:WorldToLocal(pos)
		else
			pos = ent:OBBCenter()
		end
	else
		ent = nil
		pos = pos or vector_origin
	end

	local now = CurTime()
	local hint = {Hint = hint, Pos = pos, Entity = ent, StartTime = now, EndTime = now + lifetime}
	table.insert(Hints, hint)

	return hint
end

net.Receive("zs_worldhint", function(length)
	GAMEMODE:WorldHint(net.ReadString(), net.ReadVector(), net.ReadEntity(), net.ReadFloat())
end)

local matRing = Material("effects/select_ring")
local colFG = Color(220, 220, 220, 255)

function DrawWorldHint(hint, pos, delta, scale)
	local eyepos = EyePos()

	delta = delta or 1

	colFG.a = math.min(220, delta * 220)

	local ang = (eyepos - pos):Angle()
	ang:RotateAroundAxis(ang:Right(), 270)
	ang:RotateAroundAxis(ang:Up(), 90)

	cam.IgnoreZ(true)
	cam.Start3D2D(pos, ang, (scale or 1) * math.max(250, eyepos:Distance(pos)) * delta * 0.0005)

	draw.SimpleText("!", "zshintfont", 0, 0, colFG, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(hint, "ZS3D2DFont2Small", 0, 64, colFG, TEXT_ALIGN_CENTER)

	surface.SetMaterial(matRing)
	local pulsebase = math.max(0.25, math.abs(math.sin(RealTime() * 6)))
	for i=1, 4 do
		colFG.a = colFG.a * (1 / i)
		surface.SetDrawColor(colFG)
		local pulse = pulsebase * 30 * i
		surface.DrawTexturedRectRotated(0, 0, 128 + pulse, 128 + pulse, 0)
	end

	cam.End3D2D()
	cam.IgnoreZ(false)
end

local matSigil = Material("zombiesurvival/sigil/icon.png")
function DrawSigilHint(hint, pos, delta, scale, color)
	local eyepos = EyePos()

	delta = delta or 1

	local ang = (eyepos - pos):Angle()
	ang:RotateAroundAxis(ang:Right(), 270)
	ang:RotateAroundAxis(ang:Up(), 90)

	cam.IgnoreZ(true)
	cam.Start3D2D(pos, ang, (scale or 1) * math.max(250, eyepos:Distance(pos)) * delta * 0.0004)

	draw.SimpleText(hint, "ZS3D2DFont", 0, 64, color_white, TEXT_ALIGN_CENTER)

	surface.SetMaterial(matSigil)
	surface.SetDrawColor(color)
	surface.DrawTexturedRectRotated(0, 0, 64, 128, 0)

	cam.End3D2D()
	cam.IgnoreZ(false)
end

function DrawIconHint(text, image, pos, delta, scale, color)
	local eyepos = EyePos()

	if WorldVisible(eyepos, pos) then return end

	image = Material(image)
	delta = delta or 1

	local ang = (eyepos - pos):Angle()
	ang:RotateAroundAxis(ang:Right(), 270)
	ang:RotateAroundAxis(ang:Up(), 90)

	cam.IgnoreZ(true)
	cam.Start3D2D(pos, ang, (scale or 1) * math.max(250, eyepos:Distance(pos)) * delta * 0.0005)

	draw.SimpleText(text, "ZS3D2DFont2Small", 0, 70, Vector(255, 255, 255, 255), TEXT_ALIGN_CENTER)

	surface.SetMaterial(image)
	surface.SetDrawColor(color)
	surface.DrawTexturedRectRotated(0, 0, 128, 128, 0)

	cam.End3D2D()
	cam.IgnoreZ(false)
end
local DrawWorldHint = DrawWorldHint

function GM:DrawWorldHints()
	local count = #Hints
	if count == 0 then return end
	local curtime = CurTime()
	local write = 1
	for read = 1, count do
		local hint = Hints[read]
		local ent = hint.Entity
		if curtime < hint.EndTime and not (ent and not ent:IsValid()) then
			Hints[write] = hint
			write = write + 1
			DrawWorldHint(hint.Hint, ent and ent:LocalToWorld(hint.Pos) or hint.Pos, math.Clamp(hint.EndTime - curtime, 0, 1))
		end
	end
	local last = #Hints
	for read = count + 1, last do
		Hints[write] = Hints[read]
		write = write + 1
	end
	for index = write, last do
		Hints[index] = nil
	end
end
