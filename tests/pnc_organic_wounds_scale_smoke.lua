local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

local nowMs = 50000
local worldHour = 100
local woundEvents = 0
local eventCounts = {}
local spatialQueryCount = 0
local nearbyRowCount = 0
local npcCount = 0
local deliveryCount = 0
local replyQueueCount = 0
local liveBodies = {}
local npcRoster = {}

local function ensureHealth(record)
    record.health = type(record.health) == "table" and record.health or {
        current = 100, max = 100, state = "normal", body = { parts = {}, wounds = {} },
    }
    record.health.body = type(record.health.body) == "table" and record.health.body or { parts = {}, wounds = {} }
    record.health.current = tonumber(record.health.current) or 100
    record.health.max = tonumber(record.health.max) or 100
    record.health.state = record.health.state or "normal"
    return record.health
end

PNC = {
    Const = {
        DEFAULT_HP_MAX = 100,
        LIMP_HEALTH_RATIO = 0.40,
        LIMP_WALK_SPEED = 0.44,
        WOUND_BLEED_UPDATE_MS = 1000,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return dx * dx + dy * dy
        end,
        ForEachPlayer = function() end,
        Clamp = function(value, minimum, maximum)
            value = tonumber(value) or minimum
            return math.max(minimum, math.min(maximum, value))
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for key, child in pairs(value) do copy[key] = PNC.Core.DeepCopy(child) end
            return copy
        end,
    },
    Sandbox = {
        CanZombieWoundTransmitKnox = function() return false end,
        IsZombieSalivaTransmissible = function() return false end,
    },
    Registry = {
        Data = npcRoster,
        MarkDirty = function() end,
        Get = function(id) return npcRoster[tostring(id)] end,
        GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            spatialQueryCount = spatialQueryCount + 1
            nearbyRowCount = npcCount
            local rows = {}
            for _, record in pairs(npcRoster) do rows[#rows + 1] = record end
            return rows
        end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
        AreWarningAllies = function(observer, other)
            return observer ~= other and observer.factionID == other.factionID
        end,
        GetTeamKey = function(record) return tostring(record.factionID or "scale") end,
    },
    Health = {
        Ensure = ensureHealth,
        ApplyDamage = function(record, _, damage)
            local health = ensureHealth(record)
            local amount = tonumber(damage and damage.amount) or 0
            health.current = math.max(1, health.current - amount)
            if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
                PNC.NPCWounds.ApplyBodyDamage(record, amount, damage and damage.partId)
            end
            return true, health.current
        end,
    },
}

local Wounds = T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds.lua")
Wounds.Internal.Events = {
    emit = function(eventType)
        woundEvents = woundEvents + 1
        eventCounts[tostring(eventType)] = (eventCounts[tostring(eventType)] or 0) + 1
    end,
}
Wounds.Internal.EventTypes = {
    NPC_WOUNDED = "NPC_WOUNDED",
    NPC_WOUND_STATE_CHANGED = "NPC_WOUND_STATE_CHANGED",
    NPC_PHYSIOLOGY_BAND_CHANGED = "NPC_PHYSIOLOGY_BAND_CHANGED",
}
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHour end,
        getWorldAgeDaysSinceBegin = function() return worldHour / 24 end,
    }
end

local function makeNPC(id)
    local record = {
        id = id,
        name = "Scale Survivor " .. tostring(id),
        alive = true,
        presenceState = id % 2 == 0 and "live" or "abstract",
        x = ((id % 7) - 3) * 0.5,
        y = ((math.floor(id / 7) % 7) - 3) * 0.5,
        z = 0,
        factionID = "scale",
        social = { relationships = {}, personality = {} },
        runtime = {},
    }
    ensureHealth(record)
    Wounds.Ensure(record)
    npcRoster[tostring(id)] = record
    npcCount = npcCount + 1
    liveBodies[tostring(id)] = {
        getX = function() return record.x end,
        getY = function() return record.y end,
        getZ = function() return record.z end,
    }
    return record
