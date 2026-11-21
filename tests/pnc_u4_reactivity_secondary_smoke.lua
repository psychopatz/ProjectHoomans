local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "common_lua" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

local now = 50000
Events = {
    OnGameBoot = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    EveryTenMinutes = { Add = function() end },
    OnTick = { Add = function() end },
    OnWorldSound = { Add = function() end },
}
getText = function(key) return key end

-- Load Core capability kernel + PsychopatzShockingEventBus
require "PsychopatzCore/Composition/PC_SharedComposition"
local okCap, capFacade = PsychopatzCore.Require("core.shocking_events", "u4_smoke")
local ShockBus = (okCap and type(capFacade) == "table" and capFacade)
    or PsychopatzCore.ShockingEventBus
T.truthy(ShockBus and type(ShockBus.Emit) == "function",
    "Core PsychopatzShockingEventBus capability must load cleanly")
ShockBus.Reset()

local seq = 0
local records = {}
local haltedCalls = 0
PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        GenerateID = function(prefix)
            seq = seq + 1
            return tostring(prefix or "id") .. "-" .. tostring(seq)
        end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do
                if type(val) == "table" then
                    local sub = {}
                    for sk, sv in pairs(val) do sub[sk] = sv end
                    out[k] = sub
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
        PRESENCE_LIVE = "live",
        DOMAIN_DELTA_PROTOCOL = 1,
        ORDER_CAMP = "camp",
        ORDER_ROAM = "roam",
        ORDER_GUARD = "guard",
        ORDER_FOLLOW = "follow",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_OUTFIT = "PNC_Carrier",
        BODY_SHELL_CARRIER_VERSION = 1,
    },
    Registry = {
        Data = records,
        Get = function(id) return records[tostring(id or "")] end,
        GetLiveZombie = function(id)
            local rec = records[tostring(id or "")]
            return rec and rec.liveZombie or nil
        end,
    },
    BehaviorCommon = {
        HaltMovement = function() haltedCalls = haltedCalls + 1 end,
    },
    IndividualNeeds = { Queries = {} },
}

-- Load compiled U2 registries directly from common layer
local ReactionRegistry = T.load("ProjectHoomans", "common_lua", "PNC/ReactionPolicy/Registry.lua")
local ScenarioRegistry = T.load("ProjectHoomans", "common_lua", "PNC/WorkScenario/Registry.lua")
T.truthy(ReactionRegistry.GetProfile("profile.colonist_default"),
    "compiled profile.colonist_default must exist")
T.truthy(ReactionRegistry.GetReaction("reaction.explosion_flee"),
    "compiled reaction.explosion_flee must exist")
T.truthy(ScenarioRegistry.GetScenario("scenario.evening_lounge"),
    "compiled scenario.evening_lounge must exist")

-- Load U4 modules
local PerceptionSvc = T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_PerceptionService.lua")
local Secondary = T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_SecondaryChannel.lua")
local Catalog = T.load("ProjectHoomans", "client", "PNC/Audio/PNC_NPCVoiceCatalog.lua")

-- Minimal PsychopatzCore.RuntimeRole for server modules
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local Agitation = T.load("ProjectHoomans", "server", "PNC/Agitation/PNC_AgitationService.lua")
local Evaluator = T.load("ProjectHoomans", "server", "PNC/Tasking/Reactions/PNC_ReactionPolicyEvaluator.lua")
local ScenarioScheduler = T.load("ProjectHoomans", "server", "PNC/Tasking/Autonomy/PNC_ScenarioScheduler.lua")

package.preload["PNC/Tasking/PNC_WorkTaskProvider"] = function() return {} end
package.preload["PNC/Tasking/PNC_CorpseHaulService"] = function() return {} end
package.preload["PNC/Tasking/PNC_TaskRequestService"] = function() return {} end
package.preload["PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"] = function() return {} end
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskPriority.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskLeaseService.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking.lua")
local ReactionProvider = T.load("ProjectHoomans", "server",
    "PNC/Tasking/Reactions/PNC_ShockingReactionTaskProvider.lua")

