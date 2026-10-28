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
                templateID = "semantic.task.fetch.admitted",
            },
            active = {
                templateID = "semantic.task.fetch.active",
            },
            completed = {
                templateID = "semantic.task.fetch.completed",
            },
            rejected = {
                templateID = "semantic.task.fetch.rejected",
            },
            failed = {
                templateID = "semantic.task.fetch.failed",
            },
        },
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
                templateID = "semantic.task.wait_at.admitted",
            },
            active = {
                templateID = "semantic.task.wait_at.active",
            },
            completed = {
                templateID = "semantic.task.wait_at.completed",
            },
            rejected = {
                templateID = "semantic.task.wait_at.rejected",
            },
            failed = {
                templateID = "semantic.task.wait_at.failed",
            },
        },
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

