local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "common_lua" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

local now = 100000
Events = {
    OnGameBoot = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    EveryTenMinutes = { Add = function() end },
    OnTick = { Add = function() end },
    OnWorldSound = { Add = function() end },
}
getText = function(key) return key end

require "PsychopatzCore/Composition/PC_SharedComposition"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local okShock, shockFacade = PsychopatzCore.Require("core.shocking_events", "u5_smoke")
local ShockBus = (okShock and type(shockFacade) == "table" and shockFacade)
    or PsychopatzCore.ShockingEventBus
T.truthy(ShockBus and type(ShockBus.Emit) == "function",
    "ShockingEventBus capability loads cleanly")
ShockBus.Reset()

local seq = 0
local records = {}
local cancelledTaskCount = 0

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
    },
    Registry = {
        Data = records,
        Get = function(id) return records[tostring(id or "")] end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y, r)
            local out = {}
            local r2 = (r or 16) * (r or 16)
            for _, rec in pairs(records) do
                if rec.alive ~= false and rec.x ~= nil and rec.y ~= nil then
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
    TaskPriority = {
        BANDS = {
            HARD_EMERGENCY = 1,
            CRITICAL_NEED = 2,
            FORCED_ORDER = 3,
            NORMAL_NEED = 4,
            HIGH_WORK = 5,
            NORMAL_WORK = 6,
            OPTIONAL = 7,
            IDLE = 8,
        },
        RANK = {
            HARD_EMERGENCY = 1,
            CRITICAL_NEED = 2,
            FORCED_ORDER = 3,
            NORMAL_NEED = 4,
            HIGH_WORK = 5,
            NORMAL_WORK = 6,
            OPTIONAL = 7,
            IDLE = 8,
        },
    },
    TaskLeaseService = {
        ByNPC = {},
        ForNPC = function(id) return PNC.TaskLeaseService.ByNPC[tostring(id or "")] end,
        CancelForNPC = function()
            cancelledTaskCount = cancelledTaskCount + 1
            return true
        end,
        Count = function()
            local c = 0
            for _ in pairs(PNC.TaskLeaseService.ByNPC) do c = c + 1 end
            return c
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Performance = {
        SafeCall = function(_, fn, ...)
            return true, fn(...)
        end,
    },
}

-- Load Tasking Claims + Core + Events + Queries, SecondaryChannel, ReactionPolicy, AgitationService
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
            reevaluations = 0,
            candidates = 0,
            preemptions = 0,
            facilityLookups = 0,
            executorTicks = 0,
            callbackFailures = 0,
            eventEmits = 0,
        },
        recentFailures = {},
        recentEvents = {},
    },
}
local Claims = require "PNC/Tasking/PNC_Tasking_Claims"
require "PNC/Tasking/Tasking/PNC_Tasking_Core"
require "PNC/Tasking/Tasking/PNC_Tasking_EventInbox"
require "PNC/Tasking/Tasking/PNC_Tasking_Queries"
require "PNC/ReactionPolicy/Registry"
require "PNC/Core/Visuals/PNC_SecondaryChannel"
require "PNC/Agitation/PNC_AgitationService"

-- 1. Verify single-artifact ConvoEngine Registry + compact DIRECTOR_INDEX
local ConversationRegistry = require "PNC/ConvoEngine/Registry"
local Catalog = require "PNC/ConvoEngine/Interaction/Catalog"
T.equal(#Catalog.Behaviors.List(), 30,
    "single-artifact ConvoEngine loads all 30 canonical behaviors")
T.equal(#Catalog.Beats.List(), 3,
    "single-artifact ConvoEngine loads all 3 canonical beats")
T.truthy(type(ConversationRegistry.DIRECTOR_INDEX) == "table"
    and type(ConversationRegistry.DIRECTOR_INDEX.byStimulus) == "table"
    and type(ConversationRegistry.DIRECTOR_INDEX.entries) == "table",
    "ConvoEngine Registry exposes compiled compact DIRECTOR_INDEX")
local warnIndex = ConversationRegistry.DIRECTOR_INDEX.entries["behavior.warn"]
T.truthy(warnIndex and warnIndex.act == "WARN",
    "DIRECTOR_INDEX entry carries act metadata")
T.equal(warnIndex.payload, nil,
    "DIRECTOR_INDEX does NOT duplicate semantic body payload")
