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

local Metadata = require
    "PNC/Semantics/PNC_SemanticTaskAdapter_Metadata"
Metadata.Register(Adapter, dispatchSemanticTask)

return Adapter
