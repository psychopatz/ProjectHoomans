-- Stable base command and vanilla-emote flavor records.
PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}
local Flavor = PNC.CompanionCommandFlavor
local Helpers = Flavor.DefinitionInternal or {}
local register = Helpers.register
local registerSimpleEmote = Helpers.registerSimpleEmote

register("follow", {
    { key = "UI_PNC_Flavor_Follow_Player_1", fallback = "{names}, on me." },
    { key = "UI_PNC_Flavor_Follow_Player_2", fallback = "Stay close, {names}." },
    { key = "UI_PNC_Flavor_Follow_Player_3", fallback = "{names}, let's move." },
}, {
    { key = "UI_PNC_Flavor_Follow_NPC_1", fallback = "Right behind you." },
    { key = "UI_PNC_Flavor_Follow_NPC_2", fallback = "I'm with you." },
    { key = "UI_PNC_Flavor_Follow_NPC_3", fallback = "Lead the way." },
})

register("stay", {
    { key = "UI_PNC_Flavor_Stay_Player_1", fallback = "{names}, wait here." },
    { key = "UI_PNC_Flavor_Stay_Player_2", fallback = "Hold this position, {names}." },
    { key = "UI_PNC_Flavor_Stay_Player_3", fallback = "{names}, stay put for now." },
}, {
    { key = "UI_PNC_Flavor_Stay_NPC_1", fallback = "I'll stay here." },
    { key = "UI_PNC_Flavor_Stay_NPC_2", fallback = "Holding position." },
    { key = "UI_PNC_Flavor_Stay_NPC_3", fallback = "I'll keep watch." },
})

register("camp", {
    { key = "UI_PNC_Flavor_Camp_Player_1", fallback = "Make camp here, {names}." },
    { key = "UI_PNC_Flavor_Camp_Player_2", fallback = "Settle in here, {names}." },
    { key = "UI_PNC_Flavor_Camp_Player_3", fallback = "We'll camp here for now, {names}." },
    { key = "UI_PNC_Flavor_Camp_Player_4", fallback = "We could make camp here, {names}." },
    { key = "UI_PNC_Flavor_Camp_Player_5", fallback = "Let's make this our camp, {names}." },
}, {
    { key = "UI_PNC_Flavor_Camp_NPC_1", fallback = "We'll make camp here." },
    { key = "UI_PNC_Flavor_Camp_NPC_2", fallback = "Settling in here." },
    { key = "UI_PNC_Flavor_Camp_NPC_3", fallback = "I'll hold this camp." },
    { key = "UI_PNC_Flavor_Camp_NPC_4", fallback = "A roof sounds good. Let's settle in." },
    { key = "UI_PNC_Flavor_Camp_NPC_5", fallback = "This works for me. We can camp here." },
})

register("camp_no_npc", {
    { key = "UI_PNC_Flavor_CampNoNPC_Player_1", fallback = "..." },
})

register("camp_rejected", {
    { key = "UI_PNC_Flavor_CampRejected_Player_1", fallback = "I can't find a safe room or campfire nearby." },
    { key = "UI_PNC_Flavor_CampRejected_Player_2", fallback = "We need a nearby room or campfire before we make camp." },
    { key = "UI_PNC_Flavor_CampRejected_Player_3", fallback = "No usable camp site is visible from here." },
}, {
    { key = "UI_PNC_Flavor_CampRejected_NPC_1", fallback = "I can't find a safe room or campfire nearby." },
    { key = "UI_PNC_Flavor_CampRejected_NPC_2", fallback = "Not here. We need a nearby room or campfire." },
    { key = "UI_PNC_Flavor_CampRejected_NPC_3", fallback = "I can't see a usable camp site from here." },
    { key = "UI_PNC_Flavor_CampRejected_NPC_4", fallback = "We're too exposed out here. Let's find a room or campfire." },
    { key = "UI_PNC_Flavor_CampRejected_NPC_5", fallback = "No usable camp site is visible from here." },
})

