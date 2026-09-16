-- Compose an inventory-aware give request into the shared ordered plan.
-- This module chooses steps only; providers own selection, movement, and the
-- authoritative inventory mutation boundary.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Requests = PNC.Semantics.TaskRequestService
local Plans = PNC.Semantics.ActionPlanService
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
    return text(context.npcID or context.targetID
        or recipient and (recipient.id or recipient.entityID))
end

local function requestIDFor(request, npcID)
    local requestID = text(request and request.requestID)
    if requestID then return requestID end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return "generated:" .. tostring(npcID) .. ":" .. tostring(now)
end

local function objectFor(request)
    local object = request and request.object
    if type(object) ~= "table" then return nil, "item_required" end
    if object.reference then return nil, "item_reference_unresolved" end
    if not text(object.itemID or object.fullType or object.category
        or object.primary or object.concept or object.text or object.value)
    then
        return nil, "item_identity_required"
    end
    return object
end

local function quantityFor(object, request)
    local modifiers = request and request.modifiers or {}
    local quantity = object and object.quantity
        or modifiers.quantity
    quantity = tonumber(quantity)
    return quantity and math.max(1, math.min(1024, math.floor(quantity)))
        or "SOME"
end

local function buildPlan(request, context)
    local npcID = npcIDFor(request, context)
    local object, objectReason = objectFor(request)
    local requestID
    if not npcID then return nil, "npc_required" end
    if not object then return nil, objectReason end
    requestID = requestIDFor(request, npcID)
    return {
        planID = "semantic:give:" .. safePart(npcID)
            .. ":" .. safePart(requestID),
        npcID = npcID,
        requestID = requestID,
        source = request.source or "semantic_dialogue",
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = request.provenance,
        metadata = {
            taskAction = "GIVE",
            objectText = text(object.text or object.value),
        },
        steps = {
            {
                id = "select_item",
                action = "SELECT_ITEM",
                parameters = {
                    object = object,
                    quantity = quantityFor(object, request),
                },
            },
            {
                id = "move_to_player",
                action = "MOVE_TO",
                parameters = {
                    target = {
                        kind = "player",
                        targetID = "player",
                        dynamic = true,
                        mode = "walk",
                        stopDistance = 1.25,
                    },
                },
            },
            {
                id = "give_item",
                action = "GIVE_ITEM",
                parameters = {
                    object = object,
                    quantity = quantityFor(object, request),
                },
            },
        },
    }
end

function Handler.Validate(request, context)
    if not request or request.intent ~= "REQUEST"
        or normalized(request.action) ~= "GIVE"
    then
        return false, "give_request_invalid"
    end
    local _, reason = objectFor(request)
    if reason then return false, reason end
    if not npcIDFor(request, context) then return false, "npc_required" end
    return true
end

function Handler.Submit(request, context)
    local plan, reason = buildPlan(request, context)
    local accepted
    local submitted
    local submitDetails
    if not plan then return false, reason end
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
    Requests.RegisterHandler("GIVE", Handler)
end

return Handler
