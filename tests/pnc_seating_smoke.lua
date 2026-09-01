local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local squares = {}
local function squareKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function makeSquare(x, y, z, objects)
    local square = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getObjects = function() return javaList(objects or {}) end,
        isFree = function() return true end,
    }
    squares[squareKey(x, y, z)] = square
    return square
end

local chair = {
    seatable = true,
    getSprite = function()
        return { getName = function() return "furniture_chair_01_0" end }
    end,
}

makeSquare(10, 20, 0, { chair })
makeSquare(11, 20, 0, {})
makeSquare(10, 21, 0, {})
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[squareKey(x, y, z)]
        end,
    }
end

local vector = {}
local seatAnimState
local seatAnimNode
function vector:x() return self.valueX end
function vector:y() return self.valueY end
function vector:z() return self.valueZ end

Vector3f = { new = function() return vector end }
SeatingManager = {
    getInstance = function()
        return {
            getTilePositionCount = function(_, object)
                return object.seatable and 1 or 0
            end,
            getAdjacentPosition = function(_, _, object, direction, side,
                animState, animNode, position)
                seatAnimState, seatAnimNode = animState, animNode
                if object ~= chair or direction ~= "E" or side ~= "Front" then
                    return false
                end
                position.valueX = 11.5
                position.valueY = 20.5
                position.valueZ = 0
                return true
            end,
        }
    end,
}

local character = {
    getX = function() return 11 end,
    getY = function() return 20 end,
}

PNC = { Core = { Now = function() return 1000 end } }
local Resources = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_FacilityResources.lua")
local Targets = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_InteractionTargetResolver.lua")

