-- Multi-NPC scaling benchmark for Tasking.Collect, Autonomy Validate,
-- ShockingReaction vs CombatGuard, Provision.Pump, SP LocalSnapshots, and
-- Spatial.Rebuild same-tick deduplication.
-- Usage:
--   lua tests/benchmarks/tasking_provision_and_snapshot_flow.lua
local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 10000
local worldHours = 24.0
local clientFlag = false
local serverFlag = true

isClient = function() return clientFlag end
isServer = function() return serverFlag end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
        getTimeOfDay = function() return 14 end,
    }
end
Events = {
    OnTick = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    OnServerShutdown = { Add = function() end },
    OnGameEnd = { Add = function() end },
}

local function bench(name, iterations, fn)
    collectgarbage("collect")
    local t0 = os.clock()
    for i = 1, iterations do
        fn(i)
    end
    local elapsedMs = (os.clock() - t0) * 1000
    local avgUs = (elapsedMs * 1000) / math.max(1, iterations)
    print(string.format("[BENCH] %-48s iters=%5d total=%7.3fms avg=%7.3fus",
        name, iterations, elapsedMs, avgUs))
    return elapsedMs, avgUs
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

PNC = { PerformanceScalingDiagnostics = nil }
local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
PNC.Core.Now = function() return nowMs end
PNC.Core.IsAuthority = function() return true end
PNC.Core.LogInfo = function() end
PNC.Core.LogWarn = function() end

-- Build 60-NPC registry fixture
local NPC_COUNT = 60
local recordsById = {}
local liveZombiesById = {}
for i = 1, NPC_COUNT do
    local id = string.format("npc_bench_%03d", i)
    local isFollower = (i <= 20)
    local inCombat = (i <= 30)
    recordsById[id] = {
        id = id,
        alive = true,
        presenceState = PNC.Const.PRESENCE_LIVE,
        presenceRevision = 1,
        recordRevision = 1,
        x = 10700 + (i % 10) * 1.5,
        y = 10600 + math.floor(i / 10) * 1.5,
        z = 0,
        orderSpec = isFollower and { kind = PNC.Const.ORDER_FOLLOW } or { kind = "roam" },
        runtime = {
            target = inCombat and { kind = "zombie", zombieId = "z_" .. tostring(i) } or nil,
            pathing = { phase = "active", visualMovingUntil = nowMs + 500 },
            provision = { dirtyRules = {}, incoming = {}, pending = {}, quarantined = {} },
        },
        health = { current = 100, max = 100, state = "healthy" },
    }
    liveZombiesById[id] = {
        getX = function() return recordsById[id].x end,
        getY = function() return recordsById[id].y end,
        getZ = function() return recordsById[id].z end,
        isDead = function() return false end,
    }
end

PNC.Registry = {
    Data = recordsById,
    Get = function(id) return recordsById[tostring(id)] end,
    GetLiveZombie = function(id) return liveZombiesById[tostring(id)] end,
    ForEach = function(fn)
        for _, rec in pairs(recordsById) do fn(rec) end
    end,
    ForEachLive = function(fn)
        for _, rec in pairs(recordsById) do
            if rec.presenceState == PNC.Const.PRESENCE_LIVE then fn(rec) end
        end
    end,
}

-- =========================================================================
-- 1. Tasking.Collect + Autonomy Validate + Emergency Short-Circuit (60 NPCs)
-- =========================================================================
T.load(SERVER .. "Tasking/PNC_TaskPriority.lua")
T.load(SERVER .. "Tasking/PNC_TaskIntent.lua")
T.load(SERVER .. "Tasking/PNC_TaskLeaseService.lua")
T.load(SERVER .. "Tasking/PNC_Tasking.lua")

local worldScanCount = 0
local seatPreviewReturn = { x = 10705, y = 10605, facilityId = "camp_1", resourceKey = "chair_1" }

