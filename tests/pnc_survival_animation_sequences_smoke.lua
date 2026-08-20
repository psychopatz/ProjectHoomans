local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local scenes = {}
PNC = {
    AnimationScenes = {
        Register = function(id, definition)
            scenes[id] = definition
            return true, definition
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationSceneDefinitions.lua")

local eat = scenes["survival.eat.inventory"]
T.equal(#eat.steps, 5, "eating scene has five ordered steps")
T.equal(eat.steps[1].bump, "Eat", "eating starts with Eat")
T.equal(eat.steps[2].bump, "Eat", "eating repeats Eat twice")
T.equal(eat.steps[3].bump, "Eat", "eating repeats Eat three times")
T.equal(eat.steps[4].bump, "WipeBrow", "eating then wipes brow")
T.equal(eat.steps[5].bump, "WipeHead", "eating finishes by wiping head")

local spigot = scenes["facility.water.drink"]
local nearby = scenes["facility.water.drink.nearby"]
for _, drink in ipairs({ spigot, nearby }) do
    T.equal(#drink.steps, 3, "drinking scene has three ordered steps")
    T.equal(drink.steps[1].bump, "Drink", "drinking starts with Drink")
    T.equal(drink.steps[2].bump, "WipeBrow", "drinking then wipes brow")
    T.equal(drink.steps[3].bump, "WipeHead", "drinking finishes by wiping head")
end

PNC.OrderSystem = {
    RegisterNormalizer = function() end,
    SetOrder = function() end,
}
PNC.JobSystem = { RegisterOrder = function() end }
PNC.BehaviorRegistry = { Register = function() end }
PNC.Core = { Distance = function() return 0 end }
PNC.NeedsUtils = { WorldAgeHours = function() return 1 end }
PNC.NeedFacilityEffects = {
    Tick = function() return true, true, "NEED_COMPLETE" end,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/PNC_FacilityJobs_Definitions.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/PNC_FacilityJobs_Behavior.lua")

local foodDefinition = PNC.FacilityJobDefinitions.Get("food.dine")
T.equal(foodDefinition.sceneId, "survival.eat.inventory",
    "home dining uses the eating sequence")
T.truthy(foodDefinition.completeWithScene,
    "home dining waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get(
    "survival.eat.inventory").completeWithScene,
    "follower eating waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get("water.drink").completeWithScene,
    "spigot drinking waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get("water.nearby").completeWithScene,
    "nearby drinking waits for its complete animation scene")

local record = {
    id = "npc:sequence",
    runtime = { facilityActivity = {
        capability = "survival.eat.inventory",
        sceneId = "survival.eat.inventory",
        reservationId = "",
        taskLeaseId = "lease:eat",
    } },
}
local keepPlaying = PNC.FacilityJobs.OnSceneTick(record, {}, {
    id = "survival.eat.inventory",
}, 1000)
T.truthy(keepPlaying,
    "completed food effect keeps the visual sequence playing")
T.truthy(record.runtime.facilityActivity.completionRequested,
    "food task records completion while wipe steps continue")

record.runtime.facilityActivity = {
    capability = "sleep", sceneId = "facility.sleep.floor",
    reservationId = "", taskLeaseId = "",
}
T.falsy(PNC.FacilityJobs.OnSceneTick(record, {}, {
    id = "facility.sleep.floor",
}, 2000), "non-sequenced needs retain immediate completion")

local movedTo
PNC.Core.Distance = function(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end
PNC.PathService = {
    Reset = function() end,
    Commands = {
        Reset = function(pathRecord)
            pathRecord.runtime.pathing = nil
        end,
    },
}
PNC.BehaviorCommon = {
    ClearCombatTarget = function() end,
    MoveRecord = function(_, _, x, y, z)
        movedTo = { x = x, y = y, z = z }
    end,
}
record.orderSpec = {
    kind = "facility_activity", capability = "water.nearby",
    x = 10.5, y = 10.5, z = 0, sceneId = "",
}
record.x, record.y, record.z = 1, 1, 0
record.runtime.facilityActivity = {
    capability = "water.nearby", sceneId = "facility.water.drink.nearby",
    reservationId = "", taskLeaseId = "", resourceKind = "nearby_water",
    resource = {}, approachIndex = 1, failedApproaches = {},
    approachCandidates = {
        { x = 10.5, y = 10.5, z = 0, approachKey = "10:10:0" },
        { x = 11.5, y = 10.5, z = 0, approachKey = "11:10:0",
            interactionFacing = "W" },
    },
}
record.runtime.pathing = { phase = "blocked", ownerMode = "blocked" }
T.truthy(PNC.FacilityJobs.Tick(record, {}),
    "blocked water travel remains owned by the facility behavior")
T.equal(record.orderSpec.x, 11.5,
    "blocked sink path rotates to the next approach square")
T.equal(record.orderSpec.interactionFacing, "W",
    "retry keeps the correct sink-facing direction")
T.equal(movedTo.x, 11.5, "the replacement trajectory is issued immediately")

local requestedOptions, faced
PNC.BehaviorCommon.HaltMovement = function() end
PNC.AnimationScenes.Request = function(_, _, _, options)
    requestedOptions = options
    return true
end
IsoDirections = { W = "west" }
local live = {
    getX = function() return 11.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    setForwardIsoDirection = function(_, direction) faced = direction end,
}
record.x, record.y, record.z = 11.5, 10.5, 0
record.runtime.pathing = nil
record.runtime.facilityActivity.facingApplied = nil
record.runtime.facilityActivity.arrivalSettled = nil
record.orderSpec.interactionFacing = "W"
T.truthy(PNC.FacilityJobs.Tick(record, live),
    "water behavior starts after reaching the adjacent square")
T.equal(requestedOptions.repeatMode, "once",
    "drink sequences cannot be overridden into an endless loop")
T.equal(faced, "west", "the NPC faces the sink from the adjacent square")

T.finish("pnc_survival_animation_sequences_smoke")
