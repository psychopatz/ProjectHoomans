-- Server-side pickup and return transactions for reusable work items.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
if not PNC.WorkItemService then
    require "PNC/Core/Production/WorkItems/PNC_JobRequirements"
    require "PNC/Core/Production/WorkItems/PNC_WorkItemService"
end
PNC.WorkItemService = PNC.WorkItemService or {}

local Service = PNC.WorkItemService
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local PICKUP = "WORK_ITEM_PICKUP"
local RETURN = "WORK_ITEM_RETURN"

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function payloadFor(order)
    return order and type(order.payload) == "table" and order.payload or {}
end

local function workerFor(order)
    return order and order.workerId and PNC.Registry
        and PNC.Registry.Get and PNC.Registry.Get(order.workerId) or nil
end

local function operationKey(operation)
    return string.upper(tostring(operation or ""))
end

local function operationHasRequirements(operation)
    if type(Service.OperationHasRequirements) == "function" then
        return Service.OperationHasRequirements(operation)
    end
    local registry = PNC.JobRequirements
    local requirements = registry and registry.GetRequirements
        and registry.GetRequirements(operationKey(operation)) or nil
    return type(requirements) == "table" and #requirements > 0
end

local function requirementTypes(operation)
    if type(Service.GetRequirementCandidates) == "function" then
        return Service.GetRequirementCandidates(operation, "primary")
    end
    local output = {}
    local requirements = PNC.JobRequirements
        and PNC.JobRequirements.GetRequirements
        and PNC.JobRequirements.GetRequirements(operationKey(operation)) or {}
    for index = 1, #requirements do
        local requirement = requirements[index]
        if requirement.equipSlot == "primary" then
            for typeIndex = 1, #(requirement.candidates or {}) do
                output[#output + 1] = requirement.candidates[typeIndex]
            end
        end
    end
    return output
end

local function storageCandidateCount(storage, itemTypes)
    if not storage then return 0 end
    if PNC.ColonyStorageService
        and type(PNC.ColonyStorageService.CountProductionAvailable) == "function"
    then
        return tonumber(PNC.ColonyStorageService.CountProductionAvailable(
            storage.id, itemTypes)) or 0
    end
    local inventory = storage.inventory
    if inventory and type(inventory.count) == "function" then
        local total = 0
        for index = 1, #(itemTypes or {}) do
            total = total + (tonumber(inventory:count({
                fullType = itemTypes[index],
            })) or 0)
        end
        return total
    end
    return 0
end

local function hasActivePendingPickup(record, operation)
    local key = operationKey(operation)
    local runtime = record and record.runtime or nil
    local pending = runtime and runtime.workItemPickups
        and runtime.workItemPickups[key] or nil
    local pendingOrder = pending and Work and Work.Queries
        and Work.Queries.Get and Work.Queries.Get(pending.orderID) or nil
    if pendingOrder and pendingOrder.status ~= Status.COMPLETED
        and pendingOrder.status ~= Status.CANCELLED
        and pendingOrder.status ~= Status.FAILED
        and pendingOrder.status ~= Status.BLOCKED
    then
        return true, pendingOrder
    end
    return false, nil
end

local function clearPendingPickup(record, operation)
    local key = operationKey(operation)
    local runtime = record and record.runtime or nil
    if runtime and runtime.workItemPickups then
        runtime.workItemPickups[key] = nil
    end
end

local function wakeRequestedOrder(orderID, releaseAutoWorker, workerID)
    if not orderID or not PNC.WorkRepository
        or type(PNC.WorkRepository.Get) ~= "function"
    then return end
    local requested = PNC.WorkRepository.Get(orderID)
    if not requested then return end
    if requested.status == Status.COMPLETED
        or requested.status == Status.CANCELLED
        or requested.status == Status.FAILED
    then return end
    local changed = false
    if releaseAutoWorker == true and requested.autoAssignedWorker == true
        and (not workerID
            or tostring(requested.requiredWorkerId or "") == tostring(workerID))
    then
        requested.requiredWorkerId = nil
        requested.autoAssignedWorker = nil
        changed = true
    end
    if requested.status == Status.WAITING_RESOURCE
        and requested.blockedReason == "WAITING_FOR_WORK_ITEM"
    then
        requested.status = Status.WAITING_FOR_WORKER or "WAITING_FOR_WORKER"
        requested.blockedReason = nil
        requested.revision = (tonumber(requested.revision) or 0) + 1
        changed = true
    end
    if changed then
        if PNC.WorkRepository.MarkDirty then PNC.WorkRepository.MarkDirty() end
        if Work and Work.Commands
            and type(Work.Commands.MarkAssignmentDirty) == "function"
        then
            Work.Commands.MarkAssignmentDirty(requested, "WORK_ITEM_READY")
        end
    end
end

local function selectedType(reservation)
    local requirements = reservation and reservation.requirements or {}
    local first = requirements[1]
    return first and first.selectedType or nil
end

local function findNode(order, worker, live)
    local x = tonumber(worker and worker.x) or 0
    local y = tonumber(worker and worker.y) or 0
    local z = tonumber(worker and worker.z) or 0
    local access = PNC.StockpileAccessService
    local node = access and access.FindNearest
        and access.FindNearest(order.baseId, x, y, z, {
            requireLoaded = live ~= nil,
        }) or nil
    if not node then
        if live then return nil, "NO_STOCKPILE_ACCESS_NODE" end
        return { x = x, y = y, z = z }
    end
    return { x = node.x, y = node.y, z = node.z, nodeId = node.id }
end

local function targetFor(order, worker, live)
    local target, reason = findNode(order, worker, live)
    if not target then return { ok = false, reason = reason } end
    return {
        ok = true,
        componentId = string.lower(order.operation) .. ":" .. tostring(order.id),
        facilityId = order.baseId,
        target = target,
        abstract = live == nil,
    }
end

local function collectPickup(order, worker)
    local payload = payloadFor(order)
    if payload.collected == true then return true end
    if not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.CollectProductionReservation
    then return false, "work_item_collection_unavailable" end
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        payload.reservationID, order.id, "work_item_pickup",
        payload.storageID, worker)
    if not ok then return false, details end
    payload.collected = true
    payload.itemIDs = details and details.itemIds or {}
    payload.records = details and details.records or {}
    payload.selectedType = payload.selectedType
        or details and details.fullType or nil
    if PNC.WorkRepository then PNC.WorkRepository.MarkDirty() end
    return true
