if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC and PNC.WaterContainerService
if not Service then return end
local Internal = Service.Internal or {}
local Portable = Internal.Portable
local Events = Internal.Events
local EventTypes = Internal.EventTypes
local Inventory = Internal.Inventory
local NearbyWater = Internal.NearbyWater
local SupplyInternal = Internal.SupplyInternal
local EPSILON = Internal.EPSILON
local call = Internal.call
local objectType = Internal.objectType
local fluidType = Internal.fluidType
local rawSourceAmount = Internal.rawSourceAmount
local setStateDetails = Internal.setStateDetails
local activityDetails = Internal.activityDetails
local logRefill = Internal.logRefill
local deepCopy = Internal.deepCopy
local reconcileCompactDescription = Internal.reconcileCompactDescription
local syncNative = Internal.syncNative
local sourceAmount = Internal.sourceAmount
local liveBody = Internal.liveBody
local syncOwnerInventory = Internal.syncOwnerInventory
local captureSource = Internal.captureSource
local restoreSource = Internal.restoreSource
local targetState = Internal.targetState
local rollbackDestination = Internal.rollbackDestination

function Service.Refill(record, itemID, source)
    local item
    local description
    local compactDescription
    local body
    local selected
    local materializeUndo
    local native
    local beforeNative
    local oldState
    local destinationAmount
    local capacity
    local freeCapacity
    local available
    local amount
    local target
    local captured
    local sourceBefore
    local sourceKey
    local ok
    local consumed
    local reason
    local consumptionDetails
    local inventory
    local details = {}
    local function fail(code, extra)
        local key
        local value
        if type(extra) == "table" then
            for key, value in pairs(extra) do details[key] = value end
        end
        details.reason = code
        details.failureReason = code
        details.inventoryRevisionAfter = record and record.inventory
            and record.inventory.revision or nil
        activityDetails(record, details)
        logRefill("failed", record, item or itemID, source, details)
        return false, code
    end
    inventory = record and Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    details.inventoryRevisionBefore = inventory
        and inventory.revision or record and record.inventory
        and record.inventory.revision or nil
    details.liveBodyAvailable = false
    logRefill("attempt", record, itemID, source, details)
    if not record then return fail("NPC_UNAVAILABLE") end
    item, description = Service.FindContainer(record, itemID)
    if not item then return fail(description) end
    details.containerID = item.id
    details.containerFullType = item.type or item.fullType
    details.containerEquipped = inventory and inventory.equipped
        and tostring(inventory.equipped.waterContainer or "")
            == tostring(item.id or "")
    setStateDetails(details, "compact", description and description.state)
    details.compactAmount = description and description.amount
    details.compactCapacity = description and description.capacity
    details.compactFreeCapacity = description and description.freeCapacity
    details.compactLiquidType = description and description.primaryType
    details.compactCanFill = description and description.canFill
    details.compactCanDrink = description and description.canDrink
    compactDescription = description
    body = liveBody(record)
    if not body then return fail("NPC_BODY_UNAVAILABLE") end
    details.liveBodyAvailable = true
    if not source or not source.object then
        sourceKey = source and source.key
        source = NearbyWater.ResolveFillSource(record, sourceKey)
    end
    sourceKey = source and source.key or sourceKey
    details.sourceKey = sourceKey
    details.sourceObjectType = objectType(source and source.object)
    details.sourceFluidType = fluidType(source and source.object)
    details.sourceAmountBefore = rawSourceAmount(source)
    details.sourceInfinite = source and source.object
        and NearbyWater.IsInfiniteFaucet(source.object) == true
    details.sourceCanFill = source and source.object
        and NearbyWater.IsFillableFaucet
        and NearbyWater.IsFillableFaucet(source.object) == true
    if not source or not source.object
        or not NearbyWater.IsCleanFaucet(source.object)
        or NearbyWater.IsFillableFaucet
            and not NearbyWater.IsFillableFaucet(source.object)
    then
        return fail("WATER_FILL_SOURCE_UNAVAILABLE")
    end
    selected = SupplyInternal and SupplyInternal.NativeCandidates
        and SupplyInternal.NativeCandidates(body, item) or {}
    native = selected[1] and selected[1].item or nil
    if not native and Inventory.MaterializeItem then
        ok, _, materializeUndo = Inventory.MaterializeItem(record, body, item.id)
        if ok then
            selected = SupplyInternal.NativeCandidates(body, item)
            native = selected[1] and selected[1].item or nil
        end
    end
    if not native then
        if materializeUndo then pcall(materializeUndo) end
        return fail("WATER_CONTAINER_PHYSICAL_MISSING")
    end
    details.physicalCandidate = true
    details.physicalItemID = call(native, "getID") or native.id
    details.physicalItemType = call(native, "getFullType") or native.type
    beforeNative = Portable.CaptureFluid(native)
    if not beforeNative then
        if materializeUndo then pcall(materializeUndo) end
        return fail("WATER_CONTAINER_STATE_UNAVAILABLE")
    end
    setStateDetails(details, "physical", beforeNative)
    description = Inventory.DescribeLiquidContainer(item, native)
    capacity = tonumber(description and description.capacity)
    destinationAmount = tonumber(description and description.amount) or 0
    freeCapacity = math.max(0, (capacity or 0) - destinationAmount)
    details.compactAmount = destinationAmount
    details.compactCapacity = capacity
    details.compactFreeCapacity = freeCapacity
    details.compactLiquidType = description and description.primaryType
    details.compactCanFill = description and description.canFill
    details.compactCanDrink = description and description.canDrink
    setStateDetails(details, "compact", description and description.state)
    if not capacity or freeCapacity <= EPSILON then
        details.compactAmountBefore = compactDescription
            and compactDescription.amount or nil
        details.compactCapacityBefore = compactDescription
            and compactDescription.capacity or nil
        details.compactStateReconciled = reconcileCompactDescription(record,
            item, compactDescription, description)
        if materializeUndo then pcall(materializeUndo) end
        return fail("WATER_CONTAINER_FULL")
    end
    available = sourceAmount(source)
    details.sourceEffectiveAmount = available
    amount = math.min(freeCapacity,
        tonumber(NearbyWater.MAX_REFILL_LITERS) or 4)
    if available ~= nil then amount = math.min(amount, available) end
    if amount <= EPSILON then
        if materializeUndo then pcall(materializeUndo) end
        return fail("INSUFFICIENT_WATER")
    end
    target = targetState(beforeNative, capacity, destinationAmount + amount)
    if not Portable.ApplyFluid(native, target) then
        if materializeUndo then pcall(materializeUndo) end
        return fail("WATER_CONTAINER_FILL_FAILED")
    end
    syncNative(native)
    captured = Portable.CaptureFluid(native)
    setStateDetails(details, "physicalAfter", captured)
    if not captured
        or (tonumber(captured.fluidAmount) or 0)
            < destinationAmount + amount - EPSILON
    then
        rollbackDestination(record, item, native, beforeNative,
            item.itemState, materializeUndo)
        return fail("WATER_CONTAINER_FILL_VERIFY_FAILED")
    end
    oldState = deepCopy(item.itemState)
    ok = Inventory.ApplyDelta(record, {{
        op = "update", itemID = item.id, itemState = captured,
    }}, "water_refill")
    if not ok then
        rollbackDestination(record, item, native, beforeNative,
            oldState, materializeUndo)
        return fail("WATER_CONTAINER_COMPACT_UPDATE_FAILED")
    end
    details.inventoryRevisionAfterDestination = record.inventory
        and record.inventory.revision or nil
    setStateDetails(details, "compactAfter", Inventory.ResolveItemState
        and Inventory.ResolveItemState(item) or item.itemState)
    sourceBefore = captureSource(source)
    details.sourceAmountBefore = rawSourceAmount(source)
    ok, consumed, reason, consumptionDetails = NearbyWater.Consume(
        record, source, amount)
    -- Consume historically returned false, reason on failure while success
    -- returns true, consumed, remaining. Normalize both forms before the
    -- transaction decides whether to roll back.
    if ok ~= true and type(consumed) == "string" then
        if type(reason) == "table" and not consumptionDetails then
            consumptionDetails = reason
        end
        reason, consumed = consumed, 0
    end
    if type(consumptionDetails) == "table" then
        for key, value in pairs(consumptionDetails) do
            details[key] = value
        end
    end
    details.sourceConsumptionResult = ok
    details.sourceConsumedAmount = consumed
    details.sourceAmountAfter = rawSourceAmount(source)
    if ok ~= true or (tonumber(consumed) or 0) < amount - EPSILON then
        local physicalRestored
        local compactRestored
        physicalRestored, compactRestored = rollbackDestination(
            record, item, native, beforeNative, oldState, materializeUndo)
        details.destinationPhysicalRollback = physicalRestored
        details.destinationCompactRollback = compactRestored
        details.sourceRollback = restoreSource(source, sourceBefore)
        details.sourceAmountAfterRollback = rawSourceAmount(source)
        return fail(reason or "WATER_FILL_SOURCE_NOT_MUTABLE", details)
    end
    if materializeUndo then materializeUndo = nil end
    if PNC.NearbyResourceLocator and PNC.NearbyResourceLocator.Invalidate then
        PNC.NearbyResourceLocator.Invalidate(
            "world_water_fill:" .. tostring(record.id))
    end
    if NearbyWater.InvalidateHydrationPlan then
        NearbyWater.InvalidateHydrationPlan(record)
    end
    local clientInventorySync, clientInventorySyncReason =
        syncOwnerInventory(record)
    logRefill("complete", record, item, source, {
        amount = amount,
        capacity = capacity,
        revision = record.inventory and record.inventory.revision or nil,
        inventoryRevisionBefore = details.inventoryRevisionBefore,
        inventoryRevisionAfter = record.inventory
            and record.inventory.revision or nil,
        containerEquipped = details.containerEquipped,
        sourceObjectType = details.sourceObjectType,
        sourceFluidType = details.sourceFluidType,
        sourceAmountBefore = details.sourceAmountBefore,
        sourceAmountAfter = details.sourceAmountAfter,
        sourceMutationAPI = details.sourceMutationAPI,
        sourceConsumedAmount = details.sourceConsumedAmount,
        compactAfterAmount = details.compactAfterAmount,
        compactAfterCapacity = details.compactAfterCapacity,
        compactAfterLiquidType = details.compactAfterPrimaryType,
        physicalAfterAmount = details.physicalAfterAmount,
        physicalAfterCapacity = details.physicalAfterCapacity,
        physicalAfterLiquidType = details.physicalAfterPrimaryType,
        transactionCommitted = true,
        clientInventorySync = clientInventorySync,
        clientInventorySyncReason = clientInventorySyncReason,
    })
    Events.emit(EventTypes.NPC_WATER_REFILLED, record, item.type, amount,
        source.key)
    return true, amount, item.id
end


return Service
