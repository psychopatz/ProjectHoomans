-- Durable facility activity installation and runtime side effects.
-- State and order payload construction are delegated to focused providers;
-- this composition provider owns record mutation and live/debug bookkeeping.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_StartState_Activity"
require "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_StartState_Order"
local Diagnostics = PNC.PerformanceScalingDiagnostics

function H.InstallActivity(context)
    context = type(context) == "table" and context or {}
    local record = context.record
    local facility = context.facility
    local options = context.options
    local capability = context.capability
    local target = context.target
    local seating = context.seating
    local liveObject = context.liveObject
    local live = context.live
    record.runtime = record.runtime or {}
    record.runtime.facilityActivity =
        H.BuildFacilityActivityState(context)
    if capability == "sleep" then
        PNC.SleepRuntime = PNC.SleepRuntime or {}
        PNC.SleepRuntime.LiveObjects = PNC.SleepRuntime.LiveObjects or {}
        PNC.SleepRuntime.LiveObjects[tostring(record.id)] = liveObject
    end
    if seating and live and liveObject and PNC.SeatingRuntime
        and PNC.SeatingRuntime.LiveObjects
    then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = liveObject
    end
    if seating and Diagnostics and Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            "seat_session_started",
            record,
            live,
            nil,
            "facility_activity_started",
            {
                "capability=" .. tostring(capability or ""),
                "targetX=" .. tostring(target.x or ""),
                "targetY=" .. tostring(target.y or ""),
                "targetZ=" .. tostring(target.z or ""),
            }
        )
    end
    if options.debugHold == true then
        record.runtime.facilityDebugWork = record.runtime.facilityActivity
    end
    PNC.OrderSystem.SetOrder(record, H.BuildFacilityActivityOrder(context))
    -- Keep the normalized executor order beside the activity lease. Passive
    -- mobile-group repair may rewrite record.orderSpec, but it must not make
    -- the live facility executor lose its target or capability.
    record.runtime.facilityActivity.activityOrder = PNC.Core.DeepCopy(
        record.orderSpec)
    return true, "facility_activity_started", {
        npcID = record.id,
        facilityId = facility.id,
        capability = capability,
        target = { x = target.x, y = target.y, z = target.z },
    }
end

return H
