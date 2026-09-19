-- Project a bounded inventory answer into conversation-local item mentions.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Diagnostics = PNC.Semantics.SemanticDiagnostics

local InventoryContext = {}

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

function InventoryContext.Record(view, payload, response)
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

return InventoryContext
