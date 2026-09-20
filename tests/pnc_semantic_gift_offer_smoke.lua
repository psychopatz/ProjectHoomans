local T = require "tests/support/test"
T.addPackagePaths()

local originalPsychopatzCore = PsychopatzCore
local originalPNC = PNC
local fallbacks = {}
PsychopatzCore = {
    Conversation = {
        Text = {
            RegisterFallback = function(key, value)
                fallbacks[key] = value
                return value
            end,
            Resolve = function(value)
                return value and (value.fallback or fallbacks[value.key]) or ""
            end,
        },
    },
}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Offer = T.load(
    "ProjectHoomans", "shared", "PNC/Gifts/PNC_GiftSemanticOffer.lua"
)

local function parse(value)
    local ir = Semantic.Parser.Parse(value)
    T.truthy(ir and ir.provenance and ir.provenance.pattern,
        "gift phrase matches a registered pattern: " .. value)
    return ir
end

local explicit = parse("I have an apple for you")
T.equal(explicit.intent, "OFFER", "explicit gift is an offer")
T.equal(explicit.action, "GIFT", "explicit gift has a compositional action")
T.equal(explicit.extensions.giftOffer.channel, "semantic",
    "explicit gift carries the semantic offer marker")
local explicitOffer = Offer.Classify(explicit)
T.equal(explicitOffer.mode, "explicit",
    "a named item does not open the vague-gift selector")
T.equal(explicitOffer.query, "apple", "named gift keeps its item query")
local addressed = parse("I have a gift for you Babe")
T.equal(Offer.Classify(addressed).mode, "selection",
    "a trailing vocative does not break a gift phrase")

local vague = parse("I have a gift for you")
local vagueOffer = Offer.Classify(vague)
T.equal(vagueOffer.mode, "selection",
    "a generic gift opens item selection")
local vagueDecision = Policy.Decide(vague, nil, { llmAvailable = false }, {})
T.equal(vagueDecision.route, "deterministic",
    "vague gift stays local without an LLM")
T.equal(vagueDecision.branch, "GIFT_SELECTION_REQUIRED",
    "vague gift selects the UI handoff branch")

local here = parse("Here's an apple for you")
T.equal(Offer.Classify(here).query, "apple",
    "here-is gift phrasing keeps its item query")
local waterGift = parse("Here's some water for you")
local waterOffer = Offer.Classify(waterGift)
T.equal(waterOffer.mode, "explicit",
    "a named water gift uses the direct gift route")
T.equal(waterOffer.query, "water",
    "the water gift keeps the item query for inventory matching")
local waterDecision = Policy.Decide(
    waterGift, nil, { llmAvailable = false }, {})
T.equal(waterDecision.branch, "GIFT_OFFER_DISPATCHED",
    "a water offer reaches the existing gift dispatch branch")
T.equal(waterDecision.giftOffer.query, "water",
    "the deterministic decision preserves the water query")
local reference = parse("This is for you")
T.equal(Offer.Classify(reference).mode, "selection",
    "reference gift remains unresolved until item context exists")

local groupOffer = parse("Who wants an apple")
T.falsy(Offer.Classify(groupOffer),
    "group demand offer is not mistaken for a direct gift")
local groupDecision = Policy.Decide(
    groupOffer, nil, { llmAvailable = false }, {})
T.equal(groupDecision.branch, "OFFER_RECEIVED",
    "group demand offer keeps its existing response branch")

local agreement = parse("sounds good")
T.equal(agreement.intent, "AGREE",
    "agreement phrases resolve through the social concept registry")
local disagreement = parse("I don't agree")
T.equal(disagreement.intent, "DISAGREE",
    "disagreement phrases resolve through the social concept registry")
local politeRefusal = parse("no thanks")
T.equal(politeRefusal.intent, "REFUSE",
    "polite refusals resolve through the existing refusal intent")
local positiveReply = parse("yes please")
T.equal(positiveReply.intent, "ACCEPT",
    "polite confirmations resolve through the existing accept intent")

local unboundYes = Policy.Decide(
    parse("yes"), nil, { llmAvailable = false }, {})
T.equal(unboundYes.branch, "SOCIAL_ACKNOWLEDGED",
    "agreement without a live offer remains a generic social response")
