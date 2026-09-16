-- Converts approved semantic task requests into bounded action plans.
--
-- This module is intentionally narrow.  It does not resolve live world
-- objects, move an NPC, or mutate inventory.  Providers own those effects;
-- this handler only validates the request and composes the ordered steps.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Requests = PNC.Semantics.TaskRequestService
local Plans = PNC.Semantics.ActionPlanService
local WorldTargets = PNC.Semantics.WorldTargetResolver
local Handler = {}

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function normalized(value)
    return string.upper(tostring(value or ""))
end

local function safePart(value, fallback)
    local result = text(value) or fallback or "unknown"
    result = string.gsub(result, "[^%w_%.:%-]", "_")
    return string.sub(result, 1, 48)
end

local function npcIDFor(request, context)
    context = type(context) == "table" and context or {}
    local recipient = request and request.recipient
    local actor = request and request.actor
    return text(context.npcID or context.targetID
        or (recipient and (recipient.id or recipient.entityID))
        or (actor and actor.id))
end

local function requestIDFor(request, npcID)
    local requestID = text(request and request.requestID)
    if requestID then return requestID end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return "generated:" .. tostring(npcID) .. ":" .. tostring(now)
end

local function targetFor(request)
    local target = request and request.target
    if type(target) ~= "table" then return nil, "target_required" end

    local category = normalized(target.category or target.concept)
    if category == "CAMPFIRE" then
        return {
            kind = "campfire",
            -- `id` on a semantic concept is commonly the vocabulary id
            -- (CAMPFIRE), not a world-object identity. Only accept an
            -- explicit world id at this boundary.
            targetID = text(target.targetID or target.objectID
                or target.worldID),
            clientHint = type(target.clientHint) == "table"
                and target.clientHint or nil,
            radius = math.max(1, math.min(32,
                tonumber(target.radius) or 16)),
            stopDistance = math.max(0.25,
                tonumber(target.stopDistance) or 1.25),
            mode = text(target.mode) or "walk",
        }
    end

    if WorldTargets and type(WorldTargets.ResolveKind) == "function" then
        local kind = WorldTargets.ResolveKind(target)
        if kind then
            local resolved = {}
            for key, value in pairs(target) do resolved[key] = value end
            resolved.kind = kind
            return resolved
        end
    end

    if text(target.kind) and text(target.kind) ~= "phrase"
        or tonumber(target.x or target.targetX) ~= nil
    then
        return target
    end
    return nil, "unsupported_wait_target"
end

local function durationFor(request)
    local modifiers = request and request.modifiers or {}
    local extensions = request and request.extensions or {}
    local value = modifiers.durationMs or modifiers.duration
        or extensions.durationMs or extensions.duration
    value = tonumber(value) or 30000
    return math.max(0, math.min(86400000, math.floor(value)))
end

local function buildPlan(request, context)
    local npcID = npcIDFor(request, context)
    local target, targetReason = targetFor(request)
    if not npcID then return nil, "npc_required" end
    if not target then return nil, targetReason end

    local requestID = requestIDFor(request, npcID)
    return {
        planID = "semantic:wait_at:" .. safePart(npcID)
            .. ":" .. safePart(requestID),
        npcID = npcID,
        requestID = requestID,
        source = request.source or "semantic_dialogue",
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = request.provenance,
        metadata = {
            taskAction = "WAIT_AT",
            targetKind = target.kind,
        },
        steps = {
            {
                id = "move_to_target",
                action = "MOVE_TO",
                parameters = {
                    target = target,
                    mode = target.mode or "walk",
                    stopDistance = target.stopDistance,
                },
            },
            {
                id = "wait_at_target",
                action = "WAIT",
                parameters = { durationMs = durationFor(request) },
            },
        },
    }
end

function Handler.Validate(request, context)
    if not request or request.intent ~= "REQUEST"
        or request.action ~= "WAIT_AT"
    then
        return false, "wait_at_request_invalid"
    end
    if not npcIDFor(request, context) then return false, "npc_required" end
    local _, reason = targetFor(request)
    if reason then return false, reason end
    return true
end

function Handler.Submit(request, context)
    local plan, reason = buildPlan(request, context)
    local accepted
    local submitted
    local submitDetails
    if not plan then
        return false, reason
    end
    accepted, submitted, submitDetails = Plans.Submit(plan, context)
    if accepted ~= true then return false, submitted, submitDetails end
    return {
        accepted = true,
        status = "accepted",
        action = request.action,
        planID = submitted.planID,
        npcID = submitted.npcID,
        plan = Plans.Get(submitted.npcID),
    }
end

if Requests and type(Requests.RegisterHandler) == "function" then
    Requests.RegisterHandler("WAIT_AT", Handler)
end

return Handler
