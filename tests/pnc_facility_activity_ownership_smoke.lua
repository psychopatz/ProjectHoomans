local T = require "tests/support/test"

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_PATROL = "patrol",
    },
}

local liveLeases = { ["lease:active"] = true }
PNC.FacilityJobsBehaviorInternal = {
    HasLiveTaskLease = function(leaseId)
        return liveLeases[leaseId] == true
    end,
}

T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_JobSystem.lua")
local JobSystem = PNC.JobSystem
JobSystem.RegisterOrder("follow", "FollowOwner")

local record = {
    orderSpec = { kind = "follow" },
    runtime = {
        facilityActivity = {
            capability = "survival.eat.inventory",
            taskLeaseId = "lease:active",
        },
    },
}

T.truthy(JobSystem.IsFacilityActivityActive(record),
    "live facility activity owns the record")
T.equal(JobSystem.Select(record), "FacilityActivity",
    "facility activity wins over follow")

liveLeases["lease:active"] = nil
T.falsy(JobSystem.IsFacilityActivityActive(record),
    "released lease is no longer active")
T.equal(JobSystem.Select(record), "FollowOwner",
    "follow resumes after the facility lease is gone")

record.runtime.facilityActivity = {
    capability = "survival.eat.inventory",
}
T.truthy(JobSystem.IsFacilityActivityActive(record),
    "manual activity without a task lease remains owned")
T.equal(JobSystem.Select(record), "FacilityActivity",
    "manual activity also wins over follow")

record.runtime.facilityActivity.stopRequested = true
T.falsy(JobSystem.IsFacilityActivityActive(record),
    "stopping activity releases behavior ownership")
T.equal(JobSystem.Select(record), "FollowOwner",
    "follow resumes after activity stop is requested")

T.finish("pnc_facility_activity_ownership_smoke")
