PNC = PNC or {}
PNC.JobSystem = PNC.JobSystem or {}

local JobSystem = PNC.JobSystem
local Const = PNC.Const

JobSystem.OrderJobs = JobSystem.OrderJobs or {}

-- A live facility task owns the behavior tick while its runtime state is
-- valid. Keep this O(1): it is used by behavior selection and order repair.
function JobSystem.IsFacilityActivityActive(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local leaseId
    local internal
    if not activity
        or activity.stopRequested == true
        or activity.finishing == true
    then
        return false
    end
    leaseId = tostring(activity.taskLeaseId or "")
    if leaseId == "" then return true end
    internal = PNC.FacilityJobsBehaviorInternal
    if internal and type(internal.HasLiveTaskLease) == "function" then
        return internal.HasLiveTaskLease(leaseId) == true
    end
    -- Shared/client code may not have the server lease table yet.
    return true
end

function JobSystem.RegisterOrder(kind, job)
    kind = tostring(kind or "")
    job = tostring(job or "")
    if kind == "" or job == "" then return false end
    JobSystem.OrderJobs[kind] = job
    return true
end

function JobSystem.Select(record)
    local order = record.orderSpec or {}
    local kind = tostring(order.kind or "")
    local registeredJob = JobSystem.OrderJobs[kind]

    if JobSystem.IsFacilityActivityActive(record) then
        return "FacilityActivity"
    end

    if registeredJob then return registeredJob end

    if record.tacticalClass == "hostile" then
        if record.runtime.target then
            return "EngageTarget"
        end
        return "HuntNearestPlayer"
    end

    if kind == Const.ORDER_FOLLOW then
        return "FollowOwner"
    end
    if kind == Const.ORDER_PATROL then
        return "PatrolRoute"
    end
    return "GuardAnchor"
end