register("return_home", {
    { key = "UI_PNC_Flavor_ReturnHome_Player_1", fallback = "{names}, head home." },
    { key = "UI_PNC_Flavor_ReturnHome_Player_2", fallback = "Return to the base, {names}." },
    { key = "UI_PNC_Flavor_ReturnHome_Player_3", fallback = "{names}, get back home safely." },
}, {
    { key = "UI_PNC_Flavor_ReturnHome_NPC_1", fallback = "Heading home." },
    { key = "UI_PNC_Flavor_ReturnHome_NPC_2", fallback = "I'll return to the base." },
    { key = "UI_PNC_Flavor_ReturnHome_NPC_3", fallback = "On my way home." },
})

register("attack_auto", {
    { key = "UI_PNC_Flavor_AttackAuto_Player_1", fallback = "{name}, use your best judgment." },
    { key = "UI_PNC_Flavor_AttackAuto_Player_2", fallback = "{name}, handle threats as you see fit." },
    { key = "UI_PNC_Flavor_AttackAuto_Player_3", fallback = "Watch our backs, {name}." },
}, {
    { key = "UI_PNC_Flavor_AttackAuto_NPC_1", fallback = "I'll handle it." },
    { key = "UI_PNC_Flavor_AttackAuto_NPC_2", fallback = "I'll stay alert." },
    { key = "UI_PNC_Flavor_AttackAuto_NPC_3", fallback = "Leave it to me." },
})

register("attack_melee", {
    { key = "UI_PNC_Flavor_AttackMelee_Player_1", fallback = "{name}, keep it close." },
    { key = "UI_PNC_Flavor_AttackMelee_Player_2", fallback = "Take the front line, {name}." },
    { key = "UI_PNC_Flavor_AttackMelee_Player_3", fallback = "{name}, save your ammunition." },
}, {
    { key = "UI_PNC_Flavor_AttackMelee_NPC_1", fallback = "Going in close." },
    { key = "UI_PNC_Flavor_AttackMelee_NPC_2", fallback = "I'll take the front." },
    { key = "UI_PNC_Flavor_AttackMelee_NPC_3", fallback = "Keeping it quiet." },
})

register("attack_ranged", {
    { key = "UI_PNC_Flavor_AttackRanged_Player_1", fallback = "{name}, keep your distance." },
    { key = "UI_PNC_Flavor_AttackRanged_Player_2", fallback = "Give us ranged cover, {name}." },
    { key = "UI_PNC_Flavor_AttackRanged_Player_3", fallback = "{name}, engage from a safe distance." },
}, {
    { key = "UI_PNC_Flavor_AttackRanged_NPC_1", fallback = "I'll cover you." },
    { key = "UI_PNC_Flavor_AttackRanged_NPC_2", fallback = "Keeping my distance." },
    { key = "UI_PNC_Flavor_AttackRanged_NPC_3", fallback = "I've got a clear shot." },
})

register("attack_none", {
    { key = "UI_PNC_Flavor_AttackNone_Player_1", fallback = "{name}, stay out of the fight." },
    { key = "UI_PNC_Flavor_AttackNone_Player_2", fallback = "Avoid trouble, {name}." },
    { key = "UI_PNC_Flavor_AttackNone_Player_3", fallback = "{name}, don't engage unless I change the order." },
}, {
    { key = "UI_PNC_Flavor_AttackNone_NPC_1", fallback = "I'll avoid trouble." },
    { key = "UI_PNC_Flavor_AttackNone_NPC_2", fallback = "I won't engage." },
    { key = "UI_PNC_Flavor_AttackNone_NPC_3", fallback = "Staying out of it." },
})

register("vanilla_emote_insult", {
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_Player_1", fallback = "Back off, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_Player_2", fallback = "You're asking for trouble, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_Player_3", fallback = "Keep your distance, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Guarded_1", fallback = "Keep it civil." },
})
register("vanilla_emote_insult_npc_guarded", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Guarded_1", fallback = "Keep it civil." },
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Guarded_2", fallback = "I heard you. Drop it." },
})
register("vanilla_emote_insult_npc_hostile", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Hostile_1", fallback = "Try that again and you'll regret it." },
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Hostile_2", fallback = "Keep talking. See where that gets you." },
})
register("vanilla_emote_insult_npc_familiar", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Familiar_1", fallback = "You're really testing my patience." },
    { key = "UI_PNC_Flavor_VanillaEmote_Insult_NPC_Familiar_2", fallback = "Not your best moment." },
})

