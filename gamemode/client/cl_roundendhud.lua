local style = ZSHUDStyle
local cached

function GM:HUDPaintEndRound()
 if not self.RoundEnded or IsValid(pEndBoard) and pEndBoard:IsVisible() then return end
 local width = math.min(440 * style.Scale(), ScrW() - 32)
 local revision = translate.GetRevision()
 if not cached or cached.winner ~= ROUNDWINNER or cached.width ~= width or cached.revision ~= revision then
  local human, undead = ROUNDWINNER == TEAM_HUMAN, ROUNDWINNER == TEAM_UNDEAD
  cached = {winner = ROUNDWINNER, width = width, revision = revision,
   color = human and style.Accent or undead and style.Danger or style.Text,
   title = style.Fit(translate.Get(human and "end_human_victory" or undead and "end_undead_victory" or "end_round_over"), "ZSHUDNumber", width - 32),
   caption = style.Fit(translate.Get(human and "humans_win" or undead and "zombies_win" or "end_results_help"), "ZSHUDLabel", width - 32)}
 end
 local x, y = (ScrW() - width) * 0.5, ScrH() * 0.4
 style.Card(x, y, width, 94 * style.Scale(), cached.color, true)
 draw.SimpleText(cached.title, "ZSHUDNumber", ScrW() * 0.5, y + 28 * style.Scale(), cached.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
 draw.SimpleText(cached.caption, "ZSHUDLabel", ScrW() * 0.5, y + 65 * style.Scale(), style.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
