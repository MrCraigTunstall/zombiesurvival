-- Sometimes persistent ones don't get created.
local dummy = CreateClientConVar("_zs_dummyconvar", 1, false, false)
ZSClientConVars = ZSClientConVars or {Create = CreateClientConVar}
local oldCreateClientConVar = ZSClientConVars.Create
function CreateClientConVar(...)
	return oldCreateClientConVar(...) or dummy
end

include("shared.lua")
include("client/cl_playervoice.lua")
include("client/cl_traitcorpses.lua")
include("client/cl_traitdrunk.lua")
include("client/cl_traitdrone.lua")
include("client/cl_traitsnarks.lua")
include("client/cl_traitbarnaclerender.lua")
include("client/cl_weaponanimation.lua")
include("client/cl_playeranimation.lua")
include("client/cl_flashlight.lua")
include("client/cl_view.lua")
include("client/cl_propinput.lua")
include("client/cl_barricadeghosting.lua")
include("client/cl_draw.lua")
include("client/cl_util.lua")
include("client/cl_fonts.lua")
include("client/cl_hudstyle.lua")
include("client/cl_hudlayout.lua")
include("client/cl_options.lua")
include("client/cl_scoreboard.lua")
include("client/cl_targetid.lua")
include("client/cl_postprocess.lua")


include("meta/obj_entity_extend_cl.lua")
include("meta/obj_player_extend_cl.lua")
include("meta/obj_weapon_extend_cl.lua")

include("client/vgui/dgamestate.lua")
include("client/vgui/dteamcounter.lua")
include("client/vgui/dmodelpanelex.lua")
include("client/vgui/dammocounter.lua")
include("client/vgui/dteamheading.lua")
include("client/vgui/dmodelkillicon.lua")
include("client/vgui/dexroundedpanel.lua")
include("client/vgui/dexroundedframe.lua")
include("client/vgui/dexrotatedimage.lua")
include("client/vgui/dexnotificationslist.lua")
include("client/vgui/dexchanginglabel.lua")
include("client/vgui/mainmenu.lua")
include("client/vgui/optionscolormixer.lua")
include("client/vgui/poptions.lua")
include("client/cl_shopcatalogue.lua")
include("client/cl_shopui.lua")
include("client/cl_notificationdetails.lua")
include("client/vgui/pendboard.lua")
include("client/vgui/pweapons.lua")
include("client/cl_classselect.lua")
include("client/cl_voice.lua")
include("client/cl_weaponselect.lua")
include("client/cl_taunt.lua")
include("client/vgui/dshoptooltip.lua")
include("client/cl_mainmenu.lua")
include("client/cl_spectators.lua")
include("client/cl_playercolors.lua")
include("client/cl_playermodels.lua")
include("client/cl_help.lua")
include("client/cl_credits.lua")
include("client/cl_worthcart.lua")
include("client/cl_worthloadouts.lua")
include("client/vgui/dequipmentcounter.lua")
include("client/vgui/pworth.lua")
include("client/vgui/ppointshop.lua")
include("client/vgui/pmutationshop.lua")
include("client/cl_mutationshop.lua")
include("client/vgui/dpingmeter.lua")
include("client/vgui/dsidemenu.lua")
include("client/cl_humanmenu.lua")
include("client/cl_redeemmenu.lua")
include("client/cl_beaconmenu.lua")
include("client/cl_shadehud.lua")
include("client/cl_healthhud.lua")
include("client/cl_fearhud.lua")
include("client/cl_medicalaura.lua")
include("client/cl_roundendhud.lua")
include("client/cl_packuphud.lua")
include("client/cl_teleporthud.lua")
include("client/cl_breathhud.lua")
include("client/cl_preparationhud.lua")
include("client/cl_respawnhud.lua")
include("client/cl_purchasehud.lua")
include("client/cl_meleecrosshair.lua")
include("client/cl_mapvote.lua")
include("client/cl_keybinds.lua")
include("client/cl_propcreator.lua")
include("client/cl_weaponforge.lua")
include("client/cl_trader.lua")
include("client/cl_quests.lua")
include("client/cl_guilds.lua")
include("client/vgui/pcosmeticshop.lua")
include("client/cl_cosmetics.lua")
include("client/cl_returns.lua")
include("client/cl_beats.lua")
include("client/vgui/pkeybinds.lua")

include("client/cl_dermaskin.lua")
include("client/cl_deathnotice.lua")
include("client/cl_floatingscore.lua")
include("client/cl_hint.lua")
include("client/cl_extras.lua")

include("zombieescape/cl_zombieescape.lua")
include("zombieescape/cl_weaponselect.lua")

w, h = ScrW(), ScrH()

UsedMutations = {}

MySelf = MySelf or NULL
hook.Add("InitPostEntity", "GetLocal", function()
	MySelf = LocalPlayer()

	GAMEMODE.HookGetLocal = GAMEMODE.HookGetLocal or (function(g) end)
	gamemode.Call("HookGetLocal", MySelf)
	RunConsoleCommand("initpostentity")
end)

-- Remove when model decal crash is fixed.
function util.Decal()
end

-- Save on global lookup time.
local render = render
local surface = surface
local draw = draw
local cam = cam
local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local ScrW = ScrW
local ScrH = ScrH
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local TEAM_HUMAN = TEAM_HUMAN
local TEAM_REDEEMER = TEAM_REDEEMER
local TEAM_UNDEAD = TEAM_UNDEAD
local translate = translate

local COLOR_PURPLE = COLOR_PURPLE
local COLOR_GRAY = COLOR_GRAY
local COLOR_RED = COLOR_RED
local COLOR_DARKRED = COLOR_DARKRED
local COLOR_DARKGREEN = COLOR_DARKGREEN
local COLOR_GREEN = COLOR_GREEN
local COLOR_WHITE = COLOR_WHITE

local surface_SetFont = surface.SetFont
local surface_SetTexture = surface.SetTexture
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
local surface_PlaySound = surface.PlaySound

local draw_SimpleText = draw.SimpleText
local draw_SimpleTextBlurry = draw.SimpleTextBlurry
local draw_SimpleTextBlur = draw.SimpleTextBlur
local draw_GetFontHeight = draw.GetFontHeight



local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team
local E_meta = FindMetaTable("Entity")
local E_IsValid = E_meta.IsValid

