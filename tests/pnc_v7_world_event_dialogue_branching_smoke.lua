local T = require "tests/support/test"
T.addPackagePaths()
package.path = "../psychopatzCore/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. package.path

local mockHours = 120.0
local hooks = {
    LoadChunk = {},
    OnSpawnVehicleEnd = {},
    OnSeeNewRoom = {},
}

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return mockHours / 24 end,
        getWorldAgeHours = function() return mockHours end,
    }
end
getCell = function()
    return {
        getGridSquare = function(_, x)
            if x >= 8160 then
                return { getRoom = function() return { name = "livingroom" } end }
            end
            return { getRoom = function() return nil end }
        end,
    }
end
Events = {}
for k, v in pairs(hooks) do
    Events[k] = {
        Add = function(fn) v[#v + 1] = fn end,
    }
end

PsychopatzCore = PsychopatzCore or {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local Predicate = require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
local ScopedEvents = Core.ScopedWorldEvents
local CoreKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
local Observer = Core.VanillaEventObserver
local DiscoveryAdapter = Core.VanillaDiscoveryAdapter
local Location = Core.WorldEventLocation

local actorOut = {
    id = "npc_out",
    coreActorID = "actor_out",
    name = "Sam Outdoor",
    alive = true,
    x = 8155,
    y = 11525,
    z = 0,
    isOutside = function() return true end,
    getSquare = function() return { isOutside = function() return true end } end,
}
local actorIn = {
    id = "npc_in",
    coreActorID = "actor_in",
    name = "Pat Indoors",
    alive = true,
    x = 8160,
    y = 11530,
    z = 0,
    isOutside = function() return false end,
    getSquare = function() return { isOutside = function() return false end } end,
}
local actorFar = {
    id = "npc_far",
    coreActorID = "actor_far",
    name = "Lee Far",
    alive = true,
    x = 14000,
    y = 4000,
    z = 0,
}

PNC = {
    Const = { MODULE = "PNC" },
    Core = {
        IsClientOnly = function() return false end,
        Now = function() return mockHours end,
    },
    Registry = {
        Get = function(id)
            if id == actorOut.id then return actorOut end
            if id == actorIn.id then return actorIn end
            if id == actorFar.id then return actorFar end
            return nil
        end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y)
            if math.abs(x - actorOut.x) < 150 and math.abs(y - actorOut.y) < 150 then
                return { actorOut, actorIn }
            end
            return {}
        end,
    },
    Semantics = {},
    ConvoEngine = {},
}

require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/ConvoEngine/Registry"

local CompiledFlows = require("PNC/ConvoEngine/Flows/Dialogue/ThematicInteractive")
local ChoicePolicy = require("PNC/ConvoEngine/Social/ChoicePolicy")
local TurnPolicy = require("PNC/ConvoEngine/Social/TurnPolicy")
local Conversation = require("PNC/ConvoEngine/Social/Conversation")
local GeneratedAffordances = require("PNC/ConvoEngine/Suggestions/GeneratedAffordanceProvider")
local UtterancePlan = require("PNC/ConvoEngine/UtterancePlan")

local FlowByID = {}
for _, flow in ipairs(CompiledFlows or {}) do
    if type(flow) == "table" and flow.id then
        FlowByID[flow.id] = flow
    end
end

-- 1. Core vanilla world events + discoveries drive grounded epistemic dialogue facts without per-NPC duplicates.
ScopedEvents.Reset()
Observer.Reset()
DiscoveryAdapter.Reset()
CoreKnowledge.Reset({ now = mockHours })
PNC.WorldKnowledge.ResetWorldStateRuntime()
Location.ClearProviders()
Location.RegisterProvider("rosewood_town", function(x, y)
    if x >= 8000 and x <= 8300 and y >= 11400 and y <= 11700 then
        return { settlementID = "settlement:rosewood", regionID = "region_south", label = "Rosewood Outskirts", kind = "settlement" }
    end
    return nil
end, 10)
PNC.WorldKnowledge.InstallCoreEventPerceptionHook()

local heliRes = assert(PNC.WorldKnowledge.ObserveHelicopterEpisode(mockHours, {
    helicopter = {
        isActive = function() return true end,
        x = 8156,
        y = 11526,
    },
}))
for _, fn in ipairs(hooks.LoadChunk) do
    fn({
        vehicleStorySpawnData = {
            story = { getName = function() return "Ambulance Crash" end },
            spawnX = 8150,
            spawnY = 11520,
        },
    })
end
local promoted = PNC.WorldKnowledge.DiscoverNearbyStories(actorOut, 80, mockHours)
T.equal(#promoted, 1, "outdoor actor discovers buffered ambulance crash")

T.equal(#ScopedEvents.QueryActive({ eventType = "world_helicopter_overflight" }, mockHours), 1,
    "single canonical helicopter episode shared across outdoor & indoor NPCs")
T.equal(#ScopedEvents.QueryActive({ eventType = "discovery_vehicle_story_ambulance_crash" }, mockHours), 1,
    "single canonical ambulance crash discovery registered")

local heliFactID = heliRes.factID
local outCtx = PNC.WorldKnowledge.BuildConversationContext(actorOut, { max = 6, now = mockHours })
local inCtx = PNC.WorldKnowledge.BuildConversationContext(actorIn, { max = 6, now = mockHours })
local farCtx = PNC.WorldKnowledge.BuildConversationContext(actorFar, { max = 6, now = mockHours })

local outHeli = PNC.WorldKnowledge.QueryActorFact(actorOut, { factID = heliFactID }, mockHours)
local inHeli = PNC.WorldKnowledge.QueryActorFact(actorIn, { factID = heliFactID }, mockHours)
local farCrashBefore = PNC.WorldKnowledge.QueryActorFact(actorFar, { topic = "ambulance crash" }, mockHours)

T.equal(outHeli.provenance, "witnessed", "outdoor NPC witnesses helicopter directly")
T.equal(inHeli.provenance, "environmental", "indoor NPC hears helicopter without false visual precision")
T.equal(farCrashBefore.epistemicStatus, "unknown", "distant NPC remains ignorant until told/radio")

local sharedToFar = assert(PNC.WorldKnowledge.PropagateConversation(actorOut, actorFar, {
    authorized = true,
    channel = "conversation",
    max = 4,
    now = mockHours + 1,
}))
T.truthy(#sharedToFar >= 1, "outdoor NPC shares facts to distant NPC over conversation")
local farHeliAfter = PNC.WorldKnowledge.QueryActorFact(actorFar, { factID = heliFactID }, mockHours + 1)
T.equal(farHeliAfter.provenance, "told", "told propagation sets told provenance")
T.equal(farHeliAfter.epistemicStatus, "uncertain", "told helicopter rumor remains uncertain")

local inRendered = ""
for _, row in ipairs(inCtx.npcGossip.statements or {}) do
    inRendered = inRendered .. " " .. tostring(type(row) == "table" and row.text or row or "")
end
T.truthy(string.find(string.lower(inRendered), "heard", 1, true) ~= nil,
    "indoor helicopter realization expresses heard/environmental uncertainty: " .. inRendered)
T.falsy(string.find(string.lower(inRendered), "saw", 1, true),
    "indoor helicopter realization never falsely claims visual sighting")
T.truthy(#(outCtx.npcGossip.factRefs or {}) >= 2 and #(farCtx.npcGossip.factRefs or {}) == 0,
    "outdoor NPC carries grounded facts while unexposed distant NPC stays ignorant before telling")

-- 2. Contextual hard constraint filtering on thematic flow branch offers (<= 8 visible offers).
local function filterOffers(flowID, nodeID, predicateContext)
    local flow = FlowByID[flowID]
    T.truthy(flow and flow.nodes and flow.nodes[nodeID], flowID .. "." .. nodeID .. " exists")
    local offers = flow.nodes[nodeID].branchOffers or {}
    T.truthy(#offers <= 8, flowID .. "." .. nodeID .. " never exceeds MAX_OFFERS=8")
    local allowedIDs = {}
    for _, bo in ipairs(offers) do
        local ok = true
        if type(bo.constraints) == "table" then
            local eval = Predicate.Evaluate(bo.constraints, predicateContext)
            ok = eval.allowed == true
        end
        if ok then allowedIDs[bo.id] = true end
    end
    return allowedIDs, #offers
end

local gossipIndoorHeli, gossipCount = filterOffers("knowledge.gossip.exchange", "probe_epistemic_basis", {
    environment = { isIndoors = true },
    worldKnowledge = { hasHelicopter = true, hasStoryDiscovery = true },
})
T.truthy(gossipIndoorHeli["knowledge.gossip.indoor_chopper_heard"] == true,
    "indoor actor unlocks heard-indoors helicopter offer")
T.truthy(gossipIndoorHeli["knowledge.gossip.outdoor_crash_seen"] == nil,
    "indoor actor cannot claim firsthand outdoor wreck sighting")

local gossipOutdoorCrash = filterOffers("knowledge.gossip.exchange", "probe_epistemic_basis", {
    environment = { isIndoors = false },
    worldKnowledge = { hasHelicopter = false, hasStoryDiscovery = true },
})
T.truthy(gossipOutdoorCrash["knowledge.gossip.outdoor_crash_seen"] == true,
    "outdoor witness near wreck unlocks crash offer")
T.truthy(gossipOutdoorCrash["knowledge.gossip.indoor_chopper_heard"] == nil,
    "outdoor actor filters out indoor-only chopper offer")
T.truthy(gossipCount >= 3 and gossipCount <= 8, "gossip hub preserves 3-8 candidate range")

local triageWithMeds = filterOffers("wellbeing.needs.checkin", "triage_care", {
    inventory = { hasMedicalItem = true },
    relationship = { approval = 15 },
})
local triageWithoutMeds = filterOffers("wellbeing.needs.checkin", "triage_care", {
    inventory = { hasMedicalItem = false },
    relationship = { approval = -30 },
})
T.truthy(triageWithMeds["wellbeing.checkin.offer_med_kit"] == true, "medical kit offer appears when item exists")
T.truthy(triageWithoutMeds["wellbeing.checkin.offer_med_kit"] == nil, "medical kit offer hidden without medical items")
T.truthy(triageWithoutMeds["wellbeing.checkin.reluctant_check"] == nil, "reluctant offer filtered below approval threshold")

-- 3. Numeric disposition + demeanor + condition + epistemic provenance drive SocialChoicePolicy selection.
local function cand(strategy, stance)
    return { id = "gen." .. string.lower(strategy), strategy = strategy, stance = stance, eligibility = { allowed = true } }
end

local epistemicCandidates = {
    cand("CORROBORATE", "POSITIVE"),
    cand("CONTRADICT", "NEGATIVE"),
    cand("EXPRESS_UNCERTAINTY", "NEUTRAL"),
    cand("REVEAL_SOURCE", "POSITIVE"),
    cand("PROTECT_SOURCE", "NEUTRAL"),
}

local witnessedChoice = ChoicePolicy.Select(epistemicCandidates, {
    motive = "EPISTEMIC",
    epistemic = { provenance = "witnessed", status = "known", corroborated = true },
    relationship = { approval = 35, respect = 30, trust = 40 },
    responderProjection = {
        actor = { disposition = { aggression = 25, confidence = 80, bravery = 70, compassion = 65, forgiveness = 60, sociability = 75, loyalty = 80 } },
    },
})
T.equal(witnessedChoice.selected.strategy, "CORROBORATE",
    "high-confidence witness selects CORROBORATE")

local indoorHeardChoice = ChoicePolicy.Select(epistemicCandidates, {
    motive = "EPISTEMIC",
    epistemic = { provenance = "environmental", status = "uncertain" },
    relationship = { approval = 0, respect = 0, trust = -10 },
    responderProjection = {
        actor = { disposition = { aggression = 30, confidence = 40, bravery = 45, compassion = 55, forgiveness = 50, sociability = 40, loyalty = 50 } },
    },
})
T.equal(indoorHeardChoice.selected.strategy, "EXPRESS_UNCERTAINTY",
    "indoor environmental provenance selects EXPRESS_UNCERTAINTY")

local contradictedChoice = ChoicePolicy.Select(epistemicCandidates, {
    motive = "EPISTEMIC",
    epistemic = { provenance = "witnessed", status = "known", contradicted = true },
    relationship = { approval = -35, respect = -20, trust = -25 },
    responderProjection = {
        actor = { disposition = { aggression = 65, confidence = 85, bravery = 75, compassion = 30, forgiveness = 30, sociability = 50, loyalty = 50 } },
    },
})
T.equal(contradictedChoice.selected.strategy, "CONTRADICT",
    "contradicting firsthand witness selects CONTRADICT")

local careChoice = ChoicePolicy.Select({
    cand("ACCEPT_TREATMENT", "POSITIVE"),
    cand("REFUSE_TREATMENT", "NEGATIVE"),
}, {
    motive = "REQUEST",
    condition = { injured = true, pain = 0.6 },
    relationship = { approval = 40, respect = 35, trust = 50 },
    responderProjection = {
        actor = { disposition = { compassion = 70, forgiveness = 65, sociability = 60 } },
    },
})
T.equal(careChoice.selected.strategy, "ACCEPT_TREATMENT",
    "injured trusting actor selects ACCEPT_TREATMENT")

local unsafeWorkChoice = ChoicePolicy.Select({
    cand("VOLUNTEER", "POSITIVE"),
    cand("NEGOTIATE", "NEUTRAL"),
    cand("REFUSE_UNSAFE_WORK", "NEGATIVE"),
}, {
    motive = "COORDINATE",
    worldKnowledge = { outdoorHazard = true },
    condition = { fatigue = 85, injured = true },
    relationship = { approval = -20, trust = -20 },
    responderProjection = {
        actor = { disposition = { aggression = 55, bravery = 35, forgiveness = 30, loyalty = 30 } },
    },
})
T.equal(unsafeWorkChoice.selected.strategy, "REFUSE_UNSAFE_WORK",
    "exhausted actor under outdoor hazard selects REFUSE_UNSAFE_WORK")

-- 4. GeneratedAffordanceProvider produces bounded semantic affordances (<= 8) with grounded epistemic realizations.
local gaCandidates = GeneratedAffordances.collectForResponder({
    dialogueIR = { intent = "QUESTION", speechAct = "QUESTION", subject = "NEWS" },
    npcID = "npc_in",
    playerID = "npc_out",
    semanticDialogueContext = {
        recentTurns = {
            {
                sequence = 1,
                speaker = "npc",
                intent = "QUESTION",
                speechAct = "QUESTION",
                subject = "NEWS",
                topic = "news",
                confidence = 1,
            },
        },
    },
    epistemic = { provenance = "witnessed", corroborated = true },
    worldKnowledge = { hasHelicopter = true },
}, {
    actorID = "npc_out",
    name = "Sam Outdoor",
})
T.truthy(#gaCandidates >= 3 and #gaCandidates <= 8,
    "GeneratedAffordanceProvider exposes bounded epistemic frontier (" .. tostring(#gaCandidates) .. ")")
T.equal(gaCandidates[1].strategy, "CORROBORATE",
    "witnessed context surfaces CORROBORATE affordance cleanly")
UtterancePlan.ResetCatalogForTests()

-- 5. Multi-actor scene turn arbitration (<= 4 participants, <= 8 turns) supports third-party interjection outcomes.
local witnessTurn = TurnPolicy.Select({
    participants = {
        { id = "npc_a", kind = "npc" },
        { id = "npc_b", kind = "npc" },
        { id = "npc_witness", kind = "npc" },
        { id = "npc_mediator", kind = "npc" },
    },
    currentSpeakerID = "npc_a",
    currentRecipientID = "player_1",
    allowInterjectionOverPlayerWait = true,
    choicesByActor = {
        npc_b = { selected = nil, reason = "no_eligible_affordance" },
        npc_witness = { selected = cand("CORROBORATE", "POSITIVE"), selectedScore = 0.88, targetID = "npc_a" },
        npc_mediator = { selected = cand("MEDIATE", "POSITIVE"), selectedScore = 0.80, targetID = "npc_a" },
    },
    interjections = {
        npc_witness = { allowed = true, priority = 0.28, motive = "EPISTEMIC", role = "witness", outcome = "witness_corroborates" },
        npc_mediator = { allowed = true, priority = 0.20, motive = "MEDIATE", role = "mediator", outcome = "mediator_deescalates" },
    },
})
T.equal(witnessTurn.mode, "emit", "witness third-party interjection fires cleanly")
T.equal(witnessTurn.actorID, "npc_witness", "highest-utility eligible third party wins turn")
T.equal(witnessTurn.interjectionOutcome, "witness_corroborates", "turn records witness_corroborates outcome")
T.equal(TurnPolicy.MAX_PARTICIPANTS, 4, "scene participant bound remains 4")
T.equal(Conversation.MAX_STEPS, 8, "scene step bound allows up to 8 turns")

T.finish("pnc_v7_world_event_dialogue_branching_smoke")
