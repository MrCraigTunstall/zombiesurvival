local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(GM.ZSQuestFrame)then GM.ZSQuestFrame:Remove();GM.ZSQuestFrame=nil end
local accent, muted = Color(130, 210, 255), Color(175, 190, 210)
local function Layout(frame, contentHeight)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 local scale=GAMEMODE.MenuScale or 1
 if frame.ContentScale~=scale then
  frame.ContentHeight=(frame.ContentHeight or 480*(frame.ContentScale or 1))*scale/(frame.ContentScale or 1)
  frame.ContentScale=scale
  for _,label in ipairs(frame.DetailLabels or {})do label:DockMargin(U(12),U(12),U(12),U(8))label.NeedsMeasure=true end
  frame.ResizeDue=true
 end
 frame.ContentHeight=contentHeight or frame.ContentHeight or U(480)
	local width, height = math.min(U(620), screenWidth - 32), math.min(frame.ContentHeight, screenHeight - 32)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
	if frame.LayoutWidth==width and frame.LayoutHeight==height then
  if screenChanged then frame:Center()end
  return
 end
 frame.LayoutWidth,frame.LayoutHeight=width,height
 frame:SetSize(width,height);frame:Center()
 frame.Details:GetVBar():SetWide(U(16))
	frame.QuestTitle:SetPos(U(20), U(12)) frame.QuestTitle:SetSize(width - U(40), U(28))
	frame.RequestLabel:SetPos(U(20), U(44)) frame.RequestLabel:SetSize(width - U(40), U(22))
	frame.Details:SetPos(U(20), U(88)) frame.Details:SetSize(width - U(40), height - U(156))
	frame.QuestAction:SetPos(U(20), height - U(52)) frame.QuestAction:SetSize(width - U(156), U(32))
	frame.CloseButton:SetPos(width - U(120), height - U(52)) frame.CloseButton:SetSize(U(100), U(32))
end

local function SetText(label, text)
	if label.QuestText == text then return end
	label.QuestText = text label:SetText(text) label.NeedsMeasure = true
end

