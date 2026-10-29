local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {}, Network = { ClientState = {
    playerContext = { characterUUID = "player-one" },
    snapshots = {
        ["npc-a"] = { id = "npc-a", activeBehavior = "FollowOwner" },
    },
} } }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity.lua"
)
local Suggestions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestions.lua"
)

local submitted
PNC.Semantics.DialogueInput = {
    Internal = {
        RouterFor = function(view)
            view._router = view._router or { state = { sequence = 7 } }
            return view._router
        end,
        ShallowContext = function(view)
            return view.spec.context
        end,
    },
    SubmitSemanticFrame = function(view, frame, options)
        submitted = { view = view, frame = frame, options = options }
        return true, "accepted"
    end,
}

local Surface = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticCombatResponseSurface.lua"
)

local clock = 1000
local conversationOpen = false
local shows, hides, syncs = 0, 0, 0
Surface.SetClock(function() return clock end)
Surface.SetConversationProbe(function() return conversationOpen end)
Surface.SetUIAdapter({
    Show = function(model)
        shows = shows + 1
        T.truthy(model and #model.rows == 3,
            "combat surface adapter receives three tactical rows")
        return true
    end,
    Hide = function()
        hides = hides + 1
        return true
    end,
    Sync = function()
        syncs = syncs + 1
        return true
    end,
})

local eventRef = "social:zombie_horde_encounter:npc-a:3000:1"
local resolved = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = eventRef,
    npcID = "npc-a",
    act = "QUESTION",
    topic = "combat",
    context = {
        eventType = "zombie_horde_encounter",
        eventRef = eventRef,
        hordePhase = "started",
        combatTacticalPrompt = true,
        presentationClass = "TACTICAL_PROMPT",
        combatReactionStyle = "practical",
        factRefs = { eventRef },
        semanticEventFacts = {
            [eventRef] = {
                eventRef = eventRef,
                authoritative = true,
                disclosure = "player",
                summary = "a zombie horde was detected",
                quantity = "8 zombies are close enough to matter.",
            },
        },
    },
}), "tactical prompt resolves for surface")

local receive = {
    npcID = "npc-a",
    eventID = eventRef,
    eventType = "zombie_horde_encounter",
    ambientFlavor = {
        npcID = "npc-a",
        eventRef = eventRef,
        responsePlanID = resolved.responsePlanID,
        poolID = resolved.realizationFamily,
        realizationID = resolved.realizationID,
        offerIDs = resolved.offerIDs,
        factRefs = { eventRef },
        act = "QUESTION",
        topic = "combat",
        ttlMs = 5000,
    },
    context = {
        npcID = "npc-a",
        eventRef = eventRef,
        presentationClass = "TACTICAL_PROMPT",
        combatTacticalPrompt = true,
        offerIDs = resolved.offerIDs,
        factRefs = { eventRef },
        semanticEventFacts = {
            [eventRef] = {
                eventRef = eventRef,
                authoritative = true,
                disclosure = "player",
                summary = "a zombie horde was detected",
                quantity = "8 zombies are close enough to matter.",
            },
        },
    },
}

local observed, reason = Surface.ObserveReceive(receive)
T.truthy(observed, "closed-conversation tactical prompt is projected")
T.equal(reason, "combat_surface_shown",
    "closed prompt chooses the compact combat surface")
local snapshot = T.truthy(Surface.Snapshot(), "surface exposes bounded snapshot")
T.equal(#snapshot.rows, 3, "surface snapshot has exactly tactical choices")
T.equal(snapshot.rows[1].id, "semantic.combat.horde.choice.engage",
    "surface row comes from canonical tactical offer")
T.truthy(snapshot.uiVisible, "surface is visible while conversation is closed")
T.truthy(shows >= 1, "UI adapter was asked to show")

local accepted, submitReason = Surface.Submit(
    "semantic.combat.horde.choice.engage"
)
T.truthy(accepted, "compact tactical row submits")
T.equal(submitReason, "accepted", "compact submit returns semantic result")
T.truthy(submitted and submitted.view.headless == true,
    "compact surface submits through a headless semantic host")
T.equal(submitted.frame.action, "COMBAT_ENGAGE",
    "compact surface submits the canonical typed action frame")
T.equal(submitted.frame.origin.eventRef, eventRef,
    "compact surface preserves encounter event guard")
T.truthy(submitted.options.transientCombatSurface,
    "compact submit marks only presentation suppression")
T.equal(Surface.Snapshot(), nil,
    "accepted compact choice closes its local prompt immediately")

submitted = nil
conversationOpen = true
clock = 2000
local openObserved, openReason = Surface.ObserveReceive(receive)
T.truthy(openObserved, "same semantic prompt remains available to conversation")
T.equal(openReason, "conversation_owns_prompt",
    "full conversation suppresses the compact duplicate surface")
T.falsy(Surface.Snapshot().uiVisible,
    "compact surface is hidden while full conversation owns the prompt")
conversationOpen = false
Surface.OnTick()
T.truthy(Surface.Snapshot().uiVisible,
    "compact surface reappears if conversation closes before resolution")

local invalidated = Surface.ApplyAuthorityState({
    eventRef = eventRef,
    active = true,
    intent = "engage",
    reason = "intent_resolved",
})
T.truthy(invalidated, "authoritative implicit engage invalidates prompt")
T.equal(Surface.Snapshot(), nil,
    "implicit authority resolution removes stale compact choices")

clock = 3000
Surface.ObserveReceive(receive)
T.truthy(Surface.Snapshot(), "third prompt is active for timeout case")
clock = 9001
Surface.OnTick()
T.equal(Surface.Snapshot(), nil, "expired tactical prompt is removed")

local preflightSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Preflight.lua"
)
local commitSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Commit.lua"
)
T.contains(preflightSource, "semanticTransientSurface",
    "transient presentation flag survives semantic preflight")
T.contains(commitSource, "skipInputPresentation = transientSemanticSurface",
    "compact semantic click does not fabricate a chat transcript line")
T.contains(commitSource, "deferResponse = transientSemanticSurface",
    "compact semantic click does not queue a duplicate chatbot acknowledgement")
T.contains(commitSource, "not transientSemanticSurface",
    "compact semantic click skips conversation-only suggestion refresh")

T.truthy(hides >= 2, "surface adapter receives bounded hide transitions")
T.finish("pnc_semantic_combat_response_surface_smoke")
