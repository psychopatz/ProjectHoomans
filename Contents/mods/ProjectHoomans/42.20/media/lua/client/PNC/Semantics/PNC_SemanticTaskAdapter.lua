-- Client-side seam for semantic task requests. This adapter may only prepare
-- a contract or hand it to an explicitly registered transport; it never
-- mutates NPC state and never reaches into Tasking internals.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Contract = PNC.Semantics.TaskRequest
    or require "PNC/Semantics/PNC_SemanticTaskRequest"
local Adapter = PNC.Semantics.TaskAdapter or {}
PNC.Semantics.TaskAdapter = Adapter

Adapter.VERSION = 1
Adapter.Actions = Adapter.Actions or {}

local function normalized(value)
    value = string.upper(tostring(value or ""))
    return string.gsub(value, "[%s%-]+", "_")
end

function Adapter.RegisterAction(action, definition)
    action = normalized(action)
    if action == "" or type(definition) ~= "table" then
        return false, "invalid_task_action"
    end
    Adapter.Actions[action] = definition
    return true, definition
end

function Adapter.Resolve(actionIntent, context)
    if type(actionIntent) ~= "table" then
        return nil, "invalid_action_intent"
    end
    if actionIntent.modifiers
        and actionIntent.modifiers.negated == true
    then
        return nil, "negated_action"
    end
    local action = normalized(actionIntent.action)
    local definition = Adapter.Actions[action]
    if not definition then return nil, "unmapped_action" end
    local request, reason = Contract.FromActionIntent(actionIntent, context)
    if not request then return nil, reason end
    if type(definition.CanSubmit) == "function"
        and definition.CanSubmit(request, context) ~= true
    then
        return nil, "task_submission_rejected"
    end
    return request, definition
end

function Adapter.Dispatch(actionIntent, context)
    context = type(context) == "table" and context or {}
    local request, definitionOrReason = Adapter.Resolve(actionIntent, context)
    if not request then
        return {
            status = definitionOrReason == "negated_action"
                and "skipped" or "unmapped",
            accepted = false,
            reason = definitionOrReason,
            action = actionIntent and actionIntent.action,
        }
    end

    local definition = definitionOrReason
    local binding = type(definition) == "table"
        and definition.capabilityID and {
            id = definition.capabilityID,
            owner = definition.owner,
            route = definition.route,
            handlerID = definition.handlerID,
            arguments = definition.arguments,
            requires = definition.requires,
            result = definition.result,
        } or nil
    local metadata = binding and {
        binding = binding,
        capabilityID = binding.id,
        handlerID = binding.handlerID,
    } or {}

    if type(definition.Dispatch) ~= "function" then
        return {
            status = "unhandled",
            accepted = false,
            reason = "task_transport_unavailable",
            action = request.action,
            request = request,
            binding = metadata.binding,
            capabilityID = metadata.capabilityID,
            handlerID = metadata.handlerID,
        }
    end

    local ok, accepted, reason, details = pcall(
        definitionOrReason.Dispatch, request, context)
    if not ok then
        return {
            status = "failed",
            accepted = false,
            reason = "task_transport_failed",
            error = tostring(accepted),
            action = request.action,
            request = request,
            binding = metadata.binding,
            capabilityID = metadata.capabilityID,
            handlerID = metadata.handlerID,
        }
    end
    if type(accepted) == "table" then
        accepted.request = accepted.request or request
        accepted.binding = accepted.binding or metadata.binding
        accepted.capabilityID = accepted.capabilityID
            or metadata.capabilityID
        accepted.handlerID = accepted.handlerID or metadata.handlerID
        return accepted
    end
    return {
        status = accepted == true and "accepted" or "rejected",
        accepted = accepted == true,
        reason = reason,
        details = details,
        action = request.action,
        request = request,
        binding = metadata.binding,
        capabilityID = metadata.capabilityID,
        handlerID = metadata.handlerID,
    }
end

-- Semantic-task transport. More actions can register their own definitions
-- without changing this adapter; the server remains the only place that can
-- create or mutate an action plan. The metadata below is data owned by the
-- task capability and is consumed by the shared automatic flow generator.
local function dispatchSemanticTask(request, context)
    local client = PNC.Client
    if not client or type(client.RequestSemanticTask) ~= "function" then
        return false, "task_transport_unavailable"
    end
    return client.RequestSemanticTask(request, context)
end

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

local TASK_RESPONSE_POOLS = {
    GIVE = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveAdmitted",
            en = "Okay, I'll give that to you.",
            tl = "Sige, ibibigay ko iyon sa iyo.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveActive",
            en = "I'm handing that over now.",
            tl = "Ibinibigay ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveCompleted",
            en = "Here you go.",
            tl = "Heto na.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveRejected",
            en = "I can't give that right now.",
            tl = "Hindi ko maibigay iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveFailed",
            en = "I couldn't give that.",
            tl = "Hindi ko naibigay iyon.",
        },
    },
    EAT = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatAdmitted",
            en = "I'll eat that.",
            tl = "Kakainin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatActive",
            en = "I'm eating that now.",
            tl = "Kinakain ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatCompleted",
            en = "That hit the spot.",
            tl = "Sakto iyon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatRejected",
            en = "I can't eat that right now.",
            tl = "Hindi ko makain iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatFailed",
            en = "I couldn't eat that.",
            tl = "Hindi ko nakain iyon.",
        },
    },
    DRINK = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkAdmitted",
            en = "I'll drink that.",
            tl = "Iinumin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkActive",
            en = "I'm drinking that now.",
            tl = "Ini-inom ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkCompleted",
            en = "I feel better.",
            tl = "Mas mabuti na ang pakiramdam ko.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkRejected",
            en = "I can't drink that right now.",
            tl = "Hindi ko mainom iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkFailed",
            en = "I couldn't drink that.",
            tl = "Hindi ko nainom iyon.",
        },
    },
    REFILL = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillAdmitted",
            en = "I'll refill that.",
            tl = "Pupunuin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillActive",
            en = "I'm refilling that now.",
            tl = "Pinupuno ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillCompleted",
            en = "It's full now.",
            tl = "Puno na ito ngayon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillRejected",
            en = "I can't refill that right now.",
            tl = "Hindi ko mapuno iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillFailed",
            en = "I couldn't refill that.",
            tl = "Hindi ko napuno iyon.",
        },
    },
    CONSUME = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeAdmitted",
            en = "I'll use that.",
            tl = "Gagamitin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeActive",
            en = "I'm using that now.",
            tl = "Ginagamit ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeCompleted",
            en = "That's done.",
            tl = "Tapos na iyon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeRejected",
            en = "I can't use that right now.",
            tl = "Hindi ko magamit iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeFailed",
            en = "I couldn't use that.",
            tl = "Hindi ko nagamit iyon.",
        },
    },
}

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

for _, action in ipairs({
    "CAMP", "GIVE", "FETCH", "EAT", "DRINK", "REFILL", "CONSUME",
    "WAIT_AT",
}) do
    local definition = TASK_METADATA[action] or {}
    definition.Dispatch = dispatchSemanticTask
    Adapter.RegisterAction(action, definition)
end

return Adapter
