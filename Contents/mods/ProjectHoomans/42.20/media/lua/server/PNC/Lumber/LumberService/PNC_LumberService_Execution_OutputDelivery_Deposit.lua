if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime
local outputEffectFor = Internal.OutputEffectFor
local setOutputEffectState = Internal.SetOutputEffectState
local call = Internal.Call
local listSize = Internal.ListSize
local listItem = Internal.ListItem
local worldObjectsFor = Internal.WorldObjectsFor
local itemID = Internal.ItemID
local itemType = Internal.ItemType
local hasCurrentOutputMarker = Internal.HasCurrentOutputMarker
local OUTPUT_RETRY_MS = 5000

local Output = Internal.OutputDelivery or {}
local oneShotAnimation = Output.OneShotAnimation
local pickupOutputItems = Output.PickupOutputItems

local function outputBase(record, job)
    local base
    if PNC.HomeDutyService and PNC.HomeDutyService.GetBase then
        base = PNC.HomeDutyService.GetBase(record, job and job.baseId)
    end
    if not base and PNC.BaseService then
        if job and job.baseId and PNC.BaseService.Get then
            base = PNC.BaseService.Get(job.baseId)
        end
        if not base and PNC.BaseService.GetForColony
            and record and record.affiliation
        then
            base = PNC.BaseService.GetForColony(
                record.affiliation.communityID or record.affiliation.communityId)
        end
    end
    return base
end

local function resolveOutputDestination(record, job, effect)
    if type(job.outputDestination) == "table" then
        local destination = job.outputDestination
        effect.destinationX = destination.x
        effect.destinationY = destination.y
        effect.destinationZ = destination.z
        effect.destinationNodeId = destination.nodeId
        effect.destinationStorageId = destination.storageId
        return job.outputDestination
    end
    local base = outputBase(record, job)
    if not base then return nil, "LUMBER_BASE_NOT_FOUND" end
    local nodeService = PNC.StockpileAccessService
    if not nodeService or type(nodeService.FindNearest) ~= "function" then
        return nil, "LUMBER_STOCKPILE_ACCESS_UNAVAILABLE"
    end
    local node = nodeService.FindNearest(base.id, effect.x, effect.y, effect.z,
        { requireLoaded = tostring(effect.sourceMode or "") == "LIVE" })
    if not node then return nil, "LUMBER_STOCKPILE_NOT_FOUND" end
    local storageID = node.storageId
    local storage
    local repository = PNC.ColonyStorageRepository
    if storageID and repository and repository.Get then
        storage = repository.Get(storageID)
    end
    if not storage and repository and repository.GetPrimary then
        storage = repository.GetPrimary(base.factionId, base.settlementId)
        storageID = storage and storage.id or storageID
    end
    if not storage then return nil, "LUMBER_STORAGE_NOT_FOUND" end
    job.baseId = base.id
    job.outputDestination = {
        nodeId = node.id, storageId = storageID,
        x = node.x, y = node.y, z = node.z,
    }
    effect.destinationX = node.x
    effect.destinationY = node.y
    effect.destinationZ = node.z
    effect.destinationNodeId = node.id
    effect.destinationStorageId = storageID
    markDirty()
    return job.outputDestination
end

