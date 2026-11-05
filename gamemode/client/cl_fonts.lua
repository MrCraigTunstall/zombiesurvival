function surface.CreateLegacyFont(font, size, weight, antialias, additive, name, shadow, outline, blursize, extended)
	surface.CreateFont(name, {font = font, size = size, weight = weight, antialias = antialias, additive = additive, shadow = shadow, outline = outline, blursize = blursize, extended = extended})
end

GM.LegacyFontScale = nil

function GM:CreateFonts()
 local screenscale = BetterScreenScale()
 if self.LegacyFontScale == screenscale then return end
 self.LegacyFontScale = screenscale
 self.LegacyFontRevision = (self.LegacyFontRevision or 0) + 1
	local fontfamily = "Roboto"
	local fontfamily3d = "Roboto"
	local fontweight = 500
	local fontweight3D = 500
	local fontaa = true
	local fontshadow = false
	local fontoutline = true
	local fontextended = true

	surface.CreateLegacyFont("csd", 42, 500, true, false, "healthsign", false, true)
	surface.CreateLegacyFont("tahoma", 96, 1000, true, false, "zshintfont", false, true)

	surface.CreateLegacyFont(fontfamily3d, 12, fontweight3D, false, false,  "ZS3D2DFontSuperTiny2", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 15, fontweight3D, false, false,  "ZS3D2DFontSuperTiny", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 20, fontweight3D, false, false,  "ZS3D2DFontTiny", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 32, fontweight3D, false, false,  "ZS3D2DFontSmallest", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 40, fontweight3D, false, false,  "ZS3D2DFontSmaller", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 48, fontweight3D, false, false,  "ZS3D2DFontSmall", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 72, fontweight3D, false, false, "ZS3D2DFont", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 128, fontweight3D, false, false, "ZS3D2DFontBig", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily3d, 48, fontweight3D, false, false,  "ZS3D2DFontSmallBlur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily3d, 72, fontweight3D, false, false, "ZS3D2DFontBlur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily3d, 128, fontweight3D, false, false, "ZS3D2DFontBigBlur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily, 40, fontweight3D, false, false,  "ZS3D2DFont2Smaller", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 48, fontweight3D, false, false,  "ZS3D2DFont2Small", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 72, fontweight3D, false, false, "ZS3D2DFont2", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 128, fontweight3D, false, false, "ZS3D2DFont2Big", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 40, fontweight3D, false, false,  "ZS3D2DFont2SmallerBlur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily, 48, fontweight3D, false, false,  "ZS3D2DFont2SmallBlur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily, 72, fontweight3D, false, false, "ZS3D2DFont2Blur", false, false, 16, true)
	surface.CreateLegacyFont(fontfamily, 128, fontweight3D, false, false, "ZS3D2DFont2BigBlur", false, false, 16, true)


	surface.CreateLegacyFont("csd", screenscale * 36, 100, true, false, "zsdeathnoticecs", false, true)
	surface.CreateLegacyFont("HL2MP", screenscale * 36, 100, true, false, "zsdeathnotice", false, true)

	surface.CreateLegacyFont(fontfamily, screenscale * 16, fontweight, fontaa, false, "ZSHUDFontTiny", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 20, fontweight, fontaa, false, "ZSHUDFontSmallest", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 22, fontweight, fontaa, false, "ZSHUDFontSmaller", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 28, fontweight, fontaa, false, "ZSHUDFontSmall", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 42, fontweight, fontaa, false, "ZSHUDFont", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 72, fontweight, fontaa, false, "ZSHUDFontBig", fontshadow, fontoutline, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 16, fontweight, fontaa, false, "ZSHUDFontTinyBlur", false, false, 8, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 22, fontweight, fontaa, false, "ZSHUDFontSmallerBlur", false, false, 8, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 22, fontweight, fontaa, false, "ZSHUDFontSmallNSBlur", false, false, 8, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 28, fontweight, fontaa, false, "ZSHUDFontSmallBlur", false, false, 8, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 42, fontweight, fontaa, false, "ZSHUDFontBlur", false, false, 8, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 72, fontweight, fontaa, false, "ZSHUDFontBigBlur", false, false, 8, true)

	surface.CreateLegacyFont(fontfamily, screenscale * 16, 0, fontaa, false, "ZSAmmoName", false, false, 0, fontextended)
	surface.CreateLegacyFont(fontfamily, screenscale * 16, fontweight, fontaa, false, "ZSHUDFontTinyNS", false, false, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 20, fontweight, fontaa, false, "ZSHUDFontSmallestNS", false, false, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 22, fontweight, fontaa, false, "ZSHUDFontSmallerNS", false, false, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 28, fontweight, fontaa, false, "ZSHUDFontSmallNS", false, false, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 42, fontweight, fontaa, false, "ZSHUDFontNS", false, false, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 72, fontweight, fontaa, false, "ZSHUDFontBigNS", false, false, 0, true)

	surface.CreateLegacyFont(fontfamily, screenscale * 16, 0, true, false, "ZSDamageResistance", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, screenscale * 16, 0, true, false, "ZSDamageResistanceBlur", false, true, 0, true)
	surface.CreateLegacyFont("HL2MP", screenscale * 96, 100, true, false, "zsdeathnoticews", false, false)
	surface.CreateLegacyFont("csd", screenscale * 96, 100, true, false, "zsdeathnoticecsws", false, false)

	surface.CreateLegacyFont(fontfamily, 32, fontweight, true, false, "ZSScoreBoardTitle", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 22, fontweight, true, false, "ZSScoreBoardSubTitle", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 16, fontweight, true, false, "ZSScoreBoardPlayer", false, true, 0, true)
	surface.CreateLegacyFont(fontfamily, 24, fontweight, true, false, "ZSScoreBoardHeading", false, false, 0, true)
	surface.CreateLegacyFont("arial", 20, 0, true, false, "ZSScoreBoardPlayerSmall", false, true)

	surface.CreateFont("DefaultFontVerySmall", {font = "tahoma", size = 10, weight = 0, antialias = false})
	surface.CreateFont("DefaultFontSmall", {font = "tahoma", size = 11, weight = 0, antialias = false})
	surface.CreateFont("DefaultFontSmallDropShadow", {font = "tahoma", size = 11, weight = 0, shadow = true, antialias = false})
	surface.CreateFont("DefaultFont", {font = "tahoma", size = 13, weight = 500, antialias = false})
	surface.CreateFont("DefaultFontBold", {font = "tahoma", size = 13, weight = 1000, antialias = false})
	surface.CreateFont("DefaultFontLarge", {font = "tahoma", size = 16, weight = 0, antialias = false})
end

hook.Add("OnScreenSizeChanged", "ZSLegacyHUDFonts", function()
 if GAMEMODE and GAMEMODE.CreateFonts then GAMEMODE:CreateFonts() end
end)
