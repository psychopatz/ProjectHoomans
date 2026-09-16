-- Server-authoritative, read-only inventory answers for semantic dialogue.
--
-- This service intentionally does not share the transfer/task path.  A
-- question can inspect the compact authoritative inventory, but it cannot
-- reserve, remove, or give an item merely by being parsed.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Contract = PNC.Semantics.InventoryQuery
    or require "PNC/Semantics/PNC_SemanticInventoryQuery"
local Selector = PNC.Semantics.ItemSelector
    or require "PNC/Semantics/Inventory/PNC_SemanticItemSelector"
local Service = PNC.Semantics.InventoryQueryService or {}
PNC.Semantics.InventoryQueryService = Service

Service.VERSION = 1
Service.MAX_ITEMS = 256
Service.MAX_RESULTS = 12

local function text(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 128
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function lower(value)
    return string.lower(text(value, 128))
end

local function normalized(value)
    return string.lower(text(value, 64))
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
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

local function sortedItemIDs(items)
    local ids = {}
    for id in pairs(items or {}) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
    return ids
end

local function inventoryFor(record)
    if record and type(record.inventory) == "table" then
        return record.inventory
    end
    if PNC.Inventory
        and type(PNC.Inventory.EnsureRecordInventory) == "function"
    then
        return PNC.Inventory.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        })
    end
    return nil
end

local function itemType(item)
    local internal = Selector and Selector.Internal
    if internal and type(internal.ItemType) == "function" then
        return tostring(internal.ItemType(item) or "")
    end
    return tostring(item and (item.type or item.fullType) or "")
end