local function compactItemsForType(record, fullType)
    local inventory = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or record.inventory
    local output = {}
    for _, item in pairs(inventory and inventory.items or {}) do
        if tostring(item.type or "") == tostring(fullType or "") then
            output[#output + 1] = item
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return output
end

local function outputReservationId(job, effect)
    return "lumber-output:" .. tostring(job and job.id or "") .. ":"
        .. tostring(effect and effect.treeKey
            or job and job.pendingOutput and job.pendingOutput.treeKey or "")
end

local function releaseOutputCapacity(job, storageInternal)
    local owner = job and job.outputCapacityReservationId or nil
    if owner and storageInternal
        and type(storageInternal.ReleaseOutputCapacity) == "function"
    then
        storageInternal.ReleaseOutputCapacity(owner)
    end
    if job then
        job.outputCapacityReservationId = nil
        job.outputCapacityDetails = nil
        job.outputWaitReason = nil
        job.outputWaitStorageId = nil
        job.outputWaitStorageRevision = nil
    end
end

-- A failed destination/capacity check is a terminal movement decision for
-- this tick.  Clear the native route before publishing the wait state so the
-- old stockpile path cannot keep walking the worker while the retry timer is
-- pending.
local function haltOutputMovement(record, body, reason)
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(
            record,
            body,
            reason or "lumber_stockpile_wait"
        )
    end
end

local function outputWaitStorageChanged(job)
    local storageID = job and job.outputWaitStorageId or nil
    local storageService = PNC.ColonyStorageService
    local storageInternal = storageService and storageService.Internal or nil
    if not storageID then
        return false
    end
    if storageInternal and type(storageInternal.HasStorageChanged) == "function" then
        local changed = storageInternal.HasStorageChanged(
            storageID,
            job.outputWaitStorageRevision
        )
        return changed == true
    end
    if not PNC.ColonyStorageRepository
        or type(PNC.ColonyStorageRepository.Get) ~= "function"
    then return false end
    local storage = PNC.ColonyStorageRepository.Get(storageID)
    if not storage then return false end
    return tostring(storage.revision or 0)
        ~= tostring(job.outputWaitStorageRevision or 0)
end

local function storageRevision(storage)
    local storageInternal = PNC.ColonyStorageService
        and PNC.ColonyStorageService.Internal or nil
    if storageInternal and type(storageInternal.GetStorageRevision) == "function" then
        return storageInternal.GetStorageRevision(storage)
    end
    return tonumber(storage and storage.revision) or 0
end

-- Build a read-only preview before the worker walks to the stockpile. This
-- prevents a full destination from turning a carried output into a repeated
-- deposit animation / travel loop. Test doubles may not expose preview(); in
-- that compatibility case the authoritative transfer still performs its own
-- preflight.
local function previewOutputItems(record, body, effect, storageInternal)
    local pendingByType = {}
    for _, descriptor in ipairs(effect.items or {}) do
        if descriptor.collected and not descriptor.delivered then
            local fullType = tostring(descriptor.fullType or "")
            pendingByType[fullType] = pendingByType[fullType] or {}
            pendingByType[fullType][#pendingByType[fullType] + 1] = descriptor
        end
    end
    local preview = {}
    for fullType, descriptors in pairs(pendingByType) do
        local remaining = #descriptors
        for _, item in ipairs(compactItemsForType(record, fullType)) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(tonumber(item.stack) or 0))
            local quantity = math.min(available, remaining)
            if quantity > 0 then
                local source, sourceReason = storageInternal.LiveNPCSource(
                    record, item, quantity, body)
                if not source then return nil, sourceReason end
                if type(source.preview) ~= "function" then
                    return nil, nil
                end
                local records, reason = source:preview()
                if not records then return nil, reason end
                for _, itemRecord in ipairs(records) do
                    preview[#preview + 1] = itemRecord
                end
                remaining = remaining - quantity
            end
        end
        if remaining > 0 then
            return nil, "LUMBER_OUTPUT_NOT_IN_INVENTORY"
        end
    end
    return preview
end

local function reserveOutputCapacity(job, record, body, storage, effect)
    local storageInternal = PNC.ColonyStorageService
        and PNC.ColonyStorageService.Internal or nil
    if not storageInternal
        or type(storageInternal.LiveNPCSource) ~= "function"
    then
        return true, nil, nil
    end
    local preview, previewReason = previewOutputItems(record, body, effect,
        storageInternal)
    if not preview then
        if previewReason then return false, previewReason end
        return true, nil, nil
    end
    local owner = outputReservationId(job, effect)
    local ok, reason, details
    if type(storageInternal.ReserveOutputCapacity) == "function" then
        ok, reason, details = storageInternal.ReserveOutputCapacity(
            storage, preview, owner)
    elseif type(storageInternal.Preflight) == "function" then
        ok, reason, details = storageInternal.Preflight(storage, preview)
    else
        return true, nil, nil
    end
    if not ok then return false, reason or "storage_full", details end
    job.outputCapacityReservationId = owner
    job.outputCapacityDetails = details
    job.outputRetryAt = nil
    job.outputWaitReason = nil
    job.outputWaitStorageId = nil
    job.outputWaitStorageRevision = nil
    return true, nil, details
end

local function depositOutputItems(record, body, storage, effect, reservationOwner)
    local storageInternal = PNC.ColonyStorageService
        and PNC.ColonyStorageService.Internal or nil
    if not storageInternal
        or type(storageInternal.LiveNPCSource) ~= "function"
        or type(storageInternal.TransferIntoStorage) ~= "function"
    then
        return false, "LUMBER_STORAGE_TRANSFER_UNAVAILABLE"
    end
    local pendingByType = {}
    for _, descriptor in ipairs(effect.items or {}) do
        if descriptor.collected and not descriptor.delivered then
            local fullType = tostring(descriptor.fullType or "")
            pendingByType[fullType] = pendingByType[fullType] or {}
            pendingByType[fullType][#pendingByType[fullType] + 1] = descriptor
        end
    end
    for fullType, descriptors in pairs(pendingByType) do
        local remaining = #descriptors
        for _, item in ipairs(compactItemsForType(record, fullType)) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(tonumber(item.stack) or 0))
            local quantity = math.min(available, remaining)
            if quantity > 0 then
                local source, sourceReason = storageInternal.LiveNPCSource(
                    record, item, quantity, body)
                if not source then return false, sourceReason end
                local ok, reason = storageInternal.TransferIntoStorage(
                    storage, source, quantity, reservationOwner)
                if not ok then return false, reason end
                local delivered = quantity
                for _, descriptor in ipairs(descriptors) do
                    if delivered <= 0 then break end
                    if not descriptor.delivered then
                        descriptor.delivered = true
                        delivered = delivered - 1
                    end
                end
                remaining = remaining - quantity
            end
        end
        if remaining > 0 then return false, "LUMBER_OUTPUT_NOT_IN_INVENTORY" end
    end
    local activity = {}
    for _, descriptor in ipairs(effect.items or {}) do
        activity[#activity + 1] = {
            fullType = descriptor.fullType, quantity = descriptor.quantity or 1,
        }
    end
    if storageInternal.RecordActivity then
        storageInternal.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), activity, "lumber")
    end
    setOutputEffectState(effect, "APPLIED", "LUMBER_OUTPUT_STORED")
    effect.phase, effect.pickupState = "DELIVERED", "STOCKPILE"
    return true
