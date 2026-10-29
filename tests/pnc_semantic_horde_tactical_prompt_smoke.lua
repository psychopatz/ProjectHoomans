local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
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

local eventRef = "social:zombie_horde_encounter:npc-a:3000:1"
local resolved = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = eventRef,
    npcID = "npc-a",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_encounter",
        eventRef = eventRef,
        hordePhase = "started",
        combatTacticalPrompt = true,
        presentationClass = "TACTICAL_PROMPT",
        combatReactionStyle = "shaken",
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
}), "tactical horde prompt resolves")

T.equal(resolved.responsePlanID, "semantic.combat.horde.prompt",
    "tactical horde uses dedicated prompt pool")
T.equal(resolved.realizationID, "semantic.combat.horde.prompt.shaken",
    "shaken follower gets hesitant prompt wording")
T.truthy(string.find(resolved.fallback, "Fuck", 1, true),
    "hesitant high-pressure prompt may use authored profanity")
T.equal(#(resolved.offerIDs or {}), 3, "prompt exposes exactly three team choices")

local offers = Catalog.OffersForSelection(
    resolved.responsePlanID,
    resolved.realizationID
)
T.equal(#offers, 3, "catalog resolves three tactical offers")
local byID = {}
for _, offer in ipairs(offers) do byID[offer.id] = offer end
T.equal(byID["semantic.combat.horde.choice.engage"].frame.action,
    "COMBAT_ENGAGE", "engage choice carries typed gameplay action")
T.equal(byID["semantic.combat.horde.choice.avoid"].frame.action,
    "COMBAT_AVOID", "avoid choice carries typed gameplay action")
T.equal(byID["semantic.combat.horde.choice.hold"].frame.action,
    "COMBAT_HOLD", "hold choice carries typed gameplay action")
T.equal(byID["semantic.combat.horde.choice.engage"].frame.target,
    "SELF", "tactical choice targets the speaking companion")

local offerIDs = {}
for index = 1, #offers do offerIDs[index] = offers[index].id end
local store = Lifecycle.New({ worldHour = 100 })
local recorded = Lifecycle.RecordNPCSpeech(store, {
    npcID = "npc-a",
    targetID = "player-one",
    playerUUID = "player-one",
    act = "QUESTION",
    topic = "combat",
    eventType = "zombie_horde_encounter",
    eventRef = eventRef,
    beatID = "beat:horde:tactical",
    responsePlanID = resolved.responsePlanID,
    realizationID = resolved.realizationID,
    factRefs = { eventRef },
    offerIDs = offerIDs,
    meaningful = false,
    transient = true,
    worldHour = 100,
})
T.truthy(recorded and recorded.thread and recorded.thread.activeBeat,
    "tactical prompt is available through transient lifecycle")
local window = Lifecycle.ResponseWindow(store, "player-one", "npc-a")
local projection = Suggestions.Build({
    sequence = 1,
    accepted = true,
    ir = {},
    decision = {
        response = {
            topic = "combat",
            plan = resolved.responsePlan,
        },
    },
}, {
    npcID = "npc-a",
    interactionLifecycle = window,
    actorAuthority = { owned = true, companion = true },
    npcState = { activeBehavior = "FollowOwner" },
}, {})
local engageCandidate
for _, candidate in ipairs(projection.candidates or {}) do
    if candidate.id == "semantic.combat.horde.choice.engage" then
        engageCandidate = candidate
        break
    end
end
T.truthy(engageCandidate,
    "tactical engage offer projects through normal Suggestions")
T.equal(engageCandidate.frame.origin.eventRef, eventRef,
    "tactical offer keeps active encounter event identity")

local engageIR = Suggestions.FrameToIR(engageCandidate.frame, {
    spec = { npcID = "npc-a" },
    session = { semanticInteractionLifecycle = window },
})
T.equal(engageIR.action, "COMBAT_ENGAGE",
    "clicked tactical choice remains a typed semantic action")
T.equal(engageIR.target.id, "npc-a",
    "SELF tactical choice binds to the speaking follower")
T.equal(engageIR.modifiers.encounterEpisodeID, eventRef,
    "clicked tactical choice carries the active encounter episode guard")
T.equal(engageIR.provenance.parser, "semantic_click_frame",
    "tactical choice never reparses displayed text")

local eager = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = eventRef .. ":eager",
    npcID = "npc-a",
    context = {
        combatTacticalPrompt = true,
        combatReactionStyle = "brave",
    },
}), "brave tactical prompt resolves")
T.equal(eager.realizationID, "semantic.combat.horde.prompt.eager",
    "brave/aggressive follower receives eager prompt family")

T.finish("pnc_semantic_horde_tactical_prompt_smoke")
