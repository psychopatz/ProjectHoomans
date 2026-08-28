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
    if not workerAvailable(worker, order) then
        return false, "NO_QUALIFIED_WORKER"
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

return Service
