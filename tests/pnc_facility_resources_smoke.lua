local T = require "tests/support/test"

T.addPackagePaths()

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local squares = {}
local function makeSquare(x, y, objects)
    local value = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        getObjects = function() return javaList(objects or {}) end,
        isFree = function() return true end,
    }
    squares[x .. ":" .. y .. ":0"] = value
    return value
end

local function bedObject()
    local properties = {
        get = function(_, key)
            local values = {
                CustomName = "Bed", BedType = "GoodBed", Facing = "E",
            }
            return values[key]
        end,
    }
    local grid = {
        getSpriteGridPosX = function() return 0 end,
        getSpriteGridPosY = function() return 0 end,
        getWidth = function() return 2 end,
        getHeight = function() return 1 end,
    }
    local sprite = {
        getName = function() return "furniture_bedding_01_0" end,
        getProperties = function() return properties end,
        getSpriteGrid = function() return grid end,
    }
    return {
        getSprite = function() return sprite end,
        getProperties = function() return properties end,
        getSurfaceOffsetNoTable = function() return 0.15 end,
    }
end

local firstBed = bedObject()
makeSquare(10, 20, { firstBed })
makeSquare(11, 20, {})
makeSquare(12, 20, { bedObject() })
makeSquare(13, 20, {})
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[x .. ":" .. y .. ":" .. z]
        end,
    }
end

PNC = {}
local Resources = require "PNC/Settlement/PNC_FacilityResources"
local Targets = require "PNC/Settlement/PNC_InteractionTargetResolver"
local region = { levels = { [0] = { rows = { [20] = { 10, 13 } } } } }
local facility = {
    id = "bedroom:1", constructionState = "BUILT",
    constructionRegion = region,
}
local scan = Resources.Refresh(facility)
T.equal(scan.status, "READY", "loaded bedroom region scan")
T.equal(#scan.resources, 2, "bed detector finds each bed once")
T.truthy(scan.resources[1].resourceKey ~= scan.resources[2].resourceKey,
    "detected beds have distinct resource keys")
T.equal(scan.resources[1].surfaceOffset, 0.15,
    "bed surface offset is retained for placement")

local target = Targets.ResolveResource(scan.resources[1], { abstract = true })[1]
T.equal(target.sceneId, "facility.sleep.bed", "bed resource selects bed scene")
T.equal(target.sleepSurface, "bed", "bed resource selects bed surface")
T.equal(target.interactionSurfaceOffset, 0.15,
    "bed target carries surface offset")
T.equal(target.interactionZ, (0.15 + 1) / 96,
    "bed target converts surface height to world Z")
local targets = Targets.ResolveResource(scan.resources[1], { abstract = true })
T.equal(#targets, 2, "two-tile bed exposes two sleep slots")
T.equal(targets[1].sleepSlotId, "slot:1", "first bed slot is stable")
T.equal(targets[2].sleepSlotId, "slot:2", "second bed slot is stable")
T.truthy(targets[1].interactionX ~= targets[2].interactionX
    or targets[1].interactionY ~= targets[2].interactionY,
    "double-bed slots have distinct interaction poses")
local isolated = {
    resourceKey = "bed:isolated", resourceKind = "sleep_surface",
    detectorId = "bed", sleepSurface = "bed", originX = 50, originY = 50,
    originZ = 0, x = 51, y = 50.5, z = 0, gridX = 0, gridY = 0,
    gridWidth = 2, gridHeight = 1,
}
T.equal(#Targets.ResolveResource(isolated, {
    abstract = false, character = {},
}), 0, "live sleep resolution rejects a bed without an approach square")
T.truthy(Resources.IsValidSleepTarget(scan.resources[1], target),
    "bed target passes the physical sleep-target gate")
T.falsy(Resources.IsValidSleepTarget(
    { resourceKind = "seating_surface", sleepSurface = "bed" },
    target), "seating resources cannot be reclassified as sleep")
T.falsy(Resources.IsValidSleepTarget(
    { resourceKind = "sleep_surface", detectorId = "seat",
        sleepSurface = "bed" }, target),
    "seat detectors cannot be reclassified as bed sleep")
T.falsy(Resources.IsValidSleepTarget(
    { resourceKind = "sleep_surface", sleepSurface = "bed" },
    { sceneId = "facility.living.sitFurniture", sleepSurface = "bed" }),
    "chair scenes cannot pass as bed sleep")

