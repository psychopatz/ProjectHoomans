-- Gift-specific semantic action boundary.
-- The central action router delegates here; item selection remains client
-- convenience, while the existing inventory transport remains authoritative.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticGiftSelection"
require "PNC/Semantics/PNC_SemanticGiftLifecycle"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local GiftSelection = PNC.Semantics.GiftSelection
local GiftLifecycle = PNC.Semantics.GiftLifecycle
local audit = Internal.Audit or function() return false end
local actionContext = Internal.ActionContext
local giftResponse = Internal.GiftResponse
local openGiftSelector = Internal.OpenGiftSelector

local function targetInventoryRevision(npcID)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local payload = state and state.characterPayloads
        and state.characterPayloads[tostring(npcID or "")] or nil
    local inventory = payload and payload.inventory or nil
    return tonumber(inventory and (inventory.revision
        or inventory.summary and inventory.summary.revision)) or 0
end

local function findGiftSelection(view, offer, context)
    if not GiftSelection or type(GiftSelection.Find) ~= "function" then
        return nil, {
            status = "gift_selector_unavailable",
            accepted = false,
            reason = "gift_matcher_unavailable",
            response = giftResponse(
                "semantic.gift.not_found", "I couldn't find that in your hands."
            ),
        }
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local selection, reason, details = GiftSelection.Find(player, offer)
    if selection then return selection end
    if reason == "gift_item_ambiguous" then
        return nil, openGiftSelector(view, offer, context, reason)
    end
    audit("semantic.gift.match_failed", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = context.requestID,
        query = offer.query,
        reason = reason,
        details = details,
    }, { requestID = context.requestID })
    return nil, {
        status = reason or "gift_item_not_found",
        accepted = false,
        reason = reason,
        response = giftResponse(
            "semantic.gift.not_found",
            "I couldn't find that in your hands.",
            { query = offer.query }
        ),
    }
end

local function beginGiftRequest(session, value, context, selection, requestID)
    if not session then return true end
    local active = GiftLifecycle and GiftLifecycle.Active
        and GiftLifecycle.Active(session, context.npcID) or nil
    if active then
        audit("semantic.gift.request_rejected", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = requestID,
            reason = "gift_request_active",
            activeRequestID = active.requestID,
        }, { requestID = requestID })
        return false, {
            status = "gift_request_busy",
            accepted = false,
            reason = "gift_request_active",
            response = giftResponse(
                "semantic.gift.busy",
                "I'm still processing the last gift."
            ),
        }
    end
    local begun
    local beginReason
    if GiftLifecycle and type(GiftLifecycle.Begin) == "function" then
        begun, beginReason = GiftLifecycle.Begin(session, requestID, {
            mode = "auto",
            rawText = value,
            query = selection.query,
            itemIDs = selection.itemIDs,
            selection = selection,
            npcID = context.npcID,
            conversationID = context.conversationID,
        })
    else
        begun, beginReason = false, "gift_lifecycle_unavailable"
    end
    if not begun then
        audit("semantic.gift.request_rejected", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = requestID,
            reason = beginReason,
        }, { requestID = requestID })
        return false, {
            status = "gift_request_busy",
            accepted = false,
            reason = beginReason,
            response = giftResponse(
                "semantic.gift.busy",
                "I'm still processing the last gift."
            ),
        }
    end
    return true
end

local function sendGiftTransfer(session, context, selection, requestID)
    local client = PNC.Client
    local sent = client and type(client.SendInventoryTransfer) == "function"
        and client.SendInventoryTransfer({
            id = context.npcID,
            direction = "player_to_npc",
            itemIDs = selection.itemIDs,
            quantity = selection.quantity,
            inventoryRevision = targetInventoryRevision(context.npcID),
            npcContainer = "root",
            gift = true,
            conversationToken = context.conversationToken,
            requestId = requestID,
        }) == true
    if not sent then
        if session and GiftLifecycle and GiftLifecycle.Clear then
            GiftLifecycle.Clear(session, requestID)
        end
        return {
            status = "gift_transfer_unavailable",
            accepted = false,
            reason = "inventory_transfer_unavailable",
            response = giftResponse(
                "semantic.gift.not_found",
                "I couldn't get that gift through right now."
            ),
        }
    end
    audit("semantic.gift.transfer_requested", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = requestID,
        query = selection.query,
        fullType = selection.fullType,
        quantity = selection.quantity,
        score = selection.score,
        matchField = selection.matchField,
    }, { requestID = requestID })
    return {
        status = "gift_transfer_pending",
        accepted = true,
        pending = true,
        requestID = requestID,
        selection = selection,
    }
end

function Internal.DispatchGiftOffer(view, result, value)
    local decision = result and result.decision or {}
    local offer = decision.giftOffer
    if type(offer) ~= "table" or type(actionContext) ~= "function" then
        return nil
    end
    local context = actionContext(view, result, value)
    if offer.mode == "selection" then
        return openGiftSelector(view, offer, context,
            "gift_item_selection_required")
    end
    local selection, selectionResult = findGiftSelection(view, offer, context)
    if not selection then return selectionResult end

    local session = view and view.session
    local requestID = "semantic-gift:" .. tostring(context.npcID or "npc")
        .. ":" .. tostring(context.requestID or "request")
    local begun, beginResult = beginGiftRequest(
        session, value, context, selection, requestID)
    if not begun then return beginResult end
    return sendGiftTransfer(session, context, selection, requestID)
end

return Input
