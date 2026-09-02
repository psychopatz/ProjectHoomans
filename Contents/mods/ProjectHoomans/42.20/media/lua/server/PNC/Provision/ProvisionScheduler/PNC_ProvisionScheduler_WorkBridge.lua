if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProvisionScheduler = PNC.ProvisionScheduler or {}

local Scheduler = PNC.ProvisionScheduler
local OPERATION = "PROVISION_PICKUP"
local STAGE = "provision"

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value)
        or value
end

local function payloadFor(order)
    return order and type(order.payload) == "table" and order.payload or {}
end

local function requirementsFor(selected)
    local requirements = {}
    for index = 1, #(selected or {}) do
        local entry = selected[index]
        local descriptor = entry.descriptor or {}
        local fullType = tostring(descriptor.fullType or "")
        local amount = math.max(1, math.floor(tonumber(entry.quantity) or 1))
        if fullType ~= "" then
            requirements[#requirements + 1] = {
                itemTypes = { fullType }, amount = amount,
                consumed = true,
            }
        end
    end
    return requirements
end

local function isFollowing(record)
    if PNC.HomeDutyService and PNC.HomeDutyService.IsFollowing then
        return PNC.HomeDutyService.IsFollowing(record) == true
    end
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

local function compactSelection(selected)
    local output = {}
    for index = 1, #(selected or {}) do
        local entry = selected[index]
        local descriptor = entry.descriptor or {}
        output[#output + 1] = {
            descriptor = { fullType = descriptor.fullType },
            quantity = math.max(1, math.floor(tonumber(entry.quantity) or 1)),
        }
    end
    return output
end

local function firstSelectedFullType(selected)
    for index = 1, #(selected or {}) do
        local entry = selected[index]
        local descriptor = entry and entry.descriptor or {}
        local fullType = tostring(descriptor.fullType or "")
        if fullType ~= "" then return fullType end
    end
    return nil
end

local function releaseReservation(id)
    if id and PNC.ColonyStorageService
        and PNC.ColonyStorageService.ReleaseProductionReservation
    then
        return PNC.ColonyStorageService.ReleaseProductionReservation(id)
    end
    return true
end

local function reservationReady(payload)
    return payload.reservationId
        and PNC.ColonyStorageService
        and PNC.ColonyStorageService.GetProductionReservation
        and PNC.ColonyStorageService.GetProductionReservation(
            payload.reservationId) ~= nil
end

local function reserveForPayload(order)
    local payload = payloadFor(order)
    if payload.collected == true then return true end
    if reservationReady(payload) then return true end
    if not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReserveProductionMaterials
    then return false, "production_reservation_unavailable" end
    local requirements = requirementsFor(payload.selected)
    if #requirements <= 0 then return false, "no_supply" end
    local reservation, reason =
        PNC.ColonyStorageService.ReserveProductionMaterials(
            payload.storageId, requirements,
            "provision:" .. tostring(order.id))
    if not reservation then return false, reason or "no_supply" end
    payload.reservationId = reservation.id
    if PNC.WorkRepository then PNC.WorkRepository.MarkDirty() end
    return true
end

local function collect(order, worker)
    local payload = payloadFor(order)
    if payload.collected == true then return true end
    local ready, reason = reserveForPayload(order)
    if not ready then return false, reason end
    if not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.CollectProductionReservation
    then return false, "production_collection_unavailable" end
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        payload.reservationId, order.id, payload.stage or STAGE,
        payload.storageId, worker)
    if not ok then return false, details end
    payload.collected = true
    payload.itemIds = details and details.itemIds or {}
    payload.records = details and details.records or {}
    if PNC.WorkRepository then PNC.WorkRepository.MarkDirty() end
    return true
end

local function finishPayload(order)
    local payload = payloadFor(order)
    if payload.storageId and PNC.ColonyStorageService
        and PNC.ColonyStorageService.ForgetProductionTransaction
    then
        PNC.ColonyStorageService.ForgetProductionTransaction(
            payload.storageId, order.id)
    end
    payload.reservationId = nil
    payload.itemIds, payload.records = nil, nil
    payload.selected, payload.request = nil, nil
    payload.storageId, payload.stage = nil, nil
end

