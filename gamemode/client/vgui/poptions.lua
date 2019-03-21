local BlurScreen = Material('pp/blurscreen')
local tab = Color(100, 100, 100, 100)
function MakepOptions()
	PlayMenuOpenSound()

	if pOptions then
		pOptions:SetAlpha(0)
		pOptions:AlphaTo(255, 0.15, 0)
		pOptions:SetVisible(true)
		pOptions:MakePopup()
		return
	end

	local Window = vgui.Create("DEXRoundedPanel")
	local wide = math.min(ScrW(), 600)
	local tall = math.min(ScrH(), 675)
	Window:SetSize(wide, tall)
	Window:Center()
	Window:SetColor(Color(0, 0, 0, 200))
	Window:SetBorderRadius(8)
	Window:SetCurve(false)
	Window.Paint = function(self, w, h)
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
		
		draw.RoundedBoxEx(self:GetBorderRadius(), 0, 0, w, h, self:GetColor(), self:GetCurveTopLeft(), self:GetCurveTopRight(), self:GetCurveBottomLeft(), self:GetCurveBottomRight())
		surface.SetDrawColor(100, 100, 100, 100)
		surface.DrawRect(0, 0, w, 40)
		
		draw.DrawText(translate.Get("mm_options"), 'ZS3D2DFontSuperTiny', self:GetWide() * 0.5, 8, Color(255,255,255,200), TEXT_ALIGN_CENTER)
	end
	
	local but = vgui.Create("DButton", Window)
	but:SetFont("ZS3D2DFontSuperTiny")
	but:SetColor(COLOR_WHITE)
	but:SetText(translate.Get("mm_back"))
	but:SetSize(80, 45)
	but:Center()
	but:AlignBottom(15)
	but.DoClick = function() Window:Hide() GAMEMODE:ShowHelp() end
	but.Paint = function(self, w, h) 
		if self.Hovered then
			surface.SetDrawColor( 231, 76, 60, 255 )
		else
			surface.SetDrawColor( 192, 57, 43, 255 )
		end
		surface.DrawRect(0, 0, but:GetWide(), but:GetTall())
	end
	
	pOptions = Window

	local y = 8
	
	local propertysheet = vgui.Create("DPropertySheet", pOptions)
	propertysheet:SetSize(550, 525)
	propertysheet:SetPos(25, 50)
	propertysheet:SetPadding(1)
	propertysheet.Paint = function()
		for k, v in pairs(propertysheet.Items) do
			if (!v.Tab) then continue end
			
			v.Tab.Paint = function(self,w,h)
			end
		end
	end
	
	local weapon_options = vgui.Create("DPanelList", propertysheet)
	weapon_options:EnableVerticalScrollbar()
	weapon_options:EnableHorizontal(false)
	weapon_options:SetSize(propertysheet:GetSize())
	weapon_options:SetPos(propertysheet:GetPos())
	weapon_options:SetPadding(8)
	weapon_options:SetSpacing(4)
	propertysheet:AddSheet(translate.Get("options_weapon"), weapon_options, "icon16/gun.png")
	
	local gameplay_list = vgui.Create("DPanelList", propertysheet)
	gameplay_list:EnableVerticalScrollbar()
	gameplay_list:EnableHorizontal(false)
	gameplay_list:SetSize(propertysheet:GetSize())
	gameplay_list:SetPos(propertysheet:GetPos())
	gameplay_list:SetPadding(8)
	gameplay_list:SetSpacing(4)
	propertysheet:AddSheet(translate.Get("options_gameplay"), gameplay_list, "icon16/bomb.png")
	
	local hud_options = vgui.Create("DPanelList", propertysheet)
	hud_options:EnableVerticalScrollbar()
	hud_options:EnableHorizontal(false)
	hud_options:SetSize(propertysheet:GetSize())
	hud_options:SetPos(propertysheet:GetPos())
	hud_options:SetPadding(8)
	hud_options:SetSpacing(4)
	propertysheet:AddSheet(translate.Get("options_visual"), hud_options, "icon16/eye.png")
	
	local sound_options = vgui.Create("DPanelList", propertysheet)
	sound_options:EnableVerticalScrollbar()
	sound_options:EnableHorizontal(false)
	sound_options:SetSize(propertysheet:GetSize())
	sound_options:SetPos(propertysheet:GetPos())
	sound_options:SetPadding(8)
	sound_options:SetSpacing(4)
	propertysheet:AddSheet(translate.Get("options_sound"), sound_options, "icon16/sound.png")
	
	local player_options = vgui.Create("DPanelList", propertysheet)
	player_options:EnableVerticalScrollbar()
	player_options:EnableHorizontal(false)
	player_options:SetSize(propertysheet:GetSize())
	player_options:SetPos(propertysheet:GetPos())
	player_options:SetPadding(8)
	player_options:SetSpacing(4)
	propertysheet:AddSheet(translate.Get("options_player"), player_options, "icon16/user.png")

	gamemode.Call("AddExtraOptions", gameplay_list, Window)
	gamemode.Call("AddExtraOptions", weapon_options, Window)
	gamemode.Call("AddExtraOptions", sound_options, Window)
	gamemode.Call("AddExtraOptions", player_options, Window)
	gamemode.Call("AddExtraOptions", hud_options, Window)


