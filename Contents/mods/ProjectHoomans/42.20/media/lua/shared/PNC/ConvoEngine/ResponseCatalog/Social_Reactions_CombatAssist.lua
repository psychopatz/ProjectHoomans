-- Authored response pools for post-combat assist, companion-survivor exchange,
-- and proactive "what's your name?" identity beats.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local function v(id, fallback, when, priority)
    return {
        id = id,
        templateID = id,
        fallback = fallback,
        when = when,
        priority = priority or 6,
    }
end

Catalog.Register("semantic.combat.assist.gratitude", {
    variants = {
        -- Horde cleared
        v("combat.assist.gratitude.horde.shaken",
            "Christ, there were so many of them... thank you, I didn't think I'd make it out of that.",
            { combatReactionRole = "assist_gratitude_horde", speakerStyle = "shaken" }, 9),
        v("combat.assist.gratitude.horde.brave",
            "Hell of a stand. We chewed right through that pack—appreciate the backup.",
            { combatReactionRole = "assist_gratitude_horde", speakerStyle = "brave" }, 9),
        v("combat.assist.gratitude.horde.aggressive",
            "Damn right—dropped the whole lot of 'em. Good timing stepping in.",
            { combatReactionRole = "assist_gratitude_horde", speakerStyle = "aggressive" }, 9),
        v("combat.assist.gratitude.horde.general",
            "That was way too many dead for one person. Appreciate you jumping in.",
            { combatReactionRole = "assist_gratitude_horde" }, 7),

        -- Night / dusk assist
        v("combat.assist.gratitude.night.shaken",
            "Hard enough seeing them out here in the dark... thank God you were nearby.",
            { combatReactionRole = "assist_gratitude_night", speakerStyle = "shaken" }, 9),
        v("combat.assist.gratitude.night.general",
            "Cutting it close out here with the light gone. Thanks for watching my back.",
            { combatReactionRole = "assist_gratitude_night" }, 7),

        -- Shaken / injured / exhausted
        v("combat.assist.gratitude.shaken.injured",
            "Ugh... I'm still catching my breath. You saved my skin back there.",
            { combatReactionRole = "assist_gratitude_shaken", speakerInjured = true }, 9),
        v("combat.assist.gratitude.shaken.general",
            "Too close. My arms are shaking—thanks for stepping in when you did.",
            { combatReactionRole = "assist_gratitude_shaken" }, 7),

        -- Wary / strained relationship
        v("combat.assist.gratitude.wary.general",
            "Didn't expect you to help... alright. I owe you one for that.",
            { combatReactionRole = "assist_gratitude_wary" }, 8),

        -- Warm / friendly / trusted / ally
        v("combat.assist.gratitude.warm.general",
            "Knew I could count on you, {addressee.name}. Appreciate the hand.",
            { combatReactionRole = "assist_gratitude_warm" }, 8),

        -- General assist by personality
        v("combat.assist.gratitude.general.supportive",
            "Hey, thank you for stepping in—that could've gone sideways fast.",
            { combatReactionRole = "assist_gratitude_general", speakerStyle = "supportive" }, 8),
        v("combat.assist.gratitude.general.brave",
            "Clean work. Appreciate the assist—always easier with another pair of hands.",
            { combatReactionRole = "assist_gratitude_general", speakerStyle = "brave" }, 8),
        v("combat.assist.gratitude.general.cold",
            "Good timing. That saved me some trouble.",
            { combatReactionRole = "assist_gratitude_general", speakerStyle = "cold" }, 8),
        v("combat.assist.gratitude.general.default",
            "Appreciate the help with those dead. I'll remember that.",
            { combatReactionRole = "assist_gratitude_general" }, 6),

        -- State-driven aftermath check-in
        v("combat.assist.aftermath.checkin.injured",
            "You're hurt—keep pressure on it and let's make sure the street's clear first.",
            { combatReactionRole = "aftermath_checkin", anyInjured = true }, 8),
        v("combat.assist.aftermath.checkin.general",
            "Take a second to catch your breath. Looks clear for now.",
            { combatReactionRole = "aftermath_checkin" }, 6),
    },
})

