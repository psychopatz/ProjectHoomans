local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local warnings = {}
local registeredBody
local dirtyDomain
local spawn
local spawnCount = 0
local now = 1000
local presenceWakeAt
local scheduledAt
local body = {
    DoZombieStats = function() end,
    setUseless = function() end,
}
local zombieList = {
    size = function() return 1 end,
    get = function() return body end,
}
local chunk = { loaded = true }
local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end
local function makeSquare(vehicleIntersecting, objects, hasFloor)
    return {
        isFree = function() return true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        isVehicleIntersecting = function() return vehicleIntersecting == true end,
        hasFloor = function() return hasFloor ~= false end,
        getObjects = function() return makeList(objects or {}) end,
        -- Return a fresh wrapper-shaped value on every call. The runtime can
        -- do the same for Java userdata, so settle identity must be coordinate
        -- based rather than Lua object based.
        getChunk = function() return { loaded = chunk.loaded } end,
    }
end
local clearSquare = makeSquare(false)
local vehicleSquare = makeSquare(true)
local barnSquare = makeSquare(false, {
    {
        isFloor = function() return false end,
        isTableSurface = function() return false end,
        getContainer = function() return {} end,
    },
})
local cell = {
    getGridSquare = function(_, x)
        if x == 1 then return vehicleSquare end
        if x == 2 then return barnSquare end
        return clearSquare
    end,
}

getCell = function() return cell end
addZombiesInOutfit = function(x, y, z, _, outfit)
    spawnCount = spawnCount + 1
    spawn = { x = x, y = y, z = z, outfit = outfit }
    return zombieList
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 40,
        ABSTRACT_DISTANCE = 50,
        MATERIALIZE_CHUNK_SETTLE_MS = 0,
        MATERIALIZE_CHUNK_RETRY_MS = 250,
        MATERIALIZE_NEIGHBOR_RADIUS = 1,
        MATERIALIZE_SAFE_RADIUS = 8,
        MATERIALIZE_MAX_PER_TICK = 10,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        GetNearestPlayerPosition = function() return { distSq = 0 } end,
        LogWarn = function(message) warnings[#warnings + 1] = message end,
        LogRecordDebug = function() end,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
        RegisterLiveZombie = function(_, value) registeredBody = value end,
        MarkDirty = function(_, domain) dirtyDomain = domain end,
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
    PathService = {},
    ZombieAggro = {},
    Network = {
        BroadcastRecord = function() end,
    },
    Inventory = {
        EnsureRecordInventory = function() end,
    },
    VisualProfiles = {
        ResolveSpawnOutfit = function() return "PNCCompanionMale" end,
    },
    SimulationClock = {
        Wake = function(_, key, dueAt)
            if key == "presence" then
                presenceWakeAt = dueAt
            end
        end,
    },
    Scheduler = {
        Schedule = function(_, dueAt)
            scheduledAt = dueAt
        end,
    },
}

T.load(ROOT .. "Pathing/PNC_TraversalQuery.lua")
T.load(ROOT .. "Presence/PNC_MaterializationSafety.lua")
T.load(ROOT .. "Presence/PNC_Presence.lua")

local passengerRecord = {
    alive = true,
    presenceState = "abstract",
    x = 0,
    y = 0,
    z = 0,
    runtime = {
        vehiclePassenger = { active = true, vehicleId = "vehicle:7", seat = 1 },
    },
}
T.equal(
    PNC.Presence.ShouldMaterialize(passengerRecord),
    false,
    "abstract vehicle passenger stays bodyless"
)

local record = {
    id = "saved_vehicle_stuck",
    name = "Saved Vehicle Stuck",
    alive = true,
    presenceState = "abstract",
    x = 1.5,
    y = 0.5,
    z = 0,
    runtime = {},
}

local materialized = PNC.Presence.Materialize(record, "range_enter")
T.equal(materialized, body, "saved NPC materialized")
T.equal(registeredBody, body, "repaired body registered")
T.equal(spawn.x, 0.5, "vehicle-stuck spawn repaired x")
T.equal(spawn.y, 0.5, "vehicle-stuck spawn repaired y")
T.equal(spawn.outfit, "Naked", "PNC engine shell uses naked base outfit")
T.equal(record.x, spawn.x, "repaired record x")
T.equal(record.presenceState, "live", "repaired record live")
T.equal(record.runtime.positionRecovery.lastEvent, "materialize_relocate",
    "materialize recovery metadata")
T.equal(record.runtime.positionRecovery.lastReason, "vehicle",
    "materialize recovery reason")
