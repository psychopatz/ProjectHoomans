local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_Presence.lua")
local now = 1000
local scheduled = 0
local woken = 0

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local record = {
    id = "npc_wake",
    x = 5,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "abstract",
    runtime = {},
}

PNC = {
    Const = {
        MATERIALIZE_DISTANCE = 28,
        PRESENCE_INTEREST_REFRESH_MS = 250,
        PRESENCE_ABSTRACT = "abstract",
        SLOT_MS = 50,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        ForEachPlayer = function(callback)
            callback(player)
            callback(player)
        end,
    },
    Registry = {},
    SpatialIndex = {
        QueryNPCs = function() return { record } end,
    },
    SimulationClock = {
        Wake = function(candidate, key, wakeAt)
            T.truthy(candidate == record and key == "presence"
                and wakeAt == now, "incorrect presence wake")
            woken = woken + 1
        end,
    },
    Scheduler = {
        SLOT_MS = 50,
        Schedule = function(candidate, dueAt)
            T.truthy(candidate == record and dueAt == now + 50,
                "incorrect materialization schedule")
            scheduled = scheduled + 1
        end,
    },
}

T.load(FILE)

T.truthy(PNC.Presence.RefreshMaterializationCandidates(now, false) == 1,
    "nearby abstract NPC was not discovered")
T.truthy(woken == 1 and scheduled == 1,
    "multiplayer player queries did not deduplicate the NPC wake")
T.truthy(record.runtime.forcePresenceCheck == true,
    "presence force flag was not set")

now = 1100
T.truthy(PNC.Presence.RefreshMaterializationCandidates(now, false) == 0,
    "interest wake throttle failed")
T.truthy(scheduled == 1, "throttled wake scheduled duplicate work")
T.finish("pnc_presence_interest_wake_smoke")

T.finish("pnc_presence_interest_wake_smoke")