end

-- H9-compatible cached-read workload: 200 records, 50 lightly wounded,
-- two clean projection reads and one physiology update per record.
local cohort = {}
for i = 1, 200 do
    local record = makeNPC(i)
    if i % 4 == 0 then
        record.health.body.openWoundCount = 1
        record.health.body.wounds.ForeArm_L = {
            id = "h9-" .. tostring(i), type = "laceration", partId = "ForeArm_L",
            severity = 25, bleedingRate = 0.02,
        }
        Wounds.InvalidateProjection(record, "h9_baseline_seed")
    end
    cohort[i] = record
end

local cleanStarted = os.clock()
local cleanCacheValid = true
for i = 1, #cohort do
    local first = Wounds.GetOrBuildProjection(cohort[i])
    local second = Wounds.GetOrBuildProjection(cohort[i])
    if first ~= second then cleanCacheValid = false end
    Wounds.UpdatePhysiology(cohort[i], 60, { worldHour = 100 })
end
local cleanMs = (os.clock() - cleanStarted) * 1000
T.truthy(cleanCacheValid, "clean projection reads reuse the cached table")
T.truthy(cleanMs < 250,
    "H9-compatible 200-NPC projection and physiology workload stays under 250ms (actual=" .. string.format("%.2fms", cleanMs) .. ")")

