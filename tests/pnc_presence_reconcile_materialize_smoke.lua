--[[
    Nearby abstract NPC materialization through the production decision path.

    This is intentionally different from the position-recovery test: it does
    not call Presence.Materialize directly. It starts with an abstract record,
    lets the real Reconcile -> ShouldMaterialize decision run, and verifies
    that the body is created and registered.
]]

local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local now = 1000
local nearby = { distSq = 4 }
local spawnCount = 0
local registered = {}
local broadcastCount = 0
local behaviorTickCount = 0
local pathPumpCount = 0
local scheduleCount = 0
local deferPresenceForHandoff = false

local body = {
    DoZombieStats = function() end,
    setUseless = function() end,
}

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local square = {
    isFree = function() return true end,
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isVehicleIntersecting = function() return false end,
    hasFloor = function() return true end,
    getObjects = function() return makeList({}) end,
    getChunk = function() return { loaded = true } end,
}

getCell = function()
    return {
        getGridSquare = function() return square end,
    }
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 40,
        ABSTRACT_DISTANCE = 50,
        ABSTRACT_NEAR_DISTANCE = 80,
        MATERIALIZE_CHUNK_SETTLE_MS = 0,
        MATERIALIZE_CHUNK_RETRY_MS = 250,
        MATERIALIZE_NEIGHBOR_RADIUS = 1,
        MATERIALIZE_SAFE_RADIUS = 8,
        MATERIALIZE_MAX_PER_TICK = 10,
        LIVE_BODY_ADMISSION_RETRY_MS = 1000,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
            local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
            return dx * dx + dy * dy
        end,
        GetNearestPlayerPosition = function() return nearby end,
        LogWarn = function() end,
        LogRecordDebug = function() end,
    },
    Registry = {
        GetLiveZombie = function(id) return registered[id] end,
        RegisterLiveZombie = function(record, zombie)
            registered[record.id] = zombie
        end,
        MarkDirty = function() end,
    },
    Health = {
        Update = function() end,
    },
    Animation = {
        ApplyLiveSetup = function() end,
        Apply = function() end,
    },
    Visuals = {
        ApplyHumanVisuals = function() end,
    },
    Equipment = {
        Apply = function() end,
    },
    BehaviorSystem = {
        Tick = function(record)
            behaviorTickCount = behaviorTickCount + 1
            if record.id == "abstract_follow_handoff"
                or record.id == "abstract_follow_vehicle_guard"
            then
                record.runtime = record.runtime or {}
                record.runtime.abstractFollowMaterializeRequested = true
                record.runtime.abstractFollowOwnsForceLive = true
                record.runtime.forceLive = true
                record.runtime.forcePresenceCheck = true
            end
        end,
    },
    PathService = {
        Pump = function() pathPumpCount = pathPumpCount + 1 end,
    },
    Network = {
        BroadcastRecord = function() broadcastCount = broadcastCount + 1 end,
    },
    BodyLifecycle = {
        IsStartupBodyCleanupComplete = function() return true end,
        HasPendingHuskForRecord = function() return false end,
        CleanupRecordShells = function() return 0 end,
        SpawnLiveBody = function()
            spawnCount = spawnCount + 1
            return body
        end,
        ClearEngineInvulnerability = function() return true end,
    },
    SimulationClock = {
        Wake = function() end,
        IsDue = function(_, key)
            if key == "presence" and deferPresenceForHandoff then
                return false
            end
            return true
        end,
    },
    Scheduler = {
        Schedule = function() scheduleCount = scheduleCount + 1 end,
        GetCadence = function() return 100 end,
    },
    Server = { Internal = {} },
}

T.load(ROOT .. "Pathing/PNC_TraversalQuery.lua")
T.load(ROOT .. "Presence/PNC_MaterializationSafety.lua")
T.load(ROOT .. "Presence/PNC_Presence.lua")
T.load(T.path(
    "ProjectHoomans",
    "server",
    "PNC/Server/Server/PNC_Server_RecordProcessing.lua"
))

-- Use the real presence position module, but make the player lookup explicit
-- so this test isolates the decision/materialization path from the spatial
-- index implementation.
PNC.Presence.Internal.FindNearestPlayer = function()
    return nearby
end

local function assertMaterialized(record, message)
    PNC.Presence.Reconcile(record)
    T.equal(record.presenceState, "live", message .. ": presence state")
    T.equal(record.runtime.lifecycle.phase, "live",
        message .. ": lifecycle phase")
    T.equal(registered[record.id], body, message .. ": registry body")
end

local ordinary = {
    id = "nearby_abstract",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = {},
}
assertMaterialized(ordinary, "ordinary nearby abstract NPC")

local legacy = {
    id = "nearby_legacy_force_abstract",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = { forceAbstract = true },
}
assertMaterialized(legacy, "legacy forceAbstract nearby NPC")

T.equal(spawnCount, 2, "nearby reconcile spawned exactly one body per NPC")
T.equal(broadcastCount, 2, "nearby materialization broadcast each transition")

local scheduled = {
    id = "nearby_scheduler_path",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = {},
    nextThinkAt = 0,
}
PNC.Server.Internal.ProcessRecord(scheduled, now)
T.equal(scheduled.presenceState, "live",
    "server ProcessRecord materialized nearby abstract NPC")
T.equal(scheduled.runtime.lifecycle.phase, "live",
    "server ProcessRecord left live lifecycle")
T.equal(registered[scheduled.id], body,
    "server ProcessRecord registered materialized body")
T.equal(behaviorTickCount, 1, "server ProcessRecord ran behavior tick")
T.equal(pathPumpCount, 1, "server ProcessRecord ran live path lane")
T.equal(scheduleCount, 1, "server ProcessRecord rescheduled the record")

-- Regression for the real abstract-follow failure: the follower requests its
-- live body from inside Behavior.Tick, after the normal presence pass has
-- already happened. ProcessRecord must reconcile that same tick rather than
-- leaving the record abstract until a later cold cadence/interest scan.
deferPresenceForHandoff = true
local handoff = {
    id = "abstract_follow_handoff",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = {},
    nextThinkAt = 0,
}
PNC.Server.Internal.ProcessRecord(handoff, now)
T.equal(handoff.presenceState, "live",
    "abstract follow handoff materialized in the same server tick")
T.equal(registered[handoff.id], body,
    "abstract follow handoff registered its live body")
T.equal(scheduleCount, 2,
    "abstract follow handoff used one final scheduler entry")

-- The same post-behavior path must not materialize a reserved vehicle
-- passenger, even if a generic follow wake flag is present.
local passenger = {
    id = "abstract_follow_vehicle_guard",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = {
        vehiclePassenger = { active = true, vehicleId = "vehicle:7", seat = 1 },
    },
    nextThinkAt = 0,
}
local passengerSpawnCount = spawnCount
PNC.Server.Internal.ProcessRecord(passenger, now)
T.equal(passenger.presenceState, "abstract",
    "abstract vehicle passenger remained bodyless during handoff")
T.equal(spawnCount, passengerSpawnCount,
    "abstract vehicle passenger did not spawn a live body")
deferPresenceForHandoff = false

local locked = {
    id = "nearby_hard_abstract",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 10,
    z = 0,
    runtime = { hardAbstract = true },
}
PNC.Presence.Reconcile(locked)
T.equal(locked.presenceState, "abstract",
    "explicit hard abstraction remains bodyless")
T.equal(spawnCount, 4, "hard abstraction did not spawn a body")

return T.finish("pnc_presence_reconcile_materialize_smoke")
