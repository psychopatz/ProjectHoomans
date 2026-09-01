local T = require "tests/support/test"
T.addPackagePaths()

local handlers = {}
local receivedRelationship

PNC = {
    Const = {
        CMD_CONVERSATION_RELATIONSHIP = "ConversationRelationship",
        CMD_LLM_SOCIAL_REACTION_RESULT = "LLMSocialReactionResult",
        CMD_PLAYER_EMOTE_INTERACTION_RESULT = "PlayerEmoteInteractionResult",
        CMD_MAP_COMMAND_RESULT = "MapCommandResult",
        CMD_FACTION_TOLL = "FactionToll",
        CMD_CONVERSATION_CEASEFIRE_RESULT = "CeasefireResult",
        CMD_CONVERSATION_BLOCK = "ConversationBlock",
        CMD_CONVERSATION_OUTCOME = "ConversationOutcome",
        CMD_CONVERSATION_RECRUIT_RESULT = "RecruitResult",
    },
    Network = { ClientState = {} },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, callback)
                handlers[command] = callback
            end,
        },
    },
    Conversation = {
        Relationship = {
            ReceivePresentation = function(summary)
                receivedRelationship = summary
            end,
        },
    },
    Core = { Now = function() return 1234 end },
}
PsychopatzCore = {
    DebugTrace = {
        IsEnabled = function() return false end,
    },
}

T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_ConversationDiary.lua")
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_InteractionResults.lua")

local result = {
    requestID = "request-1",
    callID = "call-1",
    npcID = "npc-1",
    tool = "social_react",
    accepted = true,
    reaction = "insult",
    intensity = "normal",
    relationshipBefore = { npcID = "npc-1", approval = 10, respect = 8, familiarity = 4 },
    relationshipAfter = { npcID = "npc-1", approval = 6, respect = 5, familiarity = 4 },
    relationship = { npcID = "npc-1", approval = 6, respect = 5, familiarity = 4 },
    relationshipDelta = { approval = -4, respect = -3, familiarity = 0 },
    memoryID = "memory-1",
    memoryType = "player_insulted",
    interactionType = "player_insulted",
    eventID = "event-1",
    capabilities = {
        available_reactions = { "insult" },
        positive_action_cooldown_active = true,
        positive_action_cooldown_remaining_hours = 24,
    },
}
handlers[PNC.Const.CMD_LLM_SOCIAL_REACTION_RESULT](result)

local clientState = PNC.Network.ClientState
local entries = PNC.Conversation.Diary.Get("npc-1")
T.equal(receivedRelationship.approval, 6,
    "relationship presentation reaches the client")
T.equal(clientState.lastConversationDelta.source, "llm_tool",
    "LLM result is exposed to relationship diagnostics")
T.equal(clientState.lastConversationDelta.delta.respect, -3,
    "LLM result preserves the authoritative delta")
T.equal(clientState.lastConversationDelta.before.approval, 10,
    "LLM result preserves the before snapshot")
T.equal(clientState.lastConversationDelta.after.approval, 6,
    "LLM result preserves the after snapshot")
T.equal(clientState.llmReactionCapabilities["npc-1"]
    .available_reactions[1], "insult",
    "LLM result stores safe server reaction capabilities")
T.equal(#entries, 1,
    "accepted LLM reaction appears in the interaction diary")
T.equal(entries[1].kind, "llm_social_reaction",
    "diary identifies the LLM reaction")
T.equal(entries[1].choiceID, "insult",
    "diary identifies the reaction kind")
T.equal(entries[1].delta.approval, -4,
    "diary renders the authoritative approval delta")

-- Network retries/idempotent server responses must not duplicate the UI row.
handlers[PNC.Const.CMD_LLM_SOCIAL_REACTION_RESULT](result)
T.equal(#PNC.Conversation.Diary.Get("npc-1"), 1,
    "duplicate result does not duplicate the interaction diary")

T.finish("pnc_llm_social_result_diary_smoke")
