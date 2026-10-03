-- WorkService target-provider and collection handoff.
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

local function setLiveOrder(worker, order, target, phase)
    if not target then return false end
    local payload = order.payload or {}
    PNC.OrderSystem.SetOrder(worker, {
        kind = "production_work", workOrderId = order.id,
        operation = order.operation, phase = phase or order.livePhase,
        x = target.x, y = target.y, z = target.z,
        stopDistance = target.stopDistance or payload.stopDistance,
        facilityId = order.facilityId, stationId = order.stationId,
        stockpileNodeId = target.nodeId,
        haulToken = payload.haulToken,
        sourceX = payload.sourceX, sourceY = payload.sourceY,
        sourceZ = payload.sourceZ,
        interactionX = target.interactionX or payload.interactionX,
        interactionY = target.interactionY or payload.interactionY,
        interactionZ = target.interactionZ or payload.interactionZ,
        interactionFacing = target.interactionFacing
            or payload.interactionFacing,
        interactionTarget = target.interactionTarget == true
            or payload.interactionTarget == true,
        approachKey = target.approachKey or payload.approachKey,
        dropX = payload.dropX, dropY = payload.dropY, dropZ = payload.dropZ,
    })
    return true
end

local function collectionTarget(order, worker, live)
    local standardized = PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
    if not standardized and not Service.CollectionHandlers[order.operation]
        or not PNC.StockpileAccessService
    then return nil end
    local node = PNC.StockpileAccessService.FindNearest(order.baseId,
        worker.x or 0, worker.y or 0, worker.z or 0, {
            requireLoaded = live ~= nil,
        })
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

Internal.setLiveOrder = setLiveOrder
Internal.collectionTarget = collectionTarget
Internal.requiresCollection = requiresCollection
Internal.acquireWorkTarget = acquireWorkTarget
