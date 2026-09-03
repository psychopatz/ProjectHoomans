local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local idleState = { name = "idle" }
ZombieIdleState = {
    instance = function() return idleState end,
}

PNC = {
    Core = { Now = function() return now end },
    Const = {
        NATIVE_BUMP_STALE_GRACE_MS = 750,
        NATIVE_STALL_BACKOFF_MS = 5000,
    },
    Animation = {
        IsBumpActionActive = function(body)
            return body.ownedBump == true
        end,
        IsCombatBumpActionActive = function(body)
            return body.ownedBump == true
        end,
    },
    EnginePathPlanner = { Internal = {} },
}

local body = {
    actionState = "bumped",
    bumpType = "",
    path2 = nil,
    modData = {},
    variables = {},
    getActionStateName = function(self) return self.actionState end,
    getPath2 = function(self) return self.path2 end,
    getModData = function(self) return self.modData end,
    setBumpDone = function(self, value) self.bumpDone = value end,
    setVariable = function(self, name, value)
        self.variables[name] = value
    end,
    reportEvent = function(self, event) self.reportedEvent = event end,
    setBumpType = function(self, value) self.bumpType = value end,
    changeState = function(self, state)
        self.actionState = state and state.name or "idle"
    end,
}
local lane = { nativeStallRecoveryCount = 0 }
local navigation = {
    provider = "engine_path",
    nativeActive = true,
}
local record = { id = "darin", runtime = {
    pathing = lane,
    localNavigation = navigation,
} }

local invalidations = 0
PNC.EnginePathPlanner.Invalidate = function(_, reason)
    invalidations = invalidations + 1
    navigation.nativeActive = false
    navigation.lastPlanReason = reason
    return true
end

local Internal = T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/"
    .. "PNC_EnginePathPlanner_Context_NativeState.lua")

local recovered, state = Internal.RecoverStaleNativeBump(
    record, body, navigation, now
)
T.falsy(recovered, "first bumped observation receives a grace period")
now = 1800
recovered, state = Internal.RecoverStaleNativeBump(
    record, body, navigation, now
)
T.truthy(recovered, "stale native bump is recovered")
T.equal(state, "native_stale_bump_released", "first recovery state")
T.equal(body.actionState, "idle", "stale bumped state returns to idle")
T.equal(body.bumpType, "", "stale bump selector is cleared")
T.truthy(body.bumpDone, "stale bump completion is published")
T.truthy(body.variables.BumpAnimFinished,
    "stale bump animation completion is published")
T.equal(body.reportedEvent, "ActiveAnimFinishing",
    "stale bump completion event is published")
T.equal(lane.nativeStallRecoveryCount, 1,
    "first stale bump increments recovery count")
T.truthy(Internal.InvalidateRecoveredNativeBump(
    record, body, navigation, state
), "stale bump invalidates its native request")
T.equal(invalidations, 1, "stale bump invalidates once")
T.falsy(navigation.nativeActive, "stale bump releases native ownership")

body.actionState = "bumped"
navigation.nativeActive = true
now = 3000
recovered = Internal.RecoverStaleNativeBump(record, body, navigation, now)
T.falsy(recovered, "second bump observation receives a grace period")
now = 3800
recovered, state = Internal.RecoverStaleNativeBump(
    record, body, navigation, now
)
T.truthy(recovered, "repeated native bump enters backoff")
T.equal(state, "native_stall_backoff", "persistent bump backoff state")
T.equal(lane.ownerMode, "native_backoff", "lane records native backoff")
T.equal(lane.nativeBackoffUntil, 8800, "backoff has a bounded expiry")

PNC.PathService = {}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/Lane/"
    .. "PNC_PathService_Lane_TraversalStatus.lua")
lane.phase = "active"
local movement = PNC.PathService.GetMovementRecoveryState(
    record, body, now
)
T.falsy(movement.watchable,
    "task recovery does not cancel a bounded native backoff")
T.truthy(movement.nativeBackoff,
    "movement status exposes the native backoff")

body.actionState = "bumped"
body.ownedBump = true
navigation.nativeActive = true
now = 5000
recovered = Internal.RecoverStaleNativeBump(record, body, navigation, now)
T.falsy(recovered, "owned bump is not repaired by native recovery")
T.equal(body.actionState, "bumped", "owned bump remains action-owned")

PNC.Animation.Internal = {
    getActionStateName = function(value)
        return value.actionState
    end,
    setPNCStateVars = function() end,
    applyWalkType = function() end,
    setManagedUseless = function() end,
}
body.isMoving = function() return false end
PNC.Animation.IsBumpActionActive = function() return false end
T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_Animation/PNC_Animation_NativeLocomotion.lua")
body.actionState = "pathfind"
body.path2 = {}
navigation.lastPhysicalProgressAt = 1000
now = 3000
PNC.Animation.SyncNativeLocomotionStyle(body, record)
T.falsy(body.variables.PNCMoving,
    "stale native goal does not loop a movement animation")
navigation.lastPhysicalProgressAt = now
PNC.Animation.SyncNativeLocomotionStyle(body, record)
T.truthy(body.variables.PNCMoving,
    "fresh native physical progress selects movement animation")

T.finish("pnc_native_bump_recovery_smoke")