end

local function releasePickupReservation(order)
    local payload = payloadFor(order)
    if payload.collected == true then return true end
    if payload.reservationID and PNC.ColonyStorageService
        and PNC.ColonyStorageService.ReleaseProductionReservation
    then
        local released, reason = PNC.ColonyStorageService
            .ReleaseProductionReservation(payload.reservationID)
        if released or reason == "reservation_not_found" then
            payload.reservationID = nil
            return true
        end
        return false, reason
    end
    return true
end

local function finishPickup(order)
    local payload = payloadFor(order)
    local worker = workerFor(order)
    if not worker then return false, "worker_inventory_unavailable" end
    local collected, reason = collectPickup(order, worker)
    if not collected then return false, reason end
    local operation = tostring(payload.operation or "")
    local itemID = payload.itemIDs and payload.itemIDs[1] or nil
    local ready, readyReason = Service.Ensure(worker, operation, nil, {
        owner = "work:" .. operation,
        itemID = itemID,
        applyHands = false,
    })
    if not ready then
        if PNC.ColonyStorageService.ReturnCollectedProductionRecords then
            local returned, returnReason =
                PNC.ColonyStorageService.ReturnCollectedProductionRecords(
                payload.storageID, worker, payload.itemIDs or {},
                payload.records or {})
            if not returned then
                return false, returnReason or "work_item_pickup_rollback_failed"
            end
        end
        return false, readyReason or "work_item_validation_failed"
    end
    Service.SetSource(worker, operation, {
        sourceStorageID = payload.storageID,
        sourceBaseID = payload.baseID or order.baseId,
        sourceItemIDs = copy(payload.itemIDs or {}),
        sourceRecords = copy(payload.records or {}),
        returnPolicy = "ON_JOB_END",
        sourceFullType = payload.selectedType,
    })
    clearPendingPickup(worker, operation)
    wakeRequestedOrder(payload.requestedOrderID, false, worker.id)
    return true
end

local function finishReturn(order)
    local payload = payloadFor(order)
    local worker = workerFor(order)
    if payload.returned == true then return true end
    if not worker or not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReturnCollectedProductionRecords
    then return false, "worker_inventory_unavailable" end
    local returned, reason = PNC.ColonyStorageService
        .ReturnCollectedProductionRecords(
            payload.storageID, worker, payload.itemIDs or {},
            payload.records or {})
    if not returned then return false, reason end
    payload.returned = true
    if PNC.WorkRepository then PNC.WorkRepository.MarkDirty() end
    return true
end