PNC.AutonomyScorer = {
    EvaluateAll = function(record, ctxFn)
        local ctx = ctxFn({ id = "ad.rest_seat" })
        if not ctx then return {} end
        return {
            { ad = { id = "ad.rest_seat", capability = "seat.rest" }, context = ctx, band = "IDLE", urgency = 0.2 },
            { ad = { id = "ad.social_lounge", capability = "seat.social" }, context = ctx, band = "OPTIONAL", urgency = 0.3 },
        }
    end,
    RecordFailure = function() end,
}
PNC.CoPresenceService = {}
PNC.AutonomyExecutors = {
    FacilitySeat = {
        IsEligible = function() return true, { id = "camp_1" }, nil end,
        PreviewSeat = function()
            worldScanCount = worldScanCount + 1
            return seatPreviewReturn
        end,
    },
    RoamingSeat = { CanAttempt = function() return false end, FindCandidate = function() worldScanCount = worldScanCount + 1; return nil end },
    RoamAmbient = { CanAttempt = function() return false end, GetActionPlan = function() return nil end },
}
T.load(SERVER .. "Tasking/Autonomy/PNC_AutonomyTaskProvider.lua")

local emergencyActive = false
PNC.Tasking.Providers["reaction"] = {
    GetCandidates = function(npcId)
        if not emergencyActive then return {} end
        return {
            {
                taskId = "reaction:panic:" .. tostring(npcId),
                npcId = tostring(npcId),
                kind = "BackAway",
                operation = "BackAway",
                sourceDomain = "reaction",
                sourceRef = "panic",
                precedence = "HARD_EMERGENCY",
                urgency = 0.9,
                capability = "reaction.retreat",
                interruptPolicy = "NORMAL",
            },
        }
    end,
    Validate = function() return true end,
    Assign = function() return { leaseId = "l1" } end,
}

-- 1a. Emergency short-circuit: autonomy must NOT scan when HARD_EMERGENCY exists
emergencyActive = true
worldScanCount = 0
local _, emergencyUs = bench("Tasking.Collect 60 NPCs (HARD_EMERGENCY)", 60, function(i)
    local rec = recordsById[string.format("npc_bench_%03d", i)]
    PNC.Tasking.Internal.Collect(rec)
end)
T.equal(worldScanCount, 0, "HARD_EMERGENCY candidate must skip autonomy world scans")
T.truthy(emergencyUs < 500, "emergency Tasking.Collect stays fast per NPC")

-- 1b. Idle roamers (i=31..60): 2 candidates returned -> Validate must NOT re-scan!
emergencyActive = false
worldScanCount = 0
local _, idleUs = bench("Tasking.Collect 60 NPCs (30 combat + 30 idle)", 60, function(i)
    local rec = recordsById[string.format("npc_bench_%03d", i)]
    PNC.Tasking.Internal.Collect(rec)
end)
-- 30 combat/follower NPCs = 0 scans; 30 idle NPCs = 1 scan each (NOT 3 scans each!)
T.equal(worldScanCount, 30, "Validate must reuse autonomyContext (1 scan per idle NPC, 0 for combat/followers)")
T.truthy(idleUs < 500, "mixed Tasking.Collect stays fast per NPC")

-- 1c. Empty discovery cooldown: repeated reevaluations within 1500ms do not re-scan
nowMs = nowMs + 4000
seatPreviewReturn = nil
worldScanCount = 0
for _ = 1, 5 do
    for i = 31, 60 do
        PNC.AutonomyTaskProvider.GetCandidates(string.format("npc_bench_%03d", i), { at = nowMs })
    end
    nowMs = nowMs + 200
end
T.equal(worldScanCount, 30, "empty-discovery cooldown prevents repeated scans within 1500ms")

