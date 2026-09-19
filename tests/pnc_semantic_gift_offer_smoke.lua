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
local inventory = { getItems = function() return list({ appleA, appleB, fish }) end }
local player = { getInventory = function() return inventory end }

PNC.Gifts = {
    IsValidItemType = function() return true end,
    Foundation = {
        MarketSenseAdapter = {
            BuildFacts = function(fullType)
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

local sendInventoryTransfer = PNC.Client.SendInventoryTransfer
PNC.Client.SendInventoryTransfer = function() return false end
local failedTransferResult = Input.Internal.DispatchAction(actionView, {
    sequence = 13,
    ir = { normalizedText = "i have an apple for you", confidence = 0.95 },
    decision = {
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

local inventoryWindow = PNC.InventoryWindow
PNC.InventoryWindow = nil
local unavailableSelectorResult = Input.Internal.DispatchAction(actionView, {
    sequence = 14,
    ir = { normalizedText = "i have a gift for you", confidence = 0.95 },
    decision = {
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
