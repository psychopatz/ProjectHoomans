local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = { Semantics = {} }

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticContextConstraints.lua"
)
local ReferenceResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)

local ContextState = PNC.Semantics.DialogueContextState
local store = ContextState.New({
    maxTurns = 4,
    maxMentions = 8,
    maxFocus = 4,
})

PNC.Gifts = {
    Foundation = {
        MarketSenseAdapter = {
            BuildFacts = function(fullType)
                return {
                    fullType = fullType,
                    primary = "food",
                    category = "food",
                    subcategory = "fruit",
                    leaf = "apple",
                    tags = { "fruit" },
                    marketSenseTags = { "fruit", "food" },
                    capabilities = {
                        edible = true,
                        consumable = true,
                    },
                }
            end,
        },
    },
}

local recordedTurns = 0
PNC.Semantics.DialogueInput = {
    Internal = {
        RecordContextTurn = function(view, ir, options)
            recordedTurns = recordedTurns + 1
            return view.session.semanticDialogueContext:RecordTurn(ir, {
                speaker = options and options.speaker,
                source = options and options.source,
            })
        end,
    },
}

local GiftContext = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticGiftContext.lua"
)
local view = { session = { semanticDialogueContext = store } }
local recorded = GiftContext.RecordTransfer(view, {
    npcId = "npc-alice",
    itemTypes = { "Base.Apple" },
    itemIDs = { "npc-item-42" },
}, {
    mode = "auto",
    selection = {
        fullType = "Base.Apple",
        displayName = "Apple",
        facts = PNC.Gifts.Foundation.MarketSenseAdapter.BuildFacts(
            "Base.Apple"
        ),
    },
})
T.equal(recorded, true, "authoritative gift enters semantic context")
T.equal(recordedTurns, 1, "gift context creates one bounded semantic turn")
local focus = store:GetFocus(1)[1]
T.equal(focus.itemID, "npc-item-42",
    "gift context keeps the authoritative NPC item identity")
T.equal(focus.fullType, "Base.Apple",
    "gift context keeps the stable item type for fallback selection")
T.equal(focus.concept, "APPLE", "gift context keeps the MarketSense leaf")
T.equal(focus.capabilities.edible, true,
    "gift context keeps the MarketSense consumption capability")
T.equal(focus.marketSenseTags[1], "fruit",
    "gift context keeps MarketSense tags")

local eat = Semantic.IR.New({
    rawText = "eat it",
    normalizedText = "eat it",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "EAT",
    object = { reference = "IT", unresolved = true },
    confidence = 0.90,
})
local resolved = ReferenceResolver.Resolve(
    eat,
    nil,
    { semanticContextState = store },
    {}
)
T.equal(resolved.object.itemID, "npc-item-42",
    "eat it resolves to the gifted NPC item")
T.equal(resolved.object.fullType, "Base.Apple",
    "resolved gift reference retains the stable item type")
T.equal(resolved.object.unresolved, false,
    "gifted item reference is resolved")

local Lifecycle = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticGiftLifecycle.lua"
)
local session = {}
local started = Lifecycle.Begin(session, "gift-1", {
    mode = "auto",
    npcID = "npc-alice",
}, 100)
T.equal(started, true, "gift lifecycle accepts a new request")
local duplicate, duplicateReason = Lifecycle.Begin(session, "gift-1", {}, 101)
T.equal(duplicate, false, "gift lifecycle rejects an active duplicate")
T.equal(duplicateReason, "gift_request_active",
    "active duplicate has a stable reason")
T.equal(Lifecycle.Active(session, "npc-alice").requestID, "gift-1",
    "active gift is discoverable by NPC")
Lifecycle.MarkHandled(session, "gift-1", 200)
T.equal(Lifecycle.IsHandled(session, "gift-1"), true,
    "handled gift result is remembered")
T.equal(Lifecycle.Get(session, "gift-1"), nil,
    "handled gift no longer retains pending payload")

local expired = {}
Lifecycle.Begin(expired, "gift-2", { mode = "auto" }, 0)
T.equal(Lifecycle.Expire(expired, 2000, 1000), 1,
    "stale gift request expires")
T.equal(Lifecycle.Get(expired, "gift-2").state, "expired",
    "expired result retains its semantic selection for a late callback")

T.finish("pnc_semantic_gift_context_smoke")