T.equal(dirtyDomain, "position_recovery", "materialize recovery persisted")
T.equal(#warnings, 1, "materialize recovery log count")
T.truthy(
    string.find(warnings[1], "event=materialize_relocate", 1, true),
    "materialize recovery warning missing event"
)

local clearRecord = {
    id = "saved_clear",
    name = "Saved Clear",
    alive = true,
    presenceState = "abstract",
    x = 0.75,
    y = 0.75,
    z = 0,
    runtime = {},
}
materialized = PNC.Presence.Materialize(clearRecord, "range_enter")
T.equal(materialized, body, "clear saved NPC materialized")
T.equal(spawn.x, 0.75, "clear saved x preserved")
T.equal(spawn.y, 0.75, "clear saved y preserved")
T.equal(clearRecord.runtime.positionRecovery, nil, "clear saved NPC not repaired")
T.equal(#warnings, 1, "clear materialization emitted no recovery log")

local barnRecord = {
    id = "saved_barn_fixture",
    name = "Saved Barn Fixture",
    alive = true,
    presenceState = "abstract",
    x = 2.5,
    y = 0.5,
    z = 0,
    runtime = {},
}
materialized = PNC.Presence.Materialize(barnRecord, "range_enter")
T.equal(materialized, body, "barn-fixture NPC materialized")
T.equal(spawn.x, 3.5, "barn-fixture spawn relocated x")
T.equal(spawn.y, 0.5, "barn-fixture spawn relocated y")
T.equal(
    barnRecord.runtime.positionRecovery.lastReason,
    "container_object",
    "barn-fixture recovery reason"
)
T.equal(#warnings, 2, "barn-fixture recovery logged once")

PNC.Const.MATERIALIZE_CHUNK_SETTLE_MS = 1000
now = 2000
chunk.loaded = false
local streamingRecord = {
    id = "streaming_chunk",
    name = "Streaming Chunk",
    alive = true,
    presenceState = "abstract",
    x = 0.5,
    y = 0.5,
    z = 0,
    runtime = {},
}
local previousSpawnCount = spawnCount
materialized = PNC.Presence.Materialize(streamingRecord, "range_enter")
T.equal(materialized, nil, "first streaming attempt deferred")
T.equal(spawnCount, previousSpawnCount, "deferred attempt created no body")
T.equal(
    streamingRecord.runtime.materializationDeferredReason,
    "target_chunk_loading",
    "streaming defer reason"
)
T.equal(streamingRecord.runtime.materializeRetryAt, 2250, "streaming retry scheduled")
T.equal(presenceWakeAt, 2250, "streaming presence lane wake scheduled")
T.equal(scheduledAt, 2250, "streaming record retry scheduled")

chunk.loaded = true
now = 2250
materialized = PNC.Presence.Materialize(streamingRecord, "range_enter")
T.equal(materialized, nil, "newly loaded chunk begins settling")
T.equal(
    streamingRecord.runtime.materializationDeferredReason,
    "target_chunk_settling",
    "newly loaded chunk settle reason"
)

now = 2750
materialized = PNC.Presence.Materialize(streamingRecord, "range_enter")
T.equal(materialized, nil, "partially settled chunk remains abstract")
T.equal(spawnCount, previousSpawnCount, "settling attempts created no body")

now = 3251
materialized = PNC.Presence.Materialize(streamingRecord, "range_enter")
T.equal(materialized, body, "settled chunk materialized")
T.equal(spawnCount, previousSpawnCount + 1, "settled chunk created one body")
T.equal(
    streamingRecord.runtime.materializationSafety,
    nil,
    "settled materialization state cleared"
)
T.equal(
    streamingRecord.runtime.materializationDeferredReason,
    nil,
    "settled defer reason cleared"
)

now = 4000
local explicitRecord = {
    id = "explicit_live_spawn",
    name = "Explicit Live Spawn",
    alive = true,
    presenceState = "abstract",
    x = 0.5,
    y = 0.5,
    z = 0,
    runtime = {},
}
previousSpawnCount = spawnCount
materialized = PNC.Presence.Materialize(explicitRecord, "force_live_spawn")
T.equal(materialized, body, "explicit live spawn bypasses range settle delay")
T.equal(spawnCount, previousSpawnCount + 1, "explicit live spawn created one body")

now = 5000
local movingRecord = {
    id = "moving_in_settling_chunk",
    name = "Moving In Settling Chunk",
    alive = true,
    presenceState = "abstract",
    x = 0.5,
    y = 0.5,
    z = 0,
    runtime = {},
}
previousSpawnCount = spawnCount
materialized = PNC.Presence.Materialize(movingRecord, "range_enter")
T.equal(materialized, nil, "moving NPC begins chunk settle")
T.equal(
    movingRecord.runtime.materializationSafety.readySince,
    5000,
    "moving NPC settle start recorded"
)

now = 5500
movingRecord.x = 3.5
materialized = PNC.Presence.Materialize(movingRecord, "range_enter")
T.equal(materialized, nil, "same-chunk movement remains settling")
T.equal(
    movingRecord.runtime.materializationSafety.readySince,
    5000,
    "same-chunk movement preserves settle start"
)

now = 6001
movingRecord.x = 8.5
materialized = PNC.Presence.Materialize(movingRecord, "range_enter")
T.equal(materialized, body, "moving abstract NPC materialized after settle")
T.equal(spawnCount, previousSpawnCount + 1, "moving NPC created one body")
T.equal(spawn.x, 8.5, "moving NPC uses latest abstract position")
T.finish("pnc_presence_position_recovery_smoke")

T.finish("pnc_presence_position_recovery_smoke")
