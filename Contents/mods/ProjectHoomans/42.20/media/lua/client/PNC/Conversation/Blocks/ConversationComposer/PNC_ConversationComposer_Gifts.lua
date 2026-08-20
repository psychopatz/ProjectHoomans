local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader
local Relationship = Conversation.Relationship
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

function Composer.ReceiveGiftResult(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcId)
    if not view then return false end
    local context = view.spec and view.spec.context
        and view.spec.context.conversationBlockContext or nil
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
            relationshipDelta = args.relationshipDelta,
            effect = args.giftEffect,
        }
        context.giftConversationActive = nil
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
    receiveRelationshipAfter(args.npcId, args.relationshipAfter)
    if Relationship and Relationship.RequestPresentation then
        -- The authoritative effect is committed before this callback. Refresh
        -- the live conversation panel so its marker and attitude use the same
        -- relationship snapshot that the debug laboratory displays.
        Relationship.RequestPresentation(args.npcId)
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
        -- The item selection is a spoken player line, not an inventory-only
        -- event. Keep it in the same transcript before the NPC reacts.
        view.session:append("player", dialoguePayload(
            giftSource,
            offerKey,
            context,
            offerArgs
        ))
        view.session:append("npc", dialoguePayload(
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
        npcText = resolvedDialogue(dialoguePayload(
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