T.equal(warnIndex.when, nil,
    "DIRECTOR_INDEX does NOT duplicate predicate AST")

-- Load U5b services
local SocialWitness = require "PNC/Social/PNC_SocialWitnessService"
local JointLease = require "PNC/ConvoEngine/Social/PNC_JointSceneLeaseService"
local DialogueDirector = require "PNC/ConvoEngine/Social/PNC_DialogueMicroBeatDirector"
local StreetInteraction = require "PNC/ConvoEngine/Social/PNC_StreetInteractionService"
local CoPresence = require "PNC/Tasking/Autonomy/PNC_CoPresenceService"
local DebugRows = require "PNC/UI/Colonist/PNC_ColonistDebugRows"

local alice = { id = "npc_alice", alive = true, x = 10, y = 10, z = 0, runtime = {}, social = Social.NewState() }
local bob = { id = "npc_bob", alive = true, x = 12, y = 10, z = 0, runtime = {}, social = Social.NewState() }
local carol = { id = "npc_carol", alive = true, x = 14, y = 10, z = 0, runtime = {}, social = Social.NewState() }
local blockedObs = { id = "npc_blocked", alive = true, x = 24, y = 10, z = 0, runtime = {}, social = Social.NewState() }
local distantObs = { id = "npc_distant", alive = true, x = 80, y = 80, z = 0, runtime = {}, social = Social.NewState() }
records[alice.id] = alice
records[bob.id] = bob
records[carol.id] = carol
records[blockedObs.id] = blockedObs
records[distantObs.id] = distantObs

-- 2. JointSceneLease: atomic 2-4 participants, partial failure rollback, SecondaryChannel without task cancellation, combat preemption
PNC.TaskLeaseService.ByNPC[alice.id] = { leaseId = "work:1", npcId = alice.id, precedence = "NORMAL_WORK", sourceDomain = "work", revision = 1 }
local busyOk, busyErr = JointLease.Acquire({
    participants = { alice, bob },
    speakerId = alice.id,
    responderId = bob.id,
}, now)
T.truthy(busyOk, "JointSceneLease acquires cleanly for idle/normal-work NPCs")
T.equal(cancelledTaskCount, 0,
    "JointSceneLease + SecondaryChannel never cancel active TaskLeaseService task leases")
T.equal(alice.runtime.secondaryChannel.posture, "conversing",
    "JointSceneLease sets conversing posture via SecondaryChannel")
T.equal(bob.runtime.secondaryChannel.secondaryState, "listening",
    "Responder enters non-interrupting listening SecondaryState")
T.truthy(Claims.Get("joint_scene:npc:" .. alice.id) ~= nil,
    "JointSceneLease registers claim in PNC.Tasking.Claims")

-- Partial failure rollback when carol + already-leased alice attempted together
local rollbackOk, rollbackReason = JointLease.Acquire({
    participants = { carol, alice },
    speakerId = carol.id,
    responderId = alice.id,
}, now)
T.falsy(rollbackOk, "JointSceneLease rejects partial busy participant")
T.equal(rollbackReason, "JOINT_SCENE_PARTICIPANT_BUSY",
    "Partial failure returns BUSY reason before leaking claims")
T.equal(Claims.Get("joint_scene:npc:" .. carol.id), nil,
    "Atomic rollback leaves zero leaked claims on uninvolved participant")

-- Emergency combat preemption aborts active JointSceneLease
PNC.TaskLeaseService.ByNPC[bob.id] = { leaseId = "combat:1", npcId = bob.id, precedence = "HARD_EMERGENCY", sourceDomain = "combat", revision = 1 }
PNC.Tasking.Events.Emit("TASK_LEASE_CREATED", {
    npcId = bob.id,
    entityId = "combat:1",
    source = "TaskLeaseService",
    payload = { taskId = "combat:1", sourceDomain = "combat", precedence = "HARD_EMERGENCY" },
}, { enqueue = false })
T.equal(JointLease.GetForNPC(alice.id), nil,
    "HARD_EMERGENCY TASK_LEASE_CREATED auto-aborts active JointSceneLease")
T.equal(Claims.Get("joint_scene:npc:" .. alice.id), nil,
    "Aborted JointSceneLease releases all claims")
PNC.TaskLeaseService.ByNPC[bob.id] = nil

