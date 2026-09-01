local T = require "tests/support/test"

T.addPackagePaths()

local normalizer, jobName, handler
local move
local requestedScene
local positioned
local facing
local pathResets = 0
local worldHour = 10
PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    OrderSystem = {
        RegisterNormalizer = function(_, value) normalizer = value end,
        SetOrder = function(record, order) record.orderSpec = order end,
    },
    JobSystem = { RegisterOrder = function(_, value) jobName = value end },
    BehaviorRegistry = { Register = function(_, value) handler = value end },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        HaltMovement = function(_, _, reason) move = reason end,
        MoveRecord = function(_, _, x, y, z, _, _, reason)
            move = { x = x, y = y, z = z, reason = reason }
        end,
    },
    AnimationScenes = {
        Request = function(record, _, sceneId)
            requestedScene = sceneId
            record.runtime.animationScene = { id = sceneId }
            return true
        end,
    },
    LiveBodyControl = {
        SetAuthoritativePosition = function(_, x, y, z)
            positioned = { x = x, y = y, z = z }
        end,
    },
    PathService = {
        Reset = function(_, targetRecord)
            pathResets = pathResets + 1
            targetRecord.runtime.pathing = nil
            targetRecord.runtime.localNavigation = nil
        end,
    },
    NeedsUtils = { WorldAgeHours = function() return worldHour end },
    IndividualNeeds = {
        Modify = function(record, needType, amount)
            record.needs[needType] = math.max(0,
                math.min(1, record.needs[needType] + amount))
            return record.needs[needType]
        end,
    },
}
IsoDirections = { E = "east", S = "south" }

require "PNC/Core/Facilities/PNC_FacilityJobs_Definitions"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects"
require "PNC/Core/Facilities/PNC_FacilityJobs_Behavior"
T.equal(jobName, "FacilityActivity", "facility activity job registration")
T.equal(type(handler), "function", "facility behavior registration")

local order = normalizer({}, {
    capability = "sleep", facilityId = "barracks_a",
    componentId = "bed_a", x = 10, y = 5, z = 0,
})
local record = {
    x = 0, y = 0, z = 0, orderSpec = order,
    needs = { fatigue = 0.8 },
    runtime = {
        facilityActivity = { capability = "sleep" },
        pathing = { phase = "active" },
        localNavigation = { nativeActive = true },
    },
}
T.equal(handler(record, nil, jobName, 0), true, "travelling handler")
T.equal(record.runtime.facilityActivity.phase, "TRAVELLING", "travel phase")
T.equal(move.reason, "facility_activity", "production movement request")

record.x, record.y = 10, 5
T.equal(handler(record, {}, jobName, 0), true, "working handler")
T.equal(record.runtime.facilityActivity.phase, "STARTING", "scene start phase")
T.equal(move, "facility_working", "arrival movement hold")
T.equal(pathResets, 1, "arrival releases native path ownership")
T.equal(record.runtime.pathing, nil, "stale movement lane cleared before sleep")
T.equal(requestedScene, "facility.sleep.floor", "floor sleep is the fallback scene")
T.equal(record.activeJob, "Sleep", "sleep activity drives needs model")

worldHour = 11
T.equal(PNC.FacilityJobs.OnSceneTick(record, {},
    record.runtime.animationScene, 1000), true, "sleep scene remains active")
T.equal(record.needs.fatigue < 0.8, true, "sleep scene cures fatigue")

record.needs.fatigue = 0.1
worldHour = 12
T.equal(PNC.FacilityJobs.OnSceneTick(record, {},
    record.runtime.animationScene, 2000), false, "rested NPC completes sleep")
T.equal(record.runtime.facilityActivity.completionRequested, true,
    "sleep completion is recorded")

requestedScene, positioned = nil, nil
local bedOrder = normalizer({}, {
    capability = "sleep", facilityId = "barracks_a",
    componentId = "bed_b", x = 11.5, y = 5.5, z = 0,
    interactionX = 12, interactionY = 5.5, interactionZ = 0,
    interactionAxis = "x", sceneId = "facility.sleep.bed",
    sleepSurface = "bed",
})
local bedZombie = {
    getX = function() return 11.5 end,
    getY = function() return 5.5 end,
    getZ = function() return 0 end,
    setForwardIsoDirection = function(_, value) facing = value end,
}
local bedRecord = {
    x = 11.5, y = 5.5, z = 0, orderSpec = bedOrder,
    needs = { fatigue = 0.8 },
    runtime = { facilityActivity = { capability = "sleep" } },
}
T.equal(handler(bedRecord, bedZombie, jobName, 0), true,
    "bed sleep handler starts from approach tile")
T.equal(positioned.x, 12, "bed sleeper is moved to furniture center")
T.equal(positioned.y, 5.5, "bed sleeper center y")
T.equal(facing, "east", "bed sleeper follows furniture axis")
T.equal(requestedScene, "facility.sleep.bed", "bed XML scene selected")
T.equal(bedRecord.runtime.facilityActivity.sleepSurface, "bed",
    "runtime exposes selected sleep surface")

