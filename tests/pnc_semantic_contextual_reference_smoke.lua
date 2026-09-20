local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

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
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticContextResolver.lua"
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
    currentTopic = "INVENTORY",
})

local npcInventoryAnswer = Semantic.IR.New({
    rawText = "I have a bottle of water and an apple.",
    normalizedText = "i have a bottle of water and an apple",
    intent = "INFORM",
    speechAct = "INFORM",
    subject = "INVENTORY",
    confidence = 0.96,
    extensions = {
        semanticMentions = {
            {
                id = "item:water",
                entityType = "item",
                concept = "BOTTLE_OF_WATER",
                text = "bottle of water",
                capabilities = { drinkable = true },
            },
            {
                id = "item:apple",
                entityType = "item",
                concept = "APPLE",
                text = "apple",
                capabilities = { edible = true },
            },
        },
    },
})

local recorded, event = store:RecordTurn(npcInventoryAnswer, {
    timestamp = 100,
    speaker = "npc",
    source = "npc_semantic_response",
})
T.equal(recorded, true, "NPC semantic response enters context")
T.equal(event.topic, "INVENTORY", "inventory becomes the active topic")
T.equal(store.currentTopic, "INVENTORY", "context keeps current topic")
T.equal(store:GetFocus(1)[1].concept, "APPLE",
    "latest item mention leads the discourse focus")

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
T.equal(resolved.object.id, "item:apple",
    "eat resolves it to the compatible edible item")
T.equal(resolved.object.unresolved, false,
    "resolved references are no longer unresolved")
T.equal(resolved.object.resolution.method,
    "context_salience_and_capability",
    "resolution records its contextual method")
T.equal(resolved.diagnostics.contextualResolver, true,
    "contextual resolver is visible in diagnostics")
T.truthy(resolved.diagnostics.contextualReferenceDetails.object.confidence
    >= 0.58, "compatible reference has usable confidence")

local giveStore = ContextState.New({ currentTopic = "INVENTORY" })
giveStore:RecordMention({
    id = "item:apple", entityType = "item", concept = "APPLE",
    text = "apple", capabilities = { edible = true, consumable = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
local give = Semantic.IR.New({
    rawText = "give it to me",
    normalizedText = "give it to me",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "GIVE",
    object = { reference = "IT", unresolved = true },
    confidence = 0.96,
})
local resolvedGive = ReferenceResolver.Resolve(
    give,
    nil,
    { semanticContextState = giveStore },
    {}
)
T.equal(resolvedGive.object.id, "item:apple",
    "give-it-to-me binds to the exact item from inventory dialogue")
T.equal(resolvedGive.object.unresolved, false,
    "the existing reference resolver completes the GIVE object")

local useStore = ContextState.New({ currentTopic = "INVENTORY" })
useStore:RecordMention({
    id = "item:apple", entityType = "item", concept = "APPLE",
    text = "apple", capabilities = { edible = true, consumable = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
useStore:RecordMention({
    id = "item:rifle", entityType = "item", concept = "RIFLE",
    text = "rifle", capabilities = { weapon = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
local use = Semantic.IR.New({
    rawText = "use it",
    normalizedText = "use it",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "CONSUME",
    object = { reference = "IT", unresolved = true },
    confidence = 0.94,
})
local resolvedUse = ReferenceResolver.Resolve(
    use,
    nil,
    { semanticContextState = useStore },
    {}
)
T.equal(resolvedUse.object.id, "item:apple",
    "use-it resolves only to the MarketSense-backed consumable")

local nonConsumableStore = ContextState.New({ currentTopic = "INVENTORY" })
nonConsumableStore:RecordMention({
    id = "item:rifle", entityType = "item", concept = "RIFLE",
    text = "rifle", capabilities = { weapon = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
local unresolvedUse = ReferenceResolver.Resolve(
    use,
    nil,
    { semanticContextState = nonConsumableStore },
    {}
)
T.equal(unresolvedUse.object.reference, "IT",
    "generic use stays unresolved for an item without a supported capability")

local ambiguousStore = ContextState.New({ currentTopic = "INVENTORY" })
ambiguousStore:RecordMention({
    id = "item:apple", entityType = "item", concept = "APPLE",
    capabilities = { edible = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
ambiguousStore:RecordMention({
    id = "item:pear", entityType = "item", concept = "PEAR",
    capabilities = { edible = true },
}, { turn = 1, role = "object", topic = "INVENTORY" })
local ambiguous = ReferenceResolver.Resolve(
    eat,
    nil,
    { semanticContextState = ambiguousStore },
    { minimumMargin = 0.08 }
)
T.equal(ambiguous.object.reference, "IT",
    "ambiguous references remain unresolved")
T.equal(ambiguous.diagnostics.contextualReferenceDetails.object.reason,
    "ambiguous_reference",
    "ambiguous compatible candidates request clarification")

local bounded = ContextState.New({ maxTurns = 1, maxMentions = 2 })
bounded:RecordMention({ id = "item:first", concept = "FIRST" }, { turn = 1 })
bounded:RecordMention({ id = "item:second", concept = "SECOND" }, { turn = 1 })
bounded:RecordMention({ id = "item:third", concept = "THIRD" }, { turn = 1 })
T.equal(#bounded:GetMentions(), 2, "mention history is bounded")

T.finish("pnc_semantic_contextual_reference_smoke")
