local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function square(corpses)
    local value = corpses or {}
    return {
        getDeadBodys = function() return list(value) end,
        getStaticMovingObjects = function() return list(value) end,
        transmitRemoveItemFromSquare = function() end,
    }
end

local squares = {}
local function squareKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function corpse(modData, hostSquare)
    local removed = false
    local current = hostSquare
    local value = {
        getModData = function() return modData end,
        getSquare = function() return hostSquare end,
        getCurrentSquare = function() return current end,
        setSquare = function(_, nextSquare) hostSquare = nextSquare end,
        setCurrent = function(_, nextSquare) current = nextSquare end,
        removeFromWorld = function() removed = true end,
        removeFromSquare = function() removed = true end,
    }
    value.wasRemoved = function() return removed end
    return value
end

local now = 1000
local records = {}
local bodies = {}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        BODY_TAG_VERSION = 1,
        BODY_SHELL_RESPAWN_DELAY_MS = 350,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        LogWarn = function() end,
    },
    Registry = {
        LiveByID = {},
        Get = function(id) return records[tostring(id)] end,
        EnsureLoaded = function() end,
        ForEach = function(callback)
            for _, record in pairs(records) do callback(record) end
        end,
    },
}

getCell = function()
    return {
        getZombieList = function() return list(bodies) end,
        getGridSquare = function(_, x, y, z)
            return squares[squareKey(math.floor(x), math.floor(y), math.floor(z))]
        end,
    }
end

T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Identity.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Removal.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_RecordCleanup.lua")

local liveRecord = {
    id = "npc-live",
    alive = true,
    presenceState = "abstract",
    x = 100,
    y = 100,
    z = 0,
    runtime = {},
}
records[liveRecord.id] = liveRecord

local liveSquare = square()
squares[squareKey(100, 100, 0)] = liveSquare
local staleShellCorpse = corpse({
    PNC_Owner = "ProjectHoomans",
    PNC_NPC = true,
    PNC_UUID = liveRecord.id,
    PNC_BodyKind = "live",
}, liveSquare)
local ordinaryCorpse = corpse({}, liveSquare)
liveSquare.getDeadBodys = function()
    return list({ staleShellCorpse, ordinaryCorpse })
end
liveSquare.getStaticMovingObjects = liveSquare.getDeadBodys

T.equal(
    PNC.BodyLifecycle.CleanupRecordShells(liveRecord, now),
    1,
    "stale managed shell corpse was cleaned before materialization"
)
T.equal(staleShellCorpse.wasRemoved(), true,
    "stale managed shell corpse remained in the loaded square")
T.equal(ordinaryCorpse.wasRemoved(), false,
    "ordinary corpse was removed by live-shell cleanup")

local corpseRecord = {
    id = "npc-dead",
    alive = false,
    presenceState = "corpse",
    x = 110,
    y = 110,
    z = 0,
    runtime = {},
}
records[corpseRecord.id] = corpseRecord
local corpseSquare = square()
squares[squareKey(110, 110, 0)] = corpseSquare
local authoritativeCorpse = corpse({
    PNC_UUID = corpseRecord.id,
    PNC_DeathMarkerID = corpseRecord.id,
    PNC_BodyKind = "corpse",
}, corpseSquare)
corpseSquare.getDeadBodys = function() return list({ authoritativeCorpse }) end
corpseSquare.getStaticMovingObjects = corpseSquare.getDeadBodys
T.equal(PNC.BodyLifecycle.CleanupRecordShells(corpseRecord, now), 0,
    "dead NPC corpse entered the live-shell cleanup lane")
T.equal(authoritativeCorpse.wasRemoved(), false,
    "authoritative NPC corpse was removed")

local passengerRecord = {
    id = "npc-passenger",
    alive = true,
    presenceState = "abstract",
    x = 120,
    y = 120,
    z = 0,
    runtime = { vehiclePassenger = { active = true } },
}
records[passengerRecord.id] = passengerRecord
local passengerSquare = square()
squares[squareKey(120, 120, 0)] = passengerSquare
local passengerCorpse = corpse({
    PNC_UUID = passengerRecord.id,
    PNC_NPC = true,
    PNC_BodyKind = "live",
}, passengerSquare)
passengerSquare.getDeadBodys = function() return list({ passengerCorpse }) end
passengerSquare.getStaticMovingObjects = passengerSquare.getDeadBodys
T.equal(PNC.BodyLifecycle.CleanupRecordShells(passengerRecord, now), 0,
    "vehicle passenger entered stale corpse cleanup")
T.equal(passengerCorpse.wasRemoved(), false,
    "vehicle passenger-associated body was removed")

T.finish("pnc_stale_shell_corpse_cleanup_smoke")