Catalog.Register("semantic.combat.assist.companion_exchange", {
    variants = {
        v("combat.assist.companion.horde_open",
            "Your crew really held the line back there. Didn't think anyone else out here still had people's backs.",
            { combatReactionRole = "companion_exchange_horde_open" }, 8),
        v("combat.assist.companion.open.night",
            "Glad your group came down this road before dark got any worse. Appreciate the backup.",
            { combatReactionRole = "companion_exchange_open", isNightOrDusk = true }, 8),
        v("combat.assist.companion.open.wary",
            "Your people fight pretty tight... thanks for pulling those off me, even if we don't know each other.",
            { combatReactionRole = "companion_exchange_open", relationshipTier = "wary" }, 8),
        v("combat.assist.companion.open.general",
            "Appreciate your group stepping in. Nice to see folks out here still looking out for each other.",
            { combatReactionRole = "companion_exchange_open" }, 6),

        v("combat.assist.companion.reply.checkin",
            "Don't mention it—you patched up alright? You looked like you took a rough hit there.",
            { combatReactionRole = "companion_exchange_checkin" }, 8),
        v("combat.assist.companion.reply.night",
            "No problem. Stick to cover though, they get nastier once the sun drops.",
            { combatReactionRole = "companion_exchange_night" }, 8),
        v("combat.assist.companion.reply.supportive",
            "Anytime. Nobody's making it through this mess alone anyway.",
            { combatReactionRole = "companion_exchange_reply", speakerStyle = "supportive" }, 7),
        v("combat.assist.companion.reply.general",
            "Just doing what needed doing. Stay sharp out here.",
            { combatReactionRole = "companion_exchange_reply" }, 6),
    },
})

Catalog.Register("semantic.social.identity.ask_name_proactive", {
    variants = {
        v("social.identity.ask_name.after_assist.warm",
            "Wait—I didn't even catch your name. Who do I owe a favor to?",
            { combatReactionRole = "ask_name_after_assist", speakerStyle = "supportive" }, 8),
        v("social.identity.ask_name.after_assist.wary",
            "Before we split up... what do people call you?",
            { combatReactionRole = "ask_name_after_assist", relationshipTier = "wary" }, 8),
        v("social.identity.ask_name.after_assist.general",
            "Hey, I never caught your name. Who am I thanking here?",
            { combatReactionRole = "ask_name_after_assist" }, 6),

        -- Autonomous colonist answers
        v("social.identity.colonist.answer.real_name",
            "Name's {claimed.name}. Good fighting beside you.",
            { combatReactionRole = "colonist_answer_real_name" }, 7),
        v("social.identity.colonist.answer.lie_name",
            "You can call me {claimed.name}. That's all you need to know for now.",
            { combatReactionRole = "colonist_answer_lie_name" }, 7),
        v("social.identity.colonist.answer.refuse_name",
            "Better if we keep names out of it for now. Just glad you're still breathing.",
            { combatReactionRole = "colonist_answer_refuse_name" }, 7),

        -- Asker reactions to colonist answer
        v("social.identity.ask_name.react.real_name",
            "Good to know, {claimed.name}. I'm {speaker.name}.",
            { combatReactionRole = "ask_name_react_real_name" }, 7),
        v("social.identity.ask_name.react.lie_name",
            "Alright, {claimed.name}. Fair enough—I'm {speaker.name}.",
            { combatReactionRole = "ask_name_react_lie_name" }, 7),
        v("social.identity.ask_name.react.refuse_name",
            "Fair enough, can't blame you for being careful these days.",
            { combatReactionRole = "ask_name_react_refuse_name" }, 7),
    },
})

return true