GM.LifeStatsBrainsEaten = 0
GM.LifeStatsHumanDamage = 0
GM.LifeStatsBarricadeDamage = 0
GM.InputMouseX = 0
GM.InputMouseY = 0
GM.LastTimeDead = 0
GM.LastTimeAlive = 0
GM.HeartBeatTime = 0
GM.FOVLerp = 1
GM.HurtEffect = 0
GM.PrevHealth = 0
GM.SuppressArsenalTime = 0
GM.ZombieThirdPerson = false
GM.Beats = {}

GM.DeathFog = 0
GM.FogStart = 0
GM.FogEnd = 8000
GM.FogRed = 30
GM.FogGreen = 30
GM.FogBlue = 30

function GM:ClickedPlayerButton(pl, button)
end

function GM:CenterNotify(...)
	if self.CenterNotificationHUD and self.CenterNotificationHUD:Valid() then
		return self.CenterNotificationHUD:AddNotification(...)
	end
end

function GM:TopNotify(...)
	if self.TopNotificationHUD and self.TopNotificationHUD:Valid() then
		return self.TopNotificationHUD:AddNotification(...)
	end
end

function GM:_GUIMousePressed(mc)
	if self.HumanMenuPanel and self.HumanMenuPanel:Valid() and self.HumanMenuPanel:IsVisible() and self:IsHumanMenuKeyDown(MySelf) then
		local dir = gui.ScreenToVector(gui.MousePos())
		local ent = util.TraceLine({start = MySelf:EyePos(), endpos = MySelf:EyePos() + dir * self.CraftingRange, filter = MySelf, mask = MASK_SOLID}).Entity
		if ent:IsValid() and not ent:IsPlayer() and (ent:GetMoveType() == MOVETYPE_NONE or ent:GetMoveType() == MOVETYPE_VPHYSICS) and ent:GetSolid() == SOLID_VPHYSICS then
			if mc == MOUSE_LEFT then
				if ent == self.CraftingEntity then
					self.CraftingEntity = nil
				else
					self.CraftingEntity = ent
				end
			elseif mc == MOUSE_RIGHT and self.CraftingEntity and self.CraftingEntity:IsValid() then
				RunConsoleCommand("_zs_craftcombine", self.CraftingEntity:EntIndex(), ent:EntIndex())
				self.CraftingEntity = nil
			end
		end
	end
end

function GM:TryHumanPickup(pl, entity)
end

function GM:AddExtraOptions(list, window)
end

include("client/cl_chat.lua")

function GM:SpawnMenuEnabled()
	return false
end

function GM:SpawnMenuOpen()
	return false
end

function GM:ContextMenuOpen()
	return false
end

function GM:HUDWeaponPickedUp(wep)
end

function GM:_HUDWeaponPickedUp(wep)
	if MySelf:Team() ~= TEAM_UNDEAD and not wep.NoPickupNotification then
		self:Rewarded(wep:GetClass())
	end
end

function GM:HUDItemPickedUp(itemname)
end

function GM:HUDAmmoPickedUp(itemname, amount)
end

function GM:InitPostEntity()
	if not IsValid(self.HealthHUD) then
		self.HealthHUD = vgui.Create("ZSHealthArea")
	end

	self:FixWeaponBase()
	self:LocalPlayerFound()

	self:EvaluateFilmMode()

	timer.Simple(2, function() GAMEMODE:GetFogData() end)
end

function GM:SetupWorldFog()
	if self.DeathFog == 0 then return end

	local power = self.DeathFog
	local rpower = 1 - self.DeathFog

	local fogstart = self.FogStart * rpower
	local fogend = self.FogEnd * rpower + 150 * power
	local fogr = self.FogRed * rpower
	local fogg = self.FogGreen * rpower + 40 * power
	local fogb = self.FogBlue * rpower

	render.FogMode(1)

	render.FogStart(fogstart)
	render.FogEnd(fogend)
	render.FogColor(fogr, fogg, fogb)
	render.FogMaxDensity(1)

	return true
end

function GM:SetupSkyboxFog(skyboxscale)
	if self.DeathFog == 0 then return end

	local power = self.DeathFog
	local rpower = 1 - self.DeathFog

	local fogstart = self.FogStart * rpower
	local fogend = self.FogEnd * rpower + 150 * power
	local fogr = self.FogRed * rpower
	local fogg = self.FogGreen * rpower + 40 * power
	local fogb = self.FogBlue * rpower
	local fogdensity = 1 - power * 0.1

	render.FogMode(1)

	render.FogStart(fogstart * skyboxscale)
	render.FogEnd(fogend * skyboxscale)
	render.FogColor(fogr, fogg, fogb)
	render.FogMaxDensity(1)

	return true
end

function GM:PreDrawSkyBox()
	self.DrawingInSky = true
end

local matSky = CreateMaterial("SkyOverride", "UnlitGeneric", {["$basetexture"] = "color/white", ["$vertexcolor"] = 1, ["$vertexalpha"] = 1, ["$model"] = 1})
local colSky = Color(0, 30, 0)
function GM:PostDrawSkyBox()
	self.DrawingInSky = false

	if self.DeathFog == 0 then return end

	colSky.a = self.DeathFog * 230

	cam.Start3D(EyePos(), EyeAngles())
		render.SuppressEngineLighting(true)

		render.SetMaterial(matSky)

		render.DrawQuadEasy(Vector(0, 0, 10240), Vector(0, 0, -1), 20480, 20480, colSky, 0)
		render.DrawQuadEasy(Vector(0, 10240, 0), Vector(0, -1, 0), 20480, 20480, colSky, 0)
		render.DrawQuadEasy(Vector(0, -10240, 0), Vector(0, 1, 0), 20480, 20480, colSky, 0)
		render.DrawQuadEasy(Vector(10240, 0, 0), Vector(-1, 0, 0), 20480, 20480, colSky, 0)
		render.DrawQuadEasy(Vector(-10240, 0, 0), Vector(1, 0, 0), 20480, 20480, colSky, 0)

		render.SuppressEngineLighting(false)
	cam.End3D()
end

function GM:GetFogData()
	local fogstart, fogend = render.GetFogDistances()
	local fogr, fogg, fogb = render.GetFogColor()

	self.FogStart = fogstart
	self.FogEnd = fogend
	self.FogRed = fogr
	self.FogGreen = fogg
	self.FogBlue = fogb
end


function GM:OnReloaded()
	self.BaseClass.OnReloaded(self)

	self:LocalPlayerFound()
	self:EvaluateFilmMode()
end