local seatSat
local seatSitting
local seatObject = {
    isFurnitureOccupied = function() return false end,
    setSatChair = function(_, value) seatSat = value end,
}
local seatX, seatY, seatZ = 0, 0, 0
local seatZombie = {
    getX = function() return seatX end,
    getY = function() return seatY end,
    getZ = function() return seatZ end,
    setSitOnFurnitureObject = function(_, value) seatObject.owner = value end,
    setSitOnFurnitureDirection = function(_, value) seatObject.direction = value end,
    setSittingOnFurniture = function(_, value) seatSitting = value end,
    setIsResting = function(_, value) seatObject.resting = value end,
    setBed = function(_, value) seatObject.bed = value end,
    setVariable = function(_, key, value) seatObject[key] = value end,
    clearVariable = function(_, key) seatObject[key] = nil end,
    setForwardIsoDirection = function(_, value) facing = value end,
}
PNC.SeatingRuntime.LiveObjects["npc:chair"] = seatObject
PNC.FacilityResources = {
    BuildSeatSpots = function(character, object)
        T.equal(character, seatZombie,
            "live seat refresh evaluates against the current body")
        T.equal(object, seatObject,
            "live seat refresh evaluates against the reserved furniture")
        return {
            {
                x = 10.25, y = 5.75, z = 0,
                direction = "E", side = "Front",
                approachKey = "E:Front", valid = true,
            },
            {
                x = 10.25, y = 6.75, z = 0,
                direction = "S", side = "Front",
                approachKey = "S:Front", valid = true,
            },
        }
    end,
}
local seatOrder = normalizer({}, {
    capability = "living", facilityId = "home_a", resourceKey = "seat:a",
    resourceKind = "seating_surface", seating = true,
    x = 10.25, y = 5.75, z = 0, seatDirection = "E", seatSide = "Front",
    approachKey = "E:Front", validSpot = true,
})
local seatRecord = {
    id = "npc:chair", x = 0, y = 0, z = 0, orderSpec = seatOrder,
    runtime = { facilityActivity = {
        capability = "living", seating = true, resourceKind = "seating_surface",
        resourceKey = "seat:a", resource = {}, seatDirection = "E",
        seatSide = "Front", approachKey = "E:Front", validSpot = true,
    } },
}
T.equal(handler(seatRecord, seatZombie, jobName, 0), true,
    "chair seating keeps travelling until its exact anchor is reached")
seatX, seatY, seatZ = 10.25, 5.75, 0
seatRecord.x, seatRecord.y, seatRecord.z = seatX, seatY, seatZ
T.equal(handler(seatRecord, seatZombie, jobName, 0), true,
    "chair seating starts at the exact SeatingManager anchor")
T.equal(positioned.x, 10.25, "chair seating snaps to the anchor x")
T.equal(positioned.y, 5.75, "chair seating snaps to the anchor y")
T.equal(seatSat, true, "chair is marked occupied while the NPC is seated")
T.equal(seatSitting, true, "NPC receives the furniture sitting state")
T.equal(requestedScene, "facility.living.sitFurniture",
    "chair seating selects the dedicated furniture scene")
T.equal(seatRecord.runtime.facilityActivity.phase, "STARTING",
    "chair seating enters the scene startup phase")

PNC.SeatingRuntime.LiveObjects["npc:chair-retry"] = seatObject
local retryOrder = normalizer({}, {
    capability = "living", facilityId = "home_a", resourceKey = "seat:a",
    resourceKind = "seating_surface", seating = true,
    x = 10.25, y = 5.75, z = 0, seatDirection = "E", seatSide = "Front",
    approachKey = "E:Front", validSpot = true,
})
local retryRecord = {
    id = "npc:chair-retry", x = 10.25, y = 5.75, z = 0,
    orderSpec = retryOrder,
    runtime = {
        pathing = { phase = "blocked" },
        facilityActivity = {
            capability = "living", seating = true,
            resourceKind = "seating_surface", resourceKey = "seat:a",
            resource = {}, seatDirection = "E", seatSide = "Front",
            approachKey = "E:Front", validSpot = true,
        },
    },
}
T.equal(handler(retryRecord, seatZombie, jobName, 0), true,
    "blocked chair approach is retried")
T.equal(retryRecord.orderSpec.approachKey, "S:Front",
    "blocked chair approach advances to the next valid spot")
T.equal(move.x, 10.25, "seat retry keeps the alternate approach x")
T.equal(move.y, 6.75, "seat retry moves to the alternate approach y")
T.truthy(retryRecord.runtime.facilityActivity.failedApproaches["E:Front"],
    "blocked chair approach is remembered as failed")
T.finish("pnc_facility_debug_work_smoke")

T.finish("pnc_facility_debug_work_smoke")
