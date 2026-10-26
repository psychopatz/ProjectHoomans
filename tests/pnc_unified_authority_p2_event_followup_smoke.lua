local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Lifecycle = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticInteractionLifecycle.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Identity/PNC_Identity.lua"
)
local Suggestions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestions.lua"
)
local Response = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueLocalResponse.lua"
)

local selected = Catalog.Select(
    "semantic.combat.reaction",
    { npcID = "npc-horde", eventType = "zombie_horde_detected" },
    "p2-horde"
)
T.equal(
    selected.id,
    "semantic.combat.reaction.threat",
    "horde event selects the semantic combat reaction"
)
local selectedOffers = Catalog.OffersForSelection(
    "semantic.combat.reaction",
    selected.id
)
T.equal(#selectedOffers, 3, "selected response exposes bounded follow-up offers")

local offerIDs = {}
for index = 1, #selectedOffers do
    offerIDs[index] = selectedOffers[index].id
end
local store = Lifecycle.New({ worldHour = 100 })
local recorded = Lifecycle.RecordNPCSpeech(store, {
    npcID = "npc-horde",
    targetID = "player-one",
    playerUUID = "player-one",
    act = "REACT",
    topic = "combat",
    eventType = "zombie_horde_detected",
    eventRef = "event:horde:p2",
    beatID = "beat:horde:p2",
    responsePlanID = "semantic.combat.reaction",
    poolID = "semantic.combat.reaction",
    realizationID = selected.id,
    factRefs = { "event:horde:p2", "horde.location", "horde.count" },
    offerIDs = offerIDs,
    meaningful = true,
    worldHour = 100,
})
T.truthy(recorded and recorded.thread and recorded.thread.activeBeat,
    "NPC event speech records a lifecycle response window")
local beat = recorded.thread.activeBeat
T.equal(beat.eventRef, "event:horde:p2", "event reference is retained")
T.equal(beat.realizationID, selected.id,
    "selected realization is retained without rendered text")
T.equal(#beat.offerIDs, 3, "only stable offer IDs are retained")
T.falsy(beat.renderedText, "lifecycle beat does not retain rendered speech")

local window = Lifecycle.ResponseWindow(store, "player-one", "npc-horde")
local context = {
    npcID = "npc-horde",
    interactionLifecycle = window,
    actorAuthority = { owned = true, companion = true },
    npcState = { activeBehavior = "idle", healthState = "healthy" },
}
local result = {
    sequence = 1,
    accepted = true,
    ir = { subject = "CONTEXT_REFERENCE" },
    decision = {
        response = {
            topic = "combat",
            plan = selected.plan,
        },
    },
}
local projection = Suggestions.Build(result, context, {})
local locationCandidate
for _, candidate in ipairs(projection.candidates or {}) do
    if candidate.id == "semantic.followup.event.location" then
        locationCandidate = candidate
        break
    end
end
T.truthy(locationCandidate,
    "eligible event follow-up is projected into normal Suggestions")
T.equal(locationCandidate.frame.origin.kind, "npc_event_response_plan",
    "event follow-up origin is lifecycle-backed")
T.equal(locationCandidate.frame.origin.eventRef, "event:horde:p2",
    "event follow-up carries the canonical event reference")

local clickIR = Suggestions.FrameToIR(locationCandidate.frame, {
    spec = { npcID = "npc-horde" },
    session = { semanticInteractionLifecycle = window },
})
T.equal(clickIR.subject, "CONTEXT_REFERENCE",
    "clicked event follow-up keeps the context-reference subject")
T.equal(clickIR.references.reference, "EVENT_LOCATION",
    "clicked event follow-up keeps the question reference")
T.equal(clickIR.extensions.contextQuestion, "EVENT_LOCATION",
    "clicked event follow-up carries the typed question kind")

local typedIR = Semantic.Parser.Parse("Where are they?")
T.equal(typedIR.subject, clickIR.subject,
    "typed and clicked event follow-ups share the subject")
T.equal(typedIR.extensions.contextQuestion, clickIR.extensions.contextQuestion,
    "typed and clicked event follow-ups share the question kind")

local state = { sequence = 2, currentTopic = "combat" }
local answerContext = {
    npcID = "npc-horde",
    interactionLifecycle = window,
    semanticEventFacts = {
        ["event:horde:p2"] = {
            eventRef = "event:horde:p2",
            authoritative = true,
            location = "north of the farmhouse",
        },
    },
}
local clickedResponse = Response.Resolve(
    clickIR, state, answerContext, "QUESTION_RECEIVED"
)
local typedResponse = Response.Resolve(
    typedIR, state, answerContext, "QUESTION_RECEIVED"
)
T.equal(clickedResponse.selectionID, typedResponse.selectionID,
    "clicked and typed event follow-ups select the same semantic answer")
T.equal(clickedResponse.fallback, "north of the farmhouse",
    "event answer is grounded in the authoritative event fact")
T.equal(typedResponse.eventRef, "event:horde:p2",
    "typed answer retains the authoritative event reference")

local staleContext = {
    npcID = "npc-horde",
    interactionLifecycle = window,
    semanticEventFacts = {
        ["event:stale"] = {
            eventRef = "event:stale",
            authoritative = true,
            location = "a stale place",
        },
    },
}
local staleResponse = Response.Resolve(
    typedIR, state, staleContext, "QUESTION_RECEIVED"
)
T.equal(staleResponse.referenceResolution, "event_fact_unavailable",
    "stale event facts cannot answer from a different event reference")
T.equal(staleResponse.uncertainty, "unknown",
    "stale event facts produce an explicit unknown answer")

local noFactsWindow = {
    activeBeat = {
        id = "beat:no-facts",
        eventRef = "event:no-facts",
        responsePlanID = "semantic.combat.reaction",
        realizationID = selected.id,
        factRefs = {},
        offerIDs = offerIDs,
    },
}
local noFactsProjection = Suggestions.Build(
    result,
    {
        npcID = "npc-horde",
        interactionLifecycle = noFactsWindow,
    },
    {}
)
local leaked = false
for _, candidate in ipairs(noFactsProjection.candidates or {}) do
    if candidate.id == "semantic.followup.event.location" then
        leaked = true
        break
    end
end
T.falsy(leaked, "event follow-ups are hidden without lifecycle fact refs")

local expired = Lifecycle.ResponseWindow(store, "player-one", "npc-horde")
store.worldHour = 200
local expiredWindow = Lifecycle.ResponseWindow(store, "player-one", "npc-horde")
T.truthy(expired and expired.activeBeat, "event window exists before expiry")
T.falsy(expiredWindow.activeBeat, "expired event window stops projecting offers")

T.finish("pnc_unified_authority_p2_event_followup_smoke")
