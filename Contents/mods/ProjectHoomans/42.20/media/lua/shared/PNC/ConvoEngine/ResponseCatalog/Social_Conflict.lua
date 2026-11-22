PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.hostile_remark", {
    variants = {
        {
            id = "semantic.hostile.escalated",
            templateID = "semantic.social.hostile_escalated",
            fallback = "That's enough. Keep it up and we're done.",
            when = { hostilityCount = { 2, 3, 4, 5, 6 } },
            priority = 4,
        },
        {
            id = "semantic.hostile.default",
            templateID = "social.hostile_boundary",
            fallback = "Don't talk to me like that.",
        },
        {
            id = "semantic.hostile.short",
            templateID = "social.hostile_short",
            fallback = "Watch your mouth.",
        },
        {
            id = "semantic.hostile.withdrawn",
            templateID = "social.hostile_withdrawn",
            fallback = "Then leave me alone.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.hostile.busy",
            templateID = "semantic.social.hostile_busy",
            fallback = "Not now. I have enough to deal with.",
            when = { busy = true },
            priority = 2,
        },
        {
            id = "semantic.hostile.stressed",
            templateID = "social.hostile_stressed",
            fallback = "I've had enough already.",
            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.combat.assault.react", {
    variants = {
        {
            id = "semantic.combat.assault.betrayal.shaken",
            templateID = "combat.assault.betrayal.shaken",
            fallback = "Why are you attacking me?! Stay back! I'll fight if I have to!",
            when = {
                assaultKind = "neutral_turned_hostile",
                combatReactionStyle = "shaken",
            },
            priority = 10,
        },
        {
            id = "semantic.combat.assault.betrayal.aggressive",
            templateID = "combat.assault.betrayal.aggressive",
            fallback = "Thought I was an easy target, huh?! Big mistake!",
            when = {
                assaultKind = "neutral_turned_hostile",
                combatReactionStyle = "aggressive",
            },
            priority = 10,
        },
        {
            id = "semantic.combat.assault.betrayal.brave",
            templateID = "combat.assault.betrayal.brave",
            fallback = "Big mistake jumping someone who wasn't bothering you!",
            when = {
                assaultKind = "neutral_turned_hostile",
                combatReactionStyle = "brave",
            },
            priority = 10,
        },
        {
            id = "semantic.combat.assault.betrayal.default",
            templateID = "combat.assault.betrayal.default",
            fallback = "I wasn't even looking for a fight! Now you're dead!",
            when = { assaultKind = "neutral_turned_hostile" },
            priority = 8,
        },
        {
            id = "semantic.combat.assault.react.shaken",
            templateID = "combat.assault.react.shaken",
            fallback = "What the hell?! Stay back!",
            when = { combatReactionStyle = "shaken" },
            priority = 5,
        },
        {
            id = "semantic.combat.assault.react.aggressive",
            templateID = "combat.assault.react.aggressive",
            fallback = "You just made a big mistake.",
            when = { combatReactionStyle = "aggressive" },
            priority = 5,
        },
        {
            id = "semantic.combat.assault.react.brave",
            templateID = "combat.assault.react.brave",
            fallback = "That's it. You're done.",
            when = { combatReactionStyle = "brave" },
            priority = 4,
        },
        {
            id = "semantic.combat.assault.react.reserved",
            templateID = "combat.assault.react.reserved",
            fallback = "Back off. Now.",
            when = { combatReactionStyle = "reserved" },
            priority = 3,
        },
        {
            id = "semantic.combat.assault.react.default",
            templateID = "combat.assault.react.default",
            fallback = "Why did you do that?!",
        },
    },
})

Catalog.Register("semantic.threat", {
    variants = {
        {
            id = "semantic.threat.stressed",
            templateID = "semantic.social.threat_stressed",
            fallback = "I've had enough. Back off before this gets worse.",
            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 5,
        },
        {
            id = "semantic.threat.withdrawn",
            templateID = "semantic.social.threat_withdrawn",
            fallback = "Keep your distance. I'm not discussing this.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.threat.trusted",
            templateID = "semantic.social.threat_trusted",
            fallback = "Don't make this personal. Step back.",
            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 1,
        },
        {
            id = "semantic.threat.default",
            templateID = "social.threat_boundary",
            fallback = "Back off.",
        },
        {
            id = "semantic.threat.firm",
            templateID = "semantic.social.threat_firm",
            fallback = "Don't threaten me.",
        },
        {
            id = "semantic.threat.busy",
            templateID = "semantic.social.threat_busy",
            fallback = "Pick another fight.",
            when = { busy = true },
            priority = 3,
        },
    },
})