local function cancelPickup(order)
    local payload = payloadFor(order)
    local worker = workerFor(order)
    local operation = tostring(payload.operation or "")
    local workerID = worker and worker.id or order.workerId or order.requiredWorkerId
    local targetWorker = worker or (workerID and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerID) or nil)
    if targetWorker and operation ~= "" then
        clearPendingPickup(targetWorker, operation)
    end
    wakeRequestedOrder(payload.requestedOrderID, true, workerID)
    if payload.collected == true then
        if not worker or not PNC.ColonyStorageService
            or not PNC.ColonyStorageService.ReturnCollectedProductionRecords
        then return false, "worker_inventory_unavailable" end
        return PNC.ColonyStorageService.ReturnCollectedProductionRecords(
            payload.storageID, worker, payload.itemIDs or {},
            payload.records or {})
    end
    return releasePickupReservation(order)
end

local function requestPickup(record, order)
    local operation = operationKey(order.operation)
    local report = Service.Check(record, operation)
    if report.ok then return true end
    record.runtime = record.runtime or {}
    record.runtime.workItemPickups = record.runtime.workItemPickups or {}
    if hasActivePendingPickup(record, operation) then
        return false, "WAITING_FOR_WORK_ITEM"
    end
    record.runtime.workItemPickups[operation] = nil

    local access = PNC.StorageAccessPolicy
    local storage = access and access.Resolve and access.Resolve(record) or nil
    if not storage then return false, "NO_WORK_ITEM_STORAGE" end
    if not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReserveProductionMaterials
    then return false, "WORK_ITEM_RESERVATION_UNAVAILABLE" end
    local reservation, reserveReason = PNC.ColonyStorageService
        .ReserveProductionMaterials(storage.id, {
            { itemTypes = requirementTypes(operation), amount = 1,
                consumed = true },
        }, "work_item:" .. tostring(record.id) .. ":" .. operation)
    if not reservation then
        return false, reserveReason or "NO_WORK_ITEM_SUPPLY"
    end
    if not Work or not Work.Commands or not Work.Commands.Queue then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    local pickup, queueReason = Work.Commands.Queue({
        operation = PICKUP,
        colonyId = order.colonyId, factionId = order.factionId,
        baseId = order.baseId, requiredWorkerId = record.id,
        requiredWork = 1, priority = (tonumber(order.priority) or 0) + 5,
        locationPolicy = { start = "HOME", execution = "HOME",
            returnHome = "HOME" },
        payload = {
            operation = operation, storageID = storage.id,
            baseID = order.baseId,
            reservationID = reservation.id,
            selectedType = selectedType(reservation),
            requestedOrderID = order.id,
        },
    })
    if not pickup then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return false, queueReason or "WORK_ITEM_PICKUP_QUEUE_FAILED"
    end
    record.runtime.workItemPickups[operation] = { orderID = pickup.id }
    return false, "WAITING_FOR_WORK_ITEM"
end

function Service.CheckStorageAvailability(record, operation)
    local key = operationKey(operation)
    local registry = PNC.JobRequirements
    local requirements = registry and registry.GetRequirements
        and registry.GetRequirements(key) or nil
    if type(requirements) ~= "table" or #requirements == 0 then
        return true
    end
    if not record or record.alive == false then
        return false, "worker_unavailable"
    end
    if hasActivePendingPickup(record, key) then
        return true, nil, "pending_work_item_pickup"
    end
    local access = PNC.StorageAccessPolicy
    local storage, accessReason
    if access and type(access.Resolve) == "function" then
        storage, accessReason = access.Resolve(record)
    end
    if not storage then
        return false, accessReason or "NO_WORK_ITEM_STORAGE"
    end
    for index = 1, #requirements do
        local requirement = requirements[index]
        local needed = math.max(1, math.floor(tonumber(requirement.quantity) or 1))
        local available = storageCandidateCount(
            storage, requirement.candidates or {})
        if available < needed then
            return false, "NO_WORK_ITEM_SUPPLY"
        end
    end
    return true, storage
end

function Service.CanAcquireFromStorage(record, operation)
    return Service.CheckStorageAvailability(record, operation)
end

