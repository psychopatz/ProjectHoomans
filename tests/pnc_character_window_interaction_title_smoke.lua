local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    UI = {
        Layout = {},
        Theme = {},
    },
}
PNC = {
    Conversation = {},
    Network = { ClientState = {} },
    CharacterWindowShared = {
        Text = function(_, fallback) return fallback end,
    },
}

local Tabs = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/CharacterWindow/PNC_CharacterWindow_Interactions.lua"
)

T.equal(Tabs.FormatInteractionTitle({
    kind = "llm_social_reaction",
    interactionType = "player_insulted",
    choiceID = "insult",
}), "PLAYER INSULTED", "LLM title uses the semantic interaction type")

T.equal(Tabs.FormatInteractionTitle({
    kind = "llm_social_reaction",
    choiceID = "praise",
}), "PLAYER PRAISED", "legacy LLM entry uses its reaction fallback")

T.equal(Tabs.FormatInteractionTitle({
    kind = "npc_proximity_greeting",
}), "NPC PROXIMITY GREETING", "non-LLM diary title remains unchanged")

T.finish("pnc_character_window_interaction_title_smoke")
