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

local inventoryDrink = scenes["survival.drink.inventory"]
local worldDrink = scenes["survival.drink.world"]
for _, drink in ipairs({ inventoryDrink, worldDrink }) do
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
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior.lua")

local foodDefinition = PNC.FacilityJobDefinitions.Get("food.dine")
T.equal(foodDefinition.sceneId, "survival.eat.inventory",
    "home dining uses the eating sequence")
T.truthy(foodDefinition.completeWithScene,
    "home dining waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get(
    "survival.eat.inventory").completeWithScene,
    "follower eating waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get(
    "survival.drink.inventory").completeWithScene,
    "inventory drinking waits for its complete animation scene")
T.truthy(PNC.FacilityJobDefinitions.Get(
    "survival.drink.world").completeWithScene,
    "world drinking waits for its complete animation scene")
T.equal(PNC.FacilityJobDefinitions.Get(
    "survival.drink.inventory").primitiveNeed, "thirst",
    "inventory drinking consumes through the hydration supply path")
T.equal(PNC.FacilityJobDefinitions.Get(
    "survival.drink.world").needEffect, "world_water",
    "world drinking commits against the live source")

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

-- A failed delayed effect must stop the scene without advertising completion;
-- otherwise task reevaluation can keep the failed lease alive.
local originalNeedEffectTick = PNC.NeedFacilityEffects.Tick
PNC.NeedFacilityEffects.Tick = function()
    return false, false, "WATER_CONTAINER_FULL"
end
record.runtime.facilityActivity = {
    capability = "survival.fill.water",
    sceneId = "survival.fill.water",
    reservationId = "", taskLeaseId = "lease:failed-effect",
    resourceKind = "water_refill",
}
local failedSceneResult = PNC.FacilityJobs.OnSceneTick(record, {}, {
    id = "survival.fill.water",
}, 1500)
T.falsy(failedSceneResult, "failed refill effect stops the scene")
T.equal(record.runtime.facilityActivity.failedReason,
    "WATER_CONTAINER_FULL",
    "failed refill effect preserves its transaction reason")
T.falsy(record.runtime.facilityActivity.completionRequested,
    "failed refill effect is not mislabeled as completed")
