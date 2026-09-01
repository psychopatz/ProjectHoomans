local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
local released, restored
PNC = {
    Core = { Distance = function() return 0 end },
    FacilityJobDefinitions = {
        Get = function() return { sceneId = "facility.test" } end,
    },
    FacilityReservations = {
        Release = function(id) released = id; return true end,
    },
    TaskLeaseService = {
        Get = function() return nil end,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
    },
    OrderSystem = {
        RegisterNormalizer = function() end,
        SetOrder = function(_, order) restored = order end,
    },
    JobSystem = { RegisterOrder = function() end },
    BehaviorRegistry = { Register = function() end },
    AnimationScenes = {
        Stop = function() error("scene stop failed") end,
    },
}

local Jobs = T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/PNC_FacilityJobs_Behavior.lua")
local record = {
    id = "npc:orphan",
    runtime = {
        animationScene = { id = "facility.test" },
        facilityActivity = {
            reservationId = "reservation:orphan",
            taskLeaseId = "task_lease:missing",
            previousOrder = { kind = "colony_home" },
        },
    },
}

local ok, reason = Jobs.Stop(record, "orphan_recovery")
T.truthy(ok, "activity stop succeeds even when scene interruption errors")
T.equal(reason, "facility_activity_stopped", "stop reports cleanup")
T.equal(record.runtime.facilityActivity, nil,
    "orphan activity is removed")
T.equal(released, "reservation:orphan",
    "orphan reservation is released")
T.equal(restored.kind, "colony_home", "previous order is restored")

local abortRecord = {
    id = "npc:order_change",
    orderSpec = { kind = "facility_activity" },
    runtime = {
        animationScene = { id = "facility.test" },
        facilityActivity = {
            reservationId = "reservation:order_change",
            taskLeaseId = "task_lease:missing",
            previousOrder = { kind = "follow" },
        },
    },
}
released, restored = nil, nil
local aborted, abortReason = Jobs.AbortForOrderChange(
    abortRecord, nil, "order_changed")
T.truthy(aborted, "order change abort succeeds even when scene stop errors")
T.equal(abortReason, "facility_activity_aborted",
    "order change reports an abort")
T.equal(abortRecord.runtime.facilityActivity, nil,
    "order change clears the facility activity")
T.equal(abortRecord.runtime.animationScene, nil,
    "order change clears the blocking scene")
T.equal(abortRecord.orderSpec.kind, "facility_activity",
    "order change abort does not restore the previous order")
T.equal(restored, nil, "order change abort does not call SetOrder")
T.equal(released, "reservation:order_change",
    "order change releases an orphaned reservation")

T.finish("pnc_facility_activity_recovery_smoke")
