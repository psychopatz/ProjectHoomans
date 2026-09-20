-- Compose inventory-aware give/fetch requests into the shared ordered plan.
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

local function containsToken(value, expected)
    value = string.lower(tostring(value or ""))
    for token in string.gmatch(value, "[%a%d_]+") do
        if token == expected then return true end
    end
    return false
end

local function hasExplicitFetchSource(request)
    -- This handler cannot resolve world or container inventories. Preserve
    -- the explicit relation when parsed, and fail closed from the utterance
    -- text if a future pattern omits its source capture.
    if request.sourceEntity ~= nil then return true end
    return containsToken(request.rawText, "from")
        or containsToken(request.normalizedText, "from")
end

local function normalizedTargetPhrase(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%p%s]+", " ")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function targetText(target)
    if type(target) ~= "table" then return target end
    return target.text or target.value or target.name or target.label
        or target.primary or target.concept
end

local function actorIDFor(request)
    local actor = request and request.actor
    if type(actor) ~= "table" then return nil end
    return text(actor.id or actor.entityID or actor.playerID)
end

local function matchesSpeakerID(targetID, request)
    targetID = normalizedTargetPhrase(targetID)
    if targetID == "player" then return true end
    local actorID = normalizedTargetPhrase(actorIDFor(request))
    return actorID ~= "" and targetID == actorID
end

local function isSpeakerTarget(target, request)
    if target == nil then return true end

    local phrase = normalizedTargetPhrase(targetText(target))
    local speakerPhrases = {
        me = true,
        myself = true,
        player = true,
        ["the player"] = true,
    }
    local kind = ""
    local targetID
    if type(target) == "table" then
        kind = normalized(target.kind or target.type
            or target.entityType or target.entity_type or target.targetKind)
        targetID = target.id or target.entityID or target.entityId
            or target.targetID or target.playerID
    elseif type(target) ~= "string" and type(target) ~= "number" then
        return false
    end

    if kind ~= "" and kind ~= "PLAYER" and kind ~= "PHRASE" then
        return false
    end
    if targetID ~= nil and not matchesSpeakerID(targetID, request) then
        return false
    end
    if phrase ~= "" then return speakerPhrases[phrase] == true end
    if targetID ~= nil then return true end
    return kind == "PLAYER"
end

local function hasUnsupportedFetchDestination(request)
    local target = request.target
    local destination = request.destination
    if target ~= nil and not isSpeakerTarget(target, request) then return true end
    if destination ~= nil
        and not isSpeakerTarget(destination, request)
    then
        return true
    end
    if target == nil and destination == nil then
        -- Do not default an uncaptured explicit destination to the speaker.
        return containsToken(request.rawText, "to")
            or containsToken(request.normalizedText, "to")
    end
    return false
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
    local taskAction = normalized(request.action)
    local planAction = taskAction == "FETCH" and "fetch" or "give"
    if not npcID then return nil, "npc_required" end
    if not object then return nil, objectReason end
    requestID = requestIDFor(request, npcID)
    return {
        planID = "semantic:" .. planAction .. ":" .. safePart(npcID)
            .. ":" .. safePart(requestID),
        npcID = npcID,
        requestID = requestID,
        source = request.source or "semantic_dialogue",
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = request.provenance,
        metadata = {
            taskAction = taskAction,
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
    local action = normalized(request and request.action)
    if not request or request.intent ~= "REQUEST"
        or (action ~= "GIVE" and action ~= "FETCH")
    then
        return false, action == "FETCH"
            and "fetch_request_invalid" or "give_request_invalid"
    end
    if action == "FETCH" then
        if hasExplicitFetchSource(request) then
            return false, "fetch_source_unsupported"
        end
        if hasUnsupportedFetchDestination(request) then
            return false, "fetch_destination_unsupported"
        end
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
    for _, action in ipairs({ "GIVE", "FETCH" }) do
        Requests.RegisterHandler(action, Handler)
    end
end

return Handler