-- The whole point of this is so we don't need to check if the local player is valid 1000 times a second.
function GM:LocalPlayerFound()
	self.Think = self._Think
	self.HUDShouldDraw = self._HUDShouldDraw
	self.CachedFearPower = self._CachedFearPower
	self.CalcView = self._CalcView
	self.ShouldDrawLocalPlayer = self._ShouldDrawLocalPlayer
	self.PostDrawOpaqueRenderables = self._PostDrawOpaqueRenderables
	self.PostDrawTranslucentRenderables = self._PostDrawTranslucentRenderables
	self.HUDPaint = self._HUDPaint
	self.HUDPaintBackground = self._HUDPaintBackground
	self.CreateMove = self._CreateMove
	self.PrePlayerDraw = self._PrePlayerDraw
	self.PostPlayerDraw = self._PostPlayerDraw
	self.InputMouseApply = self._InputMouseApply
	self.GUIMousePressed = self._GUIMousePressed
	self.HUDWeaponPickedUp = self._HUDWeaponPickedUp

	LocalPlayer().LegDamage = 0

	if render.GetDXLevel() >= 80 then
		self.RenderScreenspaceEffects = self._RenderScreenspaceEffects
	end
end


function GM:GetDynamicSpawning()
	return not GetGlobalBool("DynamicSpawningDisabled", false)
end

function GM:TrackLastDeath()
	if MySelf:Alive() then
		self.LastTimeAlive = CurTime()
	else
		self.LastTimeDead = CurTime()
	end
end

function GM:IsClassicMode()
	return GetGlobalBool("classicmode", false)
end

function GM:IsRedeemMode()
	return GetGlobalBool("redeemmode", false)
end

function GM:IsBabyMode()
	return GetGlobalBool("babymode", false)
end

function GM:PostRender()
	if self.m_ZombieVision and MySelf:IsValid() and MySelf:Team() ~= TEAM_HUMAN then

		local dlight = DynamicLight(MySelf:EntIndex())
		if dlight then
			dlight.Pos = MySelf:GetShootPos()
			dlight.r = 255
			dlight.g = 218
			dlight.b = 74
			dlight.Brightness = 0
			dlight.Size = 2048
			dlight.Decay = 900
			dlight.DieTime = CurTime() + 2
		end
	end
end

local lastwarntim = -1
local NextGas = 0
function GM:_Think()
	if self:GetEscapeStage() == ESCAPESTAGE_DEATH then
		self.DeathFog = math.min(self.DeathFog + FrameTime() / 5, 1)

		if CurTime() >= NextGas then
			NextGas = CurTime() + 0.01

			local eyepos = EyePos()

			local emitter = ParticleEmitter(eyepos)

			if emitter then
				for i=1, 3 do
					local randdir = VectorRand()
					randdir.z = math.abs(randdir.z)
					randdir:Normalize()
					local emitpos = eyepos + randdir * math.Rand(0, 1200)

					local particle = emitter:Add("particles/smokey", emitpos)
					if particle then
						particle:SetVelocity(randdir * math.Rand(8, 256))
						particle:SetAirResistance(16)
						particle:SetDieTime(math.Rand(2.2, 3.5))
						particle:SetStartAlpha(math.Rand(70, 90))
						particle:SetEndAlpha(0)
						particle:SetStartSize(1)
						particle:SetEndSize(math.Rand(150, 325))
						particle:SetRoll(math.Rand(0, 360))
						particle:SetRollDelta(math.Rand(-1, 1))
						particle:SetColor(0, math.Rand(20, 45), 0)
					end
				end

				emitter:Finish()
			end
		end
	elseif self.DeathFog > 0 then
		self.DeathFog = math.max(self.DeathFog - FrameTime() / 5, 0)
	end

	local health = MySelf:Health()
	if self.PrevHealth and health < self.PrevHealth then
		self.HurtEffect = math.min(self.HurtEffect + (self.PrevHealth - health) * 0.02, 1.5)
	elseif self.HurtEffect > 0 then
		self.HurtEffect = math.max(0, self.HurtEffect - FrameTime() * 0.65)
	end
	self.PrevHealth = health

	self:TrackLastDeath()

	local endtime = self:GetWaveActive() and self:GetWaveEnd() or self:GetWaveStart()
	if endtime ~= -1 then
		local timleft = math.max(0, endtime - CurTime())
		if timleft <= 10 and lastwarntim ~= math.ceil(timleft) then
			lastwarntim = math.ceil(timleft)
			if 0 < lastwarntim then
				surface_PlaySound("buttons/lightswitch2.wav")
			end
		end
	end

	local myteam = MySelf:Team()
	if myteam ~= TEAM_UNDEAD then self.RespawnHUDData = nil end

	self:PlayBeats(myteam, self:CachedFearPower())

	if myteam ~= TEAM_UNDEAD then
		local wep = MySelf:GetActiveWeapon()
		if wep:IsValid() and wep.GetIronsights and wep:GetIronsights() then
			self.FOVLerp = math.Approach(self.FOVLerp, wep.IronsightsMultiplier or 0.6, FrameTime() * 4)
		elseif self.FOVLerp ~= 1 then
			self.FOVLerp = math.Approach(self.FOVLerp, 1, FrameTime() * 5)
		end

	else
		self.HeartBeatTime = self.HeartBeatTime + (6 + self:CachedFearPower() * 5) * FrameTime()

		if not MySelf:Alive() then
			self:ToggleZombieVision(false)
		end
	end

	self:UpdatePlayerBoneAnimations()
end



local OSTintro = 0
local texHumanHealthBar = surface.GetTextureID("zombiesurvival/healthbar__human")
function GM:HumanHUD(screenscale)
	local h = ScrH()
	
	if GetConVar("zs_classichud"):GetBool() then
	self:DrawHealthBar(screenscale * 24, h - 272 * screenscale, MySelf:Health(), MySelf:GetMaxHealth(), texHumanHealthBar, screenscale, MySelf:GetPoisonDamage())
	end

	self:DrawPreparationHUD()

	self:DrawPurchaseHUD()
end

function GM:HUDPaint()
end

