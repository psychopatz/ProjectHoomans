local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

PNC = {
    Const = {
        PRESENCE_ABSTRACT = "abstract",
        ORDER_GUARD = "guard",
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
        ABSTRACT_TRAVEL_SPEED = 1.6666667,
        TICK_ABSTRACT_MS = 3000,
    },
}

dofile(ROOT .. "Scheduling/PNC_SimulationClock.lua")
dofile(ROOT .. "Scheduling/PNC_SimulationLOD.lua")

local far = {
    x = 0,
    y = 0,
    presenceState = "abstract",
    orderSpec = { kind = "roam" },
    health = { current = 100, max = 100 },
    runtime = {},
}
assert(PNC.SimulationLOD.Resolve(far) == "abstract_far",
    "far active NPC received the wrong LOD")
assert(PNC.SimulationLOD.GetCadence(far) == 15000,
    "far abstract cadence was not reduced")

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
assert(PNC.SimulationLOD.Resolve(dormant) == "abstract_dormant",
    "stationary far guard did not become dormant")
assert(PNC.SimulationLOD.GetCadence(dormant) == 60000,
    "dormant cadence is incorrect")

far.runtime.nearestPlayerDistSq = 25
assert(PNC.SimulationLOD.Resolve(far) == "abstract_near",
    "near abstract NPC did not wake to the near tier")
assert(PNC.SimulationLOD.GetCadence(far) == 3000,
    "near abstract cadence is incorrect")

far.runtime.forcePresenceCheck = true
assert(PNC.SimulationLOD.Resolve(far) == "presence_wake"
    and PNC.SimulationLOD.GetCadence(far) == 50,
    "deferred materialization did not retain its fast wake cadence")
far.runtime.forcePresenceCheck = nil

assert(PNC.SimulationClock.IsDue(far, "vitals", 1000, 5000, false),
    "new subsystem clock was not due")
assert(not PNC.SimulationClock.IsDue(far, "vitals", 2000, 5000, false),
    "subsystem clock ignored its independent deadline")
PNC.SimulationClock.Wake(far, "vitals", 2000)
assert(PNC.SimulationClock.IsDue(far, "vitals", 2000, 5000, false),
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
dofile(ROOT .. "Pathing/PNC_PathService/PNC_PathService_Motion.lua")

far.x = 0
far.y = 0
far.z = 0
far.runtime.abstractStepElapsedMs = 15000
PNC.PathService.AdvanceAbstract(far, 100, 0, 0, 0)
assert(math.abs(far.x - 25) < 0.001,
    "abstract travel speed changed with the slower cadence")

print("pnc_simulation_lod_smoke: ok")
