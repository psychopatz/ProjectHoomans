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

return Service