function GM:_HUDPaint()
	if self.FilmMode then return end

	local screenscale = BetterScreenScale()

	local myteam = MySelf:Team()
	

	if self:GetWave() > 0 and myteam ~= TEAM_SPECTATOR then
		self:DrawFearMeter(self:CachedFearPower(), screenscale)
	else
		self.FearHUDData = nil
	end
	self:HUDDrawTargetID(myteam, screenscale)
	if myteam == TEAM_SPECTATOR then return end
	if myteam == TEAM_UNDEAD then
		self:ZombieHUD(screenscale * 0.75)
	else
		self:HumanHUD(screenscale * 0.75)
	end
	if GetGlobalBool("classicmode") then
		draw_SimpleTextBlurry(translate.Get("classic_mode"), "ZSHUDFontSmaller", 4, ScrH() - 4, COLOR_GRAY, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

end

local colLifeStats = Color(255, 0, 0, 255)
function GM:ZombieHUD(screenscale)
	local curtime, h = CurTime(), ScrH()

	if GetConVar("zs_classichud"):GetBool() then
	self:DrawHealthBar(screenscale * 24, h - 272 * screenscale, MySelf:Health(), MySelf:GetMaxHealthEx(), texHumanHealthBar, screenscale)
	end
	
	self:DrawPreparationHUD()

	if self.LifeStatsEndTime and curtime < self.LifeStatsEndTime and (self.LifeStatsBarricadeDamage > 0 or self.LifeStatsHumanDamage > 0 or self.LifeStatsBrainsEaten > 0) then
		colLifeStats.a = math.Clamp((self.LifeStatsEndTime - curtime) / (self.LifeStatsLifeTime * 0.33), 0, 1) * 255

		local th = draw_GetFontHeight("ZSHUDFontSmall")
		local x = ScrW() * 0.75
		local y = ScrH() * 0.75

		draw_SimpleTextBlur(translate.Get("that_life"), "ZSHUDFontSmall", x, y, colLifeStats, TEXT_ALIGN_LEFT)
		y = y + th

		if self.LifeStatsBarricadeDamage > 0 then
			draw_SimpleTextBlur(translate.Format("x_damage_to_barricades", self.LifeStatsBarricadeDamage), "ZSHUDFontSmall", x, y, colLifeStats, TEXT_ALIGN_LEFT)
			y = y + th
		end
		if self.LifeStatsHumanDamage > 0 then
			draw_SimpleTextBlur(translate.Format("x_damage_to_humans", self.LifeStatsHumanDamage), "ZSHUDFontSmall", x, y, colLifeStats, TEXT_ALIGN_LEFT)
			y = y + th
		end
		if self.LifeStatsBrainsEaten > 0 then
			draw_SimpleTextBlur(translate.Format("x_brains_eaten", self.LifeStatsBrainsEaten), "ZSHUDFontSmall", x, y, colLifeStats, TEXT_ALIGN_LEFT)
			y = y + th
		end
	end

	self:DrawRespawnHUD()

end

function GM:_PostDrawTranslucentRenderables()
	if not self.DrawingInSky then
		self:DrawPointWorldHints()
		self:DrawWorldHints()
	end
end

local endRoundViewPosStart, endRoundViewAngleStart
function GM:RestartRound()
	self.ZSEndRoundGeneration = (self.ZSEndRoundGeneration or 0) + 1
	local meta = FindMetaTable("Player")
	if self.ZSEndRoundMeleeFilterApplied and meta.GetMeleeFilter == self.ZSEndRoundMeleeFilterApplied then meta.GetMeleeFilter = self.ZSEndRoundMeleeFilterPrevious end
	self.ZSEndRoundMeleeFilterPrevious, self.ZSEndRoundMeleeFilterApplied = nil, nil
	local hooks = hook.GetTable()
	if self.ZSEndRoundCalcView and hooks.CalcView and hooks.CalcView.EndRoundCalcView == self.ZSEndRoundCalcView then hook.Remove("CalcView", "EndRoundCalcView") end
	if self.ZSEndRoundDrawLocal and hooks.ShouldDrawLocalPlayer and hooks.ShouldDrawLocalPlayer.EndRoundShouldDrawLocalPlayer == self.ZSEndRoundDrawLocal then hook.Remove("ShouldDrawLocalPlayer", "EndRoundShouldDrawLocalPlayer") end
	self.ZSEndRoundCalcView, self.ZSEndRoundDrawLocal = nil, nil
	endRoundViewPosStart, endRoundViewAngleStart = nil, nil
	self:ResetBeats()
	self.TheLastHuman = nil
	self.RoundEnded = nil
	LASTHUMAN = nil

	if pEndBoard and pEndBoard:Valid() then
		pEndBoard:Remove()
		pEndBoard = nil
	end

	self:InitPostEntity()

	self:RevertZombieClasses()
	self:ResetWeaponInflictionUnlocks()
	timer.Create("RestartOSTintro", 10, 1, function() OSTintro = 0 end)
end

function GM:_HUDShouldDraw(name)
	if self.FilmMode and name ~= "CHudWeaponSelection" then return false end

	return name ~= "CHudHealth" and name ~= "CHudBattery"
	and name ~= "CHudAmmo" and name ~= "CHudSecondaryAmmo"
	and name ~= "CHudDamageIndicator"
end

local Current = 0
local NextCalculate = 0
function GM:_CachedFearPower()
	local now = CurTime()
	if now >= NextCalculate then
		NextCalculate = now + 0.15
		Current = self:GetFearMeterPower(EyePos(), TEAM_UNDEAD, MySelf)
	end

	return Current
end


function GM:EvaluateFilmMode()
	local visible = not self.FilmMode

	if self.GameStatePanel and self.GameStatePanel:Valid() then
		self.GameStatePanel:SetVisible(visible)
	end

	if self.TopNotificationHUD and self.TopNotificationHUD:Valid() then
		self.TopNotificationHUD:SetVisible(visible)
	end

	if self.CenterNotificationHUD and self.CenterNotificationHUD:Valid() then
		self.CenterNotificationHUD:SetVisible(visible)
	end

	if self.HealthHUD and self.HealthHUD:Valid() then
		self.HealthHUD:SetVisible(visible and not GetConVar("zs_classichud"):GetBool())
	end
end

cvars.AddChangeCallback("zs_classichud", function()
	if GAMEMODE and GAMEMODE.EvaluateFilmMode then GAMEMODE:EvaluateFilmMode() end
end, "ZSHealthHUDVisibility")

function GM:CreateVGUI()
	local screenscale = BetterScreenScale()
	self.GameStatePanel = vgui.Create("DGameState")
	self.GameStatePanel:SetTextFont("ZSRoundHUDText")
	self.GameStatePanel:SetAlpha(255)
	self.GameStatePanel:ParentToHUD()

	self.TopNotificationHUD = vgui.Create("DEXNotificationsList")
	self.TopNotificationHUD:SetAlign(RIGHT)
	self.TopNotificationHUD.PerformLayout = function(pan)
		local x, y, width, height, gap = GAMEMODE:GetCompactNotificationRegion()
		if x then
			pan:SetSize(width, math.max(0, (height - gap) * 0.5))
			pan:SetPos(x, y)
			return
		end
		local screenscale = BetterScreenScale()
		local top = math.max(16 * screenscale, pan.BreathHUDOffset or 0)
		local bottom = ScrH() - 16
		local center = GAMEMODE.CenterNotificationHUD
		if IsValid(center) then
			local _, y = center:GetPos()
			if y > 0 then bottom = math.min(bottom, y - 8) end
		end
		local right = GAMEMODE:GetHUDRightEdge()
		pan:SetSize(right * 0.4, math.max(0, math.min(ScrH() * 0.6, bottom - top)))
		pan:AlignTop(top)
		pan:AlignRight(ScrW() - right)
	end
	self.TopNotificationHUD:InvalidateLayout()
	self.TopNotificationHUD:ParentToHUD()

	self.CenterNotificationHUD = vgui.Create("DEXNotificationsList")
	self.CenterNotificationHUD:SetAlign(TEXT_ALIGN_CENTER)
	self.CenterNotificationHUD:SetMessageHeight(36)
	self.CenterNotificationHUD.PerformLayout = function(pan)
		local compactX, compactY, compactWidth, compactHeight, gap = GAMEMODE:GetCompactNotificationRegion()
		if compactX then
			local height = math.min(ScrH() * 0.35, math.max(0, (compactHeight - gap) * 0.5))
			pan:SetSize(compactWidth, height)
			pan:SetPos(compactX, compactY + compactHeight - height)
			return
		end
		local screenscale = BetterScreenScale()
		local bottom = 16 * screenscale
		local health = GAMEMODE.HealthHUD
		if IsValid(health) and health:IsVisible() then
			local x, y = health:GetPos()
			if y > 0 and x + health:GetWide() > ScrW() * 0.25 then
				bottom = math.max(bottom, ScrH() - y + 12 * screenscale)
			end
		end
		local right = GAMEMODE:GetHUDRightEdge()
		pan:SetSize(right * 0.5, ScrH() * 0.35)
		if right < 800 then
			pan:SetWide((right - 32 * screenscale) * 0.5)
			pan:AlignRight(ScrW() - right + 16 * screenscale)
			bottom = math.max(bottom, 112 * screenscale)
		else
			pan:SetX((right - pan:GetWide()) * 0.5)
		end
		pan:AlignBottom(bottom)
		local _, top = pan:GetPos()
		if pan.NotificationLayoutTop ~= top then
			pan.NotificationLayoutTop = top
			local notifications = GAMEMODE.TopNotificationHUD
			if IsValid(notifications) then notifications:InvalidateLayout() end
		end
	end
	self.CenterNotificationHUD:InvalidateLayout()
	self.CenterNotificationHUD:ParentToHUD()
end

function GM:Initialize()
	self:CreateFonts()
	self:PrecacheResources()
	self:CreateVGUI()
	self:InitializeBeats()
	self:AddCustomAmmo()
	
	self:RefreshMapIsObjective()
end

function GM:ShutDown()
end

local function FirstOfGoodType(a)
	for _, v in pairs(a) do
		local ext = string.sub(v, -4)
		if ext == ".ogg" or ext == ".wav" or ext == ".mp3" then
			return v
		end
	end
end

function GM:InitializeBeats()
	local _, dirs = file.Find("sound/zombiesurvival/beats/*", "GAME")
	for _, dirname in pairs(dirs) do
		if dirname == "none" or dirname == "default" then continue end

		self.Beats[dirname] = {}
		local highestexist
		for i=1, 10 do
			local a, __ = file.Find("sound/zombiesurvival/beats/"..dirname.."/"..i..".*", "GAME")
			local a1 = FirstOfGoodType(a)
			if a1 then
				local filename = "zombiesurvival/beats/"..dirname.."/"..a1
				if file.Exists("sound/"..filename, "GAME") then
					self.Beats[dirname][i] = Sound(filename)
					highestexist = filename

					continue
				end
			end

			if highestexist then
				self.Beats[dirname][i] = highestexist
			end
		end
	end
end

function GM:PlayerDeath(pl, attacker)
end

function GM:LastHuman(pl)
	if not IsValid(pl) then pl = nil end
	self.TheLastHuman = pl

	if not LASTHUMAN then

	hook.Add( "PreDrawHalos", "ZS.PreDrawHalos.AddHalos", function()
	if self.TheLastHuman then
		if not IsValid(self.TheLastHuman) or LocalPlayer() == self.TheLastHuman or self.TheLastHuman:Team() == TEAM_UNDEAD then return end

		halo.Add({self.TheLastHuman},team.GetColor(self.TheLastHuman:Team()),1,1,2,true,true);

		end
	end )

	LASTHUMAN = true
		timer.Simple(0.5, function() GAMEMODE:LastHumanMessage() end)
	end
end

function GM:LastHumanMessage()
	if self.RoundEnded or not MySelf:IsValid() then return end

	local icon = self.PantsMode and "weapon_zs_legs" or "default"
	if MySelf:Team() == TEAM_UNDEAD or not MySelf:Alive() then
		self:CenterNotify({killicon = icon}, {font = "ZSHUDFont"}, " ", COLOR_RED, translate.Get(self.PantsMode and "kick_the_last_human" or "kill_the_last_human"), {killicon = icon})
	else
		self:CenterNotify({font = "ZSHUDFont"}, " ", COLOR_RED, translate.Get("you_are_the_last_human"))
		self:CenterNotify({killicon = icon}, " ", COLOR_RED, translate.Format(self.PantsMode and "x_pants_out_to_get_you" or "x_zombies_out_to_get_you", team.NumPlayers(TEAM_UNDEAD)), {killicon = icon})
	end
end

function GM:PlayerShouldTakeDamage(pl, attacker)
	return pl == attacker or not attacker:IsPlayer() or pl:Team() ~= attacker:Team() or pl.AllowTeamDamage or attacker.AllowTeamDamage
end

function GM:SetWave(wave)
	SetGlobalInt("wave", wave)
end

--[[local texGradientUp = surface.GetTextureID("vgui/gradient_up")
local texGradientDown = surface.GetTextureID("vgui/gradient_down")
local texGradientRight = surface.GetTextureID("vgui/gradient-r")]]
local matFilmGrain = Material("zombiesurvival/filmgrain/filmgrain")
--local color_black = color_black
function GM:_HUDPaintBackground()
	--[[local w, h = ScrW(), ScrH()
	local bordersize = BetterScreenScale() * 32

	surface_SetDrawColor(color_black)

	surface_SetTexture(texGradientDown)
	surface_DrawTexturedRect(0, 0, w, bordersize)
	surface_SetTexture(texGradientUp)
	surface_DrawTexturedRect(0, h - bordersize, w, bordersize)
	surface_SetTexture(texGradientRight)
	surface_DrawTexturedRectRotated(bordersize / 2, h / 2, bordersize, h, 180)
	surface_DrawTexturedRect(w - bordersize, 0, bordersize, h)]]

	if self.FilmGrainEnabled and MySelf:Team() ~= TEAM_UNDEAD then
		surface_SetMaterial(matFilmGrain)
		surface_SetDrawColor(0, 0, 0, (0.25 + 0.75 * self:CachedFearPower()) * self.FilmGrainOpacity)
		surface_DrawTexturedRectUV(0, 0, ScrW(), ScrH(), 2, 2, 0, 0)
	end

	local wep = MySelf:GetActiveWeapon()
	if wep:IsValid() and wep.DrawHUDBackground then
		wep:DrawHUDBackground()
	end
end

function GM:PlayerBindPress(pl, bind, wasin)
	local action = self.ZSKeyCommandActions and self.ZSKeyCommandActions[bind]
	if action and self:GetZSKeyBinding(action) ~= 0 then return true end
    if bind == "gmod_undo" or bind == "undo" then
		if self:GetZSKeyBinding("zoom") ~= 0 then return true end
        RunConsoleCommand("+zoom")
        timer.Create("ReleaseZoom", 1, 1, function() RunConsoleCommand("-zoom") end)
    elseif bind == "+menu_context" then
		if self:GetZSKeyBinding("thirdperson") ~= 0 then return true end
        if P_Team(pl) ~= TEAM_SPECTATOR then
            self.ZombieThirdPerson = not self.ZombieThirdPerson
        end
    elseif bind == "impulse 100" then
		if self:GetZSKeyBinding("vision") ~= 0 then return true end
		if wasin == false then return true end
        if P_Team(pl) == TEAM_UNDEAD and pl:Alive() then
            self:ToggleZombieVision()
	else
			self:CreateFlashlightCheck()
        end
		return true
    end
end
local staggerdir = VectorRand():GetNormalized()
local BHopTime = 0
local WasPressingJump = false

local function PressingJump(cmd)
	return bit.band(cmd:GetButtons(), IN_JUMP) ~= 0
end

local function DontPressJump(cmd)
	cmd:SetButtons(cmd:GetButtons() - IN_JUMP)
end

function GM:_CreateMove(cmd)
	if MySelf:IsPlayingTaunt() and MySelf:Alive() then
		self:CreateMoveTaunt(cmd)
		return
	end

	-- Disables bunny hopping to an extent.
	if MySelf:GetLegDamage() >= 0.5 then
		if PressingJump(cmd) then
			DontPressJump(cmd)
		end
	elseif MySelf:OnGround() then
		if CurTime() < BHopTime then
			if PressingJump(cmd) then
				DontPressJump(cmd)
				WasPressingJump = true
			end
		elseif WasPressingJump then
			if PressingJump(cmd) then
				DontPressJump(cmd)
			else
				WasPressingJump = false
			end
		end
	else
		BHopTime = CurTime() + 0.065
	end

	local myteam = MySelf:Team()
	if myteam ~= TEAM_UNDEAD then
		if MySelf:Alive() then
			local lockon = self.HumanMenuLockOn
			if lockon then
				if self:ValidMenuLockOnTarget(MySelf, lockon) and self.HumanMenuPanel and self.HumanMenuPanel:Valid() and self.HumanMenuPanel:IsVisible() and self:IsHumanMenuKeyDown(MySelf) then
					local oldang = cmd:GetViewAngles()
					local newang = (lockon:EyePos() - EyePos()):Angle()
					--oldang.pitch = math.ApproachAngle(oldang.pitch, newang.pitch, FrameTime() * math.max(45, math.abs(math.AngleDifference(oldang.pitch, newang.pitch)) ^ 1.3))
					oldang.yaw = math.ApproachAngle(oldang.yaw, newang.yaw, FrameTime() * math.max(45, math.abs(math.AngleDifference(oldang.yaw, newang.yaw)) ^ 1.3))
					cmd:SetViewAngles(oldang)
				else
					self.HumanMenuLockOn = nil
				end
			else
				local maxhealth = MySelf:GetMaxHealth()
				local threshold = MySelf:GetPalsy() and maxhealth - 1 or maxhealth * 0.25
				local health = MySelf:Health()
				if self:ShouldStaggerAim(MySelf, health, threshold) then
					local ft = FrameTime()

					staggerdir = (staggerdir + ft * 8 * VectorRand()):GetNormalized()

					local ang = cmd:GetViewAngles()
					local rate = ft * ((threshold - health) / threshold) * 7
					ang.pitch = math.NormalizeAngle(ang.pitch + staggerdir.z * rate)
					ang.yaw = math.NormalizeAngle(ang.yaw + staggerdir.x * rate)
					cmd:SetViewAngles(ang)
				end
			end
		end
	elseif myteam == TEAM_UNDEAD then
		local buttons = cmd:GetButtons()
		if bit.band(buttons, IN_ZOOM) ~= 0 then
			cmd:SetButtons(buttons - IN_ZOOM)
		end

		MySelf:CallZombieFunction("CreateMove", cmd)
	end
end

function GM:CreateMoveTaunt(cmd)
	cmd:ClearButtons(0)
	cmd:ClearMovement()
end

function GM:PostProcessPermitted(str)
	return false
end


function GM:PreDrawViewModel(vm, pl, wep)
	if pl and pl:IsValid() and pl:IsHolding() then return true end

	if wep and wep:IsValid() and wep.PreDrawViewModel then
		return wep:PreDrawViewModel(vm)
	end
end

function GM:PostDrawViewModel(vm, pl, wep)
	if wep and wep:IsValid() then
		if wep.UseHands or not wep:IsScripted() then
			local hands = pl:GetHands()
			if hands and hands:IsValid() then
				hands:DrawModel()
			end
		end

		if wep.PostDrawViewModel then
			wep:PostDrawViewModel(vm)
		end
	end
end

local undomodelblend = false
local undozombievision = false
local matWhite = Material("models/debug/debugwhite")
function GM:_PrePlayerDraw(pl)
	if pl:CallZombieFunction("PrePlayerDraw") then
		local status = pl.status_zombiespawnbuff
		if status and status:IsValid() then
			status:PostPlayerDraw(pl)
		end
		return true
	end

	local shadowman = false

	if pl.status_overridemodel and pl.status_overridemodel:IsValid() and self:ShouldDrawLocalPlayer(MySelf) then -- We need to do this otherwise the player's real model shows up for some reason.
		undomodelblend = true
		render.SetBlend(0)
	else
		local myteam = MySelf:Team()
		if myteam == pl:Team() and pl ~= MySelf and not self.MedicalAura then
			local radius = self.TransparencyRadius
			if radius > 0 then
				local eyepos = EyePos()
				local distsqr = pl:NearestPoint(eyepos):DistToSqr(eyepos)
				if distsqr < radius * radius then
					local dist = math.sqrt(distsqr)
					local blend = math.max((dist / radius) ^ 1.4, myteam ~= TEAM_UNDEAD and 0.04 or 0.1)
					render.SetBlend(blend)
					if myteam ~= TEAM_UNDEAD and blend < 0.4 then
						render.ModelMaterialOverride(matWhite)
						render.SetColorModulation(0.2, 0.2, 0.2)
						shadowman = true
					end
					undomodelblend = true
				end
			end
		end
	end

	pl.ShadowMan = shadowman

	if (MySelf:KeyDown(IN_SPEED) and MySelf:Team() ~= TEAM_UNDEAD and MySelf:Alive() and pl:Team() ~= TEAM_UNDEAD and pl ~= MySelf) or self.m_ZombieVision and MySelf:Team() ~= TEAM_HUMAN and pl:Team() ~= TEAM_UNDEAD and pl:GetPos():DistToSqr(EyePos()) <= pl:GetAuraRange() ^ 2 then
		undozombievision = true
		local healthfrac = math.Clamp(pl:Health() / math.max(pl:GetMaxHealth(), 1), 0, 1)
		local lowhealthcolor = self.AuraColorEmpty
		local fullhealthcolor = self.AuraColorFull

		render.ModelMaterialOverride(matWhite)
		render.SetColorModulation(
			math.Approach(lowhealthcolor.r, fullhealthcolor.r, math.abs(lowhealthcolor.r - fullhealthcolor.r) * healthfrac) / 255,
			math.Approach(lowhealthcolor.g, fullhealthcolor.g, math.abs(lowhealthcolor.g - fullhealthcolor.g) * healthfrac) / 255,
			math.Approach(lowhealthcolor.b, fullhealthcolor.b, math.abs(lowhealthcolor.b - fullhealthcolor.b) * healthfrac) / 255
		)
		render.SuppressEngineLighting(true)
		cam.IgnoreZ(true)
	end
end

local colFriend = Color(10, 255, 10, 60)
local matFriendRing = Material("SGM/playercircle")
function GM:_PostPlayerDraw(pl)
	pl:CallZombieFunction("PostPlayerDraw")

	if undomodelblend then
		render.SetBlend(1)
		render.ModelMaterialOverride()
		render.SetColorModulation(1, 1, 1)

		undomodelblend = false
	end
	if undozombievision then
		render.ModelMaterialOverride()
		render.SetColorModulation(1, 1, 1)
		render.SuppressEngineLighting(false)
		cam.IgnoreZ(false)

		undozombievision = false
	end

	if pl ~= MySelf and MySelf:Team() == pl:Team() and pl:IsFriend() then
		local pos = pl:GetPos() + Vector(0, 0, 2)
		render.SetMaterial(matFriendRing)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 32, 32, colFriend)
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 32, 32, colFriend)
	end
