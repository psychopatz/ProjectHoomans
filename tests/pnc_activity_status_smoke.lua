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

local combat = Status.Build({
    alive = true,
    activeJob = "GuardAnchor",
    runtime = { target = { kind = "zombie" } },
})
T.equal(combat.activityId, "combat",
    "combat overrides a stale generic job")

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
