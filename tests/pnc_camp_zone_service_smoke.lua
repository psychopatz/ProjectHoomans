local T = require "tests/support/test"

T.addPackagePaths()

local rooms = {}
local squaresByRoom = {}
local campID = "camp:test"

local function copyBounds(bounds)
    return {
        minX = bounds.minX, minY = bounds.minY,
        maxX = bounds.maxX, maxY = bounds.maxY, z = bounds.z,
    }
end

local CampSite = {
    KIND = "camp_site",
    SCOPES = { ROOM = "room", CAMPFIRE = "campfire" },
    NormalizeScope = function(value)
        value = tostring(value or "")
        if value == "room" or value == "campfire" then return value end
        return nil
    end,
    NormalizeBounds = function(bounds)
        if type(bounds) ~= "table" then return nil end
        if bounds.minX == nil or bounds.minY == nil
            or bounds.maxX == nil or bounds.maxY == nil
        then
            return nil
        end
        return copyBounds(bounds)
    end,
}

local function makeSquare(roomID, x, y, features)
    local square = {
        roomID = roomID,
        x = x,
        y = y,
        z = 0,
        features = features or {},
    }
    function square:getX() return self.x end
    function square:getY() return self.y end
    function square:getZ() return self.z end
    return square
end

local building = { id = "house:test" }
function building:getID() return self.id end
local otherBuilding = { id = "house:other" }
function otherBuilding:getID() return self.id end

local function makeRoom(id, roomType, label, x, features, roomBuilding)
    local room = {
        id = id,
        roomType = roomType,
        label = label,
        x = x,
        building = roomBuilding or building,
    }
    room.squares = {
        makeSquare(id, x, 0, features),
        makeSquare(id, x + 1, 0, {}),
    }
    function room:getBuilding() return self.building end
    function room:getSquares() return self.squares end
    return room
end

rooms.living = makeRoom("living", "LIVING_ROOM", "living room", 0,
    { seat = true })
rooms.kitchen = makeRoom("kitchen", "KITCHEN", "kitchen", 4,
    { water = true })
rooms.bedroom = makeRoom("bedroom", "BEDROOM", "bedroom", 8,
    { bed = true })
rooms.otherBuilding = makeRoom("other", "LIVING_ROOM", "other living room", 12,
    { seat = true }, otherBuilding)
for _, room in pairs(rooms) do
    for _, square in ipairs(room.squares) do
        squaresByRoom[room.id .. ":" .. tostring(square.x)] = square
    end
end

local rootSquare = rooms.living.squares[1]
local cell = {
    getRoomList = function()
        return { rooms.living, rooms.kitchen, rooms.bedroom }
    end,
}

PNC = {
    Const = {},
    Core = { Now = function() return 100 end },
    Semantics = { CampSite = CampSite },
    Registry = {
        GetLiveZombie = function()
            return {
                getX = function() return 0 end,
                getY = function() return 0 end,
                getZ = function() return 0 end,
            }
        end,
    },
    CampResourceService = {
        Providers = {
            bed = {
                CaptureSquare = function(square, add)
                    if square.features.bed then
                        add({
                            resourceKind = "sleep_surface",
                            resourceKey = "bed:" .. tostring(square.x),
                        })
                    end
                end,
            },
            sofa = { CaptureSquare = function() end },
            faucet = {
                CaptureSquare = function(square, add)
                    if square.features.water then
                        add({
                            resourceKind = "water_source",
                            resourceKey = "faucet:" .. tostring(square.x),
                        })
                    end
                end,
            },
            seat = {
                CaptureSquare = function(square, add)
                    if square.features.seat then
                        add({
                            resourceKind = "seating_surface",
                            resourceKey = "seat:" .. tostring(square.x),
                        })
                    end
                end,
            },
        },
    },
    NeedFacilityTriggerDefinitions = {
        Get = function(id) return { id = id } end,
        Evaluate = function(definition, record)
            local needs = record.needs or {}
            local value = tonumber(needs[definition.id]) or 0
            local threshold = definition.id == "sleep" and 0.70 or 0.70
            if value <= threshold then return false end
            return true, {
                value = value,
                urgency = value,
                precedence = value >= 0.85
                    and "CRITICAL_NEED" or "NORMAL_NEED",
            }
        end,
    },
}

