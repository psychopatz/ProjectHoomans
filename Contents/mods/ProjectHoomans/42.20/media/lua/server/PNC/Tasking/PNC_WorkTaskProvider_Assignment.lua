-- Work task candidate discovery and assignment provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = PNC.WorkTaskProvider or {}
local Internal = Provider.Internal or {}
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions.STATUS
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
local assignable = Internal.Assignable

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
            local job = PNC.WorkDefinitions.JOB_BY_OPERATION
                and PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation]
            output[#output + 1] = {
                taskId = order.id, npcId = tostring(npcId),
                kind = order.operation, sourceDomain = "work",
                sourceRef = order.id,
                precedence = priority >= 90 and "FORCED_ORDER"
                    or priority >= 50 and "HIGH_WORK" or "NORMAL_WORK",
                urgency = math.max(0, math.min(1, (priority + 100) / 200)),
                workPriority = job and WorkPolicy.GetPriority(record, job)
                    or nil,
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

-- The task arbiter only needs GetCandidates during normal evaluation. The
-- diagnostic path is intentionally separate so inspecting one NPC does not
-- add a full repository explanation pass to every tasking pump.
function Provider.GetDiagnostics(npcId)
    if not Work or not Work.Queries
        or not Work.Queries.BuildAssignmentDiagnostics
    then
        return {
            totalOrders = 0,
            statusCounts = {},
            assignableOrders = 0,
            eligibleOrders = 0,
            rejectionCounts = {},
            eligibleOperations = {},
            samples = {},
            unavailable = "WORK_DIAGNOSTICS_UNAVAILABLE",
        }
    end
    return Work.Queries.BuildAssignmentDiagnostics(npcId)
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
