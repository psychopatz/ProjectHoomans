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
    },
    {
        action = "thumbsdown",
        act = "DISAPPROVE",
        topic = "disapproval",
    },
    {
        action = "wavehi",
        act = "GREET",
        topic = "greeting",
    },
    {
        action = "wavebye",
        act = "FAREWELL",
        topic = "farewell",
    },
    {
        action = "thankyou",
        act = "THANK",
        topic = "thanks",
    },
    {
        action = "thumbsup",
        act = "ACK",
        topic = "acknowledgement",
    },
    {
        action = "clap",
        act = "PRAISE",
        topic = "praise",
    },
    {
        action = "salute",
        act = "ACK",
        topic = "acknowledgement",
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
                        { kind = "translation", templateID = realizationID },
                    },
                },
            },
        },
    }
end

Catalog.Register("semantic.emote.player", { variants = variants })

