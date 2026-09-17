require "PNC/Semantics/PNC_SemanticGiftLifecycle"
require "PNC/Semantics/PNC_SemanticGiftContext"

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader
local Internal = Composer.Internal

local NEEDS_FALLBACK_SOURCE = Internal.NEEDS_FALLBACK_SOURCE
local GIFT_OFFER_KEYS = Internal.GIFT_OFFER_KEYS
local activeView = Internal.ActiveView
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local formatGiftOffer = Internal.FormatGiftOffer
local giftOfferKey = Internal.GiftOfferKey
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter
local resolvedDialogue = Internal.ResolvedDialogue
local GiftLifecycle = PNC.Semantics.GiftLifecycle
local GiftContext = PNC.Semantics.GiftContext

local PREFERENCE_REACTIONS = {
    favorite = {
        key = "semantic.gift.reaction.favorite",
        text = "You remembered exactly what I like. Thank you.",
    },
    liked = {
        key = "semantic.gift.reaction.liked",
        text = "This is a good one. Thank you.",
    },
    disliked = {
        key = "semantic.gift.reaction.disliked",
        text = "I appreciate the thought, but this isn't really my thing.",
    },
    hated = {
        key = "semantic.gift.reaction.hated",
        text = "Is this a joke? Why would you give me this?",
    },
}

local function giftReplyPayload(giftEffect, source, key, context, args)
    local disposition = giftEffect and tostring(giftEffect.disposition or "")
    local reaction = PREFERENCE_REACTIONS[disposition]
    if reaction then
        return {
            key = reaction.key,
            domain = "pnc.system.shared.categories",
            text = reaction.text,
            fallback = reaction.text,
            args = args,
        }
    end
    return dialoguePayload(source, key, context, args)
end

local function giftFailurePayload(reason)
    local value = string.lower(tostring(reason or ""))
    local fallback
    if string.find(value, "revision", 1, true) then
        fallback = "That gift is out of date. Try again."
    elseif string.find(value, "item", 1, true)
        or string.find(value, "inventory", 1, true)
    then
        fallback = "I couldn't take that gift."
    elseif string.find(value, "lease", 1, true)
        or string.find(value, "conversation", 1, true)
    then
        fallback = "I can't accept a gift right now."
    else
        fallback = "I couldn't take that gift right now."
    end
    return {
        key = "semantic.gift.failed",
        domain = "pnc.system.shared.categories",
        text = fallback,
        fallback = fallback,
        args = { reason = tostring(reason or "gift_failed") },
    }
end

