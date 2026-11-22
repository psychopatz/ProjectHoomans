local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "common_lua" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
})

local now = 10000
local worldHours = 8.0
local worldEvents = {}

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}

Events = {
    OnGameBoot = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    EveryTenMinutes = { Add = function() end },
    OnTick = { Add = function() end },
}

getText = function(key) return key end

local function makePNCBase()
    local records = {}
    local seq = 0
    return {
        Core = {
            Now = function() return now end,
            GenerateID = function(prefix)
                seq = seq + 1
                return tostring(prefix or "id") .. "-" .. tostring(seq)
            end,
            DeepCopy = function(v)
                if type(v) ~= "table" then return v end
                local out = {}
                for k, val in pairs(v) do
                    if type(val) == "table" then
                        local inner = {}
                        for ik, iv in pairs(val) do inner[ik] = iv end
                        out[k] = inner
                    else
                        out[k] = val
                    end
                end
                return out
            end,
            LogWarn = function() end,
            LogInfo = function() end,
        },
        Const = {
            ORDER_CAMP = "camp",
            ORDER_ROAM = "roam",
            ORDER_GUARD = "guard",
            JOB_AT_CAMP = "AtCamp",
            CAMP_STOP_DISTANCE = 0.45,
            GUARD_STOP_DISTANCE = 0.55,
            GUARD_REACHED_DISTANCE = 0.55,
            GUARD_ENGAGE_RADIUS = 3,
            ROAM_REACHED_DISTANCE = 0.8,
        },
        Registry = {
            Data = records,
            Get = function(id) return records[tostring(id or "")] end,
            ForEach = function(visitor)
                for _, rec in pairs(records) do visitor(rec) end
            end,
            GetLiveZombie = function(id)
                local rec = records[tostring(id or "")]
                return rec and rec.liveZombie or nil
            end,
            MarkDirty = function() end,
        },
    }
end

PNC = makePNCBase()
local AutonomyRegistry = T.load("ProjectHoomans", "common_lua", "PNC/AutonomyAd/Registry.lua")
T.truthy(AutonomyRegistry and AutonomyRegistry.GetAd("ad.rest_seat"),
    "compiled ad.rest_seat must load from AutonomyAd Registry")
T.truthy(AutonomyRegistry.GetSituation("situation.camp_chat"),
    "compiled situation.camp_chat must load from AutonomyAd Registry")

local Scorer = T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/PNC_AutonomyScorer.lua")

-- 1. Scorer curves, traits, moods, distance, hysteresis, cooldowns, zero-alloc Debug OFF, and <= 64 cap.
local sociablyBored = {
    id = "npc-1",
    alive = true,
    x = 10,
    y = 10,
    needs = { fatigue = 0.4, boredom = 0.5 },
    traits = { Sociable = true },
    moods = { bored = 1.0 },
    runtime = {},
}
local reserved = {
    id = "npc-2",
    alive = true,
    x = 10,
    y = 10,
    needs = { fatigue = 0.0, boredom = 0.0 },
    traits = { Reserved = true },
    runtime = {},
}

local loungeAd = AutonomyRegistry.GetAd("ad.social_lounge")
local score1, band1, diag1 = Scorer.ScoreAd(sociablyBored, loungeAd, { x = 10, y = 10 }, now, nil, true)
T.truthy(score1 ~= nil and score1 > 0.9,
    "sociable bored NPC should score high on ad.social_lounge")
T.equal(band1, "OPTIONAL", "ad.social_lounge must remain inside OPTIONAL band")
T.truthy(diag1 and diag1.traitDelta > 0 and diag1.moodDelta > 0,
    "diagnostics must report positive trait and mood deltas")

local scoreOff, bandOff, diagOff = Scorer.ScoreAd(sociablyBored, loungeAd, { x = 10, y = 10 }, now, nil, false)
T.truthy(scoreOff ~= nil and diagOff == nil,
    "ScoreAd with includeDiagnostics=false must allocate zero diagnostics")

local lowScore, lowReason = Scorer.ScoreAd(reserved, loungeAd, { x = 10, y = 10 }, now, nil, false)
T.equal(lowScore, nil, "reserved zero-boredom NPC below hysteresis.enter must be rejected")
T.equal(lowReason, "BELOW_HYSTERESIS_ENTER",
    "inactive low score must fail with BELOW_HYSTERESIS_ENTER")

