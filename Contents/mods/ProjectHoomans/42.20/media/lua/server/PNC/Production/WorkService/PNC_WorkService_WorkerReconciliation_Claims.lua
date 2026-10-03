-- WorkService persisted worker claim reconciliation provider.
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
local now = Internal.now
local terminal = Internal.terminal
local markAssignmentDirty = Internal.markAssignmentDirty
local releaseClaim = Internal.releaseClaim

local function releaseAssignment(order, reason)
    if Service.Commands and Service.Commands.ReleaseAssignment then
        local released, releaseReason = Service.Commands.ReleaseAssignment(
            order and order.workerId, reason)
        if released == true then return true end
        if releaseReason ~= "WORK_ORDER_UNAVAILABLE" then
            return false, releaseReason
        end
    end
    return releaseClaim(order, reason, false, true)
end

local function rebuildWorkerClaims()
    local orderIds = {}
    local workers = {}
    local stations = {}
    local repaired = 0
    for id, order in pairs(Repository.State.byId or {}) do
        if not terminal(order) and order.workerId then
            orderIds[#orderIds + 1] = id
        end
    end
    table.sort(orderIds, function(left, right)
        local a, b = Repository.State.byId[left], Repository.State.byId[right]
        local ap, bp = tonumber(a.priority) or 0, tonumber(b.priority) or 0
        if ap ~= bp then return ap > bp end
        local ac, bc = tonumber(a.createdAt) or 0, tonumber(b.createdAt) or 0
        if ac ~= bc then return ac < bc end
        return tostring(left) < tostring(right)
    end)
    for _, id in ipairs(orderIds) do
        local order = Repository.State.byId[id]
        local workerId = tostring(order.workerId or "")
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(workerId) or nil
        local valid = worker and worker.alive ~= false
            and worker.runtime
            and tostring(worker.runtime.workOrderId or "")
                == tostring(order.id or "")
        if valid and (workers[workerId]
            or order.stationId and stations[tostring(order.stationId)])
        then
            valid = false
        end
        if valid then
            workers[workerId] = order.id
            if order.stationId then
                stations[tostring(order.stationId)] = order.id
            end
        else
            local released, releaseReason = releaseAssignment(order,
                "stale_worker_claim")
            if released == false then
                order.blockedReason = releaseReason
                Repository.MarkDirty()
            else
                if order.status ~= Status.PAUSED
                    and order.status ~= Status.CANCELLING
                then
                    order.status = Status.WAITING_FOR_WORKER
                    order.blockedReason = nil
                end
                order.updatedAt, order.revision = now(), order.revision + 1
                Repository.MarkDirty()
                markAssignmentDirty(order, "STALE_WORKER_CLAIM_RECOVERED")
            end
            repaired = repaired + 1
        end
    end
    Service.ClaimsByWorker, Service.ClaimsByStation = workers, stations
    return repaired
end

Internal.RebuildWorkerClaims = rebuildWorkerClaims

return Service
