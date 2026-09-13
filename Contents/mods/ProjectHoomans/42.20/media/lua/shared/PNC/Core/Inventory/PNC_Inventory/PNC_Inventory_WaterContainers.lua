-- Generic liquid-container detection and the single logical NPC water slot.
-- The slot is intentionally separate from primary/secondary equipment: a
-- bottle must not overwrite a weapon merely because hydration selected it.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

local EPSILON = 0.0001
local SAFE_FLUIDS = {
    Water = true,
    CarbonatedWater = true,
}

Internal.WaterContainerCapabilityCache =
    Internal.WaterContainerCapabilityCache or {}

local function call(object, method, ...)
    local fn = object and object[method]
    local value
    local ok
    if type(fn) ~= "function" then return nil end
    ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function probe(fullType)
    local cached = Internal.WaterContainerCapabilityCache[fullType]
    local item
    local profile
    if cached ~= nil then return cached.item, cached.fluid == true end
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
    end
    if type(item) == "table" and not item.getFluidContainer and item[1] then
        item = item[1]
    end
    profile = item and Profiles.ClassifyNative(item) or Profiles.Get(fullType)
    cached = {
        item = item,
        fluid = profile and profile.capabilities
            and profile.capabilities.fluid == true
            or item and (call(item, "getFluidContainer") ~= nil
                or call(item, "isFluidContainer") == true
                or call(item, "IsFluidContainer") == true),
    }
    Internal.WaterContainerCapabilityCache[fullType] = cached
    return cached.item, cached.fluid == true
end

local function nativeFluidCapable(item)
    return item and (call(item, "getFluidContainer") ~= nil
        or call(item, "isFluidContainer") == true
        or call(item, "IsFluidContainer") == true)
end

local function hasFluidState(state)
    return type(state) == "table"
        and (state.fluidAmount ~= nil or state.fluidCapacity ~= nil
            or state.fluidPrimaryType ~= nil or type(state.fluids) == "table")
end

local function stateFor(item, nativeItem, nativeAuthoritative)
    local state
    if nativeAuthoritative and nativeItem then
        state = Portable.CaptureFluid(nativeItem)
    end
    if state then return state end
    if Inventory.ResolveItemState then
        state = Inventory.ResolveItemState(item) or {}
        if hasFluidState(state) then return state end
    end
    if nativeItem then return Portable.CaptureFluid(nativeItem) or {} end
    return type(item and item.itemState) == "table" and item.itemState or {}
end