-- Active hysteresis retains between exit (0.18) and enter (0.35), rejects below exit (0.18).
local stickyRecord = {
    id = "npc-sticky",
    alive = true,
    x = 0,
    y = 0,
    needs = { boredom = 0.0 }, -- curve value at 0.0 is 0.25 (between exit=0.18 and enter=0.35)
    runtime = {},
}
local sActive, bActive = Scorer.ScoreAd(stickyRecord, loungeAd, { x = 0, y = 0 }, now, "ad.social_lounge", false)
T.truthy(sActive ~= nil and bActive == "OPTIONAL",
    "hysteresis must retain active ad between exit and enter thresholds")
stickyRecord.traits = { Reserved = true } -- 0.25 - 0.20 + 0.05 = 0.10 < exit(0.18)
local sExit, rExit = Scorer.ScoreAd(stickyRecord, loungeAd, { x = 0, y = 0 }, now, "ad.social_lounge", false)
T.equal(sExit, nil, "score below hysteresis.exit must drop active ad")
T.equal(rExit, "BELOW_HYSTERESIS_EXIT", "expected BELOW_HYSTERESIS_EXIT reason")

-- Cooldown after RecordFailure
Scorer.RecordFailure("npc-1", "ad.social_lounge", "test_fail", now, 5000)
local cdScore, cdReason = Scorer.ScoreAd(sociablyBored, loungeAd, { x = 10, y = 10 }, now + 1000, nil, false)
T.equal(cdScore, nil, "cooldown must suppress failed ad before expiry")
T.equal(cdReason, "COOLDOWN_ACTIVE", "expected COOLDOWN_ACTIVE reason")
local postCdScore = Scorer.ScoreAd(sociablyBored, loungeAd, { x = 10, y = 10 }, now + 5001, nil, false)
T.truthy(postCdScore ~= nil, "ad must recover once cooldown expires")
Scorer.Reset()

-- Cap at 64 evaluations
local savedAds = AutonomyRegistry.ads
local manyAds = {}
local ctxCount = 0
for i = 1, 80 do
    local id = string.format("ad.cap_%02d", i)
    manyAds[id] = {
        id = id,
        band = "IDLE",
        curve = { { value = 0, score = 0.6 }, { value = 1, score = 0.6 } },
        hysteresis = { enter = 0.2, exit = 0.1, critical = 0.9 },
        maxRange = 20,
    }
