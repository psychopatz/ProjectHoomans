-- WorkService station and worker claim orchestration.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local now = Internal.now
local copy = Internal.copy

local function claimStation(order, worker)
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(worker.id) or nil
    local acquired = Internal.acquireWorkTarget(order, worker, live)
    if not acquired or not acquired.ok then
        return false, acquired and acquired.reason or "NO_AVAILABLE_WORKSTATION"
    end
    -- Work targets can be facility components or world objects. Store every
    -- provider's durable collision key in the common stationId field.
    local stationId = tostring(acquired.componentId or acquired.claimKey or "")
    if stationId == "" or Service.ClaimsByStation[stationId] then
        if acquired.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(acquired.reservationId,
                "station_claim_conflict")
        end
        return false, "NO_AVAILABLE_WORKSTATION"
    end
    local needsCollection = live and Internal.requiresCollection(order)
    local collectTarget = needsCollection
        and Internal.collectionTarget(order, worker, live)
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
    order.targetKind = acquired.targetKind
    order.phase = acquired.phase or order.phase
    order.livePhase = acquired.phase or order.livePhase
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
    local previousOrder = worker.orderSpec
    local payload = order.payload or {}
    local lumberProjection = previousOrder
        and tostring(previousOrder.kind or "")
            == tostring(PNC.Const and PNC.Const.ORDER_LUMBER or "lumber")
        and tostring(previousOrder.lumberJobId or "")
            == tostring(payload.lumberJobId or "")
    if lumberProjection then
        order.previousOrder = nil
    else
        order.previousOrder = copy(previousOrder)
    end
    if live and acquired.target then
        Internal.setLiveOrder(worker, order, collectTarget or acquired.target,
            collectTarget and "COLLECT_INPUTS" or "WORK_AT_STATION")
    end
    Repository.MarkDirty()
    return true
end

Internal.claimStation = claimStation
