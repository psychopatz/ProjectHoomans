-- Client-side semantic gift result response and presentation boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader
local Internal = Composer.Internal
local Presentation = {}

local NEEDS_FALLBACK_SOURCE = Internal.NEEDS_FALLBACK_SOURCE
local GIFT_OFFER_KEYS = Internal.GIFT_OFFER_KEYS
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local formatGiftOffer = Internal.FormatGiftOffer
local giftOfferKey = Internal.GiftOfferKey
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter
local resolvedDialogue = Internal.ResolvedDialogue

local PREFERENCE_REACTIONS = {
    favorite = {
        key = "semantic.gift.reaction.favorite",
        fallback = "You remembered exactly what I like. Thank you.",
    },
    liked = {
        key = "semantic.gift.reaction.liked",
        fallback = "This is a good one. Thank you.",
    },
    disliked = {
        key = "semantic.gift.reaction.disliked",
        fallback = "I appreciate the thought, but this isn't really my thing.",
    },
    hated = {
        key = "semantic.gift.reaction.hated",
        fallback = "Is this a joke? Why would you give me this?",
    },
}

local function giftReplyPayload(giftEffect, source, key, context, args)
    local disposition = giftEffect and tostring(giftEffect.disposition or "")
    local reaction = PREFERENCE_REACTIONS[disposition]
    if reaction then
        return {
            key = reaction.key,
            domain = "pnc.system.shared.categories",
            fallback = reaction.fallback,
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
        fallback = fallback,
        args = { reason = tostring(reason or "gift_failed") },
    }
end

function Presentation.AppendFailure(state)
    local args = state.args
    local failure = giftFailurePayload(args.reason)
    if state.responseSession
        and type(state.responseSession.append) == "function"
    then
        state.responseSession:append("npc", failure, {
            source = {
                kind = "semantic",
                channel = "gift_result",
                requestID = state.requestID,
                reason = args.reason,
            },
            provenance = {
                provider = "server",
                parser = "authoritative_gift_transfer",
                requestID = state.requestID,
            },
        })
    end
    return failure
end

function Presentation.BuildSuccess(state)
    local args = state.args
    local offer = formatGiftOffer(args.itemTypes)
    local offerArgs = {
        giftItemName = offer.itemName,
        giftItemSummary = offer.itemSummary,
        giftItemCount = offer.count,
    }
    local offerKey = giftOfferKey(
        offer, args.itemTypes, state.context)
    local activeBlock = state.context
        and state.context.activeConversationBlockID
        and Registry.GetBlock(state.context.activeConversationBlockID) or nil
    local giftSource = activeBlock and activeBlock.textSource
        or NEEDS_FALLBACK_SOURCE
    local giftReplyKey = args.giftReplyKey
        or "gift.received." .. tostring(args.giftEffect
            and args.giftEffect.kind or "general")
    return {
        offer = offer,
        offerArgs = offerArgs,
        offerKey = offerKey,
        giftSource = giftSource,
        giftReplyKey = giftReplyKey,
    }
end

function Presentation.RefreshRelationship(state)
    local args = state.args
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
end

function Presentation.AppendSuccess(state, result)
    local args = state.args
    local responseSession = state.responseSession
    if responseSession and responseSession.append then
        local requiredKeys = {}
        for _, key in ipairs(GIFT_OFFER_KEYS) do
            requiredKeys[#requiredKeys + 1] = key
        end
        requiredKeys[#requiredKeys + 1] = result.giftReplyKey
        Loader.EnsureSource(result.giftSource, requiredKeys)
        -- A selector gift has a separate spoken item-selection line. An
        -- explicit semantic gift already has its original line in the log;
        -- appending the synthetic selector line would duplicate it.
        if not state.semanticAuto then
            responseSession:append("player", dialoguePayload(
                result.giftSource,
                result.offerKey,
                state.context,
                result.offerArgs
            ))
        end
        responseSession:append("npc", giftReplyPayload(
            args.giftEffect,
            result.giftSource,
            result.giftReplyKey,
            state.context,
            result.offerArgs
        ))
    end
end

function Presentation.RecordDiary(state, result)
    local args = state.args
    appendDiary(args.npcId, {
        kind = "gift",
        blockID = state.context and state.context.activeConversationBlockID,
        choiceID = "gift",
        playerText = resolvedDialogue(dialoguePayload(
            result.giftSource,
            result.offerKey,
            state.context,
            result.offerArgs
        )),
        npcText = resolvedDialogue(giftReplyPayload(
            args.giftEffect,
            result.giftSource,
            result.giftReplyKey,
            state.context,
            result.offerArgs
        )),
        itemSummary = result.offer.itemSummary,
        itemTypes = args.itemTypes,
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
end

function Presentation.Finish(state)
    local responseSession = state.responseSession
    if responseSession and responseSession.currentNodeID ~= "block:gift"
        and #responseSession.queue == 0
        and responseSession.finishPending
    then
        -- The authored gift node is already the next node of the conversation.
        -- Closing the modal reveals it; do not reroll or append a second response.
        responseSession.pendingNext = "block:gift"
        responseSession:finishPending()
    end
end

Internal.GiftReceivePresentation = Presentation

return Presentation
