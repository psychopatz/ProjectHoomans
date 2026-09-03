local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1500
PNC = {
    Core = { Now = function() return now end },
    PathService = { Internal = {} },
}

local PathService = T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_TraversalStatus.lua")
PathService = PNC.PathService

local lane = {
    phase = "active",
    navigationProvider = "engine_path",
    ownerMode = "engine_path",
    startedAt = 900,
    lastProgressAt = 1000,
    lastGoalProgressAt = 1100,
    lastPhysicalMoveAt = 1200,
    goalDistance = 8,
}
local record = { runtime = { pathing = lane,
    localNavigation = { provider = "engine_path", nativeActive = true } } }

local snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.truthy(snapshot.active, "active movement lane was not reported")
T.truthy(snapshot.watchable, "ordinary movement should be watchable")
T.equal(snapshot.lastProgressAt, 1200,
    "movement snapshot did not use the latest physical progress")
T.equal(snapshot.provider, "engine_path", "movement provider was not exposed")

lane.traversalAction = { kind = "fence_climb", hardFinishAt = 1700 }
snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.falsy(snapshot.watchable,
    "task recovery must not interrupt an in-flight passage owner")
T.equal(snapshot.traversalKind, "fence_climb",
    "passage owner was not exposed")

lane.traversalAction = nil
record.runtime.localNavigation.nativeTraversalState = "climb"
record.runtime.localNavigation.nativeTraversalStartedAt = 1000
now = 1500
snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.falsy(snapshot.watchable,
    "native engine traversal was exposed to task cancellation")
T.equal(snapshot.traversalKind, "native_climb",
    "native traversal owner was not exposed")

record.runtime.localNavigation.nativeTraversalState = nil
record.runtime.localNavigation.nativeTraversalStartedAt = 0
lane.traversalAction = { kind = "fence_climb", hardFinishAt = 1700 }
now = 1800
snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.truthy(snapshot.forceRecovery,
    "an expired passage deadline did not expose forced recovery")
T.truthy(snapshot.watchable,
    "an expired passage deadline remained hidden from recovery")

lane.phase = "idle"
lane.traversalAction = nil
snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.falsy(snapshot.active, "idle movement lane was reported as active")
T.falsy(snapshot.watchable, "idle movement lane was made watchable")

record.runtime.pathing = nil
snapshot = PathService.GetMovementRecoveryState(record, nil, now)
T.falsy(snapshot.active, "missing movement lane was reported as active")
T.falsy(snapshot.watchable, "missing movement lane was made watchable")
T.equal(snapshot.lastProgressAt, nil,
    "missing movement lane fabricated a fresh progress timestamp")

T.finish("pnc_path_service_recovery_smoke")