local function fluidName(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function stateFluidSafe(state, amount)
    local entries = state and state.fluids
    local primary = fluidName(state and (state.fluidPrimaryType
        or state.fluidType))
    local seen = false
    local i
    local entry
    local name
    if type(entries) == "table" then
        for i = 1, #entries do
            entry = entries[i]
            name = fluidName(entry and entry.type)
            if tonumber(entry and entry.amount) and
                tonumber(entry.amount) > EPSILON
            then
                seen = true
                if not SAFE_FLUIDS[name] then return false end
            end
        end
    end
    if primary and (not seen or (tonumber(amount) or 0) > EPSILON)
        and not SAFE_FLUIDS[primary]
    then
        return false
    end
    return true
end

local function waterFluid()
    local fluidClass = rawget(_G, "Fluid")
    local fluidTypeClass = rawget(_G, "FluidType")
    local value
    local ok
    if fluidClass and type(fluidClass.Get) == "function" then
        ok, value = pcall(fluidClass.Get, "Water")
        if ok and value then return value end
    end
    if fluidTypeClass and fluidTypeClass.Water
        and fluidClass and type(fluidClass.Get) == "function"
    then
        ok, value = pcall(fluidClass.Get, fluidTypeClass.Water)
        if ok and value then return value end
    end
    return nil
end

local function canAcceptWater(nativeItem, state, freeCapacity)
    local container = nativeItem and call(nativeItem, "getFluidContainer")
    local water = waterFluid()
    local result
    if container and water and type(container.canAddFluid) == "function" then
        result = call(container, "canAddFluid", water)
        if result == false then return false end
    end
    return (tonumber(freeCapacity) or 0) > EPSILON
        and state.fluidInputLocked ~= true
end

function Inventory.IsLiquidContainer(item, nativeItem)
    local state
    local _, capable
    local nativeProvided = nativeItem ~= nil
    if type(item) ~= "table" then return false end
    if nativeProvided then
        capable = nativeFluidCapable(nativeItem)
    else
        nativeItem, capable = probe(item.type)
    end
    state = stateFor(item, nativeItem, nativeProvided)
    if capable then return true end
    return state.fluidCapacity ~= nil or state.fluidAmount ~= nil
        or type(state.fluids) == "table"
end

function Inventory.DescribeLiquidContainer(item, nativeItem)
    local state
    local amount
    local capacity
    local safe
    local free
    local nativeProvided = nativeItem ~= nil
    if not Inventory.IsLiquidContainer(item, nativeItem) then return nil end
    nativeItem = nativeItem or probe(item.type)
    state = stateFor(item, nativeItem, nativeProvided)
    amount = math.max(0, tonumber(state.fluidAmount) or 0)
    capacity = tonumber(state.fluidCapacity)
    free = capacity and math.max(0, capacity - amount) or 0
    safe = stateFluidSafe(state, amount)
    return {
        amount = amount,
        capacity = capacity,
        freeCapacity = free,
        primaryType = fluidName(state.fluidPrimaryType or state.fluidType),
        fluids = state.fluids,
        inputLocked = state.fluidInputLocked == true,
        safeWater = safe == true,
        empty = amount <= EPSILON,
        canFill = safe and canAcceptWater(nativeItem, state, free) or false,
        canDrink = safe and amount > EPSILON,
        state = state,
    }
end

function Inventory.IsWaterContainer(item, nativeItem)
    local description = Inventory.DescribeLiquidContainer(item, nativeItem)
    return description ~= nil
        and (description.canDrink == true or description.canFill == true)
end

function Inventory.IsRefillableWaterContainer(item, nativeItem)
    local description = Inventory.DescribeLiquidContainer(item, nativeItem)
    return description ~= nil and description.canFill == true
end

local function itemPriority(item, description, equippedID)
    if item.id == equippedID then return 1 end
    if description.canDrink then return 2 end
    if description.canFill then return 3 end
    return 4
end

function Inventory.FindWaterContainer(record)
    local inv = record and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
    local equippedID = inv and inv.equipped and inv.equipped.waterContainer
    local candidates = {}
    local itemID
    local item
    local description
    if not inv then return nil end
    for itemID, item in pairs(inv.items or {}) do
        if type(item) == "table" and not item.interactionLocked
            and not item.wornSlot and not item.attachedSlot
        then
            description = Inventory.DescribeLiquidContainer(item)
            if description and (description.canDrink or description.canFill) then
                candidates[#candidates + 1] = {
                    item = item,
                    priority = itemPriority(item, description, equippedID),
                    amount = description.amount,
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        if math.abs(left.amount - right.amount) > EPSILON then
            return left.amount > right.amount
        end
        return tostring(left.item.id) < tostring(right.item.id)
    end)
    return candidates[1] and candidates[1].item or nil
end

function Inventory.GetWaterContainer(record)
    local inv = record and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
    local id = inv and inv.equipped and inv.equipped.waterContainer
    local item = id and inv.items and inv.items[id] or nil
    if item and Inventory.IsWaterContainer(item) then return item end
    return Inventory.FindWaterContainer(record)
end

function Inventory.ReconcileWaterContainer(record)
    local inv = record and Inventory.EnsureRecordInventory
        and record.inventory
    local runtime = record and record.runtime and record.runtime.inventory
    local current
    local selected
    local id
    if not inv or not runtime then return nil end
    if runtime.waterContainerReconcileInProgress == true then return inv end
    if tonumber(runtime.waterContainerReconciledRevision) == tonumber(inv.revision) then
        return inv
    end
    runtime.waterContainerReconcileInProgress = true
    current = inv.equipped and inv.equipped.waterContainer
    id = current
    if id then
        current = inv.items and inv.items[id] or nil
        if not current or current.interactionLocked
            or current.wornSlot or current.attachedSlot
            or not Inventory.IsWaterContainer(current)
        then
            Inventory.SetWaterContainer(record, nil, "water_container_repair")
            id = nil
        elseif current.equipSlot ~= "waterContainer" then
            Inventory.SetWaterContainer(record, id, "water_container_repair")
        end
    end
    if not id then
        selected = Inventory.FindWaterContainer(record)
        if selected then
            Inventory.SetWaterContainer(record, selected.id,
                "water_container_auto_equip")
        end
    end
    runtime.waterContainerReconciledRevision = tonumber(inv.revision) or 0
    runtime.waterContainerReconcileInProgress = nil
    return inv
end

return Inventory
