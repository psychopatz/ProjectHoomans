local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "common_lua" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

local clock = 200000
local tickListeners = {}
local soundListeners = {}

Events = {
    OnGameBoot = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    EveryTenMinutes = { Add = function() end },
    OnTick = {
        Add = function(fn)
            tickListeners[#tickListeners + 1] = fn
        end,
    },
    OnWorldSound = {
        Add = function(fn)
            soundListeners[#soundListeners + 1] = fn
        end,
    },
}
getText = function(key) return key end

-- ---------------------------------------------------------------------------
-- Core capability bootstrap & isolated U6 runtime fixtures
-- ---------------------------------------------------------------------------
require "PsychopatzCore/Composition/PC_SharedComposition"
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local okShock, shockFacade = PsychopatzCore.Require("core.shocking_events", "u6_scale_smoke")
local ShockBus = (okShock and type(shockFacade) == "table" and shockFacade)
    or PsychopatzCore.ShockingEventBus
T.truthy(ShockBus and type(ShockBus.Emit) == "function",
    "Core ShockingEventBus capability loads cleanly")
ShockBus.Reset()

local seq = 0
local records = {}
local cancelledLeases = 0
local haltedBodies = 0
local releasedOutputs = {}
local cancelledInputs = {}
local releasedTools = {}

local function shallowCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, val in pairs(v) do
        if type(val) == "table" then
            out[k] = shallowCopy(val)
        else
            out[k] = val
        end
    end
    return out
end

PNC = {
    Core = {
        Now = function() return clock end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix)
            seq = seq + 1
            return tostring(prefix or "id") .. "-" .. tostring(seq)
        end,
        DeepCopy = shallowCopy,
        ShallowCopy = function(t)
            local o = {}
            for k, v in pairs(t or {}) do o[k] = v end
            return o
        end,
        Log = function() end,
        LogWarn = function() end,
        LogInfo = function() end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        DOMAIN_DELTA_PROTOCOL = 1,
        ORDER_CAMP = "camp",
        ORDER_ROAM = "roam",
        ORDER_GUARD = "guard",
        ORDER_FOLLOW = "follow",
        ORDER_LUMBER = "lumber",
        BODY_TAG_VERSION = 1,
    },
    EventTypes = {
        TASK_LEASE_CREATED = "TASK_LEASE_CREATED",
        TASK_LEASE_RELEASED = "TASK_LEASE_RELEASED",
        WORK_ORDER_QUEUED = "WORK_ORDER_QUEUED",
        WORK_ORDER_CANCELLED = "WORK_ORDER_CANCELLED",
        WORK_ORDER_COMPLETED = "WORK_ORDER_COMPLETED",
    },
    Registry = {
        Data = records,
        Get = function(id) return records[tostring(id or "")] end,
        ForEach = function(cb)
            for _, rec in pairs(records) do cb(rec) end
        end,
        GetLiveZombie = function(id)
            local rec = records[tostring(id or "")]
            return rec and rec.liveZombie or nil
        end,
        MarkDirty = function() end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y, r)
            local out = {}
            local r2 = (r or 16) * (r or 16)
            for _, rec in pairs(records) do
                if rec.alive ~= false and rec.presenceState == "live"
                    and rec.x ~= nil and rec.y ~= nil
                then
                    local dx = rec.x - x
                    local dy = rec.y - y
                    if dx * dx + dy * dy <= r2 then
                        out[#out + 1] = rec
                    end
                end
            end
            table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
            return out
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    BehaviorCommon = {
        HaltMovement = function()
            haltedBodies = haltedBodies + 1
            return true
        end,
    },
    IndividualNeeds = {
        Queries = {
            GetNeed = function(rec, needKey)
                return rec and rec.needs and rec.needs[needKey] or 50
            end,
        },
    },
    WorkOutputService = {
        ReleaseOutputCapacity = function(order)
            releasedOutputs[#releasedOutputs + 1] = order and order.id
            return true
        end,
        FlushAbstractDelivery = function() return true, "COMPLETED" end,
        TickLiveDelivery = function() return true, true, "COMPLETED" end,
    },
    WorkInputService = {
        Cancel = function(order)
            cancelledInputs[#cancelledInputs + 1] = order and order.id
            return true
        end,
    },
    WorkItemService = {
        OperationHasRequirements = function() return false end,
        Release = function(record, op)
            releasedTools[#releasedTools + 1] = tostring(record.id) .. ":" .. tostring(op)
            return true
        end,
    },
    ColonyStorageService = {},
    SettlementRepository = {
        Load = function() end,
        State = { bases = {} },
        GetFacility = function() return nil end,
    },
    PZFarming = {},
    PlantingCatalog = {},
    Farming = { FARMER_JOB = "Farmer", FACILITY_ID = "farm_plot" },
    Fishing = { FISHING_JOB = "Fishing" },
    WorldEffectService = {
        Register = function() end,
        RegisterProvider = function() end,
    },
}

-- Load compiled common-layer IR catalogs (CodeBuilder U2 + U5a outputs)
local AutonomyRegistry = T.load("ProjectHoomans", "common_lua", "PNC/AutonomyAd/Registry.lua")
local ReactionRegistry = T.load("ProjectHoomans", "common_lua", "PNC/ReactionPolicy/Registry.lua")
local ScenarioRegistry = T.load("ProjectHoomans", "common_lua", "PNC/WorkScenario/Registry.lua")
local ConversationRegistry = T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.truthy(AutonomyRegistry and AutonomyRegistry.GetAd("ad.rest_seat"), "AutonomyAd registry loaded")
T.truthy(ReactionRegistry and ReactionRegistry.GetReaction("reaction.explosion_flee"), "ReactionPolicy registry loaded")
T.truthy(ScenarioRegistry and ScenarioRegistry.GetScenario("scenario.evening_lounge"), "WorkScenario registry loaded")
T.truthy(ConversationRegistry and type(ConversationRegistry.DIRECTOR_INDEX) == "table", "ConvoEngine DIRECTOR_INDEX loaded")

local Diagnostics = T.load("ProjectHoomans", "shared", "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_Runtime.lua")
local Priority = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskPriority.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskIntent.lua")
local Leases = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskLeaseService.lua")
PNC.Performance = PNC.Performance or { SafeCall = function(_, fn, ...) return true, fn(...) end }
PNC.Tasking = {
    Commands = {},
    Queries = {},
    Events = {},
    Inbox = {},
    Providers = {},
    Executors = {},
    Internal = {},
    Dirty = { queue = {}, byNPC = {}, head = 1, tail = 0, pendingCount = 0 },
    Diagnostics = {
        byNPC = {},
        counters = {
            reevaluations = 0, candidates = 0, preemptions = 0,
            facilityLookups = 0, executorTicks = 0, callbackFailures = 0, eventEmits = 0,
        },
        recentFailures = {},
        recentEvents = {},
    },
}
local Claims = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking_Claims.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/Tasking/PNC_Tasking_Core.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/Tasking/PNC_Tasking_EventInbox.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/Tasking/PNC_Tasking_Queries.lua")
local Tasking = PNC.Tasking

local Scorer = T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/PNC_AutonomyScorer.lua")
local PerceptionSvc = T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_PerceptionService.lua")
local Secondary = T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_SecondaryChannel.lua")
local Agitation = T.load("ProjectHoomans", "server", "PNC/Agitation/PNC_AgitationService.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/Reactions/PNC_ReactionPolicyEvaluator.lua")
local ReactionProvider = T.load("ProjectHoomans", "server", "PNC/Tasking/Reactions/PNC_ShockingReactionTaskProvider.lua")

local SocialWitness = T.load("ProjectHoomans", "server", "PNC/Social/PNC_SocialWitnessService.lua")
local JointLease = T.load("ProjectHoomans", "server", "PNC/ConvoEngine/Social/PNC_JointSceneLeaseService.lua")
local DialogueDirector = T.load("ProjectHoomans", "server", "PNC/ConvoEngine/Social/PNC_DialogueMicroBeatDirector.lua")
local StreetInteraction = T.load("ProjectHoomans", "server", "PNC/ConvoEngine/Social/PNC_StreetInteractionService.lua")

-- ===========================================================================
-- 1. O(N)/O(L): 200 abstract SurvivorWorld actors + 6 promoted live NPCs
-- ===========================================================================
for i = 1, 200 do
    local absId = "npc-abs-" .. tostring(i)
    records[absId] = {
        id = absId,
        alive = true,
        presenceState = "abstract",
        x = 500 + i,
        y = 500,
        z = 0,
        runtime = {},
        social = Social.NewState(),
    }
end

local liveNPCs = {}
for i = 1, 6 do
    local liveId = "npc-live-" .. tostring(i)
    local rec = {
        id = liveId,
        alive = true,
        presenceState = "live",
        x = 10 + i * 2,
        y = 10,
        z = 0,
        liveZombie = { id = "body:" .. liveId },
        needs = { fatigue = 80, boredom = 85 },
        runtime = { facingDirX = 1, facingDirY = 0 },
        social = Social.NewState(),
    }
    records[liveId] = rec
    liveNPCs[i] = rec
end

T.equal(Agitation.GetActiveCount(), 0, "sparse AgitationService holds 0 entries for unagitated abstract pool")
T.equal(Scorer.MAX_ADS_EVALUATED, 64, "AutonomyScorer enforces <= 64 ad evaluation cap")
T.near(Priority.SAME_BAND_MARGIN, 0.08, 1e-6, "TaskPriority preserves SAME_BAND_MARGIN = 0.08")

local autonomyScored = Scorer.EvaluateAll(liveNPCs[1], nil, clock)
T.truthy(#autonomyScored >= 1, "compiled AutonomyScorer evaluates promoted live NPC cleanly")
for i = 1, #autonomyScored do
    local band = autonomyScored[i].band
    T.truthy(band == "OPTIONAL" or band == "IDLE",
        "AutonomyScorer strictly confines ads to OPTIONAL/IDLE bands")
end
for i = 1, 200 do
    local absRec = records["npc-abs-" .. tostring(i)]
    T.equal(absRec.runtime.secondaryChannel, nil, "abstract NPC holds zero SecondaryChannel state")
    T.equal(JointLease.GetForNPC(absRec.id), nil, "abstract NPC holds zero JointSceneLease state")
    T.equal(DialogueDirector.GetActorTelemetry(absRec.id), nil, "abstract NPC holds zero DialogueDirector state")
end

-- 8-band precedence wall: max-score OPTIONAL (0.99) NEVER preempts NORMAL_WORK or HARD_EMERGENCY
T.equal(Priority.Compare(
    { precedence = "NORMAL_WORK", urgency = 0.05, taskId = "work:1" },
    { precedence = "OPTIONAL", urgency = 0.99, taskId = "auto:1" }
), 1, "8-band wall prevents OPTIONAL(0.99) from outranking NORMAL_WORK(0.05)")
T.falsy(Priority.CanPreempt(
    { precedence = "NORMAL_WORK", urgency = 0.05 },
    { precedence = "OPTIONAL", urgency = 0.99 }
), "CanPreempt forbids OPTIONAL from preempting NORMAL_WORK")

-- ===========================================================================
-- 2. O(live): 32-threat dense crowd, <= 8/tick LOS budget & cleanup teardown
-- ===========================================================================
PerceptionSvc.Reset()
local losCalls = 0
local clearTargets = { ["threat-1"] = true, ["threat-2"] = true, ["threat-3"] = true }
PNC.Perception = {
    CanSeeWorldObject = function(_, obj)
        losCalls = losCalls + 1
        return clearTargets[obj.id] == true, clearTargets[obj.id] and "clear" or "blocked"
    end,
}

local guardRec = liveNPCs[1]
guardRec.orderSpec = { kind = "guard" }
for i = 1, 32 do
    local tid = "threat-" .. tostring(i)
    PerceptionSvc.QueueLOSCheck(guardRec, {
        id = tid,
        getX = function() return guardRec.x + 4 + i * 0.1 end,
        getY = function() return guardRec.y end,
        getZ = function() return 0 end,
    }, tid, nil, { at = clock })
end
T.equal(PerceptionSvc.PumpLOSQueue(clock, 8), 8, "LOS queue processes at most 8 checks on tick 1")
T.equal(PerceptionSvc.PumpLOSQueue(clock + 100, 8), 8, "LOS queue processes at most 8 checks on tick 2")
T.equal(losCalls, 16, "budgeted LOS queue executed exactly 16 checks over 2 ticks for 32 queued threats")
T.equal(#PerceptionSvc.GetClues(guardRec, clock + 100), 3,
    "blocked LOS threats never leak into ClueMemory")

-- Verify demotion/reanimation/cleanup releases SecondaryChannel, Claims, JointLease, and Agitation
local animVars = {}
local fakeBody = {
    getX = function() return 10.0 end,
    getY = function() return 10.0 end,
    faceLocationF = function() end,
    setVariable = function(_, k, v) animVars[k] = v end,
}
PNC.NPCVoice = {
    MODE_WORLD = "world",
    PlayWorld = function() return 1 end,
    Stop = function() return true end,
}
Secondary.SetAlertLevel(liveNPCs[2], "tense")
Secondary.SetPosture(liveNPCs[2], "crouch")
Agitation.ApplyTrigger(liveNPCs[2], "weapon_draw", "threat-1", clock)
JointLease.Acquire({
    participants = { liveNPCs[2], liveNPCs[3] },
    speakerId = liveNPCs[2].id,
    responderId = liveNPCs[3].id,
}, clock)
T.truthy(JointLease.GetForNPC(liveNPCs[2].id) ~= nil, "JointSceneLease active before demotion cleanup")

Secondary.ClearForRecord(liveNPCs[2], fakeBody)
Agitation.Clear(liveNPCs[2].id)
JointLease.OnParticipantUnavailable(liveNPCs[2].id, "demoted_abstract", clock)
Claims.ReleaseByOwner(liveNPCs[2].id, "demoted_abstract")
T.equal(liveNPCs[2].runtime.secondaryChannel, nil, "demotion clears SecondaryChannel")
T.equal(animVars.PNCAlertLevel, "calm", "demotion resets Build 42 PNCAlertLevel var")
T.equal(animVars.PNCPosture, "relaxed", "demotion resets Build 42 PNCPosture var")
T.equal(JointLease.GetForNPC(liveNPCs[2].id), nil, "demotion aborts active JointSceneLease")
T.equal(Claims.Get("joint_scene:npc:" .. liveNPCs[2].id), nil, "demotion releases Tasking.Claims")
T.equal(Agitation.GetActiveCount(), 0, "demotion prunes sparse AgitationService state")

-- ===========================================================================
-- 3. ShockingEventBus burst (200 events -> 128 cap, 1000ms dedup) & HARD_EMERGENCY abort
-- ===========================================================================
ShockBus.Reset()
ReactionProvider.Reset()

local firstEv, firstStatus = ShockBus.Emit({
    eventType = "shock.gunfire",
    x = 20, y = 10, z = 0,
    radius = 25, severity = 90,
    dedupKey = "burst-gun-1",
    at = clock,
})
local secondEv, secondStatus = ShockBus.Emit({
    eventType = "shock.gunfire",
    x = 20, y = 10, z = 0,
    radius = 25, severity = 90,
    dedupKey = "burst-gun-1",
    at = clock + 200,
})
T.truthy(firstEv and firstStatus == "emitted", "first shocking event accepted")
T.equal(secondStatus, "deduplicated", "1000ms dedup window suppresses duplicate burst event")
T.equal(secondEv and secondEv.id, firstEv and firstEv.id, "dedup returns original event id")

for i = 1, 200 do
    ShockBus.Emit({
        eventType = "shock.suspicious_sound",
        x = 20 + (i % 5), y = 10, z = 0,
        radius = 20, severity = 50,
        dedupKey = "burst:" .. tostring(i),
        at = clock + i,
    })
end
T.equal(ShockBus.GetStats().activeCount, 128, "PsychopatzShockingEventBus FIFO cap bounds queue to 128 events")
local nearbyBurst = ShockBus.QueryNear(20, 10, 0, 50, { at = clock + 250 })
T.truthy(#nearbyBurst <= 128, "QueryNear returns bounded nearby events")

-- HARD_EMERGENCY TASK_LEASE_CREATED aborts an active JointSceneLease cleanly
JointLease.Reset()
DialogueDirector.Reset()
local leaseOk = JointLease.Acquire({
    participants = { liveNPCs[3], liveNPCs[4] },
    speakerId = liveNPCs[3].id,
    responderId = liveNPCs[4].id,
}, clock + 300)
T.truthy(leaseOk, "JointSceneLease acquired prior to HARD_EMERGENCY shock")
Tasking.Events.Emit("TASK_LEASE_CREATED", {
    npcId = liveNPCs[3].id,
    entityId = "shock:gun:1",
    payload = { taskId = "shock:gun:1", sourceDomain = "reaction", precedence = "HARD_EMERGENCY" },
}, { enqueue = false })
T.equal(JointLease.GetForNPC(liveNPCs[3].id), nil,
    "HARD_EMERGENCY reaction lease aborts active JointSceneLease")
T.equal(Claims.Get("joint_scene:npc:" .. liveNPCs[4].id), nil,
    "HARD_EMERGENCY abort cleans partner JointScene claims")

-- ===========================================================================
-- 4. O(dirty) Colony Work unification (4 reconcilers, zero OnTick bypass, AbortOrder cleanup)
-- ===========================================================================
T.load("ProjectHoomans", "shared", "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions.lua")
T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkRepository.lua")
PNC.WorkRepository.Import(nil)

local Work = T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkService.lua")
local Runner = T.load("ProjectHoomans", "server", "PNC/Production/WorkService/PNC_WorkToilRunner.lua")

PNC.FarmingService = { Data = { zones = {} }, Internal = {}, HasActionableWork = function() return false end }
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingWorkAdapter.lua")
PNC.FishingService = { Data = { jobs = {}, zones = {} }, ValidateZone = function() return false end }
T.load("ProjectHoomans", "server", "PNC/Fishing/PNC_FishingWorkAdapter.lua")
local LumberService = T.load("ProjectHoomans", "server", "PNC/Lumber/PNC_LumberService.lua")
LumberService.Data = { zones = {}, zoneOrder = {}, trees = {}, jobs = {} }
LumberService.Loaded = true
T.load("ProjectHoomans", "server", "PNC/Lumber/PNC_LumberWorkAdapter.lua")
local tickCountBeforeCorpse = #tickListeners
local CorpseService = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_CorpseHaulService.lua")
T.equal(#tickListeners, tickCountBeforeCorpse,
    "CorpseHaulService adds zero Events.OnTick bypass loops when WorkService active")

T.equal(type(Work.ReconcileHandlers.FARMING), "function", "WorkService owns FARMING reconciler")
T.equal(type(Work.ReconcileHandlers.FISHING), "function", "WorkService owns FISHING reconciler")
T.equal(type(Work.ReconcileHandlers.LUMBER), "function", "WorkService owns LUMBER reconciler")
T.equal(type(Work.ReconcileHandlers.CORPSE_HAUL), "function", "WorkService owns CORPSE_HAUL reconciler")

-- O(dirty): throttle skips redundant reconciler passes when clean
local corpseRuns = 0
Work.ReconcileHandlers.CORPSE_HAUL = function()
    corpseRuns = corpseRuns + 1
    return 0
end
Work.NextPassAt = 0
Work.Tick(clock + 1000)
local runsAfterFirst = corpseRuns
Work.Tick(clock + 1010) -- same cadence window -> skipped (0 work)
T.equal(runsAfterFirst, 1, "WorkService runs dirty pass once")
T.equal(corpseRuns, 1, "WorkService skips unscheduled clean-frame chore polls")

-- AbortOrder clears Tasking.Claims cleanly
Claims.Acquire("work_station:farm:u6", "order:u6:1", { leaseId = "lease:u6:1", domain = "work", ttlMs = 0 })
local abOk = Runner.AbortOrder({
    id = "order:u6:1",
    operation = "FARMING",
    workerId = liveNPCs[1].id,
    payload = { input = { staged = true } },
    outputEffect = { kind = "TEST" },
}, { leaseId = "lease:u6:1", npcId = liveNPCs[1].id }, "u6_abort")
T.truthy(abOk, "WorkToilRunner.AbortOrder succeeds")
T.equal(Claims.IsClaimed("work_station:farm:u6"), false, "AbortOrder releases work Claims cleanly")

-- ===========================================================================
-- 5. Co-Presence 5-Stage Micro-Beats, Street Acts & Witness-Only Hearsay
-- ===========================================================================
DialogueDirector.Reset()
JointLease.Reset()
Agitation.Reset()
local speaker, responder, listener = liveNPCs[1], liveNPCs[3], liveNPCs[4]
local blockedObs = { id = "npc-blocked-u6", alive = true, presenceState = "live", x = responder.x + 12, y = responder.y, z = 0, runtime = {}, social = Social.NewState() }
local distantObs = { id = "npc-far-u6", alive = true, presenceState = "live", x = 300, y = 300, z = 0, runtime = {}, social = Social.NewState() }

local stOk, scene = DialogueDirector.StartScene({
    act = "GREET",
    speakerId = speaker.id,
    responderId = responder.id,
    participants = { speaker, responder, listener },
    firstContact = true,
    maxTurns = 4,
    waitTimeoutMs = 5000,
}, clock + 2000)
T.truthy(stOk and scene and scene.llmCalls == 0, "3-NPC micro-beat scene starts deterministically with 0 LLM calls")
T.equal(scene.stage, "wait_with_timeout", "scene enters wait_with_timeout stage")

local mixOk, mixRes = DialogueDirector.InjectGlobalMixin(scene.sceneId, {
    mixinType = "bystander_bark",
    severity = "low",
    tensionDelta = 15,
    barkId = "bark.whisper_check",
}, clock + 2500)
T.truthy(mixOk and mixRes and mixRes.action == "interleaved", "global mix-in interrupts deterministically")

local pObj = { id = "player_u6", isPlayer = true, x = responder.x + 1, y = responder.y, z = 0 }
local antOk, antRes = StreetInteraction.HandleStreetAct(pObj, responder, "ANTAGONIZE", {
    at = clock + 3000,
    witnessCandidates = { responder, listener, blockedObs, distantObs },
    losCheck = function(obs) return obs.id ~= blockedObs.id end,
})
T.truthy(antOk and antRes.llmCalls == 0 and antRes.agitation and antRes.agitation.score >= 20,
    "RDR2 ANTAGONIZE updates AgitationService score with zero LLM calls")
T.truthy(#(responder.social.memoryBank or {}) >= 1, "direct responder records PsychopatzSocial memory")
T.truthy(#(listener.social.memoryBank or {}) >= 1, "clear-LOS witness records PsychopatzSocial memory")
T.equal(#(blockedObs.social.memoryBank or {}), 0, "LOS-blocked NPC receives zero leaked memories")
T.equal(#(distantObs.social.memoryBank or {}), 0, "out-of-range NPC receives zero leaked memories")

local hs1 = SocialWitness.PropagateHearsay(listener, distantObs, { at = clock + 4000 })
T.truthy(hs1 and hs1.propagated == true and hs1.hopCount == 1, "1-hop hearsay propagates shareable memory")
local hsBounce = SocialWitness.PropagateHearsay(distantObs, listener, { at = clock + 5000 })
T.falsy(hsBounce.propagated, "hearsay does not bounce already-recorded baseEventId back")

-- ===========================================================================
-- 6. Domain-Delta MP Replication & Profiler-OFF Zero Overhead
-- ===========================================================================
PNC.Network = { Internal = { SnapshotParts = {}, PresencePayload = {} } }
T.load("ProjectHoomans", "shared", "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DomainDeltas.lua")
T.equal(PNC.Network.ResolveEventDeltaKind("secondary_channel"), "presence",
    "secondary_channel routes through narrow presence delta")

Secondary.ClearForRecord(liveNPCs[5], fakeBody)
T.equal(Secondary.BuildDeltaPayload(liveNPCs[5], clock + 6000), nil,
    "clean NPC with default SecondaryChannel emits nil delta (zero wire bloat)")
Secondary.SetAlertLevel(liveNPCs[5], "tense")
Secondary.SetPosture(liveNPCs[5], "crouch")
local dirtySecDelta = Secondary.BuildDeltaPayload(liveNPCs[5], clock + 6000)
T.truthy(dirtySecDelta and dirtySecDelta.alertLevel == "tense" and dirtySecDelta.posture == "crouch",
    "dirty SecondaryChannel emits compact anim-var delta")
T.equal(dirtySecDelta.appearance, nil, "secondary delta omits heavy appearance data")

-- Profiler OFF guarantees zero counter/timing overhead and zero persisted record telemetry
Diagnostics.Enabled = false
Diagnostics.TimingEnabled = false
Diagnostics.RuntimeLogEnabled = false
local beforePumps = tonumber(Diagnostics.Counters["Pathing.PathPumps"]) or 0
local tName, tStart = Diagnostics.BeginTiming("u6.scale.hot_path", clock + 6100)
Diagnostics.RecordPathPump(liveNPCs[1], "u6_scale")
Diagnostics.RecordDirtyMark("u6_test")
Diagnostics.EndTiming(tName, tStart, liveNPCs[1].id)
T.equal(tName, nil, "profiler-OFF BeginTiming is a zero-cost no-op")
T.equal(tonumber(Diagnostics.Counters["Pathing.PathPumps"]) or 0, beforePumps,
    "profiler-OFF RecordPathPump adds zero counter overhead")
T.equal(liveNPCs[1].diagnostics, nil, "records carry zero persisted diagnostic telemetry")
T.equal(liveNPCs[1].performance, nil, "records carry zero persisted performance telemetry")

T.finish("pnc_u6_unified_ai_scale_smoke")
