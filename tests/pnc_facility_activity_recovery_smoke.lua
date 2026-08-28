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

T.finish("pnc_facility_activity_recovery_smoke")