local function queryTags(query)
    query = type(query) == "table" and query or {}
    if query.concept and Selector
        and type(Selector.TagsForConcept) == "function"
    then
        local mapped = Selector.TagsForConcept(query.concept)
        if mapped then return mapped end
    end
    local concept = string.upper(tostring(query.concept
        or query.category or ""))
    if type(query.tags) == "table" and #query.tags > 0 then
        local output = {}
        for index = 1, math.min(#query.tags, 8) do
            output[#output + 1] = normalized(query.tags[index])
        end
        return output
    end
    return {}
end

local function itemLabel(item, fullType)
    local label = item and (item.customName or item.displayName)
    if not label and item and type(item.itemState) == "table" then
        label = item.itemState.customName or item.itemState.displayName
    end
    label = text(label, 96)
    if label == "" then label = fullType end
    return label
end

local function traceQuery(record, query, status, reason, result, options)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if not trace or type(trace.IsEnabled) ~= "function"
        or trace.IsEnabled() ~= true
        or type(trace.Record) ~= "function"
    then
        return result, reason
    end
    query = type(query) == "table" and query or {}
    trace.Record({
        source = "ProjectHoomans.Semantics",
        event = "semantic.inventory.query",
        requestID = options and options.requestID or query.requestID,
        data = {
            npcID = record and (record.id or record.npcID),
            status = status,
            reason = reason,
            mode = query.mode,
            text = text(query.text, 96),
            concept = text(query.concept, 64),
            category = text(query.category, 64),
            totalCount = result and result.totalCount or 0,
            distinctItems = result and result.distinctItems or 0,
            inventoryRevision = result and result.inventoryRevision,
        },
    })
    return result, reason
end

local function textMatches(item, queryText, fullType)
    queryText = lower(queryText)
    if queryText == "" then return false end
    local label = lower(itemLabel(item, fullType))
    local typeText = lower(fullType)
    return string.find(label, queryText, 1, true) ~= nil
        or string.find(typeText, queryText, 1, true) ~= nil
end

local function compactClassification(details)
    if type(details) ~= "table" then return nil end
    local output = {
        primary = text(details.primary, 64),
        category = text(details.category, 64),
        tags = {},
    }
    for tag in pairs(details.tags or {}) do
        if #output.tags >= 16 then break end
        output.tags[#output.tags + 1] = text(tag, 64)
    end
    table.sort(output.tags)
    return output
end

function Service.Query(record, query, options)
    options = type(options) == "table" and options or {}
    query = type(query) == "table" and query or {}
    local inventory = inventoryFor(record)
    local items = inventory and inventory.items or nil
    if type(items) ~= "table" then
        return traceQuery(record, query, "failed", "inventory_unavailable",
            nil, options)
    end

    local tags = queryTags(query)
    local queryText = query.text
    local ids = sortedItemIDs(items)
    local limit = math.max(1, math.min(Service.MAX_ITEMS, math.floor(
        tonumber(options.maxItems) or Service.MAX_ITEMS)))
    local candidates = {}
    local classificationReason
    local index
    for index = 1, math.min(#ids, limit) do
        local item = items[ids[index]]
        if item and item.interactionLocked ~= true then
            local fullType = itemType(item)
            local matched = false
            local details
            local reason
            local score = 0
            if #tags > 0 then
                matched, reason, details = Selector.Matches(item, {
                    tags = tags,
                })
                if matched then
                    score = (Selector.Internal.Score
                        and Selector.Internal.Score(item, { tags = tags }, details)
                        or (#tags * 20))
                elseif reason == "classification_unavailable"
                    or reason == "classification_failed"
                then
                    classificationReason = reason
                end
            elseif queryText then
                matched = Selector.Internal
                    and Selector.Internal.TextMatches
                    and Selector.Internal.TextMatches(item, queryText,
                        fullType)
                    or textMatches(item, queryText, fullType)
                reason = matched and "text_matched" or "item_text_mismatch"
            end
            if matched then
                candidates[#candidates + 1] = {
                    itemID = tostring(item.id or ids[index]),
                    fullType = fullType,
                    displayName = itemLabel(item, fullType),
                    quantity = math.max(1, math.floor(
                        tonumber(item.stack) or 1)),
                    score = score,
                    classification = compactClassification(details),
                }
            end
        end
    end

    if #candidates < 1 then
        if classificationReason then
            return traceQuery(record, query, "failed", classificationReason,
                nil, options)
        end
        return traceQuery(record, query, "empty", "empty", {
            status = "empty",
            items = {},
            totalCount = 0,
            distinctItems = 0,
        }, options)
    end

    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.fullType ~= right.fullType then
            return left.fullType < right.fullType
        end
        return left.itemID < right.itemID
    end)

    local totalCount = 0
    for index = 1, #candidates do
        totalCount = totalCount + candidates[index].quantity
    end
    local resultItems = {}
    for index = 1, math.min(#candidates, Service.MAX_RESULTS) do
        resultItems[index] = candidates[index]
    end
    return traceQuery(record, query, "found", "found", {
        status = "found",
        items = resultItems,
        totalCount = totalCount,
        distinctItems = #candidates,
        inventoryRevision = inventory.revision,
    }, options)
end

local function authority()
    return not PNC.Core or not PNC.Core.IsAuthority
        or PNC.Core.IsAuthority() == true
end

local function recordFor(request, context)
    local npcID = tostring(context.npcID or request.npcID or "")
    if npcID == "" then return nil, "npc_required" end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    if record.alive == false then return nil, "npc_unavailable" end
    return record
end

local function authorize(request, context, record)
    context = type(context) == "table" and context or {}
    if context.internal == true or not context.player then
        return true, "server_owned"
    end
    local token = tostring(context.conversationToken
        or request.conversationToken or "")
    if token == "" then return false, "conversation_token_required" end
    local authorityAPI = PNC.Conversation
        and PNC.Conversation.Authority
    local internal = authorityAPI and authorityAPI.Internal
    if not internal or type(internal.ValidateLease) ~= "function" then
        return false, "conversation_authority_unavailable"
    end
    return internal.ValidateLease(context.player, record, token)
end

local function resultPayload(request, status, reason, result)
    result = type(result) == "table" and result or {}
    request = type(request) == "table" and request or {}
    return {
        accepted = status == "found" or status == "empty",
        status = status,
        reason = reason,
        requestID = request and request.requestID,
        npcID = request and request.npcID,
        conversationID = request and request.conversationID,
        query = copyValue(request and request.query),
        items = copyValue(result.items) or {},
        totalCount = tonumber(result.totalCount) or 0,
        distinctItems = tonumber(result.distinctItems) or 0,
        inventoryRevision = result.inventoryRevision,
    }
end

function Service.HandleRequest(raw, context)
    context = type(context) == "table" and context or {}
    local request, reason = Contract.Normalize(raw)
    local record
    local authorized
    local result
    local status
    if not authority() then
        return resultPayload(raw, "failed", "server_authority_required")
    end
    if not request then return resultPayload(raw, "failed", reason) end
    context.npcID = context.npcID or request.npcID
    request.npcID = request.npcID or tostring(context.npcID or "")
    record, reason = recordFor(request, context)
    if not record then return resultPayload(request, "failed", reason) end
    authorized, reason = authorize(request, context, record)
    if authorized ~= true then
        return resultPayload(request, "failed", reason or "query_unauthorized")
    end
    result, reason = Service.Query(record, request.query, context)
    status = result and result.status or "failed"
    local payload = resultPayload(request, status, reason, result)
    if context.network == true and context.player and sendServerCommand then
        sendServerCommand(
            context.player,
            PNC.Const.MODULE,
            PNC.Const.CMD_SEMANTIC_INVENTORY_QUERY_RESULT,
            payload
        )
    end
    return payload
end

return Service