T.equal(unboundYes.giftConsent, nil,
    "agreement without a live offer cannot authorize a gift")

local function list(values)
    return {
        size = function(self) return #values end,
        get = function(self, index) return values[index + 1] end,
    }
end

local function item(id, fullType, displayName)
    return {
        getID = function(self) return id end,
        getFullType = function(self) return fullType end,
        getDisplayName = function(self) return displayName end,
        getName = function() return nil end,
        isFavorite = function() return false end,
        isEquipped = function() return false end,
    }
end

local appleA = item("apple-a", "Base.Apple", "Apple")
local appleB = item("apple-b", "Base.Apple", "Apple")
local fish = item("fish-a", "Base.FishFillet", "Fish Fillet")
local waterBottle = item(
    "water-a", "Base.WaterBottleFull", "Water Bottle"
)
local inventory = {
    getItems = function()
        return list({ appleA, appleB, fish, waterBottle })
    end,
}
local player = { getInventory = function() return inventory end }

PNC.Gifts = {
    IsValidItemType = function() return true end,
    Foundation = {
        MarketSenseAdapter = {
            BuildFacts = function(fullType)
                if fullType == "Base.WaterBottleFull" then
                    return {
                        primary = "drink", category = "drink",
                        subcategory = "water", leaf = "water bottle",
                        preferenceCandidates = {
                            {
                                type = "subcategory",
                                value = "water",
                                priority = 5,
                            },
                        },
                        marketSenseTags = { "water", "drink" },
                    }
                end
                if fullType == "Base.FishFillet" then
                    return {
                        primary = "food", category = "food",
                        subcategory = "seafood", leaf = "fish fillet",
                        preferenceCandidates = {
                            { type = "subcategory", value = "seafood", priority = 4 },
                        },
                        marketSenseTags = { "seafood" },
                    }
                end
                return {
                    primary = "food", category = "food",
                    subcategory = "fruit", leaf = "apple",
                    preferenceCandidates = {
                        { type = "leaf", value = "apple", priority = 5 },
                    },
                    marketSenseTags = { "fruit" },
                }
            end,
        },
    },
}
PNC.Semantics.GiftSelection = nil
local Selection = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticGiftSelection.lua"
)
local seafood = Selection.Find(player, { query = "seafood" })
T.truthy(seafood, "MarketSense subcategory matches a seafood query")
T.equal(seafood.fullType, "Base.FishFillet",
    "semantic gift matching chooses the MarketSense item category")
local waterSelection = Selection.Find(player, waterDecision.giftOffer)
T.truthy(waterSelection,
    "MarketSense item semantics resolve the water offer from inventory")
T.equal(waterSelection.fullType, "Base.WaterBottleFull",
    "water gift selection preserves the concrete item type")
local apples = Selection.Find(player, { query = "2 apple" })
T.truthy(apples, "quantity-prefixed gift matches local inventory")
T.equal(apples.quantity, 2, "quantity-prefixed gift selects both apples")
T.equal(#apples.itemIDs, 2, "quantity selection returns authoritative item IDs")

local sentTransfer
local openedSelector
PNC.Client = {
    SendInventoryTransfer = function(args)
        sentTransfer = args
        return true
    end,
}
PNC.InventoryWindow = {
    Open = function(npcID, options)
        openedSelector = { npcID = npcID, options = options }
        return true
    end,
}
getSpecificPlayer = function() return player end
local Input = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)
T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_GiftPresentation.lua"
)
T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Gifts.lua"
)
local actionView = {
    spec = {
        npcID = "npc-alice",
        context = {
            conversationLifecycleState = { token = "lease-one" },
            conversationBlockContext = {},
        },
    },
    session = {},
}
local actionResult = Input.Internal.DispatchAction(actionView, {
    sequence = 11,
    ir = { normalizedText = "i have an apple for you", confidence = 0.95 },
    decision = {
        branch = "GIFT_OFFER_DISPATCHED",
        route = "deterministic",
        giftOffer = { mode = "explicit", query = "apple" },
    },
}, "I have an apple for you")
T.equal(actionResult.status, "gift_transfer_pending",
    "explicit semantic gift submits a pending authoritative transfer")
T.equal(sentTransfer.gift, true, "direct gift uses the gift transfer boundary")
T.equal(sentTransfer.itemIDs[1], "apple-a",
    "direct gift sends the locally matched item ID")
