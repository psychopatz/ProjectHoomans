-- Server-authoritative refill transactions for NPC liquid containers.
-- Destination state is committed before source water is debited; if the
-- source cannot be consumed, both compact and physical destination state are
-- restored. This keeps a failed path/interaction from duplicating water.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WaterContainerService = PNC.WaterContainerService or {}

local Service = PNC.WaterContainerService
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Inventory = PNC.Inventory
local NearbyWater = PNC.NearbyWaterService
local SupplyInternal = PNC.SupplyInventoryInternal

local EPSILON = 0.0001

local function call(object, method, ...)
    local fn = object and object[method]
    local ok
    local value
    if type(fn) ~= "function" then return nil end
    ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function objectType(object)
    local class = call(object, "getClass")
    return tostring(call(class, "getName")
        or call(object, "getClassName")
        or object and object.className
        or object and object.__type
        or "")
end

local function fluidType(object)
    local container = call(object, "getFluidContainer")
    local fluid = call(object, "getPrimaryFluid")
        or call(container, "getPrimaryFluid")
    local value = call(fluid, "getFluidTypeString")
    if value then return tostring(value) end
    return call(object, "hasWater") == true and "Water" or ""
end

local function rawSourceAmount(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    return tonumber(call(object, "getFluidAmount"))
        or tonumber(call(object, "getWaterAmount"))
        or tonumber(call(container, "getAmount"))
end

local function setStateDetails(details, prefix, state)
    if type(state) ~= "table" then return end
    details[prefix .. "Amount"] = state.fluidAmount
    details[prefix .. "Capacity"] = state.fluidCapacity
    details[prefix .. "PrimaryType"] = state.fluidPrimaryType
    details[prefix .. "InputLocked"] = state.fluidInputLocked
    if type(state.fluids) == "table" then
        local entries = {}
        for index = 1, #state.fluids do
            local entry = state.fluids[index]
            entries[#entries + 1] = tostring(entry and entry.type or "")
                .. ":" .. tostring(entry and entry.amount or "")
        end
        details[prefix .. "Fluids"] = table.concat(entries, ",")
    end
end

local function activityDetails(record, details)
    local runtime = record and record.runtime
    local activity = runtime and runtime.facilityActivity
    local scene = runtime and runtime.animationScene
    details.currentActivity = activity and activity.capability or ""
    details.currentActivityPhase = activity and activity.phase or ""
    details.currentScene = scene and scene.id or ""
    details.currentSceneStep = scene and scene.step or ""
end

local function logRefill(event, record, item, source, details)
    local core = PNC.Core
    local itemID = type(item) == "table" and item.id or item
    local itemType = type(item) == "table"
        and (item.type or item.fullType) or nil
    local sourceKey = type(source) == "table" and source.key or nil
    local message
    if not core or not core.LogInfo then return end
    message = "[PNC][WATER] refill event=" .. tostring(event)
        .. " npc=" .. tostring(record and record.id or "")
        .. " item=" .. tostring(itemID or "")
        .. " type=" .. tostring(itemType or "")
        .. " source=" .. tostring(sourceKey or "")
    for key, value in pairs(type(details) == "table" and details or {}) do
        if type(value) ~= "table" and type(value) ~= "function" then
            message = message .. " " .. tostring(key) .. "=" .. tostring(value)
        end
    end
    core.LogInfo(message)
end

local function deepCopy(value)
    if PNC.Core and PNC.Core.DeepCopy then return PNC.Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = deepCopy(entry) end
    return result
end

local function syncNative(item)
    if item and type(item.syncItemFields) == "function" then
        pcall(item.syncItemFields, item)
    end
    if sendItemStats and item then pcall(sendItemStats, item) end
end

local function sourceAmount(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    if NearbyWater.IsInfiniteFaucet(object) then return nil end
    return tonumber(call(object, "getFluidAmount"))
        or tonumber(call(object, "getWaterAmount"))
        or tonumber(call(container, "getAmount"))
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function ownerPlayer(record)
    local core = PNC.Core
    local order = record and record.orderSpec or {}
    local activity = record and record.runtime
        and record.runtime.facilityActivity or {}
    local previousOrder = activity.previousOrder or {}
    local player
    local onlineID = record and record.ownerOnlineID
        or order and order.ownerOnlineID
        or previousOrder.ownerOnlineID
    local username = record and record.ownerUsername
        or order and order.ownerUsername
        or previousOrder.ownerUsername
    if not core or not record then return nil end
    if core.ResolvePlayerByOnlineID and onlineID ~= nil then
        player = core.ResolvePlayerByOnlineID(onlineID)
        if player then return player end
    end
    if core.ResolvePlayerByUsername and username then
        player = core.ResolvePlayerByUsername(username)
        if player then return player end
    end
    return nil
end

-- Inventory.ApplyDelta is the authoritative server mutation, but it does not
-- know which client has a character window open. Push the committed full
-- payload to the owner so the compact itemState decoder on the client cannot
-- remain at the pre-refill amount.
local function syncOwnerInventory(record)
    local network = PNC.Network
    local player = ownerPlayer(record)
    local ok
    local result
    if not network or type(network.SendCharacterPayload) ~= "function" then
        return false, "network_unavailable"
    end
    if not player then return false, "owner_unavailable" end
    ok, result = pcall(network.SendCharacterPayload, player, record)
    if not ok then return false, tostring(result or "payload_send_failed") end
    return true, "character_payload"
end

local function captureSource(entry)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    local infinite = NearbyWater.IsInfiniteFaucet(object) == true
    return {
        fluid = not infinite and container and Portable.CaptureFluid(object)
            or nil,
        amount = sourceAmount(entry),
        rawAmount = rawSourceAmount(entry),
    }
end

local function restoreSource(entry, before)
    local object = entry and entry.object
    local container = call(object, "getFluidContainer")
    local restored = true
    local currentAmount
    if not object or not before then return true end
    if before.fluid then
        restored = Portable.ApplyFluid(object, before.fluid) == true
    end
    if before.amount ~= nil and not restored
        or before.amount ~= nil and before.rawAmount ~= nil
            and rawSourceAmount(entry) ~= before.rawAmount
    then
        if container and type(container.adjustAmount) == "function" then
            local ok, value = pcall(container.adjustAmount, container,
                before.amount)
            restored = ok and value ~= false
        end
        if (not restored or not container)
            and type(object.setWaterAmount) == "function"
        then
            local ok, value = pcall(object.setWaterAmount, object,
                before.amount)
            restored = ok and value ~= false
        end
    end
    if restored and type(object.sync) == "function" then
        pcall(object.sync, object)
    end
    if restored and before.rawAmount ~= nil then
        currentAmount = rawSourceAmount(entry)
        restored = currentAmount ~= nil
            and math.abs(currentAmount - before.rawAmount) <= EPSILON
    end
    return restored
end

local function targetState(before, capacity, amount)
    local state = {
        fluidAmount = amount,
        fluidCapacity = capacity,
        fluidPrimaryType = "Water",
        fluidInputLocked = false,
        fluids = { { type = "Water", amount = amount } },
    }
    if before and before.fluidCanPlayerEmpty ~= nil then
        state.fluidCanPlayerEmpty = before.fluidCanPlayerEmpty
    end
    if before and before.fluidRainCatcher ~= nil then
        state.fluidRainCatcher = before.fluidRainCatcher
    end
    return state
end

local function rollbackDestination(record, item, native, beforeState, oldState,
    materializeUndo)
    local physicalRestored = true
    local compactRestored = true
    if native and beforeState then
        physicalRestored = Portable.ApplyFluid(native, beforeState) == true
        syncNative(native)
    end
    if Inventory.ApplyDelta and item then
        compactRestored = Inventory.ApplyDelta(record, {{
            op = "update", itemID = item.id,
            itemState = oldState or {},
        }}, "water_refill_rollback")
    end
    if materializeUndo then pcall(materializeUndo) end
    return physicalRestored, compactRestored
end

function Service.FindContainer(record, itemID)
    local inv = record and Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local item = inv and inv.items and inv.items[tostring(itemID or "")]
    if not item and inv then item = Inventory.GetWaterContainer(record) end
    -- Keep full liquid containers in the transaction path so the caller gets
    -- the precise WATER_CONTAINER_FULL reason instead of the broader
    -- not-refillable result.
    if not item or not Inventory.IsLiquidContainer(item) then
        return nil, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    local description = Inventory.DescribeLiquidContainer(item)
    if not description then
        return nil, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    return item, description
end

function Service.Refill(record, itemID, source)
    local item
    local description
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
