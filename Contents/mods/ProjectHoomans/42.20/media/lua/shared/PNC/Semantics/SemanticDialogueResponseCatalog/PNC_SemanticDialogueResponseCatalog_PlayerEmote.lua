-- Semantic realization plans for the player's visible vanilla-emote speech.
--
-- Dialogue Content is the only first-party wording owner.  The pool below
-- chooses the semantic act; SpeechRealization applies the authored phrase.

local Catalog = PNC.Semantics.ResponseCatalog

local DEFINITIONS = {
    {
        action = "insult",
        act = "INSULT",
        topic = "hostility",
        fallback = "Back off.",
    },
    {
        action = "thumbsdown",
        act = "DISAPPROVE",
        topic = "disapproval",
        fallback = "No.",
    },
    {
        action = "wavehi",
        act = "GREET",
        topic = "greeting",
        fallback = "Hey, {names}.",
    },
    {
        action = "wavebye",
        act = "FAREWELL",
        topic = "farewell",
        fallback = "Take care.",
    },
    {
        action = "thankyou",
        act = "THANK",
        topic = "thanks",
        fallback = "Thanks.",
    },
    {
        action = "thumbsup",
        act = "ACK",
        topic = "acknowledgement",
        fallback = "Good.",
    },
    {
        action = "clap",
        act = "PRAISE",
        topic = "praise",
        fallback = "Well done.",
    },
    {
        action = "salute",
        act = "ACK",
        topic = "acknowledgement",
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
        contentOwner = "projecthoomans.dialogue_content.commands_emotes",
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