T.equal(sentTransfer.conversationToken, "lease-one",
    "direct gift preserves the conversation lease token")
local busyResult = Input.Internal.DispatchAction(actionView, {
    sequence = 11,
    ir = { normalizedText = "i have an apple for you", confidence = 0.95 },
    decision = {
        branch = "GIFT_OFFER_DISPATCHED",
        route = "deterministic",
        giftOffer = { mode = "explicit", query = "apple" },
    },
}, "I have an apple for you")
T.equal(busyResult.status, "gift_request_busy",
    "a pending gift blocks a second request for the same conversation")
T.equal(PNC.Semantics.GiftLifecycle.Active(
    actionView.session, "npc-alice").requestID, sentTransfer.requestId,
    "a rejected gift leaves the active request intact")
PNC.Semantics.GiftLifecycle.Clear(actionView.session,
    sentTransfer.requestId)

local waterTransferResult = Input.Internal.DispatchAction(actionView, {
    sequence = 15,
    ir = waterGift,
    decision = waterDecision,
}, waterGift.normalizedText)
T.equal(waterTransferResult.status, "gift_transfer_pending",
    "an offered water item uses the existing authoritative transfer path")
T.equal(sentTransfer.itemIDs[1], "water-a",
    "the water offer transfers the item selected by MarketSense semantics")
T.equal(sentTransfer.gift, true,
    "the water transfer retains the existing gift flag")
PNC.Semantics.GiftLifecycle.Clear(actionView.session,
    sentTransfer.requestId)

local sendInventoryTransfer = PNC.Client.SendInventoryTransfer
PNC.Client.SendInventoryTransfer = function() return false end
local failedTransferResult = Input.Internal.DispatchAction(actionView, {
    sequence = 13,
    ir = { normalizedText = "i have an apple for you", confidence = 0.95 },
    decision = {
        branch = "GIFT_OFFER_DISPATCHED",
        route = "deterministic",
        giftOffer = { mode = "explicit", query = "apple" },
    },
}, "I have an apple for you")
T.equal(failedTransferResult.status, "gift_transfer_unavailable",
    "a rejected transport returns the existing transfer failure")
T.equal(PNC.Semantics.GiftLifecycle.Active(
    actionView.session, "npc-alice"), nil,
    "a failed transfer clears its pending gift request")
PNC.Client.SendInventoryTransfer = sendInventoryTransfer

local selectorResult = Input.Internal.DispatchAction(actionView, {
    sequence = 12,
    ir = { normalizedText = "i have a gift for you", confidence = 0.95 },
    decision = {
        branch = "GIFT_SELECTION_REQUIRED",
        route = "deterministic",
        giftOffer = { mode = "selection", query = "gift" },
    },
}, "I have a gift for you")
T.equal(selectorResult.status, "gift_selector_open",
    "vague semantic gift opens the existing inventory selector")
T.equal(openedSelector.npcID, "npc-alice",
    "gift selector targets the conversation NPC")
T.equal(openedSelector.options.mode, "gift",
    "gift selector uses the existing gift UI mode")
T.truthy(actionView.spec.context.giftConversationActive,
    "opening the selector marks the semantic gift conversation active")
T.truthy(actionView.spec.context.conversationBlockContext.giftConversationActive,
    "opening the selector marks the conversation block context active")

local groupSession = { conversationID = "conversation-group" }
local consentGroup = {
    id = "group:conversation-group",
    PrimarySession = function() return groupSession end,
    ViewFor = function(self, npcID)
        if npcID == "npc-alice" then return actionView end
        return nil
    end,
}
local groupPrimaryView = {
    spec = { npcID = "npc-primary", context = {} },
    session = groupSession,
    groupConversation = consentGroup,
}
local offerContext = {
    llmAvailable = false,
    pendingGiftConsent = {
        groupID = consentGroup.id,
        query = "apple",
        candidates = { { npcID = "npc-alice", name = "Alice" } },
    },
}
local consentIR = parse("yes")
local consentDecision = Policy.Decide(consentIR, nil, offerContext, {})
T.equal(consentDecision.branch, "GIFT_CONSENT_GRANTED",
    "a clear confirmation binds to the active one-recipient offer")
T.equal(consentDecision.giftConsent.recipientID, "npc-alice",
    "the consent decision preserves the interested NPC identity")
