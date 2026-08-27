local T = require "tests/support/test"
T.addPackagePaths()

local legacyComponent = {
    id = "legacy-bed", facilityId = "bedroom:1", role = "sleep.bed",
    kind = "anchor",
}
local facility = {
    id = "bedroom:1", definitionId = "bedroom", level = 1,
    components = { legacyComponent },
}
local resource = {
    resourceKey = "bed:11:41:0", resourceKind = "sleep_surface",
    role = "sleep.bed", exclusive = true,
    object = {},
}
local floorResource = {
    resourceKey = "bedroom:1:floor", resourceKind = "floor_sleep",
    role = "sleep.bed", exclusive = false,
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix) return prefix .. ":1" end,
    },
    SettlementRepository = {
        GetFacility = function(id)
            return tostring(id) == facility.id and facility or nil
        end,
        GetComponent = function(id)
            return tostring(id) == legacyComponent.id and legacyComponent or nil
        end,
    },
    FacilityDefinitions = {
        GetLevel = function()
            return { activityLimits = { sleep = { maxConcurrent = 2 } } }
        end,
    },
    FacilityService = {
        ListByCapability = function() return { facility } end,
        RevalidateTargets = function() return true end,
    },
}
PNC.FacilityResources = {
    CopyDescriptor = function(value)
        local copy = {}
        for key, item in pairs(value) do
            if key ~= "object" then copy[key] = item end
        end
        return copy
    end,
    GetBinding = function()
        return { detectorId = "bed", role = "sleep.bed" }
    end,
    GetCapacity = function(room)
        return room.capacity or 1
    end,
    Select = function(room, _, options)
        if PNC.FacilityReservations
            and PNC.FacilityReservations.ByResource[resource.resourceKey]
        then
            if room.capacity then
                return {
                    resource = floorResource,
                    target = { x = 10.5, y = 40.5, z = 0,
                        sceneId = "facility.sleep.floor",
                        sleepSurface = "floor" },
                    targets = {}, role = floorResource.role,
                    resourceKind = floorResource.resourceKind,
                    resourceKey = floorResource.resourceKey,
                }
            end
            return nil
        end
        return {
            resource = resource,
            target = { x = 10.5, y = 40.5, z = 0,
                sceneId = "facility.sleep.bed", sleepSurface = "bed" },
            targets = {}, role = resource.role,
            resourceKind = resource.resourceKind,
            resourceKey = resource.resourceKey,
        }
    end,
}

local Reservations = require "PNC/Settlement/PNC_FacilityReservations"
local first = PNC.FacilityService.AcquireActivity(
    facility.id, "npc:1", "sleep", { ttlMs = 5000 })
T.truthy(first.ok, "first NPC acquires discovered bed")
T.equal(first.componentId, nil, "resource activity has no fake component id")
T.equal(first.resourceKey, resource.resourceKey,
    "resource key reaches the activity assignment")
T.equal(Reservations.ByID[first.reservationId].resource.object, nil,
    "resource reservations keep world objects out of runtime state")

local second = PNC.FacilityService.AcquireActivity(
    facility.id, "npc:2", "sleep", { ttlMs = 5000 })
T.falsy(second.ok, "reserved discovered bed is exclusive")
T.equal(second.reason, "NO_ACTIVITY_CAPACITY",
    "reserved discovered bed reports no capacity")

T.truthy(Reservations.Release(first.reservationId, "complete"),
    "resource reservation releases through the generic API")
T.falsy(Reservations.ByResource[resource.resourceKey],
    "released resource is available again")

facility.capacity = 2
local bedSleeper = PNC.FacilityService.AcquireActivity(
    facility.id, "npc:3", "sleep", { ttlMs = 5000 })
local floorSleeper = PNC.FacilityService.AcquireActivity(
    facility.id, "npc:4", "sleep", { ttlMs = 5000 })
T.truthy(bedSleeper.ok and floorSleeper.ok,
    "room capacity allows a floor sleeper after its bed is occupied")
T.equal(floorSleeper.resourceKey, floorResource.resourceKey,
    "capacity overflow selects the shared floor resource")
local overCapacity = PNC.FacilityService.AcquireActivity(
    facility.id, "npc:5", "sleep", { ttlMs = 5000 })
T.falsy(overCapacity.ok, "room capacity limits total sleepers")
T.equal(overCapacity.reason, "NO_ACTIVITY_CAPACITY",
    "room capacity returns the normal activity capacity reason")
Reservations.Release(bedSleeper.reservationId, "complete")
Reservations.Release(floorSleeper.reservationId, "complete")
T.finish("pnc_facility_resource_reservation_smoke")