-- Vanilla emotes enter the semantic lifecycle as acts.  These pools are the
-- response authority; wording is supplied by Dialogue Content.
Catalog.Register("semantic.emote.reply", {
    variants = {
        {
            id = "semantic.emote.reply.thumbsup.active",
            templateID = "emote.reply.thumbsup.active",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsup", previousTopic = "water" },
            priority = 4,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "water",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.thumbsup.active" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsup",
            templateID = "emote.reply.thumbsup",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsup" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.thumbsup" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsdown",
            templateID = "emote.reply.thumbsdown",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsdown" },
            priority = 2,
            plan = {
                dialogueAct = "DISAPPROVE",
                sourcePoolID = "semantic.emote.reply",
                topic = "disapproval",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.thumbsdown" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.insult",
            templateID = "emote.reply.insult",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "insult" },
            priority = 2,
            plan = {
                dialogueAct = "INSULT",
                sourcePoolID = "semantic.emote.reply",
                topic = "hostility",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.insult" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavehi",
            templateID = "emote.reply.wavehi",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "wavehi" },
            priority = 2,
            plan = {
                dialogueAct = "GREET",
                sourcePoolID = "semantic.emote.reply",
                topic = "greeting",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.wavehi" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavebye",
            templateID = "emote.reply.wavebye",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "wavebye" },
            priority = 2,
            plan = {
                dialogueAct = "FAREWELL",
                sourcePoolID = "semantic.emote.reply",
                topic = "farewell",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.wavebye" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thankyou",
            templateID = "emote.reply.thankyou",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thankyou" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "thanks",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.thankyou" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.clap",
            templateID = "emote.reply.clap",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "clap" },
            priority = 2,
            plan = {
                dialogueAct = "PRAISE",
                sourcePoolID = "semantic.emote.reply",
                topic = "praise",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.clap" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.salute",
            templateID = "emote.reply.salute",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "salute" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.salute" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.default",
            templateID = "emote.reply.default",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.emote.reply",
                topic = "social_reaction",
                turns = { { segments = {
                    { kind = "translation", templateID = "emote.reply.default" },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.combat.assault.friendly_fire", {
    variants = {
        {
            id = "semantic.combat.assault.friendly_fire.penalty",
            templateID = "combat.assault.friendly_fire.penalty",
            fallback = "I've had enough of you shoving me around today. Stay out of my space!",
            when = { friendlyPushTier = "penalty" },
            priority = 6,
        },
        {
            id = "semantic.combat.assault.friendly_fire.warn",
            templateID = "combat.assault.friendly_fire.warn",
            fallback = "Seriously, knock it off with the shoving!",
            when = { friendlyPushTier = "warn" },
            priority = 5,
        },
        {
            id = "semantic.combat.assault.friendly_fire.first",
            templateID = "combat.assault.friendly_fire.first",
            fallback = "Whoa, easy there! I'm on your side!",
            when = { friendlyPushTier = "first" },
            priority = 4,
        },
        {
            id = "semantic.combat.assault.friendly_fire.default",
            templateID = "combat.assault.friendly_fire.first",
            fallback = "Hey, watch where you're swinging!",
        },
    },
})

Catalog.Register("semantic.combat.assault.hostile_taunt", {
    variants = {
        {
            id = "semantic.combat.assault.hostile_taunt.backpack",
            templateID = "combat.assault.hostile_taunt.backpack",
            fallback = "Nice {slot.loot.name} on your back! Drop it before I pry it off you!",
            when = { lootCategory = "backpack" },
            priority = 6,
        },
        {
            id = "semantic.combat.assault.hostile_taunt.weapon",
            templateID = "combat.assault.hostile_taunt.weapon",
            fallback = "Nice {slot.loot.name} you've got there! It'll look better in my hands!",
            when = { lootCategory = "weapon" },
            priority = 6,
        },
        {
            id = "semantic.combat.assault.hostile_taunt.money",
            templateID = "combat.assault.hostile_taunt.money",
            fallback = "Still carrying {slot.loot.name} around? Empty your pockets!",
            when = { lootCategory = "money" },
            priority = 6,
        },
        {
            id = "semantic.combat.assault.hostile_taunt.general",
            templateID = "combat.assault.hostile_taunt.general",
            fallback = "Empty your pockets now or bleed for every scrap you're carrying!",
        },
    },
})

Catalog.Register("semantic.world.alarm.react", {
    variants = {
        {
            id = "semantic.world.alarm.react.house_alarm_open",
            templateID = "world.alarm.react.house_alarm_open",
            fallback = "Burglar alarm just tripped! {addressee.name}, get ready for company!",
            when = { combatReactionRole = "house_alarm_open" },
            priority = 6,
        },
        {
            id = "semantic.world.alarm.react.house_alarm_reply",
            templateID = "world.alarm.react.house_alarm_reply",
            fallback = "I hear it, {addressee.name}. Weapons up and keep moving away from that noise.",
            when = { combatReactionRole = "house_alarm_reply" },
            priority = 6,
        },
    },
})

Catalog.Register("semantic.world.utility.outage", {
    variants = {
        {
            id = "semantic.world.utility.outage.power_shutoff_open",
            templateID = "world.utility.outage.power_shutoff_open",
            fallback = "The lights aren't coming back on. The grid gave out today, {addressee.name}.",
            when = { combatReactionRole = "power_shutoff_open" },
            priority = 6,
        },
        {
            id = "semantic.world.utility.outage.power_shutoff_reply",
            templateID = "world.utility.outage.power_shutoff_reply",
            fallback = "I felt the hum stop too, {addressee.name}. Flashlights and generators from here on out.",
            when = { combatReactionRole = "power_shutoff_reply" },
            priority = 6,
        },
        {
            id = "semantic.world.utility.outage.water_shutoff_open",
            templateID = "world.utility.outage.water_shutoff_open",
            fallback = "Pipes just ran dry today, {addressee.name}. Water system finally quit on us.",
            when = { combatReactionRole = "water_shutoff_open" },
            priority = 6,
        },
        {
            id = "semantic.world.utility.outage.water_shutoff_reply",
            templateID = "world.utility.outage.water_shutoff_reply",
            fallback = "Got it, {addressee.name}. Rain collectors and pots are top priority now.",
            when = { combatReactionRole = "water_shutoff_reply" },
            priority = 6,
        },
    },
})

Catalog.Register("semantic.world.object.notice", {
    variants = {
        {
            id = "semantic.world.object.notice.tv_reminisce_open",
            templateID = "world.object.notice.tv_reminisce_open",
            fallback = "Seeing an old TV still sitting there hits strange, {addressee.name}.",
            when = { combatReactionRole = "tv_reminisce_open" },
            priority = 6,
        },
        {
            id = "semantic.world.object.notice.tv_reminisce_reply",
            templateID = "world.object.notice.tv_reminisce_reply",
            fallback = "Yeah, {addressee.name}, feels like a lifetime ago when that was our biggest worry.",
            when = { combatReactionRole = "tv_reminisce_reply" },
            priority = 6,
        },
        {
            id = "semantic.world.object.notice.tv_power_out_open",
            templateID = "world.object.notice.tv_power_out_open",
            fallback = "Dead screen and dark tubes, {addressee.name}. Without the grid, that TV's just furniture.",
            when = { combatReactionRole = "tv_power_out_open" },
            priority = 6,
        },
        {
            id = "semantic.world.object.notice.tv_power_out_reply",
            templateID = "world.object.notice.tv_power_out_reply",
            fallback = "Feels eerie seeing every screen dead like that, {addressee.name}.",
            when = { combatReactionRole = "tv_power_out_reply" },
            priority = 6,
        },
    },
})

Catalog.Register("semantic.world.media.broadcast", {
    variants = {
        {
            id = "semantic.world.media.broadcast.tv_watching_life_and_living_open",
            templateID = "world.media.broadcast.tv_watching_life_and_living_open",
            fallback = "Shh, {addressee.name}, keep watching {slot.show.name}! You can learn solid survival tricks from this.",
            when = { combatReactionRole = "tv_watching_life_and_living_open" },
            priority = 6,
        },
        {
            id = "semantic.world.media.broadcast.tv_watching_life_and_living_reply",
            templateID = "world.media.broadcast.tv_watching_life_and_living_reply",
            fallback = "Taking mental notes already, {addressee.name}. Keep the volume down just in case.",
            when = { combatReactionRole = "tv_watching_life_and_living_reply" },
            priority = 6,
        },
        {
            id = "semantic.world.media.broadcast.tv_watching_show_open",
            templateID = "world.media.broadcast.tv_watching_show_open",
            fallback = "Still weird hearing voices on {slot.show.name}, {addressee.name}.",
            when = { combatReactionRole = "tv_watching_show_open" },
            priority = 6,
        },
        {
            id = "semantic.world.media.broadcast.tv_watching_show_reply",
            templateID = "world.media.broadcast.tv_watching_show_reply",
            fallback = "Feels oddly grounding listening to {slot.show.name} with you, {addressee.name}.",
            when = { combatReactionRole = "tv_watching_show_reply" },
            priority = 6,
        },
    },
})

return true
