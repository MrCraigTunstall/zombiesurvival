--[[
English is the standard language that you should base your ID's off of.
If something isn't found in your language file then it will fall back to English.

Valid languages (from gmod's menu): bg cs da de el en en-PT es-ES et fi fr ga-IE he hr hu it ja ko lt nl no pl pt-BR pt-PT ru sk sv-SE th tr uk vi zh-CN zh-TW
You MUST use one of the above when using translate.AddLanguage
]]

--[[
RULES FOR TRANSLATORS!!
* Only translate formally. Do not translate with slang, improper grammar, spelling, etc.
* Do not translate proper things. For example, do not translate Zombie Survival (the name of the game). Do translate "survive the zombies".
  For names of weapons, you would translate only the "Handgun" part of 'Peashooter' Handgun (and the quotes if your language doesn't use ' as quotes)
  For names of classes, you would translate Bloated Zombie to whatever the word for Bloated and Zombie are. But you wouldn't translate Pukepus or Bonemesh.
* Comment out things that you have not yet translated in your language file.
  It will then fall back to this file instead of potentially using out of date wording in yours.
]]

translate.AddLanguage("en", "English")

-- Various gamemode stuff
LANGUAGE.minute_points_added						= "No damage received for a whole minute! Added %d points."
LANGUAGE.infliction_reached_class_unlocked			= "%d%% infliction has been reached! %s unlocked!"
LANGUAGE.infliction_reached							= "%d%% of humans have died!"
LANGUAGE.disconnect_killed							= "%s was disconnect killed by %s."
LANGUAGE.nail_removed_by							= "%s removed a nail belonging to %s."
LANGUAGE.removed_your_nail = "%s removed your nail."
LANGUAGE.banned_for_life_warning					= "You're banned for life so you can't purchase anything!"
LANGUAGE.need_to_be_near_arsenal_crate				= "You need to be near an Arsenal Crate to purchase items!"
LANGUAGE.cant_purchase_right_now					= "You can't purchase anything right now."
LANGUAGE.dont_have_enough_points					= "You don't have enough points."
LANGUAGE.prepare_yourself							= "Prepare yourself..."
LANGUAGE.purchased_x_for_y_points					= "Purchased %s for %d points!"
LANGUAGE.give_time_before_suicide					= "Give others time to spawn before suiciding."
LANGUAGE.no_spare_ammo_to_give						= "No spare ammo to give!"
LANGUAGE.no_person_in_range							= "No person in range!"
LANGUAGE.that_life									= "That life..."
LANGUAGE.x_damage_to_barricades						= "%d damage to barricades"
LANGUAGE.x_damage_to_humans							= "%d damage to humans"
LANGUAGE.x_brains_eaten								= "%d brains eaten"
LANGUAGE.press_jump_to_free_roam					= "Press JUMP to free roam"
LANGUAGE.press_rmb_to_cycle_targets					= "Press RMB to cycle targets"
LANGUAGE.press_lmb_to_spawn_on_them					= "Press LMB to spawn on them"
LANGUAGE.press_lmb_to_spawn							= "Press LMB to spawn"
LANGUAGE.press_reload_to_spawn_at_normal_point		= "Press RELOAD to spawn at a normal spawn point"
LANGUAGE.press_walk_to_spawn_as_x					= "Press WALK to spawn as a %s"
LANGUAGE.observing_x								= "Observing %s (%d)"
LANGUAGE.waiting_for_next_wave						= "Waiting for the next wave to begin..."
LANGUAGE.impossible									= "Impossible."
LANGUAGE.trying_to_put_nails_in_glass				= "Trying to put nails in glass is a silly thing to do."
LANGUAGE.boss_class_select							= "You will be %s the next time you're a boss zombie."
LANGUAGE.person_has_weapon							= "They already have that weapon."
LANGUAGE.cant_do_that_in_classic_mode				= "You can't do that in Classic Mode."
LANGUAGE.cant_use_x_in_classic_mode					= "You can't use %s in Classic Mode."
LANGUAGE.cant_use_x_in_zombie_escape				= "You can't use %s in Zombie Escape."
LANGUAGE.cant_use_x_noodlearm						= "You're banned from using %s!"
LANGUAGE.cant_use_x_without_sigils = "You can't use %s while sigils are disabled."
LANGUAGE.no_class_switch_in_this_mode				= "The current mode doesn't allow you to switch classes."
LANGUAGE.press_sprint_to_get_up						= "Press SPRINT to get up"
LANGUAGE.zombie_escape								= "Zombie Escape!"
LANGUAGE.nothing_for_this_ammo						= "You don't have anything that uses this type of ammo."
LANGUAGE.you_decide_to_leave_some					= "You decide to leave some for your team."
LANGUAGE.you_cant_purchase_now						= "You can't purchase items right now."
LANGUAGE.no_ammo_here								= "There's no ammo here right now."
LANGUAGE.you_redeemed								= "You have redeemed!"
LANGUAGE.kill_the_last_human						= "Kill the last human!"
LANGUAGE.kick_the_last_human						= "Kick the last human!"
LANGUAGE.you_are_the_last_human						= "YOU ARE THE LAST HUMAN!"
LANGUAGE.x_zombies_out_to_get_you					= "%d ZOMBIES ARE OUT TO GET YOU!"
LANGUAGE.x_pants_out_to_get_you						= "%d PANTS ARE OUT TO GET YOU!"
LANGUAGE.you_have_died								= "You have died."
LANGUAGE.you_were_killed_by_x						= "You were killed by %s"
LANGUAGE.you_were_kicked_by_x						= "You were kicked in the shins by %s"
LANGUAGE.arsenal_upgraded							= "Arsenal Upgraded"
LANGUAGE.final_wave									= "THE FINAL WAVE HAS BEGUN!"
LANGUAGE.final_wave_sub								= "ALL classes unlocked and the chance for redemption has ended!"
LANGUAGE.wave_x_has_begun							= "Wave %d has begun!"
LANGUAGE.x_unlocked									= "%s unlocked!"
LANGUAGE.wave_x_is_over								= "Wave %d is over!"
LANGUAGE.wave_x_is_over_sub							= "The Undead have stopped rising and the Points Shop is %d%% off."
LANGUAGE.you_are_x									= "You are %s!"
LANGUAGE.x_has_risen_as_y							= "%s has risen as %s!!"
LANGUAGE.x_has_risen								= "%s has risen!"
LANGUAGE.cant_use_worth_anymore						= "You can't use the Worth menu any more!"
LANGUAGE.class_not_unlocked_will_be_unlocked_x		= "That class is not unlocked yet. It will be unlocked at the start of wave %d."
LANGUAGE.you_are_already_a_x						= "You are already a %s."
LANGUAGE.you_will_spawn_as_a_x						= "You will spawn as a %s."
LANGUAGE.crafting_successful						= "Crafting successful!"
LANGUAGE.x_crafted_y								= "%s crafted %s."
LANGUAGE.escape_from_the_zombies					= "Escape from the zombies!"
LANGUAGE.too_close_to_another_nail					= "Too close to another nail."
LANGUAGE.object_too_damaged_to_be_used				= "That object is too damaged to be used anymore."
LANGUAGE.thanks_for_being_a_fan_of_zs				= "Thanks for being a fan of Zombie Survival!"
LANGUAGE.cant_remove_nails_of_superior_player		= "You can't remove the nails of a player doing so much better than you."
LANGUAGE.x_turned_on_noclip							= "%s turned on noclip."
LANGUAGE.x_turned_off_noclip						= "%s turned off noclip."
LANGUAGE.unlocked_on_wave_x							= "Unlocked on wave %d"
LANGUAGE.brains_eaten_x								= "Brains eaten: %s"
LANGUAGE.points_x									= "Points: %s"
LANGUAGE.hud_invasion_begins = "Invasion begins"
LANGUAGE.hud_wave_ends = "Wave ends"
LANGUAGE.hud_next_wave = "Next wave"
LANGUAGE.hud_next_round = "Next round"
LANGUAGE.hud_escape_objective = "Reach the escape point"
LANGUAGE.hud_wave_objective = "Survive the wave"
LANGUAGE.next_wave_in_x								= "Next wave in %s"
LANGUAGE.wave_ends_in_x								= "Wave ends in %s"
LANGUAGE.wave_x_of_y								= "Wave %d of %d"
LANGUAGE.zombie_invasion_in_x						= "Zombie invasion in %s"
LANGUAGE.intermission								= "Intermission"
LANGUAGE.press_f2_for_the_points_shop				= "Press F2 for the Points Shop!"
LANGUAGE.breath										= "Breath"
LANGUAGE.zombie_volunteers							= "Zombie Volunteers"
LANGUAGE.x_will_be_y_soon							= "%s will become %s soon!"
LANGUAGE.you_will_be_x_soon							= "You will become %s soon!"
LANGUAGE.x_discount_for_buying_between_waves		= "%d%% discount for buying between waves!"
LANGUAGE.number_of_initial_zombies_this_game		= "Number of initial zombies this game (%d%%): %d"
LANGUAGE.humans_closest_to_spawns_are_zombies		= "The humans closest to the zombie spawns will start as zombies."
LANGUAGE.waiting_for_players						= "Waiting for players..."
LANGUAGE.requires_x_people							= "Requires %d people"
LANGUAGE.packing_others_object						= "Packing other person's object"
LANGUAGE.packing									= "Packing"
LANGUAGE.ze_humans_are_frozen_until_x				= "Humans are frozen until %d seconds before the round starts."
LANGUAGE.loading									= "Loading..."
LANGUAGE.next_round_in_x							= "Next round in: %s"
LANGUAGE.warning									= "Warning!"
LANGUAGE.arsenal_ammo_warning = "This weapon is sold without spare ammunition. Check its ammo and buy extra if needed."
LANGUAGE.ok_and_no_reminder							= "OK and don't pop this message up anymore"
LANGUAGE.classic_mode_warning						= "This server is running Zombie Survival in 'Classic Mode'\nClassic Mode is a setting which greatly alters gameplay. Things that are changed:\n* No selection of zombie classes. Everyone uses the Classic Zombie class\n* No barricading tools such as nailing or turrets\n* More but faster waves\n\nThis is NOT original Zombie Survival!\n\n-- Servers which run classic mode will display CLASSIC MODE in the bottom left of the screen --"
LANGUAGE.classic_mode								= "CLASSIC MODE"
LANGUAGE.resist_x									= "Resist: %d%%"
LANGUAGE.right_click_to_hammer_nail					= "Right click to hammer in a nail."
LANGUAGE.nails_x									= "Nails: %d"
LANGUAGE.hammer_place_nail = "Place nail"
LANGUAGE.hammer_remove_nail = "Remove nail"
LANGUAGE.hammer_repair_strike = "Repair / strike"
LANGUAGE.resupply_box								= "Resupply Box"
LANGUAGE.purchase_now								= "Purchase now!"
LANGUAGE.integrity_x								= "Integrity: %d%%"
LANGUAGE.empty										= "EMPTY"
LANGUAGE.manual_control								= "MANUAL CONTROL"
LANGUAGE.arsenal_crate								= "Arsenal Crate"
LANGUAGE.not_enough_room_for_a_nest					= "Not enough room here for a nest!"
LANGUAGE.too_close_to_another_nest					= "Too close to another nest!"
LANGUAGE.nest_created								= "Nest created! Finish building to enable spawning here."
LANGUAGE.nest_built_by_x							= "A Flesh Creeper nest has been built by %s and is now a spawn point."
LANGUAGE.nest_destroyed								= "A Flesh Creeper nest has been destroyed."
LANGUAGE.wait_x_seconds_before_making_a_new_nest	= "You must wait %d more seconds before creating a new nest."
LANGUAGE.too_close_to_a_human						= "Too close to a human!"
LANGUAGE.too_close_to_a_spawn						= "Too close to a zombie spawn!"
--LANGUAGE.nest_already_being_built					= "This nest is already being built by someone else!"
LANGUAGE.x_has_built_this_nest_and_is_still_around	= "%s has built this nest and is still around, so you can't demolish it."
LANGUAGE.no_other_nests								= "You can't destroy a nest if only one remains."
LANGUAGE.no_free_channel							= "Radio interference from too many already being placed!"
LANGUAGE.gave_x_y_ammo_to_z							= "Gave %d %s ammo to %s"
LANGUAGE.obtained_x_y_ammo_from_z					= "Obtained %d %s ammo from %s"

-- Sigils point objectives
LANGUAGE.sigil_destroyed							= "The Undead have destroyed a Sigil!"
LANGUAGE.sigil_destroyed_only_one_remain_h			= "Only one remains! If it falls then there is no hope of escape!"
LANGUAGE.sigil_destroyed_only_one_remain_z			= "Only one remains!"
LANGUAGE.sigil_destroyed_x_remain					= "%d Sigils remaining."
LANGUAGE.last_sigil_destroyed_all_is_lost			= "The Undead have destroyed the last Sigil."
LANGUAGE.last_sigil_destroyed_all_is_lost2			= "There is no hope of escape."
LANGUAGE.prop_obj_exit_h							= "Escape!"
LANGUAGE.prop_obj_exit_z							= "Stop them!"
LANGUAGE.sigil_escapestart                          = "Escape sequence started"
LANGUAGE.sigil_escapeboss                           = "Escape sequence boss stage"
LANGUAGE.sigil_deathfog                             = "Escape sequence death fog stage"
LANGUAGE.sigil_yousurvived                          = "You've managed to survive! Waiting for other survivors..."
LANGUAGE.sigil_teleporting                          = "Teleporting to %s"

-- Message beacon messages
LANGUAGE.message_beacon_1							= "Meet up here"
LANGUAGE.message_beacon_2							= "Need defense here"
LANGUAGE.message_beacon_3							= "Need turrets here"
LANGUAGE.message_beacon_4							= "Need arsenal crates here"
LANGUAGE.message_beacon_5							= "Need medics here"
LANGUAGE.message_beacon_6							= "Ammunition box here"
LANGUAGE.message_beacon_7							= "Arsenal crate here"
LANGUAGE.message_beacon_8							= "Need force fields here"
LANGUAGE.message_beacon_9							= "Need explosives here"
LANGUAGE.message_beacon_10							= "Zombies come from here"
LANGUAGE.message_beacon_11							= "Do not enter!!"
LANGUAGE.message_beacon_12							= "Don't go out"
LANGUAGE.message_beacon_13							= "Defend this area"
LANGUAGE.message_beacon_14							= "Defend this spot"
LANGUAGE.message_beacon_15							= "Medics here"
LANGUAGE.message_beacon_16							= "Buy from my crate"
LANGUAGE.message_beacon_17							= "Barricade here"
LANGUAGE.message_beacon_18							= "Don't barricade here"
LANGUAGE.message_beacon_19							= "Don't let zombies in here"
LANGUAGE.message_beacon_20							= "This will break"
LANGUAGE.message_beacon_21							= "This place is dangerous!"
LANGUAGE.message_beacon_22							= "Beware of poison!"
LANGUAGE.message_beacon_23							= "Zombies are breaking through here!"
LANGUAGE.message_beacon_24							= "Zombies are coming. Build a barricade!"
LANGUAGE.message_beacon_25							= "Plan B here"

-- Class names
LANGUAGE.class_pvp = "PVP"
LANGUAGE.description_pvp = "An armed player class for PVP encounters."
LANGUAGE.controls_pvp = "Use your equipped weapon to fight other players."

LANGUAGE.class_zombie								= "Zombie"
LANGUAGE.class_poison_zombie						= "Poison Zombie"
LANGUAGE.class_fast_zombie							= "Fast Zombie"
LANGUAGE.class_bloated_zombie						= "Bloated Zombie"
LANGUAGE.class_classic_zombie						= "Classic Zombie"
LANGUAGE.class_super_zombie							= "Super Zombie"
LANGUAGE.class_fresh_dead							= "Fresh Dead"
LANGUAGE.class_ghoul								= "Ghoul"
LANGUAGE.class_headcrab								= "Headcrab"
LANGUAGE.class_fast_headcrab						= "Fast Headcrab"
LANGUAGE.class_poison_headcrab						= "Poison Headcrab"
LANGUAGE.class_the_tickle_monster					= "The Tickle Monster"
LANGUAGE.class_burster                              = "Burster"
LANGUAGE.class_nightmare							= "Nightmare"
LANGUAGE.class_pukepus								= "Pukepus"
LANGUAGE.class_bonemesh								= "Bonemesh"
LANGUAGE.class_crow									= "Crow"
LANGUAGE.class_wilowisp								= "Wil O' Wisp"
LANGUAGE.class_zombie_torso							= "Zombie Torso"
LANGUAGE.class_zombie_legs							= "Zombie Legs"
LANGUAGE.class_wraith								= "Wraith"
LANGUAGE.class_fast_zombie_legs						= "Fast Zombie Legs"
LANGUAGE.class_chem_zombie							= "Chem Zombie"
LANGUAGE.class_shade								= "Shade"
LANGUAGE.class_butcher								= "The Butcher"
LANGUAGE.class_flesh_creeper						= "Flesh Creeper"
LANGUAGE.class_gore_child							= "Gore Child"
LANGUAGE.class_giga_gore_child						= "Giga Gore Child"
LANGUAGE.class_reaper								= "Reaper"
LANGUAGE.class_nugget								= "Nugget"
LANGUAGE.class_boss_inferno					  	 	= "Inferno Zombie"
LANGUAGE.class_bastardzine							= "Bastardzine"
LANGUAGE.class_zombine								= "Zombine"
LANGUAGE.class_undertaker							= "The Undertaker"
LANGUAGE.class_night_stalker                        = "Night Stalker"


-- Class descriptions
LANGUAGE.description_zombie							= "The basic zombie is very durable and has powerful claws.\nIt's hard to keep down, especially if not shot in the head."
LANGUAGE.description_poison_zombie					= "This mutated zombie is not only extremely durable but has abnormal strength.\nIts body is extremely toxic and will even tear out and toss its own flesh at things too far away to hit."
LANGUAGE.description_fast_zombie					= "This bony cadaver is much faster than other zombies.\nThey aren't much of a threat by themselves but can reach nearly any area by climbing with their razor sharp claws\nThey also have no problem hunting down weak or hurt humans."
LANGUAGE.description_bloated_zombie					= "Their body is comprised of volatile, toxic chemicals.\nAlthough they move slower, they can take slightly more of a beating."
LANGUAGE.description_ghoul							= "This zombie has highly toxic flesh.\nIt's slightly weaker than other zombies but makes up for it with its debilitating attacks.\nIts claws can debuff a human for a short time, causing increased damage from other attacks."
LANGUAGE.description_headcrab						= "Headcrabs are what caused the initial infection.\nNo one knows where they truly came from.\nTheir method of attack is lunging with the sharp beaks on their belly."
LANGUAGE.description_fast_headcrab					= "The male headcrab is considerably faster but less beefy than the female.\nEither way, it's equally as annoying and deadly in groups."
LANGUAGE.description_poison_headcrab				= "This Headcrab is full of deadly neurotoxins.\nOne bite is usually enough to kill an adult human.\nIt also has the ability to spit a less potent version of its poisons.\nThe spit is just as deadly if its victim is hit in the face."
LANGUAGE.description_the_tickle_monster				= "Said to be the monster that hides in your closet at night to drag you from your bed.\nThe Tickle Monster's almost elastic arms make it extremely hard to outrun and they also make it an ideal barricade destroyer."
LANGUAGE.description_nightmare						= "An extremely rare mutation gives the Nightmare its abnormal abilities.\nStronger than the every day zombie in almost every way, the Nightmare is a force to be reckoned with.\nOne swipe of its claws is enough to put down almost any person."
LANGUAGE.description_pukepus						= "The rotting body of the Puke Pus is comprised entirely of organs used for the generation of poison.\nIt is capable of vomiting gallons of poison puke at a time making it extremely dangerous."
LANGUAGE.description_bonemesh						= "Disfigured and mangled, the Bonemesh is capable of tossing blood bombs.\nEach bomb is comprised of bones and flesh that damages humans while giving precious food to other zombies."
LANGUAGE.description_crow							= "Carrion Crows are more of a pest than they were before the infection.\nThey feed on infected flesh and become 'carriers' for the undead.\nWhy would you ever make this class not hidden?\nWhat is wrong with you?"
LANGUAGE.description_wilowisp						= "Sometimes referred to as spirits of the dead."
LANGUAGE.description_zombie_torso					= "You shouldn't even be seeing this."
LANGUAGE.description_zombie_legs					= "You shouldn't even be seeing this."
LANGUAGE.description_wraith							= "A zombie or an apparition?\nNot much is known about it besides the fact that it uses its\nunique stealth ability and sharp claws to cut things to ribbons."
LANGUAGE.description_fast_zombie_legs				= "You shouldn't even be seeing this."
LANGUAGE.description_chem_zombie					= "The Chem Zombie body is comprised of volatile, toxic chemicals.\nIt has no other means of attack besides being killed in hopes of blowing up next to any nearby humans."
LANGUAGE.description_shade							= "This spectral boss resists human attacks while dark.\nAim flashlights or spotlamps at it to burn it and weaken its protection.\nIt can lift and throw movable props. Bright light breaks its grip."
LANGUAGE.description_butcher						= "A crazed, undead butcher. It isn't very tough but anyone unlucky enough to be near it will most likely be torn to shreds."
LANGUAGE.description_flesh_creeper					= "Flesh Creepers possess the ability to create nests.\nFrom these nests, other zombified creatures emerge.\nThe way this works is unknown but it is imperative to destroy any nests or creepers."
LANGUAGE.description_gore_child						= "Once zombified, an unborn child becomes infected as well.\nPossessing no special abilities, their strength comes from their numbers."
LANGUAGE.description_giga_gore_child				= "The result of a Gore Child which has been left unchecked for too long.\nA horror to behold, their massive body is the result of zombified stem cells.\nThey also become a host for Gore Children which can always be found in tow with it."
LANGUAGE.description_reaper							= "Fast as hell an can scare the shit out of humans\n Run your foes down an eat those brains!"
LANGUAGE.description_bastardzine                    = "Once nuggets began to roam the earth, they found hosts just like their lower headcrab kin.\n This new breed of zombie is a hybrid of mass chaos, crazy fast and deadly."
LANGUAGE.description_burster                        = "This infected can explode if he killed."
LANGUAGE.description_zombine						= "When a head-crab infects a Combine Soldier this horrid zombie is created.\nThis zombie is a threat to barricades mostly an is only unlocked on later waves."
LANGUAGE.description_undertaker						= "Risen from the grave Undertaker. \nThings didn't change for him - he's still trying to put you into a tomb."
LANGUAGE.description_night_stalker					= "The shadowed version of bastardzine. \nThis unseen entity can ambush humans and knock them back, when leaping at them. \nBut when standing still or attacking and leaping, it can be visible \nBut when moving it becomes invisible. Which make this creature a dangerous threat in darkness and shadow"
LANGUAGE.description_boss_inferno                   = "The pits of hell an back, this zombie utilizes fire as a strength.\n Everything is touchs with its claws burst to flames.\n Most infernos near death will erupt in a big explosion."


-- Class control schemes
LANGUAGE.controls_zombie							= "> PRIMARY: Claws\n> SECONDARY: Scream\n> RELOAD: Moan\n> SPRINT: Feign death\n> ON FATAL HIT IN LEGS: Revive / Transform"
LANGUAGE.controls_poison_zombie						= "> PRIMARY: Claws\n> SECONDARY: Flesh toss\n> RELOAD: Scream"
LANGUAGE.controls_fast_zombie						= "> PRIMARY: Claws\n> SECONDARY: Lunge / Climb (next to wall)\n> RELOAD: Scream"
LANGUAGE.controls_bloated_zombie					= "> PRIMARY: Claws\n> SECONDARY: Moan\n> SPRINT: Feign death\n> ON DEATH: Poison Gibs"
LANGUAGE.controls_ghoul								= "> PRIMARY: Poison claws\n> SECONDARY: Flesh toss\n> SPRINT: Feign death\n> RELOAD: Scream\n> ON HIT HUMAN: Ghoul Touch"
LANGUAGE.controls_headcrab							= "> PRIMARY: Lunge attack\n> RELOAD: Burrow"
LANGUAGE.controls_fast_headcrab						= "> PRIMARY: Lunge attack"
LANGUAGE.controls_poison_headcrab					= "> PRIMARY: Lunge attack\n> SECONDARY: Spit poison\n> ON HIT HUMAN: Deadly poison\n> ON HIT POISON IN EYES: Blind\n> RELOAD: Scream"
LANGUAGE.controls_the_tickle_monster				= "> PRIMARY: Elastic claws\n> SECONDARY: Moan"
LANGUAGE.controls_nightmare							= "> PRIMARY: Death touch\n> SECONDARY: Moan"
LANGUAGE.controls_pukepus							= "> PRIMARY: Puke"
LANGUAGE.controls_bonemesh							= "> PRIMARY: Claws\n> SECONDARY: Toss blood bomb"
LANGUAGE.controls_wraith							= "> PRIMARY: Claws\n> SECONDARY: Scream\n> INVISIBILITY BASED ON MOVEMENT AND VIEW DISTANCE"
LANGUAGE.controls_chem_zombie						= "> ON DEATH: Poison Bomb"
LANGUAGE.controls_shade								= "> PRIMARY: Throw held prop\n> SECONDARY: Lift / release prop"
LANGUAGE.controls_butcher							= "> PRIMARY: Chop"
LANGUAGE.controls_flesh_creeper						= "> PRIMARY: Head Smash\n> SECONDARY: Nest"
LANGUAGE.controls_gore_child						= "> PRIMARY: Claws"
LANGUAGE.controls_giga_gore_child					= "> PRIMARY: Smash\n> SECONDARY: Throw Gore Child"
LANGUAGE.controls_reaper							= "> PRIMARY: Axe\n> RELOAD: Moan"
LANGUAGE.controls_burster                           = "> PRIMARY: Poison Bomb\n> ON DEATH: Poison Bomb"
LANGUAGE.controls_zombine							= "> PRIMARY: Claws\n> SECONDARY: Grenade"	
LANGUAGE.controls_undertaker						= "> PRIMARY: Hit\n> SECONDARY: Throw dart, that can heal zombies and damage humans."
LANGUAGE.controls_night_stalker                     = "> PRIMARY: Claws\n> SECONDARY: Lunge / Climb (next to wall)\n> RELOAD: Scream \n> INVISIBILITY WHEN MOVING"
LANGUAGE.controls_boss_inferno                      = "> PRIMARY: Incendiary Claws\n> SECONDARY: N/A\n> RELOAD: Moan\n> SPRINT: Regenerate"

-- The help file... Quite big! I wouldn't blame you if you didn't translate this part.
LANGUAGE.help_cat_introduction						= "Introduction"
LANGUAGE.help_cat_survival							= "Survival"
LANGUAGE.help_cat_barricading						= "Barricading"
LANGUAGE.help_cat_upgrades							= "Upgrades"
LANGUAGE.help_cat_being_a_zombie					= "Being a Zombie"
LANGUAGE.help_cont_introduction						= [[<p>    Welcome to Zombie Survival, the (zombie) survival simulator. ZS allows you to fight zombie attacks, create barricades, and even be part of the undead horde.</p>

<p>There are two teams: the survivors and the zombies. The humans win if they survive every wave. Some levels have special objectives to be completed, which may be optional or required to win.
If a human is killed then they'll come back as a zombie, which makes it even more difficult for the remaining humans.</p>

<p>The goal for the zombies is to kill all of the humans, making them all zombies and causing everyone to lose the round.
Zombies can earn redemption by meeting the server's kill requirement. When the current mode allows it, redemption offers a chance to return to the human team.
The humans win by surviving the round or completing the map's escape objectives. The zombies win by eliminating the surviving humans.</p>

<p>A certain amount of people are chosen (or volunteer) for being the starting zombies. The number of starting zombies is shown before the round starts.</p>

<p><b>Use the buttons up top to get help on more specific things.</b></p>

<p>Tips for this section:
<ul><li>If you leave the game as a human then you'll rejoin as a zombie.</li>
<li>After a certain amount of time has gone by, even new players will spawn as zombies.</li>
<li>Use TEAM CHAT when needed. The default key is U and allows you to speak to only your team.</li>
</ul></p>
]]
LANGUAGE.help_cont_survival							= [[<p>Tips for this section:
<ul><li>Holding the ZOOM key (default: Z) allows you to move freely through barricades while walking extremely slow.</li>
<li>Use an Arsenal Crate or the mode's trader to buy equipment. Intermissions can offer discounts; shop access depends on the mode. You can also recover supplies from fallen teammates.</li>
<li>If a human is directly killed by a zombie then they will rise again wherever they stand. Make sure you end their misery before they give you any.</li>
<li>You're only given a certain amount of Worth to play with so think carefully what you should get!</li>
<li>You can create, save, load, delete, and mark as default carts by pressing F2. This saves a ton of time which could be better spent setting up barricades or creating game plans.</li>
<li>A spot that feels safe one moment may be a death trap with more or different types of zombies roaming around. Always allow extra space and a "Plan B" if things get ugly.</li>
<li>You're useless to your team if you're not doing anything to help. You're even more useless to yourself since you're not getting any points or bigger weapons!</li>
<li>By holding your SPRINT key for about ten seconds while looking at deployed objects that you own, you can pack them up for later use.</li>
<li>Turrets without owners (a blue light) can be claimed by pressing USE on them. Ownerless turrets will not scan for targets!</li>
<li>Props that aren't nailed to something don't make very good barricades unless they're really heavy.</li>
<li>With enough punishment, doors can be thrown off their hinges.</li>
<li>Most props will become red with more and more damage.</li>
<li>Zombies can spawn on top of each other if no humans are around to witness it.</li>
<li>Most melee weapons have a longer reach than zombie claws. Use this to your advantage if you insist on defending with a melee weapon.</li>
<li>Players on the same team do not damage or collide with each other and can freely shoot and swing through each other.</li>
<li>Make sure you use a barricade to your advantage and stay behind it a good distance away from the zombies. Guns generally outrange zombie claws. Keep your distance while defending.</li>
<li>Poison damage will heal over time but enough of it can still kill you.</li>
<li>Your team members aren't always right, don't be a sheep! Zombies like to kill sheep.</li>
<li>Zombies can see your health, even through walls. Make sure to fall back when hurt as zombies will most likely try to pick you off.</li>
<li>Don't hide, zombies can sense you through walls and in complete darkness.</li>
<li>The Horde Meter shows your damage and knockback resistance. Stay close to other zombies when attacking strongholds.</li>
<li>If you don't have enough zombies to take down a barricade, try hunting for new "team mates" elsewhere.</li>
<li>Don't shoot zombies in the green gas! It quickly heals them and you're only wasting ammunition!</li>
<li>Zombies are resistant to damage in the chest and even more so in the arms and legs. Make sure you're aiming for the head as some zombies have the ability to get up again if you don't!</li>
<li>Although zombies take less damage in the legs, shooting them there will slow them down for a short time, enough to allow you or a team member to escape.</li>
</ul></p>
]]
LANGUAGE.help_cont_barricading						= [[<p>Barricading is an extremely important part of survival. It may seem like the undead aren't a threat early on but eventually they'll be powerful enough to kill your entire team in a few seconds.</p>

<p>The only thing keeping the zombies out is a well-built and well-maintained barricade.</p>

<p>There are a couple of tools that give you the ability to set this up. The one most useful tool is the hammer and nails. This allows you to nail down props which then must have the nails destroyed in order for the zombies to get to you.
Position the prop you want to nail by pressing USE on it to pick it up. You can hold SPRINT while holding it to lock it in place. Then take your hammer and right click where you want the nail to go. It's a good idea to nail the prop to a sturdy object such as a wall instead of other props.
Remember, when a prop is nailed it will forward the damage it takes to the nails themselves. You can repair nails by hitting them with the hammer but eventually they'll become too damaged to repair anymore. You can hold SHIFT with the hammer out to get a view of every single nail deployed on your screen as well as the owner.
If you think a nail is in a bad place or you'd like to reposition a prop, you can remove nails by pointing at it and pressing RELOAD. Be warned, if you take a nail that doesn't belong to you then you will be given a point penalty.
One more thing to remember: nails take less damage when they're nailed to bigger props. The bigger the size of the prop, the less damage its nails take and the other way around.</p>

<p>One other tool is the 'Aegis' Barricade Kit. This quick-deploying tool allows you to place boards on any surface or deploy them between two walls. It doesn't even need props. To use it, you need to position a board in a spot that is legal. The ghost will turn from red to green to let you know.
Deploy a board by pressing PRIMARY ATTACK. Rotate the board by using SECONDARY ATTACK and RELOAD. It uses boards for ammunition so boards you have from the Board Pack work as extra ammunition! You can pack up boards you've deployed by pressing SPRINT while pointing at it.</p>

<p>Another tool worth noting is the Turret. This tosses bullets at any zombie that gets in the way of its laser. Its only downside is that it requires ammunition. You can refill ammunition by pressing USE on it. This will give you bonus points for helping the team.
To deploy the turret, position it in a way so that the ghost is green. It must be on a solid surface (no props!). Rotate the turret with SECONDARY ATTACK and RELOAD. If you mess up, you can always pack the turret back up by pressing SPRINT while pointing at it. Remember, the turret will only fire at zombies that cross its tracking beam.</p>

<p>Tips for this section:
<ul>
<li>You get a 25% point bonus for killing zombies that are attacking a barricade!</li>
<li>Use bigger props for barricades. The nails take less damage and the prop has room for more nails. In addition to that, it even acts as cover from projectiles.</li>
</ul></p>]]
LANGUAGE.help_cont_upgrades							= [[<p>Points are obtained through killing zombies, healing team mates, and building defenses.
Use them at an Arsenal Crate or the mode's trader to buy weapons, ammunition and equipment.
Intermission discounts can stretch your points further.</p>

<p>Tips for this section:
<ul>
<li>Try planning ahead. Buy extra pistol ammunition in the Worth menu so you have plenty to spare once you get your first upgrade.</li>
<li>You still get points for assists. The greater half of the points goes to the killer and the lesser half goes to the one who assisted in the kill.</li>
<li>Worth and Points are separate. Make sure you spend all of your Worth!</li>
<li>Arsenal Crates are extremely valuable and prime targets for zombie attacks.</li>
</ul></p>]]
LANGUAGE.help_cont_being_a_zombie					= [[<p>Tips for this section:
<ul>
<li>You have an unlimited amount of lives, the humans only have one each. Don't be afraid to attack, attack, attack!</li>
<li>The regular Zombie class has the ability of durability. The only way to kill you for sure is to get shot in the head or be killed by a melee weapon. You don't need your legs.</li>
<li>Zombies can spawn on top of each other if no humans are around to see it. Check the eyes of the skull on the bottom of your screen. If they're green then you are a valid spawn point!</li>
<li>With enough practice, you can use props to slam them in to humans from a distance.</li>
<li>Destroy deployables such as turrets and especially Arsenal Crates to cripple the humans.</li>
<li>With enough punishment, doors can be thrown off their hinges.</li>
<li>Most props will become red with more and more damage.</li>
<li>The Wraith is completely invisible while standing still or at a distance.</li>
<li>The Fast Zombie's lunge attack damage scales by how long you're in the air. The more air time you get, the larger the damage. Use your claw attack when in close range!</li>
<li>In addition to being extremely tough, the Poison Zombie can rip out chunks of its own poison flesh and throw them at humans by pressing SECONDARY ATTACK.</li>
<li>Most zombie claws have two chances to hit their target. If you "hit" your target when you click your mouse button then you're guaranteed a hit as long as they remain in range.</li>
<li>The Poison Headcrab's spit projectile can confuse humans if it hits them in the head.</li>
<li>Go for the humans with low health! Other zombies are also attracted to them so they should be the easiest targets.</li>
<li>The Horde Meter shows your damage and knockback resistance. Stay close to other zombies when attacking strongholds.</li>
<li>If you don't have enough zombies to take down a barricade, try hunting for new "team mates" elsewhere.</li>
<li>If an area is too dark, try pressing your FLASHLIGHT button to toggle night vision.</li>
</ul></p>
]]

-- Place any custom stuff below here...

--[[ Anything that has an \n means a new line: Example
Hello there.\nWelcome to the server will output as:

Hello there. 
Welcome to the server

So remember that when translating]]--

-- Redeem Menu

LANGUAGE.redeemer_credit							= "Zombie Survival - created by William \"JetBoom\" Moodhe.             Zombie Survival: Bandits by MrCraigTunstall"
LANGUAGE.redeemer_save								= "CHANGE TO A HUMAN AND SAVE HUMANITY"
LANGUAGE.redeemer_kill								= "STAY AS A BANDIT AND CHOOSE TO HELP OR KILL THE HUMANS"

-- Worth Menu

LANGUAGE.worth_title								= "Select Your Survival Loadout"
LANGUAGE.worth_close								= "Press F2 to re-open the Worth Menu."
LANGUAGE.worth_worth								= "Worth: %s"
LANGUAGE.worth_worth_cost							= "%s Worth"
LANGUAGE.worth_favtab								= "Favorites"
LANGUAGE.worth_favtooltip							= "This is your default cart.\nIf you join the game late then you'll spawn with this cart."
LANGUAGE.worth_favbuy								= "Purchase this saved cart."
LANGUAGE.worth_favload								= "Load this saved cart."
LANGUAGE.worth_favremove							= "Remove this cart as your default."
LANGUAGE.worth_favdelete							= "Delete this saved cart."
LANGUAGE.worth_favdefault							= "Make this cart your default."
LANGUAGE.worth_checkout								= "Checkout"
LANGUAGE.worth_checkouttooltip						= "Self-Explanatory."
LANGUAGE.worth_random								= "Random Loadout"
LANGUAGE.worth_randomtooltip						= "Using this will randomly give you a set of items instead of normal checkout.\n Also use this to close the worth menu."
LANGUAGE.worth_clear								= "Clear Loadout"
LANGUAGE.worth_cleartooltip							= "Clears all items out of your cart."
LANGUAGE.worth_saveload								= "Save Loadout"
LANGUAGE.worth_saveloadtooltip						= "Use this to save your current cart(s) for easy checkout later."
LANGUAGE.worth_github								= "GitHub"
LANGUAGE.worth_githubtooltip						= "This will take you to the modified Zombie Survival GitHub page."
LANGUAGE.worth_forum								= "Forum"
LANGUAGE.worth_forumtooltip							= "This will take you to voidresonance.com"
LANGUAGE.worth_steam								= "Steam Group"
LANGUAGE.worth_steamtooltip							= "This will take you to our Void Resonance's Steam group."
LANGUAGE.worth_savecart								= "Save cart"
LANGUAGE.worth_entername                            = "Enter a name for this cart."
LANGUAGE.worth_name                                 = "Name"
LANGUAGE.worth_ok                                   = "OK"
LANGUAGE.worth_cancel                               = "Cancel"

-- Pointshop Menu

LANGUAGE.all_sales                                  = "All sales are final"
LANGUAGE.the_pointshop                              = "The Points Shop"
LANGUAGE.for_allapocalypse                          = "For all of your zombie apocalypse needs!"
LANGUAGE.pts_tospend                                = "Points to spend: %s"
LANGUAGE.ars_discount                               = "%s%% discount for buying between waves!"
LANGUAGE.ars_tooltip                                = "This shop is armed with the QUIK - Anti-zombie backstab device.\nMove your mouse outside of the shop to quickly close it!"
LANGUAGE.ars_worth                                  = "Worth Menu"
LANGUAGE.ars_purchase                               = "Purchase"  
LANGUAGE.ars_purchaseammo                           = "Purchase ammunition"
LANGUAGE.ars_pts                                    = "%s Points"

-- Ressuply Box

LANGUAGE.res_box_ready                              = "Ready"
LANGUAGE.res_box_seconds                            = "%i s"

-- Helios
LANGUAGE.helios_venting                             = "VENTING"
LANGUAGE.helios_heat                                = "Heat"

-- Message beacon

LANGUAGE.msgbeacon_text                             = "Select a message"

-- PendBoard (End Game)

LANGUAGE.win                                        = "You have won!"
LANGUAGE.lose                                       = "You have lost."
LANGUAGE.humans_win                                 = "The humans have survived for now."
LANGUAGE.zombies_win                                = "The undead army grows stronger."
LANGUAGE.mentions                                   = "Honorable Mentions"
LANGUAGE.end_profile                                = "Click here to view their Steam Community profile."

-- Shop Items (worth menu)

--[[Some shop items that are part of the 
arsenal crate get their translations from the Worth Menu as
it's pointless to translate the same weapon twice]]-- 

LANGUAGE.worth_peashooter                           = "'Peashooter' Handgun"
LANGUAGE.worth_battleaxe                            = "'Battleaxe' Handgun"
LANGUAGE.worth_owens                                = "'Owens' Handgun"
LANGUAGE.worth_blaster                              = "'Blaster' Shotgun"
LANGUAGE.worth_tosser                               = "'Tosser' SMG"
LANGUAGE.worth_stubber                              = "'Stubber' Rifle"
LANGUAGE.worth_crackler                             = "'Crackler' Assault Rifle"
LANGUAGE.worth_z9000                                = "'Z9000' Pulse Pistol"
LANGUAGE.worth_3pistol                              = "3 pistol ammo boxes"
LANGUAGE.worth_3shotgun                             = "3 shotgun ammo boxes"
LANGUAGE.worth_3smg                                 = "3 SMG ammo boxes"
LANGUAGE.worth_3assaultrifle                        = "3 assault rifle ammo boxes"
LANGUAGE.worth_3rifle                               = "3 rifle ammo boxes"
LANGUAGE.worth_3pulse                               = "3 pulse ammo boxes"
LANGUAGE.worth_5pistol                              = "5 pistol ammo boxes"
LANGUAGE.worth_5shotgun                             = "5 shotgun ammo boxes"
LANGUAGE.worth_5smg                                 = "5 SMG ammo boxes"
LANGUAGE.worth_5assaultrifle                        = "5 assault rifle ammo boxes"
LANGUAGE.worth_5rifle                               = "5 rifle ammo boxes"
LANGUAGE.worth_5pulse                               = "5 pulse ammo boxes"
LANGUAGE.worth_axe                                  = "Axe"
LANGUAGE.worth_crowbar                              = "Crowbar"
LANGUAGE.worth_stun                                 = "Stun Baton"
LANGUAGE.worth_knife                                = "Knife"
LANGUAGE.worth_plank                                = "Plank"
LANGUAGE.worth_fryingpan                            = "Frying Pan"
LANGUAGE.worth_cookingpot                           = "Cooking Pot"
LANGUAGE.worth_leadpipe                             = "Lead Pipe"
LANGUAGE.worth_meathook                             = "Meat Hook"
LANGUAGE.worth_medkit                               = "Medical Kit"
LANGUAGE.worth_medgun                               = "Medic Gun"
LANGUAGE.worth_150meds                              = "150 Medical Kit power"
LANGUAGE.worth_150meds2                             = "150 extra power for the Medical Kit."
LANGUAGE.worth_arsenalcrate                         = "Arsenal Crate"
LANGUAGE.worth_resupplybox                          = "Resupply Box"
LANGUAGE.worth_turret                               = "Infrared Gun Turret"
LANGUAGE.worth_turret2                              = "This automated turret requires constant upkeep to be useful.\nPress PRIMARY ATTACK to deploy the turret.\nPress SECONDARY ATTACK and RELOAD to rotate the turret.\nPress USE on a deployed turret to give it some of your SMG ammunition.\nPress USE on a deployed turret with no owner (blue light) to reclaim it."
LANGUAGE.worth_manhack                              = "Manhack"
LANGUAGE.worth_wrench                               = "Mechanic's Wrench"
LANGUAGE.worth_hammer                               = "Carpenter's Hammer"
LANGUAGE.worth_6nails                               = "Box of 12 nails"
LANGUAGE.worth_6nails2                              = "An extra box of nails for all your barricading needs."
LANGUAGE.worth_junkpack                             = "Junk Pack"
LANGUAGE.worth_spotlamp                             = "Spot Lamp"
LANGUAGE.worth_beacon                               = "Message Beacon"
LANGUAGE.worth_fieldemiter                          = "Force Field Emitter"
LANGUAGE.worth_fieldemiter_desc                     = "Blocks zombie projectiles but will not stop humans or zombies from passing.\nPress PRIMARY ATTACK to deploy.\nPress SECONDARY ATTACK and RELOAD to rotate."
LANGUAGE.worth_stone                                = "Stone"
LANGUAGE.worth_oxygentank                           = "Oxygen Tank"
LANGUAGE.worth_oxygentank2                          = "Grants significantly more underwater breathing time to the user."
LANGUAGE.worth_fit                                  = "Fit"
LANGUAGE.worth_fit2                                 = "Increases survivability by increasing maximum health by a small amount."
LANGUAGE.worth_tough                                = "Tough"
LANGUAGE.worth_tough2                               = "Increases survivability by increasing maximum health."
LANGUAGE.worth_quick                                = "Quick"
LANGUAGE.worth_quick2                               = "Gives a slight bonus to running speed."
LANGUAGE.worth_surged                               = "Surged"
LANGUAGE.worth_surged2                              = "Gives a noticeable bonus to running speed."
LANGUAGE.worth_handy                                = "Handy"
LANGUAGE.worth_handy2                               = "Gives a 25% bonus to all repair rates."
LANGUAGE.worth_engi                                 = "Engineer"
LANGUAGE.worth_engi2                                = "Gives a 50% bonus to all repair rates."
LANGUAGE.worth_surgeon                              = "Surgeon"
LANGUAGE.worth_surgeon2                             = "Increases the rate by which you can heal yourself and others with the Medical Kit by 30%. Increases Medic Gun effectiveness by 33%."
LANGUAGE.worth_medicine                             = "Medicine"
LANGUAGE.worth_medicine2                            = "Increases the rate by which you can heal yourself and others with the Medical Kit by 50%. Increases Medic Gun effectiveness by 53%."
LANGUAGE.worth_resistant                            = "Resistant"
LANGUAGE.worth_resistant2                           = "You will take half damage from poison."
LANGUAGE.worth_regen                                = "Regenerative"
LANGUAGE.worth_regen2                               = "If you drop below 50% health, you will regenerate 1 health every 6 seconds."
LANGUAGE.worth_muscular                             = "Muscular"
LANGUAGE.worth_muscular2                            = "You do 20% extra damage with melee weapons and you can carry heavy objects instead of dragging them."
LANGUAGE.worth_carpenter                            = "Carpenter"
LANGUAGE.worth_carpenter2                           = "50% Decreased delay in using hammers."
LANGUAGE.worth_cannibal                             = "Cannibalism"
LANGUAGE.worth_cannibal2                            = "You can now eat gore giblets from zombies and humans to regain health.\n Simply touch the gore gibs to eat them."
LANGUAGE.worth_ghostmode                            = "Ghost Mode"
LANGUAGE.worth_ghostmode2                           = "You can ghost through props much faster."
LANGUAGE.worth_fastresupply                         = "Resupplyer"
LANGUAGE.worth_fastresupply2                        = "Resupply boxes recharge much faster."
LANGUAGE.worth_fastteleport                         = "Teleporter"
LANGUAGE.worth_fastteleport2                        = "You teleport nearly instantly."
LANGUAGE.worth_crateshare                           = "Crate Share"
LANGUAGE.worth_crateshare2                          = "Allows to buy from crates on another client's back."
LANGUAGE.worth_crateshare3                          = "You're missing the Crate Share trait!"
LANGUAGE.worth_allergic                             = "Allergic"
LANGUAGE.worth_allergic2                            = "Poison does twice as much damage in exchange for Worth."
LANGUAGE.worth_weak                                 = "Weakness"
LANGUAGE.worth_weak2                                = "Reduces health by 30 in exchange for Worth."
LANGUAGE.worth_slow                                 = "Slowness"
LANGUAGE.worth_slow2                                = "Reduces speed by a significant amount in exchange for Worth."
LANGUAGE.worth_palasy                               = "Palsy"
LANGUAGE.worth_palasy2                              = "Reduces aiming ability while hurt in exchange for Worth."
LANGUAGE.worth_hemo                                 = "Hemophilia"
LANGUAGE.worth_hemo2                                = "Applies bleeding damage when hit in exchange for Worth."
LANGUAGE.worth_banlive                              = "Banned for Life"
LANGUAGE.worth_banlive2                             = "Disallows point purchases in exchange for Worth."
LANGUAGE.worth_clumsy                               = "Clumsy"
LANGUAGE.worth_clumsy2                              = "Makes you extremely easy to knock down in exchange for Worth."
LANGUAGE.worth_wideload                             = "Wide Load"
LANGUAGE.worth_wideload2                            = "Prevents you from ghosting through props in exchange for Worth."
LANGUAGE.worth_noodlearms                           = "Noodle Arms"
LANGUAGE.worth_noodlearms2                          = "Disallows picking up of objects in exchange for Worth."

-- Shop Items (arsenal crate) 

LANGUAGE.ars_deagle                                 = "'Zombie Drill' Desert Eagle"
LANGUAGE.ars_glock                                  = "'Crossfire' Glock 3"
LANGUAGE.ars_magnum                                 = "'Ricochet' Magnum"
LANGUAGE.ars_tacticalpistol                         = "'Eraser' Tactical Pistol"
LANGUAGE.ars_uzi                                    = "'Sprayer' Uzi 9mm"
LANGUAGE.ars_shredder                               = "'Shredder' SMG"
LANGUAGE.ars_bulletstorm                            = "'Bullet Storm' SMG"
LANGUAGE.ars_hunter                                 = "'Hunter' Rifle"
LANGUAGE.ars_reaperump                              = "'Reaper' UMP"
LANGUAGE.ars_autoen                                 = "'Ender' Automatic Shotgun"
LANGUAGE.ars_akbar                                  = "'Akbar' Assault Rifle"
LANGUAGE.ars_galil                                  = "'Riddler' Galil Assault Rifle"
LANGUAGE.ars_silencer                               = "'Silencer' SMG"
LANGUAGE.ars_stalker                                = "'Stalker' Assault Rifle"
LANGUAGE.ars_inferno                                = "'Inferno' Assault Rifle"
LANGUAGE.ars_annabele                               = "'Annabelle' Rifle"
LANGUAGE.ars_infiltrator                            = "'Infiltrator' G3sg1 Rifle"
LANGUAGE.ars_crossbow                               = "'Impaler' Crossbow"
LANGUAGE.ars_eliminator                             = "'Eliminator' SG552 Assault Rifle"
LANGUAGE.ars_sweeper                                = "'Sweeper' Shotgun"
LANGUAGE.ars_tiny                                   = "'Tiny' Slug Rifle"
LANGUAGE.ars_adonis                                 = "'Adonis' Pulse Rifle"
LANGUAGE.ars_punisher                               = "'Punisher' M249 Machine Gun"
LANGUAGE.ars_killer                                 = "'Killer' SG550 Sniper Rifle"
LANGUAGE.ars_boomstick                              = "Boom Stick"
LANGUAGE.ars_pistol_ammo                            = "pistol ammo box"
LANGUAGE.ars_shotgun_ammo                           = "shotgun ammo box"
LANGUAGE.ars_smg_ammo                               = "SMG ammo box"
LANGUAGE.ars_assaultrifle_ammo                      = "assault rifle ammo box"
LANGUAGE.ars_rifle_ammo                             = "rifle ammo box"
LANGUAGE.ars_bolt                                   = "crossbow bolt"
LANGUAGE.ars_pulse_ammo                             = "pulse ammo box"
LANGUAGE.ars_shovel                                 = "Shovel"
LANGUAGE.ars_sledge                                 = "Sledge Hammer"
LANGUAGE.ars_aegis                                  = "'Aegis' Barricade Kit"
LANGUAGE.ars_nail                                   = "Nail"
LANGUAGE.ars_nail2                                  = "It's just one nail."
LANGUAGE.ars_50meds                                 = "50 Medical Kit power"
LANGUAGE.ars_50meds2                                = "50 extra power for the Medical Kit."
LANGUAGE.ars_grenade                                = "Grenade"
LANGUAGE.ars_detpack                                = "Detonation Pack"
LANGUAGE.ars_mednade                                = "Medic Cloud Bomb"
LANGUAGE.ars_mednade_desc                           = "Explodes in to a cloud of healing gas. Heals 2HP, every second, for 10 seconds."
LANGUAGE.ars_molotov                                = "Molotov"
LANGUAGE.ars_molotov2                               = "Molotov Cocktail"
LANGUAGE.ars_molotov_desc                           = "A highly flammable concoction.\nThrow at your own risk."
LANGUAGE.ars_spinfusor                              = "'Spinfusor' Pulse Disc Launcher"
LANGUAGE.ars_spinfusor_desc                         = "Launches pulse projectiles that react on walls, sending energy back in the direction they travelled."
LANGUAGE.ars_helios                                 = "Helios' Gluon Gun"
LANGUAGE.ars_helios_desc                            = "Projects a stream of gluons at the target, causing immense damage."
LANGUAGE.ars_gluon                                  = "Gluon Gun"

-- Shop Items (zombie shop)
-- Normal Mutations
LANGUAGE.zshop_alphazomb                            = "Alpha Zombie"
LANGUAGE.zshop_alphazomb2                           = "+50 maximum health when you spawn as any zombie class. Lasts until the round ends."
LANGUAGE.zshop_zombsprint                           = "Zombie Sprint"
LANGUAGE.zshop_zombsprint2                          = "Press Reload (R by default) to toggle sprinting: +60% movement speed with compatible zombie claws. Class-specific sprint abilities keep their existing speed. Taking damage stops the sprint unless you own Zombie Guard. Lasts until the round ends."
LANGUAGE.zshop_zombguard                            = "Zombie Guard"
LANGUAGE.zshop_zombguard2                           = "Requires Zombie Sprint to have an effect. Taking damage no longer stops your sprint; it does not reduce incoming damage. Lasts until the round ends."
-- Boss Mutations
LANGUAGE.zshop_bossphysicshazard                    = "Physics Hazard"
LANGUAGE.zshop_bossphysicshazard2                   = "Shade only: raises the requested prop throw speed from 3,500 to 6,000 units per second. Server physics limits can cap the actual speed below this. Prop weight limits are unchanged. Lasts until the round ends."

-- Craft Weapons 

LANGUAGE.craft_electricshovel                       = "Electric Shovel"
LANGUAGE.craft_empower                              = "Empowerment Tool"
LANGUAGE.craft_empower_desk                         = "While it's useless as a weapon, it seems to have a mystical property while you hold it."
LANGUAGE.craft_empowercrowbar                       = "Empowered Crowbar"
LANGUAGE.craft_hammergod                            = "Hammergod"
LANGUAGE.craft_infinity                             = "'Infinity' Handgun"
LANGUAGE.craft_glock9                               = "'Crossfire' Glock 9"
LANGUAGE.medkitgod                                  = "Medkit God"
LANGUAGE.craft_infboomstick                         = "Infinity Boom Stick"
LANGUAGE.craft_infdeagle                            = "'Infinity' Desert Eagle"
LANGUAGE.craft_infm249                              = "'Infinity M249' Machine Gun"
LANGUAGE.craft_infplank                             = "Infinity Plank"
LANGUAGE.craft_infinochet                           = "'Infinochet' Handgun"
LANGUAGE.craft_deagleredeemers                      = "'Redemption' Desert Eagles"
LANGUAGE.craft_dualboomstick                        = "Dual Boom Stick"
LANGUAGE.craft_dualboomstickdesk                    = "These shotguns allow you to load up to four shells in the chamber at once. Hold down reload for faster loading of each shell."
LANGUAGE.craft_empowershovel                        = "Empowered Shovel"
LANGUAGE.craft_empowerkongol                        = "Empowered Kongol Axe"
LANGUAGE.craft_jethammer                            = "Jet Hammer"
LANGUAGE.craft_jethammerdesk                        = "Powered by powerful jet engines, this hammer still takes time to load up but has extreme damage and knockback output in return."
LANGUAGE.craft_kongol                               = "Kongol Axe"
LANGUAGE.craft_multiinferno                         = "'Multi Inferno' AUG"
LANGUAGE.craft_nukemasher                           = "Nuke Masher"
LANGUAGE.craft_scar                                 = "'Terminus' SCAR-L"
LANGUAGE.craft_volcanoarm                           = "'Volcano Arm Handgun'"
LANGUAGE.craft_volcanoarmdesk                       = "This gun deals extremely large amounts of damage. That's it."

-- Weapon Names 

LANGUAGE.wn_bonemesh                                = "Bone Mesh"
LANGUAGE.wn_chem                                    = "Chem Zombie"
LANGUAGE.wn_crow                                    = "Crow"
LANGUAGE.wn_detpack                                 = "Remote Detonation Pack"
LANGUAGE.wn_turret                                  = "Gun Turret"
LANGUAGE.wn_headcrab                                = "Headcrab"
LANGUAGE.wn_pheadcrab                               = "Poison Headcrab"
LANGUAGE.wn_poisonzombie                            = "Poison Zombie"
LANGUAGE.wn_wisp                                    = "Will O' Wisp"
LANGUAGE.wn_spotlmp                                 = "Spot Lamp"
LANGUAGE.wn_wraith                                  = "Wraith"
LANGUAGE.wn_zombie                                  = "Zombie"
LANGUAGE.wn_bloatedzombie                           = "Bloated Zombie"
LANGUAGE.wn_buststick                               = "Bust-on-a-stick"
LANGUAGE.wn_butcherknife                            = "Butcher Knife"
LANGUAGE.wn_detpackremote                           = "Detonation Pack Remote"
LANGUAGE.wn_drone                                   = "Drone"
LANGUAGE.wn_droncontroll                            = "Drone Control"
LANGUAGE.wn_hammerelectro                           = "Electrohammer"
LANGUAGE.wn_fheadcrab                               = "Fast Headcrab"
LANGUAGE.wn_fastlegs                                = "Fast Zombie Kung Fu"
LANGUAGE.wn_fists                                   = "Fists"
LANGUAGE.wn_freshcreeper                            = "Flesh Creeper"
LANGUAGE.wn_ghoul                                   = "Ghoul"
LANGUAGE.wn_turretcontroll                          = "Gun Turret Controller"
LANGUAGE.wn_keyboard                                = "Keyboard"
LANGUAGE.wn_lamp                                    = "Lamp"
LANGUAGE.wn_manhacksaw                              = "Manhack - Saw Attachment"
LANGUAGE.wn_manhackcontroll                         = "Manhack Control"
LANGUAGE.wn_megamasher                              = "Mega Masher"
LANGUAGE.wn_nightmare                               = "Nightmare"
LANGUAGE.wn_pot                                     = "Pot"
LANGUAGE.wn_pukepus                                 = "Puke Pus"
LANGUAGE.wn_redeemers                               = "'Redeemers' Dual Handguns"
LANGUAGE.wn_sawhack                                 = "Sawhack"
LANGUAGE.wn_ticlemonster                            = "The Tickle Monster"
LANGUAGE.wn_waraxe                                  = "'Waraxe' Handgun"
LANGUAGE.wn_zombielegs                              = "Zombie Kung Fu"
LANGUAGE.weapon_katana                              = "Katana"
LANGUAGE.weapon_python                              = "'Python' Magnum"
LANGUAGE.wn_suicidebmb                              = "Suicide Bomb"
LANGUAGE.wn_explosivecrowbar                        = "Explosive Crowbar"
LANGUAGE.wn_explosiveredeemers                      = "Explosive 'Redeemers' Dual Handguns"
LANGUAGE.wn_claws                                   = "Claws"

-- Special Weapons (admins only things)

LANGUAGE.wn_gokufists                               = "Goku's Fists"

-- Item Descriptions 

LANGUAGE.z900_desk                                  = "Although the Z9000 does not deal that much damage, the pulse shots it fires will slow targets."
LANGUAGE.knife_desk                                 = "Deals double damage to the back."
LANGUAGE.crowbar_desk                               = "Instantly kills headcrabs."
LANGUAGE.stun_desk                                  = "Although weak compared to the other weapons, this baton\nhas the ability to slow zombies with an electric shock."
LANGUAGE.wrench_desk                                = "This tool can be used to repair deployables as long as they were not damaged recently."
LANGUAGE.manhack_desk                               = "A deployable, remotely controlled device.\nIdeal for scouting but also can be used for attacking from safety."
LANGUAGE.ars_desk                                   = "This crate is invaluable to survival. It allows people to purchase new weapons, tools, ammunition, etc.\nThe deployer gets a 7% commission on purchases not made by themselves.\nPress PRIMARY ATTACK to deploy the crate.\nPress SECONDARY ATTACK and RELOAD to rotate the crate."
LANGUAGE.ars_resupply                               = "Allows survivors to get ammunition for their current weapon. Each person can only use the box once every so often.\nPress PRIMARY ATTACK to deploy the box.\nPress SECONDARY ATTACK and RELOAD to rotate the box."
LANGUAGE.medkit_desk                                = "An advanced kit of medicine, bandages, and morphine.\nVery useful for keeping a group of survivors healthy.\nUse PRIMARY FIRE to heal other players.\nUse SECONDARY FIRE to heal yourself.\nHealing other players is not only faster but you get a nice point bonus!"
LANGUAGE.medgun_desk                                = "Fires medical darts which can heal at a range. Although less potent than a full medical kit, it can be fired rapidly and used at a range."
LANGUAGE.carpenderhm_desk                           = "A simple but extremely useful tool. Allows you to hammer in nails to make barricades.\nPress SECONDARY FIRE to hammer in nail. It will be attached to whatever is behind it.\nPress RELOAD to take a nail out.\nUse PRIMARY FIRE to bash zombie brains or to repair damaged nails.\nYou get a point bonus for repairing damaged nails but a point penalty for removing another player's nails."
LANGUAGE.junk_desk                                  = "It's simply a pack of wooden junk kept together with some duct tape.\nVery useful for making barricades when no materials are around.\nNeeds something like a hammer and nails to keep the things in place."
LANGUAGE.msgbeacon_desk                             = "This beacon allows you to display messages to all other humans in range.\nPress SECONDARY ATTACK to select different messages.\nPress PRIMARY ATTACK to deploy.\nPress SPRINT on a deployed message beacon that you own to pick it up."
LANGUAGE.femiter_desk                               = "Blocks bullets and other projectiles but will not stop humans, zombies, or other creatures from passing.\nPress PRIMARY ATTACK to deploy.\nPress SECONDARY ATTACK and RELOAD to rotate."
LANGUAGE.stone_desk                                 = "A simple stone found laying pretty much anywhere."
LANGUAGE.deagle_desk                                = "This handgun uses high-powered rounds that have more knockback than others."
LANGUAGE.erazer_desk                                = "Damage increases as remaining bullets decrease. The last shot is worth triple damage."
LANGUAGE.magnum_desk                                = "This gun's bullets will bounce off of walls which will then deal extra damage."
LANGUAGE.stalker_desk                               = "Using this gun will severely reduce the distance in which zombies can see your aura."
LANGUAGE.hunter_desk                                = "Fires special large caliber rounds. The reloading time is slow but it packs a powerful punch."
LANGUAGE.bulletstorm_desk                           = "Hold right click to use the Storm firing mode: fire rate is reduced to 60% but two bullets are fired at once."
LANGUAGE.annabele_desk                              = "This modified hunting rifle's bullets will explode in to smaller bullets upon hitting a hard surface."
LANGUAGE.crossbow_desk                              = "This ancient weapon can easily skewer groups of zombies."
LANGUAGE.tiny_desk                                  = "A powerful precision rifle with a two-round base magazine. Headshot damage depends on the target and its damage resistance."
LANGUAGE.boom_desk                                  = "This shotgun allows you to load up to four shells in the chamber at once. Hold down reload for faster loading of each shell."
LANGUAGE.adonis_desk                                = "Deals massive damage and slows targets."
LANGUAGE.shovel_desk                                = "Instantly kills zombies that are knocked down."
LANGUAGE.grenade_desk                               = "A simple fragmentation grenade.\nWhen used in the right conditions, it can obliterate groups of zombies."
LANGUAGE.detpack_desk                               = "A pack of explosives that can be placed on surfaces and detonated remotely.\nPress PRIMARY ATTACK to deploy.\nPress PRIMARY ATTACK again to detonate.\nPress SPRINT on a deployed detonation pack to disarm and retrieve it."
LANGUAGE.aegis_desk                                 = "A ready-to-go, all-in-one board deployer.\nIt automatically deploys the board and then firmly attaches it to almost any surface.\nUse PRIMARY FIRE to deploy boards.\nUse SECONDARY FIRE and RELOAD to rotate the board.\nA ghost of the board shows you if placement is valid or not."
LANGUAGE.spotlmp_desk                               = "This lamp is a watchful eye which illuminates an area.\nPress PRIMARY ATTACK to deploy.\nPress SECONDARY ATTACK and RELOAD to rotate."
LANGUAGE.medkit_text                                = "Medical Kit"
LANGUAGE.wn_detpackremotedes                        = "Allows the user to remotely detonate their detonation packs."
LANGUAGE.wn_dronedes                                = "A deployable, remotely controlled device.\nIdeal for scouting, retrieval, and targeted attacks."
LANGUAGE.wn_droncontrolldes                         = "Controller for your Drone."
LANGUAGE.wn_turretcontrolldes                       = "Allows the user to manually take control of any turrets they own."
LANGUAGE.wn_manhacksawdes                           = "A modified manhack with a saw blade attachment.\nDoes significantly more damage and is more durable. Slightly less easy to control."
LANGUAGE.wn_manhackcontrolldes                      = "Controller for your Manhack."
LANGUAGE.wn_manhacksawcontrolldes                   = "Controller for your modified Manhack."
LANGUAGE.wn_oxygentankdes                           = "Grants the user much higher air capacity."
LANGUAGE.wn_manhacksawcontroll                      = "A modified manhack with a saw blade attachment.\nDoes significantly more damage and is more durable. Slightly less easy to control."

-- Honorable Mentions 

LANGUAGE.hm_most_zombies_killed                     = "Most zombies killed"
LANGUAGE.hm_most_zombies_killed2                    = "by %s, with %d killed zombies."
LANGUAGE.hm_most_dmg_undead                         = "Most damage to undead"
LANGUAGE.hm_most_dmg_undead2                        = "goes to %s, with a total of %d damage dealt to the undead."
LANGUAGE.hm_pacifist                                = "Pacifist"
LANGUAGE.hm_pacifist2                               = "goes to %s for not killing a single zombie and still surviving!"
LANGUAGE.hm_most_helpful                            = "Most helpful"
LANGUAGE.hm_most_helpful2                           = "goes to %s for assisting in the disposal of %d zombies."
LANGUAGE.hm_last_human                              = "Last Human"
LANGUAGE.hm_last_human2                             = "goes to %s for being the last person alive."
LANGUAGE.hm_outlander                               = "Outlander"
LANGUAGE.hm_outlander2                              = "goes to %s for getting killed %d feet away from a zombie spawn."                       
LANGUAGE.hm_good_doctor                             = "Good Doctor"
LANGUAGE.hm_good_doctor2                            = "goes to %s for healing their team for %d points of health."
LANGUAGE.hm_handy_man                               = "Handy Man"
LANGUAGE.hm_handy_man2                              = "goes to %s for getting %d barricade assistance points."
LANGUAGE.hm_scarecrow                               = "Scarecrow"
LANGUAGE.hm_scarecrow2                              = "goes to %s for killing %d poor crows."
LANGUAGE.hm_most_brains_eaten                       = "Most brains eaten"
LANGUAGE.hm_most_brains_eaten2                      = "by %s, with %d brains eaten."
LANGUAGE.hm_most_dmg_tohumans                       = "Most damage to humans"
LANGUAGE.hm_most_dmg_tohumans2                      = "goes to %s, with a total of %d damage given to living players."
LANGUAGE.hm_last_bite                               = "Last Bite"
LANGUAGE.hm_last_bite2                              = "goes to %s for ending the round."
LANGUAGE.hm_most_useful                             = "Most useful to opposite team"
LANGUAGE.hm_most_useful2                            = "goes to %s for giving up a whopping %d kills!"
LANGUAGE.hm_stupid                                  = "Stupid"
LANGUAGE.hm_stupid2                                 = "is what %s is for getting killed %d feet away from a zombie spawn."
LANGUAGE.hm_salesman                                = "Salesman"
LANGUAGE.hm_salesman2                               = "is what %s is for having %d points worth of items taken from their arsenal crate."
LANGUAGE.hm_warehouse                               = "Warehouse"
LANGUAGE.hm_warehouse2                              = "describes %s well since they had their resupply boxes used %d times."
LANGUAGE.hm_spawn_point                             = "Spawn Point"
LANGUAGE.hm_spawn_point2                            = "goes to %s for having %d zombies spawn on them."
LANGUAGE.hm_crow_fighter                            = "Crow Fighter"
LANGUAGE.hm_crow_fighter2                           = "goes to %s for annihilating %d of his crow brethren."
LANGUAGE.hm_minor_annoyance                         = "Minor Annoyance"
LANGUAGE.hm_minor_annoyance2                        = "is what %s is for dealing %d damage to barricades while a crow."
LANGUAGE.hm_barricade_destroyer                     = "Barricade Destroyer"
LANGUAGE.hm_barricade_destroyer2                    = "goes to %s for doing %d damage to barricades."
LANGUAGE.hm_nest_destroyer                          = "Nest Destroyer"
LANGUAGE.hm_nest_destroyer2                         = "goes to %s for destroying %d nests."
LANGUAGE.hm_nest_master                             = "Nest Master"
LANGUAGE.hm_nest_master2                            = "goes to %s for having %d zombies spawn through their nest."

-- Weapon Titles

LANGUAGE.title_worthguns                            = "Weaponry"
LANGUAGE.title_guns                                 = "Hand Guns"
LANGUAGE.title_shotguns                             = "Shotguns"
LANGUAGE.title_smg                                  = "SMG"
LANGUAGE.title_assault                              = "Assault"
LANGUAGE.title_rifles                               = "Rifles"
LANGUAGE.title_ammo                                 = "Ammunition"
LANGUAGE.title_melee                                = "Melee Weapons"
LANGUAGE.title_tools                                = "Tools"
LANGUAGE.title_other                                = "Other"
LANGUAGE.title_traits                               = "Traits"
LANGUAGE.title_returns                              = "Returns"
LANGUAGE.title_classm                               = "Class Mutations"
LANGUAGE.title_bossm                                = "Boss Mutations"

-- Main Menu (F1 menu)

LANGUAGE.mm_menu                                    = "Main Menu"
LANGUAGE.mm_pm_selection                            = "Player model selection"
LANGUAGE.mm_pm_color                                = "Player color"
LANGUAGE.mm_color                                   = "Colors"
LANGUAGE.mm_w_color                                 = "Weapon color"
LANGUAGE.mm_close                                   = "Close"
LANGUAGE.mm_credits                                 = "Credits"
LANGUAGE.mm_credits2                                = "ZS:R Credits"
LANGUAGE.mm_options                                 = "Options"
LANGUAGE.mm_pc                                      = "Player color"
LANGUAGE.mm_pm                                      = "Player model"
LANGUAGE.mm_pm2                                     = "Player models"
LANGUAGE.mm_pm3                                     = "Models"
LANGUAGE.mm_back                                    = "Back" 
LANGUAGE.mm_help                                    = "Help" 
LANGUAGE.mm_pm_messg                                = "You've changed your desired player model to %s"
LANGUAGE.mm_sp                                      = "Spectate"
LANGUAGE.mm_unsp                                    = "Un-Spectate"
LANGUAGE.mm_spectators                              = "Spectators"
LANGUAGE.spectator_now                              = "You are now a Spectator"
LANGUAGE.spectator_cantchange                       = "You can't change during wave 0"
LANGUAGE.spectator_cantchange2                      = "This server has disabled spectator mode"
LANGUAGE.spectator_cantchange3                      = "You can't change during last human phase"
LANGUAGE.spectator_canchange_in_x                   = "You can change from spectator in %s"


-- Weapon Database

LANGUAGE.wb_database                                = "Weapon Database"
LANGUAGE.wb_wspeed                                  = "Movement speed"
LANGUAGE.wb_mdmg                                    = "Damage"
LANGUAGE.wb_range                                   = "Range"
LANGUAGE.wb_msize                                   = "Size"
LANGUAGE.wb_clipsize                                = "Clip size"
LANGUAGE.wb_dmg                                     = "Damage"
LANGUAGE.wb_numshots                                = "Number of shots"
LANGUAGE.wb_delay                                   = "Rate of fire"
LANGUAGE.wb_minaccu                                 = "Minimum accuracy"
LANGUAGE.wb_maxaccu                                 = "Maximum accuracy"

-- Class Selection

LANGUAGE.close                                      = "Close"
LANGUAGE.normal_selection                           = "Back to normal class menu..."
LANGUAGE.boss_selection                             = "Select desired boss class..."
LANGUAGE.mutations_selection                        = "Mutations"
LANGUAGE.mutation_search = "Search all mutations..."
LANGUAGE.mutation_empty = "No mutations match your search."
LANGUAGE.worth_search = "Search items or saved loadouts..."
LANGUAGE.worth_empty = "No items or loadouts match your search."
LANGUAGE.classes_and                                = "and"
LANGUAGE.classes_undeadclasses                      = "UNDEAD CLASSES"
LANGUAGE.classes_chooseresawn                       = "Choose the class you want to respawn as."
LANGUAGE.classes_hp_x                               = "HP : %s"
LANGUAGE.classes_speed_x                            = "SPEED : %s"
LANGUAGE.classes_dmg_x                              = "DMG : %s"
LANGUAGE.classes_force_x                            = "FORCE : %s"

-- Options

LANGUAGE.options_gameplay                           = "Gameplay"
LANGUAGE.options_weapon                             = "Weapon"
LANGUAGE.options_visual                             = "Visual"
LANGUAGE.options_sound                              = "Sound"
LANGUAGE.options_player                             = "Player"


LANGUAGE.options_options                            = "Options"
LANGUAGE.options_no_discord                         = "Don't show the official Discord link in chat"
LANGUAGE.options_no_ars_crate                       = "Don't show arsenal crates through walls"
LANGUAGE.options_no_status_ars_crate                = "Don't show arsenal crates on clients"
LANGUAGE.options_old_hud                            = "Use classic health HUD"
LANGUAGE.options_no_resupply                        = "Don't show resupply boxes through walls"
LANGUAGE.options_no_floating_score                  = "Don't show point floaters"
LANGUAGE.options_iron_sights_crosshair              = "Draw crosshair in ironsights"
LANGUAGE.options_film_mode                          = "Film Mode (disable most of the HUD)"
LANGUAGE.options_beats                              = "Enable ambient music"
LANGUAGE.options_play_music                         = "Enable last human music"
LANGUAGE.options_post_processing                    = "Enable post processing"
LANGUAGE.options_color_mod                          = "Enable Color Mod"
LANGUAGE.options_draw_pain_flash                    = "Enable pain flashes"
LANGUAGE.options_no_crosshair_rotate                = "No crosshair rotate"
LANGUAGE.options_auras                              = "Enable human health auras"
LANGUAGE.options_damage_floaters                    = "Enable damage indicators"
LANGUAGE.options_movement_view_roll                 = "Enable movement view roll"
LANGUAGE.options_always_show_nails                  = "Always display nail health"
LANGUAGE.options_show_old_baseoutlined_hud          = "Show old base outlined HUD"
LANGUAGE.options_no_redeem                          = "Disable automatic redeeming (next round)"
LANGUAGE.options_no_bandit                          = "Disable becoming a bandit"
LANGUAGE.options_always_volunteer                   = "Always volunteer to start as a zombie"
LANGUAGE.options_no_boss_pick                       = "Prevent being picked as a boss zombie"
LANGUAGE.options_suicide_on_change                  = "Automatic suicide when changing classes"
LANGUAGE.options_intro_music                        = "Enable intro music"
LANGUAGE.options_music_volume                       = "Music volume"
LANGUAGE.options_transparency_radius                = "Transparency radius"
LANGUAGE.options_film_grain                         = "Film grain"
LANGUAGE.options_crosshair_p                        = "Crosshair primary color"
LANGUAGE.options_crosshair_s                        = "Crosshair secondary color"
LANGUAGE.options_hp_full                            = "Health aura color - Full health"
LANGUAGE.options_hp_no                              = "Health aura color - No health"
LANGUAGE.options_beatset_zombie                     = "Zombie ambient beat set"
LANGUAGE.options_beatset_human                      = "Human ambient beat set"
LANGUAGE.options_weapon_hud_mode                    = "Weapon HUD display style"
LANGUAGE.options_thirdpersoned                      = "Third person view point"
LANGUAGE.options_proprotation                       = "Prop rotation snap angle"


-- Help menu

LANGUAGE.help_help                                  = "Help"
LANGUAGE.help_credits                               = "Credits"
LANGUAGE.help_credits2                              = "Zombie Survival : Redemption"

-- Scoreboard (teams)

LANGUAGE.team_humans                                = "Survivors"
LANGUAGE.team_zombie                                = "Zombies"

-- Scoreboard (tags)
LANGUAGE.tag_jetboom                                = "JetBoom\nCreator of Zombie Survival!"
LANGUAGE.tag_craig                                  = "MrCraigTunstall\nCoder of Zombie Survival Redemption."
LANGUAGE.tag_flair                                  = "Flairieve\nThat Awesome Cat!"
LANGUAGE.tag_mka                                    = "Mka0207\nConcepted and created Zombie Survival Redemption."
LANGUAGE.tag_d3                                     = "D3\nAssistant coder of Zombie Survival Redemption."
LANGUAGE.tag_gabi                                   = "Gabi\nHollowcreek Owner."

LANGUAGE.tag_ru                                     = "berry\nRussian Translator."
LANGUAGE.tag_es                                     = "Sulfito\nSpanish Translator."
LANGUAGE.tag_ko                                     = "Sandball\nKorean Translator."

LANGUAGE.tag_bot                                    = "Beep Boop!\nI'm a bot!"
LANGUAGE.tag_sa                                     = "Super Admin"
LANGUAGE.tag_admin                                  = "Admin"
LANGUAGE.tag_mod                                    = "Moderator"
LANGUAGE.tag_user                                   = "User"
LANGUAGE.tag_supporter                              = "ZSR Supporter"

-- ALT menu

LANGUAGE.alt_title = "Supplies"
LANGUAGE.alt_hint = "Drop supplies or share with teammates."
LANGUAGE.alt_ammunition = "AMMUNITION"
LANGUAGE.alt_actions = "WEAPON ACTIONS"
LANGUAGE.alt_gw                                     = "Give Weapon"
LANGUAGE.alt_gw5                                    = "Give Weapon and 5 clips"
LANGUAGE.alt_dw                                     = "Drop weapon"
LANGUAGE.alt_ec                                     = "Empty clip"
LANGUAGE.alt_drop                                   = "Drop"
LANGUAGE.alt_give                                   = "Give"

-- Ammo names

LANGUAGE.ammo_pistol                                = "Pistol"
LANGUAGE.ammo_smg                                   = "SMG"
LANGUAGE.ammo_rifle                                 = "Rifle"
LANGUAGE.ammo_bolts                                 = "Bolts"
LANGUAGE.ammo_buckshots                             = "Buckshot"
LANGUAGE.ammo_boards                                = "Boards"
LANGUAGE.ammo_grenade                               = "Grenades"
LANGUAGE.ammo_turrets                               = "Turrets"
LANGUAGE.ammo_meds                                  = "Medical Supplies"
LANGUAGE.ammo_nail                                  = "Nails"
LANGUAGE.ammo_ars                                   = "Arsenal Crates"
LANGUAGE.ammo_beacons                               = "Beacons"
LANGUAGE.ammo_forcefilds                            = "Force Field Emitters"
LANGUAGE.ammo_spotlamp                              = "Spot Lamps"
LANGUAGE.ammo_stone                                 = "Stones"
LANGUAGE.ammo_pulse                                 = "Pulse Shots"

-- Player HUD things

LANGUAGE.pl_poison                                  = "POISON!"
LANGUAGE.pl_bleed                                   = "BLEED!"
LANGUAGE.pl_ghtc                                    = "GHOUL TOUCH!"
LANGUAGE.carrying_prop                              = "Carrying [%s]"
LANGUAGE.stay_from_zombie_spawns                    = "Stay Away from the Zombie Spawns!"
LANGUAGE.invasion_in                                = "The invasion will begin in..."
LANGUAGE.wave_intermission                          = "Wave Intermission:"
LANGUAGE.wave                                       = "Wave:"
LANGUAGE.health                                     = "Health:"
LANGUAGE.health_ghosting                            = "Ghosting"

-- Floating Score

LANGUAGE.fc_assisted                                = "(assisted)"
LANGUAGE.fc_assist                                  = "(assist)"
LANGUAGE.fc_point                                   = "point"
LANGUAGE.fc_s                                       = "s"
LANGUAGE.fc_munch                                   = "MUNCH!"
LANGUAGE.fc_brainget                                = "BRAIN GET!"
LANGUAGE.fc_joinus                                  = "JOIN US!"
LANGUAGE.fc_oneofus                                 = "ONE OF US!"
LANGUAGE.fc_buttmagned                              = "BUTT MANGLED!"
LANGUAGE.fc_chomp                                   = "CHOMP!"

-- Credits

LANGUAGE.credits_credits                            = "Zombie Survival Credits"


-- Tier System

LANGUAGE.dont_have_weapon_x                         = "Can't sell, you do not have a %s"
LANGUAGE.not_unlocked_yet_unlocked_on_x             = "That weapon is not unlocked yet. It will be unlocked at the start of wave %d."
LANGUAGE.weapon_tier_x                              = "Weapon tier %d unlocked."
LANGUAGE.sold_x_for_y_points                        = "Sold %s for %d points!"

-- Spray mon

LANGUAGE.spray_spraycant                            = "You can't place your spray here."
LANGUAGE.spray_sprayedby                            = "Sprayed by:"

-- Mutations

LANGUAGE.you_dont_have_enough_btokens               = "You don't have enough damage tokens!"
LANGUAGE.purchased_x_for_y_btokens                  = "Purchased %s for %d damage tokens!"
LANGUAGE.cant_buy_mutations                         = "You can't use the Mutation Shop right now!"
LANGUAGE.mutationstokens                            = "%s Tokens"
LANGUAGE.mutationsdamagetokens                      = "Damage Tokens: %s"

-- Discord / misc

LANGUAGE.post_discord_init_text                     = "Hey there! This gamemode has an official Discord.\nYou can be part of it by following this link - \nhttps://discord.me/voidresonance"
LANGUAGE.post_discord_init_text2                    = "You can disable this message with the console command\nzs_nodiscord 1"


LANGUAGE.options_melee_crosshair = "Melee crosshair"
LANGUAGE.options_melee_crosshair_size = "Melee crosshair size"
LANGUAGE.crosshair_off = "Off"
LANGUAGE.crosshair_cross = "Cross"
LANGUAGE.crosshair_dot = "Dot"
LANGUAGE.crosshair_open_cross = "Open cross"

LANGUAGE.ze_weapon_menu = "Zombie Escape weapons"
LANGUAGE.ze_weapon_help = "Choose your primary weapon with F2. You can exchange it once before the round starts. Your choice is saved for future spawns; changing weapons preserves your ammo budget."
LANGUAGE.ze_weapon_unavailable = "Choose a weapon while alive before the Zombie Escape round starts."
LANGUAGE.ze_weapon_invalid = "That weapon is not available on this server."
LANGUAGE.ze_weapon_wait = "Please wait before choosing again."
LANGUAGE.ze_weapon_locked = "You have already exchanged your weapon this spawn."
LANGUAGE.ze_weapon_selected = "Weapon selected. Your choice is saved for future spawns."
LANGUAGE.ze_weapon_next_spawn = "Your weapon choice is saved for your next spawn."

LANGUAGE.worth_repairemitter = "Repair field emitter"
LANGUAGE.worth_repairemitter_desc = "Automatically repairs nearby nailed barricades within 160 units. Repairs up to 60 health per second, with a maximum of 20 per prop. Uses each prop's remaining repair capacity; overlapping fields do not stack on the same prop. Can be packed up. Requires a human owner."
LANGUAGE.ammo_repairemitter = "Repair field emitters"

LANGUAGE.player_level = "Level %s"
LANGUAGE.cant_remove_barricade_expert_nail = "Barricade Expert protects these nails from players below the owner's level."
LANGUAGE.nail_cannot_place = "You cannot place a nail"

LANGUAGE.mapvote_title = "Map vote"
LANGUAGE.mapvote_search = "Search available maps"
LANGUAGE.mapvote_vote = "Vote for map"
LANGUAGE.mapvote_map = "Map"
LANGUAGE.mapvote_count = "Votes"
LANGUAGE.mapvote_choose = "Choose the map you would like to play next."
LANGUAGE.mapvote_loading = "Loading the server's available maps..."
LANGUAGE.mapvote_loading_progress = "Receiving map list... %d%%"
LANGUAGE.mapvote_load_failed = "Map list could not be loaded. Refresh to retry."
LANGUAGE.mapvote_refresh_wait = "Please wait before refreshing the map list."
LANGUAGE.mapvote_refresh_countdown = "Refresh (%ds)"
LANGUAGE.mapvote_empty = "The server has no maps available for voting."
LANGUAGE.mapvote_no_matches = "No maps match your search."
LANGUAGE.mapvote_selected = "Your vote: %s"
LANGUAGE.mapvote_disabled = "Map voting is disabled on this server."
LANGUAGE.mapvote_wait = "Please wait before changing your vote."
LANGUAGE.mapvote_invalid = "That map is no longer available for voting."
LANGUAGE.mapvote_refresh = "Refresh"

LANGUAGE.keys_title = "Keys"
LANGUAGE.keys_description = "Save named ZS shortcut profiles for each server. Engine controls remain available in Keyboard settings."
LANGUAGE.keys_help = "F1 menu"
LANGUAGE.keys_shop = "Shop / Zombie Escape weapons"
LANGUAGE.keys_class = "Zombie class / human weapons"
LANGUAGE.keys_options = "Options"
LANGUAGE.keys_thirdperson = "Third-person view"
LANGUAGE.keys_vision = "Zombie vision / human flashlight"
LANGUAGE.keys_zoom = "Zoom"
LANGUAGE.keys_mapvote = "Map vote"
LANGUAGE.keys_dropweapon = "Drop current weapon"
LANGUAGE.keys_dropammo = "Drop current weapon's ammo"
LANGUAGE.keys_quickbuy = "Points shop / mode shop"
LANGUAGE.keys_altmenu = "Human action menu (hold)"
LANGUAGE.keys_taunt = "Taunt menu"
LANGUAGE.keys_suicide = "Suicide (living zombies only)"
LANGUAGE.keys_weapons = "Weapon database"
LANGUAGE.keys_keys = "Key settings"
LANGUAGE.keys_camera_cycle = "Cycle third-person camera"
LANGUAGE.keys_camera_1 = "Camera: right shoulder"
LANGUAGE.keys_camera_2 = "Camera: centre"
LANGUAGE.keys_camera_3 = "Camera: left shoulder"
LANGUAGE.keys_camera_4 = "Camera: high right"
LANGUAGE.keys_camera_5 = "Camera: high centre"
LANGUAGE.keys_camera_6 = "Camera: low right"
LANGUAGE.keys_camera_7 = "Camera: low centre"
LANGUAGE.keys_camera_8 = "Camera: far back"
LANGUAGE.keys_legacy_imported = "Imported %d old shortcuts. %d conflicting or invalid shortcuts remain unbound. The old file is unchanged."
LANGUAGE.keys_import = "Import old shortcuts"
LANGUAGE.keys_legacy_missing = "No usable old key profile was found for this server."
LANGUAGE.keys_profile_name = "Profile name"
LANGUAGE.keys_load = "Load"
LANGUAGE.keys_save = "Save and use"
LANGUAGE.keys_rename = "Rename file"
LANGUAGE.keys_engine_settings = "Keyboard settings"
LANGUAGE.keys_engine_default = "Engine default"
LANGUAGE.keys_unbound = "Unbound"
LANGUAGE.keys_custom = "Custom shortcut"
LANGUAGE.keys_clear = "Clear"
LANGUAGE.keys_default = "Default"
LANGUAGE.keys_saved = "Profile updated. This server will remember your selection."
LANGUAGE.keys_invalid = "Invalid key settings."
LANGUAGE.keys_conflict = "That key is already assigned to %s. Clear that shortcut first."
LANGUAGE.keys_engine_conflict = "That key is used by an engine control. Choose an unused key."
LANGUAGE.keys_name_invalid = "Use 1-48 letters, numbers, spaces, underscores or hyphens for the profile name."
LANGUAGE.keys_name_exists = "A profile with that name already exists."
LANGUAGE.keys_save_failed = "The profile could not be saved."
LANGUAGE.keys_load_failed = "The profile is missing or invalid."

LANGUAGE.propcreator_name = "Prop Creator"
LANGUAGE.propcreator_description = "Tool gun that creates a board, wooden table or refrigerator. Right-click to choose, then left-click on clear ground within 160 units. Two successful spawns per player per round; buying another tool does not reset the limit."
LANGUAGE.propcreator_board = "Wooden board"
LANGUAGE.propcreator_table = "Wooden table"
LANGUAGE.propcreator_fridge = "Refrigerator"
LANGUAGE.propcreator_choose = "Choose a prop. You have %s spawns remaining this round. Left-click on clear ground to create it."
LANGUAGE.propcreator_hud = "%s | %s spawns left | Right-click to choose"
LANGUAGE.propcreator_limit = "You have already created your two props this round."
LANGUAGE.propcreator_unavailable = "You cannot create a prop right now."
LANGUAGE.propcreator_wait = "Please wait before creating another prop."
LANGUAGE.propcreator_invalid = "Choose a valid prop first."
LANGUAGE.propcreator_model_missing = "This prop model is unavailable on the server."
LANGUAGE.propcreator_floor = "Aim at clear ground within 160 units."
LANGUAGE.propcreator_blocked = "There is not enough clear space for this prop."
LANGUAGE.propcreator_failed = "The prop could not be created. Your allowance was not used."

LANGUAGE.zombie_variant_active = "POWERED-UP VARIANT!"
LANGUAGE.zombie_variant_spawned = "%s spawned as a POWERED-UP VARIANT!"

LANGUAGE.class_doom = "Doom"
LANGUAGE.description_doom = "A swift super boss with resistant hide, claws, a leap and poison spit."
LANGUAGE.controls_doom = "PRIMARY: Claws\nSECONDARY: Leap\nRELOAD: Poison spit"
LANGUAGE.class_apocalypse = "Apocalypse"
LANGUAGE.description_apocalypse = "A resilient super boss with powerful claws, poison bursts and a leap."
LANGUAGE.controls_apocalypse = "PRIMARY: Claws\nSECONDARY: Poison burst\nRELOAD: Leap"

LANGUAGE.shade_light_sync = "Light exposure: syncing"
LANGUAGE.shade_light_protected = "Light exposure: protected"
LANGUAGE.shade_light_burning = "Light exposure: burning"
LANGUAGE.shade_light_exposed = "Light exposure: exposed"
LANGUAGE.shade_grip_sync = "Waiting for Shade state"
LANGUAGE.shade_grip_disrupted = "Bright light breaks your grip"
LANGUAGE.shade_grip_unavailable = "Telekinesis unavailable"
LANGUAGE.shade_grip_holding = "Holding prop: primary to throw"
LANGUAGE.shade_grip_recovering = "Telekinesis recovering"
LANGUAGE.shade_grip_ready = "Secondary to lift a prop"

LANGUAGE.mm_hub_description = "Your survivor, settings and server tools."
LANGUAGE.mm_help_description = "Learn survival, barricading and zombie tactics."
LANGUAGE.mm_options_description = "Adjust controls, sound and gameplay preferences."
LANGUAGE.mm_models_description = "Choose your survivor's character model."
LANGUAGE.mm_color_description = "Customize player and weapon colors."
LANGUAGE.mm_cosmetics = "Cosmetics"
LANGUAGE.mm_cosmetics_description = "Browse your cosmetic items and appearance."
LANGUAGE.mm_mapvote_description = "View the maps available for the next vote."
LANGUAGE.mm_spectators_description = "See who is watching the current game."
LANGUAGE.mm_spectate_description = "Switch between playing and watching."
LANGUAGE.mm_credits_description = "Meet the people behind Zombie Survival."

LANGUAGE.mm_spectator_count = "Players watching: %d"
LANGUAGE.mm_no_spectators = "No players are spectating right now."

LANGUAGE.mm_color_spawn_notice = "Choose your colors. Apply changes for your next spawn."
LANGUAGE.mm_color_brightness = "Brightness"
LANGUAGE.mm_apply_colors = "Apply colors"

LANGUAGE.mm_model_spawn_notice = "Choose your character for your next human spawn."
LANGUAGE.mm_model_search = "Search character names or model paths..."
LANGUAGE.mm_model_no_results = "No characters match your search."
LANGUAGE.mm_model_previous = "Previous"
LANGUAGE.mm_model_next = "Next"
LANGUAGE.mm_model_page = "Page %s / %s  -  Characters: %s"
LANGUAGE.mm_model_unavailable = "Unavailable"
LANGUAGE.mm_model_donator = "Donator only"
LANGUAGE.mm_model_private = "Player restricted"
LANGUAGE.mm_model_exclusive = "Exclusive"

LANGUAGE.mm_guide_description = "Learn survival, barricading, upgrades and the undead."

LANGUAGE.cosmetic_search = "Search cosmetics..."
LANGUAGE.cosmetic_empty = "No cosmetics match this search for your team."
LANGUAGE.cosmetic_equip = "Equip"
LANGUAGE.cosmetic_unequip = "Unequip"
LANGUAGE.cosmetic_buy = "Buy - %s"
LANGUAGE.cosmetic_timeout = "The request timed out. Try again."
LANGUAGE.cosmetic_balance_points = "%s points - Purchases stay in your profile."
LANGUAGE.cosmetic_balance_tokens = "%s brain tokens - Purchases stay in your profile."

LANGUAGE.spectator_cooldown = "You can leave spectator mode in %s"

LANGUAGE.worth_invalid_name = "Use a loadout name from 1 to 128 bytes, without control characters, and at most 128 items."
LANGUAGE.worth_loadout_limit = "You can save up to 128 loadouts. Delete one before adding another."
LANGUAGE.worth_save_failed = "The loadout could not be saved. Check that your game data folder is writable."
LANGUAGE.worth_invalid_loadout = "This loadout is no longer valid. Review your selection before checking out."
LANGUAGE.worth_over_budget = "This loadout is %d worth over your limit. Remove items before checking out."
LANGUAGE.worth_loadout_readonly = "This loadout file could not be fully read. Back it up and repair it before saving or deleting loadouts."

LANGUAGE.points_search = "Search weapons, ammunition and equipment..."
LANGUAGE.points_empty = "No items match your search."

LANGUAGE.notification_details_title = "Notification"
LANGUAGE.notification_details_hint = "Open F1 > Notification to read the full message"
LANGUAGE.notification_details_description = "Read the last extended notification."
LANGUAGE.notification_details_empty = "No extended notification is available yet."

LANGUAGE.preparation_more_volunteers = "+%d more volunteers"

LANGUAGE.custom_voice_desc = "Show compact voice cards with player names, team colors and volume meters"
LANGUAGE.options_custom_voice = "Custom voice display"
LANGUAGE.voice_chat = "VOICE CHAT"
LANGUAGE.voice_more_speaking = "+%s more speaking"
LANGUAGE.voice_unknown_player = "Player %s"

LANGUAGE.weaponselect_desc = "Show compact equipment cards with weapon slots and ammunition"
LANGUAGE.weaponselect_mode_desc = "Choose whether selecting a weapon equips it immediately or waits for confirmation"
LANGUAGE.options_custom_weaponselect = "Custom weapon selection"
LANGUAGE.weaponselect_follow = "Follow game settings"
LANGUAGE.weaponselect_confirm = "Click to confirm"
LANGUAGE.weaponselect_instant = "Switch immediately"
LANGUAGE.weaponselect_header = "Equipment - %s/%s"
LANGUAGE.weaponselect_confirm_header = "Click to equip - %s/%s"
LANGUAGE.weaponselect_equipped = "Equipped"

LANGUAGE.taunt_title = "Taunts"
LANGUAGE.taunt_subtitle = "Express yourself with a gesture"
LANGUAGE.taunt_description = "Choose gestures available to your current class"
LANGUAGE.taunt_dead = "Respawn to use a taunt."
LANGUAGE.taunt_unavailable = "Taunts are unavailable for your current class or state."
LANGUAGE.taunt_playing = "Your current taunt is still playing."
LANGUAGE.taunt_cooldown = "Wait a moment before another taunt."
LANGUAGE.taunt_ready = "Choose a gesture available for your current model."
LANGUAGE.taunt_dance = "Dance"
LANGUAGE.taunt_robot = "Robot"
LANGUAGE.taunt_muscle = "Muscle"
LANGUAGE.taunt_laugh = "Laugh"
LANGUAGE.taunt_wave = "Wave"
LANGUAGE.taunt_cheer = "Cheer"
LANGUAGE.taunt_zombie = "Zombie"
LANGUAGE.taunt_drunk = "Drunk"
LANGUAGE.taunt_salute = "Salute"
LANGUAGE.taunt_forward = "Forward"
LANGUAGE.taunt_becon = "Beckon"
LANGUAGE.taunt_group = "Group"
LANGUAGE.taunt_surrender = "Surrender"
LANGUAGE.taunt_disagree = "Disagree"
LANGUAGE.taunt_agree = "Agree"

LANGUAGE.taunt_model_unavailable = "This player model does not support this gesture."

LANGUAGE.ze_weapon_akbar_detail = "Automatic rifle with a tighter spread than the submachine gun. Aim for controlled fire at medium range."
LANGUAGE.ze_weapon_sweeper_detail = "Close-range shotgun. Several pellets hit together; stay close to make the most of each shot."
LANGUAGE.ze_weapon_smg_detail = "Automatic submachine gun with a wider spread. Best for keeping pressure on nearby zombies."
LANGUAGE.ze_weapon_stubber_detail = "Scoped rifle with heavy single-shot damage and a five-round magazine. Make each shot count."
LANGUAGE.ze_weapon_bulletstorm_detail = "Automatic weapon with an alternate aimed fire mode. Aim down sights to change its shot pattern."
LANGUAGE.ze_weapon_custom_detail = "A primary weapon supplied by this server. Your selection follows the same exchange and ammo rules."
LANGUAGE.ze_weapon_stats = "Base damage per projectile: %s    |    Magazine: %s"
LANGUAGE.ze_weapon_choose_now = "Select a weapon to exchange your primary once. Your ammo budget is preserved and the choice is saved."
LANGUAGE.ze_weapon_choose_future = "The round is underway or you are waiting to spawn. Select a weapon to save it for your next spawn."
LANGUAGE.ze_weapon_close = "Close weapon selection"

LANGUAGE.weapon_repairfield = "Portable repair field"
LANGUAGE.weapon_repairfield_desc = "Hold primary fire to repair up to three nailed barricades in front of you within 200 units. Each half-second pulse repairs up to 30 health total, with a maximum of 10 per prop, and spends one pulse-ammo charge only when a repair succeeds. Uses remaining barricade repair capacity and shares each prop's field-repair cooldown. Cannot heal players, NPCs or un-nailed props."
LANGUAGE.repairfield_hud = "FIELD CHARGE: %d | 3 TARGETS | 200 UNITS"
LANGUAGE.repairfield_capacity = "REPAIR CAPACITY: %d"

LANGUAGE.zshop_armour = "Armoured Hide"
LANGUAGE.zshop_armour_desc = "Take 15% less incoming damage as any zombie class, including bosses. Stacks with Toughened Flesh for 36.25% less damage before other modifiers. Lasts until the round ends."
LANGUAGE.zshop_tough = "Toughened Flesh"
LANGUAGE.zshop_tough_desc = "Take 25% less incoming damage as any zombie class, including bosses. Stacks with Armoured Hide for 36.25% less damage before other modifiers. Lasts until the round ends."

LANGUAGE.mutation_requirement_missing = "Select or own the required mutation before buying this buff."
LANGUAGE.mutation_requires = "Requires %s"

LANGUAGE.classes_normal_tab = "Zombie classes"
LANGUAGE.classes_boss_tab = "Boss preference"
LANGUAGE.classes_search = "Search classes, abilities or controls..."
LANGUAGE.classes_empty = "No classes match your search."
LANGUAGE.classes_count = "%d classes shown"
LANGUAGE.classes_current = "Current class"
LANGUAGE.classes_available = "Available on respawn"
LANGUAGE.classes_unavailable = "Currently unavailable"
LANGUAGE.classes_preferred_boss = "Your preferred boss"
LANGUAGE.classes_choose_boss = "Choose as your preferred boss"
LANGUAGE.classes_round_assigned = "Assigned by the round; cannot be a boss preference"
LANGUAGE.classes_boss_help = "Choose your preference for the next time the server selects you as a boss."

LANGUAGE.wb_fire_delay = "Base primary delay (seconds)"
LANGUAGE.wb_spread_max = "Maximum spread"
LANGUAGE.wb_spread_min = "Minimum spread"
LANGUAGE.wb_no_stats = "No base combat stats are listed for this weapon."
LANGUAGE.wb_no_description = "No description is available for this weapon."
LANGUAGE.wb_no_model = "No model preview is available."
LANGUAGE.wb_reference_help = "Weapon reference: base stats before player traits and Forge upgrades."
LANGUAGE.wb_base_stats = "Base stats"
LANGUAGE.wb_search = "Search weapons or descriptions..."
LANGUAGE.wb_empty = "No weapons match your search."
LANGUAGE.wb_count = "%d weapons shown"

LANGUAGE.end_human_victory = "Human victory"
LANGUAGE.end_undead_victory = "Undead victory"
LANGUAGE.end_round_over = "Round over"
LANGUAGE.end_results_help = "Results from the finished round."
LANGUAGE.end_mentions_pending = "Waiting for the round awards..."
LANGUAGE.end_no_mentions = "No round awards this time."
LANGUAGE.end_mentions_count = "%d honorable mentions"

LANGUAGE.trader_title = "Ghost Trader"
LANGUAGE.trader_subtitle = "Buy supplies between waves."
LANGUAGE.trader_hint = "Weapons you already own cannot be purchased again."
LANGUAGE.trader_search = "Search items, descriptions or signatures..."
LANGUAGE.trader_points = "%s points available"
LANGUAGE.trader_price = "%s pts"
LANGUAGE.trader_purchasing = "Purchasing %s..."
LANGUAGE.trader_timeout = "The request timed out. You can try again."
LANGUAGE.trader_empty = "No items match your search."
LANGUAGE.trader_page = "Page %d / %d - %d items"
LANGUAGE.trader_owned = "Already owned"
LANGUAGE.trader_unavailable = "Unavailable"
LANGUAGE.trader_no_points = "Not enough points"

LANGUAGE.redeem_menu_title = "You have redeemed"
LANGUAGE.redeem_menu_description = "Choose how you want to return to the fight."
LANGUAGE.redeem_menu_human = "Join the humans"
LANGUAGE.redeem_menu_human_description = "Become a human and fight alongside the survivors."
LANGUAGE.redeem_menu_bandit = "Remain a bandit"
LANGUAGE.redeem_menu_bandit_description = "Keep your bandit role. Choose to help or fight the humans."
LANGUAGE.redeem_menu_later = "Decide later"

LANGUAGE.beacon_menu_title = "Message beacon"
LANGUAGE.beacon_menu_description = "Choose the message shown to nearby humans when you deploy this beacon."
LANGUAGE.beacon_menu_apply = "Use this message"
LANGUAGE.beacon_menu_empty = "No messages are available."

LANGUAGE.mutation_choose = "Choose buffs below. Their effects last until the round ends."
LANGUAGE.mutation_cart_summary = "%s selected | %s damage tokens to spend"
LANGUAGE.mutation_pending = "Waiting for the server to confirm your purchase..."
LANGUAGE.mutation_timeout = "No confirmation received. Check your tokens and owned buffs before retrying."

LANGUAGE.scoreboard_score = "Score"
LANGUAGE.scoreboard_brains = "Brains"
LANGUAGE.scoreboard_empty_team = "No players on this team."

LANGUAGE.ze_boss = "Boss"
LANGUAGE.ze_more_bosses = "+%d more bosses nearby"

LANGUAGE.hud_shop_shortcut = "%s  ·  %s"
LANGUAGE.hud_shop_loadout = "Survival loadout"

LANGUAGE.worth_close_hint = "Close this window. Use your shop shortcut to reopen it; configure shortcuts in Keys."
LANGUAGE.worth_grant_pending = "Waiting for the server to confirm your loadout..."
LANGUAGE.worth_grant_timeout = "No confirmation yet. Retry safely; the server keeps track of rewards already delivered."
LANGUAGE.worth_grant_resume = "Retry missing items"
LANGUAGE.worth_grant_retry = "Could not finish %s. Retry to receive missing items; confirmed rewards will be kept."
LANGUAGE.worth_grant_failed = "Loadout stopped at %s. Earlier rewards were kept. This item cannot safely be retried; contact a server administrator."
LANGUAGE.worth_grant_stale = "This loadout belongs to an earlier life or round."
LANGUAGE.worth_grant_cart_locked = "Finish your original loadout before choosing different items."
LANGUAGE.worth_grant_unavailable = "%s is unavailable. No items were granted; choose another loadout."
LANGUAGE.ze_weapon_help_shortcuts = "Choose a primary weapon. You can exchange it once before the round starts. Your choice is saved for future spawns; changing weapons preserves your ammo budget."

LANGUAGE.fear_hud_fear = "Fear"
LANGUAGE.fear_hud_resistance = "Resistance"
LANGUAGE.fear_spawn_ready = "Spawn ready"
LANGUAGE.fear_spawn_blocked = "Spawn blocked"

LANGUAGE.weapon_tier_label = "Tier %d"

LANGUAGE.options_pointshop_autoclose = "Close the point shop when the pointer leaves"
LANGUAGE.options_pointshop_close_delay = "Point shop close delay (seconds; 0 = instant)"
