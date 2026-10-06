local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local nearestByID = {}
local logs = {}
local wakeCount = 0

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 28,
        ABSTRACT_DISTANCE = 40,
    },
    Core = {
        Now = function() return now end,
    },
    PerformanceScalingDiagnostics = {
        PresenceTraversalAuditEnabled = false,
        IsPresenceTraversalAuditEnabled = function()
            return PNC.PerformanceScalingDiagnostics
                .PresenceTraversalAuditEnabled == true
        end,
        LogPresenceTraversal = function(eventName, fields)
            logs[#logs + 1] = {
                event = eventName,
                fields = fields,
            }
            return true
        end,
    },
    Presence = {
        Internal = {
            FindNearestPlayer = function(record)
                return nearestByID[record.id]
            end,
        },
    },
    SimulationClock = {
        Wake = function() wakeCount = wakeCount + 1 end,
    },
}

local Presence = PNC.Presence
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions.lua"
)

local body = {
    getX = function() error("disabled audit read body X") end,
    getY = function() error("disabled audit read body Y") end,
    getZ = function() error("disabled audit read body Z") end,
}
local record = {
    id = "traversal-audit",
    name = "Traversal Audit",
    x = 100,
    y = 100,
    z = 0,
    alive = true,
    presenceState = "live",
    presenceRevision = 4,
    runtime = {
        bodyLease = "body:4",
        nearestPlayerDistSq = nil,
    },
}

