local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})

local deliveredBeats = {}
local damageCalls = {}
local sceneFacts = {}

isServer = function() return true end
isClient = function() return false end

local worldAgeNow = 0
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldAgeNow end,
    }
end

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local ScopedWorldEvents = require "PsychopatzCore/WorldEvents/PsychopatzScopedWorldEvents"
local CoreWKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local records = {}
local factions = {}
local groups = {}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        TICK_ABSTRACT_MS = 1000,
        TICK_LIVE_COLD_MS = 500,
        TICK_LIVE_WARM_MS = 250,
        TICK_LIVE_HOT_MS = 75,
        SCHEDULER_MAX_RECORDS_PER_TICK = 24,
        SCHEDULER_MAX_JOBS_PER_TICK = 4,
    },
    EventTypes = {
        NPC_NEED_CRITICAL_DAMAGE = "NPC_NEED_CRITICAL_DAMAGE",
    },
    Core = {
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
        Now = function() return worldAgeNow * 3600000 end,
        NowWorldAgeHours = function() return worldAgeNow end,
        GenerateID = function(prefix) return tostring(prefix or "id") .. "_1" end,
        DeepCopy = function(val)
            if type(val) ~= "table" then return val end
            local out = {}
            for k, v in pairs(val) do out[k] = PNC.Core.DeepCopy(v) end
            return out
        end,
        ForEachPlayer = function(cb)
            cb({
                getX = function() return 100 end,
                getY = function() return 100 end,
                getZ = function() return 0 end,
                getOnlineID = function() return 1 end,
                getUsername = function() return "tester" end,
            })
        end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(player, npcId, ev, payload)
            deliveredBeats[#deliveredBeats + 1] = {
                npcId = npcId,
                eventType = ev,
                payload = payload,
            }
            return true
        end,
    },
    Registry = {
        Data = records,
        Get = function(id) return records[tostring(id or "")] end,
        MarkDirty = function() end,
    },
    Factions = {
        Get = function(id) return factions[tostring(id or "")] end,
        IsMobileGroup = function(f) return type(f) == "table" and f.isMobile == true end,
        SetNeeds = function(id, state)
            local f = factions[tostring(id or "")]
            if not f then return nil end
            f.needs = state
            return state
        end,
    },
    Health = {
        Ensure = function(rec)
            rec.health = rec.health or { current = 100, max = 100, body = { wholeBodyAilments = {} } }
            rec.health.body = rec.health.body or { wholeBodyAilments = {} }
            rec.health.body.wholeBodyAilments = rec.health.body.wholeBodyAilments or {}
            return rec.health
        end,
        ApplyDamage = function(rec, body, spec)
            local amt = tonumber(spec and spec.amount) or 0
            rec.health.current = math.max(0, (tonumber(rec.health.current) or 100) - amt)
            damageCalls[#damageCalls + 1] = {
                npcId = rec.id,
                amount = amt,
                damageType = spec and spec.type,
            }
            return true
        end,
    },
    DirectorConfig = {
        RESOURCE_CATEGORIES = { "food", "water", "ammo", "medical", "materials" },
        Scavenging = {
            DURATION_MIN_HOURS = 1,
            DURATION_MAX_HOURS = 2,
            BASE_YIELD_SCALE = 0.22,
            MIN_REMAINING_FACTOR = 0.04,
            VARIANCE_MIN = 0.90,
            VARIANCE_MAX = 1.10,
            EFFECTIVE_SCAVENGER_EXPONENT = 0.62,
            DEPLETION_BASE = 2.5,
            DEPLETION_PER_YIELD = 0.07,
            MAX_YIELD_PER_RESOURCE = 40,
            NEED_YIELD_BONUS = 0.35,
            NEED_RESTORE_PER_RESOURCE = { food = 0.7, water = 0.9 },
        },
        Population = {
            GROUP_ARCHETYPE_WEIGHTS = {
                REFUGEE = 0.28,
                LOOTER = 0.20,
                WANDERER = 0.25,
                TRADER = 0.15,
                SCAVENGER = 0.12,
            },
        },
    },
    HoomansWorldView = {
        WorldAgeHours = function() return worldAgeNow end,
        Touch = function() end,
        Emit = function() end,
    },
    AbstractGroups = {
        Get = function(id) return groups[tostring(id or "")] end,
    },
    AbstractLocations = {},
    AbstractResourceNeeds = {
        Get = function() return { food = 0.5, water = 0.5 } end,
    },
    PopulationSectors = {
        GroupIDs = {},
        Get = function(id) return { id = id, regionID = "region_knox" } end,
        WorldSeed = function() return 123456, "PNC-123456" end,
        WeightedChoice = function(weights) return "LOOTER" end,
    },
    PopulationBudget = {
        WorldAgeWeights = function()
            return { refugee = 1.0, established = 1.0 }
        end,
    },
    Sandbox = {
        PlayerOwnedNPCNeedMortalityEnabled = function() return true end,
    },
}