--[[
////////// gameplay_list //////////
]]--

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_movement_view_roll"))
	check:SetConVar("zs_movementviewroll")
	check:SizeToContents()
	gameplay_list:AddItem(check)



--[[
////////// weapon_options //////////
]]--

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_floating_score"))
	check:SetConVar("zs_nofloatingscore")
	check:SizeToContents()
	weapon_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_iron_sights_crosshair"))
	check:SetConVar("zs_ironsightscrosshair")
	check:SizeToContents()
	weapon_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_crosshair_rotate"))
	check:SetConVar("zs_nocrosshairrotate")
	check:SizeToContents()
	weapon_options:AddItem(check)
	
	
	weapon_options:AddItem(EasyLabel(Window, translate.Get"options_weapon_hud_mode") , "DefaultFontSmall", color_white)
	local dropdown = vgui.Create("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	dropdown:AddChoice("3D")
	dropdown:AddChoice("2D")
	dropdown:AddChoice("Both")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_weaponhudmode", value == "Both" and 2 or value == "2D" and 1 or 0)
	end
	dropdown:SetText(GAMEMODE.WeaponHUDMode == 2 and "Both" or GAMEMODE.WeaponHUDMode == 1 and "2D" or "3D")
	weapon_options:AddItem(dropdown)

--[[
////////// sound_options //////////
]]--

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_beats"))
	check:SetConVar("zs_beats")
	check:SizeToContents()
	sound_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_play_music"))
	check:SetConVar("zs_playmusic")
	check:SizeToContents()
	sound_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_intro_music"))
	check:SetConVar("zs_intro")
	check:SizeToContents()
	sound_options:AddItem(check)
	
	sound_options:AddItem(EasyLabel(Window, translate.Get"options_beatset_human"), "DefaultFontSmall", color_white)
	local dropdown = vgui.Create("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	for setname in pairs(GAMEMODE.Beats) do
		if setname ~= GAMEMODE.BeatSetHumanDefualt then
			dropdown:AddChoice(setname)
		end
	end
	dropdown:AddChoice("none")
	dropdown:AddChoice("default")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_beatset_human", value)
	end
	dropdown:SetText(GAMEMODE.BeatSetHuman == GAMEMODE.BeatSetHumanDefault and "default" or GAMEMODE.BeatSetHuman)
	sound_options:AddItem(dropdown)

	sound_options:AddItem(EasyLabel(Window, translate.Get"options_beatset_zombie"), "DefaultFontSmall", color_white)
	local dropdown = vgui.Create("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	for setname in pairs(GAMEMODE.Beats) do
		if setname ~= GAMEMODE.BeatSetZombieDefualt then
			dropdown:AddChoice(setname)
		end
	end
	dropdown:AddChoice("none")
	dropdown:AddChoice("default")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_beatset_zombie", value)
	end
	dropdown:SetText(GAMEMODE.BeatSetZombie == GAMEMODE.BeatSetZombieDefault and "default" or GAMEMODE.BeatSetZombie)
	sound_options:AddItem(dropdown)
	
	local slider = vgui.Create("DNumSlider", Window)
	slider:SetDecimals(0)
	slider:SetMinMax(0, 100)
	slider:SetConVar("zs_beatsvolume")
	slider:SetText(translate.Get("options_music_volume"))
	slider:SizeToContents()
	sound_options:AddItem(slider)



--[[
////////// player_options //////////
]]--

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_discord"))
	check:SetConVar("zs_nodiscord")
	check:SizeToContents()
	player_options:AddItem(check)
	
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_redeem"))
	check:SetConVar("zs_noredeem")
	check:SizeToContents()
	player_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_bandit"))
	check:SetConVar("zs_nobandit")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_always_volunteer"))
	check:SetConVar("zs_alwaysvolunteer")
	check:SizeToContents()
	player_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_boss_pick"))
	check:SetConVar("zs_nobosspick")
	check:SizeToContents()
	player_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_suicide_on_change"))
	check:SetConVar("zs_suicideonchange")
	check:SizeToContents()
	player_options:AddItem(check)


--[[
////////// hud_options //////////
]]--

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_old_hud"))
	check:SetConVar("zs_classichud")
	check:SizeToContents()
	hud_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_ars_crate"))
	check:SetConVar("zs_noarscrate")
	check:SizeToContents()
	hud_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_status_ars_crate"))
	check:SetConVar("zs_nostatusarscrate")
	check:SizeToContents()
	hud_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_no_resupply"))
	check:SetConVar("zs_noresupply")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_film_mode"))
	check:SetConVar("zs_filmmode")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_post_processing"))
	check:SetConVar("zs_postprocessing")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_film_grain"))
	check:SetConVar("zs_filmgrain")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_color_mod"))
	check:SetConVar("zs_colormod")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_draw_pain_flash"))
	check:SetConVar("zs_drawpainflash")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_auras"))
	check:SetConVar("zs_auras")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_damage_floaters"))
	check:SetConVar("zs_damagefloaters")
	check:SizeToContents()
	hud_options:AddItem(check)

	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_always_show_nails"))
	check:SetConVar("zs_alwaysshownails")
	check:SizeToContents()
	hud_options:AddItem(check)
	
	local check = vgui.Create("DCheckBoxLabel", Window)
	check:SetText(translate.Get("options_show_old_baseoutlinedhud_hud"))
	check:SetConVar("zs_oldbaseoutlinedhud")
	check:SizeToContents()
	hud_options:AddItem(check)
		
	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_proprotation"), "DefaultFontSmall", color_white)
	dropdown = vgui.Create("DComboBox", Window)
	dropdown:SetMouseInputEnabled(true)
	dropdown:AddChoice("No snap")
	dropdown:AddChoice("15 degrees")
	dropdown:AddChoice("30 degrees")
	dropdown:AddChoice("45 degrees")
	dropdown.OnSelect = function(me, index, value, data)
		RunConsoleCommand("zs_proprotationsnap", value == "15 degrees" and 15 or value == "30 degrees" and 30 or value == "45 degrees" and 45 or 0)
	end
	dropdown:SetText(GAMEMODE.PropRotationSnap == 15 and "15 degrees"
		or GAMEMODE.PropRotationSnap == 30 and "30 degrees"
		or GAMEMODE.PropRotationSnap == 45 and "45 degrees"
		or "No snap")
	gameplay_list:AddItem(dropdown)
	
	local slider = vgui.Create("DNumSlider", Window)
	slider:SetDecimals(0)
	slider:SetMinMax(0, 512)
	slider:SetConVar("zs_transparencyradius")
	slider:SetText(translate.Get("options_transparency_radius"))
	slider:SizeToContents()
	gameplay_list:AddItem(slider)

	local slider = vgui.Create("DNumSlider", Window)
	slider:SetDecimals(1)
	slider:SetMinMax(0, 255)
	slider:SetConVar("zs_filmgrainopacity")
	slider:SetText(translate.Get("options_film_grain"))
	slider:SizeToContents()
	gameplay_list:AddItem(slider)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_crosshair_p"))
	local colpicker = vgui.Create("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_crosshair_colr")
	colpicker:SetConVarG("zs_crosshair_colg")
	colpicker:SetConVarB("zs_crosshair_colb")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_crosshair_s"))
	local colpicker = vgui.Create("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_crosshair_colr2")
	colpicker:SetConVarG("zs_crosshair_colg2")
	colpicker:SetConVarB("zs_crosshair_colb2")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_hp_full"))
	local colpicker = vgui.Create("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_auracolor_full_r")
	colpicker:SetConVarG("zs_auracolor_full_g")
	colpicker:SetConVarB("zs_auracolor_full_b")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	gameplay_list:AddItem(EasyLabel(Window, translate.Get"options_hp_no"))
	local colpicker = vgui.Create("DColorMixer", Window)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker:SetConVarR("zs_auracolor_empty_r")
	colpicker:SetConVarG("zs_auracolor_empty_g")
	colpicker:SetConVarB("zs_auracolor_empty_b")
	colpicker:SetTall(72)
	gameplay_list:AddItem(colpicker)

	Window:SetAlpha(0)
	Window:AlphaTo(255, 0.5, 0)
	Window:MakePopup()
end