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
            templateID = "semantic.quest.clinic_supplies.offer.queued",
        },
        rejected = {
            templateID = "semantic.quest.clinic_supplies.offer.rejected",
        },
        failed = {
            templateID = "semantic.quest.clinic_supplies.offer.failed",
        },
    },
    accept = {
        queued = {
            templateID = "semantic.quest.clinic_supplies.accept.queued",
        },
        rejected = {
            templateID = "semantic.quest.clinic_supplies.accept.rejected",
        },
        failed = {
            templateID = "semantic.quest.clinic_supplies.accept.failed",
        },
    },
    status = {
        queued = {
            templateID = "semantic.quest.clinic_supplies.status.queued",
        },
        rejected = {
            templateID = "semantic.quest.clinic_supplies.status.rejected",
        },
        failed = {
            templateID = "semantic.quest.clinic_supplies.status.failed",
        },
    },
    turn_in = {
        queued = {
            templateID = "semantic.quest.clinic_supplies.turn_in.queued",
        },
        rejected = {
            templateID = "semantic.quest.clinic_supplies.turn_in.rejected",
        },
        failed = {
            templateID = "semantic.quest.clinic_supplies.turn_in.failed",
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
