local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua",
    package.path,
}, ";")

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
equal(jobName, "FacilityActivity", "facility activity job registration")
equal(type(handler), "function", "facility behavior registration")

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
equal(handler(record, nil, jobName, 0), true, "travelling handler")
equal(record.runtime.facilityActivity.phase, "TRAVELLING", "travel phase")
equal(move.reason, "facility_activity", "production movement request")

record.x, record.y = 10, 5
equal(handler(record, {}, jobName, 0), true, "working handler")
equal(record.runtime.facilityActivity.phase, "STARTING", "scene start phase")
equal(move, "facility_working", "arrival movement hold")
equal(pathResets, 1, "arrival releases native path ownership")
equal(record.runtime.pathing, nil, "stale movement lane cleared before sleep")
equal(requestedScene, "facility.sleep.floor", "floor sleep is the fallback scene")
equal(record.activeJob, "Sleep", "sleep activity drives needs model")

worldHour = 11
equal(PNC.FacilityJobs.OnSceneTick(record, {},
    record.runtime.animationScene, 1000), true, "sleep scene remains active")
equal(record.needs.fatigue < 0.8, true, "sleep scene cures fatigue")

record.needs.fatigue = 0.1
worldHour = 12
equal(PNC.FacilityJobs.OnSceneTick(record, {},
    record.runtime.animationScene, 2000), false, "rested NPC completes sleep")
equal(record.runtime.facilityActivity.completionRequested, true,
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
equal(handler(bedRecord, bedZombie, jobName, 0), true,
    "bed sleep handler starts from approach tile")
equal(positioned.x, 12, "bed sleeper is moved to furniture center")
equal(positioned.y, 5.5, "bed sleeper center y")
equal(facing, "east", "bed sleeper follows furniture axis")
equal(requestedScene, "facility.sleep.bed", "bed XML scene selected")
equal(bedRecord.runtime.facilityActivity.sleepSurface, "bed",
    "runtime exposes selected sleep surface")

print("pnc_facility_debug_work_smoke: ok")
