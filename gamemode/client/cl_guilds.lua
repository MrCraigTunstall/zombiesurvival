local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(GM.ZSGuildFrame)then GM.ZSGuildFrame:Remove();GM.ZSGuildFrame=nil end
local accent, background, muted = Color(105, 175, 255), Color(14, 22, 34), Color(175, 190, 210)
local ring = Material("SGM/playercircle")
local up, down, lift = Vector(0, 0, 1), Vector(0, 0, -1), Vector(0, 0, 2)
local actions = {list = 0, create = 1, join = 2, invite = 3, leave = 4}
local nextRequest = 0

local function Request(action, text)
	local now = RealTime()
	if now < nextRequest then return false end
	nextRequest = now + 0.5
	net.Start("zs_guild_action"); net.WriteUInt(actions[action], 3); net.WriteString(text or ""); net.SendToServer()
	return true
end

hook.Add("PostPlayerDraw", "ZSGuildCircle", function(pl)
	if not IsValid(MySelf) or not IsValid(pl) or pl == MySelf or pl:IsBot() or not pl:Alive()
		or MySelf:Team() ~= TEAM_HUMAN or pl:Team() ~= TEAM_HUMAN or not GAMEMODE:ArePlayersInSameGuild(MySelf, pl) then return end
	local position = pl:GetPos() + lift
	render.SetMaterial(ring)
	render.DrawQuadEasy(position, up, 44, 44, accent)
	render.DrawQuadEasy(position, down, 44, 44, accent)
end)

local function Enable(control, value)
 if control:IsEnabled() ~= value then control:SetEnabled(value) end
end
local function StyleEntry(entry)
 GAMEMODE:StyleShopSearch(entry,true)
end
local function GuildDataChanged(frame,list)
 local snapshot=frame.GuildSnapshot
 if not snapshot or #snapshot~=#list then return true end
 for index,guild in ipairs(list)do
  local old=snapshot[index]
  if old.id~=guild.id or old.name~=guild.name or old.members~=guild.members or old.owner~=guild.owner then return true end
 end
 return false
end
local function RememberGuildData(frame)
 local snapshot=frame.GuildSnapshot or {}
 for index,guild in ipairs(frame.Guilds)do
  local record=snapshot[index]or {} snapshot[index]=record
  record.id,record.name,record.members,record.owner=guild.id,guild.name,guild.members,guild.owner
 end
 for index=#snapshot,#frame.Guilds+1,-1 do snapshot[index]=nil end
 frame.GuildSnapshot=snapshot
end
local function Layout(frame)
 local screenWidth,screenHeight=ScrW(),ScrH()
 GAMEMODE:RefreshMenuScale()
 frame:ApplyScale()
 local width,height=math.min(U(600),screenWidth-24),math.min(U(640),screenHeight-24)
 local screenChanged=frame.LayoutScreenWidth~=screenWidth or frame.LayoutScreenHeight~=screenHeight
 frame.LayoutScreenWidth,frame.LayoutScreenHeight=screenWidth,screenHeight
 if frame.LayoutWidth~=width or frame.LayoutHeight~=height then
  frame.LayoutWidth,frame.LayoutHeight=width,height
  frame:SetSize(width,height)frame.Header:SetWide(width-U(64))frame:Center()frame:InvalidateLayout(true)
 elseif screenChanged then frame:Center()
 end
end
local function Show(frame)
 Layout(frame)
 if frame:IsVisible()then return end
 frame:SetVisible(true)frame:Center()frame:MakePopup()frame.NextRefresh=0
end