PNC.NeedFacilityEffects.Tick = originalNeedEffectTick

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
    kind = "facility_activity", capability = "survival.drink.world",
    x = 10.5, y = 10.5, z = 0, sceneId = "",
}
record.x, record.y, record.z = 1, 1, 0
record.runtime.facilityActivity = {
    capability = "survival.drink.world", sceneId = "survival.drink.world",
    reservationId = "", taskLeaseId = "", resourceKind = "world_water",
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

-- A traversal timeout can leave the lane active while the passage repair is
-- handed back to the engine. The water activity must still rotate its
-- approach candidate on the next facility tick.
record.orderSpec.x, record.orderSpec.y = 10.5, 10.5
record.runtime.facilityActivity.approachIndex = 1
record.runtime.facilityActivity.failedApproaches = {}
record.runtime.facilityActivity.worldWaterApproachRetry = true
record.runtime.pathing = { phase = "active", ownerMode = "engine_path_waiting" }
T.truthy(PNC.FacilityJobs.Tick(record, {}),
    "water behavior handles a path timeout left in engine waiting state")
T.equal(record.orderSpec.x, 11.5,
    "water path timeout rotates to the next approach square")
T.falsy(record.runtime.facilityActivity.worldWaterApproachRetry,
    "water path retry marker is consumed once")

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

-- Do not play a refill scene when the selected bottle is already full by the
-- time the NPC reaches the source. This is the last-mile guard for a stale
-- assignment made while the bottle was still empty.
PNC.Core.Now = function() return 1000 end
local originalInventory = PNC.Inventory
local refillSceneRequests = 0
PNC.Inventory = {
    EnsureRecordInventory = function()
        return { items = {
            ["full-bottle"] = { id = "full-bottle", type = "Base.WaterBottle" },
        } }
    end,
    DescribeLiquidContainer = function()
        return { amount = 1, capacity = 1, freeCapacity = 0,
            canFill = false, canDrink = true }
    end,
}
PNC.AnimationScenes.Request = function()
    refillSceneRequests = refillSceneRequests + 1
    return true
end
local staleRefill = {
    id = "npc:stale-refill",
    orderSpec = {
        kind = "facility_activity", capability = "survival.fill.water",
        x = 11.5, y = 10.5, z = 0, sceneId = "survival.fill.water",
    },
    runtime = { facilityActivity = {
        capability = "survival.fill.water",
        sceneId = "survival.fill.water",
        resourceKind = "water_refill",
        activityItemID = "full-bottle",
        taskLeaseId = "",
        previousOrder = { kind = "follow" },
    } },
    x = 11.5, y = 10.5, z = 0,
}
T.truthy(PNC.FacilityJobs.Tick(staleRefill, live),
    "stale refill assignment is handled before scene start")
T.equal(refillSceneRequests, 0,
    "full bottle does not start another refill animation")
T.equal(staleRefill.runtime.waterRefillRetryAt, 6000,
    "last-mile full-bottle rejection installs a bounded retry cooldown")
T.equal(staleRefill.runtime.facilityActivity, nil,
    "last-mile full-bottle rejection cleans up the activity")
PNC.Inventory = originalInventory

-- Failed one-shot scenes must not leave a WORKING task lease stranded after
-- the activity has already been cleaned up.
local originalTasking = PNC.Tasking
local originalTaskLeaseService = PNC.TaskLeaseService
local leasePhase
local cancelledLease
PNC.TaskLeaseService = {
    Get = function() return { phase = "WORKING" } end,
    SetPhase = function(_, phase) leasePhase = phase; return true end,
}
PNC.Tasking = {
    Commands = {
        CancelForNPC = function(_, reason)
            cancelledLease = reason
            return true
        end,
    },
}
local failedRefill = {
    id = "npc:failed-refill",
    orderSpec = { kind = "facility_activity" },
    runtime = { facilityActivity = {
        capability = "survival.fill.water",
        resourceKind = "water_refill",
        taskLeaseId = "lease:failed-refill",
        failedReason = "WATER_CONTAINER_FULL",
        previousOrder = { kind = "follow" },
    } },
}
PNC.FacilityJobs.OnSceneStopped(failedRefill, nil, {
    id = "survival.fill.water",
}, "callback_complete")
T.equal(leasePhase, "WAITING",
    "failed refill moves a working lease to a cancellable phase")
T.equal(cancelledLease, "WATER_CONTAINER_FULL",
    "failed refill cancellation preserves the transaction reason")
PNC.Tasking = originalTasking
PNC.TaskLeaseService = originalTaskLeaseService

PNC.AnimationScenes.Request = function()
    return false, "scene_missing"
end
record.runtime.animationScene = nil
record.runtime.facilityActivity.phase = nil
T.truthy(PNC.FacilityJobs.Tick(record, live),
    "facility behavior did not handle a failed scene request")
T.equal(record.runtime.facilityActivity.phase, "INTERRUPTED",
    "failed scene request left the activity in STARTING")
T.equal(record.runtime.facilityActivity.interruptReason, "scene_missing",
    "failed scene request did not expose its reason")

-- If playback ends before the delayed food effect runs, the activity must be
-- finished and backed off. Leaving it in INTERRUPTED makes the behavior tick
-- request the same eating scene forever without consuming food.
PNC.Core.Now = function() return 1000 end
local interruptedFood = {
    id = "npc:food-interrupted",
    orderSpec = { kind = "facility_activity" },
    runtime = {
        facilityActivity = {
            capability = "survival.eat.inventory",
            resourceKind = "personal_food",
            reservationId = "", taskLeaseId = "",
            previousOrder = { kind = "follow" },
        },
    },
}
PNC.FacilityJobs.OnSceneStopped(interruptedFood, nil, {
    id = "survival.eat.inventory",
}, "completed")
T.falsy(interruptedFood.runtime.facilityActivity,
    "unfinished food scene does not leave an immortal activity behind")
T.equal(interruptedFood.runtime.personalFoodRetryAt, 6000,
    "unfinished food scene installs a bounded retry cooldown")

local interruptedRefill = {
    id = "npc:refill-interrupted",
    orderSpec = { kind = "facility_activity" },
    runtime = {
        facilityActivity = {
            capability = "survival.fill.water",
            resourceKind = "water_refill",
            reservationId = "", taskLeaseId = "",
            previousOrder = { kind = "follow" },
        },
    },
}
PNC.FacilityJobs.OnSceneStopped(interruptedRefill, nil, {
    id = "survival.fill.water",
}, "completed")
T.falsy(interruptedRefill.runtime.facilityActivity,
    "unfinished refill scene does not leave an immortal activity behind")
T.equal(interruptedRefill.runtime.waterRefillRetryAt, 6000,
    "unfinished refill scene installs a bounded retry cooldown")

T.finish("pnc_survival_animation_sequences_smoke")
