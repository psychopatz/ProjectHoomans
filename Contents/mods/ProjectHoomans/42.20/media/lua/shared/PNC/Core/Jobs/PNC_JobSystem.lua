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
    if not activity then
        return false
    end
    -- Sleep teardown is a two-phase transaction. An order change marks the
    -- activity as stopping, but the wake pump still owns the behavior tick
    -- until native release and sleep-surface cleanup are complete.
    if tostring(activity.capability or "") == "sleep"
        and activity.sleepWakePending == true
    then
        return true
    end
    if activity.stopRequested == true or activity.finishing == true then
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

local function isCampPlacementTransit(record, kind)
    local placement
    local state
    if not Const or kind ~= Const.ORDER_CAMP then return false end
    placement = record and record.runtime
        and record.runtime.campPlacement or nil
    state = placement and placement.state
        or record and record.orderSpec and record.orderSpec.placementState
    state = string.lower(tostring(state or ""))
    return state == "queued" or state == "moving" or state == "failed"
end

function JobSystem.Select(record)
    local order = record.orderSpec or {}
    local kind = tostring(order.kind or "")
    local registeredJob = JobSystem.OrderJobs[kind]
    local campTransit = isCampPlacementTransit(record, kind)
    local activity = record.runtime and record.runtime.facilityActivity or nil

    -- A camp placement owns the movement boundary. Existing facility work is
    -- allowed to finish only when it is in the explicit native sleep-wake
    -- transaction; otherwise it must not reclaim the actor between the camp
    -- coordinator's movement ticks.
    if not campTransit and JobSystem.IsFacilityActivityActive(record) then
        return "FacilityActivity"
    end
    if campTransit and activity and activity.sleepWakePending == true
        and JobSystem.IsFacilityActivityActive(record)
    then
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