-- =========================================================================
-- 1. PerceptionService: cadence, azimuth cone pre-filter, budgeted LOS queue, ClueMemory, WorldSound
-- =========================================================================
PerceptionSvc.Reset()
local observer = {
    id = "npc-obs",
    alive = true,
    x = 100,
    y = 100,
    z = 0,
    orderSpec = { kind = "guard" }, -- selects profile.guard_alert
    runtime = { facingDirX = 1, facingDirY = 0 },
}
records[observer.id] = observer

local guardProfile = PerceptionSvc.GetProfile(observer)
T.equal(guardProfile.id, "profile.guard_alert", "guard order must select guard_alert profile")
T.equal(PerceptionSvc.GetCadenceMs(observer, guardProfile, now), 1000, "idle cadence should be 1000ms")
observer.runtime.combatTarget = { id = "z1" }
T.equal(PerceptionSvc.GetCadenceMs(observer, guardProfile, now), 100, "combat cadence should be 100ms")
observer.runtime.combatTarget = nil

T.truthy(PerceptionSvc.ShouldScan(observer, now, guardProfile), "first scan should run")
T.falsy(PerceptionSvc.ShouldScan(observer, now + 500, guardProfile), "scan should respect idle cadence")
T.truthy(PerceptionSvc.ShouldScan(observer, now + 1000, guardProfile), "scan should unlock after cadence")

-- Azimuth cone pre-filter: target behind (+x facing, target at -x) at distance 10m -> rejected
local frontOk = PerceptionSvc.CheckVisionCone(observer, 110, 100, 0, guardProfile)
local backOk = PerceptionSvc.CheckVisionCone(observer, 90, 100, 0, guardProfile)
local peripheralOk = PerceptionSvc.CheckVisionCone(observer, 98.5, 100, 0, guardProfile) -- dist 1.5m <= 2.5m
T.truthy(frontOk, "target directly in front inside visionRange must pass cone")
T.falsy(backOk, "distant target behind facing azimuth must fail cone pre-filter")
T.truthy(peripheralOk, "close-proximity target inside 2.5m passes peripheral exemption")

-- Budgeted LOS queue (max 8 per tick) + blocked LOS never leaks target into ClueMemory
local losCalls = 0
local clearSet = { ["t-1"] = true, ["t-2"] = true }
PNC.Perception = {
    CanSeeWorldObject = function(_, obj)
        losCalls = losCalls + 1
        if clearSet[obj.id] then return true, "clear" end
        return false, "blocked"
    end,
}
for i = 1, 12 do
    local tid = "t-" .. tostring(i)
    PerceptionSvc.QueueLOSCheck(observer, {
        id = tid,
        getX = function() return 105 + i end,
        getY = function() return 100 end,
        getZ = function() return 0 end,
    }, tid, nil, { at = now })
end
local ran1 = PerceptionSvc.PumpLOSQueue(now, 8)
T.equal(ran1, 8, "first PumpLOSQueue tick must enforce budget=8")
T.equal(losCalls, 8, "first tick executed 8 LOS checks")
local ran2 = PerceptionSvc.PumpLOSQueue(now + 100, 8)
T.equal(ran2, 4, "second tick processes remaining 4 queued LOS checks")
T.truthy(PerceptionSvc.GetMostRecentClue(observer, "visual_lkp", now),
    "clear LOS must record visual_lkp clue")