function Composer.ReceiveGiftResult(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcId)
    if not view then return false end
    local rootContext = view.spec and view.spec.context or nil
    local context = rootContext and rootContext.conversationBlockContext
        or rootContext
    local session = view.session
    local requestID = tostring(args.requestId or "")
    if session and requestID ~= ""
        and GiftLifecycle and type(GiftLifecycle.IsHandled) == "function"
        and GiftLifecycle.IsHandled(session, requestID)
    then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("Conversation gift result ignored duplicate npc="
                .. tostring(args.npcId or "unknown") .. " request="
                .. requestID)
        end
        return true, "gift_result_duplicate"
    end
    local pending = session and GiftLifecycle
        and type(GiftLifecycle.Get) == "function"
        and GiftLifecycle.Get(session, requestID) or nil
    if not pending and session and session.semanticGiftRequests then
        -- Compatibility with a request created by an older hot-reloaded
        -- client before the lifecycle spoke was installed.
        pending = session.semanticGiftRequests[requestID]
    end
    local semanticAuto = pending and pending.mode == "auto"
    if session and requestID ~= "" and GiftLifecycle
        and type(GiftLifecycle.MarkHandled) == "function"
    then
        GiftLifecycle.MarkHandled(session, requestID)
    elseif pending and session and session.semanticGiftRequests then
        session.semanticGiftRequests[requestID] = nil
    end
    local state = PNC.Network and PNC.Network.ClientState
    if args.relationshipDelta and state then
        state.lastConversationDelta = {
            npcID = args.npcId,
            source = "gift",
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            effects = args.giftEffect,
            itemTypes = args.itemTypes,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        }
    end
    if args.success ~= true then
        if semanticAuto then
            if context then context.giftConversationActive = nil end
            if rootContext then rootContext.giftConversationActive = nil end
        end
        local failure = giftFailurePayload(args.reason)
        if session and type(session.append) == "function" then
            session:append("npc", failure, {
                source = {
                    kind = "semantic",
                    channel = "gift_result",
                    requestID = requestID,
                    reason = args.reason,
                },
                provenance = {
                    provider = "server",
                    parser = "authoritative_gift_transfer",
                    requestID = requestID,
                },
            })
        end
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation gift rejected npc="
                .. tostring(args.npcId or "unknown") .. " reason="
                .. tostring(args.reason or "unknown"))
        end
        return false, args.reason
    end
    if context then
        context.lastGift = {
            itemTypes = args.itemTypes,
            itemIDs = args.itemIDs,
            relationshipDelta = args.relationshipDelta,
            effect = args.giftEffect,
        }
        context.giftConversationActive = nil
    end
    if rootContext then rootContext.giftConversationActive = nil end
    if GiftContext and type(GiftContext.RecordTransfer) == "function" then
        local recorded, contextReason = GiftContext.RecordTransfer(
            view, args, pending)
        if not recorded and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation gift context not recorded npc="
                .. tostring(args.npcId or "unknown") .. " reason="
                .. tostring(contextReason or "unknown"))
        end
    end
    local offer = formatGiftOffer(args.itemTypes)
    local offerArgs = {
        giftItemName = offer.itemName,
        giftItemSummary = offer.itemSummary,
        giftItemCount = offer.count,
    }
    local offerKey = giftOfferKey(offer, args.itemTypes, context)
    local activeBlock = context and context.activeConversationBlockID
        and Registry.GetBlock(context.activeConversationBlockID) or nil
    local giftSource = activeBlock and activeBlock.textSource
        or NEEDS_FALLBACK_SOURCE
    local giftReplyKey = args.giftReplyKey
        or "gift.received." .. tostring(args.giftEffect
            and args.giftEffect.kind or "general")
    -- Use the authoritative after-state immediately, then request a full
    -- presentation as a persistence/network consistency check.
    receiveRelationshipAfter(
        args.npcId,
        args.relationshipAfter,
        args.relationshipDelta,
        {
            source = "gift",
            eventID = args.eventID,
            revision = args.relationshipAfter
                and args.relationshipAfter.revision,
        }
    )
    local relationship = Conversation.Relationship
    if relationship and relationship.RequestPresentation then
        -- The authoritative effect is committed before this callback. Refresh
        -- the live conversation panel so its marker and attitude use the same
        -- relationship snapshot that the debug laboratory displays.
        relationship.RequestPresentation(args.npcId)
    end
    if PNC.InventoryWindow and PNC.InventoryWindow.Close then
        PNC.InventoryWindow.Close()
    end
    if view.session and view.session.append then
        local requiredKeys = {}
        for _, key in ipairs(GIFT_OFFER_KEYS) do
            requiredKeys[#requiredKeys + 1] = key
        end
        requiredKeys[#requiredKeys + 1] = giftReplyKey
        Loader.EnsureSource(giftSource, requiredKeys)
        -- A selector gift has a separate spoken item-selection line. An
        -- explicit semantic gift already has its original line in the log;
        -- appending the synthetic selector line would duplicate it.
        if not semanticAuto then
            view.session:append("player", dialoguePayload(
                giftSource,
                offerKey,
                context,
                offerArgs
            ))
        end
        view.session:append("npc", giftReplyPayload(
            args.giftEffect,
            giftSource,
            giftReplyKey,
            context,
            offerArgs
        ))
    end
    appendDiary(args.npcId, {
        kind = "gift",
        blockID = context and context.activeConversationBlockID,
        choiceID = "gift",
        playerText = resolvedDialogue(dialoguePayload(
            giftSource,
            offerKey,
            context,
            offerArgs
        )),
        npcText = resolvedDialogue(giftReplyPayload(
            args.giftEffect,
            giftSource,
            giftReplyKey,
            context,
            offerArgs
        )),
        itemSummary = offer.itemSummary,
        itemTypes = args.itemTypes,
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("Conversation gift result npc="
            .. tostring(args.npcId or "unknown")
            .. " items=" .. tostring(#(args.itemTypes or {}))
            .. " reply=" .. tostring(giftReplyKey)
            .. " relationship_refresh="
            .. tostring(args.relationshipAfter ~= nil))
    end
    -- The authored gift node is already the next node of the conversation.
    -- Closing the modal reveals it; do not reroll or append a second response.
    if view.session and view.session.currentNodeID ~= "block:gift"
        and #view.session.queue == 0
        and view.session.finishPending
    then
        view.session.pendingNext = "block:gift"
        view.session:finishPending()
    end
    return true
end

return Composer
