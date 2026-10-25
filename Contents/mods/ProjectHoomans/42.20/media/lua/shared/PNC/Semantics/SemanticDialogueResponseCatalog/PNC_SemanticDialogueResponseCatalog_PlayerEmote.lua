-- Semantic realization plans for the player's visible vanilla-emote speech.
--
-- The existing CompanionCommandFlavor groups remain authored localized
-- content.  They are compatibility aliases selected only after this pool
-- has chosen the semantic emote meaning and realization family.

local Catalog = PNC.Semantics.ResponseCatalog

local DEFINITIONS = {
    {
        action = "insult",
        act = "INSULT",
        topic = "hostility",
        flavorID = "vanilla_emote_insult",
        fallback = "Back off.",
    },
    {
        action = "thumbsdown",
        act = "DISAPPROVE",
        topic = "disapproval",
        flavorID = "vanilla_emote_thumbsdown",
        fallback = "No.",
    },
    {
        action = "wavehi",
        act = "GREET",
        topic = "greeting",
        flavorID = "vanilla_emote_wavehi",
        fallback = "Hey.",
    },
    {
        action = "wavebye",
        act = "FAREWELL",
        topic = "farewell",
        flavorID = "vanilla_emote_wavebye",
        fallback = "Take care.",
    },
    {
        action = "thankyou",
        act = "THANK",
        topic = "thanks",
        flavorID = "vanilla_emote_thankyou",
        fallback = "Thanks.",
    },
    {
        action = "thumbsup",
        act = "ACK",
        topic = "acknowledgement",
        flavorID = "vanilla_emote_thumbsup",
        fallback = "Good.",
    },
    {
        action = "clap",
        act = "PRAISE",
        topic = "praise",
        flavorID = "vanilla_emote_clap",
        fallback = "Well done.",
    },
    {
        action = "salute",
        act = "ACK",
        topic = "acknowledgement",
        flavorID = "vanilla_emote_salute",
        fallback = "Respect.",
    },
}

local variants = {}
local index
local definition
local realizationID

for index = 1, #DEFINITIONS do
    definition = DEFINITIONS[index]
    realizationID = "semantic.emote.player." .. definition.action
    variants[#variants + 1] = {
        id = realizationID,
        templateID = realizationID,
        fallback = definition.fallback,
        compatibilityFlavorID = definition.flavorID,
        dialogueAct = definition.act,
        topic = definition.topic,
        when = { action = definition.action },
        priority = 2,
        plan = {
            dialogueAct = definition.act,
            sourcePoolID = "semantic.emote.player",
            topic = definition.topic,
            turns = {
                {
                    segments = {
                        { kind = "literal", text = definition.fallback },
                    },
                },
            },
        },
    }
end

Catalog.Register("semantic.emote.player", { variants = variants })