local declinedConsent = Policy.Decide(parse("no thanks"), nil,
    { llmAvailable = false, pendingGiftConsent = offerContext.pendingGiftConsent }, {})
T.equal(declinedConsent.branch, "GIFT_CONSENT_DECLINED",
    "a clear refusal closes the active offer without dispatching a gift")
T.equal(declinedConsent.giftConsent.recipientID, "npc-alice",
    "the refusal stays associated with the NPC who asked")
local consentTransfer = Input.Internal.DispatchAction(groupPrimaryView, {
    sequence = 20,
    ir = consentIR,
    decision = consentDecision,
}, "yes")
T.equal(consentTransfer.status, "gift_transfer_pending",
    "confirmed group offer uses the existing gift transfer path")
T.equal(sentTransfer.id, "npc-alice",
    "the confirmed item is routed to the interested secondary NPC")
T.equal(sentTransfer.requestId, "semantic-gift:npc-alice:20",
    "consent transfer keeps the existing idempotent request identity")
T.equal(sentTransfer.conversationToken, "lease-one",
    "consent transfer preserves the selected NPC's conversation lease")
PNC.Semantics.GiftLifecycle.Clear(actionView.session,
    sentTransfer.requestId)

local closedGroupDecision = Policy.Decide(parse("yes"), nil, offerContext, {})
consentGroup.closed = true
local closedGroupDispatch = Input.Internal.DispatchAction(groupPrimaryView, {
    sequence = 22,
    ir = parse("yes"),
    decision = closedGroupDecision,
}, "yes")
T.equal(closedGroupDispatch.status, "gift_consent_expired",
    "a closed group cannot authorize a stale pending gift")
consentGroup.closed = false

local groupOfferSession = {}
local lifecycle = PNC.Semantics.GiftLifecycle
lifecycle.StageOfferConsent(groupOfferSession, {
    query = "apple", groupID = consentGroup.id, groupTurnID = "turn:1",
}, { npcID = "npc-alice", name = "Alice" }, 1000)
lifecycle.StageOfferConsent(groupOfferSession, {
    query = "apple", groupID = consentGroup.id, groupTurnID = "turn:1",
}, { npcID = "npc-bob", name = "Bob" }, 1100)
local ambiguousContext = lifecycle.PendingOfferConsent(
    groupOfferSession, 1200, nil, consentGroup.id)
T.equal(#ambiguousContext.candidates, 2,
    "same-turn group interest is bounded and accumulated by recipient")
local ambiguousDecision = Policy.Decide(parse("yes"), nil, {
    llmAvailable = false,
    pendingGiftConsent = ambiguousContext,
}, {})
T.equal(ambiguousDecision.branch, "GIFT_CONSENT_AMBIGUOUS",
    "a generic yes cannot choose between multiple interested NPCs")
local previousRequestID = sentTransfer.requestId
local ambiguousDispatch = Input.Internal.DispatchAction(groupPrimaryView, {
    sequence = 21,
    ir = parse("yes"),
    decision = ambiguousDecision,
}, "yes")
T.equal(ambiguousDispatch, nil,
    "ambiguous consent does not dispatch a transfer")
T.equal(sentTransfer.requestId, previousRequestID,
    "ambiguous consent leaves the prior transfer untouched")
lifecycle.ClearOfferConsent(groupOfferSession)

local inventoryWindow = PNC.InventoryWindow
PNC.InventoryWindow = nil
local unavailableSelectorResult = Input.Internal.DispatchAction(actionView, {
    sequence = 14,
    ir = { normalizedText = "i have a gift for you", confidence = 0.95 },
    decision = {
        branch = "GIFT_SELECTION_REQUIRED",
        route = "deterministic",
        giftOffer = { mode = "selection", query = "gift" },
    },
}, "I have a gift for you")
T.equal(unavailableSelectorResult.status, "gift_selector_unavailable",
    "missing inventory UI returns the established selector failure")
T.equal(unavailableSelectorResult.response.key,
    "semantic.gift.selection_required",
    "missing inventory UI preserves the selection response contract")
PNC.InventoryWindow = inventoryWindow

PNC = originalPNC
PsychopatzCore = originalPsychopatzCore
T.finish("pnc_semantic_gift_offer_smoke")
