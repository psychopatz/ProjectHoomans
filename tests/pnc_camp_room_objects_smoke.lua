local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local gridSquareCalls = 0
local chairA = { kind = "chair", id = "chair-a" }
local chairB = { kind = "chair", id = "chair-b" }
local bedA = { kind = "bed", id = "bed-a" }

local room = {}
local roomDef = {
    getIDString = function() return "lounge-1" end,
    getName = function() return "livingroom" end,
    getX = function() return 20 end,
    getY = function() return 10 end,
    getX2 = function() return 28 end,
    getY2 = function() return 18 end,
    getZ = function() return 0 end,
}
local building = {
    getID = function() return "bldg-1" end,
    getDef = function()
        return { getIDString = function() return "bldg-1" end }
    end,
}

local roomSquares = {}
local grid = {}
for x = 20, 27 do
    for y = 10, 17 do
        local objects = {}
        if x == 21 and y == 11 then objects = { chairA }
        elseif x == 26 and y == 16 then objects = { chairB }
        elseif x == 24 and y == 11 then objects = { bedA }
        end
        local sq = {
            getX = function() return x end,
            getY = function() return y end,
            getZ = function() return 0 end,
            getRoom = function() return room end,
            isInARoom = function() return true end,
            isFree = function() return #objects == 0 end,
            getObjects = function() return objects end,
        }
        roomSquares[#roomSquares + 1] = sq
        grid[tostring(x) .. ":" .. tostring(y)] = sq
    end
end
room.getRoomDef = function() return roomDef end
room.getBuilding = function() return building end
room.getSquares = function() return roomSquares end
room.getFreeTile = function() return roomSquares[1] end

local cell = {
    getGridSquare = function(_, x, y, z)
        gridSquareCalls = gridSquareCalls + 1
        return grid[tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))]
    end,
}
getCell = function() return cell end

local reservations = {}
local emittedEvents = {}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ORDER_CAMP = "camp",
        CAMP_RADIUS = 3,
        CAMP_RESOURCE_RADIUS = 12,
        CAMP_RESOURCE_MAX = 32,
        CAMP_RESOURCE_SCAN_SQUARES_PER_TICK = 32,
    },
    Core = {
        Now = function() return now end,
    },
    Registry = {
        MarkDirty = function() end,
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
    FacilityResources = {
        GetDetector = function(id)
            if id == "bed" then
                return {
                    collect = function(sq, emit)
                        for _, obj in ipairs(sq:getObjects()) do
                            if obj.kind == "bed" then emit(obj) end
                        end
                    end,
                    matches = function(_, obj)
                        return obj and obj.kind == "bed"
                    end,
                    describe = function(sq, obj)
                        return {
                            id = obj.id,
                            x = sq:getX(),
                            y = sq:getY(),
                            z = sq:getZ(),
                            sleepSurface = "bed",
                            sleepPriority = 100,
                        }
                    end,
                    key = function(info)
                        return "bed:" .. tostring(info.id)
                    end,
                }
            end
            if id == "seat" then
                return {
                    matches = function(_, obj)
                        return obj and obj.kind == "chair"
                    end,
                    describe = function(sq, obj)
                        return {
                            resourceKey = "seat:" .. tostring(obj.id),
                            x = sq:getX(),
                            y = sq:getY(),
                            z = sq:getZ(),
                        }
                    end,
                }
            end
            return nil
        end,
        InspectSleepObject = function(sq, obj, detectorId)
            if detectorId == "bed" and obj.kind == "bed" then
                return {
                    resourceKey = "bed:" .. tostring(obj.id),
                    resourceKind = "sleep_surface",
                    detectorId = "bed",
                    sleepSurface = "bed",
                    sleepPriority = 100,
                    x = sq:getX(),
                    y = sq:getY(),
                    z = sq:getZ(),
                }
            end
            return nil
        end,
        InspectSeatingObject = function(sq, obj)
            if obj.kind == "chair" then
                return {
                    resourceKey = "seat:" .. tostring(obj.id),
                    resourceKind = "seating_surface",
                    x = sq:getX(),
                    y = sq:getY(),
                    z = sq:getZ(),
                }
            end
            return nil
        end,
    },
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            return { {
                x = resource.x + 0.5,
                y = resource.y + 0.5,
                z = resource.z,
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                sleepSurface = resource.sleepSurface,
                seating = resource.resourceKind == "seating_surface",
            } }
        end,
    },
    FacilityReservations = {
        IsReserved = function(_, key) return reservations[key] == true end,
        ReserveResource = function(_, resource)
            reservations[resource.resourceKey] = true
            return true, { id = "res:" .. tostring(resource.resourceKey) }
        end,
    },
    Tasking = {
        Events = {
            Emit = function(eventType, payload)
                emittedEvents[#emittedEvents + 1] = {
                    type = eventType,
                    payload = payload,
                }
            end,
        },
    },
}

