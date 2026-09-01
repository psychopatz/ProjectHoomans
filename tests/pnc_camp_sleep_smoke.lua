local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local squares = {}
local reservations = {}
local nextReservation = 0

local function squareKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function newSquare(x, y, z, objects)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getObjects = function() return objects end,
    }
end

local bed = { bed = true }
local faucet = { faucet = true }
squares[squareKey(10, 10, 0)] = newSquare(10, 10, 0, { bed })
squares[squareKey(11, 10, 0)] = newSquare(11, 10, 0, { faucet })

local bedDetector = {
    matches = function(_, object) return object.bed == true end,
    describe = function(square)
        return {
            x = square:getX() + 0.5, y = square:getY() + 0.5,
            z = square:getZ(), axis = "x", facing = "E",
            surfaceOffset = 0,
        }
    end,
    key = function(resource)
        return "bed:" .. tostring(resource.x) .. ":" .. tostring(resource.y)
    end,
}

local bedValid = true

PNC = {
    Const = {
        ORDER_CAMP = "camp", CAMP_RESOURCE_RADIUS = 2,
        CAMP_RESOURCE_MAX = 16,
    },
    Core = { Now = function() return 1000 end },
    NeedsUtils = { WorldAgeHours = function() return 12 end },
    Registry = { MarkDirty = function() end },
    FacilityResources = {
        GetDetector = function(id)
            return id == "bed" and bedDetector or nil
        end,
        ApplyMaterializationTarget = function(_, _, target)
            return target.interactionX ~= nil
        end,
    },
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            if resource.resourceKind ~= "sleep_surface" or not bedValid then
                return {}
            end
            return { {
                x = resource.x + 1, y = resource.y, z = resource.z,
                interactionX = resource.x, interactionY = resource.y,
                interactionZ = resource.z, interactionFacing = resource.facing,
                sceneId = "facility.sleep.bed", sleepSurface = "bed",
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
            } }
        end,
    },
    NearbyWaterService = {
        IsCleanFaucet = function(object) return object.faucet == true end,
    },
    NearbyResourceLocator = {
        ObjectKeyFor = function(_, x, y, z, ordinal)
            return "faucet:" .. tostring(x) .. ":" .. tostring(y)
                .. ":" .. tostring(z) .. ":" .. tostring(ordinal)
        end,
    },
    FacilityReservations = {
        ByID = {}, ByResource = {},
        ReserveResource = function(facilityId, resource, npcId, purpose)
            nextReservation = nextReservation + 1
            local id = "reservation:" .. tostring(nextReservation)
            local reservation = {
                id = id, facilityId = facilityId,
                resourceKey = resource.resourceKey, npcId = npcId,
                purpose = purpose,
            }
            reservations[id] = reservation
            PNC.FacilityReservations.ByID[id] = reservation
            if resource.exclusive ~= false then
                PNC.FacilityReservations.ByResource[resource.resourceKey] = id
            end
            return true, reservation
        end,
        Release = function(id)
            local reservation = reservations[id]
            if not reservation then return false end
            reservations[id] = nil
            PNC.FacilityReservations.ByID[id] = nil
            PNC.FacilityReservations.ByResource[reservation.resourceKey] = nil
            return true
        end,
    },
}

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[squareKey(x, y, z)]
        end,
    }
end

local Service = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_CampResourceService.lua")

local record = {
    id = "npc:camp-sleep",
    alive = true, x = 10, y = 10, z = 0,
    needs = { thirst = 0.60 },
    runtime = {},
    orderSpec = {
        kind = "camp", campId = "camp:test", x = 10, y = 10, z = 0,
        resourceRadius = 2,
    },
}

local snapshot = Service.Capture(record, true)
T.equal(#snapshot.resources, 2,
    "camp snapshot captures beds and faucets in the search radius")
T.equal(snapshot.resources[1].resourceKind, "sleep_surface",
    "camp resource descriptors are deterministically ordered")
T.equal(snapshot.resources[2].resourceKind, "water_source",
    "camp snapshot retains faucet descriptors for future needs")
T.falsy(snapshot.resources[1].object,
    "camp snapshots do not retain world object references")

local waterAssignment = Service.AcquireWater(record, { abstract = true })
T.truthy(waterAssignment and waterAssignment.ok,
    "camp water acquires a captured faucet for an abstract NPC")
T.equal(waterAssignment.resourceKind, "nearby_water",
    "camp water uses the shared nearby-water activity capability")
T.equal(waterAssignment.executionMode, "ABSTRACT",
    "unmaterialized camp water uses the abstract executor")
T.truthy(PNC.IndividualNeeds == nil,
    "the camp resource test keeps need effects isolated until execution")
PNC.IndividualNeeds = {
    Commands = {
        ApplyDrink = function(target, relief)
            target.needs.thirst = target.needs.thirst - relief.thirst
        end,
    },
}
local Effects = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects.lua")
record.runtime.facilityActivity = {
    campActivity = true, abstract = true,
}
local drank, drinkComplete = Effects.Tick(record, {
    resource = waterAssignment.resource,
    resourceKey = waterAssignment.resourceKey,
}, { needEffect = "nearby_water", effectDelayMs = 0 }, 0, 1000)
T.truthy(drank and drinkComplete,
    "abstract camp water satisfies thirst from the captured faucet descriptor")
