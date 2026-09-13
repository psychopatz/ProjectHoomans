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

local facilityApproach = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Approach.lua"
)
local facilitySeating = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Seating.lua"
)
local facilityTick = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Tick.lua"
)
T.falsy(string.find(facilityApproach, "runtime.target = {", 1, true),
    "facility approach must not publish a combat target")
T.falsy(string.find(facilitySeating, "runtime.target = {", 1, true),
    "facility seating must not publish a combat target")
T.falsy(string.find(facilityTick, "runtime.target = {", 1, true),
    "facility ticking must not publish a combat target")

record.runtime.facilityActivity.stopRequested = true
T.falsy(JobSystem.IsFacilityActivityActive(record),
    "stopping activity releases behavior ownership")
T.equal(JobSystem.Select(record), "FollowOwner",
    "follow resumes after activity stop is requested")

-- A stopped sleep activity is different: its native wake transaction must
-- retain ownership until the bed/resting surface is released.
record.runtime.facilityActivity = {
    capability = "sleep",
    stopRequested = true,
    sleepWakePending = true,
}
T.truthy(JobSystem.IsFacilityActivityActive(record),
    "pending sleep wake retains behavior ownership")
T.equal(JobSystem.Select(record), "FacilityActivity",
    "facility wake transaction wins over follow")

T.finish("pnc_facility_activity_ownership_smoke")
