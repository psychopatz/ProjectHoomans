-- Converts semantic task requests into action plans.  This is the domain
-- adapter between dialogue semantics and ActionPlanService; it owns neither
-- NLU nor gameplay effects.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local TaskRequests = PNC.Semantics.TaskRequestService
local ActionPlans = PNC.Semantics.ActionPlanService

local function upper(value)
    return string.upper(tostring(value or ""))
end

local function text(value)
    local result = tostring(value or "")
    return result ~= "" and result or nil
end

local function targetFor(request)
    local target = request and request.target
    if type(target) ~= "table" then return nil, "target_required" end
    local category = upper(target.category or target.concept or target.value)
    if category == "CAMPFIRE" then
        return {
            kind = "campfire",
            radius = tonumber(target.radius) or 16,
            stopDistance = tonumber(target.stopDistance) or 1.25,
        }
    end
    if tonumber(target.x) and tonumber(target.y) then
        return {
            kind = text(target.kind) or "world_point",
            id = text(target.id or target.targetID),
            x = tonumber(target.x),
            y = tonumber(target.y),
            z = tonumber(target.z) or 0,
            stopDistance = tonumber(target.stopDistance) or 0.7,
        }
    end
    return nil, "target_kind_unsupported"
end

local function npcIDFor(request, context)
    local recipient = request and request.recipient
    local value = context and (context.npcID or context.targetID)
        or recipient and (recipient.id or recipient.entityID
            or recipient.npcID)
    value = text(value)
    return value
end

local function planIDFor(request, npcID)
    local requestID = text(request and request.requestID)
        or tostring(PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    local raw = "semantic:" .. tostring(npcID) .. ":" .. requestID
    return string.sub(raw, 1, 120)
end

local function buildWaitPlan(request, context)
    local npcID = npcIDFor(request, context)
    local target, reason = targetFor(request)
    if not npcID then return nil, "npc_required" end
    if not target then return nil, reason end
    local requestID = text(request.requestID)
    local durationMs = request.modifiers
        and tonumber(request.modifiers.durationMs)
        or request.extensions and tonumber(request.extensions.durationMs)
        or 30000
    return {
        planID = planIDFor(request, npcID),
        npcID = npcID,
        source = "semantic_dialogue",
        requestID = requestID,
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = {
            adapter = "semantic_action_plan_task_handler",
            action = request.action,
        },
        metadata = {
            speechAct = request.speechAct,
            actor = request.actor,
            recipient = request.recipient,
        },
        interruptPolicy = "PAUSE",
        steps = {
            {
                id = "move:" .. tostring(requestID or "request"),
                action = "MOVE_TO",
                parameters = { target = target },
                onFailure = "STOP",
            },
            {
                id = "wait:" .. tostring(requestID or "request"),
                action = "WAIT",
                parameters = { durationMs = durationMs },
                onFailure = "STOP",
            },
        },
    }
end

local Handler = {}

function Handler.Validate(request, context)
    if not request or request.intent ~= "REQUEST" then
        return false, "semantic_request_required"
    end
    if upper(request.action) ~= "WAIT_AT" then
        return false, "unsupported_action"
    end
    local _, reason = npcIDFor(request, context)
    if reason then return false, reason end
    local _, targetReason = targetFor(request)
    if targetReason then return false, targetReason end
    return true
end

function Handler.Submit(request, context)
    local plan, reason = buildWaitPlan(request, context)
    local accepted
    local result
    if not plan then return false, reason end
    accepted, result = ActionPlans.Submit(plan, context)
    if not accepted then return false, result end
    return true, "accepted", result
end

if TaskRequests and type(TaskRequests.RegisterHandler) == "function" then
    TaskRequests.RegisterHandler("WAIT_AT", Handler)
end

return Handler
