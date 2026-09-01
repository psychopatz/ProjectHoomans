-- Built-in command flavor. Translation authors only need to provide the keys
-- below; fallbacks keep third-party commands usable while translations catch up.

PNC = PNC or {}

local Flavor = PNC.CompanionCommandFlavor

local function register(commandID, playerLines, npcLines)
    Flavor.Register(commandID, {
        player = playerLines,
        npc = npcLines,
    })
end

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
}, {
    { key = "UI_PNC_Flavor_Camp_NPC_1", fallback = "We'll make camp here." },
    { key = "UI_PNC_Flavor_Camp_NPC_2", fallback = "Settling in here." },
    { key = "UI_PNC_Flavor_Camp_NPC_3", fallback = "I'll hold this camp." },
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

-- Vanilla emotes also address people with different histories and loyalties.
-- Keep these replies separate from the relationship score thresholds: a
-- neutral survivor, a family member, and a hostile stranger should not sound
-- interchangeable even when their current approval happens to match.
local NPC_TYPES = { "hostile", "neutral", "colonist", "lover", "family" }

local function title(value)
    value = tostring(value or "")
    return string.upper(string.sub(value, 1, 1))
        .. string.sub(value, 2)
end

local function registerTypedReply(
    emoteID,
    stem,
    npcType,
    first,
    second,
    state
)
    local suffix = state and "_" .. title(state) or ""
    local keyStem = "UI_PNC_Flavor_VanillaEmote_" .. stem
        .. "_NPC_" .. title(npcType) .. suffix
    register(
        "vanilla_emote_" .. emoteID .. "_npc_" .. npcType
            .. (state and "_" .. state or ""),
        nil,
        {
            { key = keyStem .. "_1", fallback = first },
            { key = keyStem .. "_2", fallback = second },
        }
    )
end

local function registerTypedReplies(emoteID, stem, variants)
    local index
    local npcType
    local lines
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        lines = variants[npcType]
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            lines[1],
            lines[2]
        )
    end
end

local function registerDailyTypedReplies(emoteID, stem, variants)
    local index
    local npcType
    local states
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        states = variants[npcType]
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            states.first[1],
            states.first[2],
            "first"
        )
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            states.returning[1],
            states.returning[2],
            "returning"
        )
    end
end

registerTypedReplies("insult", "Insult", {
    hostile = { "Say that again and you'll regret it.", "Careful. I'm not in the mood." },
    neutral = { "That's unnecessary.", "Keep it respectful." },
    colonist = { "We're on the same side. Cut it out.", "Don't talk to me like that." },
    lover = { "You're lucky I know you.", "I know you're upset, but don't push me." },
    family = { "Watch your mouth.", "We're family; don't make this worse." },
})
registerTypedReplies("thumbsdown", "ThumbsDown", {
    hostile = { "Then stay out of my way.", "Keep making that face." },
    neutral = { "I got the message.", "You could just say what's wrong." },
    colonist = { "If you have a problem, tell me.", "We need to work together." },
    lover = { "I know that look. Talk to me.", "Tell me what bothered you, love." },
    family = { "I see the disapproval.", "Say what you mean." },
})
registerDailyTypedReplies("wavehi", "WaveHi", {
    hostile = {
        first = { "Keep your distance.", "I see you. Don't come closer." },
        returning = { "Still here? Keep moving.", "We already saw each other." },
    },
    neutral = {
        first = { "Hello.", "Morning." },
        returning = { "Hey again.", "There you are again." },
    },
    colonist = {
        first = { "Morning, good to see you.", "Hey, we're all here." },
        returning = { "Hey again, ready to work?", "Back again? Stay safe." },
    },
    lover = {
        first = { "There you are, love.", "Good morning, sweetheart." },
        returning = { "Hey, love. Again.", "I was hoping you'd come back." },
    },
    family = {
        first = { "There you are.", "Good to see you." },
        returning = { "Hey again.", "Already back?" },
    },
})

local function registerSocialGreeting(npcType, tier, state, lines)
    local stem = "SocialGreeting_" .. title(npcType) .. "_"
        .. title(tier) .. "_" .. title(state)
    register(
        "social_greeting_npc_" .. npcType .. "_" .. tier .. "_" .. state,
        nil,
        {
            {
                key = "UI_PNC_Flavor_" .. stem .. "_1",
                fallback = lines[1],
            },
            {
                key = "UI_PNC_Flavor_" .. stem .. "_2",
                fallback = lines[2],
            },
        }
    )
end

