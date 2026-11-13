-- Presentation and lifecycle for asynchronous semantic inventory answers.
-- The conversation session remains the queue/TTS authority; this spoke only
-- turns a bounded server projection into one queued NPC message.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
Input.Internal = Input.Internal or {}
local InventoryPending = require
    "PNC/ConvoEngine/Dialogue/Input_InventoryPending"
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local InventoryResponses = require
    "PNC/ConvoEngine/Dialogue/Input_InventoryResponses"
local InventoryContext = require
    "PNC/ConvoEngine/Dialogue/Input_InventoryContext"
local InventoryResultRouting = require
    "PNC/ConvoEngine/Dialogue/Input_InventoryResultRouting"
local InventoryPresentation = require
    "PNC/ConvoEngine/Dialogue/Input_InventoryPresentation"

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
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
    local view = InventoryResultRouting.ActiveView(payload)
    local pending = InventoryPending.Take(view, requestID)
    if not pending then
        InventoryResultRouting.CacheUnmatched(payload)
        return false, "inventory_query_not_active"
    end
    local response = InventoryResponses.ForResult(payload, pending)
    InventoryContext.Record(view, payload, response)
    return InventoryPresentation.QueueResult(
        view, payload, response, requestID)
end

return Input
