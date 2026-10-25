-- Registered quest-operation action contracts.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
local Adapter = PNC.Semantics.CommandAdapter

-- The clinic-supplies quest is an authoritative contract, not a second
-- command implementation. These descriptors let the same generated
-- simple-command template expose its offer, acceptance, status query, and
-- turn-in operations while the server-owned quest service remains the only
-- state mutator.
local QUEST_RESPONSE_POOLS = {
    offer = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferQueued",
            en = "I can help with the clinic supplies.",
            tl = "Matutulungan kita sa mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferRejected",
            en = "I can't take that clinic-supplies request right now.",
            tl = "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestOfferFailed",
            en = "I couldn't check that clinic-supplies request.",
            tl = "Hindi ko masuri ang kahilingan para sa suplay.",
        },
    },
    accept = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedQueued",
            en = "I'll bring the clinic supplies.",
            tl = "Dadalahin ko ang mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedRejected",
            en = "I can't accept that request right now.",
            tl = "Hindi ko matatanggap ang kahilingang iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestAcceptedFailed",
            en = "I couldn't accept that request.",
            tl = "Hindi ko matanggap ang kahilingang iyon.",
        },
    },
    status = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusQueued",
            en = "I'll check the clinic-supplies request.",
            tl = "Susuriin ko ang kahilingan para sa suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusRejected",
            en = "I can't check that request right now.",
            tl = "Hindi ko masuri ang kahilingang iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestStatusFailed",
            en = "I couldn't check that request.",
            tl = "Hindi ko masuri ang kahilingang iyon.",
        },
    },
    turn_in = {
        queued = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInQueued",
            en = "I'll turn in the clinic supplies.",
            tl = "Ipapasa ko ang mga suplay ng klinika.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInRejected",
            en = "I can't turn that in yet.",
            tl = "Hindi ko pa maipapasa iyon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_QuestTurnInFailed",
            en = "I couldn't turn in the clinic supplies.",
            tl = "Hindi ko maipasa ang mga suplay ng klinika.",
        },
    },
}

local QUEST_OPERATIONS = {
    {
        action = "HELP",
        capabilityID = "pnc:quest.clinic_supplies.offer",
        commandID = "quest:clinic_supplies:offer",
        operation = "offer",
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "HELP" },
        },
        responses = QUEST_RESPONSE_POOLS.offer,
    },
    {
        action = "QUEST_ACCEPT",
        capabilityID = "pnc:quest.clinic_supplies.accept",
        commandID = "quest:clinic_supplies:accept",
        operation = "accept",
        triggerFrames = {
            { intent = "ACCEPT", speechAct = "ACCEPT", action = "QUEST_ACCEPT" },
        },
        responses = QUEST_RESPONSE_POOLS.accept,
    },
    {
        action = "QUEST_STATUS",
        capabilityID = "pnc:quest.clinic_supplies.status",
        commandID = "quest:clinic_supplies:status",
        operation = "status",
        triggerFrames = {
            { intent = "QUESTION", speechAct = "QUESTION", action = "QUEST_STATUS" },
        },
        responses = QUEST_RESPONSE_POOLS.status,
    },
    {
        action = "QUEST_TURN_IN",
        capabilityID = "pnc:quest.clinic_supplies.turn_in",
        commandID = "quest:clinic_supplies:turn_in",
        operation = "turn_in",
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "QUEST_TURN_IN" },
        },
        responses = QUEST_RESPONSE_POOLS.turn_in,
    },
}

local function registerQuestOperation(operation)
    local capabilityID = operation.capabilityID
    Adapter.RegisterAction(operation.action, {
        capabilityID = capabilityID,
        owner = "PNC.QuestService",
        route = "existing_quest_contract",
        workflowKind = "simple_command",
        templateVersion = 1,
        contractVersion = 1,
        commandID = operation.commandID,
        operation = operation.operation,
        handlerID = "PNC.Client.RequestSemanticQuest",
        targetScope = "single_recipient",
        triggerFrames = operation.triggerFrames,
        requiredSlots = {
            npcID = {
                type = "entity",
                owner = "dialogue_context",
                source = "npcID",
            },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = capabilityID,
            requiresTarget = true,
            requiresAuthority = true,
        },
        outcomeMapping = {
            queued = "queued",
            accepted = "queued",
            pending = "queued",
            network_queued = "queued",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = operation.responses,
        translationOwner = "ProjectHoomans",
        arguments = {
            npcID = "giver_npc",
            questID = "pnc.quest.clinic_supplies",
            operation = operation.operation,
            expectedRevision = "conversation_quest_revision",
        },
        requires = {
            "conversation_or_quest_authority",
            "resolved_giver",
        },
        result = {
            "requested", "available", "accepted", "active", "ready",
            "rewarded", "rejected", "failed",
        },
    })
end

for _, operation in ipairs(QUEST_OPERATIONS) do
    registerQuestOperation(operation)
end

return Adapter
