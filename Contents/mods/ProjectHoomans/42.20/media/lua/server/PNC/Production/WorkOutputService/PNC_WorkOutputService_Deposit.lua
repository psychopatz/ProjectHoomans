-- Shared NPC-to-storage transfer and one-shot output animation helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkOutputService
local Internal = Service.Internal

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

local function pendingDescriptorsByType(effect)
    local pendingByType = {}
    for _, descriptor in ipairs(effect and effect.items or {}) do
        if descriptor.collected and not descriptor.delivered then
            local fullType = tostring(descriptor.fullType or "")
            pendingByType[fullType] = pendingByType[fullType] or {}
            pendingByType[fullType][#pendingByType[fullType] + 1] = descriptor
        end
    end
    return pendingByType
end

---Advances a per-context one-shot scene animation without stale completion reuse.
function Internal.OneShotAnimation(context, record, body, sceneID, reason)
    local runtime = record and record.runtime or nil
    local requested = context and context._animRequested == sceneID
    local scene = runtime and runtime.animationScene or nil
    if scene and tostring(scene.id or "") == tostring(sceneID) then
        if context then context._animRequested = sceneID end
        return "running"
    end
    local last = runtime and runtime.lastAnimationScene or nil
    if requested and last and tostring(last.id or "") == tostring(sceneID)
        and tostring(last.reason or "") == "completed"
    then
        context._animRequested = nil
        return "completed"
    end
    if not PNC.AnimationScenes or type(PNC.AnimationScenes.Request) ~= "function" then
        return "failed", "WORK_ANIMATION_UNAVAILABLE"
    end
    local started = PNC.AnimationScenes.Request(record, body, sceneID, {
        reason = reason, repeatMode = "once",
    })
    if started == false then return "failed", "WORK_ANIMATION_FAILED" end
    if context then context._animRequested = sceneID end
    return "started"
end

---Transfers carried work output items from worker inventory into colony storage.
function Internal.DepositOutputItems(record, body, storage, effect, owner, opts)
    local storageService = PNC.ColonyStorageService
    if not storageService or type(storageService.LiveNPCSource) ~= "function"
        or type(storageService.TransferIntoStorage) ~= "function"
    then
        return false, "WORK_STORAGE_TRANSFER_UNAVAILABLE"
    end
    for fullType, descriptors in pairs(pendingDescriptorsByType(effect)) do
        local remaining = #descriptors
        for _, item in ipairs(compactItemsForType(record, fullType)) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(tonumber(item.stack) or 0))
            local quantity = math.min(available, remaining)
            if quantity > 0 then
                local source, sourceReason = storageService.LiveNPCSource(
                    record, item, quantity, body)
                if not source then return false, sourceReason end
                local ok, reason = storageService.TransferIntoStorage(
                    storage, source, quantity, owner)
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
        if remaining > 0 then return false, "WORK_OUTPUT_NOT_IN_INVENTORY" end
    end
    if storageService.RecordActivity then
        local activity = {}
        for _, descriptor in ipairs(effect.items or {}) do
            activity[#activity + 1] = {
                fullType = descriptor.fullType, quantity = descriptor.quantity or 1,
            }
        end
        storageService.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), activity,
            opts and opts.activityTag or "work")
    end
    Service.SetOutputEffectState(effect, "APPLIED",
        opts and opts.storedReason or "WORK_OUTPUT_STORED")
    effect.phase, effect.pickupState = "DELIVERED", "STOCKPILE"
    return true
end

local function baseFor(record, context)
    local baseId = context and context.baseId or nil
    if PNC.HomeDutyService and PNC.HomeDutyService.GetBase then
        local base = PNC.HomeDutyService.GetBase(record, baseId)
        if base then return base end
    end
    if PNC.BaseService then
        if baseId and PNC.BaseService.Get then
            local base = PNC.BaseService.Get(baseId)
            if base then return base end
        end
        if PNC.BaseService.GetForColony and record and record.affiliation then
            return PNC.BaseService.GetForColony(
                record.affiliation.communityID or record.affiliation.communityId)
        end
    end
    return nil
end

---Resolves the base storage node and destination coordinates for an output effect.
function Internal.ResolveOutputDestination(record, context, effect, opts)
    if type(context and context.outputDestination) == "table" then
        local dest = context.outputDestination
        effect.destinationX, effect.destinationY, effect.destinationZ = dest.x, dest.y, dest.z
        effect.destinationNodeId, effect.destinationStorageId = dest.nodeId, dest.storageId
        return dest
    end
    local base = baseFor(record, context)
    if not base then return nil, "WORK_BASE_NOT_FOUND" end
    local nodeService = PNC.StockpileAccessService
    if not nodeService or type(nodeService.FindNearest) ~= "function" then
        return nil, "WORK_STOCKPILE_ACCESS_UNAVAILABLE"
    end
    local node = nodeService.FindNearest(base.id, effect.x, effect.y, effect.z,
        { requireLoaded = tostring(effect.sourceMode or "") == "LIVE" })
    if not node then return nil, "WORK_STOCKPILE_NOT_FOUND" end
    local repository = PNC.ColonyStorageRepository
    local storageID = node.storageId
    local storage = storageID and repository and repository.Get
        and repository.Get(storageID) or nil
    if not storage and repository and repository.GetPrimary then
        storage = repository.GetPrimary(base.factionId, base.settlementId)
        storageID = storage and storage.id or storageID
    end
    if not storage then return nil, "WORK_STORAGE_NOT_FOUND" end
    local dest = {
        nodeId = node.id, storageId = storageID,
        x = node.x, y = node.y, z = node.z,
    }
    if context then context.baseId, context.outputDestination = base.id, dest end
    effect.destinationX, effect.destinationY, effect.destinationZ = dest.x, dest.y, dest.z
    effect.destinationNodeId, effect.destinationStorageId = dest.nodeId, dest.storageId
    if opts and type(opts.markDirty) == "function" then opts.markDirty() end
    return dest
end

Internal.CompactItemsForType = compactItemsForType
Internal.PendingDescriptorsByType = pendingDescriptorsByType

return Service