-- 3. 5-stage Micro-Beat Director lifecycle + wait timeout + ephemeral tension discard + hearsay on close
DialogueDirector.Reset()
JointLease.Reset()
local startedOk, scene = DialogueDirector.StartScene({
    act = "GREET",
    speakerId = alice.id,
    responderId = bob.id,
    participants = { alice, bob, carol },
    firstContact = true,
    maxTurns = 4,
    waitTimeoutMs = 5000,
}, now)
T.truthy(startedOk, "MicroBeatDirector StartScene succeeds with 3 NPCs")
T.equal(scene.stage, "wait_with_timeout",
    "Director reaches wait_with_timeout after transition_in -> body -> local_or_global_mixin")
T.equal(scene.llmCalls, 0, "DialogueDirector executes with zero LLM calls")
T.equal(scene.stageHistory[1], "transition_in")
T.equal(scene.stageHistory[2], "body")
T.equal(scene.stageHistory[3], "local_or_global_mixin")
T.equal(scene.stageHistory[4], "wait_with_timeout")

-- 4. Non-fatal global mix-in interleaves and resumes cleanly
now = now + 1000
local mixOk, mixRes = DialogueDirector.InjectGlobalMixin(scene.sceneId, {
    mixinType = "bystander_bark",
    severity = "low",
    tensionDelta = 15,
    barkId = "bark.whisper_check",
}, now)
T.truthy(mixOk and mixRes.action == "interleaved",
    "Non-fatal global mix-in interleaves without aborting beat")
T.equal(scene.stage, "wait_with_timeout",
    "Scene resumes wait_with_timeout cleanly after non-fatal mix-in")

-- Wait timeout closes scene cleanly & discards ephemeral tension
now = now + 6000
local closedCount = DialogueDirector.SweepTimeouts(now)
T.equal(closedCount, 1, "SweepTimeouts closes expired waiting micro-beat scene")
T.equal(DialogueDirector.GetScene(scene.sceneId), nil,
    "Closed scene removes ephemeral state from ActiveScenes")
local aliceTel = DialogueDirector.GetActorTelemetry(alice.id)
T.truthy(aliceTel and aliceTel.closed == true and aliceTel.tension == nil,
    "Ephemeral local tension is discarded after transition_out")

-- Fatal HARD_EMERGENCY shocking event via PsychopatzShockingEventBus auto-aborts active JointScene
now = now + 1000
local ok2, scene2 = DialogueDirector.StartScene({
    act = "GREET",
    speakerId = alice.id,
    responderId = bob.id,
    participants = { alice, bob },
    maxTurns = 4,
}, now)
T.truthy(ok2 and DialogueDirector.GetScene(scene2.sceneId) ~= nil,
    "Second scene active before shocking event")
ShockBus.Emit({
    eventType = "shock.gunshot",
    x = alice.x,
    y = alice.y,
    z = 0,
    radius = 20,
    severity = "high",
    band = "HARD_EMERGENCY",
    sourceId = "raider_1",
    targetId = alice.id,
}, now)
T.equal(DialogueDirector.GetScene(scene2.sceneId), nil,
    "ShockingEventBus HARD_EMERGENCY gunshot cleanly aborts active JointScene")
T.equal(JointLease.GetForNPC(alice.id), nil,
    "ShockingEventBus abort releases JointSceneLease")

-- 5. RDR2 Street Interaction: GREET -> ANTAGONIZE -> DEFUSE (zero LLM calls)
DialogueDirector.Reset()
JointLease.Reset()
PNC.AgitationService.Clear(bob.id)
local playerObj = { id = "player_main", isPlayer = true, x = 11, y = 10, z = 0 }

local greetOk, greetRes = StreetInteraction.HandleStreetAct(playerObj, bob, "GREET", {
    at = now,
    firstContact = true,
    witnessCandidates = { bob, carol, blockedObs, distantObs },
    losCheck = function(obs) return obs.id ~= blockedObs.id end,
})
T.truthy(greetOk and greetRes.llmCalls == 0, "Street GREET succeeds with zero LLM calls")
T.equal(greetRes.beatId, "beat.suspicious_first_contact",
    "First-contact street GREET selects beat.suspicious_first_contact")

