local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local loaded = false
local candidates = {}
local quarantineCount = 0
local reboundCount = 0

local record = {
    id = "npc_late_stream",
    alive = true,
    presenceState = "abstract",
    isFemale = false,
    x = 100,
    y = 200,
    z = 0,
    runtime = {
        startupRehydrateExpected = true,
        startupBodyHint = {
            wasLive = true,
            lease = "saved_lease",
            instanceID = "12345",
            x = 100,
            y = 200,
            z = 0,
        },
    },
}

local reg = {
    ForEach = function(callback)
        callback(record)
    end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        BODY_SHELL_STARTUP_PASSES = 1,
        BODY_SHELL_STARTUP_SETTLE_MS = 1500,
        BODY_SHELL_LATE_STREAM_SETTLE_MS = 1500,
        BODY_SHELL_REHYDRATE_ANON_SETTLE_MS = 750,
        BODY_SHELL_REHYDRATE_ANON_RADIUS = 1.0,
        BODY_SHELL_MAINTENANCE_MS = 1000,
    },
    Core = {
        Now = function() return now end,
        LogInfo = function() end,
        LogWarn = function() end,
        IsAuthority = function() return true end,
    },
    BodyLifecycle = {
        Internal = {},
        StartupCleanup = {
            begun = false,
            active = false,
            complete = false,
            startedAt = 0,
        },
    },
    SpatialIndex = {
        QueryZombies = function()
            return candidates
        end,
        QueryNPCs = function()
            return { record }
        end,
    },
    LiveBodyControl = {
        ApplyHumanizedBodyFlags = function()
            quarantineCount = quarantineCount + 1
        end,
        SuppressZombieSounds = function() end,
    },
    Presence = {},
}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
Internal.registry = function() return reg end
Internal.GetStartupBodyInstanceID = function() return nil end
Internal.GetStartupBodyPopulationID = function() return nil end
Internal.IsProtectedBody = function() return false end
Internal.IsCanonicalStartupBody = function() return false end
Internal.GetLiveShellIdentity = function() return nil, false, false end
Internal.StartupDistanceSqToRecord = function(body, target)
    local dx = body:getX() - target.x
    local dy = body:getY() - target.y
    return dx * dx + dy * dy
end

local list = {
    size = function() return #candidates end,
    get = function(_, index) return candidates[index + 1] end,
}
local square = {
    getMovingObjects = function() return list end,
}
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if loaded and x == 100 and y == 200 and z == 0 then
                return square
            end
            return nil
        end,
    }
end
isServer = function() return true end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_AnonymousRehydrate.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_LateStream.lua"
)

Lifecycle.SweepPersistedLiveShells = function()
    return {
        available = true,
        removed = 0,
        pendingRehydrate = 0,
        unresolvedRehydrate = 0,
        ambiguous = 0,
        ordinaryUnknown = 0,
        blockedRecords = 0,
    }
end
Lifecycle.SeedHuskLedgerFromRecords = function() end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_Coordinator.lua"
)

Lifecycle.BeginStartupBodyCleanup(now, true)
Lifecycle.PumpStartupBodyCleanup(now, true)
Lifecycle.PumpStartupBodyCleanup(now, true)

T.truthy(Lifecycle.StartupCleanup.complete,
    "dedicated startup did not complete without loaded chunks")
T.equal(record.runtime.startupRehydrateExpected, nil,
    "startup claim was not transferred")
T.truthy(record.runtime.lateStreamRehydrateExpected,
    "dedicated startup discarded the saved-live restart claim")
T.equal(record.runtime.startupRehydrateMissed, nil,
    "late-stream claim was incorrectly marked missed")

-- No loaded saved square: claim blocks only this record, not global startup.
local status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "pending",
    "unloaded saved square released the late-stream claim")
T.equal(record.runtime.lateStreamRehydrateLoadedAt, nil,
    "unloaded square started the settle clock")

-- First loaded frame starts the bounded settle window.
loaded = true
now = 2000
status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "pending", "first loaded frame did not settle")
T.equal(record.runtime.lateStreamRehydrateLoadedAt, now,
    "loaded-square settle clock not recorded")

-- No old shell after the complete loaded settle releases normal spawn.
now = 3400
status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "pending",
    "late-stream claim released before full settle")
now = 3600
status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "released",
    "empty loaded square did not release after settle")
T.equal(record.runtime.lateStreamRehydrateExpected, nil,
    "released claim remained armed")

-- Fresh claim with one anonymous old shell: quarantine, settle, then rebind.
record.presenceState = "abstract"
record.runtime.startupRehydrateExpected = true
T.truthy(Lifecycle.ArmLateStreamRehydrate(record, 4000),
    "could not arm second late-stream claim")
local oldBody = {
    getOnlineID = function() return -1 end,
    getX = function() return 100.2 end,
    getY = function() return 200.2 end,
    getZ = function() return 0 end,
    isFemale = function() return false end,
}
candidates = { oldBody }
now = 4000
PNC.Presence.RebindRestoredBody = function(receivedRecord, body)
    T.equal(receivedRecord, record, "rebound wrong record")
    T.equal(body, oldBody, "rebound wrong shell")
    reboundCount = reboundCount + 1
    receivedRecord.presenceState = "live"
    return true
end

status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "pending",
    "anonymous shell bypassed late-stream settle")
T.truthy(quarantineCount > 0,
    "anonymous streamed shell was not quarantined")

now = 5600
status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "rebound",
    "unique anonymous streamed shell was not rebound")
T.equal(reboundCount, 1, "rebound ran wrong number of times")
T.equal(record.runtime.lateStreamRehydrateExpected, nil,
    "successful late-stream rebind left claim armed")
T.equal(record.presenceState, "live",
    "successful late-stream rebind did not restore live state")

-- Ambiguity stays fail-closed and never calls rebind.
record.presenceState = "abstract"
record.runtime.startupRehydrateExpected = true
T.truthy(Lifecycle.ArmLateStreamRehydrate(record, 6000),
    "could not arm ambiguous claim")
local bodyB = {
    getOnlineID = function() return -1 end,
    getX = function() return 99.8 end,
    getY = function() return 199.8 end,
    getZ = function() return 0 end,
    isFemale = function() return false end,
}
candidates = { oldBody, bodyB }
now = 6000
status = Lifecycle.ReconcileLateStreamRehydrate(record, now)
T.equal(status, "ambiguous",
    "two anonymous restart shells produced a winner")
T.equal(reboundCount, 1,
    "ambiguous restart shells triggered rebind")
T.truthy(record.runtime.lateStreamRehydrateExpected,
    "ambiguous late-stream claim was cleared")

local materializeSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_Materialize.lua"
)
local reconcileAt = materializeSource:find(
    "ReconcileLateStreamRehydrate", 1, true
)
local spawnAt = materializeSource:find(
    "pcall(spawnBody", 1, true
)
T.truthy(reconcileAt and spawnAt and reconcileAt < spawnAt,
    "replacement body can spawn before late-stream reconciliation")

return T.finish("pnc_mp_late_stream_rehydrate_smoke")