end

local function tickLiveOutput(job, record, body, at)
    local output = job.pendingOutput
    local tree = output and Service.GetTree(output.treeKey) or nil
    local effect = tree and tree.outputEffect or nil
    if not effect then
        releaseOutputCapacity(job, PNC.ColonyStorageService
            and PNC.ColonyStorageService.Internal or nil)
        job.state, job.phase = "FAILED", "FAILED"
        return false, false, "LUMBER_OUTPUT_EFFECT_MISSING"
    end
    if tostring(effect.state or "") == "APPLIED" then
        releaseOutputCapacity(job, PNC.ColonyStorageService
            and PNC.ColonyStorageService.Internal or nil)
        job.pendingOutput, job.outputTreeKey = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, true, "lumber_output_already_delivered"
    end
    if job.phase == "WAITING_FOR_WORKER" then
        job.state = "TRAVELING"
        job.phase = effect.pickupState == "NPC_INVENTORY"
            and "OUTPUT_DESTINATION_APPROACH" or "OUTPUT_APPROACH"
    end
    if effect.waitReason == "LUMBER_LIVE_WORKER_REQUIRED" then
        effect.waitReason = nil
        effect.lastReason = "LUMBER_OUTPUT_RESUMED"
        effect.updatedAt = at
        markDirty()
    end
    local square = Service.GetSquare(effect.x, effect.y, effect.z)
    if not square then
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        effect.waitReason, effect.lastReason = "TREE_CHUNK_LOADING",
            "TREE_CHUNK_LOADING"
        effect.updatedAt = at
        updateRuntime(record, job, tree)
        markDirty()
        return true, false, "tree_chunk_loading_for_output"
    end
    if job.phase == "OUTPUT_APPROACH" then
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        local distance = math.abs((tonumber(bx) or 0) - (effect.x + 0.5))
            + math.abs((tonumber(by) or 0) - (effect.y + 0.5))
        if distance > 1.5 then
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body, effect.x + 0.5,
                    effect.y + 0.5, effect.z, "walk", 0.7, "lumber_output")
            end
            updateRuntime(record, job, tree)
            return true, false, "traveling_to_lumber_output"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_grab")
        end
        job.state, job.phase = "WORKING", "GRAB_PENDING"
    end
    if job.phase == "GRAB_PENDING" then
        local status, reason = oneShotAnimation(record, body, "lumber.grab",
            "lumber_output_grab")
        if status == "failed" then
            job.state = "WAITING"
            effect.waitReason, effect.lastReason = reason, reason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, reason
        end
        if status ~= "completed" then
            updateRuntime(record, job, tree)
            return true, false, "grabbing_lumber_output"
        end
        local picked, pickupReason = pickupOutputItems(job, record, body,
            effect, square)
        if not picked then
            effect.phase = "GRAB_PENDING"
            updateRuntime(record, job, tree)
            return true, false, pickupReason
        end
    end
    if job.phase == "WAITING_FOR_STOCKPILE"
        or job.phase == "OUTPUT_DESTINATION_APPROACH"
    then
        if (tonumber(job.outputRetryAt) or 0) > at then
            if not outputWaitStorageChanged(job) then
                haltOutputMovement(record, body, "lumber_stockpile_retry_wait")
                updateRuntime(record, job, tree)
                return true, false, "waiting_for_lumber_stockpile"
            end
            -- A storage mutation (deposit, withdrawal, clear, or compact)
            -- invalidates the backoff. Recheck capacity on this tick.
            job.outputRetryAt = nil
        end
        local destination, destinationReason = resolveOutputDestination(record,
            job, effect)
        if not destination then
            haltOutputMovement(record, body, "lumber_stockpile_missing")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputWaitReason = destinationReason
            effect.waitReason, effect.lastReason = destinationReason,
                destinationReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, destinationReason
        end
        local storage = PNC.ColonyStorageRepository
            and PNC.ColonyStorageRepository.Get
            and PNC.ColonyStorageRepository.Get(destination.storageId) or nil
        if not storage then
            haltOutputMovement(record, body, "lumber_storage_missing")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.outputDestination = nil
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputWaitReason = "LUMBER_STORAGE_NOT_FOUND"
            effect.waitReason, effect.lastReason = "LUMBER_STORAGE_NOT_FOUND",
                "LUMBER_STORAGE_NOT_FOUND"
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, "LUMBER_STORAGE_NOT_FOUND"
        end
        local capacityOK, capacityReason, capacityDetails =
            reserveOutputCapacity(job, record, body, storage, effect)
        if not capacityOK then
            haltOutputMovement(record, body, "lumber_stockpile_full")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.outputDestination = nil
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputCapacityDetails = capacityDetails
            job.outputWaitReason = capacityReason
            job.outputWaitStorageId = destination.storageId
            job.outputWaitStorageRevision = storageRevision(storage)
            effect.waitReason, effect.lastReason = capacityReason,
                capacityReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, capacityReason
        end
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        local distance = math.abs((tonumber(bx) or 0) - destination.x)
            + math.abs((tonumber(by) or 0) - destination.y)
        if distance > 0.8 then
            job.state, job.phase = "TRAVELING",
                "OUTPUT_DESTINATION_APPROACH"
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body, destination.x,
                    destination.y, destination.z, "walk", 0.7,
                    "lumber_stockpile")
            end
            updateRuntime(record, job, tree)
            return true, false, "traveling_to_lumber_stockpile"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_deposit")
        end
        job.state, job.phase = "WORKING", "DEPOSIT_PENDING"
    end
    if job.phase == "DEPOSIT_PENDING" then
        local destination, destinationReason = resolveOutputDestination(record,
            job, effect)
        if not destination then
            haltOutputMovement(record, body, "lumber_stockpile_missing")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputWaitReason = destinationReason
            effect.waitReason, effect.lastReason = destinationReason,
                destinationReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, destinationReason
        end
        local storage = PNC.ColonyStorageRepository
            and PNC.ColonyStorageRepository.Get
            and PNC.ColonyStorageRepository.Get(destination.storageId) or nil
        if not storage then
            haltOutputMovement(record, body, "lumber_storage_missing")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.outputDestination = nil
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputWaitReason = "LUMBER_STORAGE_NOT_FOUND"
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, "LUMBER_STORAGE_NOT_FOUND"
        end
        local capacityOK, capacityReason, capacityDetails =
            reserveOutputCapacity(job, record, body, storage, effect)
        if not capacityOK then
            haltOutputMovement(record, body, "lumber_stockpile_full")
            releaseOutputCapacity(job, PNC.ColonyStorageService
                and PNC.ColonyStorageService.Internal or nil)
            job.outputDestination = nil
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            job.outputRetryAt = at + OUTPUT_RETRY_MS
            job.outputCapacityDetails = capacityDetails
            job.outputWaitReason = capacityReason
            job.outputWaitStorageId = destination.storageId
            job.outputWaitStorageRevision = storageRevision(storage)
            effect.waitReason, effect.lastReason = capacityReason,
                capacityReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, capacityReason
        end
        local status, reason = oneShotAnimation(record, body, "lumber.deposit",
            "lumber_output_deposit")
        if status == "failed" then
            job.state = "WAITING"
            effect.waitReason, effect.lastReason = reason, reason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, reason
        end
        if status ~= "completed" then
            updateRuntime(record, job, tree)
            return true, false, "depositing_lumber_output"
        end
        local deposited, depositReason = depositOutputItems(record, body,
            storage, effect, job.outputCapacityReservationId)
        if not deposited then
            effect.waitReason, effect.lastReason = depositReason,
                depositReason
            effect.updatedAt = at
            if depositReason == "storage_full" then
                haltOutputMovement(record, body, "lumber_stockpile_full")
                releaseOutputCapacity(job, PNC.ColonyStorageService
                    and PNC.ColonyStorageService.Internal or nil)
                job.outputDestination = nil
                job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
                job.outputRetryAt = at + OUTPUT_RETRY_MS
                job.outputWaitReason = depositReason
                job.outputWaitStorageId = destination.storageId
                job.outputWaitStorageRevision = storageRevision(storage)
            end
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, depositReason
        end
        releaseOutputCapacity(job, PNC.ColonyStorageService
            and PNC.ColonyStorageService.Internal or nil)
        job.pendingOutput, job.outputTreeKey = nil, nil
        job.outputDestination = nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, true, "lumber_output_deposited"
    end
    updateRuntime(record, job, tree)
    return true, false, "lumber_output_pending"
end
Internal.TickLiveOutput = tickLiveOutput
Internal.ReleaseOutputCapacity = function(job)
    releaseOutputCapacity(job, PNC.ColonyStorageService
        and PNC.ColonyStorageService.Internal or nil)
end