local SOCIAL_GREETING_LINES = {
    warm = {
        neutral = {
            first = { "Good to see you.", "I was hoping we'd cross paths." },
            returning = { "Back again already?", "Good, you're still around." },
        },
        colonist = {
            first = { "Good to see you. How's the camp holding?", "There you are. Ready for another day?" },
            returning = { "Back again. How's the work going?", "Good to see you again. Need anything?" },
        },
        lover = {
            first = { "There you are, love.", "I was hoping I'd see you today." },
            returning = { "Back so soon, love?", "I was hoping you'd come back." },
        },
        family = {
            first = { "There you are. You doing alright?", "Good to see you. Come here." },
            returning = { "Back again? You holding up?", "Good to see you again." },
        },
    },
    familiar = {
        neutral = {
            first = { "Hey. How have you been?", "Didn't expect to see you." },
            returning = { "Hey again. How's it going?", "There you are again." },
        },
        colonist = {
            first = { "Hey. Everything holding together?", "Good timing. We could use you." },
            returning = { "Hey again. Everything under control?", "Back again? Stay safe." },
        },
        lover = {
            first = { "Hey, love. How are you holding up?", "Good to see you, sweetheart." },
            returning = { "Hey again, love.", "You came back. Good." },
        },
        family = {
            first = { "Hey. You alright?", "Good to see you again." },
            returning = { "Hey again. You okay?", "Already back?" },
        },
    },
    reserved = {
        neutral = {
            first = { "Hello.", "Morning." },
            returning = { "Hey again.", "There you are again." },
        },
        colonist = {
            first = { "Morning.", "Hey. Stay safe out there." },
            returning = { "Hey again.", "Back already?" },
        },
        lover = {
            first = { "Hey, love.", "Morning, sweetheart." },
            returning = { "Hey again, love.", "There you are." },
        },
        family = {
            first = { "Morning.", "Hey. Take care of yourself." },
            returning = { "Hey again.", "Back already?" },
        },
    },
}

local socialGreetingTypes = { "neutral", "colonist", "lover", "family" }
local socialGreetingTiers = { "warm", "familiar", "reserved" }
local socialGreetingStates = { "first", "returning" }
local socialGreetingTypeIndex
local socialGreetingTierIndex
local socialGreetingStateIndex
local socialGreetingType
local socialGreetingTier
local socialGreetingState
local socialGreetingLines
for socialGreetingTypeIndex = 1, #socialGreetingTypes do
    socialGreetingType = socialGreetingTypes[socialGreetingTypeIndex]
    for socialGreetingTierIndex = 1, #socialGreetingTiers do
        socialGreetingTier = socialGreetingTiers[socialGreetingTierIndex]
        for socialGreetingStateIndex = 1, #socialGreetingStates do
            socialGreetingState = socialGreetingStates[socialGreetingStateIndex]
            socialGreetingLines = SOCIAL_GREETING_LINES[socialGreetingTier]
                [socialGreetingType][socialGreetingState]
            registerSocialGreeting(
                socialGreetingType,
                socialGreetingTier,
                socialGreetingState,
                socialGreetingLines
            )
        end
    end
end

registerTypedReplies("wavebye", "WaveBye", {
    hostile = { "Keep walking.", "Don't make this a conversation." },
    neutral = { "Take care.", "Goodbye." },
    colonist = { "Stay safe out there.", "See you at camp." },
    lover = { "Come back safe, love.", "I'll see you soon." },
    family = { "Take care of yourself.", "See you soon." },
})
registerTypedReplies("thankyou", "ThankYou", {
    hostile = { "Don't mistake this for friendship.", "Fine. It was nothing." },
    neutral = { "You're welcome.", "No trouble." },
    colonist = { "Anytime. We look after our own.", "That's what we're here for." },
    lover = { "Always, love.", "Anything for you." },
    family = { "Of course.", "You don't have to thank me." },
})
registerTypedReplies("thumbsup", "ThumbsUp", {
    hostile = { "Don't get comfortable.", "We'll see." },
    neutral = { "Good.", "Let's hope it holds." },
    colonist = { "Good work.", "That's how we get through this." },
    lover = { "That's my survivor.", "I knew you could do it." },
    family = { "That's the spirit.", "Proud of you." },
})
registerTypedReplies("clap", "Clap", {
    hostile = { "Save the celebration.", "Keep your hands to yourself." },
    neutral = { "Thanks, I guess.", "It was a small win." },
    colonist = { "Glad you were there.", "We did it together." },
    lover = { "You make a good audience.", "That means a lot, love." },
    family = { "You're too kind.", "Nice to hear that from you." },
})
registerTypedReplies("salute", "Salute", {
    hostile = { "Don't salute me.", "Stay sharp and stay away." },
    neutral = { "Stay sharp.", "Acknowledged." },
    colonist = { "Stay sharp, survivor.", "Right back at you." },
    lover = { "Always, love.", "Stay safe for me." },
    family = { "Stay sharp.", "Take care." },
})

return Flavor
