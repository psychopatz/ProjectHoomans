-- Presentation and lifecycle for asynchronous semantic inventory answers.
-- The conversation session remains the queue/TTS authority; this spoke only
-- turns a bounded server projection into one queued NPC message.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local Diagnostics = PNC.Semantics.SemanticDiagnostics

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function recordInventoryContext(view, payload, response)
    local internal = Input.Internal
    if not internal or type(internal.RecordContextTurn) ~= "function" then
        return false, "context_recorder_unavailable"
    end
    payload = type(payload) == "table" and payload or {}
    response = type(response) == "table" and response or {}
    local query = type(payload.query) == "table" and payload.query or {}
    local items = type(payload.items) == "table" and payload.items or {}
    local mentions = {}
    local index
    local item
    local classification
    for index = 1, math.min(#items, 12) do
        item = type(items[index]) == "table" and items[index] or {}
        classification = type(item.classification) == "table"
            and item.classification or nil
        mentions[#mentions + 1] = {
            id = item.itemID,
            itemID = item.itemID,
            entityType = "item",
            concept = query.concept or classification and classification.category,
            category = query.category or classification and classification.category,
            text = item.displayName or item.fullType,
            quantity = item.quantity,
            tags = classification and classification.tags,
            capabilities = classification and classification.capabilities,
            semanticCapabilities = classification
                and classification.semanticCapabilities,
            marketRole = classification and classification.marketRole,
            marketSenseTags = classification
                and classification.marketSenseTags,
            classification = classification,
            source = "server_inventory_projection",
        }
    end
    local recorded, event = internal.RecordContextTurn(view, {
        rawText = response.fallback,
        normalizedText = response.fallback,
        intent = "INFORM",
        speechAct = "INFORM",
        subject = "INVENTORY",
        confidence = payload.status == "found" and 0.95 or 0.80,
        extensions = { semanticMentions = mentions },
    }, {
        speaker = "npc",
        source = "inventory_query_response",
    })
    audit("semantic.context.inventory_recorded", {
        npcID = payload.npcID,
        requestID = payload.requestID,
        recorded = recorded == true,
        mentionCount = #mentions,
        contextSequence = view and view.session
            and view.session.semanticDialogueContext
            and view.session.semanticDialogueContext.sequence or nil,
        reason = type(event) == "string" and event or nil,
    }, { requestID = payload.requestID })
    return recorded, event
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
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

local function queryLabel(query)
    query = type(query) == "table" and query or {}
    local concept = string.upper(tostring(query.concept
        or query.category or ""))
    if concept == "SEAFOOD" then return "seafood" end
    if concept == "FOOD" then return "food" end
    if concept == "WATER" then return "water" end
    if concept == "MEDICINE" then return "medicine" end
    local value = tostring(query.text or query.category
        or query.concept or "that")
    return value ~= "" and value or "that"
end

local function itemLabel(item)
    item = type(item) == "table" and item or {}
    local label = tostring(item.displayName or item.customName
        or item.fullType or "item")
    local withoutModule = string.match(label, "^[^%.]+%.(.+)$")
    label = withoutModule or label
    label = string.gsub(label, "_", " ")
    return label
end

local function responseFor(payload, pending)
    payload = type(payload) == "table" and payload or {}
    local query = payload.query
        or pending and pending.query or {}
    local label = queryLabel(query)
    local status = tostring(payload.status or "failed")
    if status == "pending" then
        return {
            key = "semantic.inventory.query.pending",
            fallback = "Let me check what I have.",
            args = { query = label },
        }
    end
    if status == "found" then
        local items = type(payload.items) == "table"
            and payload.items or {}
        local names = {}
        for index = 1, math.min(#items, 4) do
            local item = items[index]
            local quantity = math.max(1, math.floor(
                tonumber(item and item.quantity) or 1))
            names[#names + 1] = itemLabel(item)
                .. " (" .. tostring(quantity) .. ")"
        end
        local more = math.max(0, (tonumber(payload.distinctItems) or 0)
            - #names)
        local suffix = table.concat(names, ", ")
        if more > 0 then
            suffix = suffix .. (suffix ~= "" and ", " or "")
                .. tostring(more) .. " more"
        end
        local count = tonumber(payload.totalCount) or 0
        local text = "I have " .. tostring(count) .. " " .. label
            .. (count == 1 and " item" or " items")
        if suffix ~= "" then text = text .. ": " .. suffix end
        return {
            key = "semantic.inventory.found",
            fallback = text .. ".",
            args = {
                query = label,
                totalCount = count,
                distinctItems = payload.distinctItems,
                items = copyValue(items),
            },
        }
    end
    if status == "empty" then
        return {
            key = "semantic.inventory.empty",
            fallback = "I don't have any " .. label .. ".",
            args = { query = label },
        }
    end
    return {
        key = "semantic.inventory.failed",
        fallback = "I can't check my inventory right now.",
        args = { query = label, reason = payload.reason },
    }
end

local function activeView(payload)
    local candidates = {}
    local active = Input.ActiveView
    if active then candidates[#candidates + 1] = active end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local visible = conversation and conversation.instance or nil
    if visible and visible ~= active then
        candidates[#candidates + 1] = visible
    end
    for index = 1, #candidates do
        local view = candidates[index]
        local session = view and view.session or nil
        if view and session and view.closed ~= true
            and view.lifecycleFinished ~= true
        then
            if not payload or not payload.npcID
                or tostring(view.spec and view.spec.npcID or "")
                    == tostring(payload.npcID)
            then
                return view
            end
        end
    end
    return nil
end

local function cacheResult(payload)
    local state = PNC.Network and PNC.Network.ClientState or nil
    if not state then return end
    state.semanticInventoryQueryResults =
        state.semanticInventoryQueryResults or {}
    state.semanticInventoryQueryResultOrder =
        state.semanticInventoryQueryResultOrder or {}
    local requestID = tostring(payload and payload.requestID or "")
    if requestID == "" then return end
    if state.semanticInventoryQueryResults[requestID] == nil then
        state.semanticInventoryQueryResultOrder[#state.semanticInventoryQueryResultOrder
            + 1] = requestID
    end
    state.semanticInventoryQueryResults[requestID] = copyValue(payload)
    while #state.semanticInventoryQueryResultOrder > 16 do
        local old = table.remove(state.semanticInventoryQueryResultOrder, 1)
        state.semanticInventoryQueryResults[old] = nil
    end
end

function Input.ReceiveInventoryQueryResult(payload)
    payload = type(payload) == "table" and payload or {}
    local requestID = tostring(payload.requestID or "")
    audit("semantic.inventory.response", {
        npcID = payload.npcID,
        conversationID = payload.conversationID,
        requestID = requestID,
        status = payload.status,
        accepted = payload.accepted == true,
        reason = payload.reason,
        query = payload.query,
        totalCount = payload.totalCount,
        distinctItems = payload.distinctItems,
        inventoryRevision = payload.inventoryRevision,
        items = payload.items,
    }, { requestID = requestID })
    local view = activeView(payload)
    local session = view and view.session or nil
    local pending = session and session.semanticInventoryQueries
        and session.semanticInventoryQueries[requestID] or nil
    if not pending then
        cacheResult(payload)
        return false, "inventory_query_not_active"
    end
    session.semanticInventoryQueries[requestID] = nil
    local response = responseFor(payload, pending)
    recordInventoryContext(view, payload, response)
    session:queueMessage("npc", response, {
        source = {
            kind = "semantic",
            channel = "inventory_query_response",
            requestID = requestID,
            status = payload.status,
            reason = payload.reason,
        },
        provenance = {
            provider = "server_inventory_projection",
            parser = "marketsense_item_selector",
            requestID = requestID,
        },
    })
    return true
end

return Input
