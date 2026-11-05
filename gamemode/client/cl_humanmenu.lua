local actions = {
 {"alt_gw", "zsgiveweapon"},
 {"alt_gw5", "zsgiveweaponclip"},
 {"alt_dw", "zsdropweapon"},
 {"alt_ec", "zsemptyclip"}
}

local function ActionClick(button)
 RunConsoleCommand(button.HumanMenuCommand)
end

function GM:RefreshHumanMenuLanguage()
 local panel = self.HumanMenuPanel
 if not IsValid(panel) then return end
 local revision = translate.GetRevision and translate.GetRevision()
 if panel.LanguageRevision == revision then return end
 panel.LanguageRevision = revision
 panel.HeaderSource = {
  title = translate.Get("alt_title"), hint = translate.Get("alt_hint"),
  ammo = translate.Get("alt_ammunition"), actions = translate.Get("alt_actions"),
  drop = translate.Get("alt_drop"), give = translate.Get("alt_give")
 }
 for _, item in ipairs(panel.Items) do
  if item.LocalizationKey then item.SourceText = translate.Get(item.LocalizationKey) end
 end
 panel.LayoutItemsDirty = true
 panel:RefreshSize()
end

hook.Add("ZSLanguageChanged", "ZSHumanMenuLanguage", function()
 if GAMEMODE then GAMEMODE:RefreshHumanMenuLanguage() end
end)

function GM:HumanMenu()
 if self.ZombieEscape then return end
 local ent = MySelf:MeleeTrace(48, 2).Entity
 self.HumanMenuLockOn = self:ValidMenuLockOnTarget(MySelf, ent) and ent or nil
 local panel = self.HumanMenuPanel
 if not IsValid(panel) then
  panel = vgui.Create("DSideMenu")
  self.HumanMenuPanel = panel
  local ammoTypes = {}
  for ammo in pairs(self.AmmoNames) do ammoTypes[#ammoTypes + 1] = ammo end
  table.sort(ammoTypes, function(a, b)
   local first, second = self.AmmoNames[a], self.AmmoNames[b]
   return first == second and a < b or first ~= second and first < second
  end)
  for _, ammo in ipairs(ammoTypes) do
   local counter = vgui.Create("DAmmoCounter", panel)
   counter:SetAmmoType(ammo)
   panel:AddItem(counter)
  end
  for _, action in ipairs(actions) do
   local button = EasyButton(panel, "", 8, 4)
   button.LocalizationKey, button.HumanMenuCommand = action[1], action[2]
   button.DoClick = ActionClick
   panel:AddItem(button)
  end
  panel.LanguageRevision = false
 end
 self:RefreshHumanMenuLanguage()
 panel:OpenMenu()
 return panel
end
