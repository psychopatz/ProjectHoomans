-- Abstract work-output delivery to colony storage or worker inventory.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local nowMs = Internal.Now

local function normalizeFlushItems(context, effect, items)
    local source = type(items) == "table" and items or (effect and effect.items) or nil
    local output = {}
    if type(source) == "table" and #source > 0 then
        for _, entry in ipairs(source) do
            if type(entry) == "table" and (entry.fullType or entry.type) then
                output[#output + 1] = {
                    fullType = tostring(entry.fullType or entry.type),
                    quantity = math.max(1, math.floor(tonumber(
                        entry.quantity or entry.stack or entry.count) or 1)),
                    modData = entry.modData,
                }
            end
        end
    elseif context and context.pendingOutput and context.pendingOutput.fullType then
        output[1] = {
            fullType = tostring(context.pendingOutput.fullType),
            quantity = math.max(1, math.floor(tonumber(
                context.pendingOutput.quantity) or 1)),
        }
    end
    return output
end

local function resolveAbstractStorage(record, context, effect, opts)
    if opts and opts.storage then return opts.storage end
    local storageId = (opts and opts.storageId)
        or (context and (context.storageId or context.outputDestination
            and context.outputDestination.storageId))
        or (effect and effect.destinationStorageId)
    local repository = PNC.ColonyStorageRepository
    if storageId and repository and repository.Get then
        local storage = repository.Get(storageId)
        if storage then return storage end
    end
    if opts and opts.resolveStorage == false then return nil end
    local dest = Internal.ResolveOutputDestination(record, context, effect or {}, opts)
    if dest and dest.storageId and repository and repository.Get then
        return repository.Get(dest.storageId)
    end
    if PNC.ProductionContext and PNC.ProductionContext.ForWorker then
        local resolved = PNC.ProductionContext.ForWorker(record)
        return resolved and resolved.storage or nil
    end
    return nil
end

---Delivers abstract work outputs to colony storage (or NPC inventory when configured).
function Service.FlushAbstractDelivery(context, record, effect, items, opts)
    opts = opts or {}
    if type(effect) == "table" and tostring(effect.state or "") == "APPLIED" then
        if context then context.pendingOutput = nil end
        return true, "ABSTRACT_ALREADY_APPLIED"
    end
    local products = normalizeFlushItems(context, effect, items)
    if #products < 1 then
        if context then context.pendingOutput = nil end
        return true, "ABSTRACT_OUTPUT_EMPTY"
    end
    local storageService = PNC.ColonyStorageService
    local targetMode = tostring(opts.deliveryTarget or "AUTO")
    local storage = targetMode ~= "NPC_INVENTORY"
        and resolveAbstractStorage(record, context, effect, opts) or nil
    if targetMode ~= "NPC_INVENTORY" and storage and storageService
        and type(storageService.DepositProductionItems) == "function"
    then
        local txId = opts.transactionId or ("abstract-out:" .. tostring(
            context and (context.id or context.workOrderId)
            or (effect and effect.id) or nowMs()))
        local ok, resultOrReason = storageService.DepositProductionItems(
            storage.id, products, opts.provenance, txId,
            opts.transactionStage or "work_abstract_output")
        if ok then
            if type(storageService.RecordActivity) == "function" then
                storageService.RecordActivity(storage, "STORE",
                    tostring(record and (record.name or record.id) or "worker"),
                    products, opts.activityTag or "work")
            end
            Service.SetOutputEffectState(effect, "APPLIED",
                "ABSTRACT_STORAGE_ACCEPTED", opts)
            if effect then effect.pickupState = "STOCKPILE" end
            if context then context.pendingOutput = nil end
            return true, "ABSTRACT_STORAGE_ACCEPTED"
        end
        if targetMode == "STORAGE" or opts.fallbackToInventory ~= true then
            local failReason = tostring(resultOrReason or "ABSTRACT_STORAGE_UNAVAILABLE")
            Service.SetOutputEffectState(effect, "PENDING", failReason, opts)
            return false, failReason
        end
    elseif targetMode == "STORAGE" then
        Service.SetOutputEffectState(effect, "PENDING",
            "ABSTRACT_STORAGE_UNAVAILABLE", opts)
        return false, "ABSTRACT_STORAGE_UNAVAILABLE"
    end

    if PNC.Inventory and type(PNC.Inventory.AddItems) == "function" and record then
        local specs = {}
        for _, entry in ipairs(products) do
            specs[#specs + 1] = { type = entry.fullType, stack = entry.quantity }
        end
        local ok, reason = PNC.Inventory.AddItems(record, specs, "root",
            opts.reason or "work_abstract_output")
        if ok then
            Service.SetOutputEffectState(effect, "APPLIED",
                "ABSTRACT_INVENTORY_ACCEPTED", opts)
            if context then context.pendingOutput = nil end
            return true, "ABSTRACT_INVENTORY_ACCEPTED"
        end
        local failReason = tostring(reason or "ABSTRACT_OUTPUT_UNAVAILABLE")
        Service.SetOutputEffectState(effect, "PENDING", failReason, opts)
        return false, failReason
    end
    Service.SetOutputEffectState(effect, "PENDING",
        "ABSTRACT_OUTPUT_UNAVAILABLE", opts)
    return false, "ABSTRACT_OUTPUT_UNAVAILABLE"
end

return Service
