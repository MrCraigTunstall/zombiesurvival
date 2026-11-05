if IsValid(GM.ZSForgeMenu)then GM.ZSForgeMenu:Remove();GM.ZSForgeMenu=nil end
local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local width,height=math.min(U(480),screenWidth-24),math.min(U(360),screenHeight-24)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth==width and frame.LayoutHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth,frame.LayoutHeight=width,height
 frame:SetSize(width,height) frame:Center()
 frame:DockPadding(U(16),U(88),U(16),U(16))
 frame.CloseButton:SetSize(U(62),U(30)) frame.CloseButton:SetPos(width-U(78),U(20))
 frame.UpgradeButton:SetTall(U(42)) frame.UpgradeButton:DockMargin(0,U(8),0,0)
 frame.ContentScroll:GetVBar():SetWide(U(16))
 frame.ContentLabel:InvalidateLayout(true)
end

local function Bonus(level, nextlevel, amount, price)
	return "+" .. level * amount .. "%" .. (price and "  ->  +" .. nextlevel * amount .. "%" or "")
end

function GM:OpenWeaponForge()
 self:RefreshMenuScale()
	local frame=self.ZSForgeMenu
 if not IsValid(frame)then
 frame=vgui.Create("DFrame");frame:SetVisible(false);frame:SetDeleteOnClose(false);frame:SetDraggable(false)
	self.ZSForgeMenu = frame

	frame:SetTitle("")
	frame:ShowCloseButton(false)
	self:StyleShopFrame(frame)
	local colors = self.ShopColors
 local background=Color(14,22,34)
 frame.Paint=function(_,width,height)
  draw.RoundedBox(8,0,0,width,height,background);draw.RoundedBox(8,0,0,width,U(72),colors.header)
  surface.SetDrawColor(colors.accent);surface.DrawRect(U(16),U(70),width-U(32),U(2))
  draw.SimpleText("Weapon Forge","ZSMenuScaledTitle",U(16),U(14),color_white)
  draw.SimpleText("Upgrade the weapon you are holding","ZSMenuScaledSmall",U(16),U(44),colors.muted)
 end
 if IsValid(frame.btnMinim)then frame.btnMinim:SetVisible(false)end
 if IsValid(frame.btnMaxim)then frame.btnMaxim:SetVisible(false)end
	local button = vgui.Create("DButton", frame)
	button:Dock(BOTTOM)
	self:StyleShopButton(button, true, true)
	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	local bar = scroll:GetVBar()
	bar.Paint = function(_, width, height) draw.RoundedBox(4, 0, 0, width, height, colors.row) end
	for _, control in ipairs({bar.btnUp, bar.btnDown, bar.btnGrip}) do
		control.Paint = function(panel, width, height) draw.RoundedBox(4, 0, 0, width, height, panel:IsHovered() and colors.accent or colors.muted) end
	end
	local label = vgui.Create("DLabel", scroll)
	label:Dock(TOP) label:SetAutoStretchVertical(true)
	label:SetFont("ZSMenuScaledBody") label:SetWrap(true) label:SetTextColor(color_white)
	frame.ContentScroll = scroll
	local close = vgui.Create("DButton", frame)
	close:SetText(translate.Get("close"));close:SetSize(62,30)
 frame.CloseButton,frame.UpgradeButton,frame.ContentLabel=close,button,label
	self:StyleShopButton(close, false, true)
	close.DoClick = function() frame:Close() end
	button.DoClick = function()
  if not frame:IsVisible()or frame.Pending then return end
  frame.NextRefresh=nil;frame:Think()
  local pl=LocalPlayer();local weapon=IsValid(pl)and pl:GetActiveWeapon()
  if not IsValid(weapon)or not button:IsEnabled()then return end
  frame.Feedback,frame.FeedbackUntil=nil,nil
		local level = GAMEMODE:GetWeaponForgeLevel(weapon)
		frame.Pending = {weapon = weapon, level = level, untiltime = CurTime() + 3}
		button:SetEnabled(false);frame.ButtonEnabled=false
		RunConsoleCommand("zs_weaponforge", tostring(level), tostring(weapon:EntIndex()))
	end
	frame.Think=function()
  if not frame:IsVisible()then return end
		local now = CurTime()
		if now < (frame.NextRefresh or 0) then return end
		frame.NextRefresh = now + 0.1
		local pl = LocalPlayer()
		local weapon = IsValid(pl) and pl:GetActiveWeapon()
		local eligible = IsValid(pl) and pl:Alive() and pl:Team() == TEAM_HUMAN and GAMEMODE:IsWeaponForgeEligible(weapon)
		local level = GAMEMODE:GetWeaponForgeLevel(weapon)
		local price = GAMEMODE:GetWeaponForgePrice(level)
  if frame.Pending then
   if weapon~=frame.Pending.weapon or level~=frame.Pending.level then frame.Pending=nil;frame.Feedback=nil;frame.FeedbackUntil=nil
   elseif now>=frame.Pending.untiltime then frame.Pending=nil;frame.Feedback="No upgrade confirmed. Try again.";frame.FeedbackUntil=now+2 end
  end
  if frame.FeedbackUntil and now>=frame.FeedbackUntil then frame.Feedback,frame.FeedbackUntil=nil,nil end
  local near=eligible and price~=nil and pl:NearArsenalCrate()or false
  local busy=eligible and price~=nil and (pl:GetBarricadeGhosting()or pl:IsHolding()or weapon.reloading or weapon.WeaponForgeReload=="heat"and weapon:GetGunState()~=0 or weapon:GetNextPrimaryFire()>now or weapon:GetNextReload()>now)or false
		local points = IsValid(pl) and pl:GetPoints() or 0
		local name = IsValid(weapon) and (weapon.PrintName or weapon:GetClass()) or "No active weapon"
		local melee = IsValid(weapon) and weapon.IsMelee
		local reload = IsValid(weapon) and weapon.WeaponForgeReload == "heat" and "Cooling / venting" or "Reload speed"
		if frame.ContentWeapon ~= weapon or frame.ContentName ~= name or frame.ContentLevel ~= level or frame.ContentPoints ~= points
			or frame.ContentPending ~= frame.Pending or frame.ContentEligible ~= eligible or frame.ContentMelee ~= melee or frame.ContentReload ~= reload
			or frame.ContentPrice~=price or frame.ContentMax~=GAMEMODE.WeaponForgeMaxLevel or frame.ContentNear~=near or frame.ContentBusy~=busy or frame.ContentFeedback~=frame.Feedback then
			frame.ContentWeapon, frame.ContentName, frame.ContentLevel, frame.ContentPoints = weapon, name, level, points
			frame.ContentPending, frame.ContentEligible, frame.ContentMelee, frame.ContentReload = frame.Pending, eligible, melee, reload
			frame.ContentPrice,frame.ContentMax,frame.ContentNear,frame.ContentBusy,frame.ContentFeedback=price,GAMEMODE.WeaponForgeMaxLevel,near,busy,frame.Feedback
			local nextlevel = math.min(level + 1, GAMEMODE.WeaponForgeMaxLevel)
			local missing = price and math.ceil(price - points) or 0
			local action=frame.Feedback or frame.Pending and "Applying upgrade..." or not eligible and "Equip a supported human weapon to upgrade."
				or not price and "This weapon has reached the maximum tier."or not near and "Move within reach of an arsenal crate."or busy and "Finish your current action before upgrading."or points < price and "You need " .. missing .. " more " .. (missing == 1 and "point." or "points.")
				or "Use an arsenal crate. Upgrades stay with this weapon."
			local content = name .. "\nTier " .. level .. " / " .. GAMEMODE.WeaponForgeMaxLevel .. "     |     " .. math.floor(points) .. " points"
				.. "\n\nDamage: " .. Bonus(level, nextlevel, 10, price) .. "\nAttack speed: " .. Bonus(level, nextlevel, 12, price)
				.. (melee and "" or "\n" .. reload .. ": " .. Bonus(level, nextlevel, 15, price)) .. "\n\n" .. action
			if frame.Content ~= content then label:SetText(content); frame.Content = content end
		end
		local text = frame.Pending and "Waiting for upgrade..." or not eligible and "Select a supported weapon" or not price and "Fully forged"or not near and "Find an arsenal crate"or busy and "Finish your current action"or "Upgrade for " .. price .. " points"
		if frame.ButtonText ~= text then button:SetText(text); frame.ButtonText = text end
  local enabled=not not(eligible and price~=nil and points>=price and near and not busy and not frame.Pending)
  if frame.ButtonEnabled~=enabled then frame.ButtonEnabled=enabled;button:SetEnabled(enabled)end
 end
 frame.OnRemove=function(panel)
  panel.Pending,panel.ContentWeapon,panel.ContentLabel,panel.UpgradeButton,panel.CloseButton,panel.ContentScroll=nil,nil,nil,nil,nil,nil
  if GAMEMODE.ZSForgeMenu==panel then GAMEMODE.ZSForgeMenu=nil end
 end
 end
 Layout(frame)
 if frame:IsVisible()then return frame end
 frame.NextRefresh=nil;frame:SetVisible(true);frame:Think();frame:MakePopup()
 return frame
end

concommand.Add("zs_forge", function() GAMEMODE:OpenWeaponForge() end)

hook.Add("OnScreenSizeChanged", "ZSForgeMenuLayout", function()
 if IsValid(GAMEMODE.ZSForgeMenu) then Layout(GAMEMODE.ZSForgeMenu) end
end)