end

function GM:DrawCraftingEntity()
	local craftingentity = self.CraftingEntity
	if craftingentity and craftingentity:IsValid() then
		if IsValid(self.HumanMenuPanel) and self.HumanMenuPanel:IsVisible() and self:IsHumanMenuKeyDown(MySelf) then
			local scale = craftingentity:GetModelScale()
			if type(scale) ~= "number" or scale <= 0 or scale >= math.huge or scale ~= scale then return end

			render.ModelMaterialOverride(matWhite)
			render.SuppressEngineLighting(true)
			render.SetBlend(0.025)
			local extrascale = 1.05 + math.abs(math.sin(RealTime() * 7)) * 0.1
			craftingentity:SetModelScale(scale * extrascale, 0)

			craftingentity:DrawModel()

			craftingentity:SetModelScale(scale, 0)
			render.SetBlend(1)
			render.SuppressEngineLighting(false)
			render.ModelMaterialOverride(nil)
		else
			self.CraftingEntity = nil
		end
	end
end

function GM:HUDPaintBackgroundEndRound()
	if IsValid(self.GameStatePanel) and self.GameStatePanel:IsVisible() then return end
	local w, h = ScrW(), ScrH()
	local timleft = math.max(0, self.EndTime + self.EndGameTime - CurTime())

	if timleft <= 0 then
		draw_SimpleTextBlur(translate.Get("loading"), "ZSHUDFont", w * 0.5, h * 0.8, COLOR_WHITE, TEXT_ALIGN_CENTER)
	else
		draw_SimpleTextBlur(translate.Format("next_round_in_x", util.ToMinutesSeconds(timleft)), "ZSHUDFontSmall", w * 0.5, h * 0.8, COLOR_WHITE, TEXT_ALIGN_CENTER)
	end
