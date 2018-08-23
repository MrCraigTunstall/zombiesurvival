-- Custom Class Menu by Mka0207 and neithque.
-- Altered to use class icons etc.
CreateClientConVar("zs_bossclass", "", true, true)

local draw_SimpleText = draw.SimpleText
local draw_RoundedBox = draw.RoundedBox
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local ScrW = ScrW
local ScrH = ScrH

local function SortDamage(weapon)
	for index, slot in pairs( weapons.GetStored( weapon ) ) do
		if index == "MeleeDamage" then
			return ", DMG : "..slot
		elseif index == "PounceDamage" then
			return ", DMG : "..slot
		elseif index == "PhysicsForce" then
			return ", FORCE : "..slot
		end
	end
	
	return ""
end

ZombieFont1 = "ZSHUDFontSmall"
function GM:OpenClassSelect(bossmode)

	local classImagesMaterials = {}

	if not IsValid(zombieFrame) then
		local zombieTable = {}
		topFrame = vgui.Create("DPanel" )
		topFrame:SetSkin("Default")
		topFrame:SetPos(0,0)
		topFrame:SetSize(ScrW(),ScrH()*0.1)
		function topFrame:Paint()
			draw_RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
		end
		
		local topFrameP = vgui.Create("DPanel", topFrame)
		topFrameP:SetPos(0, 0)
		topFrameP:SetSize(topFrame:GetWide(), topFrame:GetTall())
		topFrameP.Paint = function(self)
			draw_SimpleText(translate.Get("classes_undeadclasses"), ZombieFont1,topFrame:GetWide()*0.3, 30, Color(186,186,186), TEXT_ALIGN_LEFT)
			draw_SimpleText(translate.Get("classes_chooseresawn"), ZombieFont1,topFrame:GetWide()*0.3, 50, Color(146,146,146), TEXT_ALIGN_LEFT )
		end

		
		zombieFrame = vgui.Create("DPanel" )
		zombieFrame:SetSkin("Default")
		zombieFrame:SetPos(0, ScrH()*0.2)
		zombieFrame:SetSize(ScrW(),ScrH()*0.6)
		zombieFrame:MakePopup()
		function zombieFrame:Paint()
			draw_RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
		end

		normalZombieScrollPanel = vgui.Create( "DScrollPanel", zombieFrame )
		normalZombieScrollPanel:SetSize(zombieFrame:GetWide()-10, zombieFrame:GetTall()-50 )
		normalZombieScrollPanel:SetPos(10, 50)
		normalZombieScrollPanel:Show()

		bossZombieScrollPanel = vgui.Create( "DScrollPanel", zombieFrame )
		bossZombieScrollPanel:SetSize(zombieFrame:GetWide()-10, zombieFrame:GetTall()-50 )
		bossZombieScrollPanel:SetPos(10, 50)
		bossZombieScrollPanel:Hide()

		local normalButton = vgui.Create( "DButton", zombieFrame )
		normalButton:SetSize( 320, 30 )
		normalButton:SetPos( zombieFrame:GetWide()/2-420, 10 )
		normalButton:SetText(translate.Get("normal_selection"))
		normalButton.DoClick = function()
			bossZombieScrollPanel:Hide()	
			normalZombieScrollPanel:Show()
		end

		local bossButton = vgui.Create( "DButton", zombieFrame )
		bossButton:SetSize( 320, 30 )
		bossButton:SetPos( zombieFrame:GetWide()/2, 10 )
		bossButton:SetText(translate.Get("boss_selection"))
		bossButton.DoClick = function()
			normalZombieScrollPanel:Hide()
			bossZombieScrollPanel:Show()
		end

		local mutationButton = vgui.Create( "DButton", zombieFrame )
		mutationButton:SetSize(320, 30)
		mutationButton:SetPos( zombieFrame:GetWide()/2+400, 10 )
		mutationButton:SetText(translate.Get("mutations_selection"))
		mutationButton.DoClick = function()
			zombieFrame:Remove()
			topFrame:Remove()
			MakepMutationShop()
		end


		local classNameC = {}
		for k, v in pairs( GAMEMODE.ZombieClasses ) do
			if isnumber(k) and k == v.Index and not table.HasValue(classNameC,v.TranslationName) then
				table.insert(classNameC,v.TranslationName)
				
				if not v.Boss and not v.Hidden or v.CanUse and v:CanUse(MySelf) then
					if classImagesMaterials[k] == nil and v.Icon then
						classImagesMaterials[k] = Material(v.Icon,"noclamp")
					end

					local nButton = vgui.Create( "DButton", normalZombieScrollPanel )
					nButton:SetSize( normalZombieScrollPanel:GetWide(), 100 )
					nButton:SetPos(0,10)
					nButton:SetText( "" )
					nButton:Dock(TOP)
					nButton:SetToolTip(translate.Get(v.Description))
					local colorOffs = 0
					nButton.Paint = function( self, w, h )
						if self:IsHovered() then
							colorOffs = 40
						else
							colorOffs = 0
						end
						if gamemode.Call("IsClassUnlocked", v.Index) or LocalPlayer():GetZombieClass() == v.Index then
							draw_RoundedBox( 6,w*0.3, 0, 72, 72, Color(27+colorOffs,187+colorOffs,4+colorOffs) )
							draw_SimpleText( translate.Get(v.TranslationName), ZombieFont1, w*0.3+100, 10, Color(23+colorOffs,180+colorOffs,6+colorOffs), TEXT_ALIGN_LEFT )
						else
							draw_RoundedBox( 6,w*0.3, 0, 72, 72, Color(187+colorOffs,27+colorOffs,4+colorOffs) )
							draw_SimpleText( translate.Get(v.TranslationName).." ("..translate.Format("unlocked_on_wave_x", v.Wave)..")", ZombieFont1, w*0.3+100, 10, Color(180+colorOffs,23+colorOffs,6+colorOffs), TEXT_ALIGN_LEFT )
						end
						if v.Help then
							draw_SimpleText( translate.Get(v.Help), "Default", w*0.3+100, 50, Color(185+colorOffs,186+colorOffs,182+colorOffs), TEXT_ALIGN_LEFT )
						end
						draw_SimpleText("HP : "..v.Health..", SPEED : "..v.Speed..SortDamage(v.SWEP), "Default", w*0.3+100, 35, Color(185+colorOffs,186+colorOffs,182+colorOffs), TEXT_ALIGN_LEFT )
						if classImagesMaterials[k] then
							surface_SetDrawColor( 255, 255, 255, 255 )
							surface_SetMaterial(classImagesMaterials[k])
							surface_DrawTexturedRect( w*0.3+4, 4, 64, 64 )
						end					
					end
					nButton.DoClick = function()
						RunConsoleCommand("zs_class", v.Name, GAMEMODE.SuicideOnChangeClass and "1" or "0")
						surface.PlaySound("buttons/button15.wav")

						zombieFrame:Remove()
						topFrame:Remove()
					end

				end

				if v.Boss then
					if classImagesMaterials[k] == nil and v.Icon then
						classImagesMaterials[k] = Material(v.Icon,"noclamp")
					end
					
					local bButton = vgui.Create( "DButton", bossZombieScrollPanel )
					bButton:SetSize( bossZombieScrollPanel:GetWide(), 100 )
					bButton:SetPos(0,10)
					bButton:SetText( "" )
					bButton:Dock(TOP)
					bButton:SetToolTip(translate.Get(v.Description))
					bButton.Paint = function( self, w, h )
						if self:IsHovered() then
							colorOffs = 40
						else
							colorOffs = 0
						end
						draw_RoundedBox( 6,w*0.3, 0, 72, 72, Color(27+colorOffs,187+colorOffs,4+colorOffs) )
						draw_SimpleText( translate.Get(v.TranslationName), ZombieFont1, w*0.3+100, 10, Color(23+colorOffs,180+colorOffs,6+colorOffs), TEXT_ALIGN_LEFT )
						if v.Help then
							draw_SimpleText( translate.Get(v.Help), "Default", w*0.3+100, 50, Color(185+colorOffs,186+colorOffs,182+colorOffs), TEXT_ALIGN_LEFT )
						end
						draw_SimpleText( "HP : "..v.Health..", SPEED : "..v.Speed..SortDamage(v.SWEP), "Default", w*0.3+100, 35, Color(185+colorOffs,186+colorOffs,182+colorOffs), TEXT_ALIGN_LEFT )
						if classImagesMaterials[k] then
							surface_SetDrawColor( 255, 255, 255, 255 )
							surface_SetMaterial(classImagesMaterials[k])
							surface_DrawTexturedRect( w*0.3+4, 4, 64, 64 )
						end									
					end
					bButton.DoClick = function()
						RunConsoleCommand("zs_bossclass", v.Name)
						GAMEMODE:CenterNotify(translate.Format("boss_class_select", v.Name))
						
						surface.PlaySound("buttons/button15.wav")
						zombieFrame:Remove()
						topFrame:Remove()
					end
				end
			end
		end
	end
end

local function BossTypeDoClick(self)
	GAMEMODE:OpenClassSelect(true)
end