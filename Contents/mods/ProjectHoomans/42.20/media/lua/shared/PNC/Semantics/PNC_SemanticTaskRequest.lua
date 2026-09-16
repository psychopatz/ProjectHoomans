-- Stable, side-effect-free contract for semantic requests that may become
-- tasks. Domain services own admission, persistence, scheduling, and effects.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local Contract = PNC.Semantics.TaskRequest or {}
PNC.Semantics.TaskRequest = Contract

Contract.VERSION = 1
Contract.MAX_REQUEST_ID = 128
Contract.MAX_TEXT = 4096
Contract.MAX_TARGET_HINT_TEXT = 64
Contract.MAX_TARGET_HINT_DISTANCE = 32

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 10 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Contract.MAX_TEXT
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function actionID(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    return value
end

local function confidence(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function tableOrNil(value)
    return type(value) == "table" and copyValue(value) or nil
end

local function finiteCoordinate(value)
    value = tonumber(value)
    if value == nil or value ~= value or math.abs(value) > 1000000 then
        return nil
    end
    return value
end

-- Client world observations are hints, not assignments.  Normalize them into
-- a tiny primitive shape before the request can cross a multiplayer boundary.
-- Invalid hints are ignored so the authoritative resolver can use its normal
-- server-side lookup path instead of turning a stale client observation into
-- a hard failure.
local function targetHint(value)
    if type(value) ~= "table" then return nil end
    local x = finiteCoordinate(value.x)
    local y = finiteCoordinate(value.y)
    if x == nil or y == nil then return nil end
    local z = finiteCoordinate(value.z) or 0
    local radius = tonumber(value.radius) or 16
    local score = confidence(value.score)
    return {
        version = tonumber(value.version) or 1,
        source = boundedText(value.source or "client_loaded_world", 32),
        kind = boundedText(value.kind, 64),
        scope = boundedText(value.scope or value.siteScope, 16),
        siteScope = boundedText(value.siteScope or value.scope, 16),
        siteID = boundedText(value.siteID, 128),
        roomID = boundedText(value.roomID, 128),
        buildingID = boundedText(value.buildingID, 128),
        roomType = boundedText(value.roomType, 48),
        campfireID = boundedText(value.campfireID, 128),
        label = boundedText(value.label, Contract.MAX_TARGET_HINT_TEXT),
        labelKey = boundedText(value.labelKey, 96),
        risk = boundedText(value.risk, 32),
        query = boundedText(value.query, Contract.MAX_TARGET_HINT_TEXT),
        x = x,
        y = y,
        z = z,
        minX = finiteCoordinate(value.minX),
        minY = finiteCoordinate(value.minY),
        maxX = finiteCoordinate(value.maxX),
        maxY = finiteCoordinate(value.maxY),
        minZ = finiteCoordinate(value.minZ),
        maxZ = finiteCoordinate(value.maxZ),
        radius = math.max(1, math.min(Contract.MAX_TARGET_HINT_DISTANCE,
            math.floor(radius))),
        score = score,
        observedAt = tonumber(value.observedAt),
    }
end

local function targetTable(value)
    local output = tableOrNil(value)
    if not output then return nil end
    if type(value.clientHint) == "table" then
        output.clientHint = targetHint(value.clientHint)
    else
        output.clientHint = nil
    end
    return output
end

function Contract.Validate(request)
    if type(request) ~= "table"
        or tonumber(request.schemaVersion) ~= Contract.VERSION
        or request.kind ~= "semantic_task_request"
    then
        return false, "invalid_task_request_schema"
    end
    if type(request.action) ~= "string" or request.action == "" then
        return false, "task_action_required"
    end
    if request.intent ~= "REQUEST" then
        return false, "task_request_requires_request_intent"
    end
    if request.intent ~= nil and type(request.intent) ~= "string" then
        return false, "task_intent_invalid"
    end
    if request.requestID ~= nil and type(request.requestID) ~= "string" then
        return false, "task_request_id_invalid"
    end
    if type(request.rawText) ~= "string"
        or type(request.normalizedText) ~= "string"
    then
        return false, "task_text_invalid"
    end
    if type(request.confidence) ~= "number"
        or request.confidence < 0 or request.confidence > 1
    then
        return false, "task_confidence_invalid"
    end
    return true, request
end

function Contract.Normalize(raw)
    if type(raw) ~= "table" then return nil, "task_request_required" end

    local request = {
        schemaVersion = Contract.VERSION,
        kind = "semantic_task_request",
        requestID = raw.requestID ~= nil
            and boundedText(raw.requestID, Contract.MAX_REQUEST_ID) or nil,
        source = boundedText(raw.source or "semantic_dialogue", 64),
        intent = raw.intent and actionID(raw.intent) or nil,
        speechAct = raw.speechAct and actionID(raw.speechAct) or nil,
        action = actionID(raw.action),
        actor = tableOrNil(raw.actor),
        recipient = tableOrNil(raw.recipient),
        target = targetTable(raw.target),
        object = tableOrNil(raw.object),
        sourceEntity = tableOrNil(raw.sourceEntity or raw.sourceRef),
        destination = tableOrNil(raw.destination),
        modifiers = tableOrNil(raw.modifiers) or {},
        confidence = confidence(raw.confidence),
        rawText = boundedText(raw.rawText or raw.text),
        normalizedText = boundedText(raw.normalizedText),
        provenance = tableOrNil(raw.provenance) or {},
        extensions = tableOrNil(raw.extensions),
    }

    if request.intent == "" then request.intent = nil end
    if request.speechAct == "" then request.speechAct = nil end
    if request.source == "" then request.source = "semantic_dialogue" end
    if request.normalizedText == "" then request.normalizedText = request.rawText end

    local valid, reason = Contract.Validate(request)
    if not valid then return nil, reason end
    return request
end

function Contract.FromIR(ir, context)
    context = type(context) == "table" and context or {}
    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        return nil, validationReason or "invalid_semantic_ir"
    end
    if tostring(ir.intent or ir.speechAct or "") ~= "REQUEST" then
        return nil, "task_request_requires_request_intent"
    end
    return Contract.Normalize({
        requestID = context.requestID or context.requestId,
        source = context.source or "semantic_dialogue",
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        actor = ir.actor or context.actor,
        recipient = ir.recipient or context.recipient,
        target = ir.target,
        object = ir.object,
        sourceEntity = ir.source,
        destination = ir.destination,
        modifiers = ir.modifiers,
        confidence = ir.confidence,
        rawText = context.rawText or ir.rawText,
        normalizedText = ir.normalizedText,
        provenance = ir.provenance,
        extensions = ir.extensions,
    })
end

function Contract.FromActionIntent(actionIntent, context)
    context = type(context) == "table" and context or {}
    if type(actionIntent) ~= "table" then
        return nil, "invalid_action_intent"
    end
    return Contract.FromIR(IR.New({
        rawText = context.rawText,
        normalizedText = context.normalizedText,
        intent = actionIntent.intent or "REQUEST",
        speechAct = actionIntent.speechAct or actionIntent.intent or "REQUEST",
        action = actionIntent.action,
        actor = actionIntent.actor,
        recipient = actionIntent.recipient,
        target = actionIntent.target,
        object = actionIntent.object,
        source = actionIntent.source,
        destination = actionIntent.destination,
        modifiers = actionIntent.modifiers,
        confidence = actionIntent.confidence,
        provenance = actionIntent.provenance,
    }), context)
end

return Contract