end

local function EndRoundCalcView(pl, origin, angles, fov, znear, zfar)
	if GAMEMODE.EndTime and CurTime() < GAMEMODE.EndTime + 5 then
		endRoundViewPosStart = endRoundViewPosStart or origin
		endRoundViewAngleStart = endRoundViewAngleStart or angles
		local endRoundViewPosEnd = GAMEMODE.LastHumanPosition
		local override = GetGlobalVector("endcamerapos", 1)
		if type(override) ~= "number" then
			endRoundViewPosEnd = override
		end
		if endRoundViewPosEnd then
			local delta = math.Clamp((CurTime() - GAMEMODE.EndTime) * 2, 0, 1)

			local camPos = endRoundViewPosEnd * delta + endRoundViewPosStart * (1 - delta)
			local camVec = Angle(0, CurTime() * 30, 0):Forward() * delta - endRoundViewAngleStart:Forward() * (1 - delta)
			camVec:Normalize()
			local tr = util.TraceHull({start = camPos, endpos = camPos + delta * 128 * camVec, mins = Vector(-2, -2, -2), maxs = Vector(2, 2, 2), filter = player.GetAll(), mask = MASK_SOLID})
			return {origin = tr.HitPos + tr.HitNormal, angles = (camPos - tr.HitPos):Angle()}
		end

		return
	end

	endRoundViewPosStart = nil
	endRoundViewAngleStart = nil

	hook.Remove("CalcView", "EndRoundCalcView")
