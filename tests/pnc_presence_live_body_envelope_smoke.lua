local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local safetySource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_LiveBodySafety.lua"
)
T.truthy(safetySource:find("ForEachLive", 1, true),
    "live-body safety no longer uses the bounded live registry")
T.falsy(safetySource:find("getZombieList", 1, true),
    "live-body safety introduced a world-zombie scan")
T.falsy(safetySource:find("Registry.ForEach(", 1, true),
    "live-body safety introduced a full record-registry scan")

local nearest = { distSq = 10 * 10 }
local bodies = {}
local behaviorSawBody = false
local pathPumps = 0
local abstractReasons = {}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MATERIALIZE_DISTANCE = 28,
        ABSTRACT_DISTANCE = 40,
        LIVE_BODY_RETIRE_DISTANCE = 40,
        ORDER_FOLLOW = "follow",
    },
    Core = {
        Now = function() return 1000 end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (x1 or 0) - (x2 or 0)
            local dy = (y1 or 0) - (y2 or 0)
            return dx * dx + dy * dy
        end,
    },
    BehaviorCommon = {},
    BodyLifecycle = {
        IsStartupBodyCleanupComplete = function() return true end,
        IsRecordBodyLost = function() return false end,
    },
    Presence = {
        Internal = {
            FindNearestPlayer = function() return nearest end,
        },
    },
}

T.load(ROOT .. "Presence/PNC_Presence/PNC_Presence_Decisions.lua")

local Presence = PNC.Presence
local function record(state)
    return {
        id = "npc_envelope",
        alive = true,
        presenceState = state,
        x = 0, y = 0, z = 0,
        runtime = {},
    }
end

-- forceLive is an embodiment preference, never permission to create a shell
-- outside player-owned live space.
local forcedAbstract = record("abstract")
forcedAbstract.runtime.forceLive = true
T.truthy(Presence.ShouldMaterialize(
    forcedAbstract, { distSq = 10 * 10 }),
    "near forceLive did not materialize")
T.falsy(Presence.ShouldMaterialize(
    forcedAbstract, { distSq = 29 * 29 }),
    "far forceLive materialized outside the materialization radius")
nearest = nil
T.falsy(Presence.ShouldMaterialize(forcedAbstract, nil),
    "forceLive materialized with no player")
nearest = { distSq = 10 * 10 }

-- The hard retirement envelope outranks forceLive and stale combat state.
local forcedLive = record("live")
forcedLive.runtime.forceLive = true
T.falsy(Presence.ShouldAbstract(forcedLive, { distSq = 39 * 39 }),
    "near forceLive was retired")
T.truthy(Presence.ShouldAbstract(forcedLive, { distSq = 40 * 40 }),
    "forceLive bypassed the hard retirement envelope")
nearest = nil
T.truthy(Presence.ShouldAbstract(forcedLive, nil),
    "forceLive survived with no player")
nearest = { distSq = 10 * 10 }

local combatLive = record("live")
combatLive.runtime.target = { kind = "zombie", zombieId = 7 }
T.falsy(Presence.ShouldAbstract(combatLive, { distSq = 30 * 30 }),
    "near combat target was retired")
T.truthy(Presence.ShouldAbstract(combatLive, { distSq = 45 * 45 }),
    "combat target bypassed the hard retirement envelope")

-- Local SP/splitscreen also respects the actual chunk-map edge. A tiny/debug
-- 5x5-like 40-tile map must retire one chunk before its edge even though the
-- NPC is well inside the generic 40-tile player-distance fence.
local localPlayer = {
    getPlayerNum = function() return 0 end,
}
local localMap = {
    getWorldXMinTiles = function() return 0 end,
    getWorldXMaxTiles = function() return 40 end,
    getWorldYMinTiles = function() return 0 end,
    getWorldYMaxTiles = function() return 40 end,
}
isServer = function() return false end
getCell = function()
    return {
        getChunkMap = function(_, index)
            return index == 0 and localMap or nil
        end,
    }
end
local edgeLive = record("live")
edgeLive.x = 32
edgeLive.y = 20
T.truthy(Presence.IsOutsideLiveBodyEnvelope(edgeLive, {
    player = localPlayer,
    distSq = 12 * 12,
}), "local chunk-map edge did not retire the live shell")
edgeLive.x = 31
T.falsy(Presence.IsOutsideLiveBodyEnvelope(edgeLive, {
    player = localPlayer,
    distSq = 11 * 11,
}), "safe local chunk-map interior retired the live shell")
isServer = function() return true end