register("vanilla_emote_thumbsdown", {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_Player_1", fallback = "No. That's not good enough, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_Player_2", fallback = "I don't like that, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_Player_3", fallback = "Try again, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_NPC_Guarded_1", fallback = "Message received." },
})
register("vanilla_emote_thumbsdown_npc_guarded", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_NPC_Guarded_1", fallback = "Message received." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_NPC_Guarded_2", fallback = "You could say that more clearly." },
})
register("vanilla_emote_thumbsdown_npc_hostile", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_NPC_Hostile_1", fallback = "Then stay out of my way." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsDown_NPC_Hostile_2", fallback = "Keep making that face." },
})

register("vanilla_emote_wavehi", {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_Player_1", fallback = "Hey, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_Player_2", fallback = "Good to see you, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_Player_3", fallback = "Morning, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_NPC_Reserved_1", fallback = "Hey." },
})
register("vanilla_emote_wavehi_npc_reserved", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_NPC_Reserved_1", fallback = "Hey." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_NPC_Reserved_2", fallback = "I see you." },
})
register("vanilla_emote_wavehi_npc_warm", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_NPC_Warm_1", fallback = "Hey, good to see you." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveHi_NPC_Warm_2", fallback = "There you are." },
})

register("vanilla_emote_wavebye", {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_Player_1", fallback = "Take care, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_Player_2", fallback = "See you around, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_Player_3", fallback = "Stay safe, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_NPC_Reserved_1", fallback = "Take care." },
})
register("vanilla_emote_wavebye_npc_reserved", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_NPC_Reserved_1", fallback = "Take care." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_NPC_Reserved_2", fallback = "Stay safe." },
})
register("vanilla_emote_wavebye_npc_warm", nil, {
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_NPC_Warm_1", fallback = "See you soon." },
    { key = "UI_PNC_Flavor_VanillaEmote_WaveBye_NPC_Warm_2", fallback = "You too. Stay safe." },
})

local function registerSimpleEmote(id, playerLines, reservedLines, warmLines)
    register("vanilla_emote_" .. id, playerLines, reservedLines)
    register("vanilla_emote_" .. id .. "_npc_reserved", nil, reservedLines)
    register("vanilla_emote_" .. id .. "_npc_warm", nil, warmLines)
end

registerSimpleEmote("thankyou", {
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_Player_1", fallback = "Thanks, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_Player_2", fallback = "I appreciate that, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_Player_3", fallback = "You have my thanks, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_NPC_Reserved_1", fallback = "You're welcome." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_NPC_Reserved_2", fallback = "No problem." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_NPC_Warm_1", fallback = "Anytime." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThankYou_NPC_Warm_2", fallback = "You don't have to thank me." },
})
registerSimpleEmote("thumbsup", {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_Player_1", fallback = "Good work, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_Player_2", fallback = "That's what I like to see, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_Player_3", fallback = "Keep it up, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_NPC_Reserved_1", fallback = "Good." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_NPC_Reserved_2", fallback = "Got it." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_NPC_Warm_1", fallback = "Glad I could help." },
    { key = "UI_PNC_Flavor_VanillaEmote_ThumbsUp_NPC_Warm_2", fallback = "We're doing alright." },
})
registerSimpleEmote("clap", {
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_Player_1", fallback = "Well done, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_Player_2", fallback = "That's worth celebrating, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_Player_3", fallback = "Nice work, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_NPC_Reserved_1", fallback = "Thanks." },
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_NPC_Reserved_2", fallback = "I did my part." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_NPC_Warm_1", fallback = "That means a lot." },
    { key = "UI_PNC_Flavor_VanillaEmote_Clap_NPC_Warm_2", fallback = "Couldn't have done it without you." },
})
registerSimpleEmote("salute", {
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_Player_1", fallback = "Respect, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_Player_2", fallback = "I see you, {names}." },
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_Player_3", fallback = "Stay sharp, {names}." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_NPC_Reserved_1", fallback = "Stay sharp." },
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_NPC_Reserved_2", fallback = "Respect." },
}, {
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_NPC_Warm_1", fallback = "Always." },
    { key = "UI_PNC_Flavor_VanillaEmote_Salute_NPC_Warm_2", fallback = "Right back at you." },
})

return Flavor