local function Detail(frame, text, font, color)
	local label = vgui.Create("DLabel", frame.Details)
 frame.DetailLabels[#frame.DetailLabels+1]=label
	label:Dock(TOP) label:DockMargin(U(12), U(12), U(12), U(8)) label:SetTall(U(48))
	label:SetFont(font) label:SetTextColor(color) label:SetWrap(true) label:SetMouseInputEnabled(false)
	SetText(label, text)
	label.PerformLayout = function(self, width)
		if self.LayoutWidth ~= width then self.LayoutWidth = width self.NeedsMeasure = true end
	end
	label.PaintOver = function(self)
		if self.NeedsMeasure then
			local height = self:GetTall() self:SizeToContentsY()
			if self:GetTall() == height then self.NeedsMeasure = nil else self:InvalidateParent(true) frame.ResizeDue = true end
		end
	end
	return label
end

local function SetDescription(frame, text)
	if frame.DescriptionText == text then return end
	frame.DescriptionText = text frame.ResizeDue = true
	local labels, position, index = frame.DescriptionLabels, 1, 0
	while position <= #text do
		index = index + 1
		local finish = math.min(position + 899, #text)
		if finish < #text then
			while finish > position and string.byte(text, finish + 1) >= 128 and string.byte(text, finish + 1) < 192 do finish = finish - 1 end
			local space = string.match(string.sub(text, position, finish), "^.*()%s")
			if space and space > 450 then finish = position + space - 1 end
		end
		local label = labels[index]
		if not IsValid(label) then label = Detail(frame, "", "ZSMenuScaledBody", color_white) labels[index] = label label:SetZPos(index) end
		SetText(label,string.sub(text,position,finish));if not label:IsVisible()then label:SetVisible(true)end
		position = finish + 1
	end
	for unused = index + 1, #labels do if labels[unused]:IsVisible()then labels[unused]:SetVisible(false)end end
end

local function Status(ent)
	local state, kind = ent:GetQuestState(), ent:GetQuestKind()
	if state == 2 then return "Completed for this round", false end
	if state ~= 1 then return state == 3 and "Previous attempt failed. You can try again." or "Available", true end
	if ent:GetQuestPlayer() ~= MySelf then return "Another survivor has accepted this quest", false end
	if kind == 1 then return ent:GetQuestProgress() .. " / " .. ent:GetQuestDuration() .. " active-wave seconds", false end
	if kind == 2 then return ent:GetQuestProgress() == 1 and "Medicine collected. Deliver it here." or "Find the marked medicine and press USE.", ent:GetQuestProgress() == 1 end
	local list = GAMEMODE.QuestDefinitions[3].weapons
	local class = list[ent:GetQuestProgress() + 1]
	return class and "Bring " .. GAMEMODE:GetQuestWeaponName(class) or "Deliveries finished. Collect your reward.", true
end

function GM:OpenQuestMenu(ent)
 self:RefreshMenuScale()
	if not IsValid(ent) or ent:GetClass() ~= "npc_zs_quest" or not self.QuestDefinitions[ent:GetQuestKind()] then return end
	local definition = self.QuestDefinitions[ent:GetQuestKind()]
	local frame = self.ZSQuestFrame
	if not IsValid(frame) then
	frame = vgui.Create("DFrame")
 frame:SetVisible(false)
	self.ZSQuestFrame = frame
 frame.DetailLabels={}
	frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:SetDeleteOnClose(false)
 self:StyleShopFrame(frame)
 local background,colors=Color(14,22,34),self.ShopColors
 frame.Paint=function(_,width,height)
  draw.RoundedBox(8,0,0,width,height,background)
  draw.RoundedBox(U(8),0,0,width,U(72),colors.header)
  surface.SetDrawColor(colors.accent);surface.DrawRect(U(20),U(70),width-U(40),U(2))
 end
 if IsValid(frame.btnMinim)then frame.btnMinim:SetVisible(false)end
 if IsValid(frame.btnMaxim)then frame.btnMaxim:SetVisible(false)end
	local title = vgui.Create("DLabel", frame)
	title:SetFont("ZSMenuScaledTitle") title:SetTextColor(color_white)
	frame.RequestLabel = vgui.Create("DLabel", frame)
	frame.RequestLabel:SetFont("ZSMenuScaledSmall") frame.RequestLabel:SetTextColor(self.ShopColors.muted)
	frame.RequestLabel:SetText("Survivor request")
	frame.Details = vgui.Create("DScrollPanel", frame)
 local bar=frame.Details:GetVBar()
 bar.Paint=function(_,width,height)draw.RoundedBox(4,0,0,width,height,colors.row)end
 for _,button in ipairs({bar.btnUp,bar.btnDown,bar.btnGrip})do
  button.Paint=function(self,width,height)draw.RoundedBox(4,0,0,width,height,self:IsHovered()and colors.accent or colors.muted)end
 end
 frame.Details.Paint = function(_, width, height) draw.RoundedBox(6, 0, 0, width, height, GAMEMODE.ShopColors.row) end
	local desc = Detail(frame, "", "ZSMenuScaledBody", color_white) desc:SetZPos(1) frame.DescriptionLabels = {desc}
	local reward = Detail(frame, "", "ZSMenuScaledSmall", self.ShopColors.muted)
	local status = Detail(frame, "", "ZSMenuScaledBody", self.ShopColors.accent) reward:SetZPos(10000) status:SetZPos(10001)
	local action = vgui.Create("DButton", frame) self:StyleShopButton(action, true, true)
	frame.QuestTitle, frame.QuestDescription, frame.QuestReward = title, desc, reward
	frame.QuestStatus, frame.QuestAction = status, action
	frame.CloseButton = vgui.Create("DButton", frame)
	frame.CloseButton:SetText(translate.Get("close")) self:StyleShopButton(frame.CloseButton, false, true)
	frame.CloseButton.DoClick = function() frame:Close() end
 frame.OnRemove=function(panel)
  panel.QuestNPC,panel.Pending,panel.DescriptionLabels,panel.DetailLabels=nil,nil,nil,nil
  if GAMEMODE.ZSQuestFrame==panel then GAMEMODE.ZSQuestFrame=nil end
 end
	action.DoClick = function()
  if frame.Pending or not frame:IsVisible()or not frame.LastEnabled or not GAMEMODE:CanReachQuest(MySelf,frame.QuestNPC,180)then return end
  frame.Pending=RealTime()+3;frame.LastEnabled=false;action:SetEnabled(false)
		net.Start("zs_quest_action"); net.WriteEntity(frame.QuestNPC); net.SendToServer()
	end
	frame.Think = function(panel)
		if not panel:IsVisible() then return end
		local ent = panel.QuestNPC
		local now = RealTime()
		if now < (panel.NextRefresh or 0) then return end
		panel.NextRefresh = now + 0.1
		if panel.ResizeDue then
			panel.ResizeDue = nil
			Layout(panel, math.Clamp(panel.Details:GetCanvas():GetTall() + U(156), U(260), U(480)))
		end
		if not GAMEMODE:CanReachQuest(MySelf, ent, 180) then panel:Close(); return end
		if panel.Pending and now >= panel.Pending then panel.Pending = nil; panel.Feedback = "No response. Try again."; panel.FeedbackUntil = now + 2 end
		local text, allowed = Status(ent)
		if panel.FeedbackUntil and now >= panel.FeedbackUntil then panel.Feedback = nil; panel.FeedbackUntil = nil end
		text = panel.Feedback or text
		if panel.LastStatus ~= text then panel.LastStatus = text; SetText(status, text) end
		local caption = panel.Pending and "Waiting..." or ent:GetQuestState() == 1 and "Deliver / collect reward" or ent:GetQuestState() == 2 and "Completed" or "Accept quest"
		if panel.LastCaption ~= caption then panel.LastCaption = caption; action:SetText(caption) end
		local enabled = not not (allowed and not panel.Pending and (ent:GetQuestState() == 1 or ent:GetQuestKind() ~= 1 or GAMEMODE:GetWaveActive()))
		if panel.LastEnabled ~= enabled then panel.LastEnabled = enabled; action:SetEnabled(enabled) end
	end
	end
 Layout(frame)
 local changed=frame.QuestNPC~=ent
 if changed then
  frame.QuestNPC,frame.NextRefresh,frame.Pending,frame.Feedback,frame.FeedbackUntil=ent,nil,nil,nil,nil
  frame.LastStatus,frame.LastCaption,frame.LastEnabled=nil,nil,nil
 end
 SetText(frame.QuestTitle,definition.title)
 SetText(frame.CloseButton,translate.Get("close"))
 SetDescription(frame,definition.description..(ent:GetQuestKind()==1 and " Protect for "..ent:GetQuestDuration().." seconds."or " Complete within three minutes."))
 SetText(frame.QuestReward,"Reward: "..(ent:GetQuestReward()~=""and self:GetQuestWeaponName(ent:GetQuestReward()).." (60 points if already owned or unavailable)"or "60 points"))
 if frame:IsVisible()then
  if changed then frame:Think()end
  return frame
 end
 frame.NextRefresh=nil;frame:SetVisible(true);frame:MakePopup();frame:Think()
	return frame
end

net.Receive("zs_quest_open", function() GAMEMODE:OpenQuestMenu(net.ReadEntity()) end)
net.Receive("zs_quest_result", function()
	local ent, ok, message = net.ReadEntity(), net.ReadBool(), net.ReadString()
	local frame = GAMEMODE.ZSQuestFrame
	if IsValid(frame) and frame.QuestNPC == ent then frame.Pending = nil; frame.Feedback = message; frame.FeedbackUntil = RealTime() + 2;frame.NextRefresh=nil end
	surface.PlaySound(ok and "buttons/bell1.wav" or "buttons/button10.wav")
end)

hook.Add("HUDPaint", "ZSQuestObjective", function()
	if not IsValid(MySelf) or not MySelf:Alive() or MySelf:Team() ~= TEAM_HUMAN then return end
	for _, ent in ipairs(GAMEMODE:GetZSClassEntities("npc_zs_quest")) do
		if IsValid(ent) and ent:GetQuestState() == 1 and ent:GetQuestPlayer() == MySelf then
			local medicine = ent:GetQuestKind() == 2 and ent:GetQuestProgress() == 0
			local position = medicine and ent:GetQuestLocation() or ent:GetPos()
			if position then
				local screen = (position + Vector(0, 0, medicine and 24 or 90)):ToScreen()
				if screen.visible then
					local text = medicine and "MEDICINE" or Status(ent)
					draw.SimpleText(text, "ZSHUDFontTiny", math.Clamp(screen.x, 100, ScrW() - 100), math.Clamp(screen.y, 40, ScrH() - 40), accent, TEXT_ALIGN_CENTER)
				end
			end
		end
	end
end)

hook.Add("OnScreenSizeChanged", "ZSQuestMenuLayout", function()
	if IsValid(GAMEMODE.ZSQuestFrame) then Layout(GAMEMODE.ZSQuestFrame) end
end)
