-- Read-only semantic inventory query contract.
--
-- A query is deliberately separate from a task request: asking what an NPC
-- carries must never be interpreted as permission to transfer or mutate an
-- item.  The server owns the answer and returns only a bounded projection.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local Contract = PNC.Semantics.InventoryQuery or {}
PNC.Semantics.InventoryQuery = Contract

Contract.VERSION = 1
Contract.MAX_REQUEST_ID = 128
Contract.MAX_TEXT = 256
Contract.MAX_TAGS = 8

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
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

local function semanticID(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    return string.sub(value, 1, 64)
end

local function confidence(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function normalizeTags(value)
    local output = {}
    local source = type(value) == "table" and value or {}
    local index
    for index = 1, math.min(#source, Contract.MAX_TAGS) do
        local tag = boundedText(source[index], 48)
        if tag ~= "" then output[#output + 1] = tag end
    end
    return output
end

local function normalizeQuery(raw)
    raw = type(raw) == "table" and raw or {}
    local item = type(raw.item) == "table" and raw.item or {}
    local query = {
        mode = semanticID(raw.mode or "LIST"),
        text = boundedText(raw.text or item.text or item.value, 128),
        concept = semanticID(raw.concept or item.concept or item.category),
        category = semanticID(raw.category or item.category),
        tags = normalizeTags(raw.tags),
    }
    if query.mode == "" then query.mode = "LIST" end
    if query.concept == "" then query.concept = nil end
    if query.category == "" then query.category = nil end
    if query.text == "" then query.text = nil end
    if #query.tags == 0 then query.tags = nil end
    return query
end

function Contract.Validate(request)
    if type(request) ~= "table"
        or tonumber(request.schemaVersion) ~= Contract.VERSION
        or request.kind ~= "semantic_inventory_query"
    then
        return false, "invalid_inventory_query_schema"
    end
    if type(request.query) ~= "table" then
        return false, "inventory_query_required"
    end
    if not request.query.text
        and not request.query.concept
        and not request.query.category
        and not request.query.tags
    then
        return false, "inventory_query_value_required"
    end
    if request.requestID ~= nil and type(request.requestID) ~= "string" then
        return false, "inventory_query_id_invalid"
    end
    if type(request.rawText) ~= "string"
        or type(request.normalizedText) ~= "string"
    then
        return false, "inventory_query_text_invalid"
    end
    if type(request.confidence) ~= "number"
        or request.confidence < 0 or request.confidence > 1
    then
        return false, "inventory_query_confidence_invalid"
    end
    return true, request
end

function Contract.Normalize(raw)
    if type(raw) ~= "table" then return nil, "inventory_query_required" end
    local request = {
        schemaVersion = Contract.VERSION,
        kind = "semantic_inventory_query",
        requestID = raw.requestID ~= nil
            and boundedText(raw.requestID, Contract.MAX_REQUEST_ID) or nil,
        source = boundedText(raw.source or "semantic_dialogue", 64),
        npcID = boundedText(raw.npcID, 128),
        conversationID = boundedText(raw.conversationID, 128),
        conversationToken = boundedText(
            raw.conversationToken or raw.token, 128),
        confidence = confidence(raw.confidence),
        rawText = boundedText(raw.rawText or raw.text),
        normalizedText = boundedText(raw.normalizedText),
        query = normalizeQuery(raw.query or raw.inventoryQuery),
        provenance = copyValue(raw.provenance) or {},
    }
    if request.npcID == "" then request.npcID = nil end
    if request.conversationID == "" then request.conversationID = nil end
    if request.conversationToken == "" then request.conversationToken = nil end
    if request.normalizedText == "" then request.normalizedText = request.rawText end
    local valid, reason = Contract.Validate(request)
    if not valid then return nil, reason end
    return request
end

function Contract.FromIR(ir, context)
    context = type(context) == "table" and context or {}
    local valid, reason = IR.Validate(ir)
    if valid ~= true then return nil, reason or "invalid_semantic_ir" end
    if ir.intent ~= "QUESTION" or ir.subject ~= "INVENTORY" then
        return nil, "inventory_query_requires_inventory_question"
    end
    return Contract.Normalize({
        requestID = context.requestID or context.requestId,
        source = context.source or "semantic_dialogue",
        npcID = context.npcID or context.targetID,
        conversationID = context.conversationID,
        conversationToken = context.conversationToken or context.token,
        confidence = ir.confidence,
        rawText = context.rawText or ir.rawText,
        normalizedText = ir.normalizedText,
        query = ir.inventoryQuery,
        provenance = ir.provenance,
    })
end

return Contract
