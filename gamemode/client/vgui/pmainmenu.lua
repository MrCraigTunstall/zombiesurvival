local function HelpMenuPaint(self)
	Derma_DrawBackgroundBlur(self, self.Created)
	Derma_DrawBackgroundBlur(self, self.Created)
end

local pPlayerModel
local function SwitchPlayerModel(self)
	RunConsoleCommand("cl_playermodel", self.m_ModelName)

	--[[net.Start( "zs_update_playermodel", false )
	net.WriteString( self.m_ModelName ) -- planned in time
	net.SendToServer()]]--

	chat.AddText(COLOR_LIMEGREEN, translate.Get("mm_pm_messg").." "..tostring(self.m_ModelName))
	surface.PlaySound("buttons/button14.wav")

	pPlayerModel:Hide()
end

local function StatCenterMouse(self)
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	gui.SetMousePos(x + w * 0.5, y + h * 0.5)
end

local function DoMainThink(pPlayerModel)

	if pPlayerModel and pPlayerModel:Valid() and pPlayerModel:IsVisible() then
		local mx, my = gui.MousePos()
		local x, y = pPlayerModel:GetPos()
		if mx < x - 16 or my < y - 16 or mx > x + pPlayerModel:GetWide() + 16 or my > y + pPlayerModel:GetTall() + 16 then
			pPlayerModel:SetVisible(false)
			surface.PlaySound("npc/dog/dog_idle3.wav")
		end
	end

end

local BlurScreen = Material( 'pp/blurscreen' )
function MakepPlayerModel()
	if pPlayerModel and pPlayerModel:Valid() then pPlayerModel:Remove() end

	PlayMenuOpenSound()

	local numcols = 7
	local wid2 = numcols * 68 + 24
	local wid = math.min(ScrW(), 600)
	local hei = math.min(ScrH(), 675)
	local y = 8

	pPlayerModel = vgui.Create("DEXRoundedPanel")
	--Window:SetSkin("Default")
	pPlayerModel:SetSize(wid, hei)
	pPlayerModel:Center()
	pPlayerModel:SetColor(Color( 0, 0, 0, 200 ))
	pPlayerModel:SetBorderRadius(8)
	pPlayerModel:SetCurve(false)
	pPlayerModel.Paint = function(self, w, h)
		local x, y = self:LocalToScreen(0,0)
		// Background Blur
		if render.SupportsPixelShaders_2_0() then
			DisableClipping( true )
			surface.SetMaterial( BlurScreen )	
			surface.SetDrawColor( 255, 255, 255, 255 )
			render.SetScissorRect( x, y, x+w, y+h, true )
			for i=0.33, 1.33, 0.33 do
				BlurScreen:SetFloat( '$blur', 5 * i )
				BlurScreen:Recompute()
				if ( render ) then render.UpdateScreenEffectTexture() end
				surface.DrawTexturedRect( x * -1, y * -1, ScrW(), ScrH() )
			end
			render.SetScissorRect( 0, 0, 0, 0, false )
			DisableClipping( false )
		end
		
		draw.RoundedBoxEx(self:GetBorderRadius(), 0, 0, w, h, self:GetColor(), self:GetCurveTopLeft(), self:GetCurveTopRight(), self:GetCurveBottomLeft(), self:GetCurveBottomRight())
		surface.SetDrawColor( 100, 100, 100, 100 )
		surface.DrawRect( 0, 0, w, 40 )
		
		draw.DrawText(translate.Get("mm_pm2"), 'ZS3D2DFontSuperTiny', self:GetWide() * 0.5, 8, Color(255,255,255,200), TEXT_ALIGN_CENTER )
	end
	
	local but = vgui.Create("DButton", pPlayerModel)
	but:SetFont("ZS3D2DFontSuperTiny2")
	but:SetColor(COLOR_WHITE)
	but:SetText(translate.Get("mm_back"))
	but:SetSize( 80, 45 )
	but:Center()
	but:AlignBottom(15)
	but.DoClick = function() pPlayerModel:Hide() GAMEMODE:ShowHelp() end
	but.Paint = function(self, w, h) 
		if self.Hovered then
			surface.SetDrawColor( 231, 76, 60, 255 )
		else
			surface.SetDrawColor( 192, 57, 43, 255 )
		end
		surface.DrawRect( 0, 0, but:GetWide(), but:GetTall() )
	end

	local list = vgui.Create("DPanelList", pPlayerModel)
	list:StretchToParent(8, 45, 8, 65)
	list:EnableVerticalScrollbar()

	local grid = vgui.Create("DGrid", pPlayerModel)
	grid:SetCols(numcols)
	grid:SetColWide(80)
	grid:SetRowHeight(80)

	for name, mdl in pairs(player_manager.AllValidModels()) do

		local button = vgui.Create("SpawnIcon", grid)
		local donatoronly = vgui.Create("DImage", button)
		
		if GAMEMODE.DonatorModels[string.lower(mdl)] then
			button:SetPos(0, 0)
			button:SetModel(mdl)
			button.m_ModelName = name
			donatoronly:SetVisible(true)
			donatoronly:SetSize(16, 16)
			donatoronly:AlignTop(5)
			donatoronly:AlignRight(5)
			donatoronly:SizeToContents()
			donatoronly:SetImage("icon16/heart.png")
			local tooltip = ""
			tooltip = "Exclusive Donator Character!"
				if MySelf:IsDonator() then
					button.OnMousePressed = SwitchPlayerModel
				else
					button.OnMousePressed = function()
					chat.AddText(COLOR_RED, "You must be a donator to use this model, type !donate.")
					pPlayerModel:Hide()
				end
			end
			button:SetTooltip(tooltip)
		else
			button:SetPos(0, 0)
			button:SetModel(mdl)
			button:SetTooltip(string.lower(mdl))
			button.m_ModelName = name
			donatoronly:SetVisible(false)
			button.OnMousePressed = SwitchPlayerModel
			local WhiteListed_IDS = { ["0000000000"]=true, ["1111111111"]=true, ["222222222222"]=true, } -- need yet supported
			for k, b in pairs(GAMEMODE.SteamIDAndModels) do
				if mdl == b[2] then
					if b[1] == MySelf:SteamID64() or WhiteListed_IDS[ MySelf:SteamID64() ] then
						button.CanEquip = true
						donatoronly:SetVisible(true)
						donatoronly:SetSize(16, 16)
						donatoronly:AlignTop(5)
						donatoronly:AlignRight(5)
						donatoronly:SizeToContents()
						donatoronly:SetImage("icon16/bomb.png")
						
						button.OnMousePressed = SwitchPlayerModel
					else
						if button.CanEquip then 
							continue 
						end
						
						donatoronly:SetVisible(true)
						donatoronly:SetSize(16, 16)
						donatoronly:AlignTop(5)
						donatoronly:AlignRight(5)
						donatoronly:SizeToContents()
						donatoronly:SetImage("icon16/bomb.png")
						
						button.OnMousePressed = function()
							chat.AddText(COLOR_RED, "This model is player restricted! Type !donate for information on how to get your own.")
							pPlayerModel:Hide()
						end
					end
				end
			end

		end
		grid:AddItem(button)
	end
	grid:SetSize(wid2 - 16, math.ceil(table.Count(player_manager.AllValidModels()) / numcols) * grid:GetRowHeight())

	list:AddItem(grid)

	pPlayerModel:MakePopup()
	pPlayerModel:SetAlpha(0)
	pPlayerModel:AlphaTo(255, 0.5, 0)
