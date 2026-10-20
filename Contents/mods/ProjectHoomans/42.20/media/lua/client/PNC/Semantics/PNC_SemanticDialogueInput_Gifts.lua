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

-- Public metadata for the existing multi-stage gift route. The lifecycle,
-- inventory selector, and authoritative transfer remain the owners; this is
-- discovery/trace data, not a second gift dispatcher.
local GiftCapability = {
    capabilityID = "pnc:gift.offer",
    owner = "PNC.Semantics.GiftLifecycle",
    route = "existing_inventory_transfer",
    workflowKind = "multi_stage_gift",
    templateVersion = 1,
    contractVersion = 1,
    targetScope = "single_recipient",
    handlerID = "PNC.Client.SendInventoryTransfer",
    arguments = {
        npcID = "recipient_target",
        itemIDs = "resolved_inventory_selection",
        quantity = "bounded",
        inventoryRevision = "target_revision",
        conversationToken = "authority_lease",
    },
    requires = {
        "conversation_or_gift_authority",
        "resolved_inventory_selection",
        "target_inventory_revision",
    },
    result = {
        "requested",
        "pending",
        "rejected",
        "applied",
        "completed",
    },
    triggerFrames = {
        { intent = "OFFER", speechAct = "OFFER", action = "GIFT" },
        { intent = "OFFER", action = "GIFT" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            source = "npcID",
            owner = "dialogue_context",
        },
        object = {
            type = "item",
            source = "object",
            owner = "semantic_ir",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:gift.offer",
        requiresAuthority = true,
    },
    outcomeMapping = {
        requested = "pending",
        pending = "pending",
        gift_transfer_pending = "pending",
        gift_selector_open = "selection_required",
        gift_selector_unavailable = "selection_required",
        selection_required = "selection_required",
        gift_item_not_found = "rejected",
        gift_transfer_unavailable = "failed",
        rejected = "rejected",
        applied = "completed",
        completed = "completed",
        gift_transferred = "completed",
        failed = "failed",
    },
    responsePools = {
        selection_required = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiftSelectionRequired",
            en = "I need to see what you brought me first.",
            tl = "Kailangan ko munang makita ang dala mo.",
        },
        pending = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiftPending",
            en = "I'll take a look at that gift.",
            tl = "Titingnan ko ang regalong iyan.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiftCompleted",
            en = "Thank you for the gift.",
            tl = "Salamat sa regalo.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiftRejected",
            en = "I can't accept that gift right now.",
            tl = "Hindi ko matanggap ang regalong iyan ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiftFailed",
            en = "I couldn't accept that gift.",
            tl = "Hindi ko matanggap ang regalong iyan.",
        },
    },
    translationOwner = "ProjectHoomans",
}
PNC.Semantics.GiftCapability = GiftCapability

local function targetInventoryRevision(npcID)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local payload = state and state.characterPayloads
        and state.characterPayloads[tostring(npcID or "")] or nil
    local inventory = payload and payload.inventory or nil
    return tonumber(inventory and (inventory.revision
        or inventory.summary and inventory.summary.revision)) or 0
end

local function findGiftSelection(view, offer, context, options)
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
    local selection, reason, details = GiftSelection.Find(
        player, offer, options)
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
            generatedFlow = context.generatedFlow,
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

local function sendGiftTransfer(
    session, context, selection, requestID, medicalSupplyRequest
)
    local client = PNC.Client
    local transferRequest = {
        id = context.npcID,
        direction = "player_to_npc",
        itemIDs = selection.itemIDs,
        quantity = selection.quantity,
        inventoryRevision = targetInventoryRevision(context.npcID),
        npcContainer = "root",
        gift = true,
        conversationToken = context.conversationToken,
        requestId = requestID,
        medicalSupplyTaskID = medicalSupplyRequest
            and medicalSupplyRequest.taskID or nil,
        medicalSupplyRequestID = medicalSupplyRequest
            and medicalSupplyRequest.requestID or nil,
    }
    local sent = client and type(client.SendInventoryTransfer) == "function"
        and client.SendInventoryTransfer(transferRequest) == true
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
        action = "GIFT",
        binding = GiftCapability,
        capabilityID = GiftCapability.capabilityID,
        handlerID = GiftCapability.handlerID,
        request = transferRequest,
        selection = selection,
    }
end

