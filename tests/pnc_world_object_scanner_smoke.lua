local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 5000
local gridCalls = 0
local reservations = {}

local bedObj = { kind = "bed", id = "bed-1" }
local sofaObj = { kind = "sofa", id = "sofa-1" }
local chairObj = { kind = "chair", id = "chair-1" }
local heaterObj = { kind = "heater", id = "heater-1" }

local squares = {}
for x = 40, 60 do
    for y = 40, 60 do
        local objs = {}
        if x == 51 and y == 50 then objs = { bedObj }
        elseif x == 49 and y == 50 then objs = { sofaObj }
        elseif x == 50 and y == 52 then objs = { chairObj }
        elseif x == 52 and y == 51 then objs = { heaterObj }
        end
        squares[tostring(x) .. ":" .. tostring(y)] = {
            getX = function() return x end,
            getY = function() return y end,
            getZ = function() return 0 end,
            isSolid = function() return false end,
            isSolidTrans = function() return false end,
            isFree = function() return #objs == 0 end,
            getObjects = function() return objs end,
        }
    end
end

local cell = {
    getGridSquare = function(_, x, y)
        gridCalls = gridCalls + 1
        return squares[tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))]
    end,
}
getCell = function() return cell end

PNC = {
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
            local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            return { {
                x = resource.x,
                y = resource.y,
                z = resource.z or 0,
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                validSpot = true,
            } }
        end,
    },
    FacilityReservations = {
        IsReserved = function(_, key) return reservations[key] == true end,
        IsResourceAvailable = function(resource)
            return reservations[tostring(resource.resourceKey or "")] ~= true
        end,
        ByResource = reservations,
    },
}

local WorldObjects = T.load("ProjectHoomans", "server",
    "PNC/World/WorldObjects/PNC_WorldObjects.lua")

-- Replace bed/sofa/seat detectors with lightweight test matchers on the
-- canonical unified registry.
WorldObjects.Register("bed", {
    resourceKind = "sleep_surface",
    capability = "sleep",
    sleepSurface = "bed",
    sleepPriority = 100,
    matches = function(_, o) return o and o.kind == "bed" end,
    describe = function(sq, o)
        return {
            resourceKey = "bed:" .. tostring(o.id),
            x = sq:getX() + 0.5,
            y = sq:getY() + 0.5,
            z = sq:getZ(),
            object = o,
        }
    end,
})
WorldObjects.Register("sofa", {
    resourceKind = "sleep_surface",
    capability = "sleep",
    sleepSurface = "sofa",
    sleepPriority = 50,
    matches = function(_, o) return o and o.kind == "sofa" end,
    describe = function(sq, o)
        return {
            resourceKey = "sofa:" .. tostring(o.id),
            x = sq:getX() + 0.5,
            y = sq:getY() + 0.5,
            z = sq:getZ(),
            object = o,
        }
    end,
})
WorldObjects.Register("seat", {
    resourceKind = "seating_surface",
    capability = "living",
    matches = function(_, o) return o and o.kind == "chair" end,
    describe = function(sq, o)
        return {
            resourceKey = "seat:" .. tostring(o.id),
            x = sq:getX() + 0.5,
            y = sq:getY() + 0.5,
            z = sq:getZ(),
            object = o,
        }
    end,
})

local RoamAmbient = T.load("ProjectHoomans", "server",
    "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Discovery.lua")

PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamingSeat = {
    SEARCH_RADIUS = 6,
    MAX_OBJECTS = 96,
    Internal = {
        facilityResources = function() return PNC.FacilityResources end,
        interactionTargets = function() return PNC.FacilityInteractionTargets end,
        eachObject = function() end,
        isReserved = function(res) return reservations[res.resourceKey] == true end,
        idHash = function() return 0 end,
        distanceTo = function(z, x, y)
            return PNC.Core.Distance(z:getX(), z:getY(), x, y)
        end,
        AMBIENT_FACILITY_ID = "ambient",
        FLOOR_SCENE_ID = "facility.living.sit",
    },
}
T.load("ProjectHoomans", "server",
    "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Discovery.lua")
local RoamingSeat = PNC.AutonomyExecutors.RoamingSeat

local npc1 = {
    getX = function() return 50.5 end,
    getY = function() return 50.5 end,
    getZ = function() return 0 end,
}
local npc2 = {
    getX = function() return 51.0 end,
    getY = function() return 50.5 end,
    getZ = function() return 0 end,
}
local rec1 = { id = "npc-1" }

-- 1. RoamAmbient scans once and prefers bed (priority 100) over sofa (50).
gridCalls = 0
local sleepPick = RoamAmbient.FindSleepSurface(npc1)
T.truthy(sleepPick, "RoamAmbient finds sleep surface via unified scanner")
T.equal(sleepPick.resource.resourceKey, "bed:bed-1",
    "bed outranks sofa by priority")
T.equal(sleepPick.object, bedObj, "live object reference is preserved")
local callsAfterFirst = gridCalls
T.truthy(callsAfterFirst > 0, "initial radius scan inspected grid squares")

-- 2. RoamingSeat in the same spatial bucket reuses the EXACT same scan cache!
local seatPick = RoamingSeat.FindCandidate(rec1, npc1)
T.truthy(seatPick, "RoamingSeat finds chair via unified scanner")
T.equal(seatPick.resource.resourceKey, "seat:chair-1",
    "chair discovered from the same shared spatial-bucket scan")
T.equal(seatPick.object, chairObj, "chair live object reference preserved")
T.equal(gridCalls, callsAfterFirst,
    "RoamingSeat performs zero additional grid lookups on shared bucket cache")

-- 3. Another nearby NPC respects reservations and falls back to sofa without
--    re-scanning the world!
reservations["bed:bed-1"] = true
local sleepPick2 = RoamAmbient.FindSleepSurface(npc2)
T.truthy(sleepPick2, "second NPC finds unreserved sofa")
T.equal(sleepPick2.resource.resourceKey, "sofa:sofa-1",
    "reserved bed is skipped in favor of unreserved sofa")
T.equal(gridCalls, callsAfterFirst,
    "second nearby NPC also reuses the shared spatial-bucket cache")

-- 4. Adding and removing a custom plug-in object type works cleanly.
WorldObjects.Register("heater", {
    resourceKind = "heat_source",
    capability = "heat",
    matches = function(_, o) return o and o.kind == "heater" end,
    describe = function(sq, o)
        return {
            resourceKey = "heater:" .. tostring(o.id),
            x = sq:getX() + 0.5,
            y = sq:getY() + 0.5,
            z = sq:getZ(),
            object = o,
        }
    end,
})
WorldObjects.ClearCache()
local heatPick = WorldObjects.FindBestInRadius(rec1, npc1, "heat", { radius = 6 })
T.truthy(heatPick, "new plug-in heater discovered via unified FindBestInRadius")
T.equal(heatPick.resource.resourceKey, "heater:heater-1",
    "heater resourceKey returned")

T.equal(WorldObjects.Unregister("heater"), true, "heater unregisters cleanly")
local missingHeat = WorldObjects.FindBestInRadius(rec1, npc1, "heat", { radius = 6 })
T.equal(missingHeat, nil, "unregistered heater is no longer returned")