end

local function EndRoundShouldDrawLocalPlayer(pl)
	if GAMEMODE.EndTime and CurTime() < GAMEMODE.EndTime + 5 then
		return true
	end

	hook.Remove("ShouldDrawLocalPlayer", "EndRoundShouldDrawLocalPlayer")
end

local function EndRoundGetMeleeFilter(self) return {self} end
function GM:EndRound(winner, nextmap)
	if self.RoundEnded then return end
	self.RoundEnded = true
	if IsValid(self.CenterNotificationHUD) then self.CenterNotificationHUD:ClearNotifications() end
	self:ResetBeats()

	ROUNDWINNER = winner

	self.EndTime = CurTime()
	self.ZSEndRoundGeneration = (self.ZSEndRoundGeneration or 0) + 1
	local generation = self.ZSEndRoundGeneration

	RunConsoleCommand("stopsound")

	local meta = FindMetaTable("Player")
	self.ZSEndRoundMeleeFilterPrevious, self.ZSEndRoundMeleeFilterApplied = meta.GetMeleeFilter, EndRoundGetMeleeFilter
	meta.GetMeleeFilter = EndRoundGetMeleeFilter

	self.HUDPaint = self.HUDPaintEndRound
	self.HUDPaintBackground = self.HUDPaintBackgroundEndRound

	if winner == TEAM_UNDEAD and GetGlobalBool("endcamera", true) then
		hook.Add("CalcView", "EndRoundCalcView", EndRoundCalcView)
		hook.Add("ShouldDrawLocalPlayer", "EndRoundShouldDrawLocalPlayer", EndRoundShouldDrawLocalPlayer)
		self.ZSEndRoundCalcView, self.ZSEndRoundDrawLocal = EndRoundCalcView, EndRoundShouldDrawLocalPlayer
	end

	local dvar = winner == TEAM_UNDEAD and self.AllLoseSound or self.HumanWinSound
	local snd = GetGlobalString(winner == TEAM_UNDEAD and "losemusic" or "winmusic", dvar)
	if snd == "default" then
		snd = dvar
	elseif snd == "none" then
		snd = nil
	end
	if snd then
		timer.Simple(0.5, function() if self.RoundEnded and self.ZSEndRoundGeneration == generation then surface_PlaySound(snd) end end)
	end

	timer.Simple(5, function()
		if self.RoundEnded and self.ZSEndRoundGeneration == generation and not (pEndBoard and pEndBoard:IsValid()) then
			MakepEndBoard(winner)
		end
	end)