local Geometry = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")
PNC.Semantics.CampSiteGeometry = Geometry

local CampResources = T.load("ProjectHoomans", "server",
    "PNC/World/CampResourceService/PNC_CampResourceService.lua")

local bounds = { minX = 20, minY = 10, maxX = 27, maxY = 17, z = 0 }
local npc1 = {
    id = "npc-1",
    alive = true,
    x = 21.5,
    y = 12.5,
    z = 0,
    runtime = {},
    orderSpec = {
        kind = "camp",
        campId = "camp:group:1",
        scope = "room",
        siteScope = "room",
        siteID = "room:bldg-1:lounge-1",
        roomID = "lounge-1",
        buildingID = "bldg-1",
        roomBounds = bounds,
        x = 22.5,
        y = 12.5,
        z = 0,
        radius = 3,
        resourceRadius = 12,
        placementState = "arrived",
    },
}
local npc2 = {
    id = "npc-2",
    alive = true,
    x = 26.5,
    y = 15.5,
    z = 0,
    runtime = {},
    orderSpec = {
        kind = "camp",
        campId = "camp:group:1",
        scope = "room",
        siteScope = "room",
        siteID = "room:bldg-1:lounge-1",
        roomID = "lounge-1",
        buildingID = "bldg-1",
        roomBounds = bounds,
        x = 25.5,
        y = 15.5,
        z = 0,
        radius = 3,
        resourceRadius = 12,
        placementState = "arrived",
    },
}

-- 1. Pending room scan does NOT prematurely fall back to floor seating/sleep.
local seatPending, _, _, seatReason = CampResources.FindSeat(npc1, { abstract = true })
T.equal(seatPending, nil, "FindSeat waits while room scan is pending")
T.equal(seatReason, "CAMP_RESOURCE_CAPTURE_PENDING",
    "FindSeat reports pending room capture instead of floor fallback")

local sleepPending, _, _, sleepReason = CampResources.FindSleep(npc1, { abstract = true })
T.equal(sleepPending, nil, "FindSleep waits while room scan is pending")
T.equal(sleepReason, "CAMP_RESOURCE_CAPTURE_PENDING",
    "FindSleep reports pending room capture instead of floor fallback")

-- 2. Bounded Pump finishes the 64-tile room in 2 ticks using room:getSquares()
--    directly (only 1 cell:getGridSquare lookup to get the room).
CampResources.Pump(1001)
CampResources.Pump(1002)
T.equal(gridSquareCalls, 1,
    "room scan iterates room:getSquares() directly instead of scanning cell grid")

-- 3. Both members with different interior slots share ONE cached snapshot.
local snap1 = CampResources.GetSnapshot(npc1, false)
local snap2 = CampResources.GetSnapshot(npc2, false)
T.truthy(snap1, "first member receives completed room snapshot")
T.equal(snap2, snap1,
    "second member at a different slot reuses the exact same room snapshot")
T.equal(gridSquareCalls, 1,
    "second member triggers zero additional square lookups")

-- 4. Nearest unreserved chair is picked per NPC, and bed is discovered.
local seat1 = CampResources.FindSeat(npc1, { abstract = true })
local seat2 = CampResources.FindSeat(npc2, { abstract = true })
T.truthy(seat1, "first NPC finds a chair in the room")
T.equal(seat1.resourceKey, "seat:chair-a",
    "first NPC picks the chair nearest to its position")
T.truthy(seat2, "second NPC finds a chair in the room")
T.equal(seat2.resourceKey, "seat:chair-b",
    "second NPC picks the chair nearest to its own position")

local sleep1 = CampResources.FindSleep(npc1, { abstract = true })
T.truthy(sleep1, "tired NPC finds the bed in the room")
T.equal(sleep1.resourceKey, "bed:bed-a",
    "tired NPC selects the room bed over floor sleep")

-- 5. FacilitySeat.IsEligible respects camp placementState.
PNC.CompanionCommands = { IsCompanion = function() return true end }
PNC.ActorControl = { IsPuppetOwned = function() return false end }
local FacilitySeat = T.load("ProjectHoomans", "server",
    "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_FacilitySeat.lua")

npc1.orderSpec.placementState = "moving"
T.equal(FacilitySeat.IsEligible(npc1), false,
    "FacilitySeat does not interrupt a camp member still moving to its slot")
npc1.orderSpec.placementState = "arrived"
local eligible, isCamp = FacilitySeat.IsEligible(npc1)
T.equal(eligible, true, "FacilitySeat allows an arrived camp member to sit")
T.equal(isCamp, true, "FacilitySeat identifies arrived member as camping")
