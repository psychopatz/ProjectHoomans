local T = require "tests/support/test"

local now = 1000
PNC = {
    Core = { Now = function() return now end },
    FacilityJobDefinitions = { Get = function(capability)
        if capability == "sleep" then
            return {
                activityLabelKey = "UI_PNC_Activity_Sleeping",
                activityText = "Sleeping",
            }
        end
        if capability == "survival.eat.inventory" then
            return {
                activityLabelKey = "UI_PNC_Activity_Eating",
                activityText = "Eating",
            }
        end
        if capability == "water.drink" then
            return {
                activityLabelKey = "UI_PNC_Activity_Drinking",
                activityText = "Drinking",
            }
        end
    end },
    SettlementRepository = { GetFacility = function(id)
        return id == "barracks:1"
            and { definitionId = "barracks" } or nil
    end },
    WorkService = { BuildActionInformation = function(record)
        if record.runtime and record.runtime.workOrderId then
            return { kind = "work_order", operation = "CONSTRUCT" }
        end
        if record.orderSpec and record.orderSpec.kind == "colony_home" then
            return { kind = "at_home" }
        end
    end },
}

local Status = T.load("ProjectHoomans", "shared",
    "PNC/Core/Activities/PNC_ActivityStatus.lua")

local sleep = Status.Build({
    alive = true,
    activeJob = "Sleep",
    runtime = { facilityActivity = {
        capability = "sleep",
        facilityId = "barracks:1",
        phase = "SLEEPING",
    } },
})
T.equal(sleep.kind, "activity", "facility emits canonical activity payload")
T.equal(sleep.fallback, "Sleeping", "sleep has a displayable status")
T.equal(sleep.facilityDefinitionId, "barracks",
    "facility context survives the activity pipeline")
T.equal(sleep.providerId, "facility_activity",
    "specific facility provider owns sleep status")

local legacyFacilityActivity = Status.Build({
    alive = true,
    activeJob = "FacilityActivity",
    orderSpec = {
        kind = "facility_activity", capability = "sleep",
        facilityId = "barracks:1", phase = "SLEEPING",
    },
    runtime = {},
})
T.equal(legacyFacilityActivity.fallback, "Sleeping",
    "legacy FacilityActivity records keep a specific activity label")
T.equal(legacyFacilityActivity.activityId, "facility:sleep",
    "legacy FacilityActivity records keep their capability identity")

local eating = Status.Build({
    alive = true,
    runtime = {
        facilityActivity = {
            capability = "survival.eat.inventory",
            phase = "STARTING",
        },
        supply = {
            byKind = {
                FOOD = { lastUsedItem = { fullType = "Base.Apple" } },
            },
        },
    },
})
T.equal(eating.activityItemFullType, "Base.Apple",
    "food activity exposes the selected item type")
T.equal(eating.activityItemLabelKey, "UI_PNC_Action_FoodTarget",
    "food activity exposes its item fallback")

local eatingCandidate = Status.Build({
    alive = true,
    runtime = {
        facilityActivity = {
            capability = "food.dine", phase = "STARTING",
            activityItemFullType = "Base.Bread",
        },
    },
})
T.equal(eatingCandidate.activityItemFullType, "Base.Bread",
    "food activity keeps the selected item before consumption starts")

local drinking = Status.Build({
    alive = true,
    runtime = { facilityActivity = {
        capability = "water.drink", phase = "STARTING",
    } },
})
T.equal(drinking.activityItemLabelKey, "UI_PNC_Action_WaterTarget",
    "drinking activity exposes its water fallback")

local combat = Status.Build({
    alive = true,
    activeJob = "GuardAnchor",
    runtime = { target = { kind = "zombie" } },
})
T.equal(combat.activityId, "combat",
    "combat overrides a stale generic job")

PNC.BehaviorTreatment = {
    BuildSnapshot = function(record)
        return record.runtime and record.runtime.selfTreatment
    end,
}
local bandaging = Status.Build({
    alive = true,
    runtime = {
        selfTreatment = { phase = "bandaging", partId = "Hand_L" },
        inCombatUntil = now + 2500,
    },
})
T.equal(bandaging.kind, "treatment",
    "active bandaging owns activity presentation")
T.equal(bandaging.phase, "bandaging",
    "stale combat lease cannot hide bandaging phase")

local work = Status.Build({
    alive = true,
    runtime = { workOrderId = "work:1" },
})
T.equal(work.kind, "work_order",
    "existing work-order payload remains in the generalized pipeline")

local generic = Status.Build({
    alive = true,
    activeJob = "GuardAnchor",
    activeBehavior = "GuardAnchor",
    runtime = {},
})
T.equal(generic.fallback, "Guard Anchor",
    "unknown future jobs receive a readable fallback automatically")

Status.Register("mod_activity", 95, function(record)
    if record.runtime and record.runtime.modActivity then
        return {
            kind = "activity",
            activityId = "mod:custom",
            fallback = "Custom Activity",
        }
    end
end)
local custom = Status.Build({
    alive = true,
    activeJob = "GuardAnchor",
    runtime = { modActivity = true },
})
T.equal(custom.providerId, "mod_activity",
    "external systems can register higher-priority activity providers")
T.truthy(Status.Unregister("mod_activity"),
    "activity providers can be removed without touching nameplates")

T.finish("pnc_activity_status_smoke")