end

function GM:WeaponDeployed(pl, wep)
end

function GM:LocalPlayerDied(attackername)
	LASTDEATH = RealTime()

	surface_PlaySound(self.DeathSound)
	if attackername then
		self:CenterNotify(COLOR_RED, {font = "ZSHUDFont"}, translate.Get("you_have_died"))
		self:CenterNotify(COLOR_RED, translate.Format(self.PantsMode and "you_were_kicked_by_x" or "you_were_killed_by_x", tostring(attackername)))
	else
		self:CenterNotify(COLOR_RED, {font = "ZSHUDFont"}, translate.Get("you_have_died"))
	end
end

function GM:KeyPress(pl, key)
	if key == self.MenuKey then
		if pl:Team() ~= TEAM_UNDEAD and pl:Alive() and not pl:IsHolding() then
			gamemode.Call("HumanMenu")
		end
	elseif key == IN_SPEED then
		if pl:Alive() then
			if pl:Team() ~= TEAM_UNDEAD then
				pl:DispatchAltUse()
			elseif pl:Team() == TEAM_UNDEAD then
				pl:CallZombieFunction("AltUse")
			end
		end
	end
end

include("shared/sh_footsteps.lua")

function GM:PlayerCanCheckout(pl)
	return pl:IsValid() and pl:Team() == TEAM_HUMAN and pl:Alive() and self:GetWave() <= 0
end

function GM:OpenWorth()
	if gamemode.Call("PlayerCanCheckout", MySelf) then
		MakepWorth()
	end
end

function GM:CloseWorth()
	if pWorth and pWorth:IsValid() then
		pWorth:Remove()
		pWorth = nil
	end
end

function GM:SuppressArsenalUpgrades(suppresstime)
	self.SuppressArsenalTime = math.max(CurTime() + suppresstime, self.SuppressArsenalTime)
end

function GM:Rewarded(class, amount)
	if CurTime() < self.SuppressArsenalTime then return end

	class = class or "0"

	local toptext = translate.Get("arsenal_upgraded")

	local wep = weapons.GetStored(class)
	if wep and wep.PrintName then
		if killicon.Get(class) == killicon.Get("default") then
			self:CenterNotify(COLOR_PURPLE, toptext..": ", color_white, wep.PrintName)
		else
			self:CenterNotify({killicon = class}, " ", COLOR_PURPLE, toptext..": ", color_white, wep.PrintName)
		end
	elseif amount then
		self:CenterNotify(COLOR_PURPLE, toptext..": ", color_white, amount.." "..class)
	else
		self:CenterNotify(COLOR_PURPLE, toptext)
	end
end

function PlayMenuOpenSound()
	LocalPlayer():EmitSound("buttons/lightswitch2.wav", 100, 30)
end

function PlayMenuCloseSound()
	LocalPlayer():EmitSound("buttons/lightswitch2.wav", 100, 20)
end

include("client/cl_network.lua")
include("client/cl_menuactions.lua")

-- Temporary fix
function render.DrawQuadEasy(pos, dir, xsize, ysize, color, rotation)
	xsize = xsize / 2
	ysize = ysize / 2

	local ang = dir:Angle()

	if rotation then
		ang:RotateAroundAxis(ang:Forward(), rotation)
	end

	local upoffset = ang:Up() * ysize
	local rightoffset = ang:Right() * xsize

	render.DrawQuad(pos - upoffset - rightoffset, pos - upoffset + rightoffset, pos + upoffset + rightoffset, pos + upoffset - rightoffset, color)
end

local mapScript = "misc/maps/" .. GM:GetMapScriptName() .. "_cl.lua"
if file.Exists(GM.FolderName .. "/gamemode/" .. mapScript, "LUA") then include(mapScript) end
