# Translations

The gamemode has dictionaries for English (`en`), Danish (`da`), Dutch (`nl`), French (`fr`), German (`de`), Italian (`it`), Korean (`ko`), European Portuguese (`pt-PT`), Russian (`ru`) and Spanish (`es-ES`). Select the language through Garry's Mod's language setting. Unsupported locales fall back to English.

English defines the canonical keys and current gameplay wording. Keep the same key IDs in every dictionary. Preserve formatting placeholders such as `%s` and `%d`, their argument order, escaped `%%`, line breaks and help-page HTML. Translate generic weapon and class descriptions while retaining proper weapon nicknames and names such as Bonemesh and Pukepus.

Worth and point-shop entries, traits, returns, mutation buffs, cosmetics and quests retain translation keys alongside their display text. Language changes refresh their labels and descriptions through the existing revision mechanism. Weapon labels and descriptions also carry keys so stored definitions and existing weapons can refresh. Explicit addon text overrides are retained.

Guild, quest, cosmetic and Forge feedback is translated for its receiving player. Item signatures, costs, callbacks, progression data and network field layouts are independent of translated text.

The language refresh runs when the language revision changes; it does not add a timer or a player/entity scan to the normal frame loop. The weapon-definition refresh uses Garry's Mod's [weapons library](https://wiki.facepunch.com/gmod/weapons), and team names update the existing [team data](https://wiki.facepunch.com/gmod/team.GetAllTeams) without replacing team scores, colors or join rules.

This translation follow-up is reviewed with dictionary, placeholder, UTF-8 and syntax checks. It does not claim new in-game visual or native multiplayer verification for every translated language.
