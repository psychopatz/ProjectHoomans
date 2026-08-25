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
local now = Internal.now
local copy = Internal.copy

local function setLiveOrder(worker, order, target, phase)
    if not target then return false end
    PNC.OrderSystem.SetOrder(worker, {
        kind = "production_work", workOrderId = order.id,
        operation = order.operation, phase = phase,
        x = target.x, y = target.y, z = target.z,
        facilityId = order.facilityId, stationId = order.stationId,
        stockpileNodeId = target.nodeId,
    })
    return true
end

local function collectionTarget(order, worker)
    local standardized = PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
    if not standardized and not Service.CollectionHandlers[order.operation]
        or not PNC.StockpileAccessService
    then return nil end
    local node = PNC.StockpileAccessService.FindNearest(order.baseId,
        worker.x or 0, worker.y or 0, worker.z or 0)
    if not node then return nil end
    return { x = node.x, y = node.y, z = node.z, nodeId = node.id }
end

local function requiresCollection(order)
    return PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
        or Service.CollectionHandlers[order.operation] ~= nil
            and not (order.payload and order.payload.inputsStaged == true)
end

local function acquireWorkTarget(order, worker, live)
    local provider = Service.TargetProviders[order.operation]
    if provider then return provider(order, worker, live) end
    local capability = Definitions.CAPABILITY_BY_OPERATION[order.operation]
    return PNC.FacilityService.AcquireActivity(order.baseId, worker.id,
        capability, { abstract = live == nil, ttlMs = 30000,
            workOrderId = order.id,
            stationId = order.requiredStationId })
end

local function claimStation(order, worker)
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(worker.id) or nil
    local acquired = acquireWorkTarget(order, worker, live)
    if not acquired or not acquired.ok then
        return false, acquired and acquired.reason or "NO_AVAILABLE_WORKSTATION"
    end
    local stationId = tostring(acquired.componentId or "")
    if stationId == "" or Service.ClaimsByStation[stationId] then
        if acquired.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(acquired.reservationId,
                "station_claim_conflict")
        end
        return false, "NO_AVAILABLE_WORKSTATION"
    end
    local needsCollection = live and requiresCollection(order)
    local collectTarget = needsCollection and collectionTarget(order, worker)
        or nil
    if needsCollection and not collectTarget then
        if acquired.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(acquired.reservationId,
                "stockpile_access_missing")
        end
        return false, "NO_STOCKPILE_ACCESS_NODE"
    end
    Service.ClaimsByStation[stationId], Service.ClaimsByWorker[worker.id] = order.id, order.id
    order.workerId, order.stationId = worker.id, stationId
    order.facilityId = acquired.facilityId
    order.facilityReservationId = acquired.reservationId
    order.stationTarget = copy(acquired.target)
    order.executionMode = live and "LIVE" or "ABSTRACT"
    order.collectionTarget = collectTarget and copy(collectTarget) or nil
    order.status = collectTarget and Status.TRAVEL_TO_STOCKPILE
        or live and Status.TRAVEL_TO_STATION or Status.WORKING
    order.blockedReason = nil
    order.updatedAt, order.lastProgressAt = now(), now()
    order.revision = order.revision + 1
    worker.runtime = worker.runtime or {}
    worker.runtime.workOrderId = order.id
    worker.runtime.lastProductionWorkAt = nil
    order.previousOrder = copy(worker.orderSpec)
    if live and acquired.target then
        setLiveOrder(worker, order, collectTarget or acquired.target,
            collectTarget and "COLLECT_INPUTS" or "WORK_AT_STATION")
    end
    Repository.MarkDirty()
    return true
end


Internal.setLiveOrder = setLiveOrder
Internal.collectionTarget = collectionTarget
Internal.requiresCollection = requiresCollection
Internal.acquireWorkTarget = acquireWorkTarget
Internal.claimStation = claimStation

return Service
