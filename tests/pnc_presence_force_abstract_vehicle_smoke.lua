local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 28,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Presence = {
        Internal = {
            FindNearestPlayer = function()
                return { distSq = 4 }
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions.lua"
)

local abstractPolicyRecord = {
    alive = true,
    presenceState = "abstract",
    runtime = {
        forceAbstract = true,
    },
}
T.truthy(
    PNC.Presence.ShouldMaterialize(abstractPolicyRecord, { distSq = 4 }),
    "legacy force-abstract flag still blocked normal proximity"
)

local hardAbstractRecord = {
    alive = true,
    presenceState = "abstract",
    runtime = {
        hardAbstract = true,
    },
}
T.falsy(
    PNC.Presence.ShouldMaterialize(hardAbstractRecord, { distSq = 4 }),
    "explicit hard-abstract lock unexpectedly materialized"
)

local followHandoffRecord = {
    alive = true,
    presenceState = "abstract",
    runtime = {
        hardAbstract = true,
        forceLive = true,
        abstractFollowMaterializeRequested = true,
    },
}
T.truthy(
    PNC.Presence.ShouldMaterialize(followHandoffRecord, { distSq = 4 }),
    "explicit follow handoff could not override force-abstract policy"
)

local passengerRecord = {
    alive = true,
    presenceState = "abstract",
    runtime = {
        hardAbstract = true,
        forceLive = true,
        abstractFollowMaterializeRequested = true,
        vehiclePassenger = {
            active = true,
            vehicleId = "vehicle:test",
            seat = 1,
        },
    },
}
T.falsy(
    PNC.Presence.ShouldMaterialize(passengerRecord, { distSq = 4 }),
    "vehicle passenger was materialized by a live handoff"
)

passengerRecord.runtime.vehiclePassenger.active = false
T.truthy(
    PNC.Presence.ShouldMaterialize(passengerRecord, { distSq = 4 }),
    "disembarked passenger did not become eligible for materialization"
)

return T.finish("pnc_presence_force_abstract_vehicle_smoke")
