-- Task capability metadata and registration for the semantic task adapter.
-- Keeping this data separate makes new task capabilities additive and keeps the
-- request/dispatch adapter focused on its stable transport contract.

local Metadata = {}
local TASK_METADATA = {
    FETCH = {
        capabilityID = "pnc:task.fetch",
        owner = "PNC.Semantics.TaskAdapter",
        route = "existing_semantic_task",
        workflowKind = "parameterized_task",
        templateVersion = 1,
        contractVersion = 1,
        targetScope = "single_or_group",
        handlerID = "PNC.Client.RequestSemanticTask",
        arguments = {
            npcID = "actor_target",
            object = "resolved_inventory_selection",
            destination = "resolved_recipient_target",
            scope = "single_or_group",
        },
        requires = {
            "conversation_or_task_authority",
            "resolved_inventory_selection",
        },
        result = {
            "requested", "rejected", "admitted", "active", "completed",
        },
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "FETCH" },
        },
        requiredSlots = {
            npcID = { type = "entity", source = "npcID", owner = "dialogue_context" },
            object = { type = "item", source = "object", owner = "semantic_ir" },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = "pnc:task.fetch",
            requiresAuthority = true,
        },
        outcomeMapping = {
            requested = "admitted",
            accepted = "admitted",
            pending = "admitted",
            admitted = "admitted",
            active = "active",
            completed = "completed",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = {
            admitted = {
                key = "UI_PNC_Conversation_Semantic_GeneratedFetchAdmitted",
                en = "I'll fetch that.",
                tl = "Kukunin ko iyon.",
            },
            active = {
                key = "UI_PNC_Conversation_Semantic_GeneratedFetchActive",
                en = "I'm working on that now.",
                tl = "Inaayos ko na iyon ngayon.",
            },
            completed = {
                key = "UI_PNC_Conversation_Semantic_GeneratedFetchCompleted",
                en = "Here you go.",
                tl = "Heto na.",
            },
            rejected = {
                key = "UI_PNC_Conversation_Semantic_GeneratedFetchRejected",
                en = "I can't fetch that right now.",
                tl = "Hindi ko makuha iyon ngayon.",
            },
            failed = {
                key = "UI_PNC_Conversation_Semantic_GeneratedFetchFailed",
                en = "I couldn't fetch that.",
                tl = "Hindi ko nakuha iyon.",
            },
        },
        translationOwner = "ProjectHoomans",
    },
    WAIT_AT = {
        capabilityID = "pnc:task.wait_at",
        owner = "PNC.Semantics.TaskAdapter",
        route = "existing_semantic_task",
        workflowKind = "parameterized_task",
        templateVersion = 1,
        contractVersion = 1,
        targetScope = "single_or_group",
        handlerID = "PNC.Client.RequestSemanticTask",
        arguments = {
            npcID = "actor_target",
            destination = "resolved_world_target",
            durationMs = "bounded_optional",
            scope = "single_or_group",
        },
        requires = {
            "conversation_or_task_authority",
            "resolved_destination",
        },
        result = {
            "requested", "rejected", "admitted", "active", "completed",
        },
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = "WAIT_AT" },
        },
        requiredSlots = {
            npcID = { type = "entity", source = "npcID", owner = "dialogue_context" },
            destination = { type = "location", source = "target", owner = "semantic_ir" },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = "pnc:task.wait_at",
            requiresTarget = true,
            requiresAuthority = true,
        },
        outcomeMapping = {
            requested = "admitted",
            accepted = "admitted",
            pending = "admitted",
            admitted = "admitted",
            active = "active",
            completed = "completed",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = {
            admitted = {
                key = "UI_PNC_Conversation_Semantic_GeneratedWaitAtAdmitted",
                en = "Okay, I'll wait there.",
                tl = "Sige, maghihintay ako roon.",
            },
            active = {
                key = "UI_PNC_Conversation_Semantic_GeneratedWaitAtActive",
                en = "I'm waiting there now.",
                tl = "Naghihintay na ako roon.",
            },
            completed = {
                key = "UI_PNC_Conversation_Semantic_GeneratedWaitAtCompleted",
                en = "I'm here.",
                tl = "Narito na ako.",
            },
            rejected = {
                key = "UI_PNC_Conversation_Semantic_GeneratedWaitAtRejected",
                en = "I can't wait there right now.",
                tl = "Hindi ako makapaghihintay roon ngayon.",
            },
            failed = {
                key = "UI_PNC_Conversation_Semantic_GeneratedWaitAtFailed",
                en = "I couldn't wait there.",
                tl = "Hindi ako nakapaghintay roon.",
            },
        },
        translationOwner = "ProjectHoomans",
    },
}

local TASK_RESPONSE_POOLS = require
    "PNC/Semantics/PNC_SemanticTaskAdapter_Responses"

local function parameterizedTaskMetadata(action)
    local capabilityID = "pnc:task." .. string.lower(action)
    return {
        capabilityID = capabilityID,
        owner = "PNC.Semantics.TaskAdapter",
        route = "existing_semantic_task",
        workflowKind = "parameterized_task",
        templateVersion = 1,
        contractVersion = 1,
        targetScope = "single_or_group",
        handlerID = "PNC.Client.RequestSemanticTask",
        arguments = {
            npcID = "actor_target",
            object = "resolved_inventory_selection",
            scope = "single_or_group",
        },
        requires = {
            "conversation_or_task_authority",
            "resolved_inventory_selection",
        },
        result = {
            "requested", "rejected", "admitted", "active", "completed",
        },
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = action },
        },
        requiredSlots = {
            npcID = {
                type = "entity",
                source = "npcID",
                owner = "dialogue_context",
            },
            object = {
                type = "item",
                source = "object",
                owner = "semantic_ir",
            },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = capabilityID,
            requiresAuthority = true,
        },
        outcomeMapping = {
            requested = "admitted",
            accepted = "admitted",
            pending = "admitted",
            admitted = "admitted",
            active = "active",
            completed = "completed",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = TASK_RESPONSE_POOLS[action],
        translationOwner = "ProjectHoomans",
    }
end

for _, action in ipairs({ "GIVE", "EAT", "DRINK", "REFILL", "CONSUME" }) do
    TASK_METADATA[action] = parameterizedTaskMetadata(action)
end

function Metadata.Register(adapter, dispatchSemanticTask)
    for _, action in ipairs({
        "CAMP", "GIVE", "FETCH", "EAT", "DRINK", "REFILL", "CONSUME",
        "WAIT_AT",
    }) do
        local definition = TASK_METADATA[action] or {}
        definition.Dispatch = dispatchSemanticTask
        adapter.RegisterAction(action, definition)
    end
end

return Metadata

