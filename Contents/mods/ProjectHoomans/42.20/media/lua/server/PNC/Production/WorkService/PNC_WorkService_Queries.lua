if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local terminal = Internal.terminal
local copy = Internal.copy
local workerAvailable = Internal.workerAvailable

local function assignable(order)
    return order and not order.workerId
        and (order.status == Status.QUEUED
            or order.status == Status.WAITING_FOR_WORKER)
end

function Service.Queries.Get(id) return copy(Repository.Get(id)) end
function Service.Queries.CanAssign(orderId, workerId)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or terminal(order) or order.workerId
        or order.status == Status.PAUSED or order.status == Status.CANCELLING
    then return false, "WORK_ORDER_UNAVAILABLE" end
    local available, reason = workerAvailable(worker, order)
    if not available then
        return false, reason or "NO_QUALIFIED_WORKER"
    end
    return true
end
function Service.Queries.List(colonyId)
    local output = {}
    Repository.Load()
    for _, order in pairs(Repository.State.byId) do
        if not colonyId or order.colonyId == tostring(colonyId) then
            output[#output + 1] = copy(order)
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then return left.priority > right.priority end
        return left.createdAt < right.createdAt
    end)
    return output
end

-- Task candidate collection should not materialize and sort the complete
-- durable history for every NPC decision. Return only the best assignable
-- orders for this worker; the task arbiter performs the final global sort.
function Service.Queries.ListAssignableForWorker(workerId, limit)
    local output = {}
    limit = math.max(1, math.floor(tonumber(limit) or 64))
    Repository.Load()
    for _, order in pairs(Repository.State.byId) do
        if assignable(order) and Service.Queries.CanAssign(order.id, workerId) then
            output[#output + 1] = order
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then return left.priority > right.priority end
        return left.createdAt < right.createdAt
    end)
    while #output > limit do output[#output] = nil end
    return output
end

-- Read-only assignment diagnostics for the task-brain UI. This deliberately
-- reports the durable queue separately from worker eligibility: a repository
-- can contain many orders without having any order that this worker may claim.
function Service.Queries.BuildAssignmentDiagnostics(workerId)
    local output = {
        workerId = tostring(workerId or ""),
        totalOrders = 0,
        statusCounts = {},
        assignableOrders = 0,
        eligibleOrders = 0,
        recoveryQuarantined = 0,
        rejectionCounts = {},
        eligibleOperations = {},
        samples = {},
    }
    local function increment(bucket, key)
        key = tostring(key or "UNKNOWN")
        bucket[key] = (tonumber(bucket[key]) or 0) + 1
    end
    local function sample(order, reason)
        if #output.samples >= 8 then return end
        output.samples[#output.samples + 1] = {
            orderId = order and order.id,
            operation = order and order.operation,
            status = order and order.status,
            reason = reason,
        }
    end
    Repository.Load()
    for _, order in pairs(Repository.State.byId) do
        output.totalOrders = output.totalOrders + 1
        increment(output.statusCounts, order and order.status)
        if assignable(order) then
            output.assignableOrders = output.assignableOrders + 1
            if order.recoveryQuarantined == true then
                output.recoveryQuarantined = output.recoveryQuarantined + 1
                increment(output.rejectionCounts,
                    "TASK_RECOVERY_QUARANTINED")
                sample(order, "TASK_RECOVERY_QUARANTINED")
            else
                local available, reason = Service.Queries.CanAssign(
                    order.id, workerId)
                if available then
                    output.eligibleOrders = output.eligibleOrders + 1
                    increment(output.eligibleOperations, order.operation)
                else
                    reason = reason or "NO_QUALIFIED_WORKER"
                    increment(output.rejectionCounts, reason)
                    sample(order, reason)
                end
            end
        end
    end
    table.sort(output.samples, function(left, right)
        local leftOperation = tostring(left.operation or "")
        local rightOperation = tostring(right.operation or "")
        if leftOperation ~= rightOperation then
            return leftOperation < rightOperation
        end
        local leftStatus = tostring(left.status or "")
        local rightStatus = tostring(right.status or "")
        if leftStatus ~= rightStatus then return leftStatus < rightStatus end
        return tostring(left.orderId or "") < tostring(right.orderId or "")
    end)
    return output
end

return Service
