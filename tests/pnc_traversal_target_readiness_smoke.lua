local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local squares = {}
local function key(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function put(x, y, z)
    squares[key(x, y, z)] = {}
end

put(10, 20, 0)
put(11, 20, 0)
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[key(x, y, z)]
        end,
    }
end

PNC = {
    Const = {},
    EnginePathPlanner = { Internal = {} },
    TraversalQuery = {
        GetSquare = function(x, y, z)
            return squares[key(x, y, z)]
        end,
    },
}

local Internal = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/"
        .. "PNC_EnginePathPlanner_Context_RoutePolicy.lua"
)

local record = { id = "readiness" }
local body = {}
local ready, reason = Internal.CheckTargetReadiness(
    record,
    body,
    { x = 10.5, y = 20.5, z = 0 },
    {}
)
T.truthy(ready, reason or "loaded target should be ready")
T.equal(reason, "target_ready", "loaded target readiness reason")

ready, reason = Internal.CheckTargetReadiness(
    record,
    body,
    { x = 30.5, y = 20.5, z = 0 },
    {}
)
T.falsy(ready, "unloaded target must defer native routing")
T.equal(reason, "target_chunk_unloaded", "unloaded target reason")

ready, reason = Internal.CheckTargetReadiness(
    record,
    body,
    { x = 10.5, y = 20.5, z = 0 },
    {
        targetValidation = "shoreline_pair",
        targetWaterX = 40.5,
        targetWaterY = 20.5,
        targetWaterZ = 0,
    }
)
T.falsy(ready, "unloaded fishing water must defer native routing")
T.equal(reason, "fishing_water_chunk_unloaded",
    "unloaded fishing water reason")

local pathCalls = 0
PNC.EnginePathPlanner.CanUseNativePath = function()
    return true
end
PNC.EnginePathPlanner.Internal.IsMultiplayerAuthority = function()
    return false
end
PNC.EnginePathPlanner.Internal.ClearEngineRequest = function() end
PNC.EnginePathPlanner.Internal.EnsureNativeMovementOwner = function() end
PNC.EnginePathPlanner.Internal.GetPathBehavior = function()
    return {
        pathToLocation = function()
            pathCalls = pathCalls + 1
        end,
    }
end
PNC.EnginePathPlanner.Internal.SetServerMovementLease = function() end
PNC.EnginePathPlanner.Internal.GetPathBehavior =
    PNC.EnginePathPlanner.Internal.GetPathBehavior
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/"
        .. "PNC_EnginePathPlanner_Request.lua"
)

local navigation = {
    record = record,
    provider = "engine_path",
    targetValidation = "shoreline_pair",
    targetWaterX = 40.5,
    targetWaterY = 20.5,
    targetWaterZ = 0,
}
local requested = Internal.BeginRequest(
    body,
    { x = 10.5, y = 20.5, z = 0, stopDistance = 0.7 },
    navigation,
    1000,
    "test"
)
T.falsy(requested, "native request must wait for unloaded fishing water")
T.equal(navigation.lastPlanReason, "fishing_water_chunk_unloaded",
    "native request exposes the readiness reason")
T.equal(pathCalls, 0, "native path was not started for an unloaded target")

T.finish("pnc_traversal_target_readiness_smoke")
