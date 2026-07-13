PNC = PNC or {}
PNC.JobSystem = PNC.JobSystem or {}

local JobSystem = PNC.JobSystem
local Const = PNC.Const

JobSystem.OrderJobs = JobSystem.OrderJobs or {}

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

    if registeredJob then return registeredJob end

    if record.faction == "hostile" then
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
