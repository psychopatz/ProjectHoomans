-- Colony stockpile destination resolution, wait backoff, and capacity reservation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local compactItemsForType = Internal.CompactItemsForType
local pendingDescriptorsByType = Internal.PendingDescriptorsByType
local DEFAULT_RETRY_MS = 5000

local function markDirty(opts)
    if opts and type(opts.markDirty) == "function" then opts.markDirty() end
end

local function updateContext(opts, record, context, effect)
    if opts and type(opts.onUpdate) == "function" then
        opts.onUpdate(record, context, effect)
    end
end

local function haltMovement(record, body, reason)
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(record, body, reason or "work_output_wait")
    end
end

local function storageRevision(storage)
    local storageService = PNC.ColonyStorageService
    if storageService and type(storageService.GetStorageRevision) == "function" then
        return storageService.GetStorageRevision(storage)
    end
    return tonumber(storage and storage.revision) or 0
end

local function waitStorageChanged(context)
    local storageID = context and context.outputWaitStorageId or nil
    if not storageID then return false end
    local storageService = PNC.ColonyStorageService
    if storageService and type(storageService.HasStorageChanged) == "function" then
        return storageService.HasStorageChanged(storageID,
            context.outputWaitStorageRevision) == true
    end
    local storage = PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.Get
        and PNC.ColonyStorageRepository.Get(storageID) or nil
    if not storage then return false end
    return tostring(storage.revision or 0)
        ~= tostring(context.outputWaitStorageRevision or 0)
end

local function previewOutputItems(record, body, effect, storageService)
    local preview = {}
    for fullType, descriptors in pairs(pendingDescriptorsByType(effect)) do
        local remaining = #descriptors
        for _, item in ipairs(compactItemsForType(record, fullType)) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(tonumber(item.stack) or 0))
            local quantity = math.min(available, remaining)
            if quantity > 0 then
                local source, sourceReason = storageService.LiveNPCSource(
                    record, item, quantity, body)
                if not source then return nil, sourceReason end
                if type(source.preview) ~= "function" then return nil, nil end
                local records, reason = source:preview()
                if not records then return nil, reason end
                for _, entry in ipairs(records) do preview[#preview + 1] = entry end
                remaining = remaining - quantity
            end
        end
        if remaining > 0 then return nil, "WORK_OUTPUT_NOT_IN_INVENTORY" end
    end
    return preview
end

---Enters a bounded backoff wait for colony stockpile availability or capacity.
function Internal.EnterStockpileWait(context, record, body, effect, at, reason,
    storage, storageId, details, opts)
    haltMovement(record, body, reason)
    Service.ReleaseOutputCapacity(context, PNC.ColonyStorageService)
    if opts and opts.clearDestinationOnWait == true and context then
        context.outputDestination = nil
    end
    context.state, context.phase = "WAITING", "WAITING_FOR_STOCKPILE"
    context.outputRetryAt = at + (tonumber(opts and opts.retryMs) or DEFAULT_RETRY_MS)
    context.outputCapacityDetails, context.outputWaitReason = details, reason
    context.outputWaitStorageId = storageId
    context.outputWaitStorageRevision = storage and storageRevision(storage) or nil
    effect.waitReason, effect.lastReason, effect.updatedAt = reason, reason, at
    updateContext(opts, record, context, effect)
    markDirty(opts)
    return true, false, reason
end

---Checks or reserves destination stockpile capacity for carried work outputs.
function Internal.EnsureDestinationCapacity(context, record, body, effect, at, opts)
    if (tonumber(context.outputRetryAt) or 0) > at then
        if not waitStorageChanged(context) then
            haltMovement(record, body, "work_stockpile_retry_wait")
            updateContext(opts, record, context, effect)
            return nil, nil, "waiting_for_work_stockpile"
        end
        context.outputRetryAt = nil
    end
    local dest, destReason = Internal.ResolveOutputDestination(record, context, effect, opts)
    if not dest then
        Internal.EnterStockpileWait(context, record, body, effect, at, destReason, nil, nil, nil, opts)
        return nil, nil, destReason
    end
    local storage = PNC.ColonyStorageRepository and PNC.ColonyStorageRepository.Get
        and PNC.ColonyStorageRepository.Get(dest.storageId) or nil
    if not storage then
        Internal.EnterStockpileWait(context, record, body, effect, at, "WORK_STORAGE_NOT_FOUND",
            nil, nil, nil, { retryMs = opts and opts.retryMs, onUpdate = opts and opts.onUpdate,
                markDirty = opts and opts.markDirty, clearDestinationOnWait = true })
        return nil, nil, "WORK_STORAGE_NOT_FOUND"
    end
    local storageService = PNC.ColonyStorageService
    if not storageService or type(storageService.LiveNPCSource) ~= "function" then
        return dest, storage, nil
    end
    local preview, previewReason = previewOutputItems(record, body, effect, storageService)
    if not preview then
        if previewReason then
            Internal.EnterStockpileWait(context, record, body, effect, at, previewReason,
                storage, dest.storageId, nil, opts)
            return nil, nil, previewReason
        end
        return dest, storage, nil
    end
    local owner = (opts and opts.reservationPrefix or "work-output") .. ":"
        .. tostring(context and (context.id or context.workOrderId) or "")
        .. ":" .. tostring(effect and (effect.ownerKey or effect.treeKey or effect.id) or "")
    local ok, reason, details = true, nil, nil
    if type(storageService.ReserveOutputCapacity) == "function" then
        ok, reason, details = storageService.ReserveOutputCapacity(storage, preview, owner)
    elseif type(storageService.Preflight) == "function" then
        ok, reason, details = storageService.Preflight(storage, preview)
    end
    if not ok then
        Internal.EnterStockpileWait(context, record, body, effect, at, reason or "storage_full",
            storage, dest.storageId, details, { retryMs = opts and opts.retryMs,
                onUpdate = opts and opts.onUpdate, markDirty = opts and opts.markDirty,
                clearDestinationOnWait = true })
        return nil, nil, reason or "storage_full"
    end
    context.outputCapacityReservationId, context.outputCapacityDetails = owner, details
    context.outputRetryAt, context.outputWaitReason = nil, nil
    context.outputWaitStorageId, context.outputWaitStorageRevision = nil, nil
    return dest, storage, nil
end

Internal.HaltMovement, Internal.MarkDirty, Internal.UpdateContext = haltMovement, markDirty, updateContext
return Service
