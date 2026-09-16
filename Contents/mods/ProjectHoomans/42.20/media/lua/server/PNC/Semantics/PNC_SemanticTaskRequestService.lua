-- Server-side semantic task request router.
--
-- This is deliberately not a second scheduler. A domain registers a narrow
-- handler that owns validation, persistence, Tasking integration, and world
-- effects. The router only normalizes the contract and contains callback
-- failures at the authority boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Contract = PNC.Semantics.TaskRequest
    or require "PNC/Semantics/PNC_SemanticTaskRequest"
local Service = PNC.Semantics.TaskRequestService or {}
PNC.Semantics.TaskRequestService = Service

Service.VERSION = 1
Service.Handlers = Service.Handlers or {}

local function normalized(value)
    value = string.upper(tostring(value or ""))
    return string.gsub(value, "[%s%-]+", "_")
end

local function authority()
    local core = PNC.Core
    if not core or type(core.IsAuthority) ~= "function" then return true end
    return core.IsAuthority() == true
end

function Service.RegisterHandler(action, definition)
    action = normalized(action)
    if action == "" or type(definition) ~= "table"
        or type(definition.Submit) ~= "function"
    then
        return false, "invalid_task_handler"
    end
    if Service.Handlers[action] then
        return false, "task_handler_already_registered"
    end
    definition.action = action
    Service.Handlers[action] = definition
    return true, definition
end

function Service.UnregisterHandler(action)
    action = normalized(action)
    if not Service.Handlers[action] then return false end
    Service.Handlers[action] = nil
    return true
end

function Service.GetHandler(action)
    return Service.Handlers[normalized(action)]
end

function Service.Submit(request, context)
    context = type(context) == "table" and context or {}
    if not authority() then
        return {
            accepted = false,
            status = "rejected",
            reason = "server_authority_required",
        }
    end

    local normalizedRequest, normalizeReason = Contract.Normalize(request)
    if not normalizedRequest then
        return {
            accepted = false,
            status = "rejected",
            reason = normalizeReason,
        }
    end

    local handler = Service.GetHandler(normalizedRequest.action)
    if not handler then
        return {
            accepted = false,
            status = "unhandled",
            reason = "no_task_handler",
            action = normalizedRequest.action,
            request = normalizedRequest,
        }
    end

    if type(handler.Validate) == "function" then
        local valid, validationReason = handler.Validate(
            normalizedRequest, context)
        if valid ~= true then
            return {
                accepted = false,
                status = "rejected",
                reason = validationReason or "task_handler_rejected",
                action = normalizedRequest.action,
                request = normalizedRequest,
            }
        end
    end

    local ok, accepted, reason, details = pcall(
        handler.Submit, normalizedRequest, context)
    if not ok then
        return {
            accepted = false,
            status = "failed",
            reason = "task_handler_failed",
            error = tostring(accepted),
            action = normalizedRequest.action,
            request = normalizedRequest,
        }
    end
    if type(accepted) == "table" then
        accepted.request = accepted.request or normalizedRequest
        return accepted
    end
    return {
        accepted = accepted == true,
        status = accepted == true and "accepted" or "rejected",
        reason = reason,
        details = details,
        action = normalizedRequest.action,
        request = normalizedRequest,
    }
end

function Service.SubmitIR(ir, context)
    local request, reason = Contract.FromIR(ir, context)
    if not request then
        return {
            accepted = false,
            status = "rejected",
            reason = reason,
        }
    end
    return Service.Submit(request, context)
end

return Service
