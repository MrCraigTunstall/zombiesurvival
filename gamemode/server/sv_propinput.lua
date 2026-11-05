local function Normalize(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return end
	if value > 360 or value < -360 then value = math.fmod(value, 360) end
	return math.NormalizeAngle(value)
end

function GM:SetPropRotationInput(pl, x, y)
	if not IsValid(pl) or not pl:IsPlayer() or not pl:IsConnected() then return false end
	x, y = Normalize(x), Normalize(y)
	if not x or not y then return false end
	if pl.InputMouseX ~= x then pl.InputMouseX = x end
	if pl.InputMouseY ~= y then pl.InputMouseY = y end
	return true
end

concommand.Add("_zs_rotateang", function(sender, _, arguments)
	GAMEMODE:SetPropRotationInput(sender, arguments[1], arguments[2])
end)