function GM:OpenGuildMenu(list, maximum, cost, adminOnly)
 self:RefreshMenuScale()
	local frame = self.ZSGuildFrame
	if IsValid(frame) then
		local changed=GuildDataChanged(frame,list)or frame.Maximum~=maximum
		if changed then
		 frame.Guilds=list;frame.FilterSource,frame.GuildIDSource=nil,nil;RememberGuildData(frame)
		elseif frame.Guilds~=list then
		 frame.Guilds,frame.FilterSource,frame.GuildIDSource=list,list,list
		 for _,guild in ipairs(list)do frame.GuildByID[guild.id]=guild end
		 for index,guild in ipairs(frame.Filtered)do frame.Filtered[index]=frame.GuildByID[guild.id]end
		 for _,button in ipairs(frame.GuildRows)do if button.Guild then button.Guild=frame.GuildByID[button.Guild.id]end end
		end
		frame.Maximum,frame.Cost,frame.AdminOnly=maximum,cost or 100,adminOnly or false
		if changed then frame:RebuildGuildRows()end
		frame.NextRefresh=0;Show(frame)
		return frame
	end
	frame = vgui.Create("DFrame")
	frame:SetVisible(false)
	self.ZSGuildFrame = frame
	frame:SetSize(math.min(U(600), ScrW() - 24), math.min(U(640), ScrH() - 24)); frame:Center()
	frame:SetTitle(""); frame:SetDeleteOnClose(false)
	frame:DockPadding(U(12),U(82),U(12),U(12))
	self:StyleShopFrame(frame)
	frame.Paint=function(_,width,height)
	 draw.RoundedBox(8,0,0,width,height,background)
	 draw.RoundedBox(U(8),0,0,width,U(72),GAMEMODE.ShopColors.header)
	 surface.SetDrawColor(accent)surface.DrawRect(U(16),U(70),width-U(32),U(2))
	end
	if IsValid(frame.btnMinim)then frame.btnMinim:SetVisible(false)end
	if IsValid(frame.btnMaxim)then frame.btnMaxim:SetVisible(false)end
	local header=vgui.Create("DLabel",frame)
	header:SetPos(U(16),U(26));header:SetSize(U(560),U(28));header:SetText("Survivor guilds");header:SetFont("ZSMenuScaledTitle");header:SetTextColor(color_white)
	frame.Header=header
	frame.GuildRows={}
	frame.OnRemove=function(panel)
		if GAMEMODE.ZSGuildFrame==panel then GAMEMODE.ZSGuildFrame=nil end
		panel.GuildRows,panel.Guilds,panel.Filtered,panel.GuildByID,panel.GuildIDSource,panel.GuildSnapshot,panel.FilterSource=nil,nil,nil,nil,nil,nil,nil
	end
	frame.Guilds, frame.Maximum, frame.Page, frame.Cost, frame.AdminOnly = list, maximum, 1, cost or 100, adminOnly or false
	local status = vgui.Create("DLabel", frame)
	status:Dock(TOP); status:DockMargin(U(12), U(10), U(12), U(6)); status:SetTall(U(42)); status:SetWrap(true); status:SetFont("ZSMenuScaledBody"); status:SetTextColor(accent)
	frame.Status = status
	local search = vgui.Create("DTextEntry", frame)
	search:Dock(TOP); search:DockMargin(U(12), 0, U(12), U(8)); search:SetTall(U(30)); search:SetPlaceholderText("Search guilds");search:SetFont("ZSMenuScaledBody");frame.Search=search;StyleEntry(search)
	local controls = vgui.Create("DPanel", frame)
	controls:Dock(BOTTOM); controls:DockMargin(U(12), U(4), U(12), U(12)); controls:SetTall(U(114)); controls.Paint = function()end
	frame.EntryRows={}
	local function EntryRow(placeholder, buttonText, action)
		local row = vgui.Create("DPanel", controls)
		row:Dock(TOP); row:SetTall(U(36)); row.Paint = function()end
		local button = vgui.Create("DButton", row)
		button:Dock(RIGHT); button:SetWide(U(100)); button:DockMargin(U(6), U(2), 0, U(2)); button:SetText(buttonText);GAMEMODE:StyleShopButton(button,action=="create",true)
		local entry = vgui.Create("DTextEntry", row)
		entry:Dock(FILL); entry:DockMargin(0, U(2), 0, U(2)); entry:SetPlaceholderText(placeholder);StyleEntry(entry)
		button.DoClick = function() frame:SendAction(action, entry:GetValue()) end
  frame.EntryRows[#frame.EntryRows+1]={row,button,entry}
		return entry, button
	end
	frame.CreateEntry, frame.CreateButton = EntryRow("New guild name (3 to 32 bytes)", "Create", "create")
	frame.InviteEntry, frame.InviteButton = EntryRow("Exact player name or numeric user ID", "Invite", "invite")
	local footer = vgui.Create("DPanel", controls)
	footer:Dock(TOP); footer:SetTall(U(36)); footer.Paint = function()end
	local leave = vgui.Create("DButton", footer)
	leave:Dock(LEFT); leave:SetWide(U(100)); leave:SetText("Leave guild");self:StyleShopButton(leave,false,true); leave.DoClick = function() frame:SendAction("leave") end
	frame.LeaveButton = leave
	local refresh = vgui.Create("DButton", footer)
	refresh:Dock(RIGHT); refresh:SetWide(U(100)); refresh:SetText("Refresh");self:StyleShopButton(refresh,false,true); refresh.DoClick = function() frame:SendAction("list") end
	local help = vgui.Create("DLabel", footer)
	help:Dock(FILL); help:SetText("  !g <message> for human guild chat"); help:SetTextColor(muted); help:SetWrap(true);help:SetFont("ZSMenuScaledSmall")
	local pager = vgui.Create("DPanel", frame)
	pager:Dock(BOTTOM); pager:DockMargin(U(12), U(4), U(12), U(4)); pager:SetTall(U(28)); pager.Paint = function()end
	local previous = vgui.Create("DButton", pager)
	previous:Dock(LEFT); previous:SetWide(U(80)); previous:SetText("Previous");self:StyleShopButton(previous,false,true);frame.Previous=previous
	local nextPage = vgui.Create("DButton", pager)
	nextPage:Dock(RIGHT); nextPage:SetWide(U(80)); nextPage:SetText("Next");self:StyleShopButton(nextPage,false,true);frame.NextPage=nextPage
	local page = vgui.Create("DLabel", pager)
	page:Dock(FILL); page:SetContentAlignment(5); page:SetTextColor(muted);page:SetFont("ZSMenuScaledSmall")
	local rows = vgui.Create("DScrollPanel", frame)
	rows:Dock(FILL); rows:DockMargin(U(12), 0, U(12), 0)
	frame.Rows = rows
	local bar=rows:GetVBar()
	bar.Paint=function(_,width,height)surface.SetDrawColor(GAMEMODE.ShopColors.row)surface.DrawRect(0,0,width,height)end
	for _,button in ipairs({bar.btnUp,bar.btnDown,bar.btnGrip})do
	 if IsValid(button)then button.Paint=function(control,width,height)draw.RoundedBox(4,0,0,width,height,control:IsHovered()and GAMEMODE.ShopColors.hover or muted)end end
	end
	frame.Empty=vgui.Create("DLabel",rows:GetCanvas())frame.Empty:Dock(TOP)frame.Empty:SetTall(U(44))frame.Empty:SetWrap(true)
	frame.Empty:SetFont("ZSMenuScaledBody")frame.Empty:SetTextColor(muted)frame.Empty:SetText("No guilds match your search.")
	function frame:SendAction(action, text)
		if self.Pending then return end
		if type(text) == "string" and #text > 64 then self.Feedback = "Keep names within 64 bytes."; return end
		if Request(action, text) then self.Pending = RealTime() + 3;self.Feedback=nil;self.NextRefresh=0 end
	end
	function frame:RebuildGuildRows()
		local query = string.lower(search:GetValue())
		if self.FilterQuery ~= query or self.FilterSource ~= self.Guilds then
			self.FilterQuery, self.FilterSource, self.Filtered = query, self.Guilds, {}
			for _, guild in ipairs(self.Guilds) do if string.find(string.lower(guild.name), query, 1, true) then self.Filtered[#self.Filtered + 1] = guild end end
		end
		local pages = math.max(1, math.ceil(#self.Filtered / 32))
		self.Page = math.Clamp(self.Page, 1, pages)
		if self.GuildIDSource~=self.Guilds then
			self.GuildIDSource=self.Guilds;self.GuildByID={}
			for _,guild in ipairs(self.Guilds)do self.GuildByID[guild.id]=guild end
		end
		local first=(self.Page-1)*32
		local visible=math.min(32,#self.Filtered-first)
		for index=1,visible do
			local guild=self.Filtered[first+index]
			local button=self.GuildRows[index]
			if not IsValid(button)then
				button=rows:Add("DButton");button:Dock(TOP);button:SetTall(U(40));button:DockMargin(0,0,0,U(4));button:SetZPos(index)
				GAMEMODE:StyleShopButton(button,false,true)button:SetFont("ZSMenuScaledBody")
				button.DoClick=function(control)if control.Guild then self:SendAction("join",control.Guild.name)end end
				self.GuildRows[index]=button
			end
			local caption=guild.name.."   "..guild.members.."/"..self.Maximum.." members"..(guild.owner and "   OWNER" or "")
			if button.Caption~=caption then button.Caption=caption;button:SetText(caption);button:SetTooltip(caption)end
			button.Guild=guild;if not button:IsVisible()then button:SetVisible(true)end
		end
		for index=visible+1,#self.GuildRows do local button=self.GuildRows[index];button.Guild=nil;if button:IsVisible()then button:SetVisible(false)end end
		if self.Empty:IsVisible()~=(visible==0)then self.Empty:SetVisible(visible==0)end
		Enable(previous,self.Page>1);Enable(nextPage,self.Page<pages)
		local caption=self.Page.." / "..pages
		if self.PageCaption~=caption then self.PageCaption=caption;page:SetText(caption)end
		self.NextRefresh=0
	end
	search.OnChange = function() frame.Page = 1; frame:RebuildGuildRows() end
	previous.DoClick = function() frame.Page = frame.Page - 1; frame:RebuildGuildRows() end
	nextPage.DoClick = function() frame.Page = frame.Page + 1; frame:RebuildGuildRows() end
	local nativeThink=frame.Think
	frame.Think = function(panel)
		if not panel:IsVisible()then return end
		if nativeThink then nativeThink(panel)end
		local now = RealTime()
		if now < (panel.NextRefresh or 0) then return end
		panel.NextRefresh = now + 0.1
		if not IsValid(MySelf) then panel:Remove(); return end
		if panel.Pending and now >= panel.Pending then panel.Pending = nil; panel.Feedback = "No response. Try again." end
		local id, human, owner = GAMEMODE:GetGuildID(MySelf), MySelf:Team() == TEAM_HUMAN, false
		local available = not panel.Pending and now >= nextRequest
		local guild=panel.GuildByID[id];owner=guild and guild.owner or false
		if panel.CreateCost~=panel.Cost then panel.CreateCost=panel.Cost;panel.CreateButton:SetText("Create (" .. panel.Cost .. ")")end
		Enable(panel.CreateButton,human and id == 0 and available and MySelf:GetPoints() >= panel.Cost and (not panel.AdminOnly or MySelf:IsAdmin()))
		Enable(panel.InviteButton,human and owner and available)
		Enable(panel.LeaveButton,id > 0 and available)
		Enable(refresh,available)
		for _,button in ipairs(panel.GuildRows)do if button.Guild then Enable(button,human and id==0 and button.Guild.members<panel.Maximum and available)end end
		local caption=panel.Feedback or panel.Pending and "Waiting for server..." or #panel.Guilds.." guilds. Select one to request membership; the owner must approve with an invitation."
		if panel.StatusCaption~=caption then panel.StatusCaption=caption;status:SetText(caption)end
	end
	function frame:ApplyScale()
  if self.AppliedScale==GAMEMODE.MenuScale then return end
  self.AppliedScale=GAMEMODE.MenuScale
  self:DockPadding(U(12),U(82),U(12),U(12))
  header:SetPos(U(16),U(26))header:SetTall(U(28))
  status:DockMargin(U(12),U(10),U(12),U(6))status:SetTall(U(42))
  search:DockMargin(U(12),0,U(12),U(8))search:SetTall(U(30))
  controls:DockMargin(U(12),U(4),U(12),U(12))controls:SetTall(U(114))
  for _,parts in ipairs(self.EntryRows)do
   parts[1]:SetTall(U(36))parts[2]:SetWide(U(100))parts[2]:DockMargin(U(6),U(2),0,U(2))parts[3]:DockMargin(0,U(2),0,U(2))
  end
  for _,entry in ipairs({search,self.CreateEntry,self.InviteEntry})do if entry.ApplySchemeSettings then entry:ApplySchemeSettings()end end
  footer:SetTall(U(36))leave:SetWide(U(100))refresh:SetWide(U(100))
  pager:DockMargin(U(12),U(4),U(12),U(4))pager:SetTall(U(28))previous:SetWide(U(80))nextPage:SetWide(U(80))
  rows:DockMargin(U(12),0,U(12),0)bar:SetWide(U(16))self.Empty:SetTall(U(44))
  for _,button in ipairs(self.GuildRows)do button:SetTall(U(40))button:DockMargin(0,0,0,U(4))end
 end
 self:CreateScaledMenuCloseButton(frame)
 RememberGuildData(frame);frame:RebuildGuildRows(); Show(frame)
	return frame
end

hook.Add("OnScreenSizeChanged","ZSGuildMenuLayout",function()local frame=GAMEMODE.ZSGuildFrame if IsValid(frame)then Layout(frame)end end)

net.Receive("zs_guild_list", function()
	local count, maximum = net.ReadUInt(8), net.ReadUInt(7)
	local cost, adminOnly = net.ReadUInt(17), net.ReadBool()
	if count > 128 or maximum < 1 or maximum > 64 or cost > 100000 then return end
	local list = {}
	for index = 1, count do
		local id, name, members, owner = net.ReadUInt(31), net.ReadString(), net.ReadUInt(7), net.ReadBool()
		if id < 1 or #name > 32 or members > 64 then return end
		list[index] = {id = id, name = name, members = members, owner = owner}
	end
	local frame = GAMEMODE:OpenGuildMenu(list, maximum, cost, adminOnly)
	nextRequest = RealTime() + 0.5
	frame.Pending = nil
end)
net.Receive("zs_guild_result", function()
	local ok, message = net.ReadBool(), net.ReadString()
	nextRequest = RealTime() + 0.5
	local frame = GAMEMODE.ZSGuildFrame
	if IsValid(frame) then frame.Pending = nil; frame.Feedback = message end
	surface.PlaySound(ok and "buttons/button14.wav" or "buttons/button10.wav")
end)
net.Receive("zs_guild_chat", function()
	local guild, sender, message = net.ReadString(), net.ReadString(), net.ReadString()
	if #guild > 32 or #sender > 64 or #message > 240 then return end
	chat.AddText(accent, "[" .. guild .. "] ", color_white, sender .. ": ", muted, message)
end)
concommand.Add("zs_guild_menu", function() Request("list") end)
