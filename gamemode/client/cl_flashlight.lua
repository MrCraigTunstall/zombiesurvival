local flashlight
local nextRequest = 0
local sound = Sound("items/flashlight1.wav")

function GM:CreateFlashlightCheck()
	local pl = LocalPlayer()
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or CurTime() < nextRequest then return end
	nextRequest = CurTime() + 0.1
	net.Start("zs_humanflashlight")
	net.WriteBool(not pl:GetNW2Bool("zs_humanflashlight", false))
	net.SendToServer()
	surface.PlaySound(sound)
end

function GM:UpdateHumanFlashlight()
	local pl = LocalPlayer()
	if not IsValid(pl) or not pl:Alive() or pl:Team() ~= TEAM_HUMAN or not pl:GetNW2Bool("zs_humanflashlight", false) then
		if IsValid(flashlight) then flashlight:Remove() end
		flashlight = nil
		return
	end
	if not IsValid(flashlight) then
		flashlight = ProjectedTexture()
		if not IsValid(flashlight) then flashlight = nil return end
		flashlight:SetTexture("effects/flashlight001")
		flashlight:SetBrightness(1)
		flashlight:SetFarZ(650)
		flashlight:SetFOV(70)
		flashlight:SetColor(color_white)
		flashlight:SetEnableShadows(false)
	end
	flashlight:SetPos(pl:GetShootPos())
	flashlight:SetAngles(pl:EyeAngles())
	flashlight:Update()
end

hook.Add("ShutDown", "ZSHumanFlashlight", function()
	if IsValid(flashlight) then flashlight:Remove() end
	flashlight = nil
end)
