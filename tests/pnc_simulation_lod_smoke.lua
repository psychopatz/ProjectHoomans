local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

PNC = {
    Const = {
        PRESENCE_ABSTRACT = "abstract",
        ORDER_GUARD = "guard",
        ORDER_FOLLOW = "follow",
        ABSTRACT_NEAR_DISTANCE = 80,
        TICK_ABSTRACT_MS = 3000,
        TICK_ABSTRACT_FAR_MS = 15000,
        TICK_ABSTRACT_DORMANT_MS = 60000,
        TICK_LIVE_HOT_MS = 100,
        TICK_LIVE_WARM_MS = 250,
        TICK_LIVE_COLD_MS = 1000,
        SIMULATION_LIVE_IDLE_MS = 1000,
        SIMULATION_VITALS_HOT_MS = 250,
        SIMULATION_VITALS_LIVE_MS = 1000,
        SIMULATION_VITALS_ABSTRACT_MS = 5000,
        SIMULATION_PRESENCE_LIVE_MS = 500,
        SIMULATION_PRESENCE_ABSTRACT_MS = 3000,
        SIMULATION_PATH_HOT_MS = 50,
        SIMULATION_PATH_MOVING_MS = 100,
        SIMULATION_PATH_IDLE_MS = 500,
        FOLLOW_TICK_INTERVAL_MS = 100,
        FOLLOW_DECISION_INTERVAL_MS = 100,
        FOLLOW_IDLE_TICK_INTERVAL_MS = 350,
        ROAM_IDLE_TICK_INTERVAL_MS = 500,
        ABSTRACT_TRAVEL_SPEED = 1.6666667,
        TICK_ABSTRACT_MS = 3000,
    },
}
PNC.Travel = {
    Model = {
        IsActive = function(journey)
            return journey and journey.state == "en_route" or false
        end,
    },
}

T.load(ROOT .. "Scheduling/PNC_SimulationClock.lua")
T.load(ROOT .. "Scheduling/PNC_SimulationLOD.lua")

local far = {
    x = 0,
    y = 0,
    presenceState = "abstract",
    orderSpec = { kind = "roam" },
    health = { current = 100, max = 100 },
    runtime = {},
}
T.truthy(PNC.SimulationLOD.Resolve(far) == "abstract_far",
    "far active NPC received the wrong LOD")
T.truthy(PNC.SimulationLOD.GetCadence(far) == 15000,
    "far abstract cadence was not reduced")

local travelling = {
    x = 0,
    y = 0,
    presenceState = "abstract",
    orderSpec = { kind = "travel" },
    travel = { state = "en_route" },
    health = { current = 100, max = 100 },
    runtime = {},
}
T.truthy(PNC.SimulationLOD.Resolve(travelling) == "abstract_travel",
    "abstract journey did not receive the travel LOD")
T.truthy(PNC.SimulationLOD.GetCadence(travelling) == 3000,
    "abstract journey cadence is incorrect")

local dormant = {
    x = 0,
    y = 0,
    anchorX = 0,
    anchorY = 0,
    presenceState = "abstract",
    orderSpec = { kind = "guard", x = 0, y = 0 },
    health = { current = 100, max = 100 },
    runtime = {},
}
T.truthy(PNC.SimulationLOD.Resolve(dormant) == "abstract_dormant",
    "stationary far guard did not become dormant")
T.truthy(PNC.SimulationLOD.GetCadence(dormant) == 60000,
    "dormant cadence is incorrect")

far.runtime.nearestPlayerDistSq = 25
T.truthy(PNC.SimulationLOD.Resolve(far) == "abstract_near",
    "near abstract NPC did not wake to the near tier")
T.truthy(PNC.SimulationLOD.GetCadence(far) == 3000,
    "near abstract cadence is incorrect")

far.runtime.forcePresenceCheck = true
T.truthy(PNC.SimulationLOD.Resolve(far) == "presence_wake"
    and PNC.SimulationLOD.GetCadence(far) == 50,
    "deferred materialization did not retain its fast wake cadence")
far.runtime.forcePresenceCheck = nil

local follower = {
    x = 0,
    y = 0,
    presenceState = "live",
    orderSpec = { kind = "follow" },
    health = { current = 100, max = 100 },
    runtime = {},
}
T.truthy(PNC.SimulationLOD.Resolve(follower) == "follow_owner",
    "stationary follower was incorrectly classified as idle")