-- Server fast-fence: do not wait for the normal 500ms presence cadence while
-- a moving follower is already outside safe live space.
PNC.Registry = {
    Data = {},
    GetLiveZombie = function(id) return bodies[id] end,
    RefreshLivePosition = function() end,
    ForEachLive = function(callback)
        for id, zombie in pairs(bodies) do
            local rec = PNC.Registry.Data[id]
            if rec and zombie then callback(rec, zombie, id) end
        end
    end,
}
PNC.Health = { Update = function() end }
PNC.Stamina = { Update = function() end }
PNC.BehaviorSystem = {
    Tick = function(_, zombie)
        behaviorSawBody = zombie ~= nil
    end,
}
PNC.PathService = {
    Pump = function()
        pathPumps = pathPumps + 1
    end,
}
PNC.Scheduler = {
    SLOT_MS = 50,
    GetCadence = function() return 100 end,
    Schedule = function() end,
}
PNC.SimulationClock = {
    IsDue = function()
        -- Presence/path are deliberately not due. The hard envelope must not
        -- depend on the ordinary simulation-clock lane.
        return false
    end,
}
PNC.SimulationLOD = {
    GetPresenceInterval = function() return 500 end,
    GetVitalsInterval = function() return 1000 end,
    GetDecisionInterval = function() return 100 end,
    GetPathInterval = function() return 100 end,
}
PNC.Network = {
    BroadcastRecord = function() end,
    QueuePeriodicRoster = function() end,
}
PNC.SpatialIndex = { UpdateNPC = function() end }
PNC.Animation = {}
PNC.Server = { Internal = {} }

Presence.Abstract = function(rec, reason)
    abstractReasons[#abstractReasons + 1] = reason
    rec.presenceState = "abstract"
    bodies[rec.id] = nil
    return true
end

-- Global safety sweep must not depend on the NPC's own scheduler cadence.
T.load(ROOT .. "Presence/PNC_Presence/PNC_Presence_Reconcile.lua")
local swept = record("live")
swept.id = "npc_global_sweep"
swept.runtime.forceLive = true
PNC.Registry.Data[swept.id] = swept
bodies[swept.id] = { id = "sweep_body" }
nearest = { distSq = 80 * 80 }
T.equal(Presence.RetireUnsafeLiveBodies(1000, true), 1,
    "global safety sweep did not retire far live body")
T.equal(swept.presenceState, "abstract",
    "global safety sweep left body live")
T.equal(bodies[swept.id], nil,
    "global safety sweep left live registry body")
T.equal(Presence.RetireUnsafeLiveBodies(1050, false), 0,
    "global safety sweep ignored its cadence bound")

-- If the engine temporarily refuses removal, the record/registry body stays
-- live for retry but the current behavior tick must still receive nil so it
-- cannot issue another native path toward the unload boundary.
local retryRecord = record("live")
retryRecord.id = "npc_failed_retire"
local retryBody = { id = "retry_body" }
PNC.Registry.Data[retryRecord.id] = retryRecord
bodies[retryRecord.id] = retryBody
nearest = { distSq = 80 * 80 }
local successfulAbstract = Presence.Abstract
Presence.Abstract = function() return false end
T.equal(Presence.EnforceLiveBodyEnvelope(retryRecord, retryBody), nil,
    "failed retirement exposed unsafe body to behavior/pathing")
T.equal(bodies[retryRecord.id], retryBody,
    "failed retirement discarded the body needed for cleanup retry")
Presence.Abstract = successfulAbstract
bodies[retryRecord.id] = nil

abstractReasons = {}
local live = record("live")
live.id = "npc_server_fence"
live.runtime.forceLive = true
live.runtime.nearestPlayerDistSq = 100
live.nextThinkAt = 0
PNC.Registry.Data[live.id] = live
bodies[live.id] = { id = "body" }
nearest = { distSq = 80 * 80 }

T.load(T.path(
    "ProjectHoomans",
    "server",
    "PNC/Server/Server/PNC_Server_RecordProcessing.lua"
))
PNC.Server.Internal.ProcessRecord(live, 1000)

T.equal(live.presenceState, "abstract",
    "server fast-fence left far live body embodied")
T.equal(abstractReasons[1], "live_body_safety_envelope",
    "server fast-fence used wrong retirement reason")
T.falsy(behaviorSawBody,
    "behavior received the retired IsoZombie after safety abstraction")
T.equal(pathPumps, 0,
    "pathing pumped a body after hard-envelope retirement")

return T.finish("pnc_presence_live_body_envelope_smoke")