local clues = PerceptionSvc.GetClues(observer, now)
T.equal(#clues, 2, "only clear LOS targets record visual_lkp clues; blocked LOS never wall-hacks")

-- ClueMemory bounded eviction (maxClues=8 on guard_alert) and TTL expiration
for i = 1, 12 do
    PerceptionSvc.RecordClue(observer, {
        key = "clue-" .. tostring(i),
        kind = "sound",
        x = 100 + i,
        y = 100,
        z = 0,
    }, now + i)
end
T.equal(#PerceptionSvc.GetClues(observer, now + 20), 8,
    "ClueMemory must evict oldest entries beyond profile.maxClues")
T.equal(#PerceptionSvc.GetClues(observer, now + 50000), 0,
    "ClueMemory must prune expired clues after clueMemoryTtlMs")

-- OnWorldSound -> records sound clue + emits ShockingEventBus event
ShockBus.Reset()
ReactionProvider.Reset()
local heardCount = PerceptionSvc.OnWorldSound(105, 100, 0, 50, 80, "player-gun")
T.equal(heardCount, 1, "OnWorldSound must notify nearby listener")
T.truthy(PerceptionSvc.GetMostRecentClue(observer, "sound", now),
    "OnWorldSound must record sound clue into listener ClueMemory")

-- =========================================================================
-- 2. ShockingReactionTaskProvider + ReactionPolicyEvaluator + 5 Intents + Claims
-- =========================================================================
-- Since ShockBus subscribed ReactionProvider on load, OnWorldSound above emitted shock.gunfire!
local cands = ReactionProvider.GetCandidates(observer.id, { at = now })
T.equal(#cands, 1, "shock.gunfire from OnWorldSound must offer reaction candidate")
T.equal(cands[1].kind, "StopAndAssess", "gunfire maps to StopAndAssess")
T.equal(cands[1].precedence, "HARD_EMERGENCY", "reaction uses compiled HARD_EMERGENCY band")

local okGun, leaseGun = PNC.Tasking.Commands.Reevaluate(observer.id, "shock_gunfire")
T.truthy(okGun and leaseGun and leaseGun.sourceDomain == "reaction",
    "Tasking must assign HARD_EMERGENCY reaction lease")
T.equal(#PNC.Tasking.Claims.ListByLease(leaseGun.leaseId), 1,
    "reaction lease must hold unified Tasking.Claims entry")
T.truthy(observer.runtime.secondaryChannel and observer.runtime.secondaryChannel.lastBarkId == "bark.alert_hey",
    "reaction start must request bark.alert_hey on secondary channel")

-- Test remaining 4 non-lethal intents + Tick + cleanup
PNC.Tasking.Commands.CancelLease(leaseGun.leaseId, "test_next")
T.equal(#PNC.Tasking.Claims.ListByLease(leaseGun.leaseId), 0,
    "CancelLease must release reaction claim cleanly")

-- weapon_aimed -> BackAway
ShockBus.Emit({ eventType = "shock.weapon_aimed", x = 104, y = 100, z = 0, radius = 15, severity = 82, at = now + 2000 })
local _, leaseBack = PNC.Tasking.Commands.Reevaluate(observer.id, "shock_aim")
T.equal(leaseBack.kind, "BackAway", "shock.weapon_aimed must trigger BackAway")
ReactionProvider.Tick(leaseBack)
T.truthy(observer.runtime.reactionMoveTarget and observer.runtime.reactionMoveTarget.reason == "reaction_back_away",
    "BackAway tick moves NPC away from source")
PNC.Tasking.Commands.CancelLease(leaseBack.leaseId, "test_next")

-- explosion -> SmartFlee
ShockBus.Emit({ eventType = "shock.explosion", x = 103, y = 100, z = 0, radius = 25, severity = 95, at = now + 4000 })
local _, leaseFlee = PNC.Tasking.Commands.Reevaluate(observer.id, "shock_exp")
T.equal(leaseFlee.kind, "SmartFlee", "shock.explosion must trigger SmartFlee")
ReactionProvider.Tick(leaseFlee)
T.truthy(observer.runtime.reactionMoveTarget and observer.runtime.reactionMoveTarget.reason == "reaction_smart_flee",
    "SmartFlee tick moves NPC away 18m")
PNC.Tasking.Commands.CancelLease(leaseFlee.leaseId, "test_next")

-- suspicious_sound -> Investigate ClueMemory LKP
PerceptionSvc.RecordClue(observer, { key = "lkp:noise", kind = "sound", x = 112, y = 106, z = 0 }, now + 5900)
ShockBus.Emit({ eventType = "shock.suspicious_sound", x = 112, y = 106, z = 0, radius = 20, severity = 60, at = now + 6000 })
local _, leaseInv = PNC.Tasking.Commands.Reevaluate(observer.id, "shock_sound")
T.equal(leaseInv.kind, "Investigate", "shock.suspicious_sound must trigger Investigate")
ReactionProvider.Tick(leaseInv)
T.truthy(observer.runtime.reactionMoveTarget and observer.runtime.reactionMoveTarget.x == 112,
    "Investigate must move toward ClueMemory last-known position")
PNC.Tasking.Commands.CancelLease(leaseInv.leaseId, "test_next")

-- ally_assaulted (friend) -> WarnGroup alerts nearby same-faction allies
observer.factionID = "fac-1"
local ally = { id = "npc-ally", alive = true, x = 103, y = 102, z = 0, factionID = "fac-1", runtime = {} }
records[ally.id] = ally
ShockBus.Emit({ eventType = "shock.ally_assaulted", x = 102, y = 100, z = 0, radius = 15, severity = 90, sourceId = ally.id, at = now + 8000 })
local _, leaseWarn = PNC.Tasking.Commands.Reevaluate(observer.id, "shock_ally")
T.equal(leaseWarn.kind, "WarnGroup", "shock.ally_assaulted with friend tier triggers WarnGroup")
ReactionProvider.Tick(leaseWarn)
T.truthy(ally.runtime.secondaryChannel and ally.runtime.secondaryChannel.alertLevel == "wary",
    "WarnGroup must raise nearby ally alert level to wary")
T.truthy(PerceptionSvc.GetMostRecentClue(ally, "hearsay_warning", now + 8000),
    "WarnGroup must share hearsay_warning clue to nearby ally")
PNC.Tasking.Commands.CancelLease(leaseWarn.leaseId, "test_next")

-- =========================================================================
-- 3. AgitationService: sparse lazy decay, cooldown, stage escalation, defuse
-- =========================================================================
Agitation.Reset()
T.equal(Agitation.GetActiveCount(), 0, "sparse agitation store starts empty")
-- Register an unrelated work lease to verify agitation/secondary never cancels tasks!
local fakeWorkLease = { leaseId = "work-lease-keep", npcId = ally.id, taskId = "work:keep", precedence = "NORMAL_WORK" }
PNC.TaskLeaseService.ForNPC = function(id) return id == ally.id and fakeWorkLease or nil end

local agOk, agStage = Agitation.ApplyTrigger(ally, "weapon_draw", "player-1", now)
T.truthy(agOk and agStage == "wary", "weapon_draw (+28) escalates stage to wary")
local cdOk, cdReason = Agitation.ApplyTrigger(ally, "weapon_draw", "player-1", now + 200)
T.falsy(cdOk, "agitation trigger respects rule cooldownMs")
T.equal(cdReason, "AGITATION_COOLDOWN", "expected AGITATION_COOLDOWN reason")
Agitation.ApplyTrigger(ally, "antagonize", "player-1", now + 1500)
Agitation.ApplyTrigger(ally, "weapon_draw", "player-1", now + 2500) -- 28+22+28 = 78 -> tense
local _, tenseStage = Agitation.ApplyTrigger(ally, "antagonize", "player-1", now + 3500, { emitShock = true })
T.equal(tenseStage, "hostile", "repeated provocation crosses hostile threshold (>=85)")
T.truthy(PNC.TaskLeaseService.ForNPC(ally.id) == fakeWorkLease,
    "SecondaryChannel & Agitation must NEVER cancel active TaskLeaseService lease")

local defOk, defStage = Agitation.ApplyTrigger(ally, "defuse", "player-1", now + 4500)
T.truthy(defOk and defStage == "tense", "defuse (-20) de-escalates hostile -> tense")

-- Lazy time decay frees sparse storage cleanly without per-tick loops
local decayedState = Agitation.GetState(ally.id, now + 4500 + 200000)
T.equal(decayedState.score, 0, "lazy decay reaches 0 after elapsed idle seconds")
T.equal(Agitation.GetActiveCount(), 0, "decayed NPC pruned automatically from sparse AgitationService")
PNC.TaskLeaseService.ForNPC = function() return nil end

-- =========================================================================
-- 4. ScenarioScheduler: time-of-day scenario chaining & intra-band boost
-- =========================================================================
local colonist = { id = "npc-col", alive = true, x = 50, y = 50, z = 0, tags = { "colony" }, runtime = {} }
local sMorning = ScenarioScheduler.GetActiveScenario(colonist, 8.0)
local sAfternoon = ScenarioScheduler.GetActiveScenario(colonist, 14.0)
local sEvening = ScenarioScheduler.GetActiveScenario(colonist, 19.0)
T.equal(sMorning.id, "scenario.morning_chores", "8:00 selects morning_chores")
T.equal(sAfternoon.id, "scenario.afternoon_work", "14:00 chains to afternoon_work")
T.equal(sEvening.id, "scenario.evening_lounge", "19:00 chains to evening_lounge")
local boost = ScenarioScheduler.GetScenarioBoostForAd(colonist, "ad.social_lounge", 19.0)
T.truthy(boost > 0, "evening_lounge provides intra-band boost to ad.social_lounge")

-- =========================================================================
-- 5. SecondaryChannel: coincident gaze guard, exhaustion decay, delta replication, recycle cleanup
-- =========================================================================
local gazeCalls = 0
local animVars = {}
local fakeBody = {
    getX = function() return 100.0 end,
    getY = function() return 100.0 end,
    faceLocationF = function() gazeCalls = gazeCalls + 1 end,
    setVariable = function(_, k, v) animVars[k] = v end,
}

local cOk, cReason = Secondary.ApplyGazeToBody(fakeBody, 100.01, 100.0)
T.falsy(cOk, "coincident gaze target must be rejected before calling faceLocationF")
T.equal(cReason, "COINCIDENT_TARGET", "expected COINCIDENT_TARGET reason")
T.equal(gazeCalls, 0, "faceLocationF must NOT be called for coincident target")

local okGaze = Secondary.ApplyGazeToBody(fakeBody, 104.0, 103.0)
T.truthy(okGaze and gazeCalls == 1, "non-coincident target invokes faceLocationF")

-- Bark speech priority gating + multiplicative line-exhaustion decay
local barkRec = { id = "npc-bark", alive = true, runtime = {} }
local b1Ok = Secondary.RequestBark(barkRec, "bark.pain_shout", now) -- priority 90
T.truthy(b1Ok, "initial high-priority bark succeeds")
local bLowOk, bLowErr = Secondary.RequestBark(barkRec, "bark.whisper_check", now + 200) -- pri 45 < 90
T.falsy(bLowOk, "active higher-priority bark suppresses lower-priority whisper")
T.equal(bLowErr, "LOWER_SPEECH_PRIORITY", "expected LOWER_SPEECH_PRIORITY")

-- Exhaustion decay (bark.alert_hey decay = 0.5: 1 -> 0.5 -> 0.25 -> 0.125 < 0.15 => BARK_EXHAUSTED)
local exhaustedReason = nil
for attempt = 1, 6 do
    local ok, err = Secondary.RequestBark(barkRec, "bark.alert_hey", now + attempt * 7000)
    if not ok then
        exhaustedReason = err
        break
    end
end
T.equal(exhaustedReason, "BARK_EXHAUSTED",
    "repeated identical bark without rest must decay below play threshold")

-- Lazy recovery restores line after waiting without needing per-tick decay loops
local recoveredOk = Secondary.RequestBark(barkRec, "bark.alert_hey", now + 180000)
T.truthy(recoveredOk, "line exhaustion must lazily recover over time")

-- Delta payload + ApplyClientSnapshot + Voice cleanup on demotion/abstraction
local voiceStopped = 0
local voicePlayed = 0
PNC.NPCVoice = {
    MODE_WORLD = "world",
    Catalog = Catalog,
    PlayWorld = function() voicePlayed = voicePlayed + 1; return 1 end,
    PlayLocal = function() voicePlayed = voicePlayed + 1; return 1 end,
    Stop = function() voiceStopped = voiceStopped + 1; return true end,
}

Secondary.SetAlertLevel(barkRec, "tense")
Secondary.SetPosture(barkRec, "crouch")
Secondary.SetSecondaryState(barkRec, "warn", nil, 4000, now + 180000)
Secondary.RequestGaze(barkRec, 110, 112, 3000, now + 180000)
local deltaPayload = Secondary.BuildDeltaPayload(barkRec, now + 180000)
T.truthy(deltaPayload and deltaPayload.alertLevel == "tense" and deltaPayload.posture == "crouch",
    "BuildDeltaPayload must serialize non-default secondary variables and gaze")

local modData = {}
local applied = Secondary.ApplyClientSnapshot({
    id = barkRec.id,
    secondaryChannel = deltaPayload,
}, fakeBody, modData)
T.truthy(applied and animVars.PNCAlertLevel == "tense" and animVars.PNCPosture == "crouch",
    "ApplyClientSnapshot must write Build 42 AnimSet variables onto live body")
T.equal(voicePlayed, 1, "first barkSeq triggers NPCVoice once")
-- Duplicate snapshot frame with same barkSeq must not replay audio
Secondary.ApplyClientSnapshot({ id = barkRec.id, secondaryChannel = deltaPayload }, fakeBody, modData)
T.equal(voicePlayed, 1, "duplicate snapshot with same barkSeq must not replay bark audio")

-- Abstraction & recycle cleanup
Secondary.ClearForRecord(barkRec, fakeBody)
T.equal(animVars.PNCAlertLevel, "calm", "ClearForRecord/ClearAnimVars resets PNCAlertLevel")
T.equal(animVars.PNCPosture, "relaxed", "ClearForRecord/ClearAnimVars resets PNCPosture")
T.equal(barkRec.runtime.secondaryChannel, nil, "ClearForRecord frees runtime secondaryChannel")

-- DomainDeltas routing check
PNC.Network = { Internal = { SnapshotParts = {}, PresencePayload = {} } }
package.preload["PNC/Core/Networking/PNC_MultiplayerBodyBinding"] = function()
    return { Projection = function() return nil, nil, nil end }
end
T.load("ProjectHoomans", "shared", "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DomainDeltas.lua")
T.equal(PNC.Network.ResolveEventDeltaKind("secondary_channel"), "presence",
    "secondary_channel delta event routes to presence domain")

-- =========================================================================
-- 6. BuildBrain + ColonistDebugRows integration
-- =========================================================================
local qRecord = {
    id = "npc-dbg",
    alive = true,
    x = 10,
    y = 10,
    z = 0,
    tags = { "colony" },
    runtime = {},
}
records[qRecord.id] = qRecord
PerceptionSvc.RecordClue(qRecord, { key = "c1", kind = "sound", x = 12, y = 12, z = 0 }, now)
Agitation.ApplyTrigger(qRecord, "weapon_draw", "p1", now)
ScenarioScheduler.GetActiveScenario(qRecord, 19.0)

local qBrain = PNC.Tasking.Queries.BuildBrain(qRecord.id)
T.truthy(qBrain.agitation and qBrain.agitation.stage == "wary",
    "BuildBrain must attach agitation state")
T.equal(qBrain.clueCount, 1, "BuildBrain must attach clueCount")
T.equal(qBrain.scenarioId, "scenario.evening_lounge", "BuildBrain must attach active scenarioId")
T.truthy(qBrain.secondaryChannel and qBrain.secondaryChannel.alertLevel == "wary",
    "BuildBrain must attach compact secondaryChannel summary")

local DebugRows = T.load("ProjectHoomans", "client", "PNC/UI/Colonist/PNC_ColonistDebugRows.lua")
local noBrain = DebugRows.Build({ id = qRecord.id, needs = {}, runtime = {} }, {}, {})
for i = 1, #noBrain do
    T.falsy(tostring(noBrain[i].key or ""):find("^debug_ai_"),
        "ColonistDebugRows must emit zero AI rows when Debug/taskBrain inactive")
end
local withBrain = DebugRows.Build({ id = qRecord.id, needs = {}, runtime = {}, taskBrain = qBrain }, {}, {})
local foundReactivity = false
for i = 1, #withBrain do
    if withBrain[i].key == "debug_ai_reactivity" then foundReactivity = withBrain[i] end
end
T.truthy(foundReactivity, "ColonistDebugRows must render debug_ai_reactivity when taskBrain present")
T.contains(foundReactivity.detail, "scenario.evening_lounge",
    "debug_ai_reactivity row must report active scenarioId")

T.finish("pnc_u4_reactivity_secondary_smoke")