T.truthy(PNC.SimulationLOD.GetCadence(follower) == 100,
    "stationary follower retained the one-second wake delay")
T.truthy(PNC.SimulationLOD.GetDecisionInterval(follower) == 100,
    "moving-owner decisions were not refreshed responsively")
T.truthy(PNC.SimulationLOD.GetPathInterval(follower) == 100,
    "follow path pumping remained on the idle cadence")

-- Once a follower has acquired and is holding formation beside a stationary
-- owner, it must leave the 100 ms hot tier. This is the common steady-state
-- case for groups and is where population-scale savings matter most.
follower.runtime.followState = {
    mode = "formation_hold",
    ownerMoving = false,
}
T.truthy(PNC.SimulationLOD.Resolve(follower) == "follow_idle",
    "stationary formation follower remained in the hot tier")
T.truthy(PNC.SimulationLOD.GetCadence(follower) == 350,
    "stationary formation follower did not receive the cool cadence")
T.truthy(PNC.SimulationLOD.GetDecisionInterval(follower) == 350,
    "stationary follower decisions were not throttled")
T.truthy(PNC.SimulationLOD.GetPathInterval(follower) == 500,
    "stationary follower kept pumping an inactive path")

-- Owner movement/path acquisition must wake the follower immediately on its
-- next scheduled decision and return path servicing to the moving cadence.
follower.runtime.followState.ownerMoving = true
T.truthy(PNC.SimulationLOD.Resolve(follower) == "follow_owner",
    "moving owner did not wake a stationary follower")
T.truthy(PNC.SimulationLOD.GetCadence(follower) == 100,
    "moving owner did not restore responsive follow cadence")
follower.runtime.followState.ownerMoving = false
follower.runtime.pathing = { phase = "active" }
T.truthy(PNC.SimulationLOD.Resolve(follower) == "follow_owner",
    "active follow path was incorrectly cooled")
T.truthy(PNC.SimulationLOD.GetPathInterval(follower) == 100,
    "active follow path did not retain its moving pump cadence")

-- A completed moveIntent is historical bookkeeping, not proof that an NPC is
-- still moving. Treating it as live kept roamers hot forever and prevented
-- ambient scenes from becoming eligible.
local idleRoamer = {
    x = 0,
    y = 0,
    presenceState = "live",
    orderSpec = { kind = "roam" },
    health = { current = 100, max = 100 },
    runtime = {
        moveIntent = { kind = "move" },
        roaming = { phase = "idle" },
    },
}
T.truthy(PNC.SimulationLOD.Resolve(idleRoamer) == "roam_idle",
    "stale move intent kept an idle roamer in the moving tier")
T.truthy(PNC.SimulationLOD.GetCadence(idleRoamer) == 500,
    "idle roamer did not receive the population-safe cadence")
T.truthy(PNC.SimulationLOD.GetPathInterval(idleRoamer) == 500,
    "idle roamer kept pumping an inactive path")

T.truthy(PNC.SimulationClock.IsDue(far, "vitals", 1000, 5000, false),
    "new subsystem clock was not due")
T.truthy(not PNC.SimulationClock.IsDue(far, "vitals", 2000, 5000, false),
    "subsystem clock ignored its independent deadline")
PNC.SimulationClock.Wake(far, "vitals", 2000)
T.truthy(PNC.SimulationClock.IsDue(far, "vitals", 2000, 5000, false),
    "woken subsystem clock did not run")

PNC.PathService = {
    Internal = {
        Core = {
            Distance = function(x1, y1, x2, y2)
                local dx = x2 - x1
                local dy = y2 - y1
                return math.sqrt(dx * dx + dy * dy)
            end,
        },
    },
}
T.load(ROOT .. "Pathing/PNC_PathService/PNC_PathService_Motion.lua")

far.x = 0
far.y = 0
far.z = 0
far.runtime.abstractStepElapsedMs = 15000
PNC.PathService.AdvanceAbstract(far, 100, 0, 0, 0)
T.truthy(math.abs(far.x - 25) < 0.001,
    "abstract travel speed changed with the slower cadence")
T.finish("pnc_simulation_lod_smoke")

T.finish("pnc_simulation_lod_smoke")