-- Event-heavy workload: 8 distinct injuries per NPC (1,600 real mutations).
-- Read the selected/aggregate projection after every event to exercise dirty
-- invalidation plus rebuild; count the production wound-event emission seam.
local woundTypes = { "scratch", "laceration", "burn", "fracture", "deep_wound", "deep_wound_glass", "bullet", "laceration" }
local parts = Wounds.PartOrder
local eventStarted = os.clock()
local mutationCount = 0
local allMutationsAccepted, allProjectionsValid = true, true
for i = 1, #cohort do
    local record = cohort[i]
    for j = 1, #woundTypes do
        local partId = parts[((j - 1) % #parts) + 1]
        local applied = Wounds.ApplyCombatDamage(record, nil, {
            amount = 0.25,
            partId = partId,
            woundType = woundTypes[j],
            attackerKind = "human",
            attackType = "melee",
        })
        if not applied then allMutationsAccepted = false end
        local projection = Wounds.GetOrBuildProjection(record)
        if not projection or not projection.injured then allProjectionsValid = false end
        mutationCount = mutationCount + 1
    end
end
local eventMs = (os.clock() - eventStarted) * 1000
T.truthy(allMutationsAccepted, "event-heavy injury mutations are accepted")
T.truthy(allProjectionsValid, "event-heavy mutations refresh injury projections")
T.equal(mutationCount, 1600, "event-heavy workload applies 1,600 injuries")
T.equal(eventCounts.NPC_WOUNDED or 0, mutationCount, "each accepted injury emits one wound event")

local postBurstStarted = os.clock()
local postBurstCacheValid = true
for i = 1, #cohort do
    local first = Wounds.GetOrBuildProjection(cohort[i])
    local second = Wounds.GetOrBuildProjection(cohort[i])
    if first ~= second then postBurstCacheValid = false end
    Wounds.UpdatePhysiology(cohort[i], 60, { worldHour = 101 })
end
local postBurstMs = (os.clock() - postBurstStarted) * 1000
T.truthy(postBurstCacheValid, "post-burst clean projection reads reuse the cache")

-- The committed H9 archive lacks the later debug/witness modules below. This
-- opt-in exit measures only the shared clean-read and event-burst segments.
if os.getenv("PNC_ORGANIC_WOUNDS_SCALE_H9_ONLY") == "1" then
    print(string.format(
        "WOUND_H9 n=%d lightly_wounded=50 injuries=%d clean_ms=%.2f burst_ms=%.2f post_burst_ms=%.2f budget_ms=250",
        #cohort, mutationCount, cleanMs, eventMs, postBurstMs))
    T.finish("pnc_organic_wounds_scale_smoke_h9")
    return
end

print(string.format(
    "WOUND_SCALE n=%d injuries=%d wound_events=%d all_events=%d clean_ms=%.2f burst_ms=%.2f post_burst_ms=%.2f",
    #cohort, mutationCount, eventCounts.NPC_WOUNDED or 0, woundEvents, cleanMs, eventMs, postBurstMs))
T.truthy(eventMs < 10000, "1,600-injury burst remains bounded below 10s (actual=" .. string.format("%.2fms", eventMs) .. ")")

-- Debug-random workload: drive the public debug injury API with an invalid
-- wound choice so its production random-type selection and normalized debug
-- provenance path are exercised for every NPC.
local debugCallouts, debugTypeCounts = 0, {}
PNC.Semantics = {
    CombatTargetCallouts = {
        OnNPCWoundReceived = function(_, hitSpec)
            debugCallouts = debugCallouts + 1
            if hitSpec and hitSpec.provenance == "debug" then
                debugTypeCounts[hitSpec.woundType] = (debugTypeCounts[hitSpec.woundType] or 0) + 1
            end
            return true
        end,
    },
}
local oldZombRand = ZombRand
local randomState = 0
ZombRand = function(limit)
    randomState = randomState + 7
    return randomState % math.max(1, tonumber(limit) or 1)
end
local debugStarted = os.clock()
local debugApplied = 0
for i = 1, #cohort do
    nowMs = nowMs + 5
    worldHour = worldHour + 0.001
    local partId = Wounds.PartOrder[((i - 1) % #Wounds.PartOrder) + 1]
    local applied = Wounds.ApplyDebugWound(cohort[i], nil, partId, "random", 0.1)
    if applied then debugApplied = debugApplied + 1 end
end
local debugMs = (os.clock() - debugStarted) * 1000
ZombRand = oldZombRand
local randomTypeCount = 0
for _ in pairs(debugTypeCounts) do randomTypeCount = randomTypeCount + 1 end
T.equal(debugApplied, 200, "debug-random API accepts one wound per NPC")
T.equal(debugCallouts, 200, "debug wounds use the normalized wound-received callback")
T.truthy(randomTypeCount >= 3, "debug-random workload selects multiple wound types")

-- Treatment/physiology workload: dirty a dressing, advance healing/dirtying,
-- and apply cold/wet exposure for the full cohort through owned wound APIs.
local treatmentStarted = os.clock()
local bandagedCount, transitionCount, physiologyCount = 0, 0, 0
for i = 1, #cohort do
    local record = cohort[i]
    local partId = Wounds.FindTreatableWound(record)
    if partId and Wounds.Bandage(record, partId, nowMs, { dirtyAfterWorldHours = 0.25 }) then
        bandagedCount = bandagedCount + 1
        Wounds.DebugAlmostDirty(record, partId)
    end
    local changed = Wounds.UpdatePhysiology(record, 4, {
        ambientTempC = -8,
        rainIntensity = 0.95,
        windIntensity = 0.8,
        clothingInsulation = 0.05,
        indoors = false,
    })
    if changed then physiologyCount = physiologyCount + 1 end
end
worldHour = worldHour + 1
nowMs = nowMs + 3600000
for i = 1, #cohort do
    local changed = Wounds.Update(cohort[i], nil, nowMs)
    if changed then transitionCount = transitionCount + 1 end
end
local treatmentMs = (os.clock() - treatmentStarted) * 1000
T.equal(bandagedCount, 200, "all cohort wounds accept bandage treatment")
T.truthy(physiologyCount > 0, "cold/wet exposure changes physiology bands")
T.truthy(transitionCount > 0, "wound updates process dirty-dressing/healing transitions")
T.truthy((eventCounts.NPC_PHYSIOLOGY_BAND_CHANGED or 0) > 0,
    "physiology band changes emit the production event")

-- Load the production witness/arbitration/delivery/Scene entrypoints. Keep
-- only transport and spatial visibility as measured test doubles.
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundProfile"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundRoles"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_WoundDelivery"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Wounds"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_InjuryScene"
local Callouts = PNC.Semantics.CombatTargetCallouts
local CalloutInternal = PNC.Semantics.CombatTargetCalloutsInternal
Callouts.ResolveSemanticLine = function(_, _, _, _, eventRef, _, _, options)
    return "A survivor is hurt.", {
        realizationID = "semantic.combat.injury.scale",
        presentationClass = "BARK",
        responsePlanID = options and options.responsePlanID,
        offerIDs = options and options.offerIDs,
        eventRef = eventRef,
    }
end
Callouts.DeliverBark = function()
    deliveryCount = deliveryCount + 1
    return 1
end
Callouts.EnqueueCustomReply = function(spec)
    replyQueueCount = replyQueueCount + 1
    if type(spec.onDelivered) == "function" then
        spec.speaker.runtime = spec.speaker.runtime or {}
        spec.onDelivered(spec.speaker, nowMs)
    end
    return true
end
Callouts.RecordHighSalienceInjuryMemory = function() end
Callouts.SeverityRank = function(value)
    local ranks = { none = 0, minor = 1, moderate = 2, severe = 3, critical = 4 }
    return ranks[tostring(value or "none")] or 0
end

local rawFindObservers = CalloutInternal.FindNearbyInjuryObservers
local maxNearbyObservers = 0
CalloutInternal.FindNearbyInjuryObservers = function(...)
    local rows = rawFindObservers(...)
    maxNearbyObservers = math.max(maxNearbyObservers, #rows)
    return rows
end
local rawSelectResponders = CalloutInternal.SelectWoundResponders
local maxArbitrationCandidates, maxSelectedResponders = 0, 0
CalloutInternal.SelectWoundResponders = function(mates, ...)
    maxArbitrationCandidates = math.max(maxArbitrationCandidates, #mates)
    local selected = rawSelectResponders(mates, ...)
    maxSelectedResponders = math.max(maxSelectedResponders, #selected)
    return selected
end

-- Actual debug wounds now run through OnNPCWoundReceived, pain Beat policy,
-- nearby observer selection, and bounded responder arbitration.
local witnessedDebugStarted = os.clock()
local witnessedDebugApplied = 0
for i = 1, 200 do
    nowMs = nowMs + 5000
    worldHour = worldHour + 0.01
    local partId = Wounds.PartOrder[((i + 4) % #Wounds.PartOrder) + 1]
    local applied = Wounds.ApplyDebugWound(cohort[i], nil, partId, "random", 0.1)
    if applied then witnessedDebugApplied = witnessedDebugApplied + 1 end
end
local witnessedDebugMs = (os.clock() - witnessedDebugStarted) * 1000
T.equal(witnessedDebugApplied, 200, "production callout path accepts each debug injury")
T.truthy(deliveryCount > 0, "production callout path delivers pain/injury Beats")
T.truthy(maxNearbyObservers <= 8, "production injury observer roster stays capped at eight")
T.truthy(maxArbitrationCandidates >= 2, "production responder arbitration considers multiple candidates")
T.truthy(maxSelectedResponders <= 2, "production responder arbitration selects at most two candidates")

-- Encounter observation runs the production bounded spatial query against
-- the 200-record roster, then commits at most one visible-condition Beat.
local rawRows = CalloutInternal.FindInjuryEncounterNeighbors(cohort[1], 6)
T.truthy(#rawRows <= 24, "production encounter neighbor list is capped at 24")
local beforeEncounterDeliveries = deliveryCount
local encounterStarted = os.clock()
local encountered = Callouts.OnInjuryEncounterCellChanged({
    id = "fresh-observer", name = "New Witness", x = cohort[1].x, y = cohort[1].y, z = 0,
    alive = true, skills = {}, runtime = {}, factionID = "scale",
}, nowMs + 1)
local encounterMs = (os.clock() - encounterStarted) * 1000
T.truthy(encountered, "fresh observer recognizes one nearby visible injury")
T.equal(deliveryCount - beforeEncounterDeliveries, 1,
    "one encounter transition opens no more than one observation Beat")

-- Ensure the two-responder path is reachable for a bonded survivor plus a
-- medic during a severe injury, while arbitrary candidate rosters stay capped.
local arbitrationTarget = {
    id = "scale-arbitration-target", alive = true, x = 0, y = 0,
    runtime = {}, health = { body = { openWoundCount = 1 } },
}
local bond = {
    id = "scale-bond", alive = true, x = 0.5, y = 0, skills = {}, runtime = {},
    social = { personality = { compassion = 0.8 }, relationships = {
        ["npc:" .. arbitrationTarget.id] = { state = "friend", approval = 40 },
    } },
}
local medic = {
    id = "scale-medic", alive = true, x = 1, y = 0, skills = { FirstAid = 3 }, runtime = {},
    social = { personality = { compassion = 0.5 }, relationships = {} },
}
local arbitrationCandidates = { bond, medic }
for i = 3, 8 do
    arbitrationCandidates[i] = {
        id = "scale-candidate-" .. tostring(i), alive = true, x = i, y = 0,
        skills = {}, runtime = {}, social = { personality = {}, relationships = {} },
    }
end
local severeProfile = {
    effectiveWoundTier = "fracture",
    physicalSeverityBand = "severe",
    severityBand = "severe",
    woundTierPriority = 4,
    totalWoundCount = 1,
    selectedWound = { bodyPart = "UpperLeg_L", woundType = "fracture", physicalSeverity = "severe" },
}
local arbitrationStarted = os.clock()
local selectedResponders = rawSelectResponders(arbitrationCandidates, arbitrationTarget, severeProfile, nowMs + 100)
local arbitrationMs = (os.clock() - arbitrationStarted) * 1000
T.equal(#selectedResponders, 2, "severe injury selects bonded and medic responders")
T.truthy(#arbitrationCandidates > #selectedResponders, "arbitration prunes the candidate roster")

-- Exercise the real Scene handoff and production SceneRuntime Open/Close APIs.
local SceneRuntime = require "PNC/ConvoEngine/Interaction/SceneRuntime"
SceneRuntime.ResetForTests({ clock = function() return nowMs end, maxActiveScenes = 4 })
local sceneStarted = os.clock()
local sceneOpened, sceneClosed = 0, 0
for i = 1, 200 do
    local helper = cohort[i]
    local injured = cohort[(i % #cohort) + 1]
    local scene = Callouts.HandoffInjuryBeatToScene(helper, "wound-scale:" .. tostring(i), {
        runtime = SceneRuntime,
        playerID = "player:scale",
        context = { playerID = "player:scale", player = { id = "player:scale", isPlayer = true } },
        participants = { injured },
        now = nowMs + i,
        ttlMs = 5000,
    })
    if scene then
        sceneOpened = sceneOpened + 1
        if SceneRuntime.Close(scene.id, "scale_complete") then sceneClosed = sceneClosed + 1 end
    end
end
local sceneMs = (os.clock() - sceneStarted) * 1000
T.equal(sceneOpened, 200, "production injury handoff opens 200 bounded Scenes")
T.equal(sceneClosed, 200, "production SceneRuntime closes each opened Scene")

-- Regression checks: continuous micro-healing must not spam sync/dirty/revision,
-- witness cache stays bounded on observer runtime, and undelivered encounters back off.
do
    local dirtyCount = 0
    local origDirty = PNC.Registry.MarkDirty
    PNC.Registry.MarkDirty = function(_, rsn)
        if rsn == "wounds" then dirtyCount = dirtyCount + 1 end
    end
    local healer = makeNPC(201)
    Wounds.ApplyCombatDamage(healer, nil, { amount = 10, partId = "UpperArm_L", woundType = "laceration", attackerKind = "npc" })
    Wounds.Bandage(healer, "UpperArm_L", nowMs, { bandageType = "Base.Bandage", dirtyAfterWorldHours = 24 })
    healer.runtime.forceSyncEvent = nil
    healer.runtime.lastWoundDirtyAt = nowMs
    local revBefore = healer.runtime.injuryRevision
    dirtyCount = 0
    for step = 1, 3 do
        nowMs = nowMs + 1000
        worldHour = worldHour + 0.05
        Wounds.Update(healer, nil, nowMs)
    end
    T.equal(healer.runtime.forceSyncEvent, nil, "partial healing ticks do not force network health sync")
    T.equal(healer.runtime.injuryRevision, revBefore, "partial healing ticks do not bump injuryRevision")
    T.equal(dirtyCount, 0, "partial healing throttles MarkDirty inside flush window")
    nowMs = nowMs + 6000
    worldHour = worldHour + 20.0
    Wounds.Update(healer, nil, nowMs)
    T.equal(healer.runtime.forceSyncEvent, "wound_healed", "completed wound healing emits forceSyncEvent")
    T.truthy((healer.runtime.injuryRevision or 0) > revBefore, "completed wound healing bumps injuryRevision")
    T.equal(dirtyCount, 1, "completed wound healing marks record dirty once")
    PNC.Registry.MarkDirty = origDirty

    local backoffObs = { id = "obs-reg", name = "Watcher", x = healer.x, y = healer.y, z = 0, alive = true, skills = {}, runtime = {} }
    local openInjured = makeNPC(202)
    openInjured.x, openInjured.y = healer.x + 1, healer.y
    Wounds.ApplyCombatDamage(openInjured, nil, { amount = 12, partId = "ForeArm_R", woundType = "laceration", attackerKind = "npc" })
    local origDeliver = Callouts.DeliverBark
    Callouts.DeliverBark = function() return 0 end
    local ok1, reason1 = Callouts.OnVisibleConditionObserved(backoffObs, openInjured, nowMs, { fromEncounter = true })
    T.equal(ok1, false, "undelivered encounter fails cleanly")
    T.equal(reason1, "observation_not_delivered", "undelivered encounter reports delivery failure")
    local ok2, reason2 = Callouts.OnVisibleConditionObserved(backoffObs, openInjured, nowMs + 1000, { fromEncounter = true })
    T.equal(ok2, false, "encounter repeats back off while undelivered")
    T.equal(reason2, "observation_backoff", "undelivered encounter enters 5s backoff")
    Callouts.DeliverBark = origDeliver
    local ok3 = Callouts.OnVisibleConditionObserved(backoffObs, openInjured, nowMs + 6000, { fromEncounter = true })
    T.truthy(ok3, "encounter observation recovers after backoff window")
    T.truthy(type(backoffObs.runtime.observedInjuries) == "table" and #(backoffObs.runtime.observedInjuries.order or {}) == 1,
        "witness observation cache lives on bounded observer runtime")
end

print(string.format(
    "WOUND_EVENTS debug_random_ms=%.2f random_types=%d treatment_physiology_ms=%.2f witnessed_debug_ms=%.2f raw_rows=%d neighbors=%d observer_cap=%d responder_candidates=%d max_responders=%d pair_selected=%d/8 encounter_ms=%.2f arbitration_ms=%.2f scenes=%d/%d scene_ms=%.2f deliveries=%d queued_replies=%d",
    debugMs, randomTypeCount, treatmentMs, witnessedDebugMs, nearbyRowCount, #rawRows,
    maxNearbyObservers, maxArbitrationCandidates, maxSelectedResponders,
    #selectedResponders, encounterMs, arbitrationMs, sceneOpened, sceneClosed,
    sceneMs, deliveryCount, replyQueueCount))
T.finish("pnc_organic_wounds_scale_smoke")