T.near(record.needs.thirst, 0.10, 0.000001,
    "abstract camp water applies proportional thirst relief")
PNC.FacilityReservations.Release(waterAssignment.reservationId, "test_cleanup")
PNC.IndividualNeeds = nil
PNC.NeedFacilityEffects = nil
record.runtime.facilityActivity = nil

local assignment = Service.AcquireSleep(record, { abstract = true })
T.truthy(assignment and assignment.ok,
    "camp sleep acquires an abstract-capable reservation")
T.equal(assignment.resourceKind, "sleep_surface",
    "camp sleep prefers a discovered bed")
T.equal(assignment.executionMode, "ABSTRACT",
    "unmaterialized camp sleep uses the abstract executor")

record.runtime.facilityActivity = {
    campActivity = true, capability = "sleep",
    facilityId = assignment.facilityId,
    resourceKey = assignment.resourceKey,
    resourceKind = assignment.resourceKind, sleepSurface = "bed",
    target = assignment.target,
}
record.orderSpec = {
    kind = "facility_activity", facilityId = assignment.facilityId,
    resourceKey = assignment.resourceKey,
    resourceKind = assignment.resourceKind, sleepSurface = "bed",
}
local rehydratedTarget = Service.ResolveActivityTarget(record)
T.truthy(rehydratedTarget and rehydratedTarget.interactionX,
    "camp sleep rehydrates its bed target from the snapshot")

record.runtime.facilityActivity.reservationId = assignment.reservationId
bedValid = false
squares[squareKey(10, 10, 0)] = newSquare(10, 10, 0, {})
local refreshed = Service.RefreshActivity(record)
T.truthy(refreshed,
    "camp sleep refreshes a stale bed reservation instead of getting stuck")
T.equal(record.runtime.facilityActivity.resourceKind, "floor_sleep",
    "stale camp bed activity falls back to floor sleep")
T.falsy(reservations[assignment.reservationId],
    "stale bed reservation is released after fallback")

local floorResource = Service.FindSleep(record, {
    abstract = true, excludeKey = assignment.resourceKey,
})
T.equal(floorResource.resourceKind, "floor_sleep",
    "a reserved bed falls back to a deterministic floor sleep slot")
T.equal(floorResource.resourceKey, "camp:test:floor:npc:camp-sleep",
    "floor fallback remains stable for the same camp and NPC")

record.orderSpec = {
    kind = "camp", campId = "camp:test", x = 10, y = 10, z = 0,
    resourceRadius = 2,
}
bedValid = true
squares[squareKey(10, 10, 0)] = newSquare(10, 10, 0, { bed })
local Routes = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes.lua")
T.truthy(Routes.Get("camp_sleep"),
    "camp sleep is exposed through the reusable away-need route registry")
local startedOptions
PNC.FacilityJobs = {
    Start = function(_, _, capability, options)
        startedOptions = options
        T.equal(capability, "sleep",
            "camp route starts through the shared sleep capability")
        return true, "started"
    end,
}
local campRoute = Routes.Get("camp_sleep")
local campAssignment = campRoute.Assign(record)
local started = campRoute.Start(record, {
    leaseId = "lease:camp-sleep", executionMode = "ABSTRACT",
}, campAssignment)
T.truthy(started, "camp route starts an abstract sleep activity")
T.truthy(startedOptions.campActivity,
    "camp sleep marks the shared facility activity as camp-owned")
T.equal(startedOptions.campRadius, 3,
    "camp sleep carries the bounded activity radius")
T.equal(startedOptions.abstract, true,
    "camp sleep preserves abstract execution mode")

local phase
local completed
PNC.Registry.Get = function() return record end
PNC.Tasking = {
    Events = { Emit = function() end },
    Commands = {
        RegisterExecutor = function() end,
        SetPhase = function(_, value) phase = value end,
        Complete = function() completed = true end,
        CancelForNPC = function() end,
    },
}
PNC.FacilityReservations.Start = function() return true end
PNC.FacilityJobDefinitions = {
    Get = function() return { needEffect = "need" } end,
}
PNC.NeedFacilityEffects = {
    Tick = function() return true, true, "rested" end,
}
PNC.TaskLeaseService = {
    SetPhase = function(_, value) phase = value end,
}
local executors = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskExecutors.lua")
local abstractTicked = executors.Abstract.Tick({
    leaseId = "lease:abstract-camp", npcId = record.id,
    reservationId = campAssignment.reservationId, capability = "sleep",
    lastEffectWorldHour = 12,
})
T.truthy(abstractTicked and completed,
    "abstract camp sleep applies its need effect and completes the lease")
T.equal(phase, "WORKING",
    "abstract camp sleep reports the standard working phase")

T.finish("pnc_camp_sleep_smoke")