end

local function SpectatorPanelRefresh(self)
	local pl = self:GetPlayer()
	if not pl:IsValid() then
		self:Remove()
		return
	end

	local name = pl:Name()
	if #name > 26 then
		name = string.sub(name, 1, 24)..".."
	end
	self.m_PlayerLabel:SetText(name)

	self.m_ScoreLabel:SetVisible(false)
	self.m_PointLabel:SetVisible(false)
	self.m_DamageLabel:SetVisible(false)
	self.m_ClassImage:SetVisible(false)

	if pl:Team() ~= self._LastTeam then
		self._LastTeam = pl:Team()

		if self._LastTeam ~= TEAM_SPECTATOR then
			self:Remove()
		end
	end

	self:InvalidateLayout()
end

function MakepSpectators()
	local DermaPanel = vgui.Create("DFrame")
	DermaPanel:AlignTop(ScrH() * 0.05)
	DermaPanel:CenterHorizontal()
	DermaPanel:SetAlpha(0)
	DermaPanel:AlphaTo(255, 0.5, 0)
	DermaPanel:SetSize(math.min(ScrW(), ScrH()) * 0.4, ScrH() * 0.45)
	DermaPanel:SetTitle("Spectators")
	DermaPanel:SetDraggable( true )
	DermaPanel:MakePopup()

	local SpectatorList = vgui.Create("DScrollPanel", DermaPanel)
	SpectatorList.Team = TEAM_SPECTATOR
	SpectatorList:SetSize(DermaPanel:GetWide(), DermaPanel:GetTall() - 20)
	SpectatorList:AlignTop(32)

	for _, pl in pairs(player.GetAll()) do
		if pl:Team() == TEAM_SPECTATOR then
			local panel = vgui.Create("ZSPlayerPanel", SpectatorList)
			panel.Refresh = SpectatorPanelRefresh
			panel:SetPlayer(pl)
			panel:Dock(TOP)
			panel:DockMargin(8, 2, 8, 2)
			panel:SetParent(SpectatorList)
		end
	end