local function cancel(order)
    local payload = payloadFor(order)
    if payload.collected == true then
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(order.workerId) or nil
        if not worker or not PNC.ColonyStorageService
            or not PNC.ColonyStorageService.ReturnCollectedProductionRecords
        then return false, "worker_inventory_unavailable" end
        local returned, reason =
            PNC.ColonyStorageService.ReturnCollectedProductionRecords(
                payload.storageId, worker, payload.itemIds or {},
                payload.records or {})
        if not returned then return false, reason end
        if PNC.ColonyStorageService.ForgetProductionTransaction then
            PNC.ColonyStorageService.ForgetProductionTransaction(
                payload.storageId, order.id)
        end
        payload.collected = false
        payload.reservationId = nil
        payload.itemIds, payload.records = nil, nil
    elseif payload.reservationId then
        local released = releaseReservation(payload.reservationId)
        if released == false then return false, "provision_reservation_release_failed" end
        payload.reservationId = nil
    end
    if PNC.WorkRepository then PNC.WorkRepository.MarkDirty() end
    return true
end

local function targetFor(order, worker, live)
    local x = tonumber(worker.x) or 0
    local y = tonumber(worker.y) or 0
    local z = tonumber(worker.z) or 0
    if live then
        x = live.getX and live:getX() or x
        y = live.getY and live:getY() or y
        z = live.getZ and live:getZ() or z
        local service = PNC.StockpileAccessService
        local node = service and service.FindNearest
            and service.FindNearest(order.baseId, x, y, z, {
                requireLoaded = true,
            }) or nil
        if not node then return nil, "NO_STOCKPILE_ACCESS_NODE" end
        return { x = node.x, y = node.y, z = node.z, nodeId = node.id }
    end
    return { x = x, y = y, z = z }
end

function Scheduler.BindWorkService(work)
    if Scheduler.WorkServiceBound == true then return true end
    if not work or not work.RegisterTargetProvider
        or not work.RegisterCollection or not work.RegisterCompletion
        or not work.RegisterPreparation
    then return false, "work_service_unavailable" end

    work.RegisterTargetProvider(OPERATION, function(order, worker, live)
        local target, reason = targetFor(order, worker, live)
        if not target then return { ok = false, reason = reason } end
        return { ok = true, componentId = "provision:" .. tostring(order.id),
            facilityId = order.baseId, target = target, abstract = live == nil }
    end)
    work.RegisterPreparation(OPERATION, reserveForPayload)
    work.RegisterCollection(OPERATION, collect)
    work.RegisterCompletion(OPERATION, function(order)
        local ok, reason = collect(order,
            PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(order.workerId) or nil)
        if not ok then return false, reason end
        finishPayload(order)
        return true
    end)
    work.CancellationHandlers = work.CancellationHandlers or {}
    work.CancellationHandlers[OPERATION] = cancel
    Scheduler.WorkServiceBound = true
    return true
end

function Scheduler.QueueLivePickup(record, storage, request, selected, state)
    local work = PNC.WorkService
    if not work then return nil, "work_service_unavailable" end
    local bound, bindReason = Scheduler.BindWorkService(work)
    if not bound then return nil, bindReason end
    if not PNC.BaseService or not PNC.BaseService.GetForColony then
        return nil, "base_service_unavailable" end
    local base = PNC.BaseService.GetForColony(storage.settlementId)
    if not base then return nil, "base_not_found" end
    if isFollowing(record) then
        return nil, "provision_blocked_while_following"
    end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(record, base.id)
    then
        return nil, "provision_waiting_for_home"
    end
    if not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReserveProductionMaterials
    then return nil, "production_reservation_unavailable" end

    local requirements = requirementsFor(selected)
    if #requirements <= 0 then return nil, "no_supply" end
    local reservation, reason =
        PNC.ColonyStorageService.ReserveProductionMaterials(
            storage.id, requirements,
            "provision:" .. tostring(record.id) .. ":"
                .. tostring(PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0))
    if not reservation then return nil, reason or "no_supply" end

    local order, queueReason = work.Commands.Queue({
        operation = OPERATION, colonyId = storage.settlementId,
        factionId = storage.ownerFactionId, baseId = base.id,
        -- Provision is a home-only pickup. An away worker is returned home by
        -- WorkService before this durable order is retried.
        locationPolicy = { start = "HOME", execution = "HOME",
            returnHome = "HOME" },
        requiredWork = 1, priority = request.priority,
        payload = {
            storageId = storage.id, reservationId = reservation.id,
            stage = STAGE, selected = compactSelection(selected),
            activityItemFullType = firstSelectedFullType(selected),
            request = copy(request),
        },
    })
    if not order then
        releaseReservation(reservation.id)
        return nil, queueReason or "provision_work_queue_failed"
    end
    state.phase = "TRAVEL_TO_STOCKPILE"
    state.reservationState = "reserved"
    state.pendingWorkOrderId = order.id
    return false, "provision_pickup_queued", { workOrderId = order.id }
end

return Scheduler