-- Load shared & server modules under test
T.load("ProjectHoomans", "shared", "PNC/Core/Scheduling/PNC_Scheduler.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsUtils.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/DispositionProjection.lua")
T.load("ProjectHoomans", "shared", "PNC/WorldKnowledge/PNC_WorldKnowledge.lua")
T.load("ProjectHoomans", "shared", "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/ResponseCatalog/Social_Conflict.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/LocalResponse_Core.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/LocalResponse_Text.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/LocalResponse_Questions_Facts.lua")

-- Minimal SpeechRealization stub if needed
PNC.ConvoEngine.SpeechRealization = {
    Apply = function(spec) return spec end,
}

-- Scene adopter stub to observe optional scene follow-up
PNC.ConvoEngine.InteractionSceneAdopters = {
    OnWorldKnowledgeFact = function(spec)
        sceneFacts[#sceneFacts + 1] = spec
        return true
    end,
}

T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticSpeechTransport.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractScavengeResolver.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_ScopedWorldEventDirector.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_ChronologyMilestones.lua")
T.load("ProjectHoomans", "server", "PNC/Needs/PNC_NeedHealthConsequences.lua")
PNC.GroupNeeds = { Internal = {}, Listeners = {} }
T.load("ProjectHoomans", "server", "PNC/Needs/GroupNeeds/PNC_GroupNeeds_Listeners.lua")
T.load("ProjectHoomans", "server", "PNC/Needs/GroupNeeds/PNC_GroupNeeds_State.lua")
T.load("ProjectHoomans", "server", "PNC/Needs/GroupNeeds/PNC_GroupNeeds_Update.lua")
PNC.GroupGenerator = { Internal = {} }
T.load("ProjectHoomans", "server", "PNC/Director/Population/GroupGenerator/PNC_GroupGenerator_Selection.lua")

local Milestones = PNC.Semantics.ChronologyMilestones
local EventDirector = PNC.ScopedWorldEventDirector
local Projection = PNC.ConvoEngine.DispositionProjection
local Scavenge = PNC.AbstractScavengeResolver
local GroupNeeds = PNC.GroupNeeds
local GroupSelection = PNC.GroupGenerator
local WorldKnowledge = PNC.WorldKnowledge
local ResolveKnowledge = PNC.ConvoEngine.LocalResponse.Internal.ResolveKnowledgeQuestion

local function resetAll()
    CoreWKG.Reset({ maxFacts = 64, maxRefs = 32 })
    ScopedWorldEvents.Reset()
    EventDirector.ResetRuntime()
    Milestones.ResetRuntime()
    PNC.Semantics.SpeechTransport.ResetRuntime()
    deliveredBeats = {}
    damageCalls = {}
    sceneFacts = {}
    records = {}
    factions = {}
    groups = {}
    PNC.Registry.Data = records
end

-- =========================================================================
-- 1. Personal chronology milestones fire exactly once without OnTick polling
-- =========================================================================
resetAll()
worldAgeNow = 0
local npcBrave = {
    id = "npc_brave",
    coreActorID = "actor_brave",
    name = "Alex Mercer",
    alive = true,
    presenceState = "live",
    x = 100, y = 100, z = 0,
    identitySeed = 101,
    survivalStartHours = 0,
    social = {
        personality = {
            bravery = 0.85,
            confidence = 0.85,
            aggression = 0.40,
            compassion = 0.30,
            sociability = 0.65,
            forgiveness = 0.55,
            materialism = 0.25,
            loyalty = 0.70,
        },
    },
    health = { current = 100, max = 100, body = { wholeBodyAilments = {} } },
}
local npcTimid = {
    id = "npc_timid",
    coreActorID = "actor_timid",
    name = "Sam Vance",
    alive = true,
    presenceState = "live",
    x = 102, y = 100, z = 0,
    identitySeed = 202,
    survivalStartHours = 0,
    social = {
        personality = {
            bravery = 0.25,
            confidence = 0.25,
            aggression = 0.25,
            compassion = 0.85,
            sociability = 0.35,
            forgiveness = 0.65,
            materialism = 0.85,
            loyalty = 0.50,
        },
    },
    health = { current = 100, max = 100, body = { wholeBodyAilments = {} } },
}
records[npcBrave.id] = npcBrave
records[npcTimid.id] = npcTimid

-- Initial eval at 0h: no milestones yet
local r0 = Milestones.EvaluateActor(npcBrave, 0)
T.equal(#r0, 0, "no milestones triggered at 0h")

-- At 720h: first_week (168h) + first_month (720h) trigger once
worldAgeNow = 720
local r720 = Milestones.EvaluateActor(npcBrave, 720)
T.equal(#r720, 2, "first_week and first_month triggered at 720h")
T.equal(r720[1].milestoneID, "first_week", "first_week triggers first")
T.equal(r720[2].milestoneID, "first_month", "first_month triggers second")
T.equal(npcBrave.lastMilestoneHours, 720, "compact watermark updated to 720h")
T.equal(npcBrave.milestoneCount, 2, "compact milestoneCount updated")
T.truthy(#deliveredBeats >= 1, "chronology beat delivered via SpeechTransport")
T.truthy(#sceneFacts >= 1, "first_month scene follow-up triggered")

-- Re-evaluating at 720h or 800h must NOT re-fire already passed milestones
local r720Again = Milestones.EvaluateActor(npcBrave, 720)
T.equal(#r720Again, 0, "first_month never fires twice at same timestamp")
local r800 = Milestones.EvaluateActor(npcBrave, 800)
T.equal(#r800, 0, "first_month never fires twice at 800h")

-- Verify WorldKnowledge fact emitted with provenance = "experienced"
local braveFactQuery = WorldKnowledge.QueryActorFact(npcBrave, { topic = "first_month" }, 720)
T.equal(braveFactQuery.epistemicStatus, "known", "milestone fact is known to actor")
T.equal(braveFactQuery.provenance, "experienced", "milestone fact provenance is experienced")

-- At 8760h: first_season + first_year trigger once
worldAgeNow = 8760
local r8760 = Milestones.EvaluateActor(npcBrave, 8760)
T.equal(#r8760, 2, "first_season and first_year trigger at 8760h")
T.equal(r8760[2].milestoneID, "first_year", "first_year triggers at 8760h")
T.equal(Milestones.EvaluateActor(npcBrave, 8760 + 24) and #Milestones.EvaluateActor(npcBrave, 8760 + 24), 0,
    "first_year never fires twice")

-- =========================================================================
-- 2. Two NPCs react differently to same milestone/event; base personality immutable
-- =========================================================================
local braveSavedBravery = npcBrave.social.personality.bravery
local timidSavedBravery = npcTimid.social.personality.bravery

local timid720 = Milestones.EvaluateActor(npcTimid, 720)
T.equal(#timid720, 2, "timid NPC triggers milestones at 720h")
T.truthy(r720[2].demeanorDelta.moraleHope > timid720[2].demeanorDelta.moraleHope,
    "confident/brave NPC gains stronger moraleHope from milestone than timid NPC")

-- Register active bandit_bonanza and check personality-modulated temporaryDemeanor
local evRaider = ScopedWorldEvents.Register({
    eventType = "bandit_bonanza",
    scope = "global",
    startsAt = 720,
    endsAt = 780,
    severity = 0.80,
    source = "hoomans-world-event",
    effects = EventDirector.CATALOG.bandit_bonanza.effects,
}, { nowHours = 720 })
T.truthy(evRaider, "bandit_bonanza registered")

local demBrave = EventDirector.ProjectActorDemeanor(npcBrave, 725)
local demTimid = EventDirector.ProjectActorDemeanor(npcTimid, 725)
T.truthy(demTimid.vigilanceFear > demBrave.vigilanceFear,
    "timid NPC gets higher vigilanceFear than brave NPC for identical bandit_bonanza")

local projBrave = Projection.Resolve(npcBrave)
local projTimid = Projection.Resolve(npcTimid)
T.truthy(projBrave.effectiveDisposition.bravery > projTimid.effectiveDisposition.bravery,
    "projected effectiveDisposition reflects personality + demeanor")
T.equal(npcBrave.social.personality.bravery, braveSavedBravery,
    "base social.personality is never mutated on brave NPC")
T.equal(npcTimid.social.personality.bravery, timidSavedBravery,
    "base social.personality is never mutated on timid NPC")

-- Bounded PumpBatch across registry
local evaluatedCount = Milestones.PumpBatch(725, 1)
T.equal(evaluatedCount, 1, "PumpBatch respects bounded budget=1")

-- =========================================================================
-- 3. Deterministic replay & mutual exclusion & bounded active cap
-- =========================================================================
resetAll()
local evA1 = EventDirector.EvaluateBucket(240, { worldSeed = "KnoxSeed-77", scope = "global", timeBucket = 10 })
T.truthy(evA1, "first deterministic replay produces an event")
resetAll()
local evA2 = EventDirector.EvaluateBucket(240, { worldSeed = "KnoxSeed-77", scope = "global", timeBucket = 10 })
T.truthy(evA2, "second deterministic replay produces an event")
T.equal(evA1.eventID, evA2.eventID, "same worldSeed+scope+timeBucket yields identical eventID")
T.equal(evA1.eventType, evA2.eventType, "same worldSeed+scope+timeBucket yields identical eventType")

-- Different buckets can yield different events
local seenTypes = {}
for b = 1, 15 do
    resetAll()
    local evB = EventDirector.EvaluateBucket(b * 24, { worldSeed = "KnoxSeed-77", scope = "global", timeBucket = b })
    if evB then seenTypes[evB.eventType] = true end
end
local distinctCount = 0
for _ in pairs(seenTypes) do distinctCount = distinctCount + 1 end
T.truthy(distinctCount >= 2, "different timeBuckets yield different event types")

-- Mutual exclusion: if food_crisis is active, agricultural_surplus cannot be selected
resetAll()
ScopedWorldEvents.Register({
    eventType = "food_crisis",
    scope = "global",
    startsAt = 0,
    endsAt = 72,
    source = EventDirector.SOURCE,
    effects = EventDirector.CATALOG.food_crisis.effects,
}, { nowHours = 10 })
for b = 1, 20 do
    local picked = EventDirector.SelectEventForBucket("KnoxSeed-77", "global", "global", b, { nowHours = 10 })
    T.truthy(not picked or (picked.id ~= "agricultural_surplus" and picked.id ~= "food_crisis"),
        "mutual exclusion blocks agricultural_surplus while food_crisis is active")
end

-- Active cap <= 6
resetAll()
for i = 1, 10 do
    EventDirector.EvaluateBucket(i * 24, {
        worldSeed = "CapSeed",
        scope = "region",
        scopeID = "region_" .. tostring(i),
        timeBucket = i,
    })
end
local activeOwned = ScopedWorldEvents.QueryActive({ source = EventDirector.SOURCE }, 240)
T.truthy(#activeOwned <= 6, "active world events capped at <= 6")

-- =========================================================================
-- 4. Causal simulation hooks: food_crisis -> GroupNeeds + Scavenge + NeedHealthConsequences
-- =========================================================================
resetAll()
worldAgeNow = 100
local hungryNPC = {
    id = "npc_hungry",
    name = "Hungry Survivor",
    alive = true,
    health = { current = 100, max = 100, body = { wholeBodyAilments = {} } },
}
records[hungryNPC.id] = hungryNPC
factions["fac_mobile"] = {
    id = "fac_mobile",
    name = "Scavengers",
    isMobile = true,
    regionID = "region_west",
    memberIDs = { [hungryNPC.id] = true },
    needs = { hunger = 0.90, thirst = 0.20, fatigue = 0.10, lastUpdateWorldAge = 100 },
}
local testGroup = {
    id = "grp_mobile",
    factionId = "fac_mobile",
    regionID = "region_west",
    memberIds = { hungryNPC.id },
    location = { id = "loc_store", x = 100, y = 100, z = 0 },
}
groups[testGroup.id] = testGroup
local testLoc = {
    id = "loc_store",
    regionID = "region_west",
    scavengedLevel = 0,
    resourcePotential = { food = 100, water = 100, ammo = 50, medical = 50, materials = 50 },
}
local scavengeAction = { seed = 9999, startedAt = 100 }

local baseRates = GroupNeeds.GetRates("fac_mobile", 100)
local baseScavenge = Scavenge.Calculate(testGroup, testLoc, scavengeAction)

-- Activate food_crisis
ScopedWorldEvents.Register({
    eventType = "food_crisis",
    scope = "region",
    scopeID = "region_west",
    startsAt = 100,
    endsAt = 172,
    severity = 0.80,
    source = EventDirector.SOURCE,
    effects = EventDirector.CATALOG.food_crisis.effects,
}, { nowHours = 100 })

local crisisRates = GroupNeeds.GetRates("fac_mobile", 100)
local crisisScavenge = Scavenge.Calculate(testGroup, testLoc, scavengeAction)

T.truthy(crisisRates.hunger > baseRates.hunger,
    "food_crisis increases GroupNeeds hunger rate")
T.truthy(crisisScavenge.yields.food < baseScavenge.yields.food,
    "food_crisis lowers AbstractScavengeResolver food yield")

-- Advance GroupNeeds so hunger hits 1.0 and NeedHealthConsequences drives starvation damage naturally
GroupNeeds.Update("fac_mobile", 20, "crisis_tick", nil, nil, 120)
T.equal(factions["fac_mobile"].needs.hunger, 1.0, "group hunger reaches 1.0")
T.truthy(hungryNPC.health.body.wholeBodyAilments.starvation ~= nil,
    "NeedHealthConsequences naturally builds starvation ailment on member")
T.truthy(#damageCalls > 0 and hungryNPC.health.current < 100,
    "NeedHealthConsequences naturally applies starvation damage without direct kill")

-- =========================================================================
-- 5. bandit_bonanza increases LOOTER weight in GroupGenerator_Selection
-- =========================================================================
local baseWeights = GroupSelection.GetArchetypeWeights("psector_0_0", 120)
ScopedWorldEvents.Register({
    eventType = "bandit_bonanza",
    scope = "region",
    scopeID = "region_knox",
    startsAt = 120,
    endsAt = 180,
    severity = 0.80,
    source = EventDirector.SOURCE,
    effects = EventDirector.CATALOG.bandit_bonanza.effects,
}, { nowHours = 120 })
local raiderWeights = GroupSelection.GetArchetypeWeights("psector_0_0", 120)
T.truthy(raiderWeights.LOOTER > baseWeights.LOOTER,
    "bandit_bonanza increases LOOTER weight in GroupGenerator_Selection")

-- =========================================================================
-- 6. Expired events stop affecting demeanor and simulation while historical facts remain
-- =========================================================================
worldAgeNow = 200
local pruned = ScopedWorldEvents.PruneExpired(200)
T.truthy(pruned >= 2, "expired world events pruned on boundary")
local postRates = GroupNeeds.GetRates("fac_mobile", 200)
local postScavenge = Scavenge.Calculate(testGroup, testLoc, { seed = 9999, startedAt = 200 })
local postWeights = GroupSelection.GetArchetypeWeights("psector_0_0", 200)
T.near(postRates.hunger, baseRates.hunger, 0.0001, "expired food_crisis stops affecting GroupNeeds")
T.equal(postScavenge.yields.food, baseScavenge.yields.food, "expired food_crisis stops affecting scavenge yield")
T.near(postWeights.LOOTER, baseWeights.LOOTER, 0.0001, "expired bandit_bonanza stops affecting LOOTER weight")

-- Check historical WorldKnowledge fact persists even after event expires
resetAll()
local evHist, _, histFact = EventDirector.EvaluateBucket(0, {
    worldSeed = "HistSeed",
    scope = "global",
    timeBucket = 0,
})
T.truthy(evHist and histFact, "world event and historical fact created")
local archivedCount = ScopedWorldEvents.PruneExpired(evHist.endsAt + 10)
T.equal(archivedCount, 1, "world event expired and removed from active registry")
local demAfterExpiry = EventDirector.ProjectActorDemeanor(npcBrave, evHist.endsAt + 10)
T.equal(demAfterExpiry.scarcityAnxiety, 0, "expired event stops affecting demeanor")
T.equal(demAfterExpiry.vigilanceFear, 0, "expired event stops affecting fear demeanor")
T.truthy(CoreWKG.Ledger.Get(CoreWKG.LedgerState, histFact.factID) ~= nil,
    "durable historical WorldKnowledge fact remains in ledger after event expires")

-- =========================================================================
-- 7. WorldKnowledge epistemic gating: known vs uncertain (rumor) vs unknown
-- =========================================================================
resetAll()
local evCrisis, _, crisisFact = EventDirector.EvaluateBucket(24, {
    worldSeed = "EpistemicSeed",
    scope = "global",
    timeBucket = 1,
})
T.truthy(evCrisis and crisisFact, "world event fact published")

local alice = { id = "npc_alice", coreActorID = "actor_alice", name = "Alice", alive = true }
local bob = { id = "npc_bob", coreActorID = "actor_bob", name = "Bob", alive = true }
local carol = { id = "npc_carol", coreActorID = "actor_carol", name = "Carol", alive = true }
local dave = { id = "npc_dave", coreActorID = "actor_dave", name = "Dave", alive = true }

-- Alice directly experiences it; Bob receives public authority notice; Carol hears rumor; Dave knows nothing
EventDirector.GrantActorEventFact(alice, evCrisis, "experienced", 25)
WorldKnowledge.AcquirePublicFact(bob, crisisFact.factID, { authorized = true, learnedAt = 25 })
WorldKnowledge.PropagateConversation(alice, carol, { authorized = true, channel = "conversation", now = 26 })

local aliceStatus = WorldKnowledge.CheckEpistemicStatus(alice, crisisFact.factID)
local bobStatus = WorldKnowledge.CheckEpistemicStatus(bob, crisisFact.factID)
local carolStatus = WorldKnowledge.CheckEpistemicStatus(carol, crisisFact.factID)
local daveStatus = WorldKnowledge.CheckEpistemicStatus(dave, crisisFact.factID)

T.equal(aliceStatus, "known", "experienced fact resolves to known")
T.equal(bobStatus, "known", "public fact resolves to known")
T.equal(carolStatus, "uncertain", "told rumor resolves to uncertain")
T.equal(daveStatus, "unknown", "uninformed actor resolves to unknown (no omniscience)")

-- Dialogue question resolution respects epistemic gating
local irQuery = {
    subject = "NPC_KNOWLEDGE",
    target = { text = evCrisis.eventType },
    slots = { topic = evCrisis.eventType },
}
local ansAlice = ResolveKnowledge(irQuery, {}, { npcRecord = alice })
local ansCarol = ResolveKnowledge(irQuery, {}, { npcRecord = carol })
local ansDave = ResolveKnowledge(irQuery, {}, { npcRecord = dave })

T.equal(ansAlice.templateID, "question.knowledge.known", "Alice answers as known")
T.equal(ansAlice.uncertainty, "known", "Alice uncertainty is known")
T.equal(ansCarol.templateID, "question.knowledge.uncertain", "Carol answers with rumor template")
T.equal(ansCarol.uncertainty, "uncertain", "Carol rumor is not treated as objective truth")
T.equal(ansDave.templateID, "question.knowledge.unknown", "Dave refuses to fabricate unknown facts")
T.equal(ansDave.uncertainty, "unknown", "Dave uncertainty is unknown")

T.finish("pnc_chronology_world_events_demeanor_smoke")
