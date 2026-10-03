if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.SupplyInventoryInternal
local CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
local Util = require
    "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Portable = require
    "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local ItemTransfer =
    require "PsychopatzCore/Inventory/PsychopatzItemTransfer"
local FLUID_EPSILON = 0.0001
local Ops = H.Consumption or {}
local syncPhysicalItem = Ops.SyncPhysicalItem
local removePhysicalUnit = Ops.RemovePhysicalUnit

local function drainPhysicalFluid(nativeItem, amount)
    local container = nativeItem and nativeItem.getFluidContainer
        and nativeItem:getFluidContainer() or nil
    local before = container and container.getAmount
        and tonumber(container:getAmount()) or nil
    local beforeState
    local removed
    local after
    if not container or not container.removeFluid or not before then
        return false, "physical_fluid_container_unavailable"
    end
    beforeState = Portable.CaptureFluid(nativeItem)
    -- Match the vanilla drink path: the second argument is the non-utensil
    -- flag. Passing true can invoke a different container treatment in B42.
    removed = container:removeFluid(amount, false)
    if removed and type(removed.release) == "function" then
        pcall(removed.release, removed)
    end
    after = tonumber(container:getAmount())
    local expected = math.max(0, before - math.max(0, tonumber(amount) or 0))
    if not after or after >= before - 0.000001
        or math.abs(after - expected) > FLUID_EPSILON
    then
        if beforeState then Portable.ApplyFluid(nativeItem, beforeState) end
        syncPhysicalItem(nativeItem)
        return false, "physical_fluid_drain_failed"
    end
    return true, function()
        if beforeState then
            return Portable.ApplyFluid(nativeItem, beforeState)
        end
        return false
    end
end

local function consumePhysicalFood(adapter, nativeItem, replacement)
    local removed, reason, undo = removePhysicalUnit(adapter, nativeItem)
    local added = {}
    local replacementResult
    if not removed then return false, reason end
    if replacement then
        replacementResult = ItemTransfer.AddToContainer(
            adapter.container, replacement, 1)
        added = Util.javaList(replacementResult)
        if #added <= 0 then
            if undo then undo() end
            return false, "physical_replacement_add_failed"
        end
    end
    syncPhysicalItem(nativeItem)
    return true, nil, function()
        local restored = true
        for index = #added, 1, -1 do
            if not adapter:_nativeRemove(added[index]) then restored = false end
        end
        if undo and not undo() then restored = false end
        syncPhysicalItem(nativeItem)
        return restored
    end
end
H.Consumption.DrainPhysicalFluid = drainPhysicalFluid
H.Consumption.ConsumePhysicalFood = consumePhysicalFood