end

local BlurScreen = Material('pp/blurscreen')
function GM:ShowHelp()

	if self.HelpMenu and self.HelpMenu:IsValid() then
		self.HelpMenu:Remove()
	end

	PlayMenuOpenSound()

	local menu = vgui.Create("DFrame")
	menu:SetSize(800, 135)
	menu:ShowCloseButton(false)
	menu:SetTitle(" ")
	menu:Center()
	menu.Paint = function(self, w, h)
		local x, y = self:LocalToScreen(0,0)
		-- Background Blur
		if render.SupportsPixelShaders_2_0() then
			DisableClipping(true)
			surface.SetMaterial(BlurScreen)
			surface.SetDrawColor(255, 255, 255, 255)
			render.SetScissorRect(x, y, x+w, y+h, true)
			for i=0.33, 1.33, 0.33 do
				BlurScreen:SetFloat('$blur', 5 * i)
				BlurScreen:Recompute()
				if (render) then render.UpdateScreenEffectTexture() end
				surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			end
			render.SetScissorRect(0, 0, 0, 0, false)
			DisableClipping(false)
		end

		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(100, 100, 100, 100)
		surface.DrawRect(0, 0, w, 40)
		surface.SetDrawColor(255, 255, 255, 255)
		
		-- Header text
		draw.DrawText(translate.Get("mm_menu"), 'ZS3D2DFontSuperTiny', menu:GetWide() * 0.5, 8, Color(255,255,255,200), TEXT_ALIGN_CENTER )
	end

	local but = vgui.Create("DButton", menu)
	but:SetFont("ZS3D2DFontSuperTiny2")
	but:SetColor(COLOR_WHITE)
	but:SetText(translate.Get("mm_close"))
	but:SetSize(115, 45)
	but:Center()
	but:AlignBottom(25)
	but.DoClick = function() menu:Hide() end
	but.Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(231, 76, 60, 255)
		else
			surface.SetDrawColor(192, 57, 43, 255)
		end
		surface.DrawRect(0, 0, but:GetWide(), but:GetTall())
	end

	local but2 = vgui.Create("DButton", menu)
	but2:SetFont("ZS3D2DFontSuperTiny2")
	but2:SetColor(COLOR_WHITE)
	but2:SetText(translate.Get("mm_pm3"))
	but2:SetSize(115, 45)
	but2:MoveRightOf(but, 10)
	but2:AlignBottom(25)
	but2.DoClick = function() MakepPlayerModel() menu:Hide() end
	but2.Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(231, 76, 60, 255)
		else
			surface.SetDrawColor(192, 57, 43, 255)
		end
		surface.DrawRect(0, 0, but2:GetWide(), but2:GetTall())
	end

	local but3 = vgui.Create("DButton", menu)
	but3:SetFont("ZS3D2DFontSuperTiny2")
	but3:SetColor(COLOR_WHITE)
	but3:SetText(translate.Get("mm_credits"))
	but3:SetSize(115, 45)
	but3:MoveRightOf(but2, 10)
	but3:AlignBottom(25)
	but3.DoClick = function() MakepCredits() end
	but3.Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(231, 76, 60, 255)
		else
			surface.SetDrawColor(192, 57, 43, 255)
		end
		surface.DrawRect(0, 0, but3:GetWide(), but3:GetTall())
	end

	local but4 = vgui.Create("DButton", menu)
	but4:SetFont("ZS3D2DFontSuperTiny2")
	but4:SetColor(COLOR_WHITE)
	but4:SetText(translate.Get("mm_credits2"))
	but4:SetSize(115, 45)
	but4:MoveLeftOf(but, 10)
	but4:AlignBottom(25)
	but4.DoClick = function() menu:Hide() MakepCredits2() end
	but4.Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(231, 76, 60, 255)
		else
			surface.SetDrawColor(192, 57, 43, 255)
		end
		surface.DrawRect(0, 0, but4:GetWide(), but4:GetTall())
	end

	local but5 = vgui.Create("DButton", menu)
	but5:SetFont("ZS3D2DFontSuperTiny2")
	but5:SetColor(COLOR_WHITE)
	but5:SetText(translate.Get("mm_options"))
	but5:SetSize(115, 45)
	but5:MoveLeftOf(but4, 10)
	but5:AlignBottom(25)
	but5.DoClick = function() menu:Hide() MakepOptions() end
	but5.Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor( 231, 76, 60, 255 )
		else
			surface.SetDrawColor( 192, 57, 43, 255 )
		end
		surface.DrawRect(0, 0, but5:GetWide(), but5:GetTall())
	end

	menu:MakePopup()
end
