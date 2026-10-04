local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = { Const = {}, EnginePathPlanner = {} }
local stateChanges = 0
local movingWrites = 0
ZombieIdleState = {
    instance = function() return "idle" end,
}

local body = {
    getActionStateName = function() return "WalkToward" end,
    getCurrentStateName = function() return "WalkTowardState" end,
    getPath2 = function() return {} end,
    changeState = function() stateChanges = stateChanges + 1 end,
    setMoving = function(_, value)
        movingWrites = movingWrites + 1
        T.falsy(value, "native owner fence clears stale moving flag")
    end,
}

local Internal = T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/"
        .. "PNC_EnginePathPlanner_Context_NativeState.lua")

T.truthy(Internal.EnsureNativeMovementOwner(body),
    "native owner fence releases stale WalkToward state")
T.truthy(PNC.EnginePathPlanner.ReconcileNativeMovementOwner(body),
    "public owner fence exposes the final engine boundary")
T.equal(stateChanges, 2, "both owner-fence entry points use idle transition")

body.getActionStateName = function() return "WalkTowardNetwork" end
T.truthy(PNC.EnginePathPlanner.ReconcileNativeMovementOwner(body),
    "network walk state is also reconciled")

body.getActionStateName = function() return "WalkToward" end
body.getPath2 = function() return nil end
T.falsy(PNC.EnginePathPlanner.ReconcileNativeMovementOwner(body),
    "walk state remains intact until Behavior2 publishes path2")
T.equal(movingWrites, 0, "native owner fence preserves the movement flag")

T.finish("pnc_engine_native_owner_smoke")