now = now + 2000
local antOk, antRes = StreetInteraction.HandleStreetAct(playerObj, bob, "ANTAGONIZE", {
    at = now,
    witnessCandidates = { bob, carol, blockedObs, distantObs },
    losCheck = function(obs) return obs.id ~= blockedObs.id end,
})
T.truthy(antOk and antRes.llmCalls == 0, "Street ANTAGONIZE succeeds with zero LLM calls")
T.equal(antRes.beatId, "beat.argument_escalation",
    "Street ANTAGONIZE transitions to beat.argument_escalation")
T.truthy(antRes.agitation and antRes.agitation.score >= 20,
    "Street ANTAGONIZE raises AgitationService score")

now = now + 2000
local defOk, defRes = StreetInteraction.HandleStreetAct(playerObj, bob, "DEFUSE", {
    at = now,
    witnessCandidates = { bob, carol, blockedObs, distantObs },
    losCheck = function(obs) return obs.id ~= blockedObs.id end,
})
T.truthy(defOk and defRes.llmCalls == 0, "Street DEFUSE succeeds with zero LLM calls")
T.equal(defRes.beatId, "beat.reconciliation",
    "Street DEFUSE selects beat.reconciliation")

-- 6. Witness-only PsychopatzSocial memory + hearsay spread (unobserved NPCs NEVER leak memories)
T.truthy(#(bob.social.memoryBank or {}) >= 1,
    "Direct target NPC recorded witnessed street memories")
T.truthy(#(carol.social.memoryBank or {}) >= 1,
    "In-range bystander NPC recorded witnessed street memories")
T.equal(#(blockedObs.social.memoryBank or {}), 0,
    "Out-of-hearing + LOS-blocked NPC recorded ZERO social memories")
T.equal(#(distantObs.social.memoryBank or {}), 0,
    "Out-of-range distant NPC recorded ZERO social memories")

-- Bounded 1-hop hearsay spread between carol (witness) and isolated distantObs (when conversing later)
local hearsay1 = SocialWitness.PropagateHearsay(carol, distantObs, { at = now + 5000 })
T.truthy(hearsay1 and hearsay1.ok == true and hearsay1.propagated == true,
    "Co-presence/dialogue close propagates 1 shareable memory as hearsay")
T.equal(hearsay1.hopCount, 1, "Hearsay sets hopCount = 1")
local hearsayMem = distantObs.social.memoryBank[1]
T.equal(hearsayMem.sourceMode, "hearsay", "Propagated memory marked sourceMode = hearsay")

-- Prevent duplicate bounce-back of same baseEventId when target already holds all shareable events from speaker
local dedupCountBefore = #(carol.social.memoryBank or {})
local hearsayDup = SocialWitness.PropagateHearsay(distantObs, carol, { at = now + 6000 })
T.falsy(hearsayDup.propagated, "Hearsay propagation does not bounce already-recorded baseEventId back")
T.equal(#(carol.social.memoryBank or {}), dedupCountBefore,
    "Listener memoryBank count unchanged on bounce-back check")

-- Closing active scene checks Debug GUI telemetry & ColonistDebugRows
local brain = PNC.Tasking.Queries.BuildBrain(bob.id)
T.truthy(brain and type(brain.dialogueDirector) == "table",
    "Tasking BuildBrain exposes dialogueDirector telemetry")
local rows = DebugRows.Build({ id = bob.id, taskBrain = brain }, { provisionStorage = {} })
local foundDialogueRow = false
for i = 1, #rows do
    if rows[i].key == "debug_ai_dialogue_director" then
        foundDialogueRow = true
        break
    end
end
T.truthy(foundDialogueRow, "ColonistDebugRows renders Dialogue Director debug row")

-- 7. CoPresenceService connects cleanly to SceneAdopters if present
local submittedSocial = 0
PNC.ConvoEngine.InteractionSceneAdopters = {
    SubmitSocial = function()
        submittedSocial = submittedSocial + 1
        return true, "ok"
    end,
}
CoPresence.Reset()
local cpOk, cpReason = CoPresence.TryTriggerForNPC(alice, now + 10000, {
    situationId = "situation.camp_chat",
    peers = { carol },
})
T.truthy(type(cpOk) == "boolean" and cpReason ~= nil, "CoPresenceService executes without error with SceneAdopters wired")

T.finish("pnc_u5_dialogue_director_smoke")