-- Disabled diagnostics do not inspect the body or allocate an event payload.
Presence.Internal.LogTraversal(record, "disabled", body)
T.equal(#logs, 0, "disabled traversal audit emitted a log")

PNC.PerformanceScalingDiagnostics.PresenceTraversalAuditEnabled = true
Presence.Internal.LogTraversal(record, "enabled", nil, { "reason=test" })
T.equal(#logs, 1, "enabled traversal audit did not emit a log")
T.equal(logs[1].event, "enabled", "wrong traversal audit event")

nearestByID[record.id] = { distSq = 80 * 80 }
T.truthy(
    Presence.RequestTraversalHandoff(record, "native_progress_timeout"),
    "off-screen non-Travel handoff was not requested"
)
T.truthy(
    record.runtime.presenceHandoffRequested,
    "handoff request was not persisted on the runtime record"
)
T.falsy(
    Presence.ShouldMaterialize(record, nearestByID[record.id]),
    "handoff request pulled an off-screen NPC back into live mode"
)
T.truthy(
    Presence.ShouldAbstract(record, nearestByID[record.id]),
    "off-screen handoff request did not authorize abstraction"
)
T.equal(wakeCount, 1, "handoff request did not wake the presence scheduler")

Presence.ClearTraversalHandoff(record, "test_clear")
nearestByID[record.id] = { distSq = 10 * 10 }
T.falsy(
    Presence.RequestTraversalHandoff(record, "visible_stall"),
    "visible NPC was handed off instead of staying embodied"
)
T.falsy(
    record.runtime.presenceHandoffRequested,
    "visible stall left an off-screen handoff request behind"
)

-- The native pump rejects stale/abstract requests before touching movement.
local clearCount = 0
local pumpLogCount = #logs
PNC.EnginePathPlanner = {
    Internal = {
        ClearEngineRequest = function(_, navigation)
            clearCount = clearCount + 1
            navigation.nativeActive = false
        end,
    },
}
PNC.BodyLifecycle = {
    Internal = {
        matchesRecordBody = function() return true end,
    },
}
PNC.ActorControl = nil
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Pump.lua"
)

local abstractRecord = {
    id = "abstract-pump",
    presenceState = "abstract",
    presenceRevision = 9,
    runtime = {
        localNavigation = {
            provider = "engine_path",
            nativeActive = true,
        },
    },
}
local pumpBody = {
    getActionStateName = function() return "idle" end,
}
local pumped, pumpReason = PNC.EnginePathPlanner.Pump(
    abstractRecord,
    pumpBody,
    "test"
)
T.falsy(pumped, "abstract NPC was physically pumped")
T.equal(pumpReason, "presence_not_live", "wrong abstract pump rejection")
T.equal(clearCount, 1, "stale abstract native request was not cleared")
T.equal(#logs, pumpLogCount + 1, "stale pump rejection was not audited")

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Frames.lua"
)
local directPump, directPumpReason = PNC.EnginePathPlanner.PumpFrame(
    abstractRecord,
    pumpBody
)
T.falsy(directPump, "abstract NPC entered the frame pump")
T.equal(
    directPumpReason,
    "presence_not_live",
    "wrong direct frame pump rejection"
)
T.equal(clearCount, 2, "direct abstract frame pump was not cleared")

local staleRecord = {
    id = "stale-revision",
    presenceState = "live",
    presenceRevision = 2,
    runtime = {
        bodyLease = "body:new",
        localNavigation = {
            provider = "engine_path",
            nativeActive = true,
            presenceRevision = 1,
            bodyLease = "body:old",
        },
    },
}
local stalePumped, staleReason = PNC.EnginePathPlanner.Pump(
    staleRecord,
    pumpBody,
    "test"
)
T.falsy(stalePumped, "stale presence revision was physically pumped")
T.equal(
    staleReason,
    "stale_presence_revision",
    "wrong stale presence revision rejection"
)
T.equal(clearCount, 3, "stale revision native request was not cleared")

-- A non-Travel native stall requests the same generic off-screen handoff
-- used by fishing and work lanes instead of completing the activity as a
-- permanent blocked failure.
local nativeHandoffCalls = 0
local nativeAuditCalls = 0
local completeCalls = 0
PNC.Presence.RequestTraversalHandoff = function(stalledRecord, reason)
    nativeHandoffCalls = nativeHandoffCalls + 1
    stalledRecord.runtime.handoffReason = reason
    return true
end
PNC.Presence.Internal.LogTraversal = function()
    nativeAuditCalls = nativeAuditCalls + 1
end
PNC.NavigationRouter = {}
PNC.PathService = {
    Internal = {
        Core = {
            Distance = function(x1, y1, x2, y2)
                local dx = x2 - x1
                local dy = y2 - y1
                return math.sqrt(dx * dx + dy * dy)
            end,
        },
        PROGRESS_TIMEOUT_MS = 100,
        LOCOMOTION_VISUAL_LEASE_MS = 100,
        describeGoal = function() return "goal" end,
        logMoveWarning = function() end,
        logMoveDebug = function() end,
        isAtGoal = function() return false end,
        tryNativeStallPassage = function() return false end,
        syncRecordPosition = function() end,
        applyHoldAnimation = function() end,
        completeMove = function()
            completeCalls = completeCalls + 1
            return true, "blocked"
        end,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionNativeProgress.lua"
)
local stalledRecord = {
    id = "native-handoff",
    presenceState = "live",
    runtime = {},
}
local stalledLane = {
    goal = { x = 5, y = 0, z = 0 },
    bestGoalDistance = 5,
    lastGoalProgressAt = 0,
    lastProgressAt = 0,
    noProgressCount = 2,
    nativeStallRecoveryCount = 2,
    visualMovingUntil = 0,
}
local stalledBody = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local handled, state = PNC.PathService.Internal.recordNativeMove(
    stalledRecord,
    stalledBody,
    stalledLane,
    {},
    { Invalidate = function() end },
    200,
    nil,
    0,
    0,
    0
)
T.truthy(handled, "terminal non-Travel native stall was not handled")
T.equal(
    state,
    "presence_handoff_requested",
    "non-Travel native stall completed as blocked instead of handing off"
)
T.equal(nativeHandoffCalls, 1, "native stall did not request one handoff")
T.truthy(nativeAuditCalls > 0, "native stall was not sent to traversal audit")

-- FollowOwner retains its durable owner target and must not become a blocked
-- fake-locomotion lane. Its native provider retries first; a later off-screen
-- stall may be handed to the normal Presence range decision.
local followRecord = {
    id = "follow-native-handoff",
    presenceState = "live",
    orderSpec = { kind = "follow" },
    runtime = {},
}
local followLane = {
    goal = { x = 5, y = 0, z = 0 },
    bestGoalDistance = 5,
    lastGoalProgressAt = 0,
    lastProgressAt = 0,
    noProgressCount = 2,
    nativeStallRecoveryCount = 2,
    visualMovingUntil = 0,
    intentReason = "follow_owner_walk",
    requestedOrder = "follow",
}
local _, followState = PNC.PathService.Internal.recordNativeMove(
    followRecord,
    stalledBody,
    followLane,
    {},
    { Invalidate = function() end },
    200,
    nil,
    0,
    0,
    0
)
T.equal(
    followState,
    "native_repath",
    "follow native stall did not retain native provider ownership"
)
T.equal(nativeHandoffCalls, 1,
    "follow native stall requested the generic handoff")
T.equal(completeCalls, 0,
    "follow native stall changed the existing non-follow completion count")

T.finish("pnc_presence_traversal_audit_smoke")
