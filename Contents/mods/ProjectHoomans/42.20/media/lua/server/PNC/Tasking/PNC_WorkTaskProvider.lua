if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = {}
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions.STATUS

local function assignable(order)
    return order and not order.workerId
        and (order.status == Status.QUEUED
            or order.status == Status.WAITING_FOR_WORKER)
end

function Provider.GetCandidates(npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId)
    if not record or record.alive == false or not Work then return {} end
    local output = {}
    local indexed = Work.Queries.ListAssignableForWorker ~= nil
    local orders = indexed
        and Work.Queries.ListAssignableForWorker(npcId, 64)
        or Work.Queries.List()
    for _, order in ipairs(orders) do
        local eligible = assignable(order)
            and (indexed or not Work.Queries.CanAssign
                or Work.Queries.CanAssign(order.id, npcId))
        if eligible == true then
            local priority = tonumber(order.priority) or 0
            output[#output + 1] = {
                taskId = order.id, npcId = tostring(npcId),
                kind = order.operation, sourceDomain = "work",
                sourceRef = order.id,
                precedence = priority >= 90 and "FORCED_ORDER"
                    or priority >= 50 and "HIGH_WORK" or "NORMAL_WORK",
                urgency = math.max(0, math.min(1, (priority + 100) / 200)),
                capability = PNC.WorkDefinitions.CAPABILITY_BY_OPERATION[
                    order.operation] or "work.construction",
                interruptPolicy = "NORMAL", revision = order.revision,
                createdAt = order.createdAt,
            }
        end
    end
    return output
end

function Provider.Validate(intent)
    local order = Work and Work.Queries.Get(intent.sourceRef)
    return assignable(order) and Work.Queries.CanAssign(
        intent.sourceRef, intent.npcId) == true
end

function Provider.Assign(intent)
    local assigned, reason = Work.Commands.Assign(intent.sourceRef, intent.npcId)
    if assigned ~= true then return nil, reason end
    local order = Work.Queries.Get(intent.sourceRef)
    return {
        facilityId = order.facilityId, componentId = order.stationId,
        reservationId = order.facilityReservationId,
        executionMode = order.executionMode,
    }
end

function Provider.Start() return true end

function Provider.RollbackAssignment(intent, _, reason)
    local order = Work and Work.Queries.Get(intent.sourceRef)
    if not order or tostring(order.workerId or "") ~= intent.npcId then
        return true
    end
    return Work.Commands.ReleaseWorker(intent.npcId,
        reason or "assignment_rolled_back")
end

function Provider.CanContinue(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    return order ~= nil and tostring(order.workerId or "") == lease.npcId
        and order.status ~= Status.CANCELLED
        and order.status ~= Status.COMPLETED
        and order.status ~= Status.FAILED
end

function Provider.Cancel(lease, reason)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order or tostring(order.workerId or "") ~= lease.npcId then
        lease.reservationId = nil
        return true
    end
    local ok, result = Work.Commands.ReleaseWorker(lease.npcId,
        reason or "task_lease_released")
    lease.reservationId = nil
    return ok, result
end

function Provider.Complete() return true end

function Provider.Tick(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order or order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then
        lease.reservationId = nil
        return PNC.Tasking.Commands.Complete(lease.leaseId,
            order and order.status or "WORK_ORDER_REMOVED")
    end
    if tostring(order.workerId or "") ~= lease.npcId then
        PNC.Tasking.Events.Emit("WORK_ASSIGNMENT_LOST", {
            npcId = lease.npcId, source = "Tasking.WorkProvider",
            entityId = lease.sourceRef,
        })
        return false
    end
    local phase = order.completionStarted == true and "ATOMIC_COMMIT"
        or order.status == Status.TRAVEL_TO_STOCKPILE
            and "TRAVEL"
        or order.status == Status.TRAVEL_TO_STATION and "TRAVEL"
        or order.status == Status.WORKING and "WORKING" or "WAITING"
    if lease.phase ~= phase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, phase)
    end
    if tonumber(order.lastProgressAt) ~= tonumber(lease.lastProgressAt) then
        lease.lastProgressAt = order.lastProgressAt
    end
    return true
end

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("work", Provider)
end

return Provider