end
AutonomyRegistry.ads = manyAds
local scoredMany = Scorer.EvaluateAll(sociablyBored, function()
    ctxCount = ctxCount + 1
    return { x = 10, y = 10 }
end, now, { includeDiagnostics = false })
T.equal(ctxCount, 64, "EvaluateAll must cap ad evaluation at 64 ads")
T.equal(#scoredMany, 64, "EvaluateAll must return at most 64 candidates")
AutonomyRegistry.ads = savedAds

-- Promotion hydration
local promoRecord = { id = "npc-promo", needs = { hunger = 0.85, fatigue = 0.70 }, runtime = {} }
Scorer.RecordFailure("npc-promo", "ad.rest_seat", "old_fail", now, 60000)
local hOk, hState = Scorer.HydrateOnPromotion(promoRecord, 4, now + 100)
T.truthy(hOk and hState and hState.hydrated == true,
    "HydrateOnPromotion must mark record hydrated")
T.truthy(promoRecord.needs.hunger < 0.85 and promoRecord.needs.fatigue < 0.70,
    "HydrateOnPromotion must apply bounded baseline need relief")
T.falsy(Scorer.IsInCooldown("npc-promo", "ad.rest_seat", now + 100),
    "HydrateOnPromotion must clear stale cooldowns")

-- 2. CoPresenceService: SpatialIndex.QueryNPCs + Registry.Data distance-first fallback + SceneAdopters routing
local submittedSocial = {}
local SceneAdoptersStub = {
    SubmitSocial = function(spec)
        submittedSocial[#submittedSocial + 1] = spec
        return true, "ACCEPTED", { sceneId = "scene-1" }
    end,
}
PNC.ConvoEngine = { Interaction = { SceneAdopters = SceneAdoptersStub } }
local CoPresence = T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/PNC_CoPresenceService.lua")

-- Build 36 far away peers with alphabetically early IDs + 1 close peer "npc-z-near"
for i = 1, 36 do
    local fid = string.format("npc-a-far-%02d", i)
    PNC.Registry.Data[fid] = { id = fid, alive = true, x = 500 + i, y = 500, z = 0, runtime = {} }
end
PNC.Registry.Data["npc-hero"] = {
    id = "npc-hero", alive = true, x = 10, y = 10, z = 0,
    orderSpec = { kind = "camp" },
    runtime = {},
}
PNC.Registry.Data["npc-z-near"] = {
    id = "npc-z-near", alive = true, x = 12, y = 11, z = 0,
    runtime = {},
}

local cpOk, cpReason = CoPresence.TryTriggerForNPC(PNC.Registry.Data["npc-hero"], now, {
    adId = "ad.roam_patrol",
})
T.truthy(cpOk == true and cpReason == "SUBMITTED",
    "Registry.Data fallback must find nearby peer regardless of alphabetical sort")
T.equal(#submittedSocial, 1, "CoPresence must submit once into SceneAdopters")
T.equal(submittedSocial[1].situationId, "situation.camp_chat",
    "roam/camp context must pick situation.camp_chat")
T.equal(submittedSocial[1].roles["npc-hero"], "initiator", "role binding must assign initiator")
T.equal(submittedSocial[1].roles["npc-z-near"], "responder", "role binding must assign responder")

-- Cooldown check
local cpCdOk, cpCdReason = CoPresence.TryTriggerForNPC(PNC.Registry.Data["npc-hero"], now + 1000, {
    adId = "ad.roam_patrol",
})
T.falsy(cpCdOk, "CoPresence situation must respect cooldown")
T.equal(cpCdReason, "SITUATION_COOLDOWN", "expected SITUATION_COOLDOWN")

-- SpatialIndex.QueryNPCs path
CoPresence.Reset()
local queryCalls = 0
PNC.SpatialIndex = {
    QueryNPCs = function(x, y, radius)
        queryCalls = queryCalls + 1
        return {
            PNC.Registry.Data["npc-hero"],
            { id = "npc-spatial-1", alive = true, x = x + 1, y = y, z = 0, runtime = {} },
            { id = "npc-spatial-2", alive = true, x = x, y = y + 2, z = 0, runtime = {} },
        }
    end,
}
local spOk = CoPresence.TryTriggerForNPC(PNC.Registry.Data["npc-hero"], now + 100000, {
    situationId = "situation.lounge_hangout",
})
T.truthy(spOk and queryCalls == 1,
    "CoPresenceService must query PNC.SpatialIndex.QueryNPCs when available")
T.equal(submittedSocial[2].convoFamilyId, "agree",
    "lounge hangout situation must use compiled convoFamilyId agree")
PNC.SpatialIndex = nil

-- 3. Tasking + 8-band precedence wall + Claims + zero read-only seat reservation leaks
PNC.Registry.Data = {}
local npc = {
    id = "npc-task-1",
    alive = true,
    x = 10,
    y = 10,
    z = 0,
    orderSpec = { kind = "colony_home" },
    needs = { fatigue = 0.85, boredom = 0.90 },
    traits = { Sociable = true, Lazy = true },
    moods = { bored = 1.0, tired = 1.0 },
    runtime = {},
}
PNC.Registry.Data[npc.id] = npc
PNC.Registry.Get = function(id) return PNC.Registry.Data[tostring(id or "")] end
PNC.Registry.ForEach = function(visitor)
    for _, r in pairs(PNC.Registry.Data) do visitor(r) end
end
PNC.CompanionCommands = { IsCompanion = function() return true end }
PNC.HomeDutyService = {
    GetBase = function() return { id = "base-1" } end,
    IsAtHome = function(rec)
        return rec and rec.orderSpec and rec.orderSpec.kind == "colony_home"
    end,
}

local reservations = {}
local acquireCalls = 0
local startFacilityCalls = 0
local stopFacilityCalls = 0
PNC.FacilityService = {
    ListByCapability = function()
        return { { id = "fac-living-1", x = 11, y = 11, z = 0 } }
    end,
    AcquireActivity = function(baseId, npcId)
        acquireCalls = acquireCalls + 1
        local resId = "res-" .. tostring(acquireCalls)
        reservations[resId] = true
        return {
            facility = { id = "fac-living-1", baseId = baseId },
            facilityId = "fac-living-1",
            resourceKey = "chair-1",
            resourceKind = "chair",
            reservationId = resId,
            target = { x = 11, y = 11, z = 0 },
        }
    end,
}
PNC.FacilityReservations = {
    ByID = reservations,
    Release = function(id) reservations[id] = nil; return true end,
}
PNC.FacilityJobs = {
    Start = function(rec, facility, cap, opts)
        startFacilityCalls = startFacilityCalls + 1
        rec.runtime.facilityActivity = {
            facilityId = facility.id,
            capability = cap,
            automatic = true,
            phase = "SITTING",
            reservationId = opts.acquired and opts.acquired.reservationId,
        }
        return true
    end,
    TickRecord = function() return true end,
    Stop = function(rec)
        stopFacilityCalls = stopFacilityCalls + 1
        rec.runtime.facilityActivity = nil
        return true
    end,
}

package.preload["PNC/Tasking/PNC_WorkTaskProvider"] = function() return {} end
package.preload["PNC/Tasking/PNC_CorpseHaulService"] = function() return {} end
package.preload["PNC/Tasking/PNC_TaskRequestService"] = function() return {} end
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskPriority.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskLeaseService.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskProviders.lua")

T.equal(PNC.LivingRoomService, nil, "legacy PNC.LivingRoomService must be retired")
T.equal(PNC.AmbientFacilityService, nil, "legacy PNC.AmbientFacilityService must be retired")
T.equal(PNC.RoamingSeat, nil, "legacy PNC.RoamingSeat must be retired")
T.equal(PNC.RoamAmbient, nil, "legacy PNC.RoamAmbient must be retired")
T.truthy(PNC.AutonomyExecutors and PNC.AutonomyExecutors.FacilitySeat
    and PNC.AutonomyExecutors.RoamingSeat and PNC.AutonomyExecutors.RoamAmbient,
    "AutonomyTaskProvider must fold FacilitySeat, RoamingSeat, RoamAmbient under PNC.AutonomyExecutors")

T.truthy(PNC.Tasking.WATCHDOG_DOMAINS.autonomy == true,
    "autonomy must be registered in WATCHDOG_DOMAINS")
T.equal(PNC.Tasking.Events.Types.AMBIENT_OPPORTUNITY, "AMBIENT_OPPORTUNITY",
    "AMBIENT_OPPORTUNITY task event type must be registered")

-- Read-only GetCandidates MUST NOT reserve any seats!
local cands = PNC.AutonomyTaskProvider.GetCandidates(npc.id, { at = now })
T.truthy(#cands >= 1, "eligible home companion must receive autonomy candidates")
T.equal(acquireCalls, 0,
    "GetCandidates must be read-only and never allocate FacilityReservations")

-- Add a NORMAL_WORK competitor and verify 8-band precedence wall blocks OPTIONAL/IDLE autonomy!
local mockWorkState = { assigned = false, cancelled = false }
PNC.Tasking.Commands.RegisterProvider("mock_work", {
    GetCandidates = function(npcId)
        if not mockWorkState.available then return {} end
        return { {
            taskId = "mock:work:1",
            npcId = npcId,
            kind = "CONSTRUCT",
            operation = "CONSTRUCT",
            sourceDomain = "mock_work",
            sourceRef = "work-1",
            precedence = "NORMAL_WORK",
            capability = "work.construction",
            urgency = 0.05, -- even very low intra-band urgency!
        } }
    end,
    Validate = function() return mockWorkState.available == true end,
    Assign = function() mockWorkState.assigned = true; return { claimKeys = nil } end,
    Start = function() return true end,
    CanContinue = function() return mockWorkState.available == true end,
    Tick = function() return true end,
    Cancel = function() mockWorkState.assigned = false; mockWorkState.cancelled = true; return true end,
    Complete = function() mockWorkState.assigned = false; return true end,
})

-- Evaluate when no work exists -> autonomy wins & acquires Claim + Seat reservation!
mockWorkState.available = false
local evalOk, lease = PNC.Tasking.Commands.Reevaluate(npc.id, "autonomy_idle")
T.truthy(evalOk and lease and lease.sourceDomain == "autonomy",
    "autonomy must acquire lease when higher bands have no tasks")
T.equal(acquireCalls, 1, "Assign must acquire facility seat exactly once")
T.truthy(npc.runtime.taskLeaseId == lease.leaseId
    and npc.runtime.facilityActivity
    and npc.runtime.facilityActivity.taskLeaseId == lease.leaseId,
    "Provider.Start must stamp taskLeaseId onto runtime and facilityActivity")
local leaseClaims = PNC.Tasking.Claims.ListByLease(lease.leaseId)
T.equal(#leaseClaims, 1, "autonomy lease must hold unified Tasking.Claims entry")

-- Query BuildBrain attaches activeBand, claims, autonomyDiagnostics
local brain = PNC.Tasking.Queries.BuildBrain(npc.id)
T.equal(brain.activeBand, "OPTIONAL", "BuildBrain must report active OPTIONAL band")
T.equal(#brain.leaseClaims, 1, "BuildBrain must expose leaseClaims")
T.truthy(brain.autonomyDiagnostics and #brain.autonomyDiagnostics.candidates >= 1,
    "BuildBrain must expose autonomyDiagnostics candidates")
-- Verify GetDiagnostics didn't leak reservations either!
T.equal(acquireCalls, 1, "GetDiagnostics must be read-only without calling AcquireSeat")

-- Now introduce NORMAL_WORK with urgency=0.05 -> must preempt OPTIONAL autonomy!
mockWorkState.available = true
local preOk, workLease = PNC.Tasking.Commands.Reevaluate(npc.id, "work_arrived")
T.truthy(preOk and workLease and workLease.sourceDomain == "mock_work",
    "NORMAL_WORK (urgency 0.05) must strictly preempt OPTIONAL autonomy")
T.equal(stopFacilityCalls, 1, "preempted autonomy must stop underlying facility seat")
T.equal(#PNC.Tasking.Claims.ListByLease(lease.leaseId), 0,
    "preempted autonomy lease must release Tasking.Claims")
T.equal(npc.runtime.autonomyAdId, nil, "preemption must clear autonomyAdId")

-- And high-scoring OPTIONAL autonomy cannot preempt active NORMAL_WORK
local reEvalOk, afterLease = PNC.Tasking.Commands.Reevaluate(npc.id, "autonomy_check")
T.truthy(reEvalOk and afterLease and afterLease.sourceDomain == "mock_work",
    "OPTIONAL autonomy must never preempt NORMAL_WORK")
PNC.Tasking.Commands.CancelLease(workLease.leaseId, "test_done")
mockWorkState.available = false

-- 4. Test roam_ambient ticket ownership without self-preemption + Behavior Ownership guard!
local roamNpc = {
    id = "npc-roam-ambient",
    alive = true,
    x = 20,
    y = 20,
    z = 0,
    orderSpec = { kind = "roam" },
    needs = { boredom = 0.8 },
    runtime = {
        roaming = { phase = "idle", idleSince = now - 5000 },
    },
}
PNC.Registry.Data[roamNpc.id] = roamNpc
PNC.AnimationScenes = {
    Request = function(rec, _, sceneId)
        rec.runtime.animationScene = { id = sceneId }
        return true
    end,
    Start = function(rec, sceneId)
        rec.runtime.animationScene = { id = sceneId }
        return true
    end,
    Interrupt = function(rec) rec.runtime.animationScene = nil end,
    ClearScene = function(rec) rec.runtime.animationScene = nil end,
}
local roamExec = PNC.AutonomyExecutors.RoamAmbient
roamExec.GetWorldAgeHours = function() return 8.0 end
roamExec.LiveEligible = function(rec) return rec ~= nil and rec.alive ~= false end

local roamEvalOk, roamLease = PNC.Tasking.Commands.Reevaluate(roamNpc.id, "roam_idle")
T.truthy(roamEvalOk and roamLease and roamLease.sourceDomain == "autonomy",
    "roam companion must run ambient action via autonomy provider")
T.truthy(roamNpc.runtime.roamAmbient
    and roamNpc.runtime.roamAmbient.taskLeaseId == roamLease.leaseId,
    "roamAmbient state must record active taskLeaseId")
T.truthy(PNC.AutonomyTaskProvider.Tick(roamLease) == true,
    "Provider.Tick must step roamAmbient without self-preemption on taskLeaseId")

PNC.BehaviorSystem = PNC.BehaviorSystem or { Internal = { TickOwnership = {} } }
PNC.BehaviorSystem.Internal = PNC.BehaviorSystem.Internal or {}
PNC.BehaviorSystem.Internal.TickOwnership = PNC.BehaviorSystem.Internal.TickOwnership or {}
PNC.BehaviorSystem.Internal.TickOwnership.puppetOperaOwnsBehavior = function()
    return false
end
T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Ownership.lua")
local directTicks = 0
local origRoamTick = roamExec.Tick
roamExec.Tick = function(...)
    directTicks = directTicks + 1
    return origRoamTick(...)
end
local tickRun = PNC.BehaviorSystem.Internal.TickOwnership.Run
T.truthy(tickRun(roamNpc, nil, now),
    "TickOwnership.Run must return true while active autonomy lease holds roamAmbient")
T.equal(directTicks, 0,
    "TickOwnership.Run must not double-tick roamAmbient owned by active autonomy lease")
-- Now simulate released lease while orphan state still lingers
roamNpc.runtime.roamAmbient.taskLeaseId = "dead-lease-999"
tickRun(roamNpc, nil, now)
T.equal(roamNpc.runtime.roamAmbient, nil,
    "TickOwnership.Run must stop orphaned roamAmbient whose taskLeaseId was released")
roamExec.Tick = origRoamTick
PNC.Tasking.Commands.CancelLease(roamLease.leaseId, "test_roam_done")

-- 5. Behavior callers route solely through AMBIENT_OPPORTUNITY & Server_SubsystemPumps has zero LivingRoomService fallback
local emittedAmbientEvents = 0
local unsub = PNC.Tasking.Events.Subscribe("AMBIENT_OPPORTUNITY", function()
    emittedAmbientEvents = emittedAmbientEvents + 1
end)
PNC.Core.Distance = function(x1, y1, x2, y2)
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
end
PNC.BehaviorCommon = {
    ClearCombatTarget = function() end,
    HaltMovement = function() end,
    MoveRecord = function() end,
}
PNC.BehaviorRoaming = {
    Internal = {
        AreaMovement = {
            Core = PNC.Core,
            Const = PNC.Const,
            Common = PNC.BehaviorCommon,
            ChooseAreaGoal = function() end,
            SyncAreaBounds = function() end,
            AreaStateChanged = function() return false end,
            HasActivePassage = function() return false end,
            BeginAreaPause = function() return false end,
        },
    },
}
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Roaming_AreaMovement.lua")
local roamBehaviorState = { phase = "idle", waitUntil = now + 5000, goalX = 20, goalY = 20, goalZ = 0 }
PNC.BehaviorRoaming.Internal.AreaMovement.Run(
    { id = "npc-br", alive = true, runtime = {} },
    nil,
    { kind = "roam" },
    roamBehaviorState,
    now
)
T.equal(emittedAmbientEvents, 1,
    "AreaMovement must emit AMBIENT_OPPORTUNITY instead of polling RoamAmbient/RoamingSeat when autonomy active")
if unsub then PNC.Tasking.Events.Unsubscribe(unsub) end

local serverPumpSrc = T.read("ProjectHoomans", "server", "PNC/Server/Server/PNC_Server_SubsystemPumps.lua")
T.falsy(serverPumpSrc:find("LivingRoomService", 1, true),
    "Server_SubsystemPumps must not contain retired LivingRoomService fallback")

-- 6. Colonist Debug UI rows + ColonistWindow debug tab taskBrainNpcID request
local DebugRows = T.load("ProjectHoomans", "client", "PNC/UI/Colonist/PNC_ColonistDebugRows.lua")
local noBrainRows = DebugRows.Build({ id = "npc-1", role = "colonist", needs = {}, runtime = {} }, {}, {})
for i = 1, #noBrainRows do
    T.falsy(tostring(noBrainRows[i].key or ""):find("^debug_ai_"),
        "ColonistDebugRows must emit zero AI debug rows when person.taskBrain is absent")
end

local withBrainRows = DebugRows.Build({
    id = "npc-1",
    role = "colonist",
    needs = {},
    runtime = {},
    taskBrain = brain,
}, {}, {})
local seenKeys = {}
for i = 1, #withBrainRows do
    seenKeys[withBrainRows[i].key] = withBrainRows[i]
end
T.truthy(seenKeys.debug_ai_band, "ColonistDebugRows must render active AI band row")
T.contains(seenKeys.debug_ai_band.detail, "OPTIONAL",
    "AI band row must include OPTIONAL band")
T.truthy(seenKeys.debug_ai_claims, "ColonistDebugRows must render Tasking Claims row")
T.truthy(seenKeys.debug_ai_autonomy_cand_1, "ColonistDebugRows must render top Autonomy candidate row")

local windowSrc = T.read("ProjectHoomans", "client", "PNC/UI/Colonist/PNC_ColonistWindow.lua")
T.contains(windowSrc, 'self.tab == "task" or self.tab == "debug"',
    "ColonistWindow must request taskBrainNpcID on debug tab without enabling Debug-OFF polling")

T.finish("pnc_u3_autonomy_copresence_smoke")
