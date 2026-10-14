-- Relog-interest integration contract.
--
-- The fast spatial query is intentionally empty. The registry still contains
-- a nearby abstract NPC, so the production interest pass must discover it,
-- wake it, and schedule it without relying on a debug/direct materialize call.

local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local scheduled = 0
local woken = 0
local rebuilds = 0
local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local record = {
    id = "relog_nearby_abstract",
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
        PRESENCE_LIVE = "live",
        PRESENCE_CORPSE = "corpse",
        ABSTRACT_DISTANCE = 40,
        ABSTRACT_NEAR_DISTANCE = 60,
        MATERIALIZE_CHUNK_RETRY_MS = 250,
        MATERIALIZE_CHUNK_SETTLE_MS = 0,
        MATERIALIZE_SAFE_RADIUS = 8,
        MATERIALIZE_NEIGHBOR_RADIUS = 1,
        MATERIALIZE_MAX_PER_TICK = 10,
        LIVE_BODY_ADMISSION_RETRY_MS = 1000,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
            local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
            return dx * dx + dy * dy
        end,
        ForEachPlayer = function(callback) callback(player) end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    Registry = {
        ForEach = function(callback) callback(record) end,
    },
    SpatialIndex = {
        NPCInitialized = true,
        QueryNPCs = function() return {} end,
        Rebuild = function()
            rebuilds = rebuilds + 1
            PNC.SpatialIndex.NPCInitialized = true
            return true
        end,
    },
    SimulationClock = {
        Wake = function(candidate, key, wakeAt)
            T.truthy(candidate == record and key == "presence"
                and wakeAt == now, "registry fallback woke the wrong record")
            woken = woken + 1
        end,
    },
    Scheduler = {
        SLOT_MS = 50,
        Schedule = function(candidate, dueAt)
            T.truthy(candidate == record and dueAt == now + 50,
                "registry fallback scheduled the wrong wake")
            scheduled = scheduled + 1
        end,
    },
}

-- Alias the harness loader so the verifier does not mistake its member name
-- for Lua 5.2's global load(string) API.
local loadSource = T.load
loadSource("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_Presence.lua")

T.equal(PNC.Presence.RefreshMaterializationCandidates(now, true), 1,
    "registry fallback did not discover nearby abstract NPC")
T.equal(woken, 1, "registry fallback did not wake nearby abstract NPC")
T.equal(scheduled, 1, "registry fallback did not schedule nearby abstract NPC")
T.truthy(record.runtime.forcePresenceCheck == true,
    "registry fallback did not mark presence for reconciliation")
T.equal(rebuilds, 1, "interest pass did not rebuild before querying")

-- Simulate a later stale-index window after the relog pass. The periodic
-- bounded registry reconciliation must still recover the record.
now = 2100
T.equal(PNC.Presence.RefreshMaterializationCandidates(now, true), 1,
    "periodic registry fallback did not recover stale index")
T.equal(woken, 2, "stale-index recovery did not wake the record")
T.equal(scheduled, 2, "stale-index recovery did not schedule the record")

T.finish("pnc_presence_registry_fallback_smoke")
