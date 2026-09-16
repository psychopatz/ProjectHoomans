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

local function requestNPCID(request, context)
    context = type(context) == "table" and context or {}
    local recipient = request and request.recipient
    return tostring(context.npcID or context.targetID
        or recipient and (recipient.id or recipient.entityID) or "")
end

-- Client-originated semantic tasks use the same conversation/companion
-- authority as existing gameplay commands. Server-owned NPC-to-NPC work can
-- omit `player` because it is already inside the authoritative simulation.
function Service.Authorize(request, context)
    context = type(context) == "table" and context or {}
    if context.internal == true or not context.player then
        return true, "server_owned"
    end

    local npcID = requestNPCID(request, context)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end

    local token = tostring(context.conversationToken or "")
    if token ~= "" then
        local authority = PNC.Conversation
            and PNC.Conversation.Authority
        local internal = authority and authority.Internal
        if not internal or type(internal.ValidateLease) ~= "function" then
            return false, "conversation_authority_unavailable"
        end
        local ok, reason = internal.ValidateLease(
            context.player, record, token)
        return ok == true, reason or (ok and "conversation_authorized"
            or "invalid_lease")
    end

    local commands = PNC.CompanionCommands
    if commands and type(commands.CanPlayerCommand) == "function" then
        local ok, reason = commands.CanPlayerCommand(
            record,
            context.player,
            tonumber(PNC.Const and PNC.Const.INVENTORY_INTERACTION_RADIUS)
                or 3
        )
        if ok == true then return true, reason or "companion_authorized" end
    end
    return false, "conversation_token_required"
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

    local authorized, authorizationReason = Service.Authorize(
        normalizedRequest, context)
    if authorized ~= true then
        return {
            accepted = false,
            status = "rejected",
            reason = authorizationReason or "task_unauthorized",
            action = normalizedRequest.action,
            request = normalizedRequest,
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
