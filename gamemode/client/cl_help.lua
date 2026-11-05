local function U(value) return math.floor(value * (GAMEMODE.MenuScale or 1) + 0.5) end
if IsValid(pHelp) then pHelp:Remove() pHelp = nil end

GM.Help = {
{Name = "help_cat_introduction",
Content = "help_cont_introduction"},

{Name = "help_cat_survival",
Content = "help_cont_survival"},

{Name = "help_cat_barricading",
Content = "help_cont_barricading"},

{Name = "help_cat_upgrades",
Content = "help_cont_upgrades"},

{Name = "help_cat_being_a_zombie",
Content = "help_cont_being_a_zombie"}
}

if not GM.BuildHelpMenu then
	function GM:BuildHelpMenu(window, propertysheet) end
end

local escapes = {['&']='&amp;', ['<']='&lt;', ['>']='&gt;', ['"']='&quot;', ["'"]='&#39;'}
local function EscapeHTML(text)
	return (string.gsub(text, "[&<>\"']", escapes))
end

function GM:BuildSurvivalGuideHTML(entry)
	local pixels = math.floor(16 * (self.MenuScale or 1) + 0.5)
	return [[<!doctype html><html><head><meta charset="utf-8"><style>html{font-size:]]..pixels..[[px}
	*{box-sizing:border-box}body{margin:0;background:#1a232d;color:#eff4f8;font:1rem/1.65 Arial,sans-serif;overflow-wrap:anywhere}
	main{max-width:56.25rem;margin:auto;padding:1.5rem}h1{font-size:1.5rem;line-height:1.25;color:#50cd87;margin:0 0 1.25rem}
	p{margin:0 0 1.125rem}ul{padding-left:1.5rem;margin:.75rem 0 1.25rem}li{margin:0 0 .75rem}b,strong{color:#fff}
	a{color:#50cd87}::-webkit-scrollbar{width:.625rem}::-webkit-scrollbar-track{background:#141b23}
	::-webkit-scrollbar-thumb{background:#394b5e;border-radius:.3125rem}
	@media(max-width:600px){main{padding:1rem}body{font-size:.9375rem}h1{font-size:1.375rem}}
	</style></head><body><main><h1>]]..EscapeHTML(translate.Get(entry.Name))..[[</h1>]]..translate.Get(entry.Content)..[[</main></body></html>]]
end

local buildGuideHTML = GM.BuildSurvivalGuideHTML

local function ShowGuideTab(frame, tab)
	local panel = IsValid(tab) and tab:GetPanel()
	local entry = IsValid(panel) and panel.HelpEntry
	local browser = frame.Browser
	if not entry then if browser:IsVisible() then browser:SetVisible(false) end return end
	if frame.BrowserPanel ~= panel then browser:SetParent(panel) browser:Dock(FILL) frame.BrowserPanel = panel end
	if not browser:IsVisible() then browser:SetVisible(true) end
	local title, content = translate.Get(entry.Name), translate.Get(entry.Content)
	local cached = frame.PageCache[entry]
	if GAMEMODE.BuildSurvivalGuideHTML ~= buildGuideHTML or not cached or cached.title ~= title or cached.content ~= content or cached.scale ~= (GAMEMODE.MenuScale or 1) then
		cached = {title = title, content = content, scale = GAMEMODE.MenuScale or 1, html = GAMEMODE:BuildSurvivalGuideHTML(entry)}
		frame.PageCache[entry] = cached
	end
	local html = cached.html
	if html ~= frame.CurrentHTML then browser:SetHTML(html) frame.CurrentHTML = html end
end

local function Layout(frame)
	if GAMEMODE.RefreshMenuScale then GAMEMODE:RefreshMenuScale() end
	local width, height = ScrW(), ScrH()
	frame.LayoutDirty = nil
	if frame.LayoutWidth == width and frame.LayoutHeight == height then return end
	frame.LayoutWidth, frame.LayoutHeight = width, height
	local oldScale = frame.GuideScale
	frame.GuideScale = GAMEMODE.MenuScale or 1
	frame:SetSize(math.min(U(940), width - U(32)), math.min(U(600), height - U(64)))
	frame:Center()
	frame:InvalidateLayout(true)
	if oldScale and oldScale ~= frame.GuideScale then ShowGuideTab(frame, frame.Sheet:GetActiveTab()) end
end

local function RefreshLabels(frame)
	local revision, getter = translate.GetRevision(), translate.Get
	if frame.LanguageRevision == revision and frame.LanguageGetter == getter then return end
	frame.LanguageRevision, frame.LanguageGetter = revision, getter
	for _, entry in ipairs(frame.LocalizedLabels) do
		local value = getter(entry[2])
		if entry[1].ZSGuideText ~= value then entry[1].ZSGuideText = value entry[1]:SetText(value) end
	end
	frame.Sheet:InvalidateLayout(true)
end

function MakepHelp()
	local frame = pHelp
	if not IsValid(frame) then
		frame = vgui.Create("DFrame")
		frame:SetVisible(false)
		frame.PageCache = {}
		pHelp = frame
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetDeleteOnClose(false)
		GAMEMODE:StyleShopFrame(frame)
		local colors, background = GAMEMODE.ShopColors, Color(15, 20, 26)
		frame.Paint = function(_, width, height)
			draw.RoundedBox(U(8), 0, 0, width, height, background)
			draw.RoundedBox(U(8), 0, 0, width, U(72), colors.header)
			surface.SetDrawColor(colors.accent) surface.DrawRect(U(16), U(70), width - U(32), U(2))
		end
		local nativeThink = frame.Think
		frame.Think = function(panel)
			if not panel:IsVisible() then return end
			if panel.LayoutDirty then Layout(panel) end
			if nativeThink then return nativeThink(panel) end
		end
		frame.Title = EasyLabel(frame, translate.Get("help_help"), "ZSMenuScaledTitle", color_white)
		frame.Subtitle = EasyLabel(frame, translate.Get("mm_guide_description"), "ZSMenuScaledSmall", GAMEMODE.ShopColors.muted)
		frame.Sheet = vgui.Create("DPropertySheet", frame)
		GAMEMODE:ScaleMenuSheet(frame.Sheet)
		frame.Sheet:SetPadding(U(8))
		frame.Sheet:SetFadeTime(0)
		frame.Sheet.Paint = function(self, width, height) draw.RoundedBox(U(5), 0, U(20), width, height - U(20), GAMEMODE.ShopColors.row) end
		frame.Browser = vgui.Create("DHTML", frame)
		frame.LocalizedLabels = {{frame.Title, "help_help"}, {frame.Subtitle, "mm_guide_description"}}
		frame.Browser:SetAllowLua(false)
		local think = frame.Browser.Think
		frame.Browser.Think = function(browser)
			if not IsValid(frame) or not frame:IsVisible() or not browser:IsVisible() then return end
			if think then return think(browser) end
		end
		local changed = frame.Sheet.OnActiveTabChanged
		frame.Sheet.OnActiveTabChanged = function(sheet, previous, new)
			if changed then changed(sheet, previous, new) end
			ShowGuideTab(frame, new)
		end
		for _, entry in ipairs(GAMEMODE.Help) do
			local panel = vgui.Create("DPanel", frame.Sheet)
			panel.Paint = function() end
			panel.HelpEntry = entry
			local item = frame.Sheet:AddSheet(translate.Get(entry.Name), panel, entry.Icon, false, false)
			item.Tab:SetFont("ZSMenuScaledSmall")
			item.Tab:SetTextColor(color_white)
			frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {item.Tab, entry.Name}
			item.Tab.Paint = function(tab, width, height)
				draw.RoundedBox(U(4), 0, 0, width, height, frame.Sheet:GetActiveTab() == tab and GAMEMODE.ShopColors.hover or GAMEMODE.ShopColors.row)
			end
		end
		frame.BackButton = vgui.Create("DButton", frame)
		frame.BackButton:SetText(translate.Get("mm_back"))
		GAMEMODE:StyleShopButton(frame.BackButton, false, true)
		frame.BackButton.DoClick = function() frame:Close() GAMEMODE:ShowHelp() end
		frame.CreditsButton = vgui.Create("DButton", frame)
		frame.CreditsButton:SetText(translate.Get("help_credits"))
		GAMEMODE:StyleShopButton(frame.CreditsButton, false, true)
		frame.CreditsButton.DoClick = function() frame:Close() MakepCredits() end
		frame.CloseButton = vgui.Create("DButton", frame)
		frame.CloseButton:SetText(translate.Get("mm_close"))
		GAMEMODE:StyleShopButton(frame.CloseButton, false, true)
		frame.CloseButton.DoClick = function() frame:Close() end
		frame.PerformLayout = function(panel, width, height)
			panel.Title:SizeToContents() panel.Subtitle:SizeToContents()
			panel.Title:SetPos(U(20), U(12)) panel.Title:SetWide(width - U(40))
			panel.Subtitle:SetPos(U(20), U(44)) panel.Subtitle:SetWide(width - U(40))
			panel.Sheet:SetPos(U(20), U(88)) panel.Sheet:SetSize(width - U(40), height - U(152))
			panel.BackButton:SetPos(U(20), height - U(48)) panel.BackButton:SetSize(U(100), U(32))
			panel.CreditsButton:SetPos(width - U(240), height - U(48)) panel.CreditsButton:SetSize(U(110), U(32))
			panel.CloseButton:SetPos(width - U(120), height - U(48)) panel.CloseButton:SetSize(U(100), U(32))
		end
		frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {frame.BackButton, "mm_back"}
		frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {frame.CreditsButton, "help_credits"}
		frame.LocalizedLabels[#frame.LocalizedLabels + 1] = {frame.CloseButton, "mm_close"}
		frame.OnRemove = function(panel)
			panel.PageCache, panel.CurrentHTML, panel.BrowserPanel, panel.LocalizedLabels, panel.Browser, panel.Sheet = nil, nil, nil, nil, nil, nil
			panel.LanguageGetter = nil
			if pHelp == panel then pHelp = nil end
		end
		gamemode.Call("BuildHelpMenu", frame, frame.Sheet)
	end
	RefreshLabels(frame)
	Layout(frame)
	ShowGuideTab(frame, frame.Sheet:GetActiveTab())
	if frame:IsVisible() then return frame end
	PlayMenuOpenSound()
	frame:SetVisible(true)
	frame:MakePopup()
	return frame
end

hook.Add("OnScreenSizeChanged", "ZSGuideLayout", function()
	if IsValid(pHelp) then
		if pHelp:IsVisible() then Layout(pHelp) else pHelp.LayoutDirty = true end
	end
end)
hook.Add("ZSLanguageChanged", "ZSGuideLanguage", function()
	if IsValid(pHelp) and pHelp:IsVisible() then
		RefreshLabels(pHelp)
		ShowGuideTab(pHelp, pHelp.Sheet:GetActiveTab())
	end
end)