local facility = {
    id = "living:seat-test",
    constructionState = "BUILT",
    constructionRegion = {
        levels = { [0] = { rows = { [20] = { 10, 10 } } } },
    },
}
local scan = Resources.Refresh(facility)
T.equal(#scan.resources, 1, "seat detector finds a chair")
local resource = scan.resources[1]
T.equal(resource.resourceKind, "seating_surface",
    "chair becomes a seating resource")
T.equal(resource.seatCount, 1, "seat capacity comes from SeatingManager")
resource.seatSpots = Resources.BuildSeatSpots(character, chair)
T.equal(#resource.seatSpots, 1,
    "vanilla SeatingManager approach spot is captured for a live NPC")
T.equal(resource.seatSpots[1].approachKey, "E:Front",
    "captured spot preserves the vanilla direction metadata")
T.near(resource.seatSpots[1].seatAnchorX, 11.5, 0.0001,
    "captured spot preserves the exact SeatingManager anchor")
T.near(resource.seatSpots[1].x, 11.5, 0.0001,
    "unblocked chair keeps its walk approach point")
T.equal(seatAnimState, "bumped",
    "seat discovery uses the zombie animation state")
T.equal(seatAnimNode, "PNC_Anim_SitChair",
    "seat discovery uses the PNC chair animation node")

local copied = Resources.CopyDescriptor(resource)
T.falsy(copied.object, "seat world object is excluded from primitive copies")
T.equal(#copied.seatSpots, 1,
    "nested seat spots survive the persistence boundary")

local targets = Targets.ResolveResource(resource, {
    abstract = false,
    character = character,
})
T.equal(#targets, 1, "seating resource resolves one valid target")
T.equal(targets[1].sceneId, "facility.living.sitFurniture",
    "seating target selects the furniture activity scene")
T.truthy(targets[1].seating, "target is marked as seating")
T.equal(targets[1].seatDirection, "E",
    "target carries the vanilla seat direction")
T.equal(targets[1].seatSide, "Front",
    "target carries the vanilla seat side")
T.equal(targets[1].approachKey, "E:Front",
    "target carries the exact vanilla approach key")
T.near(targets[1].stopDistance, 0.10, 0.0001,
    "seating target uses a tight movement stop")
T.near(targets[1].arrivalDistance, 0.14, 0.0001,
    "seating target uses a tight arrival tolerance")
T.truthy(targets[1].validSpot, "target is marked as a valid approach spot")

local reservationPurpose
PNC.Const = {
    ORDER_CAMP = "camp",
    CAMP_RESOURCE_RADIUS = 1,
    CAMP_RESOURCE_MAX = 8,
}
PNC.Registry = {
    GetLiveZombie = function() return character end,
    MarkDirty = function() end,
}
PNC.FacilityReservations = {
    ByResource = {},
    ReserveResource = function(_, resource, npcId, purpose)
        reservationPurpose = purpose
        local reservation = {
            id = "seat-reservation", resourceKey = resource.resourceKey,
            npcId = npcId, purpose = purpose,
        }
        PNC.FacilityReservations.ByResource[resource.resourceKey] =
            reservation.id
        return true, reservation
    end,
}
local Camp = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_CampResourceService.lua")
local campRecord = {
    id = "npc:camp-seat", alive = true, x = 10, y = 20, z = 0,
    runtime = {},
    orderSpec = {
        kind = "camp", campId = "camp:test", x = 10, y = 20, z = 0,
        resourceRadius = 1,
    },
}
local campSnapshot = Camp.Capture(campRecord, true)
T.equal(#campSnapshot.resources, 1,
    "camp snapshot captures the nearby seating surface")
T.equal(#campSnapshot.resources[1].seatSpots, 1,
    "camp snapshot retains vanilla approach spots")
T.equal(campSnapshot.campRadius, 3,
    "camp snapshot keeps the small movement radius separately")
local campSeat = Camp.AcquireSeat(campRecord, { abstract = true })
T.truthy(campSeat and campSeat.ok,
    "camp seating acquires a saved abstract target")
T.equal(campSeat.target.seatDirection, "E",
    "camp seating rehydrates the saved vanilla direction")
T.equal(reservationPurpose, "living",
    "camp seating uses the living reservation purpose")

campRecord.runtime.facilityActivity = {
    campActivity = true, capability = "living",
    facilityId = campSeat.facilityId, resourceKey = campSeat.resourceKey,
    resourceKind = campSeat.resourceKind, abstract = true,
    target = campSeat.target,
}
campRecord.orderSpec = {
    kind = "facility_activity", facilityId = campSeat.facilityId,
    resourceKey = campSeat.resourceKey,
    resourceKind = campSeat.resourceKind,
}
PNC.Registry.GetLiveZombie = function() return nil end
local abstractTarget = Camp.ResolveActivityTarget(campRecord)
T.truthy(abstractTarget and abstractTarget.seatDirection == "E",
    "abstract camp seating rehydrates its saved seat spot")

local ambientStartOptions
local ambientRecord = {
    id = "npc:ambient-seat", alive = true, x = 10, y = 20, z = 0,
    runtime = {}, orderSpec = { kind = "camp" },
}
PNC.CompanionCommands = {
    IsCompanion = function() return true end,
}
PNC.Registry.ForEach = function(visitor) visitor(ambientRecord) end
PNC.CampResourceService = {
    AcquireSeat = function() return campSeat end,
}
PNC.FacilityJobs = {
    Start = function(_, _, capability, options)
        ambientStartOptions = options
        T.equal(capability, "living",
            "ambient camp seating uses the living capability")
        return true
    end,
}
local Ambient = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityJobs/PNC_AmbientFacilityService.lua")
PNC.CampResourceService.AcquireSeat = function() return nil end
T.equal(Ambient.Pump(900), 0,
    "camp seating does not fall through to the home-seat resolver")
PNC.CampResourceService.AcquireSeat = function() return campSeat end
T.equal(Ambient.Pump(6000), 1,
    "idle camp companion starts an ambient seating activity")
T.truthy(ambientStartOptions and ambientStartOptions.campActivity,
    "ambient seating marks the activity as camp-owned")
T.truthy(ambientStartOptions and ambientStartOptions.seating,
    "ambient seating marks the activity as furniture seating")

T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/PNC_NameplateDebug.lua")
local seatingText = PNC.NameplateDebug.SeatingText({
    seatingDebug = {
        active = true, mode = "camp", foundCount = 1,
        facilityCount = 1, phase = "SITTING",
        seatState = "SEATED",
        selectedResourceKey = resource.resourceKey,
    },
}, { showAIDebug = true })
T.contains(seatingText, "Seats: camp ACTIVE",
    "seating debug summary reports camp activity")
T.contains(seatingText, "Phase: SITTING",
    "seating debug summary reports the activity phase")
T.contains(seatingText, "Seat: SEATED",
    "seating debug summary exposes the seat lifecycle state")
T.falsy(string.find(seatingText, "found=", 1, true),
    "seating nameplate omits facility dump counts")

local blockedSquare = makeSquare(30, 30, 0, {})
blockedSquare.isSolid = function() return true end
local blockedApproachSquare = makeSquare(31, 30, 0, {})
blockedApproachSquare.isSolid = function() return true end
local blockedChair = {
    getSquare = function() return blockedSquare end,
}
SeatingManager = {
    getInstance = function()
        return {
            getAdjacentPosition = function(_, _, object, direction, side,
                _, _, position)
                if object ~= blockedChair or direction ~= "E"
                    or side ~= "Front"
                then return false end
                position.valueX = 30.5
                position.valueY = 30.5
                position.valueZ = 0
                return true
            end,
        }
    end,
}
local blockedSpots = Resources.BuildSeatSpots(character, blockedChair)
T.equal(#blockedSpots, 1,
    "blocked furniture still exposes its rejected candidate for debugging")
T.falsy(blockedSpots[1].valid,
    "solid approach tiles are rejected before an NPC walks there")
T.equal(blockedSpots[1].rejectionReason, "solid",
    "blocked seating records the concrete approach rejection reason")
T.near(blockedSpots[1].seatAnchorX, 30.5, 0.0001,
    "blocked seating retains the animation anchor separately")

T.finish("pnc_seating_smoke")
