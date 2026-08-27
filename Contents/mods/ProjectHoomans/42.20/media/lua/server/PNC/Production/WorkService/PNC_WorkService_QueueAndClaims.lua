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
local emit = Internal.emit
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local markAssignmentDirty = Internal.markAssignmentDirty

function Service.Commands.Queue(spec)
    spec = type(spec) == "table" and spec or {}
    local operation = tostring(spec.operation or "")
    if not Definitions.CAPABILITY_BY_OPERATION[operation]
        and not Service.TargetProviders[operation]
    then
        return nil, "UNKNOWN_OPERATION"
    end
    local order = {
        schemaVersion = Repository.SCHEMA_VERSION,
        id = Repository.NextId(), operation = operation,
        colonyId = tostring(spec.colonyId or ""),
        factionId = tostring(spec.factionId or ""),
        baseId = tostring(spec.baseId or ""),
        recipeId = tonumber(spec.recipeId),
        recipeRevision = tonumber(spec.recipeRevision),
        requiredStationId = spec.requiredStationId
            and tostring(spec.requiredStationId) or nil,
        productionSkillId = spec.productionSkillId
            and tostring(spec.productionSkillId) or nil,
        funded = spec.funded == true,
        projectLifecycle = spec.projectLifecycle,
        quantity = math.max(1, math.floor(tonumber(spec.quantity) or 1)),
        requiredWork = math.max(1, tonumber(spec.requiredWork) or 100),
        progress = math.max(0, tonumber(spec.progress) or 0),
        requiredSkills = copy(spec.requiredSkills or {}),
        -- Most colony work starts at the home base. Some operations, such as
        -- This flag is explicit for persisted work-order consumers; the
        -- provision operation also enforces its home-only policy in Core.
        requiresHome = spec.requiresHome ~= false,
        autoReturnHome = spec.autoReturnHome ~= false,
        payload = copy(spec.payload or {}),
        status = Status.QUEUED, priority = tonumber(spec.priority) or 0,
        revision = 0, createdAt = now(), updatedAt = now(),
        lastProgressAt = now(),
    }
    Repository.Put(order)
    markAssignmentDirty(order, "WORK_REQUEST_QUEUED")
    emit(EventTypes.WORK_ORDER_QUEUED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return copy(order)
end

local function releaseClaim(order, reason, cancelInputs, cleanupOperation)
    if not order then return end
    if cleanupOperation == true
        and order.operation == "PROVISION_PICKUP"
        and not order.completionCommitted
    then
        local cancellation = Service.CancellationHandlers
            and Service.CancellationHandlers[order.operation]
        if cancellation then
            local cleaned, cleanupReason = cancellation(order)
            if cleaned == false then
                return false, cleanupReason or "WORK_RELEASE_CLEANUP_FAILED"
            end
        end
    end
    local input = order.payload and order.payload.input
    if PNC.WorkInputService and input
        and (cancelInputs == true or input.staged == true)
    then
        -- Collected inputs physically live on the current NPC and must return
        -- to the stockpile before a replacement can collect them. An input
        -- that is only reserved can remain attached to the durable order.
        PNC.WorkInputService.Cancel(order)
    end
    if order.stationId and Service.ClaimsByStation[order.stationId] == order.id then
        Service.ClaimsByStation[order.stationId] = nil
    end
    if order.workerId and Service.ClaimsByWorker[order.workerId] == order.id then
        Service.ClaimsByWorker[order.workerId] = nil
    end
    if order.facilityReservationId and PNC.FacilityReservations then
        PNC.FacilityReservations.Release(order.facilityReservationId,
            reason or "work_released")
    end
    local record = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if record and record.runtime and record.runtime.workOrderId == order.id then
        record.runtime.workOrderId = nil
        record.runtime.lastProductionWorkAt = nil
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, order.previousOrder)
        end
    end
    order.workerId, order.stationId, order.facilityId = nil, nil, nil
    order.facilityReservationId, order.previousOrder = nil, nil
    order.stationTarget, order.collectionTarget = nil, nil
    order.executionMode, order.lastAbstractAt = nil, nil
    return true
end

local function assignedOrderForRecord(record)
    local runtime = record and record.runtime or nil
    local orderId = runtime and runtime.workOrderId or nil
    local order = orderId and Repository.Get(orderId) or nil
    if order and not terminal(order)
        and tostring(order.workerId or "") == tostring(record.id or "")
    then
        return order
    end
    return nil
end

local function restoreOrderIsSafe(record, previous)
    if type(previous) ~= "table" then return false end
    if tostring(previous.kind or "") ~= "production_work" then return true end
    local orderId = previous.workOrderId
    local order = orderId and Repository.Get(orderId) or nil
    return order ~= nil and not terminal(order)
        and tostring(order.workerId or "") == tostring(record.id or "")
end


Internal.releaseClaim = releaseClaim
Internal.assignedOrderForRecord = assignedOrderForRecord
Internal.restoreOrderIsSafe = restoreOrderIsSafe

return Service
