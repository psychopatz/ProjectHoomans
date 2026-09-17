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

local function distance(x1, y1, x2, y2)
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
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

T.equal(CampSite.RoomLabel("UNKNOWN_ROOM", "custom_room"),
    "room", "unclassified rooms use the generic camp label")
local normalizedHere = CampSite.NormalizeTarget({
    kind = CampSite.KIND, scope = "room", query = "here",
})
T.equal(normalizedHere.scope, CampSite.SCOPES.HERE,
    "deictic room-shaped camp targets normalize to here")
T.falsy(normalizedHere.query,
    "deictic normalization clears the stale room query")

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

local outsideCell = {
    getBuildingList = function() return {} end,
    getGridSquare = cell.getGridSquare,
}
local outsidePlayer = {
    getX = function() return 12.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return outsideSquare end,
}
local outsideRoom, outsideReason = Geometry.FindNearestRoom(
    outsideCell, outsidePlayer, {}, { radius = 8 })
T.truthy(outsideRoom,
    "a nearby loaded room resolves even when the building index is empty")
T.equal(outsideReason, nil,
    "nearby loaded-square room discovery has no failure reason")
T.equal(outsideRoom.roomID, "bedroom-1",
    "outside discovery returns the nearby room identity")

PNC = {
    Const = {
        ORDER_CAMP = "camp",
        CAMP_RESOURCE_RADIUS = 3,
        CAMP_RESOURCE_MAX = 16,
        CAMP_RESOURCE_SCAN_SQUARES_PER_TICK = 64,
    },
    Core = { Now = function() return 1000 end, Distance = distance },
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

local CampBehavior = T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Camp.lua")
local activity = {
    campActivity = true, scope = CampSite.SCOPES.ROOM,
    siteScope = CampSite.SCOPES.ROOM,
    roomBounds = { minX = 10, minY = 10, maxX = 20, maxY = 20, z = 0 },
    campX = 10.5, campY = 10.5, campZ = 0, campRadius = 3,
}
local activityRecord = {
    id = "npc:room-activity", alive = true, x = 10.5, y = 10.5, z = 0,
    runtime = { facilityActivity = activity },
}
local safe, safetyReason = CampBehavior.CampActivityIsSafe(
    activityRecord, nil, activity, {
        kind = "facility_activity", x = 16.5, y = 10.5, z = 0,
    })
T.truthy(safe,
    "room activities accept targets beyond the camp anchor radius")
T.equal(safetyReason, nil,
    "room activity safety has no failure for an in-room target")
local outsideSafe, outsideReason = CampBehavior.CampActivityIsSafe(
    activityRecord, nil, activity, {
        kind = "facility_activity", x = 22.5, y = 10.5, z = 0,
    })
T.falsy(outsideSafe,
    "room activities reject targets outside the selected room")
T.equal(outsideReason, "CAMP_ACTIVITY_TARGET_OUTSIDE_ROOM",
    "room boundary rejection reports a room-specific reason")

local campfireActivity = {
    campActivity = true, scope = CampSite.SCOPES.CAMPFIRE,
    siteScope = CampSite.SCOPES.CAMPFIRE,
    campX = 10.5, campY = 10.5, campZ = 0, campRadius = 3,
}
local travellingZombie = {
    getX = function() return 20.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
}
local campfireSafe, campfireReason = CampBehavior.CampActivityIsSafe(
    { id = "npc:campfire-activity", alive = true,
        x = 20.5, y = 10.5, z = 0,
        runtime = { facilityActivity = campfireActivity } },
    travellingZombie, campfireActivity,
    { kind = "facility_activity", x = 10.5, y = 10.5, z = 0 })
T.truthy(campfireSafe,
    "campfire activity allows travel toward the camp anchor")
T.equal(campfireReason, nil,
    "campfire travel does not report a premature outside-area failure")
campfireActivity.arrivalSettled = true
local arrivedSafe, arrivedReason = CampBehavior.CampActivityIsSafe(
    { id = "npc:campfire-activity", alive = true,
        x = 10.5, y = 10.5, z = 0,
        runtime = { facilityActivity = campfireActivity } },
    { getX = function() return 10.5 end,
        getY = function() return 10.5 end,
        getZ = function() return 0 end },
    campfireActivity,
    { kind = "facility_activity", x = 10.5, y = 10.5, z = 0 })
T.truthy(arrivedSafe, "arrived campfire activity remains inside its zone")
T.equal(arrivedReason, nil,
    "arrived campfire activity has no safety failure")

T.finish("pnc_semantic_camp_site_smoke")
