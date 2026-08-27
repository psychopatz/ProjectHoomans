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
T.equal(snapshot.profile.capacity, 2,
    "automatic room capacity follows detected bed count")
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
T.finish("pnc_facility_resources_smoke")