function Service.PrepareForWorker(order, record)
    if not order or order.operation == PICKUP or order.operation == RETURN
        or not operationHasRequirements(order.operation)
    then return true end
    if not record or record.alive == false then
        return false, "WORKER_NOT_FOUND"
    end
    local report = Service.Check(record, order.operation)
    if report.ok then return true end
    local boundAutoWorker = false
    if not order.requiredWorkerId then
        order.requiredWorkerId = tostring(record.id)
        order.autoAssignedWorker = true
        boundAutoWorker = true
    elseif tostring(order.requiredWorkerId) ~= tostring(record.id) then
        return false, "REQUIRED_WORKER_MISMATCH"
    end
    local ready, reason = requestPickup(record, order)
    if ready == true then return true end
    if reason == "WAITING_FOR_WORK_ITEM" then
        order.status = Status.WAITING_RESOURCE or "WAITING_RESOURCE"
        order.blockedReason = "WAITING_FOR_WORK_ITEM"
        order.revision = (tonumber(order.revision) or 0) + 1
        if PNC.WorkRepository and PNC.WorkRepository.MarkDirty then
            PNC.WorkRepository.MarkDirty()
        end
        return false, "WAITING_FOR_WORK_ITEM"
    end
    if boundAutoWorker then
        order.requiredWorkerId = nil
        order.autoAssignedWorker = nil
    end
    return false, reason
end

function Service.PrepareOrder(order)
    if not order or order.operation == PICKUP or order.operation == RETURN
        or not order.requiredWorkerId
        or not operationHasRequirements(order.operation)
    then return true end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.requiredWorkerId) or nil
    if not record or record.alive == false then
        if order.autoAssignedWorker == true then
            order.requiredWorkerId = nil
            order.autoAssignedWorker = nil
            if PNC.WorkRepository and PNC.WorkRepository.MarkDirty then
                PNC.WorkRepository.MarkDirty()
            end
            return true
        end
        return false, "WORKER_NOT_FOUND"
    end
    local report = Service.Check(record, order.operation)
    if report.ok then return true end
    local ready, reason = requestPickup(record, order)
    if ready ~= true and reason ~= "WAITING_FOR_WORK_ITEM"
        and order.autoAssignedWorker == true
    then
        order.requiredWorkerId = nil
        order.autoAssignedWorker = nil
        if PNC.WorkRepository and PNC.WorkRepository.MarkDirty then
            PNC.WorkRepository.MarkDirty()
        end
        return true
    end
    return ready, reason
end

function Service.ReturnToStorage(record, operation, lease, options)
    options = type(options) == "table" and options or {}
    local itemIDs = lease.sourceItemIDs or {}
    local records = lease.sourceRecords or {}
    if not lease.sourceStorageID or #itemIDs <= 0 then
        return true
    end
    if #records <= 0 then return false, "WORK_ITEM_RECORDS_MISSING" end
    if lease.returnPolicy == "NEVER" or options.returnToStorage == false then
        return true
    end
    local existing = lease.returnOrderID and Work.Queries and Work.Queries.Get
        and Work.Queries.Get(lease.returnOrderID) or nil
    if existing and existing.status == Status.COMPLETED then
        return true, "work_item_return_already_completed"
    end
    if existing and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.FAILED
    then return true end
    local base = lease.sourceBaseID
        or (record and record.baseId)
        or ""
    local order, reason = Work.Commands.Queue({
        operation = RETURN,
        colonyId = record.affiliation and record.affiliation.communityID or "",
        factionId = record.affiliation and record.affiliation.factionID or "",
        baseId = base, requiredWorkerId = record.id, requiredWork = 1,
        priority = 90,
        locationPolicy = { start = "HOME", execution = "HOME",
            returnHome = "HOME" },
        payload = {
            operation = operation, storageID = lease.sourceStorageID,
            baseID = base,
            itemIDs = copy(lease.sourceItemIDs),
            records = copy(lease.sourceRecords or {}),
        },
    })
    if not order then return false, reason or "WORK_ITEM_RETURN_QUEUE_FAILED" end
    lease.returnOrderID = order.id
    return true
end

if Work and Work.RegisterTargetProvider then
    Work.RegisterTargetProvider(PICKUP, targetFor)
    Work.RegisterTargetProvider(RETURN, targetFor)
end
if Work and Work.RegisterCollection then
    Work.RegisterCollection(PICKUP, collectPickup)
end
if Work and Work.RegisterCompletion then
    Work.RegisterCompletion(PICKUP, finishPickup)
    Work.RegisterCompletion(RETURN, finishReturn)
end
if Work and Work.RegisterCompletionRecovery then
    Work.RegisterCompletionRecovery(RETURN, function(order, reason)
        order.status = Status.WORKING
        order.blockedReason = "WORK_ITEM_RETURN_WAITING"
        order.lastExecutionFailureReason = tostring(reason or "storage_unavailable")
        return true, "WORK_ITEM_RETURN_RETRY"
    end)
end
if Work then
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers[PICKUP] = cancelPickup
end

return Service
