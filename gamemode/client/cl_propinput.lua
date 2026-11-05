local math = math
local IsValid = IsValid
local snapAngle = Angle()
local lastObject, lastX, lastY

function GM:_InputMouseApply(cmd, x, y, ang)
	local pl = MySelf
	if not IsValid(pl) or not pl:KeyDown(IN_WALK) then lastObject = nil return end
	local object = pl:GetHolding()
	if not IsValid(object) then lastObject = nil return end
	self.InputMouseX = math.NormalizeAngle(self.InputMouseX - x * 0.02 * self.PropRotationSensitivity)
	self.InputMouseY = math.NormalizeAngle(self.InputMouseY - y * 0.02 * self.PropRotationSensitivity)
	local snap = self.PropRotationSnap
	local ax, ay = self.InputMouseX, self.InputMouseY
	if snap > 0 then
		snapAngle.p = ax
		ax = snapAngle:SnapTo("p", snap).p
		snapAngle.p = ay
		ay = snapAngle:SnapTo("p", snap).p
	end
	if object ~= lastObject or ax ~= lastX or ay ~= lastY then
		RunConsoleCommand("_zs_rotateang", ax, ay)
		lastObject, lastX, lastY = object, ax, ay
	end
	return true
end

local frame = -1
hook.Remove("Think", "ZSDeployGhostInput")

function GM:UpdateDeploymentGhostInput(ghost)
 local owner = ghost:GetOwner()
 if owner ~= LocalPlayer() or not IsValid(owner) or not owner:Alive() then return end
 local weapon = owner:GetActiveWeapon()
 if not IsValid(weapon) or weapon:GetClass() ~= ghost.GhostWeapon or not weapon.GhostRotationInput or not weapon.RotateGhost then return end
 local current = FrameNumber()
 if current == frame then return end
 frame = current
 local direction = (owner:KeyDown(IN_ATTACK2) and 1 or 0) - (owner:KeyDown(IN_RELOAD) and 1 or 0)
 if direction == 0 then return end
 local delta = FrameTime()
 if delta > 0 then weapon:RotateGhost(direction * delta * 60) end
end
