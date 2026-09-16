local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function list(values)
    return values
end

local function square(x, y, z, room, objects)
    local value = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getRoom = function() return room end,
        isInARoom = function() return room ~= nil end,
        isFree = function() return true end,
        getObjects = function() return objects or {} end,
    }
    return value
end

local bedroomDefinition = {
    getIDString = function() return "bedroom-1" end,
    getName = function() return "bedroom" end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getX2 = function() return 12 end,
    getY2 = function() return 12 end,
    getZ = function() return 0 end,
}

local bathroomDefinition = {
    getIDString = function() return "bathroom-1" end,
    getName = function() return "bathroom" end,
    getX = function() return 20 end,
    getY = function() return 10 end,
    getX2 = function() return 22 end,
    getY2 = function() return 12 end,
    getZ = function() return 0 end,
}

local bedroom = {}
local bathroom = {}
local bedroomBed = { bed = true }
local outsideBed = { bed = true }
local bedroomSquare = square(10, 10, 0, bedroom, { bedroomBed })
local bedroomSquareTwo = square(11, 10, 0, bedroom, {})
local bathroomSquare = square(20, 10, 0, bathroom, {})
local outsideSquare = square(12, 10, 0, nil, { outsideBed })

bedroom.getRoomDef = function() return bedroomDefinition end
bedroom.getSquares = function() return list({ bedroomSquare, bedroomSquareTwo }) end
bedroom.getFreeTile = function() return bedroomSquare end

bathroom.getRoomDef = function() return bathroomDefinition end
bathroom.getSquares = function() return list({ bathroomSquare }) end
bathroom.getFreeTile = function() return bathroomSquare end

local bedroomBuilding = {
    getID = function() return "building-1" end,
    getDef = function()
        return { getIDString = function() return "building-1" end }
    end,
    rooms = list({ bedroom, bathroom }),
    isToxic = function() return false end,
    isResidential = function() return true end,
}
bedroom.getBuilding = function() return bedroomBuilding end
bathroom.getBuilding = function() return bedroomBuilding end

local squares = {
    ["10:10:0"] = bedroomSquare,
    ["11:10:0"] = bedroomSquareTwo,
    ["12:10:0"] = outsideSquare,
    ["20:10:0"] = bathroomSquare,
}
local cell = {
    getBuildingList = function() return list({ bedroomBuilding }) end,
    getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end,
}
getCell = function() return cell end

local Geometry = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")
local CampSite = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSite.lua")

local player = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return bedroomSquare end,
}

local roomSite, roomReason = Geometry.FindNearestRoom(
    cell, player, { roomType = "BEDROOM", text = "bedroom" }, { radius = 32 })
T.truthy(roomSite, "a loaded bedroom resolves as a camp site")
T.equal(roomReason, nil, "room resolution has no failure reason")
T.equal(roomSite.scope, CampSite.SCOPES.ROOM, "room site has room scope")
T.equal(roomSite.roomID, "bedroom-1", "room identity uses RoomDef id")
T.equal(roomSite.buildingID, "building-1", "room identity keeps building id")
T.equal(roomSite.roomType, "BEDROOM", "room identity keeps normalized type")
T.truthy(Geometry.MatchesRoom(bedroomSquare, roomSite),
    "the selected room accepts its own squares")
T.falsy(Geometry.MatchesRoom(bathroomSquare, roomSite),
    "the selected room rejects another room in the building")

PNC = {
    Const = {
        ORDER_CAMP = "camp",
        CAMP_RESOURCE_RADIUS = 3,
        CAMP_RESOURCE_MAX = 16,
        CAMP_RESOURCE_SCAN_SQUARES_PER_TICK = 64,
    },
    Core = { Now = function() return 1000 end },
    Registry = { MarkDirty = function() end },
    FacilityResources = {},
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            return { {
                x = resource.x + 0.5, y = resource.y, z = resource.z,
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                sleepSurface = resource.sleepSurface,
            } }
        end,
    },
}

-- The provider receives (square, object), so keep the test detector's
-- signature aligned with the production detector contract.
PNC.FacilityResources.GetDetector = function(id)
    if id ~= "bed" then return nil end
    return {
        matches = function(_, object) return object.bed == true end,
        describe = function(sq)
            return {
                x = sq:getX() + 0.5, y = sq:getY() + 0.5,
                z = sq:getZ(), sleepSurface = "bed",
            }
        end,
        key = function(resource) return "bed:" .. tostring(resource.x) end,
        sleepSurface = "bed", sleepPriority = 100,
    }
end

T.load("ProjectHoomans", "server", "PNC/World/PNC_CampResourceService.lua")
local Service = PNC.CampResourceService
local record = {
    id = "npc:room-camp", alive = true, x = 10.5, y = 10.5, z = 0,
    runtime = {}, orderSpec = {
        kind = "camp", campId = "room:building-1:bedroom-1",
        scope = "room", siteScope = "room",
        siteID = roomSite.siteID, roomID = roomSite.roomID,
        buildingID = roomSite.buildingID, roomType = roomSite.roomType,
        roomBounds = roomSite.roomBounds,
        x = roomSite.x, y = roomSite.y, z = roomSite.z,
        radius = 3, resourceRadius = 3,
    },
}

local snapshot = Service.Capture(record, true)
T.truthy(snapshot, "room camp capture completes")
T.equal(snapshot.scope, "room", "room camp snapshot preserves scope")
T.equal(#snapshot.resources, 1,
    "room camp capture excludes objects outside the selected room")
T.equal(snapshot.resources[1].resourceKey, "bed:10.5",
    "room camp keeps the selected room's resource")

local resource, target = Service.FindSleep(record, { abstract = true })
T.truthy(resource and target, "room camp can use an in-room sleep resource")
T.equal(resource.resourceKey, "bed:10.5",
    "room camp resource selection remains room-scoped")

T.finish("pnc_semantic_camp_site_smoke")