PNC.FacilityDefinitions = {
    GetLevel = function()
        return { resourceBindings = {
            sleep = { detectorId = "bed", role = "sleep.bed",
                resourceKind = "sleep_surface",
                virtual = { key = "floor", resourceKind = "floor_sleep",
                    sceneId = "facility.sleep.floor", sleepSurface = "floor" },
            },
        } }
    end,
}
local snapshot = Resources.BuildSnapshot(facility)
T.equal(snapshot.profile.bedCount, 2, "room profile counts discovered beds")
T.equal(snapshot.profile.capacity, 4,
    "automatic room capacity follows detected bed slots")
T.equal(snapshot.profile.classification, "barracks",
    "multiple beds classify the room as barracks")
T.equal(#snapshot.components, 2, "discovered beds become read-only components")
T.equal(snapshot.components[1].kind, "discovered",
    "discovered component is not an editable anchor")
T.equal(snapshot.components[1].object, nil,
    "world object reference does not cross snapshot boundary")

facility.capacity = 1
local singleCapacity = Resources.BuildSnapshot(facility)
T.equal(singleCapacity.profile.capacity, 1,
    "room capacity override controls effective occupancy")
T.equal(singleCapacity.profile.classification, "bedroom",
    "capacity of one keeps a multi-bed room private")

facility.capacity = 5
local sharedCapacity = Resources.BuildSnapshot(facility)
T.equal(sharedCapacity.profile.capacity, 5,
    "larger room capacity override is exposed in the profile")
T.equal(sharedCapacity.profile.classification, "barracks",
    "capacity above one classifies the room as barracks")

local emptyFacility = {
    id = "bedroom:2", constructionState = "BUILT",
    constructionRegion = { levels = { [0] = { rows = { [20] = { 30, 30 } } } } },
}
makeSquare(30, 20, {})
Resources.Refresh(emptyFacility)
local empty = Resources.BuildSnapshot(emptyFacility)
T.equal(empty.profile.bedCount, 0, "empty room has no discovered beds")
T.equal(empty.profile.sleepSurface, "floor", "empty room uses floor fallback")

local sofaProperties = {
    get = function(_, key)
        local values = {
            CustomName = "Sofa", FurnitureType = "Seating",
        }
        return values[key]
    end,
}
local sofaGrid = {
    getWidth = function() return 2 end,
    getHeight = function() return 1 end,
}
local sofaSprite = {
    getName = function() return "furniture_seating_01_0" end,
    getProperties = function() return sofaProperties end,
    getSpriteGrid = function() return sofaGrid end,
    tilesetName = "furniture_seating",
}
local sofa = {
    getName = function() return "Sofa" end,
    getSprite = function() return sofaSprite end,
    getProperties = function() return sofaProperties end,
    getSurfaceOffsetNoTable = function() return 0.10 end,
}
makeSquare(31, 20, { sofa })
makeSquare(31, 21, {})
local sofaFacility = {
    id = "bedroom:sofa", constructionState = "BUILT",
    constructionRegion = { levels = { [0] = { rows = { [20] = { 31, 31 } } } } },
}
local sofaScan = Resources.Refresh(sofaFacility)
T.equal(#sofaScan.resources, 1, "sofa detector finds an approved sofa")
T.equal(sofaScan.resources[1].detectorId, "sofa",
    "sofa remains separate from generic seating resources")
T.equal(sofaScan.resources[1].sleepSurface, "sofa",
    "sofa resource carries its sleep surface classification")
local sofaTarget = Targets.ResolveResource(
    sofaScan.resources[1], { abstract = true })[1]
T.equal(sofaTarget.sceneId, "facility.sleep.sofa",
    "sofa resource selects the dedicated sofa sleep scene")
T.equal(sofaTarget.sleepSurface, "sofa",
    "sofa target preserves its sleep surface classification")

PNC.FacilityDefinitions = {
    GetLevel = function()
        return { resourceBindings = {
            sleep = {
                detectorId = "bed", detectorIds = { "bed", "sofa" },
                role = "sleep.bed", resourceKind = "sleep_surface",
                virtual = { key = "floor", resourceKind = "floor_sleep",
                    sceneId = "facility.sleep.floor", sleepSurface = "floor" },
            },
        } }
    end,
}
local sofaSnapshot = Resources.BuildSnapshot(sofaFacility)
T.equal(sofaSnapshot.profile.sofaCount, 1,
    "room profile counts discovered sofas")
T.equal(sofaSnapshot.profile.sleepSurfaceCount, 1,
    "sofas count as physical sleep surfaces")
T.equal(sofaSnapshot.profile.sleepSurface, nil,
    "sofa-only rooms do not use the floor profile")
local selectedSofa = Resources.Select(sofaFacility, "sleep")
T.equal(selectedSofa.resourceKey, sofaScan.resources[1].resourceKey,
    "sleep selection can acquire a sofa resource")
T.equal(selectedSofa.target.sceneId, "facility.sleep.sofa",
    "sleep selection does not route sofas through chair seating")

local floorBinding = {
    detectorId = "seat", role = "living.chair",
    resourceKind = "seating_surface",
    virtual = {
        key = "floor", role = "living.floor",
        resourceKind = "floor_seating", exclusive = false,
        perNpc = true, seating = true, floorSeating = true,
        allowActivityOverflow = true,
        sceneId = "facility.living.sit",
        stopDistance = 0.45, arrivalDistance = 0.55,
    },
}
PNC.FacilityDefinitions.GetLevel = function()
    return {
        resourceBindings = { living = floorBinding },
        activityLimits = { living = { maxConcurrent = 8 } },
    }
end
makeSquare(40, 40, {})
makeSquare(41, 40, {})
local emptyLiving = {
    id = "living:floor", definitionId = "living_room", level = 1,
    constructionState = "BUILT",
    constructionRegion = {
        levels = { [0] = { rows = { [40] = { 40, 41 } } } },
    },
}
local firstFloor = Resources.Select(emptyLiving, "living", {
    npcId = "npc:floor:1",
})
local secondFloor = Resources.Select(emptyLiving, "living", {
    npcId = "npc:floor:2",
})
T.equal(firstFloor.resourceKind, "floor_seating",
    "living selection falls back to a virtual floor seat")
T.equal(firstFloor.target.sceneId, "facility.living.sit",
    "facility floor fallback selects the ground sitting scene")
T.truthy(firstFloor.target.seating and firstFloor.target.floorSeating,
    "facility floor fallback remains a seated presentation")
T.truthy(firstFloor.resourceKey ~= secondFloor.resourceKey,
    "facility floor seating allocates a stable per-NPC resource key")
T.truthy(firstFloor.target.x >= 40.5 and firstFloor.target.x <= 41.5
        and firstFloor.target.y == 40.5,
    "facility floor target remains inside its construction region")
PNC.SettlementRepository = {
    GetFacility = function(id)
        return tostring(id) == emptyLiving.id and emptyLiving or nil
    end,
}
local rehydratedFloor = Resources.ResolveActivityTarget({
    id = "npc:floor:1",
    runtime = { facilityActivity = {
        capability = "living", facilityId = emptyLiving.id,
        resourceKey = firstFloor.resourceKey,
        resourceKind = "floor_seating", floorSeating = true,
    } },
})
T.equal(rehydratedFloor.resourceKey, firstFloor.resourceKey,
    "facility floor seating rehydrates by its per-NPC resource key")
T.equal(rehydratedFloor.sceneId, "facility.living.sit",
    "rehydrated facility floor seating retains its ground scene")

PNC.FacilityService = {
    ListByCapability = function() return { emptyLiving } end,
}
PNC.Registry = { GetLiveZombie = function() return nil end }
PNC.FacilityReservations = {
    Internal = {}, ByResource = {},
    ReserveResource = function(_, resource, npcId, capability)
        return true, {
            id = "floor-seat-reservation", resourceKey = resource.resourceKey,
            npcId = npcId, purpose = capability,
        }
    end,
}
T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityReservations/PNC_FacilityReservations_Acquisition.lua")
local acquiredFloor = PNC.FacilityService.AcquireActivity(
    emptyLiving.id, "npc:acquired-floor", "living", { abstract = true })
T.truthy(acquiredFloor.ok,
    "generic facility acquisition accepts the floor seating resource")
T.equal(acquiredFloor.facility, emptyLiving,
    "generic facility acquisition returns the selected facility")
T.truthy(acquiredFloor.floorSeating
        and acquiredFloor.target.floorSeating,
    "generic facility acquisition preserves floor seating metadata")
T.finish("pnc_facility_resources_smoke")