-- =========================================================================
-- 2. ShockingReaction vs CombatGuard tug-of-war (60 NPCs)
-- =========================================================================
PNC.ReactionPolicyEvaluator = {
    Evaluate = function()
        return { reaction = { id = "r_inv", intent = "Investigate", band = "HARD_EMERGENCY", priority = 60 } }
    end,
}
PNC.SpatialIndex = {
    LastRebuildAt = nil,
    QueryNPCs = function()
        local list = {}
        for i = 1, 16 do list[#list + 1] = recordsById[string.format("npc_bench_%03d", i)] end
        return list
    end,
}
T.load(SERVER .. "Tasking/Reactions/PNC_ShockingReactionTaskProvider.lua")

local emittedCount = 0
local origEmit = PNC.Tasking.Events.Emit
PNC.Tasking.Events.Emit = function(evType, payload)
    if evType == "SHOCKING_EVENT" then emittedCount = emittedCount + 1 end
    return origEmit(evType, payload)
end

-- First 16 NPCs are all in active combat -> Investigate must NOT emit SHOCKING_EVENT
local offered = PNC.ShockingReactionTaskProvider.HandleShockingEvent({
    id = "ev_1", eventType = "gunshot", x = 10705, y = 10605, z = 0, radius = 30, at = nowMs,
})
T.equal(offered, 0, "combat-engaged NPCs must not receive Investigate shock offers")
T.equal(emittedCount, 0, "combat-engaged NPCs must not spam Tasking.Inbox with Investigate events")

-- Active Investigate lease must complete with COMBAT_PREEMPTED when NPC enters combat
local completedReason = nil
PNC.Tasking.Commands.Complete = function(_, reason)
    completedReason = reason
    return true
end
local combatRec = recordsById["npc_bench_001"]
combatRec.runtime.reactionState = {
    leaseId = "lease_combat_1", intent = "Investigate", expiresAt = nowMs + 10000,
    targetX = 10710, targetY = 10610, targetZ = 0,
}
PNC.ShockingReactionTaskProvider.Tick({ leaseId = "lease_combat_1", npcId = "npc_bench_001" })
T.equal(completedReason, "COMBAT_PREEMPTED", "Investigate tick yields cleanly to active combat")

-- =========================================================================
-- 3. ProvisionScheduler under 60-NPC x 3-rule (180 entries) queue
-- =========================================================================
local bandageRipCalls = 0
PNC.WorldItemService = {
    RequestBandageRip = function()
        bandageRipCalls = bandageRipCalls + 1
        return false, "none"
    end,
}
PNC.HomeDutyService = { IsAtHome = function() return false end }
PNC.SupplyMetrics = { Increment = function() end, SetGauge = function() end, Set = function() end }
PNC.ProvisionRuleRegistry = {
    Get = function(id) return { id = id, resourceKind = "MEDICAL" } end,
    List = function() return { { id = "bandage" } } end,
}
PNC.ProvisionEvaluator = {
    Evaluate = function() return { satisfied = false, incoming = 0, deficit = 1, onHand = 0 } end,
    BuildRequest = function(rec) return { npcId = rec.id, resourceKind = "MEDICAL" } end,
}
T.load(SERVER .. "Provision/PNC_ProvisionScheduler.lua")

-- Combat NPC must NOT trigger world bandage-rip scan
PNC.ProvisionScheduler.Internal.Process({ npcID = "npc_bench_001", ruleID = "bandage", readyAt = 0 })
T.equal(bandageRipCalls, 0, "combat-engaged NPC must not scan world items for bandage rip")

-- Time-budgeted pump with 180 queued entries
PNC.ProvisionScheduler.Queue = {}
PNC.ProvisionScheduler.Queued = {}
PNC.ProvisionScheduler.MAX_PER_SLICE = 20
PNC.ProvisionScheduler.SLICE_TIME_BUDGET_MS = 2
PNC.ProvisionScheduler.SLICE_INTERVAL_MS = 0
PNC.ProvisionScheduler.Bootstrap = function() end
PNC.ProvisionScheduler.Audit = function() end
for i = 1, NPC_COUNT do
    local id = string.format("npc_bench_%03d", i)
    PNC.ProvisionScheduler.MarkDirty(id, "food", 0)
    PNC.ProvisionScheduler.MarkDirty(id, "hydration", 0)
    PNC.ProvisionScheduler.MarkDirty(id, "bandage", 0)
end
local _, provUs = bench("ProvisionScheduler.Pump (180-entry queue)", 50, function()
    nowMs = nowMs + 100
    PNC.ProvisionScheduler.Pump(nowMs)
end)
T.truthy(provUs < 2000, "ProvisionScheduler.Pump stays bounded under 180-entry queue")

-- =========================================================================
-- 4. SP LocalSnapshots unchanged-state skip + MP safety (60 live NPCs)
-- =========================================================================
local fullBuilds = 0
local deltaBuilds = 0
PNC.Network = {
    ClientState = { snapshots = {} },
    BuildSnapshot = function(rec)
        fullBuilds = fullBuilds + 1
        return {
            id = rec.id, x = rec.x, y = rec.y, z = rec.z,
            presenceRevision = rec.presenceRevision,
            recordRevision = rec.recordRevision,
            visualState = { attackActive = false },
        }
    end,
    BuildPresenceDelta = function(rec)
        deltaBuilds = deltaBuilds + 1
        return {
            id = rec.id, x = rec.x, y = rec.y, z = rec.z,
            presenceRevision = rec.presenceRevision,
            recordRevision = rec.recordRevision,
            visualState = { attackActive = false },
        }
    end,
}
PNC.ClientPresenceSync = {
    Internal = {
        CanRequestRemoteSync = function() return clientFlag == true end,
    },
}
T.load("ProjectHoomans", "client", "PNC/PresenceSync/PNC_ClientPresenceTick_LocalSnapshots.lua")

-- SP initial build: 60 full snapshots, 0 deltas
clientFlag = false
serverFlag = false
nowMs = nowMs + 500
PNC.ClientPresenceSync.Internal.PresenceTick.LocalSnapshots.RefreshAuthority(nowMs)
T.equal(fullBuilds, NPC_COUNT, "SP initial pass builds 60 full snapshots")
T.equal(deltaBuilds, 0, "SP initial pass builds 0 deltas")

-- SP unchanged steady-state across 20 ticks: 0 redundant BuildPresenceDelta calls!
local _, spSnapUs = bench("SP LocalSnapshots 60 unchanged NPCs", 20, function()
    nowMs = nowMs + 300
    PNC.ClientPresenceSync.Internal.PresenceTick.LocalSnapshots.RefreshAuthority(nowMs)
end)
T.equal(deltaBuilds, 0, "unchanged SP NPCs must not rebuild PresenceDelta")
T.truthy(spSnapUs < 1000, "SP unchanged snapshot scan stays sub-millisecond for 60 NPCs")

-- Moving 5 NPCs triggers exactly 5 BuildPresenceDelta calls
for i = 1, 5 do
    recordsById[string.format("npc_bench_%03d", i)].x = recordsById[string.format("npc_bench_%03d", i)].x + 1.0
end
nowMs = nowMs + 300
PNC.ClientPresenceSync.Internal.PresenceTick.LocalSnapshots.RefreshAuthority(nowMs)
T.equal(deltaBuilds, 5, "moved SP NPCs immediately refresh PresenceDelta")

-- MP remote client: LocalSnapshots must do nothing
clientFlag = true
deltaBuilds = 0
for i = 1, 5 do
    recordsById[string.format("npc_bench_%03d", i)].x = recordsById[string.format("npc_bench_%03d", i)].x + 1.0
end
nowMs = nowMs + 300
local mpRebuilt = PNC.ClientPresenceSync.Internal.PresenceTick.LocalSnapshots.RefreshAuthority(nowMs)
T.falsy(mpRebuilt, "MP remote client must bypass local authority snapshot builder")
T.equal(deltaBuilds, 0, "MP remote client must never call local BuildPresenceDelta")

-- =========================================================================
-- 5. Centralized Throttled Lazy Logger + Zero-Alloc Stutter Spike Pinpointer
-- =========================================================================
local capturedLogs = {}
local origCoreLog = PNC.Core.Log
local origCoreLogWarn = PNC.Core.LogWarn
PNC.Core.Log = function(level, msg)
    capturedLogs[#capturedLogs + 1] = "[" .. tostring(level) .. "] " .. tostring(msg)
end
PNC.Core.LogWarn = function(msg)
    PNC.Core.Log("WARN", msg)
end
PNC.Core.ResetLogThrottle()

local lazyBuildCalls = 0
local function lazyMsg()
    lazyBuildCalls = lazyBuildCalls + 1
    return "spam_event"
end

-- 100 rapid warnings in the same 2000ms window -> only 1 emitted, 1 lazy build!
for _ = 1, 100 do
    PNC.Core.LogWarnThrottled("spam_key", 2000, lazyMsg)
end
T.equal(#capturedLogs, 1, "throttled logger emits once per window")
T.equal(lazyBuildCalls, 1, "suppressed calls must never invoke lazy message builder")

-- After window elapses, next emit includes [suppressed=99]
nowMs = nowMs + 2500
PNC.Core.LogWarnThrottled("spam_key", 2000, lazyMsg)
T.equal(#capturedLogs, 2, "throttled logger emits again after window")
T.contains(capturedLogs[2], "[suppressed=99]", "next emit reports exact suppressed count")

-- Stutter spike pinpointer
T.load(SHARED .. "Diagnostics/PNC_PerformanceScalingDiagnostics.lua")
local Diag = PNC.PerformanceScalingDiagnostics
Diag.Enabled = true
Diag.TimingEnabled = true
Diag.RuntimeLogEnabled = true
Diag.TimingSampleIntervalMs = 0
Diag.TickSpike.ThresholdMs = 50
Diag.TickSpike.LogIntervalMs = 2000
Diag.TickSpike.LastLogAt = 0

capturedLogs = {}
Diag.BeginFrame()
local _, tServer = Diag.BeginTiming("Server.Update", nowMs)
local _, tPrep = Diag.BeginTiming("Server.Prepare", nowMs)
local _, tBody = Diag.BeginTiming("server_prepare.body_audit", nowMs)
nowMs = nowMs + 35
Diag.EndTiming("server_prepare.body_audit", tBody)
local _, tTask = Diag.BeginTiming("Tasking.Pump", nowMs)
nowMs = nowMs + 25
Diag.EndTiming("Tasking.Pump", tTask)
Diag.EndTiming("Server.Prepare", tPrep)
local _, tRec = Diag.BeginTiming("Server.ProcessRecord", nowMs)
nowMs = nowMs + 18
Diag.EndTiming("Server.ProcessRecord", tRec, "npcSteveBox_CMBA")
local _, tFin = Diag.BeginTiming("Server.Finish", nowMs)
nowMs = nowMs + 10
Diag.EndTiming("Server.Finish", tFin)
Diag.EndTiming("Server.Update", tServer)

T.equal(#capturedLogs, 1, "stutter tick >= ThresholdMs emits one stutter_spike line")
T.contains(capturedLogs[1], "stutter_spike", "stutter line tagged with stutter_spike")
T.contains(capturedLogs[1], "server_prepare.body_audit:35ms", "stutter line names #1 slowest stage")
T.contains(capturedLogs[1], "Tasking.Pump:25ms", "stutter line names #2 slowest stage")
T.contains(capturedLogs[1], "slowestNpc=npcSteveBox_CMBA:18ms", "stutter line names slowest NPC")

-- =========================================================================
-- 6. SocialEncounterTracker.EndEncounter (20 participants -> bounded pairs + 1 beat)
-- =========================================================================
PNC.EntityRef = {
    IsNPC = function(key) return tostring(key or ""):sub(1, 4) == "npc:" end,
}
local socialEmits = 0
local beatNotifies = 0
PNC.Semantics = {
    DialogueBeats = {
        OnCombatEncounterCleared = function()
            beatNotifies = beatNotifies + 1
        end,
    },
}
PNC.SocialEncounterTracker = {
    Encounters = {},
    ByParticipant = {},
    ByThreat = {},
    MAX_SHARED_PAIRS_PER_ENCOUNTER = 24,
    MIN_THREATS = 1,
    MIN_DURATION_HOURS = 0,
    MIN_SHARED_COMBAT_HOURS = 0,
    MIN_SHARED_THREATS = 1,
    Internal = {
        finite = function(v, fb) return tonumber(v) or fb end,
        countEntries = function(t)
            local c = 0
            for _ in pairs(t or {}) do c = c + 1 end
            return c
        end,
        encounterQualifies = function() return true end,
        participantAlive = function() return true end,
        releaseEncounter = function(enc) PNC.SocialEncounterTracker.Encounters[enc.id] = nil end,
        emit = function()
            socialEmits = socialEmits + 1
            return { ok = true, memoriesCreated = 1 }
        end,
    },
}
T.load(SERVER .. "Social/SocialEncounterTracker/PNC_SocialEncounterTracker_Completion.lua")

local bigParticipants = { ["player:local"] = { eligibleForShared = true } }
for i = 1, 19 do
    bigParticipants["npc:bench_" .. tostring(i)] = { eligibleForShared = true }
end
PNC.SocialEncounterTracker.Encounters["enc_big_1"] = {
    id = "enc_big_1",
    startedAt = 23.0,
    x = 10700, y = 10600, z = 0,
    hordeAttack = false,
    threatIDs = { z1 = true, z2 = true, z3 = true },
    participants = bigParticipants,
}
local okEnd, reasonEnd = PNC.SocialEncounterTracker.EndEncounter("enc_big_1", 24.0)
T.truthy(okEnd, "EndEncounter succeeds for 20-participant brawl")
T.equal(reasonEnd, "encounter_socialized", "EndEncounter socializes qualifying encounter")
T.equal(socialEmits, 24, "20-participant encounter (190 pairs) is bounded to MAX_SHARED_PAIRS_PER_ENCOUNTER=24")
T.equal(beatNotifies, 1, "DialogueBeats.OnCombatEncounterCleared fires once per encounter, not once per pair")

-- 7. Deferred SocialEncounterTracker pair drain (no 1.35s frame freeze on Pump)
socialEmits = 0
beatNotifies = 0
PNC.SocialEncounterTracker.PendingPairEmits = {}
PNC.SocialEncounterTracker.PendingPairHead = 1
PNC.SocialEncounterTracker.PendingPairTail = 0
PNC.SocialEncounterTracker.Encounters["enc_big_deferred"] = {
    id = "enc_big_deferred",
    startedAt = 23.0,
    x = 10700, y = 10600, z = 0,
    hordeAttack = false,
    threatIDs = { z1 = true, z2 = true, z3 = true },
    participants = bigParticipants,
}
local okDef, reasonDef, emittedDef = PNC.SocialEncounterTracker.EndEncounter(
    "enc_big_deferred", 24.0, { deferPairs = true }
)
T.truthy(okDef, "deferred EndEncounter succeeds")
T.equal(reasonDef, "encounter_socialized", "deferred EndEncounter drains initial slice")
T.equal(emittedDef, 2, "deferred EndEncounter drains only 2 pairs on first tick")
T.equal(socialEmits, 2, "only 2 emits ran synchronously on end frame")
local drains = 0
while (tonumber(PNC.SocialEncounterTracker.PendingPairHead) or 1)
    <= (tonumber(PNC.SocialEncounterTracker.PendingPairTail) or 0)
    and drains < 30
do
    PNC.SocialEncounterTracker.DrainPendingPairs(2)
    drains = drains + 1
end
T.equal(socialEmits, 24, "all 24 bounded pairs finish draining across subsequent ticks")
T.equal(beatNotifies, 1, "deferred encounter still fires DialogueBeats once")

-- 8. Autonomous neutral NPC holding a firearm with default melee weaponMode
-- resolves to mixed ranged instead of bashing zombies in melee.
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}
PNC.Equipment.Internal.peekWeaponDescriptor = function(fullType)
    if fullType == "Base.DoubleBarrelShotgun" then
        return {
            fullType = fullType,
            primaryType = "rifle",
            hasWeapon = true,
            hasUsableFirearm = true,
            weaponStatus = "equipped_rifle",
        }
    end
    return {
        fullType = nil,
        primaryType = "barehand",
        hasWeapon = false,
        hasUsableFirearm = false,
        weaponStatus = "barehand",
    }
end
T.load(SHARED .. "Equipment/PNC_Equipment/PNC_Equipment_Describe.lua")
local neutralGunner = {
    id = "neutral_gunner",
    recruited = false,
    weaponMode = "melee",
    equipment = { primaryFullType = "Base.DoubleBarrelShotgun" },
    runtime = {},
}
local neutralDesc = PNC.Equipment.Describe(neutralGunner)
T.equal(neutralDesc.combatModeResolved, "mixed",
    "autonomous neutral NPC holding a firearm resolves to mixed (ranged capable), not melee")
local commandedCompanion = {
    id = "companion_melee_cmd",
    recruited = true,
    weaponMode = "melee",
    equipment = { primaryFullType = "Base.DoubleBarrelShotgun" },
    runtime = {},
}
local compDesc = PNC.Equipment.Describe(commandedCompanion)
T.equal(compDesc.combatModeResolved, "melee",
    "recruited companion explicitly set to melee keeps melee mode")

PNC.Core.Log = origCoreLog
PNC.Core.LogWarn = origCoreLogWarn
print("[BENCH] ALL 60-NPC HOTPATH ASSERTIONS PASSED")