function Internal.DispatchGiftOffer(view, result, value)
    local decision = result and result.decision or {}
    local offer = decision.giftOffer
    local contextualSupplyRequest
    if type(offer) ~= "table" or type(actionContext) ~= "function" then
        return nil
    end
    local context = actionContext(view, result, value)
    context.generatedFlow = result and result.flow or nil
    if offer.marker
        and offer.marker.requiresActiveMedicalSupply == true
    then
        contextualSupplyRequest = context.activeMedicalSupplyRequest
        if not contextualSupplyRequest
            or not contextualSupplyRequest.taskID
            or not contextualSupplyRequest.requestID
        then
            return {
                status = "medical_supply_request_inactive",
                accepted = false,
                reason = "medical_supply_request_inactive",
                response = giftResponse(
                    "semantic.gift.not_found",
                    "I couldn't find that in your hands."
                ),
            }
        end
        local contextualOffer = {}
        for key, offerValue in pairs(offer) do
            contextualOffer[key] = offerValue
        end
        contextualOffer.query = contextualSupplyRequest.itemQuery or "bandage"
        contextualOffer.quantity = 1
        contextualOffer.object = {
            category = "medical_supply",
            concept = "BANDAGE",
            text = contextualOffer.query,
            value = contextualOffer.query,
            unresolved = true,
            quantity = 1,
        }
        offer = contextualOffer
    end
    if offer.mode == "selection" then
        return openGiftSelector(view, offer, context,
            "gift_item_selection_required")
    end
    local selection, selectionResult = findGiftSelection(
        view, offer, context,
        contextualSupplyRequest and { margin = -1 } or nil)
    if not selection then return selectionResult end
    if contextualSupplyRequest then
        local firstItemID = selection.itemIDs
            and selection.itemIDs[1] or nil
        if not firstItemID then
            return {
                status = "gift_item_not_found",
                accepted = false,
                reason = "gift_item_not_found",
                response = giftResponse(
                    "semantic.gift.not_found",
                    "I couldn't find that in your hands."
                ),
            }
        end
        selection.query = contextualSupplyRequest.itemQuery or "bandage"
        selection.itemIDs = { firstItemID }
        selection.quantity = 1
        selection.requestedQuantity = 1
    end

    local session = view and view.session
    local requestID = "semantic-gift:" .. tostring(context.npcID or "npc")
        .. ":" .. tostring(context.requestID or "request")
    local begun, beginResult = beginGiftRequest(
        session, value, context, selection, requestID)
    if not begun then return beginResult end
    return sendGiftTransfer(
        session, context, selection, requestID, contextualSupplyRequest)
end

function Internal.DispatchGiftConsent(view, result, value)
    local decision = result and result.decision or {}
    local consent = decision.giftConsent
    if type(consent) ~= "table" or consent.status ~= "granted"
        or type(consent.offer) ~= "table"
    then
        return nil
    end

    local group = view and view.groupConversation or nil
    if consent.groupID ~= nil
        and (not group or group.closed == true
            or tostring(group.id or "")
            ~= tostring(consent.groupID))
    then
        return {
            status = "gift_consent_expired",
            accepted = false,
            reason = "gift_consent_group_changed",
            response = giftResponse(
                "semantic.gift.consent.expired",
                "That offer has gone stale. Ask me again if you still want it."
            ),
        }
    end

    local recipientID = tostring(consent.recipientID or "")
    if recipientID == "" then return nil end
    local targetView = view
    if group and type(group.ViewFor) == "function" then
        targetView = group:ViewFor(recipientID)
    elseif tostring(view and view.spec and view.spec.npcID or "")
        ~= recipientID
    then
        targetView = nil
    end
    if not targetView or not targetView.session
        or targetView.closed == true
        or tostring(targetView.spec and targetView.spec.npcID or "")
            ~= recipientID
    then
        return {
            status = "gift_consent_target_unavailable",
            accepted = false,
            reason = "gift_consent_recipient_unavailable",
            response = giftResponse(
                "semantic.gift.consent.target_missing",
                "I can't reach the person who asked for it right now."
            ),
        }
    end

    local giftResult = {
        sequence = result.sequence,
        ir = result.ir,
        decision = {
            route = "deterministic",
            branch = "GIFT_CONSENT_GRANTED",
            giftOffer = {
                mode = "explicit",
                query = consent.offer.query,
                quantity = consent.offer.quantity,
            },
        },
    }
    return Internal.DispatchGiftOffer(targetView, giftResult, value)
end

return Input