PNC.Semantics.CampSiteGeometry = {
    GetSquare = function(_, x)
        if math.floor(tonumber(x) or -1) == 0 then return rootSquare end
        return nil
    end,
    MatchesRoom = function(square, site)
        return square and tostring(square.roomID) == tostring(site.roomID)
    end,
    EnumerateRooms = function(_, callback)
        callback(rooms.living, building, 1)
        callback(rooms.kitchen, building, 2)
        callback(rooms.bedroom, building, 3)
        callback(rooms.otherBuilding, otherBuilding, 4)
        return 4
    end,
    DescribeRoom = function(room)
        return {
            kind = "camp_site",
            scope = "room",
            siteScope = "room",
            siteID = "room:" .. room.id,
            roomID = room.id,
            buildingID = building.id,
            roomType = room.roomType,
            roomName = room.label,
            roomBounds = {
                minX = room.x, minY = 0, maxX = room.x + 1,
                maxY = 0, z = 0,
            },
            x = room.x + 0.5,
            y = 0.5,
            z = 0,
            label = room.label,
            radius = 3,
            resourceRadius = 12,
        }
    end,
    _Internal = {
        RoomFor = function() return rooms.living end,
    },
}

getCell = function() return cell end

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/World/PNC_CampZoneService.lua"
)

local rootSite = {
    kind = "camp_site",
    scope = "room",
    siteScope = "room",
    siteID = "room:living",
    roomID = "living",
    buildingID = building.id,
    roomType = "LIVING_ROOM",
    roomName = "living room",
    roomBounds = { minX = 0, minY = 0, maxX = 1, maxY = 0, z = 0 },
    x = 0.5, y = 0.5, z = 0,
    label = "living room",
    radius = 3,
    resourceRadius = 12,
}

local records = {
    sleepy = { id = "npc_sleepy", needs = { sleep = 0.95 } },
    thirsty = { id = "npc_thirsty", needs = { hydration = 0.95 } },
    hungry = { id = "npc_hungry", needs = { hunger = 0.95 } },
    socialA = { id = "npc_social_a", needs = {} },
    socialB = { id = "npc_social_b", needs = {} },
}

local directory = Service.BuildGroup(rootSite, {
    records.sleepy,
    records.thirsty,
    records.hungry,
    records.socialA,
    records.socialB,
}, { campId = campID, cell = cell })

T.truthy(directory, "camp zone directory was not built")
T.equal(directory.zoneCount, 3, "loaded room directory size")
T.equal(directory.assignments.npc_sleepy.zoneID, "room:bedroom",
    "sleep need did not choose bedroom")
T.equal(directory.assignments.npc_sleepy.zoneLabel, "bedroom",
    "sleep assignment omitted room label")
T.equal(directory.assignments.npc_thirsty.zoneID, "room:kitchen",
    "hydration need did not choose water room")
T.equal(directory.assignments.npc_hungry.zoneID, "room:kitchen",
    "hunger need did not choose kitchen")
T.equal(directory.assignments.npc_social_a.zoneID, "room:living",
    "normal NPC did not choose living room")
T.equal(directory.zones[1].capabilities.water, false,
    "living-room floor was misclassified as water")
T.equal(directory.zones[4], nil,
    "group camp crossed into a different building")
T.equal(Service.GetAssignment(campID, "npc_sleepy").needKind, "sleep",
    "stored assignment omitted need kind")

local socialDirectory = Service.BuildGroup(rootSite, {
    records.socialA,
    records.socialB,
}, { campId = "camp:social", cell = cell })
T.equal(socialDirectory.assignments.npc_social_a.zoneID, "room:living",
    "normal NPC did not choose living room")
T.equal(socialDirectory.assignments.npc_social_b.zoneID, "room:kitchen",
    "normal NPCs were not distributed across social rooms")

local previousMaximum = Service.MAX_RETAINED_CAMPS
Service.MAX_RETAINED_CAMPS = 1
Service.BuildGroup(rootSite, { records.socialA }, {
    campId = "camp:retained:one", cell = cell,
})
Service.BuildGroup(rootSite, { records.socialB }, {
    campId = "camp:retained:two", cell = cell,
})
T.equal(Service.Get("camp:retained:one"), nil,
    "old camp directories were not pruned")
T.truthy(Service.Get("camp:retained:two"),
    "newest camp directory was pruned")
Service.MAX_RETAINED_CAMPS = previousMaximum
Service.Release("camp:retained:two")

T.finish("pnc_camp_zone_service_smoke")
